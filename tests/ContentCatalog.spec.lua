-- Source-level execution with deterministic adapters; no Studio/data writes.
local function execute(source, environment, name)
	local fn = assert(loadstring(source, name))
	setfenv(fn, setmetatable(environment or {}, {__index = getfenv()}))
	return fn()
end
local config = execute(sources.Config, {}, "Config")
local function database(source, settings)
	return execute(source, {script = {Parent = {AnimalKingdomConfig = "Config"}}, require = function() return settings end}, "PetDatabase")
end
local before, after = database(sources.Before, config), database(sources.Database, config)
assert(#before.Ordered == 300 and #after.Ordered == #before.Ordered)
for index, old in ipairs(before.Ordered) do
	local new = after.Ordered[index]
	for key, value in pairs(old) do assert(new[key] == value, "Existing pet record changed: " .. old.PetId .. "." .. key) end
	for key, value in pairs(new) do assert(old[key] == value, "Existing pet record gained unexpected data: " .. key) end
end
local extended = table.clone(config); extended.Biomes = table.clone(config.Biomes)
table.insert(extended.Biomes, {Id = "CatalogTestBiome", DisplayName = "Catalog Test", MinIncome = 10, MaxIncome = 100, UnlockCost = 10})
local expanded = database(sources.Database, extended)
assert(#expanded.Ordered == 325 and expanded.CatalogTestBiome_Common_01, "A thirteenth configured biome could not register pets")
local duplicate = table.clone(config); duplicate.Biomes = table.clone(config.Biomes)
table.insert(duplicate.Biomes, config.Biomes[1])
assert(not pcall(database, sources.Database, duplicate), "Duplicate biome IDs silently overwrote pet records")
local duplicateRarity = table.clone(config); duplicateRarity.RarityOrder = table.clone(config.RarityOrder)
table.insert(duplicateRarity.RarityOrder, config.RarityOrder[1])
assert(not pcall(database, sources.Database, duplicateRarity), "Duplicate rarity rows silently generated duplicate pets")
print("PASS content catalog: existing 300 records unchanged, thirteenth biome expands cleanly, duplicate IDs rejected")

local function bootstrap(destinationCount, missingLast)
	local waits, ensureCalls, children, destinations = 0, 0, {}, {}
	for i = 1, destinationCount do
		local name = "Biome" .. i
		destinations[name] = name
		if not missingLast or i < destinationCount then children[name] = {IsA = function(_, class) return class == "BasePart" end} end
	end
	-- Unrelated children must not make a partially registered catalog look complete.
	children.Decor = {IsA = function() return false end}
	local markers = {FindFirstChild = function(_, name) return children[name] end}
	local landing = {EnsureMarkers = function()
		ensureCalls += 1
		if ensureCalls > 1 then
			for name in pairs(destinations) do children[name] = {IsA = function(_, class) return class == "BasePart" end} end
		end
		return markers
	end}
	local signal = {Connect = function() end}
	local remote = {IsA = function(_, class) return class == "RemoteEvent" end, OnServerEvent = signal, FireClient = function() end}
	local remotes = {FindFirstChild = function() return remote end}
	local storage = {FindFirstChild = function() return remotes end}
	local server = {}; function server:WaitForChild() return self end
	local services = {Players = {PlayerRemoving = signal}, ReplicatedStorage = storage, ServerScriptService = server}
	local modules = {Destinations = destinations, Landing = landing, RequestHandler = {new = function() return function() end, function() end end}}
	execute(sources.Teleport, {
		game = {GetService = function(_, name) return services[name] end},
		script = {Destinations = "Destinations", Landing = "Landing", RequestHandler = "RequestHandler"},
		require = function(key) return modules[key] or {} end,
		task = {spawn = function(callback) callback() end, wait = function() waits += 1 end},
	}, "BiomeTeleport")
	return waits, ensureCalls
end
local waits, calls = bootstrap(13, false)
assert(waits == 0 and calls == 1, "Complete thirteen-biome catalog kept retrying")
waits, calls = bootstrap(13, true)
assert(waits == 1 and calls == 2, "Extra marker child concealed a missing catalog destination")
waits, calls = bootstrap(12, false)
assert(waits == 0 and calls == 1, "Current twelve-biome startup changed")
print("PASS biome startup: current/new catalog completion, missing destination recovered despite unrelated children")
