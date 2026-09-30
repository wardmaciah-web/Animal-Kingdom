-- Client presentation only. Expedition state and rewards remain server-owned.
local RS = game:GetService("ReplicatedStorage")
local Run = game:GetService("RunService")
local Http = game:GetService("HttpService")
local Players = game:GetService("Players")
local Appearance = require(RS.Shared.Gameplay.PetAppearance)
local Geometry = require(RS.Shared.Gameplay.PetVisualGeometry)
local Pets = require(RS.Shared.Gameplay.Definitions.PetDefinitions)
local G = require(RS.Shared.Gameplay.Definitions.GardenDefinitions)
local player = Players.LocalPlayer
local realm = workspace:WaitForChild("PetGardenRealm")
local slots, connections, prompts = {}, {}, {}
local statusElapsed, cropElapsed = 0, 0
local STATUS_INTERVAL, CROP_INTERVAL = .25, .1
local DRAW_DISTANCE = 230
local profile = Run:IsStudio() and {Elapsed = 0, Frames = 0, Total = 0, Peak = 0} or nil

local function strip(model)
	for _, object in ipairs(model:GetDescendants()) do
		if object:IsA("BillboardGui") or object:IsA("LuaSourceContainer") then
			object:Destroy()
		elseif object:IsA("BasePart") then
			object.Anchored = true
			object.CanCollide = false
			object.CanTouch = false
			object.CanQuery = false
		end
	end
end

local function clearPet(slot)
	if slot.pet then slot.pet:Destroy() end
	slot.pet, slot.emitter, slot.glow, slot.bounds = nil, nil, nil, nil
	slot.signature, slot.rotation, slot.lastRendered = nil, nil, nil
	slot.effects = nil
end

local function removeSlot(area)
	local slot = slots[area]
	if not slot then return end
	slots[area] = nil
	for _, connection in ipairs(slot.connections) do connection:Disconnect() end
	slot.visuals:Destroy()
end

local function cropAt(slot, index, id)
	if type(index) ~= "number" or index % 1 ~= 0 or index < 1 or index > #G.CropNames or not G.Crops[id] then return end
	local marker = slot.area:FindFirstChild("CropNode_" .. index)
	local node = slot.crops[index]
	if not marker or not marker:IsA("BasePart") then
		if node then node.model:Destroy(); slot.crops[index] = nil end
		return
	end
	if node and node.id == id and node.model.Parent then
		if node.cf ~= marker.CFrame then node.model:PivotTo(marker.CFrame) end
		node.cf = marker.CFrame
		return node
	end
	local assets = RS:FindFirstChild("GardenAssets")
	local templates = assets and assets:FindFirstChild("Crops")
	local template = templates and templates:FindFirstChild(id)
	if not template or not template:IsA("Model") or not template:FindFirstChildWhichIsA("BasePart", true) then return end
	if node then node.model:Destroy() end
	local model = template:Clone()
	strip(model)
	model.Name = "Crop_" .. index .. "_" .. id
	model:PivotTo(marker.CFrame)
	model.Parent = slot.visuals
	node = {id = id, model = model, cf = marker.CFrame, scale = model:GetScale(), growAt = 0}
	slot.crops[index] = node
	return node
end

local function readState(slot)
	local encoded = slot.area:GetAttribute("VisualState")
	local state
	if type(encoded) == "string" and encoded ~= "" then
		local ok, value = pcall(Http.JSONDecode, Http, encoded)
		if ok and type(value) == "table" and type(value.Pet) == "table" and Pets[value.Pet.PetId] then state = value end
	end
	slot.state = state
	slot.dirty = false
	if not state then
		clearPet(slot)
		slot.trip, slot.lastCycle, slot.nextAt, slot.target = nil, nil, nil, nil
		slot.position, slot.moveFrom, slot.messageUntil, slot.message = nil, nil, nil, nil
		slot.retryAt, slot.retrySignature = nil, nil
		for _, crop in pairs(slot.crops) do crop.growAt = 0 end
	end
end

local function groundPosition(slot, position)
	-- Use the actual authored soil plane, without moving any authored geometry.
	local soil = slot.area.Parent and slot.area.Parent:FindFirstChild("SoilBase")
	if soil and soil:IsA("BasePart") and soil.CFrame.UpVector.Y > .5 then
		local normal = soil.CFrame.UpVector
		local top = soil.Position + normal * soil.Size.Y / 2
		local y = top.Y - (normal.X * (position.X - top.X) + normal.Z * (position.Z - top.Z)) / normal.Y
		return Vector3.new(position.X, y, position.Z)
	end
	return Vector3.new(position.X, slot.anchor.Position.Y, position.Z)
