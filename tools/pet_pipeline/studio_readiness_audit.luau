-- Run in Studio Edit or Server through execute_luau. Read-only: no rewards,
-- profile writes, imports, gate changes, or publication. Actual interaction QA
-- is a separate mandatory step; this audit cannot certify that step.
local RS = game:GetService("ReplicatedStorage")
assert(game:GetService("RunService"):IsStudio(), "Studio only")
local Gameplay = RS.Shared.Gameplay
local Pets = require(Gameplay.Definitions.PetDefinitions)
local Biomes = require(Gameplay.Definitions.BiomeDefinitions)
local Families = require(Gameplay.Definitions.TreeFamilyDefinitions)
local Eggs = require(Gameplay.Definitions.EggDefinitions)
local Resolver = require(Gameplay.PetModelResolver)
local existingAudit = require(Gameplay.PetAssetValidator).Run()
local report = {place_id=game.PlaceId, universe_id=game.GameId, biomes={},
    existing_asset_audit=existingAudit, interaction_qa="not_run",
    scope="read-only definitions, model resolution, texture bindings and physical tree mapping"}
local physical = {}
for _, object in ipairs(workspace:GetDescendants()) do
    if object:IsA("Model") and object:GetAttribute("AuthoredGatherableTree") then
        local biome=object:GetAttribute("BiomeId") or object:GetAttribute("Biome")
        if biome then
            physical[biome]=physical[biome] or {mapped={},unmapped=0,total=0}
            local row=physical[biome];row.total+=1
            local family=object:GetAttribute("ShakeableId") or object:GetAttribute("RewardPoolId")
            if family and Families[family] and Families[family].Biome==biome then
                row.mapped[family]=(row.mapped[family] or 0)+1
            else row.unmapped+=1 end
        end
    end
end
local function validAsset(value)
    return type(value)=="string" and (value:match("rbxassetid://[1-9]%d*")~=nil
        or value:match("[?&]id=[1-9]%d*")~=nil)
end
for _, biome in ipairs(Biomes.Ordered) do
    local row={id=biome.Id,content_ready=Biomes.IsContentReady(biome.Id),families={},
        errors={},physical_trees=physical[biome.Id],interaction_qa="not_run"}
    local membership={}
    local families=Families.ByBiome[biome.Id] or {}
    if #families~=5 then table.insert(row.errors,"Expected five configured tree families") end
    for _, family in ipairs(families) do
        local familyRow={id=family.Id,name=family.DisplayName,errors={},pets={},
            physical_copies=physical[biome.Id] and physical[biome.Id].mapped[family.Id] or 0}
        local function fail(message)table.insert(familyRow.errors,message)end
        local egg=Eggs[family.Id]
        if type(family.Cost)~="number" or family.Cost<=0 then fail("Missing canonical search price") end
        if #family.PetIds==0 then fail("Empty species roster") end
        if familyRow.physical_copies==0 then fail("No mapped physical tree") end
        local rewardIds={}
        for _, entry in ipairs(egg and egg.Pets or {}) do
            if rewardIds[entry.PetId] then fail("Duplicate reward entry: "..entry.PetId) end
            rewardIds[entry.PetId]=true
            if type(entry.DropWeight)~="number" or entry.DropWeight<=0 then fail("Invalid drop weight") end
        end
        for _, id in ipairs(family.PetIds) do
            local pet=Pets[id];local petRow={id=id,errors={}}
            local function petFail(message)table.insert(petRow.errors,message)end
            if membership[id] then petFail("Species belongs to multiple normal families") end
            membership[id]=family.Id
            if not rewardIds[id] then petFail("Missing reward entry") end
            rewardIds[id]=nil
            if not pet or pet.Biome~=biome.Id or pet.LegacyOnly or pet.RetiredFromRewards then
                petFail("Invalid or retired species definition")
            else
                petRow.rarity=pet.Rarity;petRow.base_weight=pet.BaseWeight;petRow.base_income=pet.BaseIncome
                if type(pet.BaseWeight)~="number" or pet.BaseWeight<=0 then petFail("Missing gameplay weight") end
                if type(pet.BaseIncome)~="number" or pet.BaseIncome<=0 then petFail("Invalid income") end
                local template,reason=Resolver.Resolve(id)
                if not template then petFail(reason or "Missing model") else
                    petRow.template=template:GetFullName();petRow.meshes={}
                    local parts=template:GetDescendants()
                    if template:IsA("BasePart") then table.insert(parts,template) end
                    for _, part in ipairs(parts) do
                        if part:IsA("MeshPart") and part.Transparency<.99 then
                            local surface=part:FindFirstChildWhichIsA("SurfaceAppearance")
                            local color=part.TextureID
                            if surface then
                                local ok,uri=pcall(function()return surface.ColorMapContent.Uri end)
                                if ok and uri~="" then color=uri end
                            end
                            table.insert(petRow.meshes,{mesh_id=part.MeshId,color_map=color})
                            if not validAsset(part.MeshId) then petFail("Non-durable mesh binding") end
                            if not validAsset(color) then petFail("Non-durable or missing color texture") end
                        end
                    end
                    if #petRow.meshes==0 then petFail("No textured MeshParts for production import") end
                end
            end
            if #petRow.errors>0 then fail("Species QA failed: "..id) end
            table.insert(familyRow.pets,petRow)
        end
        for id in pairs(rewardIds) do fail("Unexpected reward entry: "..id) end
        familyRow.definition_and_asset_pass=#familyRow.errors==0
        if not familyRow.definition_and_asset_pass then table.insert(row.errors,"Family incomplete: "..family.Id) end
        table.insert(row.families,familyRow)
    end
    row.definition_and_asset_pass=#row.errors==0
    row.release_certified=false -- Actual feature/interaction tests still required.
    table.insert(report.biomes,row)
end
return game:GetService("HttpService"):JSONEncode(report)
