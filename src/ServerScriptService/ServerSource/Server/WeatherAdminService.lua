local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GroupService = game:GetService("GroupService")
local TextChatService = game:GetService("TextChatService")
local TweenService = game:GetService("TweenService")
local Knit = require(ReplicatedStorage.Packages.Knit)
local EventDefinitions = require(ReplicatedStorage.Shared.EventDefinitions)
local CameraDefinitions = require(ReplicatedStorage.Shared.AdminCameraDefinitions)
local PlotLocator = require(game:GetService("ServerScriptService").PlotLocator)
local Teleports = require(game:GetService("ServerScriptService").AdminCommandCenter.Teleports)

-- Add numeric UserIds here. The experience creator is authorized automatically.
local ADMIN_USER_IDS = {
	-- [123456789] = true,
}
local ADMIN_GROUP_ID = 0 -- Optional; 0 disables group-rank authorization.
local MIN_ADMIN_GROUP_RANK = 255
local ACTION_COOLDOWN = 0.35
local ROOM_CENTER = Vector3.new(0, 25000, 0)
local ROOM_WIDTH, ROOM_DEPTH, ROOM_HEIGHT = 170, 106, 40

local WeatherAdminService = Knit.CreateService({ Name = "WeatherAdminService", Client = {} })
-- Server-only integration: all admin tools use this service's existing policy.
WeatherAdminService.ActionRecorded = Instance.new("BindableEvent")
local WeatherEventService
local weatherState
local room
local boardState
local boardFeedback
local actionRemote
local cameraRemote
local lastAction = {}
local lastCameraAction = {}
local returnCFrames = {}
local groupOwnerResolved = false
local groupOwnerId
local lastGroupOwnerCheck
local eventIndicators = {}
local eventActiveLabels = {}
local indicatedEventId

local normalOrder = {
	"SunnySkies", "RainyDay", "Thunderstorm", "Snowfall", "Foggy", "Windy",
	"Heatwave", "Aurora", "BloodMoon", "MeteorShower", "SpiritNight", "Rainbow",
}
local secretOrder = { "Chaos", "Inverted", "Nightmare", "Void", "Golden", "AdminAbuse" }
local eventColors = {
	SunnySkies = Color3.fromRGB(244, 194, 76), RainyDay = Color3.fromRGB(74, 162, 220),
	Thunderstorm = Color3.fromRGB(72, 91, 178), Snowfall = Color3.fromRGB(157, 221, 240),
	Foggy = Color3.fromRGB(136, 158, 173), Windy = Color3.fromRGB(117, 194, 160),
	Heatwave = Color3.fromRGB(247, 133, 71), Aurora = Color3.fromRGB(118, 116, 236),
	BloodMoon = Color3.fromRGB(203, 69, 82), MeteorShower = Color3.fromRGB(242, 144, 91),
	SpiritNight = Color3.fromRGB(91, 194, 198), Rainbow = Color3.fromRGB(203, 124, 232),
	Chaos = Color3.fromRGB(245, 92, 175), Inverted = Color3.fromRGB(89, 222, 190),
	Nightmare = Color3.fromRGB(142, 52, 99), Void = Color3.fromRGB(112, 70, 177),
	Golden = Color3.fromRGB(255, 201, 58), AdminAbuse = Color3.fromRGB(230, 107, 241),
}

local function isAuthorized(player)
	if not player or not player:IsA("Player") or not player:IsDescendantOf(Players) then return false end
	local userId = player.UserId
	if ADMIN_USER_IDS[userId] then return true end
	if game.CreatorType == Enum.CreatorType.User and game.CreatorId == userId then return true end
	if game.CreatorType == Enum.CreatorType.Group then
		if not groupOwnerResolved and (not lastGroupOwnerCheck or os.clock() - lastGroupOwnerCheck >= 30) then
			lastGroupOwnerCheck = os.clock()
			local ok, info = pcall(GroupService.GetGroupInfoAsync, GroupService, game.CreatorId)
			if ok and type(info) == "table" then
				groupOwnerResolved = true
				if type(info.Owner) == "table" then groupOwnerId = info.Owner.Id end
			end
		end
		if groupOwnerId == userId then return true end
	end
	if ADMIN_GROUP_ID > 0 then
		local ok, rank = pcall(player.GetRankInGroup, player, ADMIN_GROUP_ID)
		if ok and rank >= MIN_ADMIN_GROUP_RANK then return true end
	end
	return false
end

local function makePart(name, size, cframe, tint, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Anchored = true
	part.CanCollide = true
	part.Material = material or Enum.Material.SmoothPlastic
	part.Color = tint
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = room
	return part
end

local function makeAccent(name, size, cframe, tint)
	local part = makePart(name, size, cframe, tint, Enum.Material.Neon)
	part.CanCollide = false
	part.CanTouch = false
	return part
end

local function makeText(part, name, value, tint, textSize, face)
	-- A pixel density preserves the physical face's aspect ratio, including
	-- top-facing pads (X/Z). A fixed 900x300 canvas stretched these labels.
	local surface = Instance.new("SurfaceGui")
	surface.Name = name .. "Surface"
	surface.Face = face or Enum.NormalId.Front
	surface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surface.PixelsPerStud = name == "Active" and 24 or (name == "Readout" and 16 or 12)
	surface.LightInfluence = 0
	surface.Parent = part
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = value
	label.TextColor3 = tint
	label.TextStrokeColor3 = Color3.fromRGB(8, 11, 22)
	label.TextStrokeTransparency = 1
	label.TextScaled = false
	label.TextSize = textSize or 24
	label.TextWrapped = name == "Readout" or name == "KingdomMark" or value:find("\n", 1, true) ~= nil or surface.Face == Enum.NormalId.Top
	label.Font = (name == "Title" or name == "KingdomMark") and Enum.Font.GothamBold or Enum.Font.GothamMedium
	label.TextXAlignment = name == "Readout" and Enum.TextXAlignment.Left or Enum.TextXAlignment.Center
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.RichText = false
	label.Parent = surface
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 8)
	padding.PaddingRight = UDim.new(0, 8)
	padding.PaddingTop = UDim.new(0, 4)
	padding.PaddingBottom = UDim.new(0, 4)
	padding.Parent = label
	return label