end

local function updatePet(slot, now)
	local pet = slot.state.Pet
	-- A stable signature avoids cloning on table-key ordering changes or pet XP.
	local signature = table.concat({tostring(pet.UID), tostring(pet.PetId), tostring(pet.Mutation), tostring(pet.Shiny), tostring(pet.Prismatic), tostring(pet.Cosmetic),tostring(pet.Weight),tostring(pet.CoinsPerSecond)}, "|")
	if slot.pet and slot.pet.Parent and signature == slot.signature then return end
	if slot.retrySignature == signature and slot.retryAt and now < slot.retryAt then return end
	slot.retryAt, slot.retrySignature = now + 2, signature
	clearPet(slot)
	local ok, model = pcall(Appearance.Create, pet, "Garden")
	if not ok or not model then return end
	if model:GetAttribute("Placeholder") then model:Destroy(); return end
	strip(model)
	local bounds = Geometry.Measure(model)
	local root = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
	if not bounds or not root then model:Destroy(); return end
	model.Name = "ForagingPet"
	model:SetAttribute("PetInstanceId", pet.UID)
	model:SetAttribute("ForageState", slot.phase)
	slot.pet, slot.bounds, slot.signature = model, bounds, signature
	slot.retryAt, slot.retrySignature = nil, nil
	slot.effects = {}
	for _, object in ipairs(model:GetDescendants()) do
		if object:IsA("ParticleEmitter") then slot.effects[object] = object.Enabled end
	end
	slot.modelRotation = Geometry.ContextRotation(Pets[pet.PetId], "Garden")
	slot.rotation = slot.anchor.CFrame.Rotation
	slot.position = groundPosition(slot, slot.position or slot.anchor.Position)
	model:PivotTo(Geometry.GroundCFrame(bounds, slot.position, slot.rotation * slot.modelRotation, .04))
	model.Parent = slot.visuals
	local attachment = Instance.new("Attachment")
	attachment.Parent = root
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "ForageLeaves"
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Color = ColorSequence.new(Color3.fromRGB(136, 184, 81))
	emitter.Rate = 0
	emitter.Lifetime = NumberRange.new(.35, .65)
	emitter.Speed = NumberRange.new(1, 2)
	emitter.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, .12), NumberSequenceKeypoint.new(1, 0)})
	emitter.Parent = attachment
	slot.emitter = emitter
	local glow = Instance.new("Highlight")
	glow.Name = "ReadyGlow"
	glow.FillColor = Color3.fromRGB(240, 209, 116)
	glow.FillTransparency = .88
	glow.OutlineTransparency = .65
	glow.OutlineColor = Color3.fromRGB(244, 225, 139)
	glow.DepthMode = Enum.HighlightDepthMode.Occluded
	glow.Enabled = false
	glow.Parent = model
	slot.glow = glow
end

local function presentState(slot, now, reduced)
	local state = slot.state
	if not state then
		for i, id in ipairs(G.CropNames) do local crop = cropAt(slot, i, id); if crop then crop.growAt = 0 end end
		return
	end
	updatePet(slot, now)
	for i, id in ipairs(G.CropNames) do
		local crop = slot.crops[i]
		cropAt(slot, i, crop and crop.id or id)
	end
	if slot.trip ~= state.TripId then
		slot.lastCycle, slot.nextAt, slot.target, slot.messageUntil = nil, nil, nil, nil
		slot.trip = state.TripId
	end
	local last = state.Last
	if type(last) == "table" and last.Cycle ~= slot.lastCycle and type(last.At) == "number" then
		local crop = cropAt(slot, last.Node, last.Crop)
		if crop then
			slot.lastCycle = last.Cycle
			crop.growAt = last.At
			if now - last.At < 3 then
				if slot.emitter and not reduced then slot.emitter:Emit(5) end
				slot.messageUntil, slot.message = now + 1.3, "+" .. tostring(last.Amount) .. " " .. tostring(last.Crop)
			end
		end
	end
	local nextNode = state.Next
	if type(nextNode) == "table" and type(nextNode.At) == "number" then
		local crop = cropAt(slot, nextNode.Node, nextNode.Crop)
		if crop then
			if nextNode.At ~= slot.nextAt then
				slot.nextAt, slot.moveStart = nextNode.At, now
				slot.moveFrom = slot.position or slot.anchor.Position
			end
			slot.target = crop.cf.Position
		else
			slot.target = nil
		end
	else
		slot.target, slot.nextAt = nil, nil
	end
	if slot.glow then slot.glow.Enabled = state.Ready == true end
	if slot.emitter then slot.emitter.Rate = state.Ready and not reduced and .5 or 0 end
