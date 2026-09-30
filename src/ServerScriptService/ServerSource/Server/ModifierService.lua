local RS=game:GetService("ReplicatedStorage")
local Knit=require(RS.Packages.Knit)
local Upgrades=require(RS.Shared.Gameplay.Definitions.UpgradeDefinitions)
local Rarities=require(RS.Shared.Gameplay.Definitions.RarityDefinitions)
local LuckyRules=require(RS.Shared.Gameplay.LuckyTreeRules)
local Odds=require(RS.Shared.Gameplay.NormalTreeOdds)
local Biomes=require(RS.Shared.Gameplay.Definitions.BiomeDefinitions)
local Families=require(RS.Shared.Gameplay.Definitions.TreeFamilyDefinitions)
local Kingdom=require(RS.Shared.Gameplay.KingdomProgress)
local ActivityConfig=require(RS.Shared.Gameplay.Definitions.KingdomActivityDefinitions)
local Modifier=Knit.CreateService({Name="ModifierService",Client={}})
local Data,Weather
local providers={}
function Modifier:RegisterProvider(id,callback) assert(type(id)=="string" and type(callback)=="function");providers[id]=callback end
function Modifier:Get(player,key,biome,scope)
 local data=Data:Get(player);local value=Weather:GetModifier(key,biome)
 if data then
  for id,def in pairs(Upgrades) do if def.Key==key then value*=1+math.clamp(data.Upgrades[id] or 0,0,def.MaxLevel)*def.Effect end end
  for _,boost in pairs(data.Boosts) do
   if type(boost)=="table" and boost.Group~="LuckyTree" and boost.Key==key and type(boost.ExpiresAt)=="number" and boost.ExpiresAt>os.time() and type(boost.Multiplier)=="number" then value*=math.clamp(boost.Multiplier,1,10) end
  end
 end
 if data and key=="Luck"then local boost=LuckyRules.EffectiveBoost(data.Boosts,workspace:GetServerTimeNow());if boost then value*=boost.Multiplier end end
 local ordered={};for id in pairs(providers)do table.insert(ordered,id)end;table.sort(ordered)
 for _,id in ipairs(ordered) do
  local additional=providers[id](player,key,biome,scope)
  if type(additional)=="number" and additional==additional then value*=math.clamp(additional,.1,10) end
 end
 -- New normal-search effects have a separate conservative combined cap. Base
 -- weather/upgrades/streak/Lucky boost behavior is preserved and applied once.
 if data and scope and scope.Normal then
  local now=workspace:GetServerTimeNow();local extra=1
  if key=="Luck"then
   if Kingdom.Active(data,"Clover",now)then extra*=1.10 end
   extra*=Kingdom.FamilyLuck(data,scope.FamilyId)
   extra*=scope.Hot and scope.Hot.Luck or 1
   value*=math.min(ActivityConfig.Limits.NormalLuckExtra,extra)
  elseif key=="SearchRecovery" and Kingdom.Active(data,"Search",now)then value*=.70 end
 end
 return math.clamp(value,.1,1000)
end
function Modifier:GetOddsContext(player,biome,scope)
 local context={Luck=self:Get(player,"Luck",biome,scope),RareDrops=self:Get(player,"RareDrops",biome,scope),SecretChance=self:Get(player,"SecretChance",biome,scope),Rarities={},BiomeMultiplier=1}
 for _,rarity in ipairs(Rarities.Ordered)do context.Rarities[rarity]=Weather:GetRarityMultiplier(rarity) end
 local key=({Snow="IcePetMultiplier",Desert="DesertPetMultiplier",Sky="FlyingPetMultiplier"})[biome]
 if key then context.BiomeMultiplier=Knit.GetService("EventModifierService"):GetMultiplier(key) end
 return context
end
function Modifier:SearchSnapshot(player,tree,biome,familyId)
 local data=Data:Get(player);local challenge=Knit.GetService("ChallengeService")
 local effects=challenge:GetSearchEffects(player,tree,familyId)
 local scope={Normal=true,FamilyId=familyId,Hot=effects}
 local bias=(Kingdom.Active(data,"Heavy",workspace:GetServerTimeNow())and .15 or 0)+(effects.WeightBias or 0)
 return {Odds=self:GetOddsContext(player,biome,scope),WeightBias=math.min(ActivityConfig.Limits.WeightBias,bias),Recovery=math.max(ActivityConfig.Limits.RecoveryFloor,1.5*self:Get(player,"SearchRecovery",biome,scope)),TreeCooldown=effects.Cooldown or 20,BonusCoins=effects.BonusCoins or 0,Mastery=effects.Mastery or 0,OneUseRunId=effects.OneUseRunId,HotId=effects.HotId,HeldUID=data.ActiveHeldPetUID or "",TreeId=tree:GetAttribute("ActivityTreeId")}
end
function Modifier:GetPetDropWeight(player,pet,base,biome)
 return pet and Odds.Weight({PetId=pet.PetId,DropWeight=base},self:GetOddsContext(player,biome)) or 0
end
function Modifier:PublishOdds(player)
 local data=Data:Get(player);if not data then return end
 local boost=LuckyRules.EffectiveBoost(data.Boosts,workspace:GetServerTimeNow())
 player:SetAttribute("LuckyTreeBoostPercent",boost and math.floor((boost.Multiplier-1)*100+.5) or 0)
 player:SetAttribute("LuckyTreeBoostExpiresAt",boost and boost.ExpiresAt or 0)
 local contexts={};for _,biome in ipairs(Biomes.Ordered)do if Biomes.IsContentReady(biome.Id)then contexts[biome.Id]=self:GetOddsContext(player,biome.Id,{Normal=true})end end
 -- Index source details can show the exact family context, plus the active Hot
 -- copy separately. Ordinary family copies never inherit another copy's buff.
 for _,family in ipairs(Families.Ordered)do if Biomes.IsContentReady(family.Biome)then contexts[family.Id]=self:GetOddsContext(player,family.Biome,{Normal=true,FamilyId=family.Id})end end
 local activities=Knit.GetService('ChallengeService').Activities
 local hot=activities and activities.World and activities.World.Hot
 if hot and hot.EndsAt>workspace:GetServerTimeNow()then contexts['Hot:'..hot.FamilyId]=self:GetOddsContext(player,hot.Biome,{Normal=true,FamilyId=hot.FamilyId,Hot=ActivityConfig.Hot[hot.Variant]})end
 local function equal(a,b)
  if type(a)~=type(b)then return false end;if type(a)~="table" then return a==b end
  for k,v in pairs(a)do if not equal(v,b[k])then return false end end
  for k in pairs(b)do if a[k]==nil then return false end end;return true
 end
 if not equal(data.NormalTreeModifiers,contexts)then data.NormalTreeModifiers=contexts;Data:Publish(player,"NormalTreeModifiers")end
end
function Modifier:KnitStart()
 local profiles=Knit.GetService("ProfileService")
 profiles.Loaded:Connect(function(player)self:PublishOdds(player)end)
 task.spawn(function()while true do
  for player in pairs(profiles.Profiles)do self:PublishOdds(player)end
  task.wait(1)
 end end)
end
function Modifier:KnitInit() Data=Knit.GetService("PlayerDataService");Weather=Knit.GetService("WeatherGameplayService") end
return Modifier
