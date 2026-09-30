local Legacy=require(script.Parent.Parent.Parent.Parent.SharedSource.Datas.PetDatabase)
local Biomes=require(script.Parent.BiomeDefinitions)
local Rarities=require(script.Parent.RarityDefinitions)
local Weights=require(script.Parent.PetWeightDefinitions)
local result={Ordered={}}
for _,pet in ipairs(Legacy.Ordered) do
 local rarity=pet.Rarity=="Mystic" and "Mythical" or pet.Rarity
 local def={PetId=pet.PetId,DisplayName=pet.Name,Name=pet.Name,Rarity=rarity,ModelName=pet.PetId,Biome=pet.Biome,
  BasePower=math.floor(4*1.65^(Biomes[pet.Biome].Order-1)*(Rarities[rarity].Order)),BaseSpeed=1,
  CoinsPerSecond=pet.CoinsPerSecond,Prismatic=pet.Prismatic,Protected=pet.Prismatic}
 result[pet.PetId]=def;table.insert(result.Ordered,def)
end
for _,entry in ipairs({{"Bunny","Common",4},{"Dog","Common",5},{"Deer","Rare",12},{"GoldenFox","Legendary",30}}) do
 local def={PetId=entry[1],DisplayName=entry[1]=="GoldenFox" and "Golden Fox" or entry[1],Name=entry[1],Rarity=entry[2],ModelName=entry[1],Biome="Meadow",BasePower=entry[3],BaseSpeed=1,CoinsPerSecond=1}
 result[def.PetId]=def;table.insert(result.Ordered,def)
end
-- Canonical Meadow roster. Model asset IDs are provenance, never MeshIds.
result.MeadowOrdered={}
for _,def in ipairs(result.Ordered) do if def.Biome=="Meadow" then def.LegacyOnly=true end end
local meadow={
 {"MeadowFieldMouse","Field Mouse","Common",2.5,113989055590248,"rbxassetid://127414738965477","rbxassetid://73748377999416","rbxassetid://107513294671066","rbxassetid://125785402534996","rbxassetid://128877854788095"},
 {"MeadowChick","Meadow Chick","Common",4,98876995093333,"rbxassetid://122845755829690","rbxassetid://77213563483513","rbxassetid://115349930864646","rbxassetid://131516093008909","rbxassetid://80616376937051"},
 {"MeadowHoneyLop","Honey Lop Bunny","Uncommon",1.5,nil,nil,nil,nil,nil,nil},
 {"MeadowRedSquirrel","Red Squirrel","Uncommon",6,110005101968034,"rbxassetid://73672924650229","rbxassetid://83064824068183","rbxassetid://91452865932667","rbxassetid://91604476939489","rbxassetid://84855289193392"},
 {"MeadowGoat","Meadow Goat","Uncommon",9,84570662269866,"rbxassetid://89904570166738","rbxassetid://79773020130638","rbxassetid://125176441379752","rbxassetid://134672877643564","rbxassetid://134593766738006"},
 {"MeadowFawn","Meadow Fawn","Rare",5,131817571953129,"rbxassetid://107263251366206","rbxassetid://76132821896289","rbxassetid://75047215073772","rbxassetid://70797534053995","rbxassetid://74949285323504"},
 {"MeadowFluffyLop","Fluffy Lop Bunny","Rare",8,72284151375691,"rbxassetid://99771514014908","rbxassetid://77371096825073","rbxassetid://90499505870975","rbxassetid://91625036019127","rbxassetid://76445437935068"},
 {"MeadowPatchworkLop","Patchwork Lop Bunny","Rare",3.5,100554319678383,"rbxassetid://129971024677390","rbxassetid://129853249692809","rbxassetid://87653626714147","rbxassetid://133854510456521","rbxassetid://140170357182395"},
 {"MeadowDaisyHedgehog","Daisy Hedgehog","Epic",14,95703383291167,"rbxassetid://82581654748495","rbxassetid://83789055307274","rbxassetid://131533535435586","rbxassetid://77242246500235","rbxassetid://102478534355936"},
 {"MeadowBuck","Meadow Buck","Epic",12,112116752525943,"rbxassetid://74693569451680","rbxassetid://116242731028580","rbxassetid://128041311526858","rbxassetid://72971033504395","rbxassetid://73864039726135"},
 {"MeadowDaisyCrownBunny","Daisy-Crown Bunny","Epic",14,133237199904570,"rbxassetid://70876461319097","rbxassetid://120392697720099","rbxassetid://132840718932667","rbxassetid://94880270353711","rbxassetid://135222764389571"},
 {"MeadowBlossomBunny","Blossom Bunny","Legendary",6,138223719551625,"rbxassetid://81163303277235","rbxassetid://110600438861044","rbxassetid://116518881029932","rbxassetid://122149791379322","rbxassetid://119040525148593"},
 {"MeadowPrismAntlerDeer","Prism-Antler Deer","Legendary",12,105166919366910,"rbxassetid://125325309083944","rbxassetid://70473479723436","rbxassetid://113832268002902","rbxassetid://101532226048659","rbxassetid://88319662713940"},
 {"MeadowCloudtailFox","Cloudtail Fox","Legendary",8,110305591746768,"rbxassetid://99272790538349","rbxassetid://100873128150834","rbxassetid://137574484960331","rbxassetid://140611944152897","rbxassetid://81175225099490"},
 {"MeadowCelestialLamb","Celestial Lamb","Secret",22,97905390781453,"rbxassetid://112434751758874","rbxassetid://104848496835588","rbxassetid://102063994556417","rbxassetid://110363759590435","rbxassetid://106228697606258"},
}
for _,row in ipairs(meadow) do
 local id,name,rarity,income,asset,mesh,color,normal,rough,metal=table.unpack(row,1,10)
 local def={PetId=id,PetTypeId=id,DisplayName=name,Name=name,Biome="Meadow",Rarity=rarity,
  BaseIncomePerSecond=income,CoinsPerSecond=income,BasePower=4*Rarities[rarity].Order,BaseSpeed=1,
  ModelName=id,RealModelTemplate="MeadowPetTemplates."..id,RobloxModelAssetId=asset,
  IsMeadowPet=true,LegacyOnly=id=="MeadowHoneyLop",RetiredFromRewards=id=="MeadowHoneyLop",Protected=rarity=="Secret",
  ModelAssets=mesh and {{MeshId=mesh,ColorMap=color,NormalMap=normal,RoughnessMap=rough,MetalnessMap=metal}} or {}}
 result[id]=def;table.insert(result.Ordered,def);table.insert(result.MeadowOrdered,def)
