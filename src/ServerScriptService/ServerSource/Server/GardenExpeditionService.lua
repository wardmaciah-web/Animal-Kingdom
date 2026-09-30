local RS=game:GetService("ReplicatedStorage")
local Players=game:GetService("Players")
local Http=game:GetService("HttpService")
local Knit=require(RS.Packages.Knit)
local Garden=require(RS.Shared.Gameplay.Definitions.GardenDefinitions)
local Progress=require(RS.Shared.Gameplay.GardenProgress)
local PetDefs=require(RS.Shared.Gameplay.Definitions.PetDefinitions)
local Variants=require(RS.Shared.Gameplay.Definitions.VariantDefinitions)
local PetMath=require(RS.Shared.Gameplay.PetMath)
local Locations=require(RS.Shared.Gameplay.PetLocations)
local Appearance=require(RS.Shared.Gameplay.PetAppearance)
local Guard=require(script.Parent.Parent.Utilities.GameplayGuard)
local Runtime=require(script.Parent.Parent.Utilities.GardenPlotRuntime)
local Teleports=require(game:GetService("ServerScriptService").AdminCommandCenter.Teleports)
local Signal=require(RS.Packages.Signal)
local Service=Knit.CreateService({Name="GardenExpeditionService",Client={},Settled=Signal.new()})
local Data
local returnSpots,locks,receipts,connections={},{},{},{}
local REALM_CENTER=Garden.RealmCenter
local function find(data,uid)
 for i,trip in ipairs(data.GardenExpeditions) do if trip.UID==uid then return trip,i end end
end
local function petFor(data,uid) return Knit.GetService("PetService"):FindOwned(data,uid) end
local function realModel(pet)
 local ok,model=pcall(Appearance.Create,pet)
 if not ok or not model then return false end
 local valid=not model:GetAttribute("Placeholder") and model:FindFirstChildWhichIsA("BasePart",true)~=nil
 model:Destroy();return valid
end
function Service:Transaction(player,requestId,operation,callback)
 if not Guard.IsPlayer(player) then return false,"Invalid player" end
 if locks[player] then return false,"Garden action already in progress" end
 local cache=receipts[player] or {};receipts[player]=cache
 local key=requestId and tostring(requestId)
 if key then
  local old=cache[key];if old then return false,"This Garden request was already processed." end
 end
 if not Data:Get(player) then return false,"Profile is loading" end
 locks[player]=true
 local ok,success,result=xpcall(function()return Knit.GetService("PetService"):Transaction(player,callback)end,debug.traceback)
 locks[player]=nil
 if key then
  for k,v in pairs(cache) do if os.clock()-v.At>120 then cache[k]=nil end end
  cache[key]={At=os.clock(),Operation=operation}
 end
 if not ok then warn("[Garden] "..operation..": "..tostring(success));return false,"Garden action unavailable; please try again" end
 return success,result
end
function Service:Process(player,now,publish)
 local data=Data:Get(player);if not data then return end
 local used={};local changed=false
 for _,trip in ipairs(data.GardenExpeditions) do
  local pet=petFor(data,trip.UID)
  if pet then
   local slot=trip.SlotId
   if type(slot)~="number" or slot<1 or slot>3 or used[slot] then
    slot=nil;for i=1,3 do if not used[i] then slot=i;break end end
   end
   if slot then used[slot]=true end
   Progress.Initialize(trip,pet,data,slot);trip.SlotId=slot
   changed=Progress.Advance(trip,now) or changed
  end
 end
 if changed and publish then Data:Publish(player,"GardenExpeditions") end
 Runtime.Sync(player,data,now)
 return data
end
function Service:Start(player,uid,durationId,requestId)
 return self:Transaction(player,requestId,"Send",function()
  if not Guard.Id(uid) or not Garden.Durations[durationId] then return false,"Invalid expedition" end
  local data=Data:Get(player);local pet=petFor(data,uid)
  if not pet or not PetDefs[pet.PetId] then return false,"Pet unavailable" end
  if find(data,uid) then return false,"This pet is already foraging." end
  if #data.GardenExpeditions>=3 then return false,"All three forage slots are occupied." end
  if pet.Location~="Inventory" then return false,"Move this pet to normal Inventory before sending it." end
  if pet.Locked then return false,"Unlock this pet before sending it." end
  if not realModel(pet) then return false,"This pet's real model is not available for Garden yet." end
  if not Runtime.Assign(player) then return false,"Your Garden plot is being assigned." end
  local used={};for _,t in ipairs(data.GardenExpeditions) do used[t.SlotId]=true end
  local slot;for i=1,3 do if not used[i] then slot=i;break end end
  local duration=Garden.Durations[durationId];local now=os.time()
  local trip={TripId=Http:GenerateGUID(false),UID=uid,PetId=pet.PetId,DurationId=durationId,Duration=duration.Seconds,StartedAt=now,ReadyAt=now+duration.Seconds}
  local _,kingdom=require(RS.Shared.Gameplay.KingdomProgress).Ensure(data)
  if kingdom.Fertilizer>0 then trip.KingdomFertilizer=1.15 end
  Progress.Initialize(trip,pet,data,slot);table.insert(data.GardenExpeditions,trip)
  if trip.KingdomFertilizer then kingdom.Fertilizer-=1;Data:Publish(player,'KingdomShop')end
  Locations.Set(pet,"Garden",slot);Knit.GetService("PetService"):Publish(player)
  Data:Publish(player,"GardenExpeditions");Runtime.Sync(player,data,now)
  return true,{Kind="GardenStarted",PetId=pet.PetId,DisplayName=PetDefs[pet.PetId].DisplayName,DurationLabel=duration.DisplayName,SlotId=slot}
 end)
