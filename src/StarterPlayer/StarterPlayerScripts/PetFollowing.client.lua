-- Server publishes equipped state. All movement here is cosmetic and local.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Run = game:GetService("RunService")
local Http = game:GetService("HttpService")
local Gameplay = RS.Shared.Gameplay
local Appearance = require(Gameplay.PetAppearance)
local Geometry = require(Gameplay.PetVisualGeometry)
local Formation = require(Gameplay.FollowerFormation)
local Definitions = require(Gameplay.Definitions.PetDefinitions)
local localPlayer = Players.LocalPlayer
local folder = Instance.new("Folder")
folder.Name = "LocalPetFollowers"
folder.Parent = workspace
local records, connections = {}, {}
local active, visibilityElapsed, filterElapsed = {}, 1, 1
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.RespectCanCollide = true
rayParams.IgnoreWater = true
local alive = true
local studioProfile = Run:IsStudio()
local profileElapsed, profileTotal, profilePeak, profileFrames, profileRays, profileClones = 0, 0, 0, 0, 0, 0

local function destroyVisual(entry)
	if entry.Model then entry.Model:Destroy() end
	entry.Model, entry.Bounds, entry.Position, entry.Rotation, entry.Ground = nil, nil, nil, nil, nil
end
local function signature(pet)
	return table.concat({pet.PetId, pet.Mutation or "Normal", tostring(pet.Shiny), tostring(pet.Prismatic), pet.Cosmetic or "",tostring(pet.Weight),tostring(pet.CoinsPerSecond)}, "|")
end
local function refresh(player)
	local record = records[player]
	if not record then return end
	local ok, pets = pcall(Http.JSONDecode, Http, player:GetAttribute("EquippedPetData") or "[]")
	if not ok or type(pets) ~= "table" then return end
	local previous, nextPets = {}, {}
	for _, entry in ipairs(record.Pets) do previous[entry.Pet.UID] = entry end
	local seen = {}
	for i, pet in ipairs(pets) do
		if i > 1 then break end
		if type(pet) ~= "table" or type(pet.UID) ~= "string" or not Definitions[pet.PetId] or seen[pet.UID] then continue end
		seen[pet.UID] = true
		local entry = previous[pet.UID] or {Phase = Formation.Phase(pet.UID)}
		previous[pet.UID] = nil
		local nextSignature = signature(pet)
		if entry.Signature ~= nextSignature then destroyVisual(entry); entry.RetryAt = 0 end
		entry.Pet, entry.Signature = pet, nextSignature
		table.insert(nextPets, entry)
	end
	for _, entry in pairs(previous) do destroyVisual(entry) end
	record.Pets = nextPets
	visibilityElapsed = 1
end
local function add(player)
	if records[player] then return end
	local record = {Pets = {}}
	records[player] = record
	record.Connection = player:GetAttributeChangedSignal("EquippedPetData"):Connect(function() refresh(player) end)
	record.CharacterConnection = player.CharacterAdded:Connect(function()
		for _, entry in ipairs(record.Pets) do destroyVisual(entry); entry.RetryAt = 0 end
		filterElapsed, visibilityElapsed = 1, 1
	end)
	refresh(player)
end
local function remove(player)
	local record = records[player]
	if not record then return end
	record.Connection:Disconnect()
	record.CharacterConnection:Disconnect()
	for _, entry in ipairs(record.Pets) do destroyVisual(entry) end
	records[player] = nil
	visibilityElapsed, filterElapsed = 1, 1