end

local function facingCenter(position)
	return CFrame.lookAt(position, Vector3.new(ROOM_CENTER.X, position.Y, ROOM_CENTER.Z))
end

local function feedback(message, button)
	if boardFeedback then boardFeedback.Text = message end
	if button and button.Parent then
		local originalColor = button.Color
		local originalCFrame = button.CFrame
		TweenService:Create(button, TweenInfo.new(0.12, Enum.EasingStyle.Quad), {
			Color = originalColor:Lerp(Color3.new(1, 1, 1), 0.55),
			CFrame = originalCFrame * (button:GetAttribute("PressDown") and CFrame.new(0, -0.2, 0) or CFrame.new(0, 0, 0.2)),
		}):Play()
		task.delay(0.13, function()
			if button.Parent then
				TweenService:Create(button, TweenInfo.new(0.17, Enum.EasingStyle.Quad), {
					Color = originalColor, CFrame = originalCFrame,
				}):Play()
			end
		end)
	end
end

local function getRoot(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 or not root then return nil end
	return root
end

local function isInsideRoom(player)
	local root = getRoot(player)
	if not root then return false end
	local relative = root.Position - ROOM_CENTER
	return math.abs(relative.X) < ROOM_WIDTH / 2 - 3
		and relative.Y > -2 and relative.Y < ROOM_HEIGHT - 2
		and math.abs(relative.Z) < ROOM_DEPTH / 2 - 3
end

local function normalSpawnCFrame(player)
	local plotId = player and player:GetAttribute("PlotId")
	if plotId then
		for _, plot in ipairs(PlotLocator.getPlots()) do
			if plot.Name == plotId then
				local marker = plot:FindFirstChild("PlotSpawn", true)
				if marker and marker:IsA("BasePart") then return marker.CFrame * CFrame.new(0, 3, 0) end
			end
		end
	end
	local spawn = workspace:FindFirstChild("MeadowSpawn", true)
	if spawn and spawn:IsA("BasePart") then return spawn.CFrame + Vector3.new(0, 5, 0) end
	local anySpawn = workspace:FindFirstChildWhichIsA("SpawnLocation", true)
	if anySpawn then return anySpawn.CFrame + Vector3.new(0, 5, 0) end
	return CFrame.new(0, 8, 0)
end

local function enterRoom(player)
	local root = getRoot(player)
	if not root then return false end
	local returnFrame = returnCFrames[player]
	if not isInsideRoom(player) then
		local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
		returnFrame = humanoid and humanoid.FloorMaterial ~= Enum.Material.Air and root.CFrame or nil
	end
	local moved = Teleports.Near(player, CFrame.lookAt(ROOM_CENTER + Vector3.new(0, 4.5, 36), ROOM_CENTER + Vector3.new(0, 4.5, -20)))
	if moved then returnCFrames[player] = returnFrame end
	return moved
end

local function returnToGame(player)
	local root = getRoot(player)
	if not root then return false end
	local saved = returnCFrames[player]
	local moved = saved and Teleports.Near(player, saved) or false
	if not moved then moved = Teleports.ToPlot(player, player) end
	if not moved then moved = Teleports.Near(player, normalSpawnCFrame(player)) end
	if moved then
		if cameraRemote then cameraRemote:FireClient(player, "Close") end
		returnCFrames[player] = nil
	end
	return moved
end

local function checkCooldown(player)
	local now = os.clock()
	local previous = lastAction[player]
	if previous and now - previous < ACTION_COOLDOWN then return false end
	lastAction[player] = now
	return true
end

local function dispatch(player, action, eventId, button)
	-- Shared by physical prompts, chat commands, and the remote. Never trust a client payload.
	if not checkCooldown(player) or not isAuthorized(player) or type(action) ~= "string" then return end
	if action == "Teleport" then
		if enterRoom(player) then
			feedback(player.DisplayName .. " entered the weather room", button)
			print("[WeatherAdmin] " .. player.Name .. " entered admin room")
		end
		return
	end
	if action == "Return" then
		if not isInsideRoom(player) then return end
		if returnToGame(player) then
			feedback(player.DisplayName .. " returned to the kingdom", button)
			print("[WeatherAdmin] Returning player: " .. player.Name)
		end
		return
	end
	if not isInsideRoom(player) then return end
	-- ClickDetectors can reach every wall panel; room membership remains the boundary.
	if action == "StartEvent" then
		if type(eventId) ~= "string" or not EventDefinitions[eventId] then return end
		WeatherEventService:StartEvent(eventId)
		WeatherAdminService.ActionRecorded:Fire(player, "started " .. EventDefinitions[eventId].DisplayName)
		feedback("Started " .. EventDefinitions[eventId].DisplayName .. " • " .. player.DisplayName, button)
		print("[WeatherAdmin] Starting event: " .. eventId)
	elseif action == "RandomEvent" then
		local selected = WeatherEventService:StartRandomAutomaticEvent()
		WeatherAdminService.ActionRecorded:Fire(player, "started random event " .. EventDefinitions[selected].DisplayName)
		feedback("Random event: " .. EventDefinitions[selected].DisplayName .. " • " .. player.DisplayName, button)
		print("[WeatherAdmin] Random event: " .. selected)
	elseif action == "EndEvent" then
		if WeatherEventService.CurrentPhase ~= "Event" then return end
		WeatherEventService:EndCurrentEvent()
		WeatherAdminService.ActionRecorded:Fire(player, "ended weather")
		feedback("Current event ended • " .. player.DisplayName, button)
		print("[WeatherAdmin] Ending current event")
	elseif action == "PauseAuto" then
		WeatherEventService:PauseAutomaticEvents()
		WeatherAdminService.ActionRecorded:Fire(player, "paused automatic weather")
		feedback("Automatic events paused • " .. player.DisplayName, button)
		print("[WeatherAdmin] Automatic events paused")
	elseif action == "ResumeAuto" then
		WeatherEventService:ResumeAutomaticEvents()
		WeatherAdminService.ActionRecorded:Fire(player, "resumed automatic weather")
		feedback("Automatic events resumed • " .. player.DisplayName, button)
		print("[WeatherAdmin] Automatic events resumed")
	end
end

local function addClick(button, handler)
	local detector = Instance.new("ClickDetector")
	detector.MaxActivationDistance = 150
	detector.Parent = button
	local baseColor = button.Color
	detector.MouseHoverEnter:Connect(function(player)
		if isAuthorized(player) and isInsideRoom(player) then
			TweenService:Create(button, TweenInfo.new(0.12), { Color = baseColor:Lerp(Color3.new(1, 1, 1), 0.16) }):Play()
		end
	end)
	detector.MouseHoverLeave:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.12), { Color = baseColor }):Play()
	end)
	detector.MouseClick:Connect(handler)
