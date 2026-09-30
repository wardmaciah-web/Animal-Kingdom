local RS=game:GetService('ReplicatedStorage')
local Players=game:GetService('Players')
local W=require(script.Parent.GameplayWidgets)
local Catalog=require(RS.Shared.Gameplay.Definitions.ShopDefinitions)
local Kingdom=require(script.Parent.KingdomShopMenu)
local M={Category='All',Page='Boosts'}
local function available(def)
 local assets=RS:FindFirstChild('Assets');local category=assets and assets:FindFirstChild(def.Category);local model=category and category:FindFirstChild(def.ModelName)
 return model and not model:GetAttribute('Placeholder') and (model:IsA('BasePart') or model:FindFirstChildWhichIsA('BasePart',true))
end
local function place(ctx,id)
 local player=Players.LocalPlayer;local root=player.Character and player.Character:FindFirstChild('HumanoidRootPart');local plot
 for _,name in ipairs({'PlayerPlots','AnimalKingdomPlayerPlots','Plots','AnimalKingdomFuturePlayerPlots'})do
  local folder=workspace:FindFirstChild(name,true)
  if folder then for _,p in ipairs(folder:GetChildren())do if p:GetAttribute('OwnerUserId')==player.UserId then plot=p;break end end end
  if plot then break end
 end
 if not plot or not root then ctx.Notify('Visit your plot first');return end
 local cf=plot:IsA('Model') and plot:GetBoundingBox() or plot.CFrame
 local point=cf:PointToObjectSpace(root.Position)
 ctx.Request('Place',{Id=id,Offset=Vector3.new(math.round(point.X),0,math.round(point.Z)),Rotation=0})
end
function M.Decorations(ctx)
 local data=ctx.Data
 W.Text(ctx.Content,'Stand on your plot where you want to place a decoration. Owned copies are reusable.',UDim2.new(1,-8,0,48),nil,14,W.Color.Muted)
 local placed={};for _,entry in ipairs(data.PlotProgression.Placements)do placed[entry.ItemId]=(placed[entry.ItemId] or 0)+1 end
 local any=false
 for id,d in pairs(Catalog)do
  local owned=data.Items[id] or 0
  if owned>0 and not d.UpgradeId then
   any=true
   local b=W.Button(ctx.Content,d.DisplayName..' • '..(placed[id] or 0)..' / '..owned..' placed • PLACE HERE',UDim2.new(1,-8,0,46),nil,function()place(ctx,id)end);b.Name='Place_'..id;W.Disabled(b,(placed[id] or 0)>=owned or not available(d))
  end
 end
 if not any then W.Empty(ctx.Content,'Your decorations','Buy furniture or flowers in Shop.')end
 for _,e in ipairs(data.PlotProgression.Placements)do
  local b=W.Button(ctx.Content,'REMOVE '..(Catalog[e.ItemId] and Catalog[e.ItemId].DisplayName or 'decoration'),UDim2.new(1,-8,0,44),nil,function()ctx.Request('RemovePlacement',{UID=e.UID})end,W.Color.Wood);b.Name='Remove_'..e.UID
 end
end
function M.Shop(ctx)
 W.List(ctx.Content)
 local tabs=W.New('Frame',{Name='ShopPages',Size=UDim2.new(1,-8,0,46),BackgroundTransparency=1},ctx.Content)
 for i,page in ipairs({'Boosts','Furniture','My Decorations'})do local b=W.Button(tabs,page:upper(),UDim2.new(1/3,-6,1,0),UDim2.fromScale((i-1)/3,0),function()M.Page=page;ctx.Refresh()end,M.Page==page and W.Color.Green or W.Color.Wood);b.Name=page=='My Decorations'and 'MyDecorations'or page end
 if M.Page=='My Decorations' then M.Decorations(ctx);return end
 Kingdom.Instruction(ctx)
 if M.Page=='Boosts'then Kingdom.Render(ctx);return end
 local bar=W.New('Frame',{Size=UDim2.new(1,-8,0,46),BackgroundTransparency=1},ctx.Content)
 for i,category in ipairs({'All','Furniture','Decorations'})do W.Button(bar,category,UDim2.new(1/3,-8,1,0),UDim2.fromScale((i-1)/3,0),function()M.Category=category;ctx.Refresh()end,M.Category==category and W.Color.Green or W.Color.Wood)end
 local grid=W.New('Frame',{Size=UDim2.new(1,-8,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1},ctx.Content);if ctx.Short then W.List(grid)else W.Grid(grid,math.min(400,math.max(260,(ctx.Content.AbsoluteSize.X-40)/2)),274,14)end
 local ids={};for id,d in pairs(Catalog)do if not d.Season and available(d) and (M.Category=='All' or M.Category==d.Category)then table.insert(ids,id)end end;table.sort(ids)
 for _,id in ipairs(ids)do
  local d=Catalog[id];local card=W.Card(grid,ctx.Short and 100 or 274);card.Name='Shop_'..id
  local folder=RS:FindFirstChild('Assets');folder=folder and folder:FindFirstChild(d.Category);local model=folder and folder:FindFirstChild(d.ModelName)
  if model and (model:IsA('Model') or model:IsA('BasePart'))then
   local clone=model:Clone();if clone:IsA('BasePart')then local container=Instance.new('Model');clone.Parent=container;container.PrimaryPart=clone;clone=container end
   W.Viewport(card,clone,ctx.Short and UDim2.fromOffset(86,86)or UDim2.new(1,-30,0,100),UDim2.fromOffset(12,8))
  else W.Icon(card,d.Category=='Furniture' and 'Plot' or 'Flower',UDim2.new(1,-50,0,115),UDim2.fromOffset(25,16))end
  if ctx.Short then
   W.Heading(card,d.DisplayName,UDim2.new(.62,-114,0,36),UDim2.fromOffset(104,8),20)
   W.Text(card,'Owned '..(ctx.Data.Items[id]or 0)..' / '..d.MaxOwned..' • '..d.Category,UDim2.new(.62,-114,0,34),UDim2.fromOffset(104,46),13,W.Color.Muted)
   local b=W.Button(card,'Buy • '..W.Format(d.Cost)..' '..W.Theme.CurrencyName(d.Currency),UDim2.new(.38,-16,0,52),UDim2.new(.62,0,.5,-26),function()ctx.Request('ShopBuy',{Id=id})end);b.Name='Buy_'..id;W.Disabled(b,(ctx.Data.Items[id]or 0)>=d.MaxOwned)
   continue
  end
  local title=W.Heading(card,d.DisplayName,UDim2.new(1,-26,0,31),UDim2.fromOffset(13,113),23);title.TextXAlignment=Enum.TextXAlignment.Center
  W.Text(card,d.Description or (d.Category=='Furniture' and 'Furniture for your personal plot.' or 'A little color for your personal plot.'),UDim2.new(1,-28,0,33),UDim2.fromOffset(14,150),14,W.Color.Muted)
  W.Text(card,'Owned '..(ctx.Data.Items[id] or 0)..' / '..d.MaxOwned,UDim2.new(1,-28,0,24),UDim2.fromOffset(14,187),12,W.Color.Muted)
  local b=W.Button(card,'Buy • '..W.Format(d.Cost)..' '..W.Theme.CurrencyName(d.Currency),UDim2.new(1,-28,0,46),UDim2.fromOffset(14,216),function()ctx.Request('ShopBuy',{Id=id})end);b.Name='Buy_'..id;W.Disabled(b,(ctx.Data.Items[id] or 0)>=d.MaxOwned)
 end
end
return M
