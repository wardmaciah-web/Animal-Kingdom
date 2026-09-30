-- ANIMAL KINGDOM CENTRAL TOWN V1 - Roblox Studio Command Bar script
-- Generated offline. This file is self-contained and must be run manually in Studio.

local Workspace = game:GetService("Workspace")
local ServerStorage = game:GetService("ServerStorage")
local InsertService = game:GetService("InsertService")

local MARKER = "AnimalKingdomTownV1"
local ATLAS = "rbxassetid://93627508647867"
local TOWN_SIZE = 126
local PLOT_SIZE = 130
local EPSILON = 0.05

local ASSETS = {
    Wall = 88374836934642, WallCorner = 78139193205943,
    Doorway = 106107740919121, RoundWindow = 88011698979100,
    ShutterWindow = 88253499430112, Roof = 76653808502810,
    RoofCorner = 115180896810651, RoofGable = 138205829417270,
    RoofGableEnd = 78848222435820, RoofWindow = 112853025493294,
    Steps = 81098502670920, Chimney = 133059995829669,
    BannerGreen = 106236921110292, BannerRed = 122987210365530,
    Fence = 129944176788142, FenceCorner = 94253313516131,
    FenceGate = 112627448878182, FencePost = 116440707817869,
    Lantern = 117012476534105, Bench = 120040680875976,
    Hedge = 111946652384154, HedgeCurved = 120863360072043,
    StallGreen = 90033337652507, StallRed = 88281544212682,
    Cart = 77376515720600, Fountain = 107448191673575,
    FountainDetail = 77809500452976, Tree = 87701629507380,
    TreeCrooked = 85384724169493, TreeHighRound = 75245397368575,
}

local BIOMES = {
    "Meadow", "Forest", "Jungle", "Desert", "Snow", "Volcano", "Ocean",
    "AncientRuins", "MagicalForest", "Sky", "Prehistoric", "Mythical",
}

local BIOME_COLORS = {
    Meadow = Color3.fromRGB(112, 173, 71), Forest = Color3.fromRGB(55, 104, 60),
    Jungle = Color3.fromRGB(62, 133, 66), Desert = Color3.fromRGB(218, 177, 103),
    Snow = Color3.fromRGB(220, 238, 241), Volcano = Color3.fromRGB(66, 57, 54),
    Ocean = Color3.fromRGB(64, 166, 201), AncientRuins = Color3.fromRGB(151, 132, 96),
    MagicalForest = Color3.fromRGB(105, 78, 139), Sky = Color3.fromRGB(150, 204, 230),
    Prehistoric = Color3.fromRGB(100, 111, 59), Mythical = Color3.fromRGB(76, 53, 117),
}

local function fail(message)
    error("Preflight stopped before mutation: " .. message, 0)
end

local function descendantsOfClass(root, className)
    local result = {}
    for _, item in ipairs(root:GetDescendants()) do
        if item:IsA(className) then table.insert(result, item) end
    end
    return result
end

local function visibleBounds(model)
    local ok, cf, size = pcall(function() return model:GetBoundingBox() end)
    if not ok or size.X <= 0 or size.Y <= 0 or size.Z <= 0 then
        return nil, nil
    end
    return cf, size
end

local function cleanTemplate(container, key)
    for _, item in ipairs(container:GetDescendants()) do
        if item:IsA("LuaSourceContainer") or item:IsA("ProximityPrompt")
            or item:IsA("ClickDetector") or item:IsA("TouchTransmitter") then
            item:Destroy()
        elseif item:IsA("BasePart") then
            item.Anchored = true
            item.CanCollide = false
            item.CanTouch = false
            item.CanQuery = false
            if item:IsA("MeshPart") then item.TextureID = ATLAS end
            item.Color = Color3.new(1, 1, 1)
        end
    end
    local cf, size = visibleBounds(container)
    if not cf or #descendantsOfClass(container, "BasePart") == 0 then
        fail("invalid selected template " .. key)
    end
    container.Name = key
    return container, size
end

local templates, templateSizes = {}, {}
local function loadTemplates()
    for key, assetId in pairs(ASSETS) do
        if type(assetId) ~= "number" or assetId <= 0 then fail("invalid asset ID for " .. key) end
        local ok, loaded = pcall(function() return InsertService:LoadAsset(assetId) end)
        if not ok or not loaded then fail("LoadAsset failed for " .. key .. ": " .. tostring(loaded)) end
        local template, size = cleanTemplate(loaded, key)
        templates[key], templateSizes[key] = template, size
        print(string.format("AK_TOWN_SELECTED_ASSET role=%s sourceFBX=%s meshAssetId=%d verified=true usesSharedAtlas=true",
            key, key, assetId))
    end
end

local function median(values)
    local sorted = table.clone(values)
    table.sort(sorted)
    local n = #sorted
    if n == 0 then return nil end
    if n % 2 == 1 then return sorted[(n + 1) / 2] end
    return (sorted[n / 2] + sorted[n / 2 + 1]) / 2
