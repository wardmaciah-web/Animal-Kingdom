-- Development diagnostics only. No assets, profiles, rewards, or templates are mutated.
local Run = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")
local Definitions = require(script.Parent.Definitions.PetDefinitions)
local Rarities = require(script.Parent.Definitions.RarityDefinitions)
local Biomes = require(script.Parent.Definitions.BiomeDefinitions)
local Resolver = require(script.Parent.PetModelResolver)
local Geometry = require(script.Parent.PetVisualGeometry)
local Validator = {}

function Validator.Run()
	assert(Run:IsStudio(), "Pet asset diagnostics are Studio-only")
	local report = { Errors = {}, Warnings = {}, Deferred = {}, Definitions = #Definitions.Ordered, Available = 0 }
	local seen, referenced = {}, {}
	local function issue(kind, id, message)
		table.insert(report[kind], { PetTypeId = id, Message = message })
	end
	for _, def in ipairs(Definitions.Ordered) do
		local id = def.PetTypeId or def.PetId
		if type(id) ~= "string" or id == "" then issue("Errors", tostring(id), "Missing PetTypeId")
		elseif seen[id] then issue("Errors", id, "Duplicate PetTypeId") end
		seen[id or false] = true
		if not Rarities[def.Rarity] then issue("Errors", id, "Invalid rarity") end
		if not Biomes[def.Biome] then issue("Errors", id, "Unknown biome") end
		local income = def.BaseIncomePerSecond or def.CoinsPerSecond or def.BaseIncome
		if type(income) ~= "number" or income ~= income or income < 0 or income >= math.huge then issue("Errors", id, "Invalid income") end
		local ok, template, reason = pcall(Resolver.Resolve, id)
		if not ok then issue("Errors", id, "Model definition could not be resolved")
		elseif not template then
			local kind=not Biomes.IsContentReady(def.Biome) and Biomes[def.Biome] and "Deferred" or def.LegacyOnly and "Warnings" or "Errors"
			issue(kind, id, reason or "Definition without model")
		else
			referenced[template] = true
			report.Available += 1
			local bounds = Geometry.Measure(template)
			if not bounds or math.max(bounds.Size.X, bounds.Size.Y, bounds.Size.Z) > 1000 then issue("Errors", id, "Bad display bounds") end
			local parts = template:GetDescendants()
			if template:IsA("BasePart") then table.insert(parts, template) end
			for _, part in ipairs(parts) do
				if part:IsA("MeshPart") and Geometry.IsVisiblePart(part) then
					local surface = part:FindFirstChildWhichIsA("SurfaceAppearance")
					if part.TextureID == "" and not surface then issue("Warnings", id, "Visible mesh has no texture or SurfaceAppearance: " .. part.Name) end
				end
			end
		end
	end
	local assets = RS:FindFirstChild("Assets")
	for _, name in ipairs({ "PetAssets", "MeadowPetTemplates", "LegacyPets" }) do
		local folder = name == "LegacyPets" and assets and assets:FindFirstChild("Pets") or RS:FindFirstChild(name)
		if folder then
			for _, model in ipairs(folder:GetChildren()) do
				if (model:IsA("Model") or model:IsA("BasePart")) and not referenced[model] then
					issue("Warnings", model.Name, "Model without a resolvable PetDefinition: " .. model:GetFullName())
				end
			end
		end
	end
	return report
end

return Validator
