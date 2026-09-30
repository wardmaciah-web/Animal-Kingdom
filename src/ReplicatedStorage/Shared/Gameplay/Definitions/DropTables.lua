local Biomes=require(script.Parent.BiomeDefinitions)
local tables={}
for _,biome in ipairs(Biomes.Ordered) do
 tables[biome.ResourceTable]={
  {Weight=78,Currency="Coins",Min=biome.BaseReward,Max=math.floor(biome.BaseReward*1.4)},
  {Weight=18,Currency="Coins",Min=biome.BaseReward*2,Max=biome.BaseReward*3},
  {Weight=4,Currency="FriendshipTokens",Min=biome.Order*2,Max=biome.Order*4,Coins=biome.BaseReward},
 }
end
-- Supplemental server-only rolls, gated by the current weather.
tables.MeteorLoot={{Weight=95,Currency="Coins",Min=250,Max=500},{Weight=5,ItemId="MeteorShard",Min=1,Max=1}}
tables.StormLoot={{Weight=95,Currency="FriendshipTokens",Min=2,Max=6},{Weight=5,ItemId="StormCrystal",Min=1,Max=1}}
return tables
