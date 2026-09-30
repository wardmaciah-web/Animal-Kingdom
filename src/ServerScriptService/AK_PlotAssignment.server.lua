local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlotLocator = require(script.Parent.PlotLocator)
local Teleports = require(script.Parent.AdminCommandCenter.Teleports)

local playerPlots = {}
local plotOwners = {}
local joining = {}
local initializedPlots = {}
local remotes = ReplicatedStorage:FindFirstChild("AnimalKingdomRemotes")
if not remotes then
	remotes = Instance.new("Folder")
	remotes.Name = "AnimalKingdomRemotes"
	remotes.Parent = ReplicatedStorage
end
local assignedRemote = remotes:FindFirstChild("AK_PlotAssigned")
if not assignedRemote then
	assignedRemote = Instance.new("RemoteEvent")
	assignedRemote.Name = "AK_PlotAssigned"
	assignedRemote.Parent = remotes
end

local function getPlots()
	return PlotLocator.getPlots()
end

local function getPlayerPlot(player)
	return playerPlots[player]
end

local function findAvailablePlot()
	for _, plot in ipairs(getPlots()) do
		if not plotOwners[plot] and plot:GetAttribute("Claimed") ~= true then return plot end
	end
end

local function plotFootprint(plot)
	if plot:IsA("BasePart") then return plot.CFrame, plot.Size, plot end
	local selected, score = nil, -math.huge
	for _, part in ipairs(plot:GetDescendants()) do
		if part:IsA("BasePart") and part.Size.X >= 10 and part.Size.Z >= 10 then
			local name = part.Name:lower()
			local floorName = name:find("floor", 1, true) or name:find("ground", 1, true)
				or name:find("base", 1, true) or name:find("platform", 1, true)
			local candidateScore = part.Size.X * part.Size.Z + (floorName and 1000000 or 0)
			if candidateScore > score then selected, score = part, candidateScore end
		end
	end
	if selected then return selected.CFrame, selected.Size, selected end
	local cf, size = PlotLocator.getBounds(plot)
	return cf, size, nil
end

local function findSpawn(plot)
	local cf, size = plotFootprint(plot)
	for _, name in ipairs({ "PlotSpawn", "PlayerSpawn", "SpawnPoint", "Spawn", "SpawnLocation" }) do
		local marker = plot:FindFirstChild(name, true)
		if marker and marker:IsA("BasePart") and cf then
			local relative = cf:PointToObjectSpace(marker.Position)
			if math.abs(relative.X) <= size.X * 0.5 - 1 and math.abs(relative.Z) <= size.Z * 0.5 - 1 then
				return marker
			end
		end
	end
end

local function ensureSpawn(plot)
	local marker = findSpawn(plot)
	local validExisting = marker ~= nil
	if not marker then
		local prior = plot:FindFirstChild("PlotSpawn", true)
		if prior and prior:IsA("BasePart") then marker = prior end
	end
	if marker and marker.Name ~= "PlotSpawn" then return marker end
	local isPriorGenerated = marker and plot:IsA("BasePart") and marker.Transparency == 1 and not marker.CanCollide
		and marker.Size.X <= 1.1 and marker.Size.Y <= 1.1 and marker.Size.Z <= 1.1
	if marker and validExisting and not marker:GetAttribute("AKGeneratedPlotSpawn") and not isPriorGenerated then return marker end
	local cf, size, floor = plotFootprint(plot)
	if not cf then return end
	local center = cf.Position
	local town = PlotLocator.getTown()
	local plaza = town and town:FindFirstChild("TownPlaza", true)
	local townCenter = plaza and plaza:IsA("BasePart") and plaza.Position or nil
	local outward = townCenter and Vector3.new(center.X - townCenter.X, 0, center.Z - townCenter.Z) or Vector3.zero
	if outward.Magnitude > 0.01 then outward = outward.Unit else outward = Vector3.zero end
	local horizontalOffset = outward * math.min(size.X, size.Z) * 0.18
	local desired = center + horizontalOffset
	local top = floor and floor.CanCollide and (floor.Position.Y + floor.Size.Y * 0.5) or nil
	if not top then
		local ray = RaycastParams.new()
		ray.FilterType = Enum.RaycastFilterType.Exclude
		ray.FilterDescendantsInstances = { plot }
		local hit = workspace:Raycast(desired + Vector3.new(0, math.max(120, size.Y + 50), 0), Vector3.new(0, -math.max(400, size.Y + 250), 0), ray)
		top = hit and hit.Position.Y or center.Y + size.Y * 0.5
	end
	if not marker then
		marker = Instance.new("Part")
		marker.Name = "PlotSpawn"
		marker.Size = Vector3.new(1, 1, 1)
		marker.Parent = plot
	end
	marker.CFrame = CFrame.new(desired.X, top + 0.5, desired.Z)
	marker.Anchored = true
	marker.Transparency = 1
	marker.CanCollide = false
	marker.CanTouch = false
	marker.CanQuery = false
	marker:SetAttribute("AKGeneratedPlotSpawn", true)
	return marker