end
local function grantXP(pet,amount)
 if pet.Level>=Variants.MaxLevel then return end
 pet.XP+=amount
 while pet.Level<Variants.MaxLevel and pet.XP>=PetMath.RequiredXP(pet.Level) do pet.XP-=PetMath.RequiredXP(pet.Level);pet.Level+=1 end
 if pet.Level>=Variants.MaxLevel then pet.XP=0 end
end
function Service:Settle(player,uid,recall)
 local data=Data:Get(player);local trip,index=find(data,uid)
 if not trip then return false,"That expedition was already claimed or recalled." end
 local now=os.time()
 if recall and now>=trip.ReadyAt then return false,"This trip is complete. Claim its full harvest." end
 if not recall and now<trip.ReadyAt then return false,"This pet is still foraging." end
 local pet=petFor(data,uid);if not pet then return false,"Saved pet is unavailable; expedition retained." end
 Progress.Initialize(trip,pet,data,trip.SlotId);Progress.Advance(trip,now)
 local factor=recall and .5 or 1
 local crops=Progress.EmptyCrops();for _,id in ipairs(Garden.CropNames) do crops[id]=math.floor(trip.PendingCrops[id]*factor) end
 local amount=math.floor(trip.PendingHarvest*factor+1e-7)
 local xp=math.floor(trip.PendingXP*factor+1e-7)
 local canCredit,creditWhy=Knit.GetService('EconomyService'):CanReceive(player,{[Garden.Currency]=amount})
 if not canCredit then return false,creditWhy end
 for id,n in pairs(crops)do if data.GardenCrops[id]+n>9e15 then return false,'Make room for the full crop harvest before settling this expedition.'end end
 -- Everything below is synchronous under one action lock. Removing the trip is the claim receipt.
 table.remove(data.GardenExpeditions,index)
 Locations.Set(pet,"Inventory")
 for id,n in pairs(crops) do data.GardenCrops[id]+=n end
 if amount>0 then local _,credited=Knit.GetService("EconomyService"):Add(player,Garden.Currency,amount,recall and "GardenRecall" or "Garden");amount=credited or 0 end
 grantXP(pet,xp);Knit.GetService("PetService"):Publish(player)
 Data:Publish(player,"GardenCrops","GardenExpeditions");Runtime.Sync(player,data,now)
 if not recall then self.Settled:Fire(player,trip.TripId,pet.UID)end
 return true,{Kind=recall and "GardenRecall" or "GardenClaim",Amount=amount,Crops=Progress.Breakdown(crops),PetId=pet.PetId,XP=xp,TripId=trip.TripId}
end
function Service:Claim(player,uid,requestId) return self:Transaction(player,requestId,"Claim",function() return self:Settle(player,uid,false) end) end
function Service:Cancel(player,uid,requestId) return self:Transaction(player,requestId,"Recall",function() return self:Settle(player,uid,true) end) end
function Service:ClaimAll(player,requestId)
 return self:Transaction(player,requestId,"ClaimAll",function()
  local ready={};for _,trip in ipairs(Data:Get(player).GardenExpeditions) do if trip.ReadyAt<=os.time() then table.insert(ready,trip.UID) end end
  if #ready==0 then return false,"No finished expeditions to claim." end
  local result={Kind="GardenClaimAll",Amount=0,Claims={}};local crops=Progress.EmptyCrops()
  for _,uid in ipairs(ready) do local ok,claim=self:Settle(player,uid,false);if ok then result.Amount+=claim.Amount;table.insert(result.Claims,claim);for _,c in ipairs(claim.Crops) do crops[c.Name]+=c.Amount end end end
  if #result.Claims==0 then return false,"No claimable expeditions; saved trips retained." end
  result.Crops=Progress.Breakdown(crops);return true,result
 end)
