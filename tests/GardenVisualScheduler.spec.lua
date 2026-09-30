-- Executes the production client scheduler with lifecycle/time adapters.
-- Geometry and rendering are intentionally stubbed; Studio must verify appearance.
local function signal()
	local listeners = {}
	return {
		Connect = function(_, callback)
			local connection = {Connected = true}
			function connection:Disconnect() self.Connected = false end
			listeners[connection] = callback
			return connection
		end,
		Fire = function(_, ...)
			for connection, callback in pairs(table.clone(listeners)) do if connection.Connected then callback(...) end end
		end,
		Count = function()
			local count = 0
			for connection in pairs(listeners) do if connection.Connected then count += 1 end end
			return count
		end,
	}
end

local vectorMeta = {}
local function vector(x, y, z) return setmetatable({X = x or 0, Y = y or 0, Z = z or 0}, vectorMeta) end
function vectorMeta.__add(a, b) return vector(a.X + b.X, a.Y + b.Y, a.Z + b.Z) end
function vectorMeta.__sub(a, b) return vector(a.X - b.X, a.Y - b.Y, a.Z - b.Z) end
function vectorMeta.__mul(a, b) return vector(a.X * b, a.Y * b, a.Z * b) end
function vectorMeta.__div(a, b) return vector(a.X / b, a.Y / b, a.Z / b) end
function vectorMeta.__index(a, key)
	if key == "Magnitude" then return math.sqrt(a.X * a.X + a.Y * a.Y + a.Z * a.Z) end
	if key == "Lerp" then return function(self, other, alpha) return self + (other - self) * alpha end end
end
local frameMeta = {}
local function frame(x, y, z) return setmetatable({Position = type(x) == "table" and x or vector(x, y, z)}, frameMeta) end
function frameMeta.__mul(a, b) return frame(a.Position + b.Position) end
function frameMeta.__index(_, key)
	if key == "Rotation" then return frame() end
	if key == "UpVector" then return vector(0, 1, 0) end
	if key == "VectorToWorldSpace" then return function(_, value) return value end end
	if key == "Lerp" then return function(self, other, alpha) return frame(self.Position:Lerp(other.Position, alpha)) end end
end

local methods = {}
local function instance(class, name, parent)
	local value = setmetatable({ClassName = class, Name = name or class, children = {}, attributes = {}, changes = {},
		CFrame = frame(), Size = vector(1, 1, 1), Enabled = true, scale = 1, pivots = 0,
		AncestryChanged = signal(), Destroying = signal(), DescendantAdded = signal(), DescendantRemoving = signal()}, {
		__index = function(self, key)
			if key == "Parent" then return rawget(self, "_parent") end
			if key == "Position" then return self.CFrame.Position end
			if methods[key] then return methods[key] end
			for _, child in ipairs(self.children) do if child.Name == key then return child end end
		end,
		__newindex = function(self, key, nextValue)
			if key ~= "Parent" then rawset(self, key, nextValue); return end
			local old = rawget(self, "_parent")
			if old then local index = table.find(old.children, self); if index then table.remove(old.children, index) end end
			rawset(self, "_parent", nextValue)
			if nextValue then table.insert(nextValue.children, self) end
			self.AncestryChanged:Fire(self, nextValue)
		end,
	})
	value.Parent = parent
	return value
end
function methods:IsA(class) return self.ClassName == class or class == "BasePart" and self.ClassName == "Part" end
function methods:GetChildren() return table.clone(self.children) end
function methods:GetDescendants()
	local result = {}
	for _, child in ipairs(self.children) do table.insert(result, child); for _, nested in ipairs(child:GetDescendants()) do table.insert(result, nested) end end
	return result
end
function methods:FindFirstChild(name, recursive)
	for _, child in ipairs(recursive and self:GetDescendants() or self.children) do if child.Name == name then return child end end
end
function methods:WaitForChild(name) return assert(self:FindFirstChild(name), name) end
function methods:FindFirstChildWhichIsA(class, recursive)
	for _, child in ipairs(recursive and self:GetDescendants() or self.children) do if child:IsA(class) then return child end end
