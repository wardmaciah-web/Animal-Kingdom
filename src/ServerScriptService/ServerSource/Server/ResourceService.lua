local RS=game:GetService("ReplicatedStorage")
local Collection=game:GetService("CollectionService")
local RunService=game:GetService("RunService")
local Knit=require(RS.Packages.Knit)
local Signal=require(RS.Packages.Signal)
local Guard=require(script.Parent.Parent.Utilities.GameplayGuard)
local Tables=require(RS.Shared.Gameplay.Definitions.DropTables)
local BiomeDefinitions=require(RS.Shared.Gameplay.Definitions.BiomeDefinitions)
local TreeShake=require(RS.Shared.Gameplay.TreeShakeMotion)
local Eggs=require(RS.Shared.Gameplay.Definitions.EggDefinitions)
local Format=require(RS.Shared.Gameplay.PetNumberFormat)
local Resource=Knit.CreateService({Name="ResourceService",Client={},Harvested=Signal.new()})
local records,shaking={},{}
local busy=setmetatable({},{__mode="k"})
local Data,Biomes,Loot,Modifiers,Pets,Egg
local function move(object,cf) object:PivotTo(cf) end
local function hide(record)
 for object,properties in pairs(record.Properties) do
  if object.Parent then
   if object:IsA("BasePart") then object.Transparency=1;object.CanCollide=false;object.CanTouch=false;object.CanQuery=false
   elseif object:IsA("Decal") or object:IsA("Texture") then object.Transparency=1
   elseif properties.Enabled~=nil then
    object.Enabled=false
    if object:IsA("ParticleEmitter") or object:IsA("Trail") then object:Clear() end
   end
  end
 end
end
local function resetPose(record)
 move(record.Object,record.Pivot)
 -- MeshPart/PrimaryPart pivot offsets can round a PivotTo round-trip. Restoring
 -- saved part frames also prevents cumulative drift in nested imported assets.
 for part,properties in pairs(record.Properties) do if properties.CFrame and part.Parent then part.CFrame=properties.CFrame end end
end
local function restore(record)
 if not record.Object:IsDescendantOf(workspace) then return end
 resetPose(record)
 for object,properties in pairs(record.Properties) do if object.Parent then for key,value in pairs(properties) do object[key]=value end end end
 record.State="AVAILABLE";record.Claim=nil;record.Awarded=nil;record.HatchResult=nil
 record.Object:SetAttribute("ResourceState","AVAILABLE");record.Object:SetAttribute("RespawnAt",nil)
end
local function notify(player,message)
 if Guard.IsPlayer(player) then Knit.GetService("NotificationService"):Send(player,message,"Error") end
