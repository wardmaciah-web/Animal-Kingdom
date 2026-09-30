local Guard=require(script.Parent.GameplayGuard)
local Policy={}
local id=Guard.Id
local boolean=function(v) return type(v)=="boolean" end
local number=function(v) return Guard.Finite(v) and v>=0 and v%1==0 and v<=1e7 end
local target=function(v) return typeof(v)=="Instance" and (v:IsA("Model") or v:IsA("BasePart")) and v:IsDescendantOf(workspace) end
local offset=function(v) return typeof(v)=="Vector3" and Guard.Finite(v.X) and Guard.Finite(v.Y) and Guard.Finite(v.Z) and v.Magnitude<1000 end
Policy.Actions={
 MovePet={.2,{UID=id,Location=function(v)return v=='Inventory' or v=='Held' or v=='Sanctuary'end,Slot=number}},
 SwapSanctuary={.3,{HeldSlot=number,SanctuarySlot=number,HeldUID=function(v)return v=='' or id(v)end,SanctuaryUID=function(v)return v=='' or id(v)end}},
 SellPets={.5,{Mode=function(v)return v=='Inventory' or v=='Held'end,UID=function(v)return v=='' or id(v)end}},
 PetAssetsLoaded={.15,{Id=id,Signature=function(v)return type(v)=="string" and #v<=1024 end,Loaded=boolean}},
 DisplayMeadowPet={.2,{UID=id,Displayed=boolean}},
 Equip={.15,{UID=id,Equipped=boolean}},Favorite={.15,{UID=id,Value=boolean}},Lock={.15,{UID=id,Value=boolean}},
 RequestDelete={.3,{UID=id}},Delete={.3,{UID=id,Token=id}},
 LuckyTry={.3,{EventId=id,RequestId=id}},
 Gather={.3,{Target=target}},Upgrade={.4,{Id=id}},UnlockBiome={.5,{Id=id}},ClaimChallenge={.4,{Period=function(v) return v=="Daily" or v=="LegacyDaily" or v=="LegacyWeekly" or v=="Weekly" or v=="Contracts" end,Id=id}},
 ActivityAccept={1,{Id=id,Biome=id}},ActivityClaim={.5,{Id=id}},ActivityAbandon={.5,{Kind=id,Id=id}},PawDiscover={.25,{Id=id,Index=number}},
 MissionStart={.5,{UID=id,Kind=id}},MissionClaim={.5,{Id=id}},
 ClaimMastery={.5,{Biome=id,Level=number}},
 ClaimIndex={.5,{Percent=number}},ClaimSeasonal={.5,{Season=id,RewardId=id}},Setting={.2,{Id=id,Value=boolean}},AutoDelete={.2,{Rarity=id,Value=boolean}},
  TutorialNext={.3,{}},TutorialRevealDone={.3,{UID=id}},TutorialComplete={.5,{}},TutorialRestart={1,{}},ShopBuy={.5,{Id=id,RequestId=id,Rotation=number}},KingdomBuy={.5,{Id=id,RequestId=id,Rotation=number}},StartExpedition={.5,{UID=id,DurationId=id,RequestId=id}},ClaimExpedition={.5,{UID=id,RequestId=id}},CancelExpedition={.5,{UID=id,RequestId=id}},
  ClaimAllExpeditions={1.5,{RequestId=id}},VisitGarden={1.5,{}},ReturnGarden={1.5,{}},
  BuyGardenSupply={.5,{Id=id,RequestId=id}},UpgradeGarden={.5,{Id=id,RequestId=id}},
  BuyGardenCosmetic={.5,{Id=id,RequestId=id}},EquipGardenCosmetic={.5,{UID=id,CosmeticId=id,RequestId=id}},Place={.4,{Id=id,Offset=offset,Rotation=number}},RemovePlacement={.4,{UID=id}},
 TeleportPlot={1.5,{}},PlotVisitors={.5,{Allowed=boolean}},PlotUpgrade={.5,{}},CollectIdle={.5,{}},
}
function Policy.Check(player,action,payload)
 if not Guard.IsPlayer(player) or not Guard.RateLimit(player,"GameplayGlobal",.08) then return false end
 if type(action)~="string" or #action>32 then return false end
 local spec=Policy.Actions[action]
 if not spec or not Guard.Shape(payload,spec[2]) or not Guard.RateLimit(player,"Gameplay:"..action,spec[1]) then return false end
 return Guard.Alive(player)~=nil
end
return Policy
