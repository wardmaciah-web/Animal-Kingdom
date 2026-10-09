-- Additional real imports, from any configured biome, register here.
-- Each entry needs PetTypeId, DisplayName, Biome, Rarity, BaseIncome and ModelKey.
-- ModelKey resolves ReplicatedStorage.PetAssets; optional ModelAssets pins mesh/PBR provenance.
-- Add the registered species to its authoritative reward pool after validating the import.
return {
 {PetTypeId="JungleRedPanda",DisplayName="Red Panda",Biome="Jungle",Rarity="Epic",
  BaseWeight=7,BaseIncome=130,ModelKey="JungleRedPanda",ModelRotation=0,
  ProductionRun="red-panda-texture-001",ModelAssets={
   {MeshId="rbxassetid://101125666523290",ColorMap="rbxassetid://91899617902182",NormalMap="rbxassetid://86440326379848"},
   {MeshId="rbxassetid://114629416154775",TextureId="rbxassetid://91899617902182"},
  }},
 {PetTypeId="JungleOcelot",DisplayName="Ocelot",Biome="Jungle",Rarity="Rare",
  BaseWeight=12,BaseIncome=93,ModelKey="JungleOcelot",ModelRotation=0,
  ProductionRun="ocelot-d-reproduction-001",ModelAssets={
   {MeshId="rbxassetid://86956296653033",TextureId="rbxassetid://89955741043720"},
   {MeshId="rbxassetid://83705741042121",TextureId="rbxassetid://89955741043720"},
  }},
}
