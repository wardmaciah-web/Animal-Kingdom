local RS=game:GetService("ReplicatedStorage")
local Knit=require(RS.Packages.Knit)
local Extras=require(RS.Shared.Gameplay.Definitions.WeatherGameplayDefinitions)
local Weather=Knit.CreateService({Name="WeatherGameplayService",Client={}})
local Events,Legacy
local keys={Coins="CoinMultiplier",Luck="PetLuckMultiplier",MutationChance="MutationMultiplier",Shiny="ShinyMultiplier",PetXP="PetXPMultiplier",WalkSpeed="MovementSpeedMultiplier"}
function Weather:GetEventId()
 local state=Events:GetCurrentState()
 return state.Phase=="Event" and state.EventId or nil
end
function Weather:GetModifier(key,biome)
 local id=self:GetEventId();if not id then return 1 end
 local multiplier=keys[key] and Legacy:GetMultiplier(keys[key]) or 1
 if key=="Luck" then multiplier*=Legacy:GetGlobalLuckMultiplier() end
 local extra=Extras[id] or {}
 if type(extra[key])=="number" then multiplier*=extra[key] end
 if key=="ResourceRewards" and ((extra.Biome and extra.Biome==biome) or (extra.Biomes and extra.Biomes[biome])) then multiplier*=extra.BiomeResourceRewards end
 if id=="Chaos" and key=="ResourceRewards" then
  -- Controlled deterministic stage, shared by all requests in the same weather window.
  local state=Events:GetCurrentState();multiplier*=1+((math.floor(state.StartedAt)+math.floor((workspace:GetServerTimeNow()-state.StartedAt)/30))%3)*.25
 end
 return multiplier
end
function Weather:GetRarityMultiplier(rarity) return Legacy:GetRarityMultiplier(rarity) end
function Weather:KnitInit() Events=Knit.GetService("WeatherEventService");Legacy=Knit.GetService("EventModifierService") end
return Weather
