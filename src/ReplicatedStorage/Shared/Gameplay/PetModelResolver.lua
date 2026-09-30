-- One source of pet models. Missing imports remain unavailable; never fabricate a pet.
local RS = game:GetService("ReplicatedStorage")
local Definitions = require(script.Parent.Definitions.PetDefinitions)
local MeadowModels = require(script.Parent.PetModelValidation)
local Geometry = require(script.Parent.PetVisualGeometry)
local Resolver = {}
local roots = { PetAssets = true, MeadowPetTemplates = true, Assets = true }

local function path(value)
	if type(value) ~= "string" or value == "" then return nil end
	value = value:gsub("^ReplicatedStorage%.", "")
	if not roots[value:match("^[^.]+") or ""] then return nil end
	local node = RS
	for segment in value:gmatch("[^.]+") do
		node = node:FindFirstChild(segment)
		if not node then return nil end
	end
	return node
end

function Resolver.Resolve(id)
	local def = Definitions[id]
	if not def then return nil, "Pet definition unavailable" end
	-- Existing paid Meadow reward pools retain their exact mesh/PBR binding validation.
	if def.IsMeadowPet then return MeadowModels.Resolve(id) end
	local key = def.ModelKey or def.ModelName or id
	if type(key) ~= "string" or key == "" then return nil, "Pet model key unavailable" end
	local petAssets = RS:FindFirstChild("PetAssets")
	local assets = RS:FindFirstChild("Assets")
	local legacy = assets and assets:FindFirstChild("Pets")
	local template = path(def.RealModelTemplate) or path(key)
		or (petAssets and petAssets:FindFirstChild(key)) or (legacy and legacy:FindFirstChild(key))
	if not template or not (template:IsA("Model") or template:IsA("BasePart")) or template:GetAttribute("Placeholder") then
		return nil, def.DisplayName .. ": imported model unavailable"
	end
	local descendants=template:GetDescendants()
 if template:IsA("BasePart") then table.insert(descendants,template) end
 local meshCount=0
 for _, descendant in ipairs(descendants) do
  if descendant:IsA("LuaSourceContainer") then return nil,def.DisplayName..": unexpected template script" end
  if descendant:GetAttribute("Placeholder") or descendant.Name:find("PENDING_REAL_MODEL_IMPORT") then return nil,def.DisplayName..": placeholder template" end
  if descendant:IsA("MeshPart") and descendant.MeshId~="" and descendant.Transparency<.99 then meshCount+=1 end
  if descendant:IsA("SpecialMesh") and descendant.MeshType==Enum.MeshType.FileMesh and descendant.MeshId~="" then meshCount+=1 end
 end
 if meshCount==0 then return nil,def.DisplayName..": real imported mesh required" end
 if def.ModelAssets and #def.ModelAssets>0 then
  local expected={};for _,binding in ipairs(def.ModelAssets)do expected[binding.MeshId]=binding end
  if meshCount~=#def.ModelAssets then return nil,def.DisplayName..": mesh count does not match import" end
  for _,part in ipairs(descendants)do if part:IsA("MeshPart")then
   local binding=expected[part.MeshId];if not binding then return nil,def.DisplayName..": mesh binding mismatch" end
   if binding.TextureId and part.TextureID~=binding.TextureId then return nil,def.DisplayName..": texture binding mismatch" end
   if binding.ColorMap then
    local surface=part:FindFirstChildWhichIsA("SurfaceAppearance");if not surface then return nil,def.DisplayName..": SurfaceAppearance missing" end
    for _,key in ipairs({"ColorMap","NormalMap","RoughnessMap","MetalnessMap"})do
     if binding[key] then local ok,value=pcall(function()return surface[key.."Content"].Uri end);if not ok or value~=binding[key]then return nil,def.DisplayName..": "..key.." binding mismatch" end end
    end
   end
  end end
 end
	if not Geometry.Measure(template) then return nil, def.DisplayName .. ": invalid visible bounds" end
	return template
end

function Resolver.Clone(id)
	local template, issue = Resolver.Resolve(id)
	if not template then return nil, issue end
	local clone = template:Clone()
	if not clone then return nil, "Pet model is unavailable for cloning" end
	local model = clone
	if clone:IsA("BasePart") then
		model = Instance.new("Model")
		clone.Parent = model
		model.PrimaryPart = clone
	end
	model.Name = id
	model:SetAttribute("PetTypeId", id)
	model:SetAttribute("CanonicalPet", true)
	if Definitions[id].IsMeadowPet then model:SetAttribute("CanonicalMeadowPet", true) end
	local particleBudget = 8
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
			part.CanTouch = false
			part.CanQuery = false
		elseif part:IsA("LuaSourceContainer") or part:IsA("ProximityPrompt") then
			part:Destroy()
		elseif part:IsA("ParticleEmitter") then
			part.Rate = math.min(part.Rate, particleBudget)
			particleBudget -= part.Rate
			part.Lifetime = NumberRange.new(math.min(part.Lifetime.Min, 2), math.min(part.Lifetime.Max, 2))
		end
	end
	model.PrimaryPart = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
	return model
end

return Resolver