end

local function addActionClick(button, action, eventId)
	addClick(button, function(player)
		dispatch(player, action, eventId, button)
	end)
end

local WHITE = Color3.fromRGB(245, 248, 252)
local GRAY = Color3.fromRGB(205, 218, 231)
local NAVY = Color3.fromRGB(8, 24, 48)
local BLUE = Color3.fromRGB(25, 125, 255)
local CYAN = Color3.fromRGB(65, 210, 255)
local OFF = Color3.fromRGB(49, 75, 105)
local cameraAllowed = {}
for _, definition in ipairs(CameraDefinitions) do
	if type(definition.DisplayName) == "string" and definition.DisplayName:match("%S") then
		cameraAllowed[definition.Id] = definition
	end
end
local refreshSpecialCamera
local function selectCamera(player, id, button)
	if type(id) ~= "string" or not cameraAllowed[id] or not isAuthorized(player) or not isInsideRoom(player) then return end
	if refreshSpecialCamera and (id == "PlayerPlots" or id == "Town") then refreshSpecialCamera(id) end
	local folder = workspace:FindFirstChild("AK_AdminCameraPoints")
	if not folder or not folder:FindFirstChild(id) then return end
	local now = os.clock()
	if lastCameraAction[player] and now - lastCameraAction[player] < 0.15 then return end
	lastCameraAction[player] = now
	cameraRemote:FireClient(player, "Open", id)
	if button then feedback("Viewing live camera: " .. id, button) end
	print("[AdminCamera] Opening camera: " .. id)
end
local queueState
local serverState

local function roomPart(name, size, offset, color, material)
	return makePart(name, size, CFrame.new(ROOM_CENTER + offset), color, material)
end

local function lightPart(part, brightness, range, color)
	local light = Instance.new("PointLight")
	light.Brightness = brightness
	light.Range = range
	light.Color = color
	light.Parent = part
end

local function topLabel(part, name, value, color)
	return makeText(part, name, value, color, name == "KingdomMark" and 34 or 20, Enum.NormalId.Top)
end

local function makeWallCard(name, value, position, width, accent, height)
	height = height or 4.9
	local direction = math.abs(position.X - ROOM_CENTER.X) > 60
		and Vector3.new(position.X < ROOM_CENTER.X and 1 or -1, 0, 0)
		or Vector3.new(0, 0, 1)
	local face = CFrame.lookAt(position, position + direction)
	local frame = makePart(name .. "Frame", Vector3.new(width + 1.2, height + 0.9, 0.8), face * CFrame.new(0, 0, 0.15), GRAY, Enum.Material.Metal)
	local card = makePart(name, Vector3.new(width, height, 0.5), face * CFrame.new(0, 0, -0.4), NAVY, Enum.Material.SmoothPlastic)
	if value then makeText(card, "Label", value, WHITE, 24) end
	local accentPart = makeAccent(name .. "Accent", Vector3.new(0.25, height - 0.3, 0.13), face * CFrame.new(-width / 2 + 0.4, 0, -0.75), accent)
	return card, face, frame, accentPart
end

local function clearOldCameraPanels()
	local removed = 0
	for _, child in ipairs(room:GetDescendants()) do
		if child.Parent and (child.Name == "CameraWallPanels" or (child:IsA("BasePart") and child.Name:match("^Camera"))) then
			child:Destroy() -- Descendant UI and click detectors are destroyed with the part.
			removed += 1
		end
	end
	print("[WeatherAdminCamera] Old physical camera panels removed: " .. removed)
	return removed
end

local function createCameraPanel(definition, index, container)
	local id = definition.Id
	assert(type(definition.DisplayName) == "string" and definition.DisplayName:match("%S"),
		"Missing DisplayName for camera " .. tostring(id))
	local col = (index - 1) % 3
	local row = math.floor((index - 1) / 3)
	local position = ROOM_CENTER + Vector3.new(-29 + col * 29, 26.2 - row * 5.5, -51.2)
	local face = CFrame.lookAt(position, position + Vector3.new(0, 0, 1))
	local frame = makePart("Camera" .. id .. "Frame", Vector3.new(26.2, 5.2, 0.8), face * CFrame.new(0, 0, 0.15), GRAY, Enum.Material.Metal)
	local panel = makePart("Camera" .. id, Vector3.new(25, 5, 0.5), face * CFrame.new(0, 0, -0.4), NAVY, Enum.Material.SmoothPlastic)
	local accent = makeAccent("Camera" .. id .. "Accent", Vector3.new(0.25, 4.7, 0.13), face * CFrame.new(-12.1, 0, -0.75), CYAN)
	frame.Parent = container
	panel.Parent = container
	accent.Parent = container
	panel:SetAttribute("CameraId", id)
	panel:SetAttribute("CameraDisplayName", definition.DisplayName)
	addClick(panel, function(player)
		selectCamera(player, definition.Id, panel)
	end)
	panel:SetAttribute("CameraActionConnected", true)
	return panel