end
function Service:BuySupply(player,id,requestId)
 return self:Transaction(player,requestId,"BuySupply",function()
  local def=Garden.Supplies[id];if not def then return false,"Unknown Garden supply" end
  local data=Data:Get(player);local now=os.time()
  local expires=data.GardenBoosts[id] or 0
  if expires-now>=86400 then return false,"This boost already has a full day's supply." end
  if not Knit.GetService("EconomyService"):CanAfford(player,Garden.Currency,def.Cost) then return false,"Not enough Harvest." end
  self:Process(player,now,false)
  if not Knit.GetService("EconomyService"):Spend(player,Garden.Currency,def.Cost,"GardenSupply") then return false,"Not enough Harvest." end
  data.GardenBoosts[id]=math.max(now,expires)+def.Seconds
  for _,trip in ipairs(data.GardenExpeditions) do trip.Boosts=table.clone(data.GardenBoosts) end
  Data:Publish(player,"GardenBoosts","GardenExpeditions");Runtime.Sync(player,data,now)
  return true,def.DisplayName.." active! Reusing it extends the timer."
 end)
end
function Service:Upgrade(player,id,requestId)
 return self:Transaction(player,requestId,"Upgrade",function()
  local def=Garden.Upgrades[id];if not def then return false,"Unknown Garden upgrade" end
  local data=Data:Get(player);local level=data.GardenUpgrades[id] or 0
  if level>=5 then return false,"Already at maximum level." end
  local cost=Garden.UpgradePrices[level+1];local economy=Knit.GetService("EconomyService")
  if not economy:CanAfford(player,Garden.Currency,cost) then return false,"Not enough Harvest." end
  self:Process(player,os.time(),false)
  if not economy:Spend(player,Garden.Currency,cost,"GardenUpgrade") then return false,"Not enough Harvest." end
  data.GardenUpgrades[id]=level+1
  for _,trip in ipairs(data.GardenExpeditions) do trip.Upgrades=table.clone(data.GardenUpgrades) end
  Data:Publish(player,"GardenUpgrades","GardenExpeditions");Runtime.Sync(player,data,os.time())
  return true,def.DisplayName.." upgraded to level "..(level+1).."!"
 end)
end
function Service:BuyCosmetic(player,id,requestId)
 return self:Transaction(player,requestId,"BuyCosmetic",function()
  local def=Garden.Cosmetics[id];if not def then return false,"Unknown cosmetic" end
  local data=Data:Get(player);if data.GardenCosmetics[id] then return false,"Already owned" end
  if not Knit.GetService("EconomyService"):Spend(player,Garden.Currency,def.Cost,"GardenCosmetic") then return false,"Not enough Harvest." end
  data.GardenCosmetics[id]=true;Data:Publish(player,"GardenCosmetics");return true,def.DisplayName.." unlocked!"
 end)
end
function Service:EquipCosmetic(player,uid,id,requestId)
 return self:Transaction(player,requestId,"EquipCosmetic",function()
  local data=Data:Get(player);local pet=petFor(data,uid);if not pet then return false,"Pet unavailable" end
  if id~="None" and (not Garden.Cosmetics[id] or not data.GardenCosmetics[id]) then return false,"Unlock this cosmetic first." end
  pet.Cosmetic=id~="None" and id or nil;Knit.GetService("PetService"):Publish(player);Runtime.Sync(player,data,os.time());return true,"Garden style updated!"
 end)
end
local function facingGarden(position: Vector3): CFrame
 local direction=REALM_CENTER-position
 direction=Vector3.new(direction.X,0,direction.Z)
 if direction.Magnitude<0.01 then direction=Vector3.new(0,0,-1) end
 return CFrame.lookAt(position,position+direction)
end

