-- Guidance state only. Existing services own travel, pets, placement and money.
local RS=game:GetService('ReplicatedStorage')
local Players=game:GetService('Players')
local Paths=game:GetService('PathfindingService')
local Http=game:GetService('HttpService')
local Knit=require(RS.Packages.Knit)
local Locations=require(RS.Shared.Gameplay.PetLocations)
local Trees=require(RS.Shared.Gameplay.Definitions.MeadowTreeDefinitions)
local Models=require(RS.Shared.Gameplay.PetModelResolver)
local Readiness=require(script.Parent.Parent.Utilities.MeadowPoolReadiness)
local Pools=require(script.Parent.Parent.Utilities.RewardPoolValidation)
local Display=require(script.Parent.Parent.Utilities.MeadowSanctuaryDisplay)
local Guard=require(script.Parent.Parent.Utilities.GameplayGuard)
local Service=Knit.CreateService({Name='TutorialService',Client={}})
local Data
local sessions={}
local rng=Random.new()
local function state(player)
 local s=sessions[player]
 if not s then
  local target=player:FindFirstChild('TutorialTreeTarget') or Instance.new('ObjectValue')
  target.Name='TutorialTreeTarget';target.Parent=player
  s={Target=target,Resuming=true};sessions[player]=s
 end
 return s
end
function Service:Publish(player)
 Data:Publish(player,'TutorialProgress','TutorialCompleted')
 Knit.GetService('PetService'):RequestSave(player)
end
function Service:Normalize(data)
 local p=data.TutorialProgress
 if p.FlowVersion~=2 then
  p.LegacyStep=p.LegacyStep or p.Step
  p.Step=1;p.FlowVersion=2;p.PetUID=nil;p.SlotId=nil;p.RevealReadyAt=nil
 end
 p.Step=math.clamp(math.floor(tonumber(p.Step) or 1),1,6)
 return p
end
function Service:ValidTree(player,object)
 local record=Knit.GetService('ResourceService'):GetRecords()[object]
 if not record or record.Biome~='Meadow' or not record.IsTree or record.State~='AVAILABLE' or not object:IsDescendantOf(workspace) or not record.Prompt.Parent or not record.Prompt.Enabled then return false end
 local def=Trees.Get(object,'Meadow')
 -- The first search must be the canonical starter family, even when other
 -- Meadow trees are reachable. New profiles can afford exactly this price.
 if not def or def.Id~=Trees.Ordered[1].Id or not Pools.Check(def) or not Readiness.Check(def,player) then return false end
 local floor=Knit.GetService('BiomeService'):GetFloor('Meadow');if not floor then return false end
 local p=floor.CFrame:PointToObjectSpace(record.InteractionPosition)
 return math.abs(p.X)<floor.Size.X/2 and math.abs(p.Z)<floor.Size.Z/2 and math.abs(p.Y)<18,record