end

local function ownerDisplay(plot)
	local existing = plot:FindFirstChild("AK_PlotOwnerBillboard", true)
	if existing and existing:IsA("BillboardGui") then
		local label = existing:FindFirstChild("OwnerText", true)
		if label and label:IsA("TextLabel") then
			existing.Size = UDim2.fromOffset(210, 44)
			existing.StudsOffset = Vector3.zero
			existing.StudsOffsetWorldSpace = Vector3.new(0, 5, 0)
			existing.MaxDistance = 105
			local panel = label.Parent
			if panel:IsA("Frame") then
				panel.BackgroundColor3 = Color3.fromRGB(8, 24, 48)
				panel.BackgroundTransparency = 0.18
			end
			label.TextColor3 = Color3.fromRGB(245, 248, 252)
			label.TextStrokeColor3 = Color3.fromRGB(25, 125, 255)
			label.TextStrokeTransparency = 0.2
			return label, existing
		end
	end
	for _, name in ipairs({ "OwnerSign", "PlotSign", "PlotOwnerSign", "OwnerBillboard" }) do
		local sign = plot:FindFirstChild(name, true)
		if sign then
			local label = sign:FindFirstChildWhichIsA("TextLabel", true)
			local gui = label and label:FindFirstAncestorWhichIsA("LayerCollector")
			if label and gui and (gui:IsA("BillboardGui") or gui:IsA("SurfaceGui")) then
				if gui:IsA("BillboardGui") then
					gui.Size = UDim2.fromOffset(210, 44)
					gui.MaxDistance = 105
				end
				return label, gui
			end
		end
	end
	local marker = ensureSpawn(plot)
	if not marker then return end
	local gui = Instance.new("BillboardGui")
	gui.Name = "AK_PlotOwnerBillboard"
	gui.Size = UDim2.fromOffset(210, 44)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 5, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 105
	gui.Enabled = false
	gui.Parent = marker
	local panel = Instance.new("Frame")
	panel.Size = UDim2.fromScale(1, 1)
	panel.BackgroundColor3 = Color3.fromRGB(8, 24, 48)
	panel.BackgroundTransparency = 0.18
	panel.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = panel
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(25, 125, 255)
	stroke.Thickness = 2
	stroke.Parent = panel
	local label = Instance.new("TextLabel")
	label.Name = "OwnerText"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(245, 248, 252)
	label.TextStrokeColor3 = Color3.fromRGB(25, 125, 255)
	label.TextStrokeTransparency = 0.2
	label.Parent = panel
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 10)
	padding.Parent = label
	return label, gui
end

local function updateOwnerDisplay(plot, player)
	-- Clear any label saved from the previous version before showing ownership.
	for _, descendant in ipairs(plot:GetDescendants()) do
		if descendant:IsA("TextLabel") and descendant.Text == "AVAILABLE PLOT" then
			descendant.Text = ""
			descendant.Visible = false
		end
	end
	local label, gui = ownerDisplay(plot)
	if not label or not gui then return end
	local claimed = player ~= nil
	label.Text = claimed and player.Name or ""
	label.Visible = claimed
	gui.Enabled = claimed
end

local function preparePlots(plots)
	for _, plot in ipairs(plots) do
		if not initializedPlots[plot] then
			initializedPlots[plot] = true
			plot:SetAttribute("OwnerUserId", 0)
			plot:SetAttribute("OwnerUsername", "")
			plot:SetAttribute("Claimed", false)
			ensureSpawn(plot)
			updateOwnerDisplay(plot, nil)
		end
	end
end

