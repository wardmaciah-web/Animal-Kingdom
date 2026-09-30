-- Shared runtime map lookup for plot assignment and the admin plot camera.
local PlotLocator = {}
local CONTAINERS = { "PlayerPlots", "AnimalKingdomPlayerPlots", "Plots", "AnimalKingdomFuturePlayerPlots" }
local cachedContainer

-- The admin status board reads plots every second. Rediscover only when map
-- containers change instead of walking the entire decorated world each tick.
local function invalidateContainer(instance)
	if table.find(CONTAINERS, instance.Name)
		or (instance.Parent and table.find(CONTAINERS, instance.Parent.Name)) then
		cachedContainer = nil
	end
end
workspace.DescendantAdded:Connect(invalidateContainer)
workspace.DescendantRemoving:Connect(invalidateContainer)

local function validPlot(instance)
	if not (instance:IsA("Model") or instance:IsA("BasePart")) then return false end
	if instance:IsA("SpawnLocation") then return false end
	if instance:IsA("Model") and not instance:FindFirstChildWhichIsA("BasePart", true) then return false end
	if instance:GetAttribute("Feature") == "PlayerPlot" then return true end
	-- The live folder contains sibling Plot1Floor, Plot1Fence, Plot1Spawn,
	-- and Plot1PetDisplay objects. Only the actual plot is an ownership slot.
	return instance.Name:match("^Plot[%s_%-]*%d+$") ~= nil
		or instance.Name:match("^Plot[%s_%-]*%d+Floor$") ~= nil
		or instance.Name:match("^PlayerPlot[%s_%-]*%d+$") ~= nil
		or instance.Name:match("^PlayerPlot[%s_%-]*%d+Floor$") ~= nil
end

function PlotLocator.getContainer()
	if cachedContainer and cachedContainer:IsDescendantOf(workspace) and table.find(CONTAINERS, cachedContainer.Name) then
		for _, child in ipairs(cachedContainer:GetChildren()) do
			if validPlot(child) then return cachedContainer end
		end
	end
	cachedContainer = nil
	local found = {}
	for _, candidate in ipairs(workspace:GetDescendants()) do
		if (candidate:IsA("Folder") or candidate:IsA("Model")) and table.find(CONTAINERS, candidate.Name) then
			for _, child in ipairs(candidate:GetChildren()) do
				if validPlot(child) then
					found[candidate.Name] = found[candidate.Name] or candidate
					break
				end
			end
		end
	end
	for _, name in ipairs(CONTAINERS) do
		if found[name] then cachedContainer = found[name]; return cachedContainer end
	end
end

function PlotLocator.getPlots()
	local container = PlotLocator.getContainer()
	local plots = {}
	if container then
		for _, child in ipairs(container:GetChildren()) do
			if validPlot(child) then table.insert(plots, child) end
		end
	end
	table.sort(plots, function(a, b)
		local ai = tonumber(a.Name:match("%d+")) or math.huge
		local bi = tonumber(b.Name:match("%d+")) or math.huge
		return ai == bi and a.Name < b.Name or ai < bi
	end)
	return plots
end

function PlotLocator.getBounds(instance)
	if instance:IsA("BasePart") then return instance.CFrame, instance.Size end
	if instance:IsA("Model") and instance:FindFirstChildWhichIsA("BasePart", true) then
		return instance:GetBoundingBox()
	end
end

function PlotLocator.getCollectionBounds()
	local low, high
	for _, plot in ipairs(PlotLocator.getPlots()) do
		local cf, size = PlotLocator.getBounds(plot)
		if cf then
			local half = size * 0.5
			for _, x in ipairs({ -half.X, half.X }) do
				for _, y in ipairs({ -half.Y, half.Y }) do
					for _, z in ipairs({ -half.Z, half.Z }) do
						local point = cf:PointToWorldSpace(Vector3.new(x, y, z))
						low = low and Vector3.new(math.min(low.X, point.X), math.min(low.Y, point.Y), math.min(low.Z, point.Z)) or point
						high = high and Vector3.new(math.max(high.X, point.X), math.max(high.Y, point.Y), math.max(high.Z, point.Z)) or point
					end
				end
			end
		end
	end
	if low then return CFrame.new((low + high) * 0.5), high - low end
end

function PlotLocator.getTown()
	return workspace:FindFirstChild("AnimalKingdomTown")
end

return PlotLocator