end

local function updateStatus(slot, now)
	local marker = slot.area:FindFirstChild("SlotMarker")
	local board = marker and marker:FindFirstChild("SlotStatus")
	local label = board and board:FindFirstChild("Text")
	if not label or not label:IsA("TextLabel") then return end
	local text = slot.messageUntil and now < slot.messageUntil and slot.message
		or slot.state and slot.state.Ready and "READY!"
		or "SLOT " .. tostring(slot.area:GetAttribute("SlotId") or "") .. " · " .. (slot.state and slot.phase or "AVAILABLE")
	if label.Text ~= text then label.Text = text end
end

local function register(area)
	if slots[area] or not area:IsA("Model") or not area.Name:match("^ForageSlot_%d+$") then return end
	local visuals = Instance.new("Folder")
	visuals.Name = "ForageVisuals"
	visuals.Parent = area
	local slot = {area = area, visuals = visuals, crops = {}, connections = {}, dirty = true, phase = "IDLE"}
	slots[area] = slot
	table.insert(slot.connections, area:GetAttributeChangedSignal("VisualState"):Connect(function() slot.dirty = true end))
	table.insert(slot.connections, area.AncestryChanged:Connect(function()
		if not area:IsDescendantOf(realm) then removeSlot(area) end
	end))
end

local function registerPrompt(prompt)
	if not prompt:IsA("ProximityPrompt") or prompt.Name ~= "ReturnPrompt" or prompts[prompt] then return end
	prompts[prompt] = prompt.Triggered:Connect(function(triggeringPlayer)
		if triggeringPlayer ~= player then return end
		local ui=player.PlayerGui:FindFirstChild('AnimalKingdomUI')
		local travel=ui and ui:FindFirstChild('PresentationTravel')
		if travel then travel:Fire('ReturnGarden');return end
		local remotes = RS:FindFirstChild("AnimalKingdomRemotes")
		local request = remotes and remotes:FindFirstChild("UIRequest")
		if request then request:FireServer("ReturnGarden", {}) end
	end)
end

for _, object in ipairs(realm:GetDescendants()) do register(object); registerPrompt(object) end
table.insert(connections, realm.DescendantAdded:Connect(function(object)
	register(object)
	registerPrompt(object)
end))
table.insert(connections, realm.DescendantRemoving:Connect(function(object)
	if slots[object] then removeSlot(object) end
	if prompts[object] then prompts[object]:Disconnect(); prompts[object] = nil end
end))

