-- Runtime-only colored overlays for six approved Animal Kingdom town assets.
-- Canonical buildings are read only and are used exclusively for GetBoundingBox().

local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local RUNTIME_FOLDER_NAME = "AK_RuntimeTownVisuals"
local EXPANSION = 1.002
local MAX_RATIO_SPREAD = 0.03
local CENTER_TOLERANCE = 0.01
local SIZE_TOLERANCE = 0.05
local ORIENTATION_DOT_TOLERANCE = 0.999999

type Style = { color: Color3, material: Enum.Material }
type AssetSpec = {
	name: string,
	sourceName: string,
	targetPath: { string },
	expectedParts: number,
	palette: { [string]: Style },
}

local function style(red: number, green: number, blue: number, material: Enum.Material): Style
	return {
		color = Color3.fromRGB(red, green, blue),
		material = material,
	}
end

local SPECS: { AssetSpec } = {
	{
		name = "GeneralStore",
		sourceName = "GeneralStore_MaterialSplit",
		targetPath = { "AnimalKingdomTown", "DecorativeBuildings", "GeneralStoreBuilding" },
		expectedParts = 5,
		palette = {
			Walls = style(238, 218, 179, Enum.Material.SmoothPlastic),
			Timber = style(117, 78, 52, Enum.Material.WoodPlanks),
			Roof = style(144, 82, 61, Enum.Material.Slate),
			Stone = style(145, 139, 126, Enum.Material.Cobblestone),
			Sage = style(105, 145, 96, Enum.Material.SmoothPlastic),
		},
	},
	{
		name = "Blacksmith",
		sourceName = "Blacksmith_MaterialSplit",
		targetPath = { "AnimalKingdomTown", "DecorativeBuildings", "BlacksmithBuilding" },
		expectedParts = 5,
		palette = {
			Walls = style(213, 187, 147, Enum.Material.SmoothPlastic),
			Timber = style(79, 55, 42, Enum.Material.WoodPlanks),
			Roof = style(68, 67, 64, Enum.Material.Slate),
			Stone = style(145, 139, 126, Enum.Material.Cobblestone),
			ForgeAccent = style(177, 91, 64, Enum.Material.SmoothPlastic),
		},
	},
	{
		name = "CentralWell",
		sourceName = "Well_MaterialSplit",
		targetPath = { "AnimalKingdomTown", "Decor", "CentralWell" },
		expectedParts = 3,
		palette = {
			Stone = style(161, 154, 139, Enum.Material.Cobblestone),
			Wood = style(117, 78, 52, Enum.Material.WoodPlanks),
			Roof = style(83, 82, 78, Enum.Material.Slate),
		},
	},
	{
		name = "MarketStand1",
		sourceName = "MarketStand1_MaterialSplit",
		targetPath = { "AnimalKingdomTown", "DisplayProps", "MarketStand1" },
		expectedParts = 3,
		palette = {
			Wood = style(117, 78, 52, Enum.Material.WoodPlanks),
			Cream = style(238, 218, 179, Enum.Material.SmoothPlastic),
			Canopy = style(105, 145, 96, Enum.Material.SmoothPlastic),
		},
	},
	{
		name = "MarketStand2",
		sourceName = "MarketStand2_MaterialSplit",
		targetPath = { "AnimalKingdomTown", "DisplayProps", "MarketStand2" },
		expectedParts = 3,
		palette = {
			Wood = style(117, 78, 52, Enum.Material.WoodPlanks),
			Cream = style(238, 218, 179, Enum.Material.SmoothPlastic),
			Canopy = style(170, 73, 70, Enum.Material.SmoothPlastic),
		},
	},
	{
		name = "MarketCart",
		sourceName = "Cart_MaterialSplit",
		targetPath = { "AnimalKingdomTown", "DisplayProps", "MarketCart" },
		expectedParts = 4,
		palette = {
			MainWood = style(177, 123, 77, Enum.Material.WoodPlanks),
			DarkWood = style(117, 78, 52, Enum.Material.WoodPlanks),
			WheelFrame = style(79, 55, 42, Enum.Material.WoodPlanks),
			Accent = style(177, 91, 64, Enum.Material.SmoothPlastic),
		},
	},
}

local ROLE_ORDER = {
	"ForgeAccent",
	"WheelFrame",
	"MainWood",
	"DarkWood",
	"Canopy",
	"Accent",
	"Walls",
	"Timber",
	"Roof",
	"Stone",
	"Cream",
	"Sage",
	"Wood",
}

local function semanticRole(partName: string, palette: { [string]: Style }): string?
	local normalized = string.lower(partName):gsub("[^%w]", "")
	for _, role in ROLE_ORDER do
		if palette[role] and string.find(normalized, string.lower(role), 1, true) then
			return role
		end
	end
	return nil
end

local function resolvePath(root: Instance, path: { string }): Instance?
	local current = root
	for _, name in path do
		local nextInstance = current:FindFirstChild(name)
		if not nextInstance then return nil end
		current = nextInstance
	end
	return current
end

local function sourceMeshParts(source: Instance): { MeshPart }
	local result = {}
	for _, descendant in source:GetDescendants() do
		if descendant:IsA("MeshPart") then
			table.insert(result, descendant)
		elseif descendant:IsA("BasePart") then
			error(string.format("AK_TownVisualRuntime source contains non-MeshPart geometry: %s", descendant:GetFullName()))
		end
	end
	return result
end

