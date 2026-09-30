-- All connected progression tuning; no permanent modifiers or new currencies.
return {
 Contracts={Active=3,ReceiptLimit=16,
  Search={Target=10,CostFactor=2,Tokens=3},
  Family={Target=5,CostFactor=1,Tokens=2},
  Variety={Target=3,CostFactor=1,Tokens=3},
  Heavy={Target=1,WeightRatio=1.5,CostFactor=1,Tokens=3},
  Discovery={Target=1,CostFactor=1,Tokens=3},
  Collector={Target=1000,Coins=100,Tokens=2},
  Garden={Target=1,Coins=100,Tokens=2},
 },
 Mastery={
  {Searches=20,Discoveries=3,RewardSearches=2,Tokens=5},
  {Searches=75,Discoveries=6,RewardSearches=5.5,Tokens=10},
  {Searches=200,Discoveries=8,RewardSearches=12.5,Tokens=20},
 },
 Streak={IdleSeconds=600,Tiers={{Searches=0,Bonus=0},{Searches=5,Bonus=.05},{Searches=10,Bonus=.10},{Searches=20,Bonus=.15}}},
}