end

local function getTopY(part)
    local highest = -math.huge
    for _, x in ipairs({-1, 1}) do
        for _, y in ipairs({-1, 1}) do
            for _, z in ipairs({-1, 1}) do
                local point = part.CFrame:PointToWorldSpace(Vector3.new(
                    x * part.Size.X / 2, y * part.Size.Y / 2, z * part.Size.Z / 2))
                highest = math.max(highest, point.Y)
            end
        end
    end
    return highest
end

local function supportPoints(environment)
    local all, trees, shakeables, baseYs = {}, {}, {}, {}
    local scenery = environment:FindFirstChild("Scenery")
    local treeFolder = scenery and scenery:FindFirstChild("Trees")
    if treeFolder then
        for _, model in ipairs(treeFolder:GetChildren()) do
            if model:IsA("Model") then
                local cf, size = visibleBounds(model)
                if cf then
                    local point = Vector3.new(cf.Position.X, cf.Position.Y - size.Y / 2, cf.Position.Z)
                    table.insert(all, point); table.insert(trees, point); table.insert(baseYs, point.Y)
                end
            end
        end
    end
    for _, item in ipairs(environment:GetDescendants()) do
        if item:IsA("BasePart") and item.Name:lower():find("futureshakeablespot", 1, true) then
            table.insert(all, item.Position); table.insert(shakeables, item.Position)
        end
    end
    if #trees == 0 then return nil end
    return {all = all, trees = trees, shakeables = shakeables, medianY = median(baseYs)}
end

local FLOOR_EXCLUDES = {
    "trees", "rocks", "decor", "plants", "transition", "presentation", "label",
    "debug", "helper", "future", "marker", "shakeable", "clearing", "crystal", "path",
    "animalkingdomconcreteground", "animalkingdomtown", "animalkingdomfutureplayerplots",
}

local function excludedGround(part)
    if part == Workspace:FindFirstChild("GrassFloor") then return true end
    local current = part
    while current and current ~= Workspace do
        local name = current.Name:lower()
        for _, word in ipairs(FLOOR_EXCLUDES) do
            if name:find(word, 1, true) then return true end
        end
        current = current.Parent
    end
    return false
end

local function insidePartXZ(part, point, tolerance)
    local localPoint = part.CFrame:PointToObjectSpace(point)
    return math.abs(localPoint.X) <= part.Size.X / 2 + tolerance
        and math.abs(localPoint.Z) <= part.Size.Z / 2 + tolerance
end

local function colorAffinity(a, b)
    local dr, dg, db = a.R - b.R, a.G - b.G, a.B - b.B
    return 1 - math.min(1, math.sqrt(dr * dr + dg * dg + db * db) / 0.7)
end

local function eligibleGround(part, supportMedianY)
    if not part:IsA("BasePart") or not part.Anchored or part.Transparency >= 1 or excludedGround(part) then return false end
    if math.abs(part.CFrame.UpVector:Dot(Vector3.yAxis)) < 0.88 then return false end
    if part.Size.X * part.Size.Z < 100 then return false end
    return math.abs(getTopY(part) - supportMedianY) <= 18
end

local function makeGroundRayParams(environment)
    local omit = {}
    local scenery = environment:FindFirstChild("Scenery")
    if scenery then
        for _, name in ipairs({"Trees", "Rocks", "Decor", "Plants", "Presentation"}) do
            local child = scenery:FindFirstChild(name)
            if child then table.insert(omit, child) end
        end
    end
    for _, name in ipairs({"AnimalKingdomConcreteGround", "AnimalKingdomEnvironmentTransitionsV4",
        "AnimalKingdomTown", "AnimalKingdomFuturePlayerPlots", "GrassFloor"}) do
        local child = Workspace:FindFirstChild(name)
        if child then table.insert(omit, child) end
    end
    for _, item in ipairs(environment:GetDescendants()) do
        if item:IsA("BasePart") and excludedGround(item) then table.insert(omit, item) end
    end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = omit
    params.IgnoreWater = false
    return params
end

