-- Explicit policy for the inspected authored Town. Never infer solid geometry
-- from every descendant of Workspace, or turn foliage/material overlays solid.
local Workspace = game:GetService("Workspace")
local Policy = {}
local structuralRoles = {
	AK_RUNTIME_GeneralStoreVisual = {AK_Walls = true, AK_Stone = true, AK_Timber = true},
	TradingHall_Visual = {AK_Walls = true, AK_Stone = true, AK_Timber = true},
	Blacksmith_Visual = {AK_Walls = true, AK_Stone = true, AK_Timber = true},
	Rewards_Visual = {AK_Walls = true, AK_Stone = true, AK_Timber = true},
	CentralWell_Visual = {AK_Stone = true, AK_Wood = true},
	MarketStand1_Visual = {AK_Wood = true},
	MarketStand2_Visual = {AK_Wood = true},
	MarketCart = {Cart = true},
}
local function isFence(name)
	return name:match("^LeftFence%d+$") or name:match("^RightFence%d+$")
		or name:match("^BackFence%d+$") or name:match("^FrontFence%-?%d+_%d+$")
		or name:match("^FencePost%d+$") or name:match("^FenceCorner%d+$") or name == "fence"
end
local function inTown(part, plaza)
	local offset = plaza.CFrame:PointToObjectSpace(part.Position)
	return math.abs(offset.X) <= plaza.Size.X / 2 + 8
		and math.abs(offset.Z) <= plaza.Size.Z / 2 + 8
		and offset.Y > -2 and offset.Y < 100
end
function Policy.Targets()
	local plaza = Workspace:FindFirstChild("TownPlaza")
	if not plaza or not plaza:IsA("BasePart") then return {} end
	local result = {}
	for _, object in ipairs(Workspace:GetChildren()) do
		if not object:IsA("Model") then continue end
		local roles = structuralRoles[object.Name]
		local fence = isFence(object.Name)
		if not roles and not fence then continue end
		for _, part in ipairs(object:GetDescendants()) do
			if not part:IsA("BasePart") or not inTown(part, plaza) or part.Transparency >= 1 then continue end
			if (roles and roles[part.Name]) or (fence and (part.Name == "fence" or part.Name == "pillar-stone" or part.Name == "fence-curved")) then
				table.insert(result, part)
			end
		end
	end
	return result
end
function Policy.Apply()
	local changed = {}
	for _, part in ipairs(Policy.Targets()) do
		if not part.CanCollide or not part.CanQuery then
			-- Reversible evidence on exactly the changed part; original source
			-- geometry, transform, material and mesh collision fidelity stay intact.
			if part:GetAttribute("AKTownCollisionOriginalCollide") == nil then
				part:SetAttribute("AKTownCollisionOriginalCollide", part.CanCollide)
				part:SetAttribute("AKTownCollisionOriginalQuery", part.CanQuery)
			end
			part.CanCollide = true
			part.CanQuery = true
			part:SetAttribute("AKTownCollisionRole", "Structure")
			table.insert(changed, part:GetFullName())
		end
	end
	return changed
end
return Policy
