local Landing = {}
local Workspace = game:GetService("Workspace")

function Landing.FindFloor(id)
	local region = Workspace:FindFirstChild(id)
	local world = Workspace:FindFirstChild("World")
	if not region and world then
		local regions = world:FindFirstChild("BiomeBlockout") or world:FindFirstChild("Biomes")
		region = regions and regions:FindFirstChild(id)
	end
	if not region then return nil end
	for _, name in ipairs({id.."Floor", "Platform", "Ground"}) do
		local floor = region:FindFirstChild(name, true)
		if floor and floor:IsA("BasePart") and floor.CanCollide then return floor, region end
	end
end

-- Require the actual region floor, not a tree canopy, roof, water surface, or decoration.
function Landing.Check(position, floor, character, clearance)
	local excluded = {Workspace:FindFirstChild("BiomeTeleportPoints")}
	if character then table.insert(excluded, character) end
	local ray = RaycastParams.new()
	ray.FilterType = Enum.RaycastFilterType.Exclude
	ray.FilterDescendantsInstances = excluded
	ray.IgnoreWater = false
	local top = floor.Position.Y + floor.Size.Y / 2
	local hit = Workspace:Raycast(Vector3.new(position.X, top + 150, position.Z), Vector3.new(0,-160,0), ray)
	if not hit or hit.Instance ~= floor or hit.Material == Enum.Material.Water or hit.Normal.Y < .95 then return nil end
	local size = clearance or Vector3.new(6,8,6)
	local overlap = OverlapParams.new()
	overlap.FilterType = Enum.RaycastFilterType.Exclude
	table.insert(excluded, floor)
	overlap.FilterDescendantsInstances = excluded
	local center = hit.Position + Vector3.new(0,size.Y/2 + .3,0)
	for _, part in ipairs(Workspace:GetPartBoundsInBox(CFrame.new(center), size, overlap)) do
		if part.CanCollide or (part:IsA("MeshPart") and part.Transparency < .95) then return nil end
	end
	-- Check support under the corners, so the avatar cannot land over an edge.
	for _, offset in ipairs({Vector3.new(-size.X/2,0,-size.Z/2),Vector3.new(size.X/2,0,-size.Z/2),Vector3.new(-size.X/2,0,size.Z/2),Vector3.new(size.X/2,0,size.Z/2)}) do
		local corner = Workspace:Raycast(hit.Position + offset + Vector3.new(0,2,0),Vector3.new(0,-4,0),ray)
		if not corner or corner.Instance ~= floor then return nil end
	end
	return hit.Position
end

function Landing.FindSafePoint(floor, mapCenter)
	local center = floor.Position
	local inward = Vector3.new(mapCenter.X-center.X,0,mapCenter.Z-center.Z)
	local front = center + (inward.Magnitude > .01 and inward.Unit or Vector3.new(0,0,-1)) * math.min(floor.Size.X,floor.Size.Z)*.25
	local candidates = {}
	for x=-4,4 do for z=-4,4 do
		local point = floor.CFrame:PointToWorldSpace(Vector3.new(x*floor.Size.X/10, floor.Size.Y/2, z*floor.Size.Z/10))
		table.insert(candidates,point)
	end end
	table.sort(candidates,function(a,b) return (a-front).Magnitude < (b-front).Magnitude end)
	for _, candidate in ipairs(candidates) do
		local point = Landing.Check(candidate,floor)
		if point then return point end
	end
end

function Landing.EnsureMarkers(destinations)
	local folder = Workspace:FindFirstChild("BiomeTeleportPoints")
	if not folder then folder=Instance.new("Folder"); folder.Name="BiomeTeleportPoints"; folder.Parent=Workspace end
	assert(folder:IsA("Folder"), "BiomeTeleportPoints must be a Folder")
	local floors, center, count = {}, Vector3.zero, 0
	for name,id in pairs(destinations) do
		local floor,region = Landing.FindFloor(id)
		if floor then floors[name]={floor,region}; center+=floor.Position; count+=1 end
	end
	if count==0 then return folder end
	center/=count
	for name, entry in pairs(floors) do
		if not folder:FindFirstChild(name) then
			local point
			for _, markerName in ipairs({"TeleportPoint","TeleportSpawn","SpawnPoint",entry[2].Name.."Spawn"}) do
				local existing=entry[2]:FindFirstChild(markerName,true)
				if existing and existing:IsA("BasePart") then point=Landing.Check(existing.Position,entry[1]); if point then break end end
			end
			point=point or Landing.FindSafePoint(entry[1],center)
			if point then
				local marker=Instance.new("Part")
				marker.Name=name; marker.Size=Vector3.new(1,.2,1); marker.Position=point
				marker.Anchored=true; marker.CanCollide=false; marker.CanTouch=false; marker.CanQuery=false; marker.Transparency=1
				marker:SetAttribute("BiomeId",destinations[name]); marker.Parent=folder
			else warn("[BiomeTeleport] No safe landing found for "..name) end
		end
	end
	return folder
end

function Landing.Move(character, marker, floor)
	local root=character and character:FindFirstChild("HumanoidRootPart")
	local humanoid=character and character:FindFirstChildOfClass("Humanoid")
	if not root or not root:IsA("BasePart") or not humanoid or humanoid.Health<=0 or root.Anchored then return false end
	if humanoid.SeatPart then return false end -- Never move a vehicle/seat with its occupant.
	local _,bounds=character:GetBoundingBox()
	local clearance=Vector3.new(math.max(6,bounds.X),math.max(8,bounds.Y+2),math.max(6,bounds.Z))
	local ground=Landing.Check(marker.Position,floor,character,clearance)
	if not ground then return false end
	local facing=Vector3.new(root.CFrame.LookVector.X,0,root.CFrame.LookVector.Z)
	if facing.Magnitude<.01 then facing=Vector3.new(0,0,-1) end
	local destination=ground+Vector3.new(0,math.max(4,humanoid.HipHeight+root.Size.Y/2+1),0)
	local pivotOffset=root.CFrame:ToObjectSpace(character:GetPivot())
	character:PivotTo(CFrame.lookAt(destination,destination+facing)*pivotOffset)
	root.AssemblyLinearVelocity=Vector3.zero; root.AssemblyAngularVelocity=Vector3.zero
	return true
end
return Landing
