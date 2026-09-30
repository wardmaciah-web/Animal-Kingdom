local Workspace = game:GetService("Workspace")
local server = script.Parent.Parent
local Landing = require(server.BiomeTeleport.Landing)
local BiomeDestinations = require(server.BiomeTeleport.Destinations)
local PlotLocator = require(server.PlotLocator)
local PlotStatus = require(script.Parent.PlotStatus)
local Teleports = {}

local function body(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not root:IsA("BasePart") or not humanoid or humanoid.Health <= 0 or root.Anchored or humanoid.SeatPart then return nil end
	return character, root, humanoid
end

function Teleports.Near(player, anchor, excludeCharacter)
	local character, root, humanoid = body(player)
	if not character then return false, "CHARACTER NOT READY — stand up and try again" end
	local _, bounds = character:GetBoundingBox()
	local size = Vector3.new(math.max(6, bounds.X), math.max(8, bounds.Y + 2), math.max(6, bounds.Z))
	local excluded = {character}
	if excludeCharacter then table.insert(excluded, excludeCharacter) end
	local ray = RaycastParams.new()
	ray.FilterType = Enum.RaycastFilterType.Exclude
	ray.FilterDescendantsInstances = excluded
	ray.RespectCanCollide = true
	local overlap = OverlapParams.new()
	overlap.FilterType = Enum.RaycastFilterType.Exclude
	overlap.FilterDescendantsInstances = {character}
	local offsets = {Vector3.new(4,0,0), Vector3.new(-4,0,0), Vector3.new(0,0,6), Vector3.new(0,0,-6), Vector3.new(8,0,0), Vector3.new(-8,0,0), Vector3.new(0,0,10), Vector3.new(0,0,-10), Vector3.zero}
	for _, offset in ipairs(offsets) do
		local point = anchor:PointToWorldSpace(offset)
		local hit = Workspace:Raycast(point + Vector3.new(0,12,0), Vector3.new(0,-48,0), ray)
		if not hit or hit.Normal.Y < 0.95 or hit.Material == Enum.Material.Water then continue end
		local center = hit.Position + Vector3.new(0,size.Y / 2 + 0.3,0)
		local blocked = false
		for _, part in ipairs(Workspace:GetPartBoundsInBox(CFrame.new(center), size, overlap)) do
			local model = part:FindFirstAncestorOfClass("Model")
			if part.CanCollide or (model and model:FindFirstChildOfClass("Humanoid")) then blocked = true; break end
		end
		if blocked then continue end
		for _, corner in ipairs({Vector3.new(-size.X/2,0,-size.Z/2),Vector3.new(size.X/2,0,-size.Z/2),Vector3.new(-size.X/2,0,size.Z/2),Vector3.new(size.X/2,0,size.Z/2)}) do
			local support = Workspace:Raycast(hit.Position + corner + Vector3.new(0,2,0),Vector3.new(0,-4,0),ray)
			if not support or support.Normal.Y < 0.95 or support.Material == Enum.Material.Water then blocked = true; break end
		end
		if blocked then continue end
		local position = hit.Position + Vector3.new(0, math.max(4, humanoid.HipHeight + root.Size.Y / 2 + 1), 0)
		local look = Vector3.new(anchor.LookVector.X,0,anchor.LookVector.Z)
		if look.Magnitude < 0.01 then look = Vector3.new(0,0,-1) end
		local pivotOffset = root.CFrame:ToObjectSpace(character:GetPivot())
		character:PivotTo(CFrame.lookAt(position,position+look)*pivotOffset)
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
		return true
	end
	return false, "NO SAFE LANDING — clear the destination and try again"
end

function Teleports.ToPlayer(player, target)
	local character, root = body(target)
	if not character then return false, "TARGET CHARACTER NOT READY" end
	return Teleports.Near(player, root.CFrame, character)
end

function Teleports.ToPlot(player, owner)
	local plot = PlotStatus.GetPlayerPlot(owner)
	if not plot then return false, "NO PLOT ASSIGNED" end
	local marker = PlotStatus.GetSpawn(plot)
	if not marker then return false, "PLOT SPAWN UNAVAILABLE" end
	return Teleports.Near(player, marker.CFrame)
end

function Teleports.ToDestination(player, id, adminService)
	if id == "AdminRoom" then
		if not body(player) then return false, "CHARACTER NOT READY" end
		return adminService:EnterAdminRoom(player), "ADMIN ROOM UNAVAILABLE"
	elseif id == "PlayerPlots" then
		local plot = PlotStatus.GetPlayerPlot(player) or PlotLocator.getPlots()[1]
		local marker = plot and PlotStatus.GetSpawn(plot)
		if not marker then return false, "PLAYER PLOTS UNAVAILABLE" end
		return Teleports.Near(player, marker.CFrame)
	elseif id == "Town" then
		local town = PlotLocator.getTown()
		-- Live Studio keeps TownPlaza directly under Workspace. Older places
		-- keep it inside AnimalKingdomTown; support both inspected layouts.
		local plaza = Workspace:FindFirstChild("TownPlaza") or (town and town:FindFirstChild("TownPlaza", true))
		if not plaza or not plaza:IsA("BasePart") then return false, "TOWN PLAZA UNAVAILABLE" end
		return Teleports.Near(player, plaza.CFrame)
	end
	local destinationName
	for name, biomeId in pairs(BiomeDestinations) do if id == biomeId then destinationName = name; break end end
	if not destinationName then return false, "UNKNOWN DESTINATION" end
	local floor = Landing.FindFloor(id)
	if not floor then return false, "BIOME FLOOR UNAVAILABLE" end
	local markers = Workspace:FindFirstChild("BiomeTeleportPoints")
	local marker = markers and markers:FindFirstChild(destinationName)
	if marker and marker:IsA("BasePart") and Landing.Move(player.Character, marker, floor) then return true end
	-- Reuse the camera's known target as a hint, never its aerial camera position.
	local cameras = Workspace:FindFirstChild("AK_AdminCameraPoints")
	local camera = cameras and cameras:FindFirstChild(id)
	local hint = camera and camera:GetAttribute("TargetCenter")
	local point = typeof(hint) == "Vector3" and Landing.Check(hint, floor, player.Character) or nil
	point = point or Landing.FindSafePoint(floor, floor.Position)
	if point and Landing.Move(player.Character, {Position=point}, floor) then return true end
	return false, "NO SAFE BIOME LANDING"
end

return Teleports
