local RS=game.ReplicatedStorage
local Players=game:GetService('Players')
local W=require(script.Parent.GameplayWidgets)
local D=require(RS.Shared.Gameplay.Definitions.KingdomShopDefinitions)
local P=require(RS.Shared.Gameplay.KingdomProgress)
local M={}
function M.Near()
 local folder=workspace:FindFirstChild('KingdomTownInteractions');local anchor=folder and folder:FindFirstChild('Shop')
 local root=Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild('HumanoidRootPart')
 return anchor and root and (root.Position-anchor.Position).Magnitude<=D.Distance
end
function M.Instruction(ctx)
 local near=M.Near()==true
 local label=W.Text(ctx.Content,near and 'At the Town store • purchases available' or 'Browse anywhere. Walk to the General Store in Town to purchase.',UDim2.new(1,-8,0,40),nil,13,W.Color.Muted)
 task.spawn(function()while label.Parent do task.wait(1);if label.Parent and (M.Near()==true)~=near then ctx.Refresh();break end end end)
end
function M.Render(ctx)
 local state=RS:FindFirstChild('KingdomShopStock');local rotation=state and state:GetAttribute('Rotation')
 if not rotation then W.Empty(ctx.Content,'Stock is arriving','The shop will update shortly.');return end
 local restock=(rotation+1)*D.RotationSeconds
 local timer=W.Text(ctx.Content,'',UDim2.new(1,-8,0,26),nil,13,W.Color.GreenDark)
 task.spawn(function()while timer.Parent do local left=math.max(0,math.ceil(restock-workspace:GetServerTimeNow()));timer.Text=string.format('Shared stock • restocks in %d:%02d • limits are per player',math.floor(left/60),left%60);task.wait(1)end end)
 if not ctx.Short then W.Text(ctx.Content,D.Stacking,UDim2.new(1,-8,0,70),nil,12,W.Color.Muted)end
 local s=ctx.Data.KingdomShop or {};local saved=s.Rotations and s.Rotations[tostring(rotation)]or {};local counts=saved.Counts or {}
 local grid=W.New('Frame',{Name='RotatingStock',Size=UDim2.new(1,-8,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1},ctx.Content)
 if ctx.Narrow or ctx.Short then W.List(grid)else W.Grid(grid,300,330,12)end
 for _,offer in ipairs(D.Offers(rotation))do
  local def=D[offer.EffectId];local card=W.Card(grid,ctx.Short and 318 or 330);card.Name='Offer_'..offer.Id
  local title=offer.Id=='Mystery'and ('Mystery Deal • '..def.Name)or def.Name
  W.Heading(card,title,UDim2.new(1,-28,0,48),UDim2.fromOffset(14,10),18)
  W.Text(card,def.Effect..(ctx.Short and '\nNo refresh, extension or same-effect stacking.'or ''),UDim2.new(1,-28,0,ctx.Short and 100 or 116),UDim2.fromOffset(14,62),13,W.Color.Muted)
  local remaining=math.max(0,offer.Limit-(counts[offer.Id]or 0));local active=P.Active(ctx.Data,offer.EffectId,workspace:GetServerTimeNow());local pending=offer.EffectId=='Fertilizer'and (s.Fertilizer or 0)>0
  local price=W.Format(offer.Price)..' '..W.Theme.CurrencyName(offer.Currency)
  local discount=offer.OriginalPrice and (' • was '..W.Format(offer.OriginalPrice)..string.format(' (-%.1f%%)',100*(1-offer.Price/offer.OriginalPrice)))or ''
  W.Text(card,price..discount..'\n'..remaining..' / '..offer.Limit..' remaining this rotation',UDim2.new(1,-28,0,48),UDim2.new(0,14,1,-144),12)
  local status=W.Text(card,active and ('Active • '..math.ceil(active.ExpiresAt-workspace:GetServerTimeNow())..'s remaining')or pending and 'Owned • pending on next valid trip'or 'Available',UDim2.new(1,-28,0,28),UDim2.new(0,14,1,-92),12,W.Color.GreenDark)
  if active then task.spawn(function()while status.Parent do local left=math.max(0,math.ceil(active.ExpiresAt-workspace:GetServerTimeNow()));status.Text=left>0 and ('Active • '..left..'s remaining')or 'Expired';if left==0 then ctx.Refresh();break end;task.wait(1)end end)end
  local b=W.Button(card,remaining==0 and 'Limit reached'or active and 'Already active'or pending and 'Use pending Fertilizer'or M.Near()and 'Buy • '..price or 'Purchase at Town shop',UDim2.new(1,-28,0,48),UDim2.new(0,14,1,-56),function()ctx.Request('KingdomBuy',{Id=offer.Id,Rotation=rotation})end)
  b.Name='BuyOffer_'..offer.Id;W.Disabled(b,remaining==0 or active~=nil or pending or not M.Near()or not ctx.Data.TutorialCompleted)
 end
end
return M
