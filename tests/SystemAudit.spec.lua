return function(loadSource)
	local function signal()
		local listeners = {}
		return {
			Connect = function(_, callback)
				table.insert(listeners, callback)
				return { Disconnect = function() end }
			end,
			Fire = function(_, ...)
				for _, callback in ipairs(listeners) do callback(...) end
			end,
		}
	end

	local world = { DescendantAdded = signal(), DescendantRemoving = signal() }
	local scans, descendants = 0, {}
	function world:GetDescendants() scans += 1; return descendants end
	local function instance(name, class, parent, children)
		local item = { Name = name, Parent = parent, children = children or {} }
		function item:IsA(requested) return requested == class end
		function item:IsDescendantOf(ancestor) return self.Parent == ancestor end
		function item:GetChildren() return self.children end
		function item:GetAttribute() return nil end
		function item:FindFirstChildWhichIsA() return self.children[1] end
		return item
	end
	local old = instance("Plots", "Folder", world)
	old.children = {
		instance("Plot10", "BasePart", old), instance("Plot2Floor", "BasePart", old),
		instance("Plot1Fence", "Model", old, {{}}), instance("Plot1PetDisplay", "Model", old, {{}}),
		instance("Plot1Spawn", "BasePart", old),
	}
	descendants = { old }
	local locator = loadSource("PlotLocator", {workspace=world})
	assert(#locator.getPlots() == 2 and locator.getPlots()[1].Name == "Plot2Floor", "Plot decorations/spawns were counted as ownership slots")
	for _ = 1, 100 do assert(locator.getContainer() == old) end
	assert(scans == 1, "Status polling repeated a full workspace traversal")
	local preferred = instance("PlayerPlots", "Folder", world)
	preferred.children = { instance("Plot1", "BasePart", preferred) }
	table.insert(descendants, preferred)
	world.DescendantAdded:Fire(preferred)
	assert(locator.getContainer() == preferred and scans == 2, "New preferred map container was not discovered")
	world.DescendantAdded:Fire(instance("Leaf", "BasePart", {}))
	assert(locator.getContainer() == preferred and scans == 2, "Unrelated decoration invalidated plot lookup")
	world.DescendantRemoving:Fire(preferred)
	preferred.Parent = nil
	descendants = { old }
	assert(locator.getContainer() == old and scans == 3, "Removed container remained cached")
	print("PASS plot lookup: numeric ordering, one scan across 100 polls, container replacement/priority, unrelated content ignored")

	local players = { PlayerAdded=signal(), PlayerRemoving=signal() }
	function players:GetPlayers() return {} end
	local function player(id)
		local value = { Name="Test" .. id, UserId=id, Parent=players, kicks=0 }
		function value:IsDescendantOf(parent) return self.Parent == parent end
		function value:Kick(message) self.kicks += 1; self.message = message; self.Parent = nil end
		return value
	end
	local now, loadCalls = 1000, 0
	local function profile()
		local value = {
			Data = {ForestCoins=0/0,FriendshipTokens=math.huge,OwnedPets={},DisplayedPetIds={},UnlockedBiomes={},SanctuaryIncomeUpdatedAt=0},
			OnSessionEnd=signal(), FirstSessionTime=1, SessionLoadCount=1, Session={}, ended=0,
		}
		function value:AddUserId(id) self.id=id end
		function value:Reconcile() end
		function value:EndSession() self.ended += 1; self.OnSessionEnd:Fire() end
		return value
	end
	local loadAction
	local store = {}
	function store:StartSessionAsync(key, parameters)
		loadCalls += 1
		assert(type(parameters.Cancel) == "function")
		return loadAction(key, parameters)
	end
	local function node(children)
		function children:WaitForChild(name) return assert(self[name], name) end
		return children
	end
	local function knitSignal()
		local value = signal()
		value.Emit = value.Fire
		value.sent = {}
		function value:Fire(...) table.insert(self.sent, {...}) end
		return value
	end
	local values = {
		Signal={new=signal}, Knit={CreateService=function(service) return service end,CreateSignal=knitSignal},
		Store={New=function(name) assert(name == "OriginalData1");return store end},
		Migrations=loadSource("ProfileMigrations"), Template={}, Config={MaxDisplayedPets=50,SchemaVersion=1}, Pets={}, Mutations={},
	}
	local storage = {
		Packages={Signal="Signal",Knit="Knit"},
        Shared={Gameplay={ProfileMigrations="Migrations"}},
		SharedSource={Datas={ProfileTemplate="Template",AnimalKingdomConfig="Config",PetDatabase="Pets",MutationDatabase="Mutations"}},
	}
	local services = {
		Players=players, ReplicatedStorage=storage,
        HttpService={GenerateGUID=function() return "test-guid" end},
		ServerScriptService=node({ServerSource=node({Externals=node({ProfileStore="Store"})})}),
		RunService={IsStudio=function() return false end},
	}
	local warnings = {}
	local clock = table.clone(os)
	clock.clock = function() return now end
	local service = loadSource("ProfileService", {
		game={GetService=function(_, name) return assert(services[name]) end},
		require=function(name) return assert(values[name]) end,
		task={spawn=function(callback, ...) callback(...) end}, os=clock,
		warn=function(message) table.insert(warnings,message) end,
	})
	service:KnitInit(); service:KnitStart()
	local first, loaded = player(1), profile()
	loadAction = function(key, parameters)
		assert(key == "Player_1" and not parameters.Cancel())
		players.PlayerAdded:Fire(first) -- A duplicate arrives while loading.
		return loaded
	end
	players.PlayerAdded:Fire(first)
	players.PlayerAdded:Fire(first) -- A duplicate arrives after loading.
	assert(loadCalls == 1 and service.Profiles[first] == loaded)
	assert(loaded.Data.ForestCoins == 0 and loaded.Data.FriendshipTokens == 0 and loaded.Data.UnlockedBiomes.Meadow)
	service.Client.GetData:Emit(first)
	service.Client.GetData:Emit(first)
	assert(#service.Client.GetData.sent == 1, "Repeated data requests bypassed the throttle")
	now += 1
	service.Client.GetData:Emit(first)
	assert(#service.Client.GetData.sent == 2, "Legitimate data retry was rejected")
	players.PlayerRemoving:Fire(first)
	assert(loaded.ended == 1 and first.kicks == 0 and service.Profiles[first] == nil)
	print("PASS profiles: one load per player, non-finite currency normalization, normal leave ends session without a false kick")

	local departed = player(2)
	loadAction = function(_, parameters)
		assert(not parameters.Cancel())
		departed.Parent = nil
		assert(parameters.Cancel(), "Departed player kept a data load alive")
		return nil
	end
	players.PlayerAdded:Fire(departed)
	assert(departed.kicks == 0 and service.Profiles[departed] == nil)
	local timeout = player(3)
	loadAction = function(_, parameters)
		now += 119
		assert(not parameters.Cancel())
		now += 1
		assert(parameters.Cancel(), "Custom cancellation removed the load timeout")
		return nil
	end
	players.PlayerAdded:Fire(timeout)
	assert(timeout.kicks == 1)
	local failed = player(4)
	loadAction = function() error("storage unavailable") end
	players.PlayerAdded:Fire(failed)
	assert(failed.kicks == 1 and #warnings == 1)
	local stolen, stolenProfile = player(5), profile()
	loadAction = function() return stolenProfile end
	players.PlayerAdded:Fire(stolen)
	stolenProfile.OnSessionEnd:Fire()
	assert(stolen.kicks == 1 and service.Profiles[stolen] == nil)
	print("PASS profiles: departure cancellation, retained 120-second timeout, storage exceptions, external session loss")

	local malformed, malformedProfile = player(6), profile()
	function malformedProfile:Reconcile() error("malformed profile") end
	loadAction = function() return malformedProfile end
	players.PlayerAdded:Fire(malformed)
	assert(malformedProfile.ended == 1 and malformed.kicks == 1 and service.Profiles[malformed] == nil)
	local late, lateProfile = player(7), profile()
	loadAction = function() late.Parent = nil; return lateProfile end
	players.PlayerAdded:Fire(late)
	assert(lateProfile.ended == 1 and late.kicks == 0 and service.Profiles[late] == nil)
	print("PASS profiles: failed preparation and departure during load both release acquired sessions")
end
