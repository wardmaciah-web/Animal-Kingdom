local RS=game:GetService("ReplicatedStorage")
local Players=game:GetService("Players")
local Http=game:GetService("HttpService")
local Input=game:GetService("UserInputService")
local Gui=game:GetService("GuiService")
local Actions=game:GetService("ContextActionService")
local Run=game:GetService("RunService")
local W=require(script.Parent.GameplayWidgets)
local G=require(RS.Shared.Gameplay.Definitions.GardenDefinitions)
local P=require(RS.Shared.Gameplay.GardenProgress)
local Pets=require(RS.Shared.Gameplay.Definitions.PetDefinitions)
local Appearance=require(RS.Shared.Gameplay.PetAppearance)
local M={Tab="EXPEDITIONS",Shop="SUPPLIES",Page=1,Flow=nil}
local player=Players.LocalPlayer
local green=W.Color.Green;local cream=W.Color.Garden;local ink=W.Color.Ink
local berry=Color3.fromRGB(174,75,98);local timers={};local ctxNow;local selection={};local activators=setmetatable({},{__mode="k"});local busyUntil=0
local function redraw(ctx) ctx.Content.CanvasPosition=Vector2.zero;ctx.Refresh() end
local function clock(seconds) seconds=math.max(0,math.ceil(seconds));return string.format("%02d:%02d",math.floor(seconds/60),seconds%60) end
local function text(parent,value,y,height,size,color,x,width)
 return W.Text(parent,value,UDim2.new(width or 1,x and -(x+12) or -24,0,height or 26),UDim2.fromOffset(x or 12,y),size or 15,color or ink)
end
local function card(ctx,height,name)
 local c=W.Card(ctx.GardenBody or ctx.Content,height);c.Name=name;local surface=c:FindFirstChild("Surface");if surface then surface.ImageColor3=Color3.fromRGB(244,255,230) end;return c
