-- One canonical event configuration. Imported templates and real Secret pets are
-- validated before scheduling; clients preload their visuals before announcing.
return {
 AutomaticEnabled=true,
 DelayMin=480,DelayMax=720,Lifetime=300,Attempts=3,BoostSeconds=300,
 AnnouncementSeconds=6,ShakeSeconds=.8,PersonalCooldown=3,SecretRevealSeconds=1.4,InteractionDistance=14,ReceiptEvents=8,
 Categories={{Id="Secret",DropWeight=5},{Id="Coins",DropWeight=40},{Id="Luck",DropWeight=55}},
 Biomes={
  Meadow={TemplateName="MeadowLuckyTree",LuckyTreeAssetId=119754675035340,TemplatePath="ReplicatedStorage.LuckyTreeTemplates.MeadowLuckyTree",TrunkPartName="LuckyTrunkCollider",
   SecretPetId="MeadowCelestialLamb",Coins=5000,LuckMultiplier=1.35},
  Forest={TemplateName="ForestLuckyTree",LuckyTreeAssetId=128685580375576,TemplatePath="ReplicatedStorage.LuckyTreeTemplates.ForestLuckyTree",TrunkPartName="LuckyTrunkCollider",ApproachClearance=4,
   SecretPetId="ForestEmeraldWing",Coins=20000,LuckMultiplier=1.55},
 },
 -- Candidate fractions of each CURRENT biome floor, not obsolete map coordinates.
 CandidateFractions={{-.30,-.30},{-.30,0},{-.30,.30},{0,-.30},{0,.30},{.30,-.30},{.30,0},{.30,.30},{-.15,-.15},{.15,.15},
  {.15,.40},{.30,.20},{.30,.25},{-.30,-.20},{-.30,-.25},{-.15,-.40},{-.10,-.10},{0,-.20},{.30,-.10},
  {-.10,-.05},{-.10,-.025},{-.075,-.025}},
 ApproachClearance=8,TeleportClearance=22,
}