local function alignBoundingBox(model: Model, targetCFrame: CFrame, targetSize: Vector3)
	local sourceCFrame, sourceSize = model:GetBoundingBox()
	assert(sourceSize.X > 0 and sourceSize.Y > 0 and sourceSize.Z > 0, model.Name .. " has an empty source bounding box")

	local ratios = {
		targetSize.X / sourceSize.X,
		targetSize.Y / sourceSize.Y,
		targetSize.Z / sourceSize.Z,
	}
	table.sort(ratios)
	local medianRatio = ratios[2]
	local ratioSpread = (ratios[3] - ratios[1]) / math.max(medianRatio, 1e-9)
	assert(ratioSpread <= MAX_RATIO_SPREAD, string.format("%s is not proportional to canonical bounds (spread=%.6f)", model.Name, ratioSpread))

	model:ScaleTo(model:GetScale() * medianRatio)
	local scaledCFrame = model:GetBoundingBox()
	model:PivotTo(targetCFrame * scaledCFrame:Inverse() * model:GetPivot())
	local matchedCFrame, matchedSize = model:GetBoundingBox()
	local matchedOrientation = matchedCFrame.RightVector:Dot(targetCFrame.RightVector) >= ORIENTATION_DOT_TOLERANCE
		and matchedCFrame.UpVector:Dot(targetCFrame.UpVector) >= ORIENTATION_DOT_TOLERANCE
		and matchedCFrame.LookVector:Dot(targetCFrame.LookVector) >= ORIENTATION_DOT_TOLERANCE
	assert((matchedCFrame.Position - targetCFrame.Position).Magnitude <= CENTER_TOLERANCE, model.Name .. " failed canonical center alignment")
	assert((matchedSize - targetSize).Magnitude <= SIZE_TOLERANCE, model.Name .. " failed canonical size alignment")
	assert(matchedOrientation, model.Name .. " failed canonical orientation alignment")

	-- The overlay is deliberately 0.2%% larger than the matched canonical visual.
	model:ScaleTo(model:GetScale() * EXPANSION)
	local expandedCFrame = model:GetBoundingBox()
	model:PivotTo(targetCFrame * expandedCFrame:Inverse() * model:GetPivot())
	local finalCFrame, finalSize = model:GetBoundingBox()
	assert((finalCFrame.Position - targetCFrame.Position).Magnitude <= CENTER_TOLERANCE, model.Name .. " expansion recenter failed")
	assert((finalSize - targetSize * EXPANSION).Magnitude <= SIZE_TOLERANCE, model.Name .. " expansion size validation failed")
end

local imports = ServerStorage:WaitForChild("AnimalKingdomTownNativeMaterialImports", 15)
if not imports then
	warn("[AK_TownVisualRuntime] Town material imports are absent; existing authored visuals preserved")
	return
end
local stagingFolder = Instance.new("Folder")
stagingFolder.Name = RUNTIME_FOLDER_NAME

local totalMeshParts = 0
local preparedModels = {}

-- Build and validate every overlay before replacing the previous runtime folder.
for _, spec in SPECS do
	local canonical = resolvePath(Workspace, spec.targetPath)
	if not canonical or not canonical:IsA("Model") or not canonical:FindFirstChildWhichIsA("BasePart", true) then
		warn("[AK_TownVisualRuntime] Skipping absent or empty canonical model: " .. spec.name)
		continue
	end
	local source = imports:FindFirstChild(spec.sourceName)
	assert(source and source:IsA("Model"), "AK_TownVisualRuntime missing native source Model " .. spec.sourceName)

	local canonicalCFrame, canonicalSize = canonical:GetBoundingBox()

	local sourceParts = sourceMeshParts(source)
	assert(#sourceParts == spec.expectedParts, string.format("%s expected %d source MeshParts, found %d", spec.name, spec.expectedParts, #sourceParts))

	local visual = Instance.new("Model")
	visual.Name = spec.name
	local seenRoles = {}
	for _, sourcePart in sourceParts do
		assert(sourcePart.MeshId ~= "", spec.name .. " has an empty source MeshId: " .. sourcePart.Name)
		local role = semanticRole(sourcePart.Name, spec.palette)
		assert(role, spec.name .. " has an unknown semantic MeshPart: " .. sourcePart.Name)
		assert(not seenRoles[role], spec.name .. " has duplicate semantic role: " .. role)
		seenRoles[role] = true

		local roleStyle = spec.palette[role]
		local part = sourcePart:Clone()
		part.Color = roleStyle.color
		part.Material = roleStyle.material
		part.Anchored = true
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.Parent = visual
	end

	local roleCount = 0
	for _ in seenRoles do
		roleCount += 1
	end
	assert(roleCount == spec.expectedParts, string.format("%s expected %d distinct semantic roles, found %d", spec.name, spec.expectedParts, roleCount))

	alignBoundingBox(visual, canonicalCFrame, canonicalSize)
	visual:SetAttribute("AK_RuntimeTownVisual", true)
	visual.Parent = stagingFolder
	totalMeshParts += #sourceParts
	table.insert(preparedModels, { name = spec.name, parts = #sourceParts })
end

if #preparedModels == 0 then
	stagingFolder:Destroy()
	return
end

local previousRuntime = Workspace:FindFirstChild(RUNTIME_FOLDER_NAME)
if previousRuntime then
	previousRuntime:Destroy()
end
stagingFolder.Parent = Workspace

for _, result in preparedModels do
	print(string.format("AK VISUAL CREATED | %s | Parts=%d", result.name, result.parts))
end
print("ANIMAL KINGDOM TOWN VISUALS READY")
print(string.format("[AK_TownVisualRuntime] Prepared %d valid overlays / %d MeshParts", #preparedModels, totalMeshParts))