end
local function button(parent,label,y,callback,color,key)
 local b=W.Button(parent,label,UDim2.new(1,-24,0,44),UDim2.fromOffset(12,y),callback,color or green)
 b.Name=key or label;b.Selectable=true;activators[b]=callback;selection[#selection+1]=b;return b
end
local function act(ctx,action,payload)
 if os.clock()<busyUntil then return end;busyUntil=os.clock()+.6
 payload=payload or {};payload.RequestId=Http:GenerateGUID(false);ctx.Request(action,payload)
end
local function tabs(parent,labels,active,y,callback)
 local width=1/#labels
 for i,name in ipairs(labels) do
  local b=W.Button(parent,name,UDim2.new(width,-8,0,44),UDim2.new((i-1)*width,4,0,y),function() callback(name) end,name==active and green or Color3.fromRGB(139,137,109))
  activators[b]=function() callback(name) end;b.Name="Tab_"..name;b.TextSize=#labels>3 and 11 or 12;b.Selectable=true;selection[#selection+1]=b
 end
end
local function viewport(parent,pet,size,pos)
 local real=require(RS.Shared.Gameplay.PetModelResolver).Resolve(pet.PetId)~=nil
 return W.PetPreview(parent,pet,size,pos),real
end
local function pet(data,uid) for _,p in ipairs(data.Pets or {}) do if p.UID==uid then return p end end end
local function reason(data,p)
 if p.Location=="Held" then return "HELD" end
 if p.Location=="Sanctuary" then return "SANCTUARY" end
 if p.Location~="Inventory" then return "FORAGING" end
 for _,trip in ipairs(data.GardenExpeditions or {}) do if trip.UID==p.UID then return "FORAGING" end end
 if p.Locked then return "LOCKED" end
 if not Pets[p.PetId] or not require(RS.Shared.Gameplay.PetModelResolver).Resolve(p.PetId) then return "UNAVAILABLE" end
end
local function back(ctx)
 if M.Flow then if M.Flow=="Confirm" then M.Flow="Trips" elseif M.Flow=="Trips" then M.Flow="Pets" else M.Flow=nil end;redraw(ctx) else ctx.Close() end
end
function M.Back(ctx)
 if M.Flow then back(ctx);return true end
 return false
end
function M.Close() timers={};selection={};ctxNow=nil end
local function header(ctx)
 local data=ctx.Data
 if ctx.Short then
  local c=card(ctx,100,"GardenHeader")
  text(c,"Harvest "..tostring(data.Currencies.GardenHarvest or 0).."   •   Pets "..#(data.GardenExpeditions or {}).." / 3",8,38,15,green,12,.55)
  local inGarden=player:GetAttribute("InGarden")==true
  local visit=button(c,inGarden and "RETURN TO KINGDOM"or "VISIT GARDEN",8,function()ctx.GardenTravel(inGarden and "ReturnGarden"or "VisitGarden")end,green,"VisitGarden");visit.Size=UDim2.new(.42,-18,0,44);visit.Position=UDim2.new(.58,6,0,8)
  tabs(c,{"EXPEDITIONS","CROPS","SHOP"},M.Tab,50,function(name)M.Tab=name;M.Flow=nil;redraw(ctx)end)
  return
 end
 local c=card(ctx,156,"GardenHeader")
 text(c,"PET GARDEN",8,30,23,green)
 text(c,"Harvest  "..tostring(data.Currencies.GardenHarvest or 0),40,28,18)
 text(c,"Garden Plot "..tostring(player:GetAttribute("GardenPlotId") or "…").."   •   Active pets "..#(data.GardenExpeditions or {}).." / 3",70,28,13)
 local inGarden=player:GetAttribute("InGarden")==true
 local visit=button(c,inGarden and "RETURN TO KINGDOM" or "VISIT GARDEN",18,function() ctx.GardenTravel(inGarden and "ReturnGarden" or "VisitGarden") end,green,"VisitGarden");visit.Size=UDim2.new(.42,-18,0,48);visit.Position=UDim2.new(.58,6,0,20)
 tabs(c,{"EXPEDITIONS","CROPS","SHOP"},M.Tab,104,function(name) M.Tab=name;M.Flow=nil;ctx.Content.CanvasPosition=Vector2.zero;redraw(ctx) end)
end
local function baskets(c,trip,y)
 local values={}
 for _,id in ipairs(G.CropNames) do table.insert(values,G.Crops[id].Icon.." "..tostring((trip.PendingCrops or {})[id] or 0)) end
 text(c,"LIVE BASKET   "..table.concat(values,"   "),y,40,13)
end
local function expeditions(ctx)
 local data=ctx.Data;local assigned={};local count=0
 for _,trip in ipairs(data.GardenExpeditions or {}) do if trip.SlotId then assigned[trip.SlotId]=trip end;if trip.ReadyAt<=os.time() then count+=1 end end
 if #(data.GardenExpeditions or {})>0 then
  local c=card(ctx,64,'ClaimAllCard');local claim=button(c,'CLAIM ALL',10,function()act(ctx,'ClaimAllExpeditions',{})end,nil,'ClaimAll')
  timers[#timers+1]=function(now)local ready=0;for _,trip in ipairs(data.GardenExpeditions or {})do if trip.ReadyAt<=now then ready+=1 end end;if claim.Parent then claim.Text='CLAIM ALL • '..ready..' ready';W.Disabled(claim,ready==0)end end
 end
 local grid=W.New("Frame",{Name="ExpeditionCards",Size=UDim2.new(1,-8,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1},ctx.Content)
 if ctx.Short then W.List(grid)else W.Grid(grid,math.max(260,math.floor(ctx.Content.AbsoluteSize.X/3)-20),#(data.GardenExpeditions or {})>0 and 278 or 142,12)end;ctx.GardenBody=grid
 for i=1,3 do
  local trip=assigned[i];local c=card(ctx,ctx.Short and(trip and 136 or 62)or(trip and 278 or 142),"ForageSlotCard_"..i)
  if ctx.Short then
   text(c,"SLOT "..i,8,23,12,green)
   if not trip then
    text(c,"Choose a companion to forage here.",31,23,14,ink,12,.68)
    local send=button(c,"+ SEND PET",8,function()M.Flow="Pets";M.Page=1;redraw(ctx)end,nil,"SendPet_"..i);send.Size=UDim2.new(.3,-14,0,44);send.Position=UDim2.new(.7,0,0,8)
   else
    local owned=pet(data,trip.UID);local def=Pets[trip.PetId]
    if owned then viewport(c,owned,UDim2.fromOffset(68,76),UDim2.fromOffset(10,34))end
    text(c,def and def.DisplayName or "Companion",8,30,17,ink,92,.7)
    local timer=text(c,"",43,28,16,green,92,.7)
    local duration=G.Durations[trip.DurationId]
    text(c,(duration and duration.DisplayName or "Expedition").." • "..(def and def.Rarity or ""),75,23,12,green,92,.7)
    local values={};for _,cropId in ipairs(G.CropNames)do table.insert(values,G.Crops[cropId].Icon.." "..tostring((trip.PendingCrops or {})[cropId]or 0))end
    text(c,table.concat(values,"   "),104,22,12,ink,92,.7)
    local b=button(c,os.time()>=trip.ReadyAt and "CLAIM"or "RECALL",45,function()if os.time()>=trip.ReadyAt then act(ctx,"ClaimExpedition",{UID=trip.UID})else M.RecallUID=trip.UID;M.Flow="Recall";redraw(ctx)end end,green,"TripAction_"..i);b.Size=UDim2.new(.3,-14,0,44);b.Position=UDim2.new(.7,0,0,45)
    timers[#timers+1]=function(now)if not timer.Parent then return end;timer.Text=now>=trip.ReadyAt and "READY TO HARVEST"or clock(trip.ReadyAt-now);if not b:GetAttribute("Pending")then b.Text=now>=trip.ReadyAt and "CLAIM"or "RECALL"end end
   end
   continue
  end
  text(c,"SLOT "..i,9,24,13,green)
  if not trip then
   text(c,"Fresh soil, growing crops, a place for your pet.",36,42,14)
   button(c,"+ SEND PET",85,function()M.Flow="Pets";M.Page=1;redraw(ctx)end,nil,"SendPet_"..i)
  else
   local owned=pet(data,trip.UID);local def=Pets[trip.PetId]
   if owned then viewport(c,owned,UDim2.fromOffset(84,84),UDim2.fromOffset(8,37)) end
   text(c,def and def.DisplayName or trip.PetId,37,44,17,ink,100)
   text(c,(def and def.Rarity or "").."  •  "..string.format("%.1fx",trip.Power or 1),80,30,13,green,100)
   local duration=G.Durations[trip.DurationId]
   text(c,duration and duration.DisplayName or "Garden expedition",119,25,14)
   local timer=text(c,"",145,25,18,green)
   local track=W.New("Frame",{Position=UDim2.fromOffset(12,173),Size=UDim2.new(1,-24,0,7),BackgroundColor3=Color3.fromRGB(221,226,191),BorderSizePixel=0},c);W.Round(track,4)
   local fill=W.New("Frame",{Size=UDim2.fromScale(0,1),BackgroundColor3=green,BorderSizePixel=0},track);W.Round(fill,4)
   timers[#timers+1]=function(now) if not timer.Parent then return end;timer.Text=now>=trip.ReadyAt and "READY TO HARVEST" or clock(trip.ReadyAt-now);fill.Size=UDim2.fromScale(math.clamp((now-trip.StartedAt)/trip.Duration,0,1),1) end
   baskets(c,trip,182)
   local ready=os.time()>=trip.ReadyAt
   local b=button(c,ready and "CLAIM" or "RECALL",224,function()
    if os.time()>=trip.ReadyAt then act(ctx,"ClaimExpedition",{UID=trip.UID}) else
     M.RecallUID=trip.UID;M.Flow="Recall";redraw(ctx)
    end
   end,ready and green or berry,"TripAction_"..i)
   timers[#timers+1]=function(now) if b.Parent and not b:GetAttribute("Pending") then b.Text=now>=trip.ReadyAt and "CLAIM" or "RECALL" end end
  end
 end
 ctx.GardenBody=nil
end
local function selectPets(ctx,style)
 local data=ctx.Data;local all={};for _,p in ipairs(data.Pets or {})do if style or not reason(data,p) then table.insert(all,p)end end;local pages=math.max(1,math.ceil(#all/10));M.Page=math.clamp(M.Page,1,pages)
 local top=card(ctx,116,"SelectPetTitle");text(top,style and "CHOOSE A PET TO STYLE" or "1  •  SELECT PET",10,30,18,green);button(top,"BACK",57,function()M.Flow=nil;redraw(ctx)end,W.Color.Muted,"Back")
 if #all==0 then W.Empty(ctx.Content,'No eligible Inventory pets','Use STORE on a Held pet in Pets, and unlock it before sending it here.');return end
 for i=(M.Page-1)*10+1,math.min(M.Page*10,#all) do
  local p=all[i];local def=Pets[p.PetId];local why=not style and reason(data,p)
  local c=card(ctx,150,"PetChoice_"..p.UID)
  local _,real=viewport(c,p,UDim2.fromOffset(72,82),UDim2.fromOffset(8,8))
  if not real and not style then why=why or "REAL MODEL UNAVAILABLE" end
  text(c,def and def.DisplayName or p.PetId,10,46,16,why and W.Color.Muted or ink,88)
  text(c,(def and def.Rarity or "").."  •  Level "..p.Level,58,27,12,green,88)
  button(c,why or (style and "WEAR "..(M.Cosmetic=="None" and "NO COSMETIC" or G.Cosmetics[M.Cosmetic].DisplayName) or "SELECT"),94,function()
   if why then ctx.Notify(why=="EQUIPPED" and "Unequip this pet first." or why);return end
   if style then act(ctx,"EquipGardenCosmetic",{UID=p.UID,CosmeticId=M.Cosmetic});M.Flow=nil else M.UID=p.UID;M.Flow="Trips" end;redraw(ctx)
  end,why and W.Color.Muted or green,"Choose_"..p.UID)
 end
 local pager=card(ctx,108,"PetPages");text(pager,(style and "All owned pets • Page " or "Eligible Inventory pets • Page ")..M.Page.." / "..pages,6,30,14)
 tabs(pager,{"PREVIOUS","NEXT"},"",48,function(name)M.Page=math.clamp(M.Page+(name=="NEXT" and 1 or -1),1,pages);ctx.Content.CanvasPosition=Vector2.zero;redraw(ctx)end)
end
local function trips(ctx)
 local c=card(ctx,104,"ChooseTrip");text(c,"2  •  SELECT EXPEDITION",8,30,18,green);button(c,"BACK",48,function()back(ctx)end,W.Color.Muted,"Back")
 for _,id in ipairs(G.DurationOrder) do local d=G.Durations[id];local row=card(ctx,143,id);text(row,d.DisplayName,10,28,19);text(row,d.Label.."  •  More time, more harvest cycles",40,40,13);button(row,"CHOOSE "..string.upper(d.DisplayName),88,function()M.Duration=id;M.Flow="Confirm";redraw(ctx)end) end
end
local function confirm(ctx)
 local p=pet(ctx.Data,M.UID);if not p then M.Flow="Pets";selectPets(ctx);return end
 local d=G.Durations[M.Duration];local def=Pets[p.PetId]
 local now=os.time();local trip={UID=p.UID,TripId="preview",StartedAt=now,ReadyAt=now+d.Seconds,Duration=d.Seconds}
 P.Initialize(trip,p,ctx.Data,1);P.Advance(trip,trip.ReadyAt)
 local c=card(ctx,427,"SendConfirmation");text(c,"3  •  READY TO FORAGE?",8,30,18,green)
 viewport(c,p,UDim2.fromOffset(100,100),UDim2.fromOffset(10,42))
 text(c,def.DisplayName,47,46,18,ink,122);text(c,def.Rarity,95,28,14,green,122)
 text(c,string.format("Garden Power: %.1fx",P.Power(p)),150,30,19,green)
 text(c,d.DisplayName.."  •  "..d.Label,185,28,17)
 text(c,"Estimated Harvest: "..math.floor(trip.PendingHarvest+1e-7),222,30,18)
 text(c,"Possible rare crops: Starberry & Moonmelon\nYour pet keeps foraging while you are away.",255,54,14)
 button(c,"SEND TO GARDEN",317,function()act(ctx,"StartExpedition",{UID=M.UID,DurationId=M.Duration});M.Flow=nil;redraw(ctx)end,nil,"ConfirmSend")
 button(c,"BACK",369,function()back(ctx)end,W.Color.Muted,"Back")
end
local function crops(ctx)
 for _,id in ipairs(G.CropNames) do local d=G.Crops[id];local c=card(ctx,116,"CropTotal_"..id);text(c,d.Icon.."  "..string.upper(id),10,30,20,d.Color);text(c,d.Rarity,43,22,12);text(c,tostring((ctx.Data.GardenCrops or {})[id] or 0).." collected",70,32,22,green) end
end
local function shop(ctx)
 local sub=card(ctx,60,"ShopTabs");tabs(sub,{"SUPPLIES","UPGRADES","COSMETICS"},M.Shop,8,function(name)M.Shop=name;redraw(ctx)end)
 local order=M.Shop=="SUPPLIES" and G.SupplyOrder or M.Shop=="UPGRADES" and G.UpgradeOrder or G.CosmeticOrder
 for _,id in ipairs(order) do
  local defs=M.Shop=="SUPPLIES" and G.Supplies or M.Shop=="UPGRADES" and G.Upgrades or G.Cosmetics;local d=defs[id]
  local c=card(ctx,200,"Shop_"..id);text(c,d.DisplayName,10,37,19,green);text(c,d.Description,48,40,14)
  if M.Shop=="SUPPLIES" then
   local info=text(c,"",91,40,13)
   timers[#timers+1]=function(now) if info.Parent then local remaining=(ctx.Data.GardenBoosts[id] or 0)-now;info.Text=d.Cost.." Harvest • "..math.floor(d.Seconds/60).." minutes"..(remaining>0 and ("\nActive: "..clock(remaining).." • Buy to extend") or "") end end
   button(c,"BUY & ACTIVATE",145,function()act(ctx,"BuyGardenSupply",{Id=id})end,nil,"BuySupply_"..id)
  elseif M.Shop=="UPGRADES" then
   local level=ctx.Data.GardenUpgrades[id] or 0;local price=G.UpgradePrices[level+1]
   text(c,"Level "..level.." / 5   •   Current: "..(d.Base+d.Step*level).." "..d.Unit..(price and ("\nNext: "..(d.Base+d.Step*(level+1)).." "..d.Unit.."   •   "..price.." Harvest") or "\nFully upgraded"),91,44,14)
   button(c,price and "UPGRADE" or "MAX LEVEL",145,function()if price then act(ctx,"UpgradeGarden",{Id=id})end end,price and green or W.Color.Muted,"Upgrade_"..id)
  else
   local owned=ctx.Data.GardenCosmetics[id];text(c,owned and "OWNED • Available for all your pets" or d.Cost.." Harvest • Account-wide",94,36,14)
   button(c,owned and "CHOOSE PET TO WEAR" or "BUY COSMETIC",145,function()if owned then M.Cosmetic=id;M.Flow="Style";M.Page=1;redraw(ctx) else act(ctx,"BuyGardenCosmetic",{Id=id}) end end,nil,"Cosmetic_"..id)
  end
 end
 if M.Shop=="COSMETICS" then local c=card(ctx,66,"RemoveCosmetic");button(c,"REMOVE A PET'S COSMETIC",10,function()M.Cosmetic="None";M.Flow="Style";M.Page=1;redraw(ctx)end,W.Color.Muted) end
end
local function boosts(ctx)
 local active={};for _,id in ipairs(G.SupplyOrder)do if (ctx.Data.GardenBoosts[id] or 0)>os.time() then table.insert(active,id)end end
 if #active==0 then return end
 local c=card(ctx,44+22*#active,'ActiveBoosts')
 text(c,'ACTIVE SUPPLIES',6,26,14,green)
 for i,id in ipairs(active)do
  local label=text(c,'',28+(i-1)*22,22,12)
  timers[#timers+1]=function(now)if label.Parent then label.Text=G.Supplies[id].DisplayName..' • '..clock((ctx.Data.GardenBoosts[id] or 0)-now)end end
 end
end
function M.Render(ctx)
 ctxNow=ctx;ctx.GardenBody=nil;timers={};selection={};W.List(ctx.Content);header(ctx);if not M.Flow then boosts(ctx)end
 if M.Flow=="Pets" then selectPets(ctx)
 elseif M.Flow=="Trips" then trips(ctx)
 elseif M.Flow=="Confirm" then confirm(ctx)
 elseif M.Flow=="Style" then selectPets(ctx,true)
 elseif M.Flow=="Recall" then
  local c=card(ctx,218,"RecallConfirmation");text(c,"RECALL THIS PET?",10,30,19,berry);text(c,"Receive half of its earned progress so far. Completed trips can be claimed for their full harvest.",49,60,14)
  button(c,"RECALL PET",115,function()act(ctx,"CancelExpedition",{UID=M.RecallUID});M.Flow=nil;redraw(ctx)end,berry,"ConfirmRecall");button(c,"KEEP FORAGING",165,function()M.Flow=nil;redraw(ctx)end,nil,"KeepForaging")
 elseif M.Tab=="EXPEDITIONS" then expeditions(ctx)
 elseif M.Tab=="CROPS" then crops(ctx)
 elseif M.Tab=="SHOP" then shop(ctx)
 end
 for i,b in ipairs(selection) do b.NextSelectionUp=selection[i-1] or selection[#selection];b.NextSelectionDown=selection[i+1] or selection[1] end
 local now=workspace:GetServerTimeNow();for _,update in ipairs(timers) do update(now) end
 if not ctx.GardenConfirmOverlay and (Input:GetLastInputType().Name:find("Gamepad") or ctx.SelectedName) then task.defer(function() if ctx.ActiveName=="Garden" then local chosen=M.Flow and selection[6] or selection[1];for _,b in ipairs(selection) do if b.Name==ctx.SelectedName then chosen=b;break end end;Gui.SelectedObject=chosen end end) end
end
local elapsed=0
local heartbeat=Run.Heartbeat:Connect(function(dt)elapsed+=dt;if elapsed<.25 then return end;elapsed=0;if ctxNow and ctxNow.ActiveName=="Garden" then for _,update in ipairs(timers) do update(workspace:GetServerTimeNow()) end end end)
script.Destroying:Once(function()heartbeat:Disconnect();M.Close()end)
return M