local function resolveBiomeGroundRegions()
    local root = Workspace:FindFirstChild("BiomeEnvironments")
    if not root then fail("Workspace.BiomeEnvironments missing") end
    local result = {}
    for _, biome in ipairs(BIOMES) do
        local environment = root:FindFirstChild(biome .. "Environment")
        if not environment then fail("missing " .. biome .. "Environment") end
        local support = supportPoints(environment)
        if not support then fail("no visible-tree support points for " .. biome) end
        local pool, seen = {}, {}
        for _, part in ipairs(environment:GetDescendants()) do
            if part:IsA("BasePart") then table.insert(pool, part); seen[part] = true end
        end
        local biomeKey = biome:lower()
        for _, part in ipairs(Workspace:GetDescendants()) do
            if part:IsA("BasePart") and not seen[part] and not excludedGround(part) then
                local path, name = part:GetFullName():lower(), part.Name:lower()
                local namedForBiome = path:find(biomeKey, 1, true) ~= nil
                local floorNamed = name:find("floor", 1, true) or name:find("ground", 1, true)
                    or name:find("plot", 1, true) or path:find("biomefloor", 1, true)
                    or path:find("biomeplot", 1, true)
                if namedForBiome and floorNamed then table.insert(pool, part); seen[part] = true end
            end
        end
        local candidates = {}
        for _, part in ipairs(pool) do
            if eligibleGround(part, support.medianY) then
                local treeHits, shakeHits = 0, 0
                for _, point in ipairs(support.trees) do if insidePartXZ(part, point, 2) then treeHits += 1 end end
                for _, point in ipairs(support.shakeables) do if insidePartXZ(part, point, 2) then shakeHits += 1 end end
                local coverage = (treeHits + shakeHits) / math.max(1, #support.all)
                local heightFit = 1 - math.min(1, math.abs(getTopY(part) - support.medianY) / 18)
                local colorFit = colorAffinity(part.Color, BIOME_COLORS[biome])
                local score = coverage * 100 + heightFit * 8 + colorFit * 4
                    + math.min(4, part.Size.X * part.Size.Z / 2500)
                table.insert(candidates, {part = part, coverage = coverage, score = score,
                    treeHits = treeHits, shakeHits = shakeHits, raycastHits = 0})
            end
        end
        table.sort(candidates, function(a, b) return a.score > b.score end)
        local candidateByPart = {}
        for _, candidate in ipairs(candidates) do candidateByPart[candidate.part] = candidate end
        local params = makeGroundRayParams(environment)
        for _, point in ipairs(support.all) do
            local hit = Workspace:Raycast(Vector3.new(point.X, point.Y + 100, point.Z), Vector3.new(0, -200, 0), params)
            local candidate = hit and candidateByPart[hit.Instance]
            if candidate then candidate.raycastHits += 1 end
        end
        local grounds, covered, included = {}, {}, {}
        for _, candidate in ipairs(candidates) do
            local addsSupport = false
            for index, point in ipairs(support.all) do
                if not covered[index] and insidePartXZ(candidate.part, point, 2) then addsSupport = true break end
            end
            if addsSupport or candidate.raycastHits > 0 then
                table.insert(grounds, candidate.part); included[candidate.part] = true
                for index, point in ipairs(support.all) do
                    if insidePartXZ(candidate.part, point, 2) then covered[index] = true end
                end
            end
        end
        local resolvedCount, rayResolved = 0, 0
        for index, point in ipairs(support.all) do
            if covered[index] then resolvedCount += 1 end
            local hit = Workspace:Raycast(Vector3.new(point.X, point.Y + 100, point.Z), Vector3.new(0, -200, 0), params)
            if hit and included[hit.Instance] then rayResolved += 1 end
        end
        local coverage = resolvedCount / math.max(1, #support.all)
        local rayCoverage = rayResolved / math.max(1, #support.all)
        local treeOutside = 0
        for _, point in ipairs(support.trees) do
            local found = false
            for _, part in ipairs(grounds) do if insidePartXZ(part, point, 3) then found = true break end end
            if not found then treeOutside += 1 end
        end
        if #grounds == 0 or coverage < 0.9 or treeOutside > 0 or rayCoverage < 0.75 then
            print("AK_TOWN_GROUND_FAILURE")
            print("biome=" .. biome); print("supportPoints=" .. #support.all)
            print("candidateCount=" .. #candidates); print("bestCandidates=")
            for index = 1, math.min(3, #candidates) do
                local candidate = candidates[index]
                print(string.format("path=%s coverage=%.3f raycastHits=%d topY=%.3f size=%s",
                    candidate.part:GetFullName(), candidate.coverage, candidate.raycastHits,
                    getTopY(candidate.part), tostring(candidate.part.Size)))
            end
            fail("could not resolve multi-part ground region for " .. biome)
        end
        local minX, maxX, minZ, maxZ = math.huge, -math.huge, math.huge, -math.huge
        local topYs = {}
        for _, part in ipairs(grounds) do
            for _, x in ipairs({-1, 1}) do for _, z in ipairs({-1, 1}) do
                local corner = part.CFrame:PointToWorldSpace(Vector3.new(x * part.Size.X / 2, 0, z * part.Size.Z / 2))
                minX, maxX = math.min(minX, corner.X), math.max(maxX, corner.X)
                minZ, maxZ = math.min(minZ, corner.Z), math.max(maxZ, corner.Z)
            end end
            table.insert(topYs, getTopY(part))
        end
        result[biome] = {parts = grounds, support = support, coverage = coverage,
            rayCoverage = rayCoverage, medianTopY = median(topYs)}
        print("AK_TOWN_GROUND_RESOLVED")
        print("biome=" .. biome); print("groundParts=" .. #grounds)
        print("supportPoints=" .. #support.all); print("supportPointsResolved=" .. resolvedCount)
        print("coverage=" .. coverage); print("minX=" .. minX); print("maxX=" .. maxX)
        print("minZ=" .. minZ); print("maxZ=" .. maxZ); print("medianTopY=" .. result[biome].medianTopY)
    end
    return result
end

local function rectangle(center, sx, sz, yaw)
    local c, s = math.cos(yaw), math.sin(yaw)
    local ux, uz = Vector2.new(c, s), Vector2.new(-s, c)
    return {center = Vector2.new(center.X, center.Z), hx = sx / 2, hz = sz / 2, ux = ux, uz = uz}
end

local function project(rect, axis)
    local center = rect.center:Dot(axis)
    local radius = rect.hx * math.abs(rect.ux:Dot(axis)) + rect.hz * math.abs(rect.uz:Dot(axis))
    return center - radius, center + radius
end

local function overlaps(a, b, gap)
    for _, axis in ipairs({a.ux, a.uz, b.ux, b.uz}) do
        local amin, amax = project(a, axis)
        local bmin, bmax = project(b, axis)
        if amax + gap <= bmin or bmax + gap <= amin then return false end
    end
    return true
end

local function partRect(part)
    local yaw = math.atan2(part.CFrame.LookVector.X, part.CFrame.LookVector.Z)
    return rectangle(part.Position, part.Size.X, part.Size.Z, yaw)
end

local function flattenGroundRectangles(regions)
    local rectangles = {}
    for biome, region in pairs(regions) do
        for _, part in ipairs(region.parts) do
            table.insert(rectangles, {biome = biome, rect = partRect(part), part = part})
        end
    end
    return rectangles
end

local function validateRouteAccess(grass, groundRectangles, occupied)
    local cellSize = 10
    local nx = math.max(1, math.floor(grass.Size.X / cellSize))
    local nz = math.max(1, math.floor(grass.Size.Z / cellSize))
    local cells, component, componentSizes = {}, {}, {}
    local function key(x, z) return x .. ":" .. z end
    local function blocked(point)
        local p2 = Vector2.new(point.X, point.Z)
        for _, record in ipairs(groundRectangles) do
            local r, delta = record.rect, p2 - record.rect.center
            if math.abs(delta:Dot(r.ux)) < r.hx and math.abs(delta:Dot(r.uz)) < r.hz then return true end
        end
        for _, r in ipairs(occupied) do
            local delta = p2 - r.center
            if math.abs(delta:Dot(r.ux)) < r.hx and math.abs(delta:Dot(r.uz)) < r.hz then return true end
        end
        return false
    end
    for x = 1, nx do
        for z = 1, nz do
            local lx = -grass.Size.X / 2 + (x - 0.5) * grass.Size.X / nx
            local lz = -grass.Size.Z / 2 + (z - 0.5) * grass.Size.Z / nz
            local point = grass.CFrame:PointToWorldSpace(Vector3.new(lx, 0, lz))
            cells[key(x, z)] = {x = x, z = z, point = point, open = not blocked(point)}
        end
    end
    local componentId = 0
    for cellKey, seed in pairs(cells) do
        if seed.open and not component[cellKey] then
            componentId += 1
            local queue, head, count = {seed}, 1, 0
            component[cellKey] = componentId
            while head <= #queue do
                local current = queue[head]; head += 1; count += 1
                for _, offset in ipairs({{1,0},{-1,0},{0,1},{0,-1}}) do
                    local nextKey = key(current.x + offset[1], current.z + offset[2])
                    local nextCell = cells[nextKey]
                    if nextCell and nextCell.open and not component[nextKey] then
                        component[nextKey] = componentId; table.insert(queue, nextCell)
                    end
                end
            end
            componentSizes[componentId] = count
        end
    end
    local networkId, networkSize = nil, 0
    for id, size in pairs(componentSizes) do if size > networkSize then networkId, networkSize = id, size end end
    if not networkId then return false, #BIOMES end
    local accessible = {}
    for cellKey, cell in pairs(cells) do
        if component[cellKey] == networkId then
            local p2 = Vector2.new(cell.point.X, cell.point.Z)
            for _, record in ipairs(groundRectangles) do
                local r, delta = record.rect, p2 - record.rect.center
                local dx, dz = math.abs(delta:Dot(r.ux)), math.abs(delta:Dot(r.uz))
                local outside = dx >= r.hx or dz >= r.hz
                local near = dx <= r.hx + 18 and dz <= r.hz + 18
                if outside and near then accessible[record.biome] = true end
            end
        end
    end
    local blockedBiomes = {}
    for _, biome in ipairs(BIOMES) do if not accessible[biome] then table.insert(blockedBiomes, biome) end end
    if #blockedBiomes > 0 then
        print("AK_TOWN_ROUTE_FAILURE blockedBiomes=" .. table.concat(blockedBiomes, ","))
        return false, #blockedBiomes
    end
    print(string.format("AK_TOWN_ROUTE_PREFLIGHT gridCells=%d centralNetworkCells=%d blockedBiomes=0", nx * nz, networkSize))
    return true, 0
end

local function findLayout(regions)
    local grass = Workspace:FindFirstChild("GrassFloor")
    if not grass or not grass:IsA("BasePart") then fail("Workspace.GrassFloor missing") end
    local boundary = partRect(grass)
    local groundRectangles = flattenGroundRectangles(regions)
    local exclusions = {}
    for _, record in ipairs(groundRectangles) do table.insert(exclusions, record.rect) end
    local function fits(rect, used)
        local axes = {boundary.ux, boundary.uz}
        for _, axis in ipairs(axes) do
            local rmin, rmax = project(rect, axis)
            local bmin, bmax = project(boundary, axis)
            if rmin < bmin + 2 or rmax > bmax - 2 then return false end
        end
        for _, exclusion in ipairs(exclusions) do if overlaps(rect, exclusion, -EPSILON) then return false end end
        for _, occupied in ipairs(used) do if overlaps(rect, occupied, 4) then return false end end
        return true
    end
    local candidates = {}
    local step = 10
    for x = -grass.Size.X / 2 + 65, grass.Size.X / 2 - 65, step do
        for z = -grass.Size.Z / 2 + 65, grass.Size.Z / 2 - 65, step do
            local world = grass.CFrame:PointToWorldSpace(Vector3.new(x, 0, z))
            table.insert(candidates, world)
        end
    end
    local preference = grass.Position
    for _, item in ipairs(Workspace:GetDescendants()) do
        if item:IsA("SpawnLocation") then preference = item.Position break end
    end
    table.sort(candidates, function(a, b) return (a - preference).Magnitude < (b - preference).Magnitude end)
    local townCenter, used
    for _, point in ipairs(candidates) do
        local candidate = rectangle(point, TOWN_SIZE, TOWN_SIZE, 0)
        if fits(candidate, {}) then townCenter, used = point, {candidate}; break end
    end
    if not townCenter then fail("no collision-free 126x126 town footprint") end
    table.sort(candidates, function(a, b) return (a - townCenter).Magnitude < (b - townCenter).Magnitude end)
    local plots = {}
    for _, point in ipairs(candidates) do
        if #plots == 5 then break end
        local candidate = rectangle(point, PLOT_SIZE, PLOT_SIZE, 0)
        if fits(candidate, used) then table.insert(plots, point); table.insert(used, candidate) end
    end
    if #plots ~= 5 then fail("could not reserve five non-overlapping 130x130 plots") end
    local routeClear, blockedRoutes = validateRouteAccess(grass, groundRectangles, used)
    if not routeClear then fail("layout blocks " .. blockedRoutes .. " biome route(s)") end
    local tops = {}
    for _, region in pairs(regions) do for _, part in ipairs(region.parts) do table.insert(tops, getTopY(part)) end end
    local groundY = median(tops)
    print(string.format("AK_TOWN_LAYOUT town=(%.2f,%.2f) footprint=%dx%d plots=5", townCenter.X, townCenter.Z, TOWN_SIZE, TOWN_SIZE))
    return townCenter, plots, groundY, blockedRoutes
end

local mutationStarted = false
local rollback, town, plotFolder
local function rollbackAll(reason)
    if town then town:Destroy() end
    if plotFolder then plotFolder:Destroy() end
    if rollback then
        for _, child in ipairs(rollback:GetChildren()) do child.Parent = Workspace end
        rollback:Destroy()
    end
    Workspace:SetAttribute(MARKER, nil)
    error("Town build rolled back: " .. reason, 0)
end

local function folder(parent, name)
    local f = Instance.new("Folder"); f.Name = name; f.Parent = parent; return f
end

local function part(parent, name, size, cf, color, material)
    local p = Instance.new("Part")
    p.Name, p.Size, p.CFrame = name, size, cf
    p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, true, true, true
    p.Color, p.Material = color, material
    p.Parent = parent
    return p
end

local function cloneAsset(key, parent, name, desiredCenter, targetHeight, yaw)
    local model = templates[key]:Clone()
    model.Name, model.Parent = name or key, parent
    local _, initial = visibleBounds(model)
    local scale = targetHeight / initial.Y
    model:ScaleTo(scale)
    model:PivotTo(CFrame.Angles(0, yaw or 0, 0))
    local cf, size = visibleBounds(model)
    local target = Vector3.new(desiredCenter.X, desiredCenter.Y + size.Y / 2, desiredCenter.Z)
    model:PivotTo(model:GetPivot() + (target - cf.Position))
    return model
end

local function makeSign(parent, name, text, cf, width)
    local board = part(parent, name, Vector3.new(width, 4, 0.5), cf, Color3.fromRGB(255, 230, 147), Enum.Material.WoodPlanks)
    board.CanCollide = false
    local gui = Instance.new("SurfaceGui"); gui.Face = Enum.NormalId.Front; gui.AlwaysOnTop = true; gui.Parent = board
    local label = Instance.new("TextLabel"); label.Size = UDim2.fromScale(1, 1); label.BackgroundTransparency = 1
    label.Text = text; label.TextScaled = true; label.Font = Enum.Font.FredokaOne
    label.TextColor3 = Color3.fromRGB(74, 47, 37); label.Parent = gui
    return board
end

local function buildBuilding(parent, name, center, width, depth, height, accent)
    local model = Instance.new("Model"); model.Name = name; model.Parent = parent
    part(model, "Foundation", Vector3.new(width, 1, depth), CFrame.new(center + Vector3.new(0, 0.5, 0)), Color3.fromRGB(235, 209, 157), Enum.Material.Cobblestone)
    local moduleWidth = 7
    for x = -width / 2 + moduleWidth / 2, width / 2 - moduleWidth / 2, moduleWidth do
        local key = math.abs(x) < 3.6 and "Doorway" or ((math.floor(x / moduleWidth) % 2 == 0) and "RoundWindow" or "ShutterWindow")
        cloneAsset(key, model, key, center + Vector3.new(x, 1, -depth / 2), height, 0)
        cloneAsset("Wall", model, "RearWall", center + Vector3.new(x, 1, depth / 2), height, math.pi)
    end
    for z = -depth / 2 + moduleWidth / 2, depth / 2 - moduleWidth / 2, moduleWidth do
        cloneAsset("Wall", model, "SideWall", center + Vector3.new(-width / 2, 1, z), height, math.pi / 2)
        cloneAsset("Wall", model, "SideWall", center + Vector3.new(width / 2, 1, z), height, -math.pi / 2)
    end
    cloneAsset("Roof", model, "Roof", center + Vector3.new(0, height, 0), height * 0.72, 0)
    cloneAsset("RoofGable", model, "RoofGable", center + Vector3.new(0, height, 0), height * 0.76, 0)
    cloneAsset("Chimney", model, "Chimney", center + Vector3.new(width * 0.25, height + 2, 2), height * 0.55, 0)
    cloneAsset("Steps", model, "Steps", center + Vector3.new(0, 0, -depth / 2 - 2), 2.5, 0)
    cloneAsset(accent, model, "Banner", center + Vector3.new(width * 0.32, 4, -depth / 2 - 0.5), 6, 0)
    return model
end

local function marker(parent, name, center, feature, sx, sz)
    local p = part(parent, name, Vector3.new(sx or 5, 1, sz or 5), CFrame.new(center + Vector3.new(0, 0.5, 0)), Color3.new(1, 1, 1), Enum.Material.SmoothPlastic)
    p.Transparency, p.CanCollide, p.CanTouch, p.CanQuery = 1, false, false, false
    p:SetAttribute("Feature", feature); p:SetAttribute("Implemented", false)
    return p
end

local function constructTown(center, plots, y)
    mutationStarted = true
    rollback = Instance.new("Folder"); rollback.Name = "AnimalKingdomTownV1Rollback"; rollback.Parent = ServerStorage
    for _, oldName in ipairs({"AnimalKingdomTown", "AnimalKingdomFuturePlayerPlots"}) do
        local old = Workspace:FindFirstChild(oldName)
        if old then old.Parent = rollback end
    end
    town = folder(Workspace, "AnimalKingdomTown")
    local ground = folder(town, "TownGround")
    local paths = folder(town, "Paths")
    local fence = folder(town, "Fence")
    local entrance = folder(town, "Entrance")
    local decor = folder(town, "Decor")
    local benches = folder(town, "Benches")
    local lights = folder(town, "Lights")
    local planters = folder(town, "Planters")
    local display = folder(town, "DisplayProps")
    local future = folder(town, "FutureGameplayMarkers")
    local c = Vector3.new(center.X, y, center.Z)
    part(ground, "TownPlaza", Vector3.new(124, 0.6, 124), CFrame.new(c - Vector3.new(0, 0.3, 0)), Color3.fromRGB(210, 192, 160), Enum.Material.Cobblestone)
    part(paths, "MainWalkway", Vector3.new(12, 0.7, 91), CFrame.new(c + Vector3.new(0, -0.25, -17)), Color3.fromRGB(226, 211, 181), Enum.Material.Cobblestone)
    part(paths, "CrossWalkway", Vector3.new(83, 0.7, 10), CFrame.new(c + Vector3.new(0, -0.25, 7)), Color3.fromRGB(226, 211, 181), Enum.Material.Cobblestone)
    part(paths, "CentralPlaza", Vector3.new(28, 0.72, 28), CFrame.new(c + Vector3.new(0, -0.24, 0)), Color3.fromRGB(236, 220, 188), Enum.Material.Cobblestone)
    local tradingCenter = c + Vector3.new(0, 0, 37)
    local rewardsCenter = c + Vector3.new(38, 0, 28)
    buildBuilding(town, "TradingHall", tradingCenter, 36, 26, 13, "BannerGreen")
    buildBuilding(town, "RewardsBuilding", rewardsCenter, 22, 18, 11, "BannerRed")
    makeSign(town, "TradingHallSign", "TRADING HALL", CFrame.new(tradingCenter + Vector3.new(0, 13, -13.4)), 18)
    makeSign(town, "RewardsSign", "REWARDS", CFrame.new(rewardsCenter + Vector3.new(0, 11, -9.4)), 12)
    marker(future, "TradingHallInteraction", tradingCenter + Vector3.new(0, 0, -15), "PetTrading", 8, 5)
    marker(future, "RewardsInteraction", rewardsCenter + Vector3.new(0, 0, -11), "InGameRewards", 7, 5)
    local spin = c + Vector3.new(-38, 0, 28)
    part(town, "SpinWheelPlaza", Vector3.new(20, 0.72, 20), CFrame.new(spin - Vector3.new(0, 0.24, 0)), Color3.fromRGB(226, 205, 174), Enum.Material.Cobblestone)
    marker(future, "SpinWheelLocation", spin, "DailySpinWheel", 4, 4)
    cloneAsset("Fountain", decor, "CentralFountain", c + Vector3.new(0, 0.1, 0), 7, 0)
    cloneAsset("FountainDetail", decor, "FountainDetail", c + Vector3.new(0, 0.1, 0), 7.2, 0)
    -- Perimeter fence: front is negative Z and retains a 20-stud opening.
    for x = -57, 57, 8 do
        if math.abs(x) >= 12 then cloneAsset("Fence", fence, "Fence", c + Vector3.new(x, 0, -61), 4.5, 0) end
        cloneAsset("Fence", fence, "Fence", c + Vector3.new(x, 0, 61), 4.5, math.pi)
    end
    for z = -53, 53, 8 do
        cloneAsset("Fence", fence, "Fence", c + Vector3.new(-61, 0, z), 4.5, math.pi / 2)
        cloneAsset("Fence", fence, "Fence", c + Vector3.new(61, 0, z), 4.5, -math.pi / 2)
    end
    cloneAsset("FencePost", entrance, "EntrancePost", c + Vector3.new(-11, 0, -61), 6, 0)
    cloneAsset("FencePost", entrance, "EntrancePost", c + Vector3.new(11, 0, -61), 6, 0)
    makeSign(entrance, "TownWelcomeSign", "ANIMAL KINGDOM", CFrame.new(c + Vector3.new(0, 8, -61)), 20)
    local benchPositions = {{-17,-9,0},{17,-9,math.pi},{-18,13,0},{18,13,math.pi},{-44,8,math.pi/2},{44,8,-math.pi/2}}
    for i, v in ipairs(benchPositions) do cloneAsset("Bench", benches, "Bench" .. i, c + Vector3.new(v[1], 0, v[2]), 3, v[3]) end
    local lampPositions = {{-8,-48},{8,-48},{-8,-27},{8,-27},{-8,-10},{8,-10},{-29,7},{29,7},{-49,20},{49,20},{-25,48},{25,48}}
    for i, v in ipairs(lampPositions) do cloneAsset("Lantern", lights, "Lamp" .. i, c + Vector3.new(v[1], 0, v[2]), 7, 0) end
    local planterPositions = {{-52,-34,0},{52,-31,math.pi},{-51,42,0},{48,47,math.pi},{-31,-7,math.pi/2},{31,-7,-math.pi/2}}
    for i, v in ipairs(planterPositions) do cloneAsset(i % 2 == 0 and "HedgeCurved" or "Hedge", planters, "Planter" .. i, c + Vector3.new(v[1], 0, v[2]), 3.5, v[3]) end
    local treeData = {{-52,-46,"Tree",0},{50,-47,"TreeCrooked",1},{-50,51,"TreeHighRound",2},{51,52,"Tree",3},{-33,-34,"TreeCrooked",2},{35,-38,"TreeHighRound",1}}
    for i, v in ipairs(treeData) do cloneAsset(v[3], decor, "DecorTree" .. i, c + Vector3.new(v[1], 0, v[2]), 13 + (i % 3), v[4]) end
    cloneAsset("StallGreen", display, "GreenMarketStall", c + Vector3.new(-47, 0, -4), 9, math.pi / 2)
    cloneAsset("StallRed", display, "RedMarketStall", c + Vector3.new(47, 0, -4), 9, -math.pi / 2)
    cloneAsset("Cart", display, "MarketCart", c + Vector3.new(-42, 0, -18), 5, 0.35)
    plotFolder = folder(Workspace, "AnimalKingdomFuturePlayerPlots")
    for i, point in ipairs(plots) do
        local reservation = part(plotFolder, "Plot" .. i .. "Reservation", Vector3.new(PLOT_SIZE, 1, PLOT_SIZE), CFrame.new(point.X, y - 0.5, point.Z), Color3.new(1, 1, 1), Enum.Material.SmoothPlastic)
        reservation.Transparency, reservation.CanCollide, reservation.CanTouch, reservation.CanQuery = 1, false, false, false
        reservation:SetAttribute("Feature", "PlayerPlot"); reservation:SetAttribute("Implemented", false)
        reservation:SetAttribute("Reserved", true); reservation:SetAttribute("BuildableSizeX", 130)
        reservation:SetAttribute("BuildableSizeZ", 130); reservation:SetAttribute("Purpose", "FuturePlayerSanctuary")
    end
end

local function validate(regions, center)
    if #plotFolder:GetChildren() ~= 5 then return false, "future plot count" end
    local townRect = rectangle(center, TOWN_SIZE, TOWN_SIZE, 0)
    local plotRects = {}
    for _, p in ipairs(plotFolder:GetChildren()) do
        if p.Size.X ~= 130 or p.Size.Z ~= 130 then return false, "future plot size" end
        local r = partRect(p)
        for _, old in ipairs(plotRects) do if overlaps(r, old, 0) then return false, "plot/plot overlap" end end
        if overlaps(r, townRect, 0) then return false, "plot/town overlap" end
        for _, region in pairs(regions) do
            for _, floorPart in ipairs(region.parts) do
                if overlaps(r, partRect(floorPart), -EPSILON) then return false, "plot/biome overlap" end
            end
        end
        table.insert(plotRects, r)
    end
    for _, region in pairs(regions) do
        for _, floorPart in ipairs(region.parts) do
            if overlaps(townRect, partRect(floorPart), -EPSILON) then return false, "town/biome overlap" end
        end
    end
    local missingAtlas = 0
    for _, mesh in ipairs(town:GetDescendants()) do
        if mesh:IsA("MeshPart") and mesh.TextureID ~= ATLAS then missingAtlas += 1 end
        if mesh:IsA("LuaSourceContainer") then return false, "gameplay script introduced" end
    end
    if missingAtlas > 0 then return false, "town meshes missing atlas: " .. missingAtlas end
    return true
end

if Workspace:GetAttribute(MARKER) == true then warn("AnimalKingdomTownV1 already complete"); return end
if ServerStorage:FindFirstChild("AnimalKingdomTownV1Rollback") then fail("stale rollback folder exists") end

print("[1/5] Loading and validating selected town assets")
loadTemplates()
print("[2/5] Resolving biome floors and map layout")
local groundRegions = resolveBiomeGroundRegions()
local townCenter, plots, groundY, blockedRoutes = findLayout(groundRegions)
print("[3/5] Preflighting town, paths, fence, and five future plots")
print(string.format("AK_TOWN_PREFLIGHT townFootprint=%dx%d futurePlots=5 plotSize=%dx%d", TOWN_SIZE, TOWN_SIZE, PLOT_SIZE, PLOT_SIZE))
print("AK_TOWN_PREFLIGHT blockedMajorRoutes=" .. blockedRoutes .. " townOutsideMap=0 plotsOutsideMap=0")
print("[4/5] Constructing central town")
local ok, err = pcall(function() constructTown(townCenter, plots, groundY) end)
if not ok then rollbackAll(tostring(err)) end
print("[5/5] Final validation")
local valid, reason = validate(groundRegions, townCenter)
if not valid then rollbackAll(reason) end
Workspace:SetAttribute(MARKER, true)
for _, template in pairs(templates) do template:Destroy() end

print("ANIMAL KINGDOM CENTRAL TOWN V1 COMPLETE")
print("Shared Atlas Image ID: 93627508647867")
print("Selected town assets: 30")
print("Town footprint: 126 x 126")
print("Trading Hall: YES")
print("Trading Hall sign: YES")
print("Spin Wheel Plaza: YES")
print("Rewards Building: YES")
print("Rewards sign: YES")
print("Fence complete: YES")
print("Entrance opening: 20 studs")
print("Future plots reserved: 5/5")
print("Future plot size: 130x130")
print("Plot/plot overlaps: 0")
print("Plot/biome overlaps: 0")
print("Plot/town overlaps: 0")
print("Town/biome overlaps: 0")
print("Blocked major routes: 0")
print("Town meshes missing atlas: 0")
print("Preview PNGs used: 0")
print("Gameplay implemented: NONE")
print("Script Source writes: 0")
print("Failures: 0")