end
function Service:ChooseTree(player)
 local s=state(player)
 if s.Target.Value and self:ValidTree(player,s.Target.Value) then return end
 s.Target.Value=nil
 if s.Choosing or os.clock()<(s.RetryAt or 0) then return end
 local root=Guard.Alive(player);if not root then return end
 s.Choosing=true;s.RetryAt=os.clock()+3
 task.spawn(function()
  local candidates={}
  for object in pairs(Knit.GetService('ResourceService'):GetRecords())do if self:ValidTree(player,object) then candidates[#candidates+1]=object end end
  for i=#candidates,2,-1 do local j=rng:NextInteger(1,i);candidates[i],candidates[j]=candidates[j],candidates[i]end
  for _,object in ipairs(candidates)do
   local data=Data:Get(player);root=Guard.Alive(player)
   if not data or data.TutorialCompleted or data.TutorialProgress.Step~=2 or data.TutorialProgress.PetUID or not root then break end
   local valid,record=self:ValidTree(player,object)
   if valid then
    -- A supported approach within the real prompt radius must have a navigation path.
    local delta=Vector3.new(root.Position.X-record.InteractionPosition.X,0,root.Position.Z-record.InteractionPosition.Z)
    local approach=record.InteractionPosition+(delta.Magnitude>.1 and delta.Unit or Vector3.zAxis)*6
    local ray=workspace:Raycast(approach+Vector3.new(0,8,0),Vector3.new(0,-30,0))
    if ray then
     local path=Paths:CreatePath({AgentRadius=2,AgentHeight=5,AgentCanJump=true})
     local ok=pcall(function()path:ComputeAsync(root.Position,ray.Position+Vector3.new(0,2,0))end)
     local reachable=ok and path.Status==Enum.PathStatus.Success;path:Destroy()
     data=Data:Get(player)
     if reachable and sessions[player]==s and data and data.TutorialProgress.Step==2 and not data.TutorialProgress.PetUID and self:ValidTree(player,object) then s.Target.Value=object;break end
    end
   end
  end
  s.Choosing=false
 end)
end
local function usable(pet)return pet and pet.Location~='Garden' and Models.Resolve(pet.PetId)~=nil end
function Service:Reconcile(player,resuming)
 local data=Data:Get(player);if not data then return end
 local s=state(player)
 if resuming then s.Resuming=true end
 if data.TutorialCompleted then s.Target.Value=nil;return end
 local before=Http:JSONEncode(data.TutorialProgress)
 local p=self:Normalize(data);local root=Guard.Alive(player)
 if not root or not Knit.GetService('PlotService'):GetPlot(player) then
  if Http:JSONEncode(p)~=before then self:Publish(player)end
  return
 end
 resuming=s.Resuming;s.Resuming=nil
 local inMeadow=Knit.GetService('BiomeService'):AtPosition(root.Position)=='Meadow' and Knit.GetService('BiomeService'):IsUnlocked(player,'Meadow') and not player:GetAttribute('InGarden')
 if p.Step==1 and inMeadow then p.Step=2 end
 local pet=Locations.Find(data,p.PetUID)
 if p.Step==2 then
  if pet and resuming then p.Step=3;p.RevealReadyAt=nil
  elseif not pet then
   p.PetUID=nil
   -- Replay/recovery can reuse an owned companion when another paid search is unaffordable.
   -- No free reward or currency; the normal first 250-coin search is unchanged.
   if inMeadow and data.Currencies.Coins<Trees.Ordered[1].Cost then
    for _,owned in ipairs(data.Pets)do if usable(owned)then pet=owned;p.PetUID=pet.UID;p.Step=3;break end end
   end
   if p.Step==2 and inMeadow then self:ChooseTree(player)end
  end
 end
 if p.Step>=3 and p.Step<=5 then
  if not usable(pet) then
   pet=Locations.Find(data,data.ActiveHeldPetUID)
   if not usable(pet) then pet=nil;for _,owned in ipairs(data.Pets)do if usable(owned)then pet=owned;break end end end
   p.PetUID=pet and pet.UID or nil;p.SlotId=nil;p.Step=pet and 3 or 2
  end
  if pet then
   local actual=pet.Location=='Sanctuary' and Display.GetSlot(player,pet.LocationSlot)
   -- The suggested empty slot is guidance, not a requirement to move an already placed pet.
   -- Any real owned Sanctuary slot completes PLACE; normal prompt text never selects objectives.
   if actual then p.SlotId=pet.LocationSlot;p.Step=5
   elseif p.Step==5 then p.Step=4;p.SlotId=nil end
   if p.Step==3 and pet.Location=='Held' and data.ActiveHeldPetUID==pet.UID and Knit.GetService('PlotService'):IsNearOwnPlot(player) then p.Step=4 end
   if p.Step==4 then
    local slot=p.SlotId and Display.GetSlot(player,p.SlotId)
    if not slot or Locations.At(data,'Sanctuary',p.SlotId) then
     p.SlotId=nil
     for i=1,Locations.MaxSanctuarySlots do if Display.GetSlot(player,i) and not Locations.At(data,'Sanctuary',i)then p.SlotId=i;break end end
    end
    if not p.SlotId then
     -- A full existing Sanctuary already demonstrates placement; guide its real income.
     for _,owned in ipairs(data.Pets)do if owned.Location=='Sanctuary' and Display.GetSlot(player,owned.LocationSlot)then p.PetUID=owned.UID;p.SlotId=owned.LocationSlot;p.Step=5;break end end
    end
   end
  end
 end
 if p.Step~=2 or p.PetUID then s.Target.Value=nil end
 if Http:JSONEncode(p)~=before then self:Publish(player)end
end
function Service:Awarded(player,biome,result)
 local data=Data:Get(player);if not data or data.TutorialCompleted or biome~='Meadow' then return end
 -- Do not run the low-balance replay fallback between commit and attaching this reward UID.
 local p=self:Normalize(data);local entry=result and result.Results and result.Results[1]
 local pet=entry and entry.Pet and Locations.Find(data,entry.Pet.UID)
 if p.Step~=2 or p.PetUID or not pet then return end
 p.PetUID=pet.UID;p.RevealReadyAt=workspace:GetServerTimeNow()+(data.Settings.ReducedMotion and .45 or math.max(.6,result.Duration or 1.3))
 state(player).Target.Value=nil;self:Publish(player)
end
function Service:RevealDone(player,uid)
 local data=Data:Get(player);local p=data and data.TutorialProgress
 if not p or data.TutorialCompleted or p.Step~=2 or p.PetUID~=uid or not Locations.Find(data,uid) or workspace:GetServerTimeNow()<(p.RevealReadyAt or math.huge) then return false,'Companion reveal is still in progress.' end
 p.Step=3;p.RevealReadyAt=nil;self:Publish(player);self:Reconcile(player);return true
end
function Service:Collected(player,amount)
 local data=Data:Get(player);if not data or data.TutorialCompleted or amount<=0 then return end
 self:Reconcile(player)
 local p=data.TutorialProgress;local pet=Locations.Find(data,p.PetUID)
 if p.Step==5 and pet and pet.Location=='Sanctuary' and pet.LocationSlot==p.SlotId and Display.GetSlot(player,p.SlotId) then p.Step=6;self:Publish(player)end
end
function Service:Complete(player)
 local data=Data:Get(player)
 if not data or data.TutorialCompleted or (data.TutorialProgress.FlowVersion~=2 or data.TutorialProgress.Step~=6) then return false,'Finish your first Sanctuary collection first.' end
 data.TutorialCompleted=true;self:Publish(player);state(player).Target.Value=nil;return true
end
function Service:Restart(player)
 local data=Data:Get(player)
 if not data or data.TutorialCompleted or (data.TutorialProgress.FlowVersion~=2 or data.TutorialProgress.Step~=6) then return false,'Finish the guided steps first.' end
 local p=data.TutorialProgress;p.Step=1;p.FlowVersion=2;p.PetUID=nil;p.SlotId=nil;p.RevealReadyAt=nil
 data.TutorialCompleted=false;state(player).Target.Value=nil;self:Publish(player);return true
end
function Service:KnitInit()Data=Knit.GetService('PlayerDataService')end
function Service:KnitStart()
 Knit.GetService('EggService').Hatched:Connect(function(player,_,biome,result)self:Awarded(player,biome,result)end)
 Knit.GetService('PlotService').Collected:Connect(function(player,amount)self:Collected(player,amount)end)
 Knit.GetService('ProfileService').Loaded:Connect(function(player)self:Reconcile(player,true)end)
 Knit.GetService('ProfileService').UpdateSpecificData:Connect(function(player,path)
  if path[1]~='Pets' and path[1]~='ActiveHeldPetUID' then return end
  local data=Data:Get(player);local p=data and data.TutorialProgress
  if p and p.Step>=3 and p.Step<=5 then self:Reconcile(player)end
 end)
 Players.PlayerRemoving:Connect(function(player)sessions[player]=nil end)
 task.spawn(function()while true do task.wait(.5);for _,p in ipairs(Players:GetPlayers())do self:Reconcile(p)end end end)
end
return Service
