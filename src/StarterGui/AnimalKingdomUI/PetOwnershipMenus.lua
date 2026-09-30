local RS=game:GetService('ReplicatedStorage')
local W=require(script.Parent.GameplayWidgets)
local Cards=require(script.Parent.OwnedPetCards)
local M={Sort='Highest',Page=1}
function M.Back()return false end
function M.Render(ctx)
 local data=ctx.Data;W.List(ctx.Content)
 local inventoryCount=0
 for _,pet in data.Pets do if pet.Location=='Inventory' then inventoryCount+=1 end end
 local top=W.New('Frame',{Name='InventoryTools',Size=UDim2.new(1,-8,0,96),BackgroundTransparency=1},ctx.Content)
 W.Heading(top,'ALL PETS • '..#data.Pets,UDim2.new(1,0,0,24),nil,16)
 local occupancy=W.Text(top,('Inventory %d / %d'):format(inventoryCount,data.PetStorageCapacity),UDim2.new(1,0,0,18),UDim2.fromOffset(0,24),13,W.Color.Muted)
 occupancy.Name='InventoryCapacity';occupancy.TextWrapped=false;occupancy.TextScaled=true
 W.New('UITextSizeConstraint',{MinTextSize=10,MaxTextSize=13},occupancy)
 local all=W.Button(top,'SELL ALL',UDim2.new(.45,-4,0,44),UDim2.fromOffset(0,50),function()ctx.Request('SellPets',{Mode='Inventory',UID=''})end,W.Color.Red);all.Name='SellAllPets';all.TextSize=14
 local sort=W.Button(top,'SORT: '..M.Sort:upper(),UDim2.new(.55,-4,0,44),UDim2.new(.45,4,0,50),function()M.Sort=M.Sort=='Highest' and 'Lowest' or 'Highest';M.Page=1;ctx.Refresh()end,W.Color.Wood);sort.Name='PetSort';sort.TextSize=13
 local filtered=table.clone(data.Pets)
 table.sort(filtered,function(a,b)
  local x,y=a.CoinsPerSecond or 0,b.CoinsPerSecond or 0
  if x==y then return a.UID<b.UID end
  if M.Sort=='Lowest' then return x<y end
  return x>y
 end)
 if #filtered==0 then W.Empty(ctx.Content,'Your companions','Search a Meadow tree to find your first pet.');return end
 local pages=math.max(1,math.ceil(#filtered/18));M.Page=math.clamp(M.Page,1,pages)
 local wide=ctx.Short and not ctx.Narrow
 local cardHeight=wide and 172 or 246
 local grid=W.New('Frame',{Name='OwnedPetGrid',Size=UDim2.new(1,-8,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1},ctx.Content);W.Grid(grid,wide and 260 or ctx.Narrow and 130 or 145,cardHeight,10)
 for i=(M.Page-1)*18+1,math.min(#filtered,M.Page*18)do
  local pet=filtered[i]
  local frame=W.New('Frame',{Name='Owned_'..pet.UID,Size=UDim2.fromOffset(150,cardHeight),BackgroundTransparency=1,LayoutOrder=i},grid)
  local movable=pet.Location=='Inventory' or pet.Location=='Held'
  local b=Cards.Card(frame,pet,'',UDim2.new(1,0,1,-48),nil,function()if movable then ctx.Request('Equip',{UID=pet.UID,Equipped=true})end end,pet.UID==data.ActiveHeldPetUID,wide and 'wide' or false);b.Name='Select_'..pet.UID
  b.Selectable=movable
  local location=W.Text(frame,pet.Location,UDim2.new(1,-8,0,20),UDim2.new(0,4,1,-70),11,W.Color.Muted);location.Name='Location';location.TextXAlignment=Enum.TextXAlignment.Center
  local mission=data.Activities and data.Activities.Mission
  if mission and mission.UID==pet.UID then
   location.Text=pet.Location..' • Mission '..mission.Progress..'/'..mission.Target
   location.TextSize=10;location:SetAttribute('MissionUID',pet.UID)
  end
  local lock=W.Button(frame,pet.Locked and 'UNLOCK' or 'LOCK',UDim2.new(pet.Location=='Held' and .5 or 1,-2,0,44),UDim2.new(0,0,1,-44),function()ctx.Request('Lock',{UID=pet.UID,Value=not pet.Locked})end,W.Color.Wood);lock.Name='Lock_'..pet.UID;lock.TextSize=11
  if pet.Location=='Held' then local store=W.Button(frame,'STORE',UDim2.new(.5,-2,0,44),UDim2.new(.5,2,1,-44),function()ctx.Request('MovePet',{UID=pet.UID,Location='Inventory',Slot=0})end);store.Name='Store_'..pet.UID;store.TextSize=11 end
 end
 local pager=W.New('Frame',{Size=UDim2.new(1,-8,0,46),BackgroundTransparency=1},ctx.Content)
 local prev=W.Button(pager,'‹ Previous',UDim2.new(.32,0,1,0),nil,function()M.Page-=1;ctx.Content.CanvasPosition=Vector2.zero;ctx.Refresh()end);W.Disabled(prev,M.Page<=1)
 local label=W.Text(pager,M.Page..' / '..pages,UDim2.new(.32,0,1,0),UDim2.fromScale(.34,0),14);label.TextXAlignment=Enum.TextXAlignment.Center
 local next=W.Button(pager,'Next ›',UDim2.new(.32,0,1,0),UDim2.fromScale(.68,0),function()M.Page+=1;ctx.Content.CanvasPosition=Vector2.zero;ctx.Refresh()end);W.Disabled(next,M.Page>=pages)
end
return M