end
function Resource:Register(object)
 if records[object] or object:GetAttribute("GameplayGenerated")==true or not object:IsDescendantOf(workspace) or not (object:IsA("Model") or object:IsA("BasePart")) then return end
 local isTree=Collection:HasTag(object,"GatherableTree")
 if isTree and object:GetAttribute("AuthoredGatherableTree")~=true then return end
 local biome=object:GetAttribute("BiomeId");local tableId=object:GetAttribute("DropTable") or (type(biome)=="string" and biome.."Tree")
 if not Tables[tableId] then warn("[ResourceService] Missing biome/drop table: "..object:GetFullName());return end
 if isTree and biome=="Jungle" then
  local def,issue=require(RS.Shared.Gameplay.Definitions.TreeFamilyDefinitions).BindJungle(object)
  if not def then warn("[JungleTrees] "..tostring(issue)..": "..object:GetFullName());return end
 end
 local root=object:IsA("BasePart") and object or object.PrimaryPart or object:FindFirstChildWhichIsA("BasePart",true)
 if not root then return end
 local original=object:GetPivot()
 local interaction=object:GetAttribute("InteractionPosition")
 if typeof(interaction)~="Vector3" then interaction=original.Position end
 local anchor=root:FindFirstChild("AKTreeInteraction")
 if not anchor then anchor=Instance.new("Attachment");anchor.Name="AKTreeInteraction";anchor.Parent=root end
 anchor.WorldPosition=interaction
 local prompt=anchor:FindFirstChild("GatherPrompt") or Instance.new("ProximityPrompt")
 prompt.Name="GatherPrompt";prompt.ActionText=isTree and "SHAKE TREE" or "GATHER";prompt.ObjectText=isTree and "Tree" or "Resource"
 if isTree and (biome=="Meadow" or biome=="Forest") then
  local treeDefinitions=biome=="Meadow" and RS.Shared.Gameplay.Definitions.MeadowTreeDefinitions or RS.Shared.Gameplay.Definitions.ForestTreeDefinitions
  local def=require(treeDefinitions).Get(object,biome)
  if def and biome=="Forest" then object:SetAttribute("TreeTier",def.Tier);object:SetAttribute("RewardPoolId",def.Id);object:SetAttribute("ShakeableId",def.Id) end
  prompt.ActionText=def and ("SEARCH · "..Format.Number(def.Cost).." Forest Coins") or "UNAVAILABLE"
  prompt.ObjectText=def and def.DisplayName or biome.." Tree"
 elseif isTree and BiomeDefinitions.IsContentReady(biome) then
  local def=Eggs[object:GetAttribute("RewardPoolId") or BiomeDefinitions[biome].EggId]
  if def and def.Biome==biome then
   prompt.ActionText=def.CanonicalPool and ("SEARCH · "..Format.Number(def.Cost).." Forest Coins") or "SHAKE TREE"
   prompt.ObjectText=def.DisplayName or biome.." Tree"
  end
 end
 prompt.HoldDuration=.2;prompt.MaxActivationDistance=14;prompt.RequiresLineOfSight=false;prompt.Parent=anchor
 if not BiomeDefinitions.IsContentReady(biome) then prompt.ActionText="COMING SOON";prompt.Enabled=false end
 local record={Object=object,Pivot=original,InteractionPosition=interaction,IsTree=isTree,State="AVAILABLE",Properties={},Prompt=prompt,Biome=biome,Table=tableId}
 if isTree and not object:GetAttribute("ActivityTreeId")then
  -- Stable within the unchanged authored layout, including duplicate model names.
  object:SetAttribute("ActivityTreeId",string.format("%s@%.3f,%.3f,%.3f",object:GetAttribute("RewardPoolId")or biome,original.X,original.Y,original.Z))
 end
 local objects=object:GetDescendants();table.insert(objects,object)
 for _,v in ipairs(objects) do
  if v:IsA("BasePart") then record.Properties[v]={CFrame=v.CFrame,Transparency=v.Transparency,CanCollide=v.CanCollide,CanTouch=v.CanTouch,CanQuery=v.CanQuery}
  elseif v:IsA("Decal") or v:IsA("Texture") then record.Properties[v]={Transparency=v.Transparency}
  elseif v:IsA("ProximityPrompt") or v:IsA("BillboardGui") or v:IsA("SurfaceGui") or v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") or v:IsA("Light") or v:IsA("Highlight") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") then record.Properties[v]={Enabled=v.Enabled} end
 end
 records[object]=record;object:SetAttribute("ResourceState","AVAILABLE");object:SetAttribute("RespawnTime",20)
 record.Connection=prompt.Triggered:Connect(function(player) local ok,message=self:Gather(player,object);if not ok then notify(player,message) end end)
end
function Resource:Gather(player,object)
 if not Guard.RateLimit(player,"Resource",.3) then return false,"Please wait" end
 local record=records[object];local root=Guard.Alive(player)
 if not record or record.State~="AVAILABLE" or busy[player] or not Data:Get(player) or not root or (root.Position-record.InteractionPosition).Magnitude>18 then return false,"Tree unavailable" end
 if not BiomeDefinitions.IsContentReady(record.Biome) then return false,BiomeDefinitions.ComingSoonMessage end
 if not Biomes:IsUnlocked(player,record.Biome) then return false,"Biome locked" end
 local season=object:GetAttribute("Season")
 if season and not Knit.GetService("SeasonalService"):IsActive(season) then return false,"Season is inactive" end
 if record.IsTree then local ok,message=Egg:CheckTreeHatch(player,object);if not ok then return false,message end end
 -- Atomic claim and per-player guard happen before animation can yield.
 record.State="SHAKING";record.Player=player;record.Started=os.clock();record.Claim={};record.Awarded=nil;record.HatchResult=nil
 if record.IsTree then record.Claim.Search=Modifiers:SearchSnapshot(player,object,record.Biome,object:GetAttribute("RewardPoolId"))end
 record.Prompt.Enabled=false;busy[player]=record
 object:SetAttribute("ResourceState","SHAKING");shaking[object]=record
 local remotes=RS:FindFirstChild("AnimalKingdomRemotes")
 if remotes and remotes:FindFirstChild("GatherVisual") then remotes.GatherVisual:FireAllClients(player.UserId,record.InteractionPosition,.8,object) end
 return true
