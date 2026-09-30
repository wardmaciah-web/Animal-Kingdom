local function upgrade(name,key,max,cost,growth,effect,currency)
 local costs={};for level=1,max do costs[level]=math.floor(cost*growth^(level-1)) end
 return {DisplayName=name,Key=key,MaxLevel=max,Costs=costs,Effect=effect,Currency=currency or "Coins"}
end
return {
 PetStorage=upgrade("Pet Storage","PetStorageCapacity",20,500,1.55,25),
 EquippedSlots={DisplayName="Held Pet Slots",Key="MaxEquippedPets",MaxLevel=9,Costs={},Effect=0,Currency="Coins",Retired=true},
 Luck=upgrade("Luck","Luck",10,1000,2,.15),HatchSpeed=upgrade("Hatch Speed","HatchSpeed",8,1000,1.8,.15),
 WalkSpeed=upgrade("Walk Speed","WalkSpeed",8,500,1.8,.06),
 Coins=upgrade("Coin Multiplier","Coins",15,750,1.9,.15),
 FriendshipTokens=upgrade("Friendship Token Multiplier","FriendshipTokens",10,100,1.8,.15,"FriendshipTokens"),
 GatheringPower=upgrade("Gathering Power","GatheringPower",15,1000,1.8,.2),
 ResourceRewards=upgrade("Resource Reward Multiplier","ResourceRewards",15,1500,1.9,.15),
}