end

local CAMERA_LABELS = {
	"PLAYER PLOTS", "TOWN", "MEADOW",
	"FOREST", "JUNGLE", "DESERT",
	"SNOW", "VOLCANO", "OCEAN",
	"ANCIENT RUINS", "MAGICAL FOREST", "SKY",
	"PREHISTORIC", "MYTHICAL", "HIGH OVERVIEW",
}
local function attachCameraLabels()
	local container = room:FindFirstChild("CameraWallPanels")
	assert(container, "Existing camera wall panels missing")
	local panels = {}
	for _, child in ipairs(container:GetChildren()) do
		if child:IsA("BasePart") and child:FindFirstChildOfClass("ClickDetector") then
			table.insert(panels, child)
		end
	end
	assert(#panels == 15, string.format("Expected 15 existing camera panels; found %d", #panels))
	table.sort(panels, function(a, b)
		if math.abs(a.Position.Y - b.Position.Y) > 1 then return a.Position.Y > b.Position.Y end
		return a.Position.X < b.Position.X
	end)
	local playerPlotsSurface = panels[1]:FindFirstChildWhichIsA("SurfaceGui")
	local visibleFace = playerPlotsSurface and playerPlotsSurface.Face or Enum.NormalId.Front
	local surfaceCount, labelCount = 0, 0
	for index, panel in ipairs(panels) do
		for _, child in ipairs(panel:GetChildren()) do
			if child:IsA("SurfaceGui") or child:IsA("BillboardGui") then
				child:Destroy()
			end
		end
		local surface = Instance.new("SurfaceGui")
		surface.Name = "CameraNameSurface_NEW"
		surface.Adornee = panel
		surface.Parent = panel
		surface.Face = visibleFace
		surface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		surface.PixelsPerStud = 12
		surface.AlwaysOnTop = true
		surface.LightInfluence = 0
		surface.Enabled = true
		surfaceCount += 1
		local label = Instance.new("TextLabel")
		label.Name = "CameraName_NEW"
		label.Text = CAMERA_LABELS[index]
		label.Size = UDim2.fromScale(1, 1)
		label.Position = UDim2.fromScale(0, 0)
		label.BackgroundTransparency = 1
		label.TextColor3 = Color3.fromRGB(255, 255, 255)
		label.TextStrokeColor3 = Color3.fromRGB(0, 15, 50)
		label.TextStrokeTransparency = 1
		label.Font = Enum.Font.GothamBold
		label.TextScaled = false
		label.TextSize = 24
		label.TextWrapped = false
		label.TextXAlignment = Enum.TextXAlignment.Center
		label.TextYAlignment = Enum.TextYAlignment.Center
		label.Visible = true
		label.ZIndex = 50
		label.Parent = surface
		labelCount += 1
		local padding = Instance.new("UIPadding")
		padding.PaddingLeft = UDim.new(0, 10)
		padding.PaddingRight = UDim.new(0, 10)
		padding.Parent = label
	end
	assert(surfaceCount == 15 and labelCount == 15, "Camera label creation count mismatch")
end

local function eventButton(eventId, position, width, rare)
	local definition = EventDefinitions[eventId]
	local accent = rare and eventColors[eventId]:Lerp(BLUE, 0.45) or BLUE
	local button, face = makeWallCard(eventId .. "Button", definition.DisplayName, position, width, accent)
	local indicator = makeAccent(eventId .. "ActiveIndicator", Vector3.new(0.9, 0.9, 0.18), face * CFrame.new(width / 2 - 1.2, 0, -0.78), OFF)
	eventIndicators[eventId] = indicator
	local activeTag = makePart(eventId .. "ActiveTag", Vector3.new(5.5, 1.25, 0.15), face * CFrame.new(width / 2 - 3.6, -1.55, -0.79), NAVY)
	eventActiveLabels[eventId] = makeText(activeTag, "Active", "ACTIVE", OFF, 16)
	addActionClick(button, "StartEvent", eventId)
end

local function biomeRegion(id)
	-- Match BiomeTeleport.Landing.FindFloor: live top-level regions take priority
	-- over the Rojo blockout when a Studio place contains both.
	local liveRegion = workspace:FindFirstChild(id)
	if liveRegion then return liveRegion end
	local world = workspace:FindFirstChild("World")
	local regions = world and (world:FindFirstChild("BiomeBlockout") or world:FindFirstChild("Biomes"))
	return regions and regions:FindFirstChild(id)
end

local function regionBounds(region)
	if region:IsA("Model") then return region:GetBoundingBox() end
	local low, high
	for _, descendant in ipairs(region:GetDescendants()) do
		if descendant:IsA("BasePart") then
			local p, half = descendant.Position, descendant.Size * 0.5
			local a, b = p - half, p + half
			low = low and Vector3.new(math.min(low.X, a.X), math.min(low.Y, a.Y), math.min(low.Z, a.Z)) or a
			high = high and Vector3.new(math.max(high.X, b.X), math.max(high.Y, b.Y), math.max(high.Z, b.Z)) or b
		end
	end
	if low then return CFrame.new((low + high) * 0.5), high - low end
end

local function findAnchor(region)
	for _, name in ipairs({ "CameraAnchor", "CameraPoint", "BiomeCenter", "TeleportPoint", "TeleportSpawn", "SpawnPoint", "Entrance", "Center" }) do
		local anchor = region:FindFirstChild(name, true)
		if anchor and anchor:IsA("BasePart") then return anchor end
	end
end

local function clearView(position, target, ignored)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignored
	local overlap = OverlapParams.new()
	overlap.FilterType = Enum.RaycastFilterType.Exclude
	overlap.FilterDescendantsInstances = ignored
	for _, part in ipairs(workspace:GetPartBoundsInBox(CFrame.new(position), Vector3.new(5, 5, 5), overlap)) do
		if part.CanCollide and part.Transparency < 0.95 then return false end
	end
	local direction = target - position
	local hit = workspace:Raycast(position, direction, params)
	return not hit or (hit.Position - target).Magnitude < 22
end

local function cameraCFrame(target, size, ignored)
	local span = math.max(size.X, size.Z)
	local back = math.max(44, span * 0.48)
	local height = math.max(28, size.Y * 0.7 + span * 0.36)
	local position = target + Vector3.new(back * 0.18, height, back)
	for _ = 1, 4 do
		if clearView(position, target, ignored) then break end
		position += Vector3.new(0, math.max(14, span * 0.12), back * 0.08)
	end
	return CFrame.lookAt(position, target)
end

local function setCameraPoint(folder, id, displayName, cframe, target)
	local point = folder:FindFirstChild(id)
	if not point then
		point = Instance.new("Part")
		point.Name = id
		point.Parent = folder
	end
	point.Size = Vector3.new(1, 1, 1)
	point.CFrame = cframe
	point.Anchored = true
	point.CanCollide = false
	point.CanTouch = false
	point.CanQuery = false
	point.Transparency = 1
	point:SetAttribute("DisplayName", displayName)
	point:SetAttribute("TargetCenter", target)
	print("[AdminCamera] Camera point created: " .. id .. " target " .. tostring(target))
end

refreshSpecialCamera = function(id)
	local folder = workspace:FindFirstChild("AK_AdminCameraPoints")
	if not folder then return false end
	if id == "PlayerPlots" then
		local box, size = PlotLocator.getCollectionBounds()
		if not box then return false end
		local target = box.Position
		setCameraPoint(folder, id, cameraAllowed[id].DisplayName, cameraCFrame(target, size * 1.45, { folder, room }), target)
		return true
	elseif id == "Town" then
		local town = PlotLocator.getTown()
		-- The inspected live place keeps TownPlaza beside the town Folder.
		local plaza = workspace:FindFirstChild("TownPlaza") or (town and town:FindFirstChild("TownPlaza", true))
		local box, size
		if plaza and plaza:IsA("BasePart") then
			box, size = PlotLocator.getBounds(plaza)
		elseif town then
			box, size = regionBounds(town)
		end
		if not box then return false end
		local target = box.Position
		setCameraPoint(folder, id, cameraAllowed[id].DisplayName, cameraCFrame(target, size, { folder, room }), target)
		return true
	end
	return false
end

local function makeCameraPoints()
	local folder = workspace:FindFirstChild("AK_AdminCameraPoints")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "AK_AdminCameraPoints"
		folder.Parent = workspace
	end
	for _, child in ipairs(folder:GetChildren()) do
		if not cameraAllowed[child.Name] then child:Destroy() end
	end
	-- WorldService can populate gameplay objects after this service starts.
	task.spawn(function()
		local missing = {}
		for _, camera in ipairs(CameraDefinitions) do
			if camera.Target == "Biome" and cameraAllowed[camera.Id] then missing[camera.Id] = camera end
		end
		local plotsDone, townDone, highDone = false, false, false
		for attempt = 1, 30 do
			local overallLow, overallHigh
			for _, camera in ipairs(CameraDefinitions) do
				if camera.Target ~= "Biome" or not cameraAllowed[camera.Id] then continue end
				local region = biomeRegion(camera.Id)
				if region then
					local box, size = regionBounds(region)
					if box and size then
						local center = box.Position
						local half = size * 0.5
						local a, b = center - half, center + half
						overallLow = overallLow and Vector3.new(math.min(overallLow.X, a.X), math.min(overallLow.Y, a.Y), math.min(overallLow.Z, a.Z)) or a
						overallHigh = overallHigh and Vector3.new(math.max(overallHigh.X, b.X), math.max(overallHigh.Y, b.Y), math.max(overallHigh.Z, b.Z)) or b
						if missing[camera.Id] then
							local anchor = findAnchor(region)
							local target = anchor and anchor.Position or center
							setCameraPoint(folder, camera.Id, camera.DisplayName, cameraCFrame(target, size, { folder, room }), target)
							missing[camera.Id] = nil
						end
					end
				end
			end
			if not plotsDone then
				plotsDone = refreshSpecialCamera("PlayerPlots")
			end
			if not townDone then
				townDone = refreshSpecialCamera("Town")
			end
			if not highDone and overallLow and overallHigh then
				local center = (overallLow + overallHigh) * 0.5
				local size = overallHigh - overallLow
				setCameraPoint(folder, "HighOverview", cameraAllowed.HighOverview.DisplayName, cameraCFrame(center, size, { folder, room }), center)
				highDone = true
			end
			if plotsDone and townDone and highDone and next(missing) == nil then break end
			task.wait(2)
		end
		for id in pairs(missing) do warn("[AdminCamera] Missing biome region for camera: " .. id) end
		if not plotsDone then warn("[AdminCamera] Existing player plots not found; PlayerPlots camera unavailable") end
		if not townDone then warn("[AdminCamera] AnimalKingdomTown not found; Town camera unavailable") end
	end)
end

local function buildRoom()
	local existing = workspace:FindFirstChild("WeatherAdminRoom")
	assert(not existing, "WeatherAdminRoom already exists; refusing to overwrite an existing room")
	room = Instance.new("Model")
	room.Name = "WeatherAdminRoom"
	room.Parent = workspace
	roomPart("Floor", Vector3.new(ROOM_WIDTH, 2, ROOM_DEPTH), Vector3.new(0, -1, 0), WHITE, Enum.Material.Marble)
	roomPart("Ceiling", Vector3.new(ROOM_WIDTH, 2, ROOM_DEPTH), Vector3.new(0, ROOM_HEIGHT + 1, 0), WHITE, Enum.Material.SmoothPlastic)
	for _, side in ipairs({ -1, 1 }) do
		roomPart(side < 0 and "LeftWall" or "RightWall", Vector3.new(2, ROOM_HEIGHT, ROOM_DEPTH), Vector3.new(side * 85, 20, 0), WHITE, Enum.Material.SmoothPlastic)
		roomPart("WallLowerPanel", Vector3.new(1, 4, 102), Vector3.new(side * 83.7, 2, 0), GRAY, Enum.Material.Metal)
		makeAccent("WallRecessLine", Vector3.new(0.18, 0.25, 96), CFrame.new(ROOM_CENTER + Vector3.new(side * 83.1, 35.5, 0)), BLUE)
		makeAccent("FloorEdge", Vector3.new(0.25, 0.13, 95), CFrame.new(ROOM_CENTER + Vector3.new(side * 77, 0.1, 0)), CYAN)
		for _, z in ipairs({ -48, 0, 48 }) do
			roomPart("ArchitecturalColumn", Vector3.new(3, 35, 3), Vector3.new(side * 81, 18, z), WHITE, Enum.Material.Marble)
			makeAccent("ColumnInset", Vector3.new(0.18, 27, 0.25), CFrame.new(ROOM_CENTER + Vector3.new(side * 79.3, 18, z)), BLUE)
		end
	end
	roomPart("FrontWall", Vector3.new(ROOM_WIDTH, ROOM_HEIGHT, 2), Vector3.new(0, 20, -53), WHITE, Enum.Material.SmoothPlastic)
	roomPart("BackWall", Vector3.new(ROOM_WIDTH, ROOM_HEIGHT, 2), Vector3.new(0, 20, 53), WHITE, Enum.Material.SmoothPlastic)
	for _, x in ipairs({ -65, -33, 0, 33, 65 }) do
		roomPart("CeilingBay", Vector3.new(21, 0.5, 76), Vector3.new(x, 39.65, 0), GRAY, Enum.Material.Metal)
		makeAccent("BlueCeilingStrip", Vector3.new(0.22, 0.1, 76), CFrame.new(ROOM_CENTER + Vector3.new(x + 11, 39.35, 0)), BLUE)
		for _, z in ipairs({ -29, 0, 29 }) do
			local fixture = roomPart("CircularCeilingLight", Vector3.new(7, 0.25, 7), Vector3.new(x, 39.2, z), WHITE, Enum.Material.SmoothPlastic)
			fixture.Shape = Enum.PartType.Cylinder
			local glow = makeAccent("CircularLightInset", Vector3.new(5.6, 0.12, 5.6), CFrame.new(ROOM_CENTER + Vector3.new(x, 39.02, z)), WHITE)
			glow.Shape = Enum.PartType.Cylinder
			lightPart(glow, 0.75, 32, WHITE)
		end
	end
	for _, z in ipairs({ -46, 46 }) do
		makeAccent("FloorCrossStrip", Vector3.new(148, 0.08, 0.25), CFrame.new(ROOM_CENTER + Vector3.new(0, 0.04, z)), BLUE)
	end
	local floorCircle = roomPart("AnimalKingdomFloorMedallion", Vector3.new(38, 0.12, 38), Vector3.new(0, 0.08, 36), WHITE, Enum.Material.Marble)
	floorCircle.Shape = Enum.PartType.Cylinder
	local ring = roomPart("MedallionBlueRing", Vector3.new(34, 0.13, 34), Vector3.new(0, 0.16, 36), BLUE, Enum.Material.Metal)
	ring.Shape = Enum.PartType.Cylinder
	local middle = roomPart("MedallionCenter", Vector3.new(31, 0.14, 31), Vector3.new(0, 0.23, 36), WHITE, Enum.Material.Marble)
	middle.Shape = Enum.PartType.Cylinder
	topLabel(middle, "KingdomMark", "ANIMAL KINGDOM", NAVY)

	-- Event consoles sit inside framed navy wall recesses. Clicks use the existing dispatcher.
	for _, side in ipairs({ -1, 1 }) do
		local frame = makePart("EventConsoleFrame", Vector3.new(94, 34, 1.1), facingCenter(ROOM_CENTER + Vector3.new(side * 82.9, 20, 0)), GRAY, Enum.Material.Metal)
		frame.CanCollide = false
		local display = makePart("EventConsoleDisplay", Vector3.new(91, 31.5, 0.5), frame.CFrame * CFrame.new(0, 0, -0.8), NAVY, Enum.Material.SmoothPlastic)
		display.CanCollide = false
		makeAccent("EventConsoleHeaderRule", Vector3.new(86, 0.16, 0.12), display.CFrame * CFrame.new(0, 12.1, -0.34), side < 0 and BLUE or Color3.fromRGB(153, 113, 239))
	end
	local normalHeader = makePart("NormalHeader", Vector3.new(45, 3, 0.3), facingCenter(ROOM_CENTER + Vector3.new(-81.8, 34, 0)), NAVY)
	makeText(normalHeader, "Title", "NORMAL EVENTS", WHITE, 28)
	for index, id in ipairs(normalOrder) do
		local column = (index - 1) % 3
		local row = math.floor((index - 1) / 3)
		eventButton(id, ROOM_CENTER + Vector3.new(-81.1, 27 - row * 7.2, -30 + column * 30), 26, false)
	end
	local rareHeader = makePart("RareHeader", Vector3.new(45, 3, 0.3), facingCenter(ROOM_CENTER + Vector3.new(81.8, 34, 0)), NAVY)
	makeText(rareHeader, "Title", "RARE EVENTS", WHITE, 28)
	for index, id in ipairs(secretOrder) do
		local column = (index - 1) % 2
		local row = math.floor((index - 1) / 2)
		eventButton(id, ROOM_CENTER + Vector3.new(81.1, 25 - row * 9, -22 + column * 44), 37, true)
	end

	local brand = makePart("KingdomBrand", Vector3.new(92, 7, 0.5), facingCenter(ROOM_CENTER + Vector3.new(0, 36, -51.5)), WHITE, Enum.Material.Marble)
	makeText(brand, "Title", "ANIMAL KINGDOM\nWEATHER CONTROL CENTER", NAVY, 34)
	makeAccent("BrandUnderline", Vector3.new(90, 0.2, 0.2), brand.CFrame * CFrame.new(0, -3.8, -0.35), BLUE)
	local cameraHeader = makePart("LiveCameraHeader", Vector3.new(65, 3, 0.5), facingCenter(ROOM_CENTER + Vector3.new(0, 30.5, -51.6)), NAVY)
	makeText(cameraHeader, "Title", "LIVE MAP CAMERAS", WHITE, 28)
	clearOldCameraPanels()
	local cameraContainer = Instance.new("Model")
	cameraContainer.Name = "CameraWallPanels"
	cameraContainer.Parent = room
	local cameraPanels = {}
	assert(#CameraDefinitions == 15, "Weather camera wall requires exactly 15 camera definitions")
	for index, definition in ipairs(CameraDefinitions) do
		local panel = createCameraPanel(definition, index, cameraContainer)
		table.insert(cameraPanels, { Part = panel, Id = definition.Id, DisplayName = definition.DisplayName })
	end
	assert(#cameraPanels == 15, "Weather camera wall did not create exactly 15 camera panels")

	-- Raised station, recessed screens, and a deep angled control deck.
	roomPart("CommandPlatform", Vector3.new(82, 1, 33), Vector3.new(0, 0.5, 2), GRAY, Enum.Material.Marble)
	roomPart("CommandStep", Vector3.new(82, 0.5, 5), Vector3.new(0, 0.25, 21), WHITE, Enum.Material.Marble)
	makeAccent("PlatformFrontLight", Vector3.new(81, 0.18, 0.22), CFrame.new(ROOM_CENTER + Vector3.new(0, 1.05, -14.5)), BLUE)
	roomPart("ConsolePedestal", Vector3.new(76, 4.5, 17), Vector3.new(0, 3.3, 1), WHITE, Enum.Material.SmoothPlastic)
	roomPart("ConsoleTop", Vector3.new(78, 0.8, 20), Vector3.new(0, 5.9, 1), WHITE, Enum.Material.Metal)
	for _, x in ipairs({ -31, 31 }) do
		local wedge = Instance.new("WedgePart")
		wedge.Name = "AngledConsoleWing"
		wedge.Size = Vector3.new(14, 5, 18)
		wedge.CFrame = CFrame.new(ROOM_CENTER + Vector3.new(x, 3.9, 1)) * CFrame.Angles(0, x < 0 and math.rad(-12) or math.rad(12), 0)
		wedge.Color = WHITE
		wedge.Material = Enum.Material.Metal
		wedge.Anchored = true
		wedge.Parent = room
	end
	makeAccent("ConsoleBlueLip", Vector3.new(78, 0.18, 0.25), CFrame.new(ROOM_CENTER + Vector3.new(0, 6.4, 11)), CYAN)
	makeAccent("UnderConsoleLight", Vector3.new(69, 0.2, 0.3), CFrame.new(ROOM_CENTER + Vector3.new(0, 1.1, 9.6)), BLUE)
	for index, spec in ipairs({
		{ "CurrentEventBoard", "CURRENT EVENT\nLoading..." },
		{ "EventQueueBoard", "NEXT EVENT / EVENT QUEUE\nAUTOMATIC / RANDOM" },
		{ "ServerStatusBoard", "SERVER STATUS\nLoading..." },
	}) do
		local x = -25 + (index - 1) * 25
		roomPart(spec[1] .. "Housing", Vector3.new(23.5, 0.4, 8.5), Vector3.new(x, 6.45, -3.7), GRAY, Enum.Material.Metal)
		local screen = roomPart(spec[1], Vector3.new(22.5, 0.3, 7.5), Vector3.new(x, 6.76, -3.7), NAVY, Enum.Material.SmoothPlastic)
		local label = topLabel(screen, "Readout", spec[2], WHITE)
		if index == 1 then boardState = label elseif index == 2 then queueState = label else serverState = label end
		makeAccent(spec[1] .. "Indicator", Vector3.new(20, 0.08, 0.13), CFrame.new(ROOM_CENTER + Vector3.new(x, 6.95, 0.1)), BLUE)
	end
	local controls = {
		{ "RandomEvent", "RANDOM EVENT", BLUE, -27 },
		{ "EndEvent", "END EVENT", Color3.fromRGB(203, 92, 99), -13.5 },
		{ "PauseAuto", "PAUSE AUTO", BLUE, 0 },
		{ "ResumeAuto", "RESUME AUTO", BLUE, 13.5 },
		{ "Return", "RETURN TO GAME", CYAN, 27 },
	}
	for _, entry in ipairs(controls) do
		local x = entry[4]
		roomPart(entry[1] .. "Socket", Vector3.new(12.4, 0.35, 5.4), Vector3.new(x, 6.5, 6), GRAY, Enum.Material.Metal)
		local button = roomPart(entry[1] .. "Button", Vector3.new(11.4, 0.55, 4.5), Vector3.new(x, 6.94, 6), entry[3], Enum.Material.SmoothPlastic)
		button:SetAttribute("PressDown", true)
		topLabel(button, "Label", entry[2], WHITE)
		addActionClick(button, entry[1])
	end
	local feedbackPanel = makePart("StatusPanel", Vector3.new(58, 3.1, 0.5), facingCenter(ROOM_CENTER + Vector3.new(0, 10.5, 50.8)), NAVY)
	boardFeedback = makeText(feedbackPanel, "Status", "Weather controls ready", WHITE, 22)
	roomPart("ArrivalPad", Vector3.new(23, 0.25, 13), Vector3.new(0, 0.13, 37), GRAY, Enum.Material.Metal)
	makeAccent("ArrivalGuide", Vector3.new(18, 0.1, 0.25), CFrame.new(ROOM_CENTER + Vector3.new(0, 0.31, 43)), CYAN)
	makeCameraPoints()
	print("[WeatherAdmin] White and blue control center created")
end

local function updateBoard()
	local phase = weatherState:GetAttribute("Phase") or "Break"
	local eventId = phase == "Event" and weatherState:GetAttribute("EventId") or nil
	if eventId ~= indicatedEventId then
		indicatedEventId = eventId
		for id, indicator in pairs(eventIndicators) do
			indicator.Color = id == eventId and Color3.fromRGB(113, 255, 165)
				or eventColors[id]:Lerp(Color3.fromRGB(12, 17, 28), 0.7)
			eventActiveLabels[id].TextColor3 = id == eventId and Color3.fromRGB(113, 255, 165) or OFF
		end
	end
	local eventName = weatherState:GetAttribute("EventName") or ""
	local deadline = phase == "Event" and weatherState:GetAttribute("EndsAt") or weatherState:GetAttribute("BreakEndsAt")
	local seconds = type(deadline) == "number" and math.max(0, math.ceil(deadline - workspace:GetServerTimeNow())) or 0
	local timeText = string.format("%d:%02d", math.floor(seconds / 60), seconds % 60)
	local automatic = weatherState:GetAttribute("AutomaticPaused") and "PAUSED" or "ON"
	boardState.Text = string.format("CURRENT EVENT\n%s\nPhase: %s  •  %s: %s\nAutomatic Events: %s", eventName ~= "" and eventName or "None", phase, phase == "Event" and "Time Left" or "Break Time", timeText, automatic)
	local queuedId = weatherState:GetAttribute("QueuedEventId")
	local queued = queuedId and EventDefinitions[queuedId]
	queueState.Text = "NEXT EVENT / EVENT QUEUE\n" .. (queued and queued.DisplayName or "AUTOMATIC / RANDOM") .. "\nAuto events: " .. automatic
	serverState.Text = string.format("SERVER STATUS\nPlayers: %d\nAuto: %s  |  Phase: %s", #Players:GetPlayers(), automatic, phase)
end

local function addCommand(name, primary, secondary, action)
	local command = TextChatService:FindFirstChild(name)
	if not command then
		command = Instance.new("TextChatCommand")
		command.Name = name
		command.PrimaryAlias = primary
		command.SecondaryAlias = secondary
		command.AutocompleteVisible = false
		command.Parent = TextChatService
	end
	assert(command:IsA("TextChatCommand"), name .. " must be a TextChatCommand")
	command.Triggered:Connect(function(textSource)
		local player = Players:GetPlayerByUserId(textSource.UserId)
		if player then dispatch(player, action) end
	end)
end

function WeatherAdminService:IsAuthorized(player)
	return isAuthorized(player)
end

function WeatherAdminService:IsInsideRoom(player)
	return isInsideRoom(player)
end

function WeatherAdminService:EnterAdminRoom(player)
	if not isAuthorized(player) then return false end
	return enterRoom(player)
end

function WeatherAdminService:KnitInit()
	WeatherEventService = Knit.GetService("WeatherEventService")
end

function WeatherAdminService:KnitStart()
	buildRoom()
	attachCameraLabels()
	weatherState = ReplicatedStorage:WaitForChild("WeatherState")
	local remotes = ReplicatedStorage:FindFirstChild("AnimalKingdomRemotes")
	if not remotes then
		remotes = Instance.new("Folder")
		remotes.Name = "AnimalKingdomRemotes"
		remotes.Parent = ReplicatedStorage
	end
	assert(remotes:IsA("Folder"), "AnimalKingdomRemotes must be a Folder")
	actionRemote = remotes:FindFirstChild("WeatherAdminAction")
	if not actionRemote then
		actionRemote = Instance.new("RemoteEvent")
		actionRemote.Name = "WeatherAdminAction"
		actionRemote.Parent = remotes
	end
	assert(actionRemote:IsA("RemoteEvent"), "WeatherAdminAction must be a RemoteEvent")
	cameraRemote = remotes:FindFirstChild("AdminCameraControl")
	if not cameraRemote then
		cameraRemote = Instance.new("RemoteEvent")
		cameraRemote.Name = "AdminCameraControl"
		cameraRemote.Parent = remotes
	end
	assert(cameraRemote:IsA("RemoteEvent"), "AdminCameraControl must be a RemoteEvent")
	cameraRemote.OnServerEvent:Connect(function(player, command, cameraId)
		if not isAuthorized(player) or not isInsideRoom(player) then return end
		if command == "Select" then
			selectCamera(player, cameraId)
		elseif command == "Exit" then
			cameraRemote:FireClient(player, "Close")
		end
	end)
	actionRemote.OnServerEvent:Connect(function(player, payload)
		if type(payload) ~= "table" then return end
		dispatch(player, payload.Action, payload.EventId)
	end)
	addCommand("WeatherRoomCommand", "/weatherroom", "/weatheradmin", "Teleport")
	addCommand("WeatherReturnCommand", "/return", "/weatherreturn", "Return")
	Players.PlayerRemoving:Connect(function(player)
		lastAction[player] = nil
		lastCameraAction[player] = nil
		returnCFrames[player] = nil
	end)
	local function watchPlayer(player)
		player.CharacterAdded:Connect(function()
			-- Respawns use the normal game spawn; no admin-room SpawnLocation is created.
			returnCFrames[player] = nil
			cameraRemote:FireClient(player, "Close")
		end)
	end
	Players.PlayerAdded:Connect(watchPlayer)
	for _, player in ipairs(Players:GetPlayers()) do watchPlayer(player) end
	task.spawn(function()
		while room.Parent do
			updateBoard()
			task.wait(0.5)
		end
	end)
end

return WeatherAdminService