end
function methods:IsDescendantOf(parent) local current = self.Parent; while current do if current == parent then return true end; current = current.Parent end; return false end
function methods:GetAttribute(name) return self.attributes[name] end
function methods:SetAttribute(name, value) self.attributes[name] = value; if self.changes[name] then self.changes[name]:Fire() end end
function methods:GetAttributeChangedSignal(name) self.changes[name] = self.changes[name] or signal(); return self.changes[name] end
function methods:Destroy()
	if self.destroyed then return end
	self.destroyed = true
	self.Destroying:Fire()
	for _, child in ipairs(self:GetChildren()) do child:Destroy() end
	self.Parent = nil
end
function methods:Clone()
	local clone = instance(self.ClassName, self.Name)
	clone.CFrame, clone.Size = self.CFrame, self.Size
	for _, child in ipairs(self.children) do child:Clone().Parent = clone end
	return clone
end
function methods:GetScale() return self.scale end
function methods:ScaleTo(value) self.scale = value; self.scales = (self.scales or 0) + 1 end
function methods:PivotTo(value) self.CFrame = value; self.pivots += 1 end
function methods:Emit(value) self.emitted = (self.emitted or 0) + value end

local function setup(studio)
	local clock, payload, clones = 0, nil, 0
	local run = {RenderStepped = signal(), IsStudio = function() return studio == true end}
	local world = instance("Workspace", "Workspace")
	world.GetServerTimeNow = function() return clock end
	local realm = instance("Model", "PetGardenRealm", world)
	local plot = instance("Model", "GardenPlot1", realm)
	local soil = instance("Part", "SoilBase", plot); soil.CFrame = frame(0, -.5, 0)
	local area = instance("Model", "ForageSlot_1", plot); area:SetAttribute("SlotId", 1)
	local marker = instance("Part", "SlotMarker", area)
	local board = instance("BillboardGui", "SlotStatus", marker)
	local label = instance("TextLabel", "Text", board)
	local anchor = instance("Part", "PetAnchor", area); anchor.CFrame = frame(0, .1, 0)
	local node = instance("Part", "CropNode_1", area); node.CFrame = frame(6, .1, 0)
	local player = instance("Player"); player.Character = instance("Model")
	local root = instance("Part", "HumanoidRootPart", player.Character)
	local storage = instance("ReplicatedStorage")
	storage.Shared = {Gameplay = {PetAppearance = "Appearance", PetVisualGeometry = "Geometry", Definitions = {PetDefinitions = "Pets", GardenDefinitions = "Garden"}}}
	local assets = instance("Folder", "GardenAssets", storage)
	local templates = instance("Folder", "Crops", assets)
	local source = instance("Model", "Carrot", templates); instance("Part", "Fruit", source)
	local scriptObject = instance("LocalScript")
	local values = {
		Pets = {Pup = {}}, Garden = {CropNames = {"Carrot"}, Crops = {Carrot = {Regrow = 5}}},
		Geometry = {Measure = function() return {} end, ContextRotation = function() return frame() end,
			GroundCFrame = function(_, position, _, clearance) assert(clearance >= 0); return frame(position + vector(0, clearance, 0)) end},
		Appearance = {Create = function(_, context)
			assert(context == "Garden", "Garden did not use its canonical visual context")
			clones += 1
			local model = instance("Model"); instance("Part", "Body", model)
			return model
		end},
	}
	local services = {ReplicatedStorage = storage, RunService = run, Players = {LocalPlayer = player}, HttpService = {JSONDecode = function() return payload end}}
	local dummy = {new = function() return {} end}
	local env = setmetatable({game = {GetService = function(_, name) return assert(services[name], name) end}, workspace = world,
		require = function(key) return values[key] end, script = scriptObject,
		Instance = {new = function(class) return instance(class) end}, Vector3 = {new = vector, zero = vector()},
		CFrame = {new = frame, Angles = function() return frame() end, lookAt = function() return frame() end},
		Color3 = {fromRGB = function() return {} end}, NumberRange = dummy, NumberSequence = dummy, NumberSequenceKeypoint = dummy, ColorSequence = dummy,
		Enum = {HighlightDepthMode = {Occluded = 1}},
		debug = {profilebegin = function() end, profileend = function() end},
	}, {__index = getfenv()})
	local code = assert(loadstring(sourceCode, "GardenPlotVisuals")); setfenv(code, env); code()
	local test = {area = area, anchor = anchor, node = node, root = root, templates = templates, source = source, realm = realm, run = run, script = scriptObject}
	test.label = label
	function test:step(dt) clock += dt; run.RenderStepped:Fire(dt) end
	function test:setState(value) payload = value; area:SetAttribute("VisualState", value and "state" or "") end
	function test:pet() local folder = area:FindFirstChild("ForageVisuals"); return folder and folder:FindFirstChild("ForagingPet") end
	function test:clones() return clones end
	function test:start()
		self:setState({TripId = "trip1", Pet = {UID = "pet1", PetId = "Pup", Mutation = "Normal"}, Seed = 9, Next = {At = 4, Node = 1, Crop = "Carrot", Radius = 20}})
		self:step(.25)
	end
	return test
