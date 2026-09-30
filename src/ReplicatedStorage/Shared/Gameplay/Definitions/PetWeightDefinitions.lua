-- Gameplay kilograms, independent of mesh mass and species drop odds.
return {
 MaxWeightMultiplier=3, IncomeExponent=.75, ScaleExponent=.35, MaxVisualScale=1.6,
 -- Conditional, lower-biased bands. Luck only modestly reweights the tail.
 Bands={
  {Minimum=1,Maximum=1.15,DropWeight=8000},
  {Minimum=1.15,Maximum=1.35,DropWeight=1500},
  {Minimum=1.35,Maximum=1.75,DropWeight=400},
  {Minimum=1.75,Maximum=3,DropWeight=100},
 },
 BySpecies={
  MeadowFieldMouse=.1,MeadowChick=.4,MeadowHoneyLop=2.2,MeadowRedSquirrel=.5,
  MeadowGoat=18,MeadowFawn=14,MeadowFluffyLop=2.8,MeadowPatchworkLop=3,
  MeadowDaisyHedgehog=1.2,MeadowBuck=55,MeadowDaisyCrownBunny=3.2,
  MeadowBlossomBunny=3.5,MeadowPrismAntlerDeer=70,MeadowCloudtailFox=7,MeadowCelestialLamb=12,
  ForestRaccoon=6,ForestBlackBearCub=18,ForestSkunk=3,ForestBadger=12,
  ForestTreeFrog=.2,ForestRiverOtter=9,ForestBrownBat=.3,ForestWoodlandOwl=1.5,
  ForestCrestedOwl=2.4,ForestLeafAntler=70,ForestEmeraldWing=40,
  Bunny=2.5,Dog=12,Deer=55,GoldenFox=7,
 },
}