table.insert(connections, Run.RenderStepped:Connect(function(dt)
	local profileStart = profile and os.clock() or 0
	local renderedPets = 0
	if profile then debug.profilebegin("AK GardenVisuals") end
	statusElapsed += dt
	cropElapsed += dt
	local statusDue, cropDue = statusElapsed >= STATUS_INTERVAL, cropElapsed >= CROP_INTERVAL
	if statusDue then statusElapsed %= STATUS_INTERVAL end
	if cropDue then cropElapsed %= CROP_INTERVAL end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local now = workspace:GetServerTimeNow()
	local reduced = player:GetAttribute("AKReducedMotion") == true
	local positionAlpha, rotationAlpha = 1 - math.exp(-14 * dt), 1 - math.exp(-10 * dt)
	for area, slot in pairs(slots) do
		if not area:IsDescendantOf(realm) then removeSlot(area); continue end
		if statusDue then
			local anchor = area:FindFirstChild("PetAnchor")
			slot.anchor = anchor and anchor:IsA("BasePart") and anchor or nil
			if not slot.anchor and slot.pet then clearPet(slot) end
			slot.near = root and slot.anchor and (root.Position - slot.anchor.Position).Magnitude < DRAW_DISTANCE
			if slot.dirty then readState(slot) end
			if slot.near then presentState(slot, now, reduced); updateStatus(slot, now)
			else
				if slot.emitter then slot.emitter.Rate = 0 end
				if slot.glow then slot.glow.Enabled = false end
			end
			for effect, enabled in pairs(slot.effects or {}) do
				if effect.Parent then effect.Enabled = enabled and slot.near == true and not reduced end
			end
		end
		if not slot.near or not slot.anchor or not slot.anchor.Parent then continue end
		local state, ready = slot.state, slot.state and slot.state.Ready
		if cropDue then
			for _, crop in pairs(slot.crops) do
				if not crop.model.Parent then continue end
				local age, growth = now - crop.growAt, 1
				if crop.growAt > 0 and not ready then
					growth = age < .2 and math.max(.08, 1 - age / .2) or math.clamp((age - .2) / G.Crops[crop.id].Regrow, .08, 1)
				end
				if math.abs((crop.lastScale or 0) - growth) > .015 then
					crop.model:ScaleTo(crop.scale * growth)
					crop.model:PivotTo(crop.cf)
					crop.lastScale = growth
				end
			end
		end
		if not slot.pet or not slot.pet.Parent or not state then continue end
		local desired = slot.position or slot.anchor.Position
		local phase, facing = ready and "COMPLETE" or "IDLE", slot.anchor.CFrame.Rotation
		if not ready and slot.target and type(state.Next) == "table" and slot.moveStart then
			local nextNode = state.Next
			local span = math.max(.2, nextNode.At - slot.moveStart - 1)
			local t = math.clamp((now - slot.moveStart - .2) / span, 0, 1)
			local target = slot.target + slot.anchor.CFrame:VectorToWorldSpace(Vector3.new(0, 0, 1.8))
			if type(nextNode.Radius) == "number" and (slot.target - slot.anchor.Position).Magnitude <= nextNode.Radius then
				desired = slot.moveFrom:Lerp(target, t * t * (3 - 2 * t))
				phase = t <= 0 and "SEARCHING" or t < 1 and "MOVING" or "FORAGING"
			end
			local direction = phase == "MOVING" and desired - slot.position or slot.target - desired
			direction = Vector3.new(direction.X, 0, direction.Z)
			if direction.Magnitude > .05 then facing = CFrame.lookAt(Vector3.zero, direction).Rotation
			else facing = slot.rotation end
			if nextNode.At < now then phase = "HARVEST" end
		end
		desired = groundPosition(slot, desired)
		-- Re-entering visual range or a large authored relocation permits one catch-up.
		if not slot.lastRendered or now - slot.lastRendered > .75 or (desired - slot.position).Magnitude > 40 then
			slot.position, slot.rotation = desired, facing
		else
			slot.position = slot.position:Lerp(desired, positionAlpha)
			slot.rotation = slot.rotation:Lerp(facing, rotationAlpha)
		end
		slot.position = groundPosition(slot, slot.position)
		slot.lastRendered = now
		local seed = (state.Seed or 1) % 71
		local bob = reduced and 0 or (1 + math.sin(now * (phase == "FORAGING" and 6 or 2.4) + seed)) * .012
		local tilt = reduced and 0 or math.sin(now * (phase == "FORAGING" and 6 or 1.7) + seed) * (phase == "FORAGING" and .035 or .012)
		local rotation = slot.rotation * CFrame.Angles(tilt, 0, 0) * slot.modelRotation
		slot.pet:PivotTo(Geometry.GroundCFrame(slot.bounds, slot.position + Vector3.new(0, bob, 0), rotation, .04))
		if profile then renderedPets += 1 end
		if slot.phase ~= phase then slot.phase = phase; slot.pet:SetAttribute("ForageState", phase) end
	end
	if profile then
		debug.profileend()
		local cost = os.clock() - profileStart
		profile.Elapsed += dt
		profile.Frames += 1
		profile.Total += cost
		profile.Peak = math.max(profile.Peak, cost)
		if profile.Elapsed >= 5 then
			realm:SetAttribute("AKGardenRenderAvgMs", profile.Total / profile.Frames * 1000)
			realm:SetAttribute("AKGardenRenderPeakMs", profile.Peak * 1000)
			realm:SetAttribute("AKGardenRenderFrames", profile.Frames)
			realm:SetAttribute("AKGardenRenderedPets", renderedPets)
			profile.Elapsed, profile.Frames, profile.Total, profile.Peak = 0, 0, 0, 0
		end
	end
end))

script.Destroying:Connect(function()
	for _, connection in ipairs(connections) do connection:Disconnect() end
	for _, connection in pairs(prompts) do connection:Disconnect() end
	for area in pairs(slots) do removeSlot(area) end
	table.clear(prompts)
end)