end

local slow, fast = setup(), setup()
slow:start(); fast:start()
local baseline = fast:pet().pivots
for _ = 1, 30 do slow:step(1 / 30) end
for _ = 1, 120 do fast:step(1 / 120) end
assert(fast:pet().pivots - baseline == 120, "Pet movement is still capped below the render rate")
assert((slow:pet().Position - fast:pet().Position).Magnitude < .06, "Garden motion diverges substantially across frame rates")
assert(slow:clones() == 1 and fast:clones() == 1, "Unchanged state recreated pet models")
local crop = fast.area.ForageVisuals.Crop_1_Carrot
assert(crop.scales <= 2, "Unchanged crop scale is rewritten every frame")
print("PASS Garden scheduler: every render frame updates, 30/120 FPS agree, pet clones and crop scales remain stable")

local streaming = setup()
streaming.source.Parent = nil
streaming.anchor.Parent = nil
streaming:start()
assert(not streaming:pet(), "Missing anchor created a floating pet")
streaming.anchor.Parent = streaming.area
streaming:step(.25)
assert(streaming:pet(), "Restored anchor did not recover pet presentation")
assert(not streaming.area.ForageVisuals:FindFirstChild("Crop_1_Carrot"), "Missing crop template produced a fake visual")
streaming.source.Parent = streaming.templates
streaming:step(.25)
assert(streaming.area.ForageVisuals:FindFirstChild("Crop_1_Carrot"), "Late crop template did not recover")
streaming.node.Parent = nil; streaming:step(.25)
assert(not streaming.area.ForageVisuals:FindFirstChild("Crop_1_Carrot"), "Removed crop marker left an orphan visual")
streaming.anchor.Parent = nil; streaming:step(.25)
assert(not streaming:pet(), "Removed pet anchor left an orphan pet")
print("PASS Garden streaming: missing markers/templates are safe, late content recovers, removed markers clear visuals")

local cleanup = setup(); cleanup:start()
local model = cleanup:pet()
cleanup:setState(nil); cleanup:step(.25)
assert(model.destroyed and not cleanup:pet(), "Cleared expedition state left its previous pet")
assert(cleanup.label.Text == "SLOT 1 · AVAILABLE", "Empty Garden slot implied an active growing expedition")
cleanup:start()
local attribute = cleanup.area:GetAttributeChangedSignal("VisualState")
cleanup.area.Parent = nil
assert(attribute:Count() == 0 and not cleanup.area:FindFirstChild("ForageVisuals"), "Removed plot retained visual state or connections")
cleanup.script:Destroy()
assert(cleanup.run.RenderStepped:Count() == 0 and cleanup.realm.DescendantAdded:Count() == 0, "Client shutdown retained global update connections")
print("PASS Garden cleanup: expedition clears, plot removal disconnects, scheduler teardown disconnects")

local instrumented = setup(true); instrumented:start()
for _ = 1, 300 do instrumented:step(1 / 60) end
assert(type(instrumented.realm:GetAttribute("AKGardenRenderAvgMs")) == "number", "Studio sampler did not report average cost")
assert(instrumented.realm:GetAttribute("AKGardenRenderPeakMs") >= instrumented.realm:GetAttribute("AKGardenRenderAvgMs"), "Studio peak cost is below average")
assert(instrumented.realm:GetAttribute("AKGardenRenderFrames") > 0 and instrumented.realm:GetAttribute("AKGardenRenderedPets") == 1)
assert(fast.realm:GetAttribute("AKGardenRenderAvgMs") == nil, "Production client emitted Studio profiling attributes")
print("PASS Garden profiling: Studio aggregates five-second cost windows; production emits no profile attributes")
