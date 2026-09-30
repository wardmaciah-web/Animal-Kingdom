-- Shared tuning only. The existing ChallengeService owns progress and settlement.
return {
 Version=1,
 Schedule={PublicInterval=240,InvitationSeconds=180,FirstInvitation=90,HotInterval=300,HotSeconds=120,CoopSeconds=900,MicroInterval=420},
 RushOrder={"Speed","Tour","Heavy","Rarity","Species","NoRepeat"},
 Rush={
  Speed={Name="Speed Search",Seconds=120,Target=5,Kind="Trees",BudgetSearches=5},
  Tour={Name="Tree Tour",Seconds=180,Target=5,Kind="Tour",BudgetSearches=5},
  Heavy={Name="Heavy Hunt",Seconds=240,Target=1,Kind="Heavy",Ratio=1.35,BudgetSearches=12,Random=true},
  Rarity={Name="Rarity Hunt",Seconds=240,Target=1,Kind="Rarity",Rarity=3,BudgetSearches=8,Random=true},
  Species={Name="Different Species",Seconds=240,Target=3,Kind="Species",BudgetSearches=8,Random=true},
  NoRepeat={Name="No Repeat",Seconds=180,Target=4,Kind="Families",BudgetSearches=4},
 },
 Paw={Seconds=360,Markers=6,Cooldown=600,Coins={Meadow=50,Forest=150},FinaleBias=.10},
 Adventure={Seconds=1800,Ratio=1.25,Coins={Meadow=300,Forest=1000},Tokens=3},
 BiomeGoals={Searches=5,Rarity=2,Ratio=1.15,Coins={Meadow=200,Forest=800},Tokens=2},
 Journey={Coins=300,Tokens=5},
 Mission={XP=100,Searches=8,Collect=500},
 FamilyRanks={5,15,35,70,120},FamilyLuckPerRank=.01,FamilyLuckCap=.05,
 HotOrder={"Heavy","Lucky","Rich","Fast","Mastery"},
 Hot={
  Heavy={Name="Heavy Tree",WeightBias=.15,Description="Higher weight bands gain 15% weight per band step."},
  Lucky={Name="Lucky Treelet",Luck=1.15,Description="×1.15 normal-search Luck on this tree."},
  Rich={Name="Rich Tree",CoinFraction=.10,CoinCap=250,Description="10% of the search price returned as bonus coins, up to 250."},
  Fast={Name="Fast Tree",Cooldown=12,Description="This tree returns in 12 seconds after a successful search."},
  Mastery={Name="Mastery Tree",Mastery=1,Description="One extra biome and family mastery search point."},
 },
 Limits={WeightBias=.40,NormalLuckExtra=1.5,RecoveryFloor=.75,PendingRewards=32,EventReceipts=256},
 Micro={
  {Id="Breeze",Biome="Meadow",Seconds=30,Message="A gentle breeze sweeps through Meadow…"},
  {Id="Fireflies",Biome="Forest",Seconds=60,Message="Fireflies are gathering in Forest…"},
  {Id="Restless",Biome="Forest",Seconds=30,Message="The Forest trees seem restless…"},
 },
}
