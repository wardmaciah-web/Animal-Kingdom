assert(not game:GetService("RunService"):IsRunning())
local WorldService={}
function WorldService:EnsurePerimeterBoundary()
	local ground = workspace:FindFirstChild("AnimalKingdomConcreteGround")
	if not ground or not ground:IsA("BasePart") then return end
	local height, thickness = 6, 3
	if ground.Size.X <= thickness * 2 or ground.Size.Z <= thickness * 2 then return end
	local boundary = workspace:FindFirstChild("AK_AuditPerimeter")
	if boundary and (not boundary:IsA("Folder") or boundary:GetAttribute("ManagedBy") ~= "WorldService") then
		warn("[WorldService] Existing unmanaged AK_AuditPerimeter preserved")
		return
	end
	if not boundary then
		boundary = Instance.new("Folder")
		boundary.Name = "AK_AuditPerimeter"
		boundary:SetAttribute("ManagedBy", "WorldService")
		boundary.Parent = workspace
	end
	-- Four visible walls occupy the outermost three studs of the support slab.
	-- They are outside the authored biomes/routes; corners meet without gaps.
	local y = ground.Size.Y / 2 + height / 2
	local x, z = (ground.Size.X - thickness) / 2, (ground.Size.Z - thickness) / 2
	local sides = {
		{"North", Vector3.new(ground.Size.X, height, thickness), CFrame.new(0, y, -z)},
		{"South", Vector3.new(ground.Size.X, height, thickness), CFrame.new(0, y, z)},
		{"West", Vector3.new(thickness, height, ground.Size.Z - thickness * 2), CFrame.new(-x, y, 0)},
		{"East", Vector3.new(thickness, height, ground.Size.Z - thickness * 2), CFrame.new(x, y, 0)},
	}
	for _, spec in ipairs(sides) do
		local wall = boundary:FindFirstChild(spec[1])
		if wall and (not wall:IsA("Part") or wall:GetAttribute("AKBoundaryWall") ~= true) then
			warn("[WorldService] Existing unmanaged perimeter object preserved: " .. spec[1])
			continue
		end
		if not wall then wall = Instance.new("Part"); wall.Name = spec[1] end
		wall.Size = spec[2]
		wall.CFrame = ground.CFrame * spec[3]
		wall.Anchored = true
		wall.CanCollide = true
		wall.CanTouch = false
		wall.CanQuery = true
		wall.Transparency = 0
		wall.Material = Enum.Material.Slate
		wall.Color = Color3.fromRGB(143, 148, 150)
		wall.TopSurface = Enum.SurfaceType.Smooth
		wall.BottomSurface = Enum.SurfaceType.Smooth
		wall:SetAttribute("AKBoundaryWall", true)
		wall.Parent = boundary
	end
end

WorldService:EnsurePerimeterBoundary()
local blockout=workspace.World:FindFirstChild('BiomeBlockout')
if blockout then blockout:SetAttribute('EditorReferenceOnly',true);for _,o in ipairs(blockout:GetDescendants()) do if o:IsA('BasePart') then o.Transparency=1;o.CanCollide=false;o.CanTouch=false;o.CanQuery=false;if o:IsA('SpawnLocation') then o.Enabled=false end elseif o:IsA('BillboardGui') or o:IsA('SurfaceGui') or o:IsA('ProximityPrompt') then o.Enabled=false end end end
print('[MapAudit] Common playable floor Y = '..tostring(workspace:GetAttribute('AK_CommonPlayableFloorY')))
for _,id in ipairs({'Meadow','Forest','Jungle','Desert','Snow','Volcano','Ocean','AncientRuins','MagicalForest','Sky','Prehistoric','Mythical'}) do local p=assert(workspace[id]:FindFirstChild(id..'Floor'));assert(math.abs(p.Position.Y+p.Size.Y/2-9.128930568695068)<.001,id);assert(p.CanCollide and p.Anchored,id);print('[FinalMapAudit] PASS '..id..' Y='..tostring(p.Position.Y+p.Size.Y/2)) end
print('[FinalMapAudit] Perimeter '..tostring(#workspace.AK_AuditPerimeter:GetChildren()))