end
function Resource:Finish(record)
 local object,player=record.Object,record.Player
 if records[object]~=record or record.State~="SHAKING" or not player then return end
 shaking[object]=nil
 if not object:IsDescendantOf(workspace) then busy[player]=nil;record.Player=nil;return end
 resetPose(record)
 local success,result
 if record.IsTree then
  local ok,accepted,response=pcall(Egg.HatchFromTree,Egg,player,object,record.Claim)
  success=ok and accepted or record.Awarded==true;result=record.HatchResult or response
  if not ok then warn("[ResourceService] Tree hatch: "..tostring(accepted)) end
 else
  local root=Guard.Alive(player)
  success=Data:Get(player) and root and (root.Position-record.InteractionPosition).Magnitude<=18 and Biomes:IsUnlocked(player,record.Biome)
 end
 busy[player]=nil;record.Player=nil
 if not success then restore(record);notify(player,type(result)=="string" and result or "Tree hatch cancelled; try again");return end
 -- Commit is final. Hide this same instance before requesting presentation.
 record.State="RESPAWNING";object:SetAttribute("ResourceState","RESPAWNING");hide(record)
 local cooldown=record.Claim and record.Claim.Search and record.Claim.Search.TreeCooldown or 20
 record.ReturnAt=workspace:GetServerTimeNow()+cooldown;object:SetAttribute("RespawnAt",record.ReturnAt)
 task.delay(cooldown,function() if records[object]==record then restore(record) end end)
 if record.IsTree then
  local remotes=RS:FindFirstChild("AnimalKingdomRemotes")
  if remotes and remotes:FindFirstChild('GatherVisual')then remotes.GatherVisual:FireAllClients(player.UserId,record.InteractionPosition,.8,object,'Committed')end
  if remotes and remotes:FindFirstChild("GameplayFeedback") and Guard.IsPlayer(player) then remotes.GameplayFeedback:FireClient(player,{Action="TreeHatch",Success=true,Result=result}) end
 end
 -- Paid normal searches purchase one companion. The legacy resource coin roll
 -- scales with gathering upgrades and can refund more than the canonical price.
 -- Keep that loot on resource gathering; keep search XP/progression unchanged.
 local ok,err=pcall(function()
  if not (record.IsTree and result and result.PoolId) then
   local power=Pets:GetGatheringPower(player)
   local multiplier=Modifiers:Get(player,"ResourceRewards",record.Biome)*(1+math.min(power,5000)/50)
   Loot:Reward(player,record.Table,multiplier,"Gather")
   local weather=Knit.GetService("WeatherGameplayService"):GetEventId()
   if weather=="MeteorShower" then Loot:Reward(player,"MeteorLoot",1,"Weather")
   elseif weather=="Thunderstorm" then Loot:Reward(player,"StormLoot",1,"Weather") end
  end
  Pets:AddEquippedXP(player,10)
 end)
 if not ok then warn("[ResourceService] Secondary reward failed: "..tostring(err)) end
 if record.IsTree and Data:Get(player) then self.Harvested:Fire(player,record.Biome,#Data:Get(player).EquippedPets>0) end
end
function Resource:GetRecords() return records end
function Resource:KnitInit()
 Data=Knit.GetService("PlayerDataService");Biomes=Knit.GetService("BiomeService");Loot=Knit.GetService("LootService")
 Modifiers=Knit.GetService("ModifierService");Pets=Knit.GetService("PetService");Egg=Knit.GetService("EggService")
end
function Resource:KnitStart()
 for _,tag in ipairs({"GatherableTree","GatherableResource"}) do
  Collection:GetInstanceAddedSignal(tag):Connect(function(object) self:Register(object) end)
  Collection:GetInstanceRemovedSignal(tag):Connect(function(object)
   local r=records[object];if not r then return end
   if object:IsDescendantOf(workspace) and (Collection:HasTag(object,"GatherableTree") or Collection:HasTag(object,"GatherableResource")) then return end
   r.Connection:Disconnect();if r.Player then busy[r.Player]=nil end;r.Player=nil;shaking[object]=nil;records[object]=nil
   if object.Parent then restore(r) end
  end)
  for _,object in ipairs(Collection:GetTagged(tag)) do self:Register(object) end
 end
 RunService.Heartbeat:Connect(function()
  local now=os.clock()
  for object,record in pairs(shaking) do
   if not object:IsDescendantOf(workspace) then shaking[object]=nil;if record.Player then busy[record.Player]=nil;record.Player=nil end
   else
    local elapsed=now-record.Started
    if elapsed>=.8 then self:Finish(record)
    else move(object,TreeShake.Pose(record.Pivot,elapsed)) end
   end
  end
 end)
end
return Resource