function Service:VisitGarden(player: Player): (boolean, any)
 if not Guard.IsPlayer(player) then return false, "Invalid request" end
 local root = Guard.Alive(player)
 if not root then return false, "Respawn first" end
 local realm = workspace:FindFirstChild("PetGardenRealm")
 if not realm then return false, "Garden is unavailable" end
 if (root.Position - REALM_CENTER).Magnitude < 220 then return false, "You are already in the garden." end
 if locks[player] then return false, "Please wait a moment" end
 local returnSpot = root.CFrame
 local ownPlot = Runtime.Assign(player)
 local marker = ownPlot and ownPlot:FindFirstChild("PlotSign")
 local moved=false
 if marker and marker:IsA("BasePart") then
  -- The approach follows the authored bed's orientation. A rotated sign face
  -- does not move the player to the opposite side of its path.
  local soil=ownPlot:FindFirstChild("SoilBase")
  local orientation=soil and soil:IsA("BasePart") and soil.CFrame.Rotation or marker.CFrame.Rotation
  local approach=marker.Position+orientation:VectorToWorldSpace(Vector3.new(7,2,5))
  moved=Teleports.Near(player,facingGarden(approach))
 end
 if not moved then
  local arrival=realm:FindFirstChild("GardenArrival",true)
  local position=arrival and arrival:IsA("BasePart") and arrival.Position or REALM_CENTER+Vector3.new(0,2,48)
  moved=Teleports.Near(player,facingGarden(position))
 end
 if not moved then return false,"There is no clear Garden landing spot. Stand up and try again." end
 returnSpots[player] = returnSpot
 player:SetAttribute("InGarden",true)
 print("[Garden] Visit", player.Name)
 return true, { Kind = "GardenVisit" }
end

-- Called only after a different authoritative travel path successfully lands outside Garden.
function Service:LeaveGarden(player)
 returnSpots[player]=nil;player:SetAttribute('InGarden',false)
end

function Service:ReturnToKingdom(player: Player): (boolean, any)
 if not Guard.IsPlayer(player) then return false, "Invalid request" end
 local root = Guard.Alive(player)
 if not root then return false, "Respawn first" end
 local saved = returnSpots[player]
 local moved=false
 if saved then
  local pos = saved.Position
  if (pos - REALM_CENTER).Magnitude > 220 and math.abs(pos.Y) < 600 and pos.Magnitude < 12000 then
   moved=Teleports.Near(player,saved)
  end
 end
 if not moved then
  local plot = Knit.GetService("PlotService"):GetPlot(player)
  if plot then
   for _,name in ipairs({"PlotSpawn","PlayerSpawn","SpawnPoint","Spawn","SpawnLocation"}) do
    local spawnPart=plot:FindFirstChild(name,true)
    if spawnPart and spawnPart:IsA("BasePart") and Teleports.Near(player,spawnPart.CFrame) then moved=true;break end
   end
  end
 end
 if not moved then
  local markers=workspace:FindFirstChild("BiomeTeleportPoints")
  local meadow=markers and markers:FindFirstChild("Meadow")
  if meadow and meadow:IsA("BasePart") then moved=Teleports.Near(player,meadow.CFrame) end
 end
 if not moved then
  local anySpawn=workspace:FindFirstChildWhichIsA("SpawnLocation",true)
  if anySpawn and (anySpawn.Position-REALM_CENTER).Magnitude>220 then moved=Teleports.Near(player,anySpawn.CFrame) end
 end
 if not moved then return false,"There is no clear return landing spot. Stand up and try again." end
 -- A failed attempt retains the original return location and Garden state.
 self:LeaveGarden(player)
 print("[Garden] Return", player.Name)
 return true, { Kind = "GardenReturn" }
end


function Service:KnitInit() Data=Knit.GetService("PlayerDataService") end
function Service:KnitStart()
 local layoutOK,layoutError=pcall(Runtime.Prepare)
 if not layoutOK then Runtime.Plots={};warn("[Garden] Layout unavailable: "..tostring(layoutError)) end
 local profiles=Knit.GetService("ProfileService")
 local function loaded(player,data)
  Progress.Migrate(data)
  if connections[player] then connections[player]:Disconnect() end
  connections[player]=player:GetAttributeChangedSignal("PlotId"):Connect(function() Runtime.Release(player);Runtime.Assign(player);Runtime.Sync(player,data,os.time()) end)
  self:Process(player,os.time(),true);Data:Publish(player,"GardenCrops","GardenUpgrades","GardenBoosts","GardenExpeditions")
 end
 profiles.Loaded:Connect(loaded)
 profiles.Releasing:Connect(function(player)
  -- Profile-ready is already cleared here; Data:Get still returns the active session until release.
  self:Process(player,os.time(),false);Runtime.Release(player)
  if connections[player] then connections[player]:Disconnect();connections[player]=nil end
  returnSpots[player]=nil;locks[player]=nil;receipts[player]=nil
 end)
 for player,profile in pairs(profiles.Profiles) do if player:GetAttribute("ProfileReady") then loaded(player,profile.Data) end end
 task.spawn(function()
  while task.wait(1) do
   for player in pairs(profiles.Profiles) do
    if player:GetAttribute("ProfileReady") and not locks[player] then
     local ok,err=xpcall(function() self:Process(player,os.time(),true) end,debug.traceback)
     if not ok then warn("[Garden] Scheduler "..player.Name..": "..tostring(err)) end
    end
   end
  end
 end)
end
return Service
