-- Pure versioned, additive migration. Unknown pets/fields survive definition changes.
local M = { Version = 5 }
local MAX = 9_000_000_000_000_000
local function integer(value, fallback, maximum)
 if type(value) ~= "number" or value ~= value or math.abs(value) == math.huge then return fallback end
 return math.clamp(math.floor(value), 0, maximum or MAX)
end
local function dictionary(data, key) if type(data[key]) ~= "table" then data[key] = {} end return data[key] end
-- Recovery records must themselves remain serializable, even for bad test/runtime values.
local function recover(value, visiting)
 local kind = typeof(value)
 if kind == "nil" or kind == "string" or kind == "boolean" then return value end
 if kind == "number" and value == value and math.abs(value) < math.huge then return value end
 if kind ~= "table" then return {InvalidType=kind, Description=tostring(value)} end
 visiting = visiting or {}
 if visiting[value] then return {InvalidType="cycle"} end
 visiting[value] = true
 local result = {}
 for key, child in pairs(value) do result[tostring(key)] = recover(child, visiting) end
 visiting[value] = nil
 return result
end
function M.Apply(data, guid)
 local version = integer(data.DataVersion, 0)
 -- A newer deployment must not be downgraded by an older server.
 if version > M.Version then error(string.format("Profile version is newer than this server (saved=%d, supported=%d)", version, M.Version)) end
 local currencies = dictionary(data, "Currencies")
 if version < 1 then
  currencies.Coins = integer(data.ForestCoins, currencies.Coins or 0)
  currencies.FriendshipTokens = integer(data.FriendshipTokens, currencies.FriendshipTokens or 0)
  data.Pets = type(data.Pets) == "table" and #data.Pets > 0 and data.Pets or data.OwnedPets or {}
  data.EquippedPets = data.EquippedPets or {}
 end
 -- Garden fields are additive at every version; keep malformed saved values in recovery.
 local gardenRecovery = dictionary(dictionary(data, "RecoveryData"), "GardenMigration")
 local function gardenTable(key)
  if data[key] == nil then data[key] = {}
  elseif type(data[key]) ~= "table" then
   if gardenRecovery[key] == nil then gardenRecovery[key] = recover(data[key]) end
   data[key] = {}
  end
  return data[key]
 end
 local function finite(value)
  return type(value) == "number" and value == value and math.abs(value) < math.huge
 end
 if currencies.GardenHarvest ~= nil and (not finite(currencies.GardenHarvest) or currencies.GardenHarvest < 0) then
  if gardenRecovery.GardenHarvest == nil then gardenRecovery.GardenHarvest = recover(currencies.GardenHarvest) end
 end
 for key,value in pairs(currencies) do currencies[key] = integer(value, 0) end
 currencies.Coins = integer(currencies.Coins, 0)
 currencies.FriendshipTokens = integer(currencies.FriendshipTokens, 0)
 currencies.GardenHarvest = integer(currencies.GardenHarvest, 0)
 gardenTable("GardenExpeditions")
 gardenTable("GardenCosmetics")
 local pets, seen = dictionary(data, "Pets"), {}
 local valid, recovery = {}, dictionary(data, "RecoveryData")
 for _, pet in ipairs(pets) do
  if type(pet) == "table" and type(pet.PetId) == "string" then
   local uid = pet.UID or pet.UniquePetId
   if type(uid) ~= "string" or seen[uid] then uid = guid() end
   pet.UID, pet.UniquePetId, seen[uid] = uid, uid, true
   pet.Level = math.max(1, integer(pet.Level, 1, 100))
   pet.XP = integer(pet.XP, 0)
   pet.Mutation = type(pet.Mutation) == "string" and pet.Mutation or "Normal"
   if pet.Mutation == "None" then pet.Mutation = "Normal" end
    for _, flag in ipairs({"Shiny", "Prismatic", "Favorite", "Locked"}) do pet[flag] = pet[flag] == true end
    if pet.Cosmetic ~= nil and (type(pet.Cosmetic) ~= "string" or #pet.Cosmetic > 40) then
     local rejected = dictionary(gardenRecovery, "InvalidPetCosmetics")
     if rejected[uid] == nil then rejected[uid] = recover(pet.Cosmetic) end
     pet.Cosmetic = nil
    end
    table.insert(valid,pet)
  else
   recovery.Pets = recovery.Pets or {}; table.insert(recovery.Pets,pet)
  end
 end
 data.Pets = valid
 data.PetStorageCapacity = math.max(50, #valid, integer(data.PetStorageCapacity, 50, 2000))
 data.MaxEquippedPets = math.max(3, integer(data.MaxEquippedPets, 3, 12))
 local equipped, used = {}, {}
 for _, uid in ipairs(dictionary(data,"EquippedPets")) do
  if seen[uid] and not used[uid] and #equipped < data.MaxEquippedPets then table.insert(equipped,uid);used[uid]=true end
 end
 data.EquippedPets = equipped
  for _, key in ipairs({"PetIndex","UnlockedBiomes","Upgrades","DailyChallenges","WeeklyChallenges","Settings","PlotProgression","SeasonalData","Items","IndexRewards","Stats","Boosts","TutorialProgress","NumNomIndex","UnlockedDecorations","DisplayedPetIds","GardenExpeditions","GardenCosmetics"}) do dictionary(data,key) end
 local displayed, displayedSeen={},{}
 for _,id in ipairs(data.DisplayedPetIds) do
  if type(id)=="string" and seen[id] and not displayedSeen[id] and #displayed<70 then table.insert(displayed,id);displayedSeen[id]=true end
 end
  data.DisplayedPetIds=displayed
 -- Keep every valid trip, including unknown pets/extra fields and future durations.
 -- Invalid optional entries are archived, never silently discarded.
 local expeditions = {}
 for key, entry in pairs(data.GardenExpeditions) do
  if type(key) == "number" and key >= 1 and key % 1 == 0
   and type(entry) == "table" and type(entry.UID) == "string" and type(entry.PetId) == "string"
   and finite(entry.ReadyAt) and finite(entry.Duration) and entry.Duration > 0 then
   if not finite(entry.StartedAt) then entry.StartedAt = entry.ReadyAt - entry.Duration end
   if type(entry.DurationId) ~= "string" then entry.DurationId = "SproutRun" end
   if type(entry.TripId) ~= "string" or entry.TripId == "" then
    entry.TripId = entry.UID .. ":" .. tostring(entry.StartedAt) .. ":" .. tostring(entry.Duration)
   end
   table.insert(expeditions, {Index=key, Entry=entry})
  else
   local rejected = dictionary(gardenRecovery, "InvalidExpeditions")
   if rejected[tostring(key)] == nil then rejected[tostring(key)] = recover(entry) end
  end
 end
 table.sort(expeditions, function(a,b) return a.Index < b.Index end)
 local ordered = {}
 for _, row in ipairs(expeditions) do table.insert(ordered, row.Entry) end
 data.GardenExpeditions = ordered
 for id, owned in pairs(data.GardenCosmetics) do
  if type(id) ~= "string" or type(owned) ~= "boolean" then
   local rejected = dictionary(gardenRecovery, "InvalidCosmetics")
   if rejected[tostring(id)] == nil then rejected[tostring(id)] = recover(owned) end
   data.GardenCosmetics[id] = nil
  end
 end
 data.UnlockedBiomes.Meadow = true
 for id,level in pairs(data.Upgrades) do data.Upgrades[id]=integer(level,0,100) end
 for id,amount in pairs(data.Items) do data.Items[id]=integer(amount,0,1_000_000) end
 for id,value in pairs(data.Stats) do if id~="LastWeatherKey" then data.Stats[id]=integer(value,0) end end
 for id, entry in pairs(data.PetIndex) do
  if type(entry) == "number" then data.PetIndex[id] = {Count=integer(entry,0),Variants={Normal=true}}
  elseif type(entry) == "table" then entry.Count=integer(entry.Count,1);entry.Variants=type(entry.Variants)=="table" and entry.Variants or {Normal=true}
  elseif entry==true then data.PetIndex[id]={Count=1,Variants={Normal=true}}
  else recovery.PetIndex=recovery.PetIndex or {};recovery.PetIndex[id]=entry;data.PetIndex[id]=nil end
 end
 for _,pet in ipairs(valid) do
  local entry=data.PetIndex[pet.PetId]
  if type(entry)~="table" then entry={Count=1,Variants={}};data.PetIndex[pet.PetId]=entry end
  entry.Variants[pet.Mutation]=true
  if pet.Shiny then entry.Variants.Shiny=true end
  if pet.Prismatic then entry.Variants.Prismatic=true end
 end
 data.TutorialCompleted = data.TutorialCompleted == true
 data.TutorialProgress.Step = math.max(1,integer(data.TutorialProgress.Step,1,14))
 data.Settings.AutoDelete = type(data.Settings.AutoDelete)=="table" and data.Settings.AutoDelete or {}
 data.Settings.ReducedMotion = data.Settings.ReducedMotion == true
 data.Settings.ShowOtherPets = data.Settings.ShowOtherPets ~= false
 data.PlotProgression.Level = integer(data.PlotProgression.Level,0,10)
 data.PlotProgression.VisitorsAllowed = data.PlotProgression.VisitorsAllowed ~= false
 data.PlotProgression.Placements = type(data.PlotProgression.Placements)=="table" and data.PlotProgression.Placements or {}
 local placements={}
 for _,entry in ipairs(data.PlotProgression.Placements) do
  if type(entry)=="table" and type(entry.UID)=="string" and type(entry.ItemId)=="string"
   and type(entry.X)=="number" and entry.X==entry.X and math.abs(entry.X)<1000
   and type(entry.Z)=="number" and entry.Z==entry.Z and math.abs(entry.Z)<1000 then
   entry.Rotation=integer(entry.Rotation,0,359);entry.Rotation=math.floor(entry.Rotation/90)*90
   table.insert(placements,entry)
  else recovery.Placements=recovery.Placements or {};table.insert(recovery.Placements,entry) end
 end
 data.PlotProgression.Placements=placements
 -- Sanctuary uses fractional server timestamps/accrual; keep valid precision.
 if not finite(data.UncollectedSanctuaryCoins) or data.UncollectedSanctuaryCoins < 0 then data.UncollectedSanctuaryCoins = 0 end
 if not finite(data.SanctuaryIncomeUpdatedAt) or data.SanctuaryIncomeUpdatedAt < 0 then data.SanctuaryIncomeUpdatedAt = 0 end
 -- Compatibility mirrors for the old display service/UI; canonical writers own updates.
 data.OwnedPets = data.Pets
 data.ForestCoins, data.FriendshipTokens = currencies.Coins, currencies.FriendshipTokens
 require(script.Parent.GardenProgress).Migrate(data)
 require(script.Parent.PetLocations).Migrate(data)
 dictionary(data,"BiomeMastery");dictionary(data,"Contracts");dictionary(data,"LuckyTreeParticipation")
 require(script.Parent.SpeciesRecords).Seed(data)
 data.DataVersion, data.SchemaVersion = M.Version, M.Version
 return data
end
return M