local function claimPlot(player, plot)
	-- No yield between the availability check and the two ownership writes.
	if plotOwners[plot] or plot:GetAttribute("Claimed") == true or playerPlots[player] then return false end
	plotOwners[plot] = player
	playerPlots[player] = plot
	plot:SetAttribute("OwnerUserId", player.UserId)
	plot:SetAttribute("OwnerUsername", player.Name)
	plot:SetAttribute("Claimed", true)
	player:SetAttribute("PlotId", plot.Name)
	player:SetAttribute("HasPlot", true)
	return true
end

local function releasePlot(player)
	local plot = playerPlots[player]
	if not plot then return end
	playerPlots[player] = nil
	plotOwners[plot] = nil
	if plot.Parent then
		plot:SetAttribute("OwnerUserId", 0)
		plot:SetAttribute("OwnerUsername", "")
		plot:SetAttribute("Claimed", false)
		updateOwnerDisplay(plot, nil)
	end
	player:SetAttribute("PlotId", "")
	player:SetAttribute("HasPlot", false)
	print("[PlotAssignment] Released " .. plot.Name)
end

local function teleportCharacterToPlot(player, character)
	local plot = getPlayerPlot(player)
	if not plot or not plot.Parent then return end
	local root = character:WaitForChild("HumanoidRootPart", 10)
	if not root or player.Character ~= character or not player:IsDescendantOf(Players) then return end
	-- Let Roblox finish its initial spawn placement before moving the character.
	task.wait(0.15)
	if player.Character ~= character or getPlayerPlot(player) ~= plot then return end
	local marker = ensureSpawn(plot)
	if not marker then return end
	local moved, reason = Teleports.Near(player, marker.CFrame)
	if not moved then
		warn("[PlotAssignment] Safe spawn unavailable for " .. player.Name .. ": " .. tostring(reason))
		return
	end
	print("[PlotAssignment] Spawned " .. player.Name .. " at " .. plot.Name)
end

local function assignPlayer(player)
	if joining[player] or getPlayerPlot(player) then return end
	joining[player] = true
	local plots = getPlots()
	for _ = 1, 20 do
		if #plots > 0 or not player:IsDescendantOf(Players) then break end
		task.wait(1)
		plots = getPlots()
	end
	if not player:IsDescendantOf(Players) then joining[player] = nil; return end
	if #plots == 0 then
		joining[player] = nil
		warn("[PlotAssignment] No player plots found; assignment unavailable for " .. player.Name)
		return
	end
	preparePlots(plots)
	local plot = findAvailablePlot()
	if not plot or not claimPlot(player, plot) then
		joining[player] = nil
		print("[PlotAssignment] No available plots for " .. player.Name)
		player:Kick("All Animal Kingdom plots in this server are currently claimed. Please join another server.")
		return
	end
	joining[player] = nil
	local marker = ensureSpawn(plot)
	updateOwnerDisplay(plot, player)
	print("[PlotAssignment] Assigned " .. plot.Name .. " to " .. player.Name)
	if marker then assignedRemote:FireClient(player, plot.Name, player.Name) end
	player.CharacterAdded:Connect(function(character)
		task.defer(teleportCharacterToPlot, player, character)
	end)
	if player.Character then task.defer(teleportCharacterToPlot, player, player.Character) end
end

local plots = getPlots()
local container = PlotLocator.getContainer()
print("[PlotAssignment] Found " .. #plots .. " plots at " .. (container and container:GetFullName() or "<not loaded>"))
for _, plot in ipairs(plots) do print("[PlotAssignment] Plot: " .. plot:GetFullName()) end
preparePlots(plots)
if #plots == 0 then
	task.spawn(function()
		for _ = 1, 30 do
			task.wait(1)
			local loaded = getPlots()
			if #loaded > 0 then
				preparePlots(loaded)
				local loadedContainer = PlotLocator.getContainer()
				print("[PlotAssignment] Found " .. #loaded .. " plots at " .. (loadedContainer and loadedContainer:GetFullName() or "<unknown>"))
				for _, plot in ipairs(loaded) do print("[PlotAssignment] Plot: " .. plot:GetFullName()) end
				break
			end
		end
	end)
end
Players.PlayerAdded:Connect(function(player)
	task.spawn(assignPlayer, player)
end)
Players.PlayerRemoving:Connect(function(player)
	joining[player] = nil
	releasePlot(player)
end)
for _, player in ipairs(Players:GetPlayers()) do task.spawn(assignPlayer, player) end