end
-- Future imports use one entry here plus their existing reward-pool entry.
-- ModelKey defaults to PetTypeId and resolves from ReplicatedStorage.PetAssets.
-- Optional visual metadata: ModelRotation / PreviewRotation / FollowerRotation /
-- GardenRotation / DisplayRotation (yaw degrees or Vector3 XYZ degrees),
-- FollowerScale / GardenScale / DisplayScale, and DisplayYOffset (clearance only).
local imported=table.clone(require(script.Parent.ForestPetDefinitions))
for _,def in ipairs(require(script.Parent.ImportedPetDefinitions))do table.insert(imported,def)end
result.ForestOrdered={}
for _,def in ipairs(result.Ordered) do if def.Biome=="Forest" then def.LegacyOnly=true end end
for _,def in ipairs(imported) do
 def.PetId=def.PetId or def.PetTypeId
 def.DisplayName=def.DisplayName or def.Name or def.PetId
 def.Name=def.DisplayName
 def.CoinsPerSecond=def.CoinsPerSecond or def.BaseIncome or def.BaseIncomePerSecond
 def.BasePower=def.BasePower or 4*(Rarities[def.Rarity] and Rarities[def.Rarity].Order or 1)
 def.BaseSpeed=def.BaseSpeed or 1
 assert(type(def.PetId)=="string" and not result[def.PetId],"Duplicate or missing PetTypeId")
 result[def.PetId]=def;table.insert(result.Ordered,def)
 if def.Biome=="Forest" then table.insert(result.ForestOrdered,def) end
end
for _,def in ipairs(result.Ordered) do
 def.PetTypeId=def.PetId
 def.ModelKey=def.ModelKey or def.RealModelTemplate or def.ModelName or def.PetId
 def.BaseIncome=def.BaseIncome or def.BaseIncomePerSecond or def.CoinsPerSecond
 def.BaseIncomePerSecond=def.BaseIncome
 -- Anonymous legacy definitions use a stable fallback; real species have curated kilograms.
 def.BaseWeight=def.BaseWeight or Weights.BySpecies[def.PetId] or 5
 def.MaxWeightMultiplier=def.MaxWeightMultiplier or Weights.MaxWeightMultiplier
 -- Salvage value starts at four seconds of base income. Rarity/weight bonuses
 -- stay useful without making ordinary tree searches a guaranteed resale profit.
 def.BaseSellValue=def.BaseSellValue or math.max(1,math.floor(def.BaseIncome*4))
end
-- Historical discoveries remain saved/visible; only currently obtainable species count toward milestones.
function result.IndexProgress(discoveries)
 local eligible=require(script.Parent.Parent.IndexCatalog).Current()
 local found,total=0,0
 for id in pairs(eligible)do total+=1;if discoveries and discoveries[id]~=nil then found+=1 end end
 return found,total,total>0 and found/total*100 or 0
end
return result