end
connections[#connections + 1] = Players.PlayerAdded:Connect(add)
connections[#connections + 1] = Players.PlayerRemoving:Connect(remove)
for _, player in ipairs(Players:GetPlayers()) do add(player) end

-- Optional visual events must not hold up rendering while remotes replicate.
task.spawn(function()
	local remotes = RS:WaitForChild("AnimalKingdomRemotes", 30)
	local gather = remotes and remotes:WaitForChild("GatherVisual", 30)
	if not alive or not gather then return end
	connections[#connections + 1] = gather.OnClientEvent:Connect(function(userId, position, duration, _, phase)
		if phase=='Committed'then return end
		if typeof(position) ~= "Vector3" or type(duration) ~= "number" then return end
		local player = Players:GetPlayerByUserId(userId)
		local record = player and records[player]
		if record then record.Target, record.TargetUntil = position, os.clock() + math.clamp(duration, 0, 10) end
	end)
end)

-- Failed assets retry at most once every five seconds, including newly imported templates.
local function updateVisibility(now)
	local camera = workspace.CurrentCamera
	if not camera then return end
	local ordered = {}
	for player, record in pairs(records) do
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local distance = root and (camera.CFrame.Position - root.Position).Magnitude or math.huge
		table.insert(ordered, {Player = player, Record = record, Root = root, Distance = distance})
	end
	table.sort(ordered, function(a, b)
		if (a.Player == localPlayer) ~= (b.Player == localPlayer) then return a.Player == localPlayer end
		if a.Distance == b.Distance then return a.Player.UserId < b.Player.UserId end
		return a.Distance < b.Distance
	end)
	active = {}
	local budget = 60
	for _, row in ipairs(ordered) do
		local record, root = row.Record, row.Root
		local visible = root and row.Distance < (record.Visible and 195 or 180)
			and (row.Player == localPlayer or localPlayer:GetAttribute("AKShowOtherPets") ~= false)
		record.Visible, record.Spacing = visible, 3.5
		for _, entry in ipairs(record.Pets) do
			if not visible or budget <= 0 then destroyVisual(entry); continue end
			budget -= 1
			if not entry.Model and now >= (entry.RetryAt or 0) then
				entry.RetryAt = now + 5
				local created, model = pcall(Appearance.Create, entry.Pet, "Follower")
				if created and model then
					local bounds = Geometry.Measure(model)
					if bounds then
						entry.Model, entry.Bounds = model, bounds
      entry.Labels={}
      for _,label in ipairs(model:GetDescendants())do if label:IsA("BillboardGui")then label.Enabled=false;table.insert(entry.Labels,label)end end
						entry.ModelRotation = Geometry.ContextRotation(Definitions[entry.Pet.PetId], "Follower")
						entry.RetryAt = 0
						if studioProfile then profileClones += 1 end
						entry.GroundAt = now + entry.Phase / (math.pi * 2) * .1
					else model:Destroy() end
				end
			end
			if entry.Bounds then
				record.Spacing = math.max(record.Spacing, math.sqrt(entry.Bounds.Size.X ^ 2 + entry.Bounds.Size.Z ^ 2) + .65)
			end
		end
		if visible then table.insert(active, row) end
	end
 -- Name only the companion closest to the viewing center; twelve labels otherwise overlap.
 local nearest,score=nil,math.huge
 for _,row in ipairs(active)do for _,entry in ipairs(row.Record.Pets)do
  if entry.Model and entry.Model.Parent then
   local point,onScreen=camera:WorldToViewportPoint(entry.Model:GetPivot().Position)
   local offset=(Vector2.new(point.X,point.Y)-camera.ViewportSize/2).Magnitude
   if onScreen and point.Z<48 and offset<160 and offset<score then nearest=entry;score=offset end
  end
 end end
 for _,row in ipairs(active)do for _,entry in ipairs(row.Record.Pets)do for _,label in ipairs(entry.Labels or {})do label.Enabled=row.Player==localPlayer or entry==nearest end end end
end

connections[#connections + 1] = Run.RenderStepped:Connect(function(dt)
	local profileStart = studioProfile and os.clock() or 0
	if studioProfile then debug.profilebegin("AK PetFollowers") end
	local now = os.clock()
	visibilityElapsed += dt
	filterElapsed += dt
	if filterElapsed >= 1 then
		filterElapsed = 0
		local exclude = {folder}
		for _, player in ipairs(Players:GetPlayers()) do if player.Character then table.insert(exclude, player.Character) end end
		rayParams.FilterDescendantsInstances = exclude
	end
	if visibilityElapsed >= .2 then visibilityElapsed = 0; updateVisibility(now) end
	local reducedMotion = localPlayer:GetAttribute("AKReducedMotion") == true
	for _, row in ipairs(active) do
		local record, root = row.Record, row.Root
		if not root or not root.Parent then continue end
		local look = root.CFrame.LookVector * Vector3.new(1, 0, 1)
		if look.Magnitude < .01 then look = Vector3.new(0, 0, -1) else look = look.Unit end
		local rootRotation = CFrame.lookAt(Vector3.zero, look)
		for i, entry in ipairs(record.Pets) do
			local model, bounds = entry.Model, entry.Bounds
			if not model or not bounds then continue end
			local head=root.Parent:FindFirstChild("Head") or root
   local desired=head.Position+Vector3.new(0,head.Size.Y*.5+.6,0)
   local snap=not entry.Position or (entry.Position-desired).Magnitude>60
   entry.Position=snap and desired or entry.Position:Lerp(desired,Formation.Alpha(Formation.FollowSpeed,dt))
   entry.Position=Vector3.new(entry.Position.X,math.max(entry.Position.Y,head.Position.Y+head.Size.Y*.5+.35),entry.Position.Z)
   entry.Rotation=snap and rootRotation or (entry.Rotation or rootRotation):Lerp(rootRotation,Formation.Alpha(Formation.TurnSpeed,dt))
   model:PivotTo(Geometry.GroundCFrame(bounds,entry.Position,entry.Rotation*entry.ModelRotation,.05))
			if not model.Parent then model.Parent = folder end
		end
	end
	if studioProfile then
		debug.profileend()
		local cost = os.clock() - profileStart
		profileFrames += 1; profileTotal += cost; profilePeak = math.max(profilePeak, cost); profileElapsed += dt
		if profileElapsed >= 5 then
			folder:SetAttribute("RenderAvgMs", profileTotal / profileFrames * 1000)
			folder:SetAttribute("RenderPeakMs", profilePeak * 1000)
			folder:SetAttribute("RenderFrames", profileFrames)
			folder:SetAttribute("RaycastsPerSecond", profileRays / profileElapsed)
			folder:SetAttribute("ClonesPerWindow", profileClones)
			folder:SetAttribute("VisiblePets", #folder:GetChildren())
			profileElapsed, profileTotal, profilePeak, profileFrames, profileRays, profileClones = 0, 0, 0, 0, 0, 0
		end
	end
end)
script.Destroying:Connect(function()
	alive = false
	for _, connection in ipairs(connections) do connection:Disconnect() end
	for player in pairs(records) do remove(player) end
	folder:Destroy()
end)
