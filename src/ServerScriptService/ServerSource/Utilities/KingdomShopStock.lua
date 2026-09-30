-- Extension of the existing ShopService, using its existing currencies/profile.
local RS=game.ReplicatedStorage
local Knit=require(RS.Packages.Knit)
local Http=game.HttpService
local Defs=require(RS.Shared.Gameplay.Definitions.KingdomShopDefinitions)
local P=require(RS.Shared.Gameplay.KingdomProgress)
local M={};M.__index=M
local function service(id)return Knit.GetService(id)end
local function now()return workspace:GetServerTimeNow()end
function M.new(owner)
 local folder=RS:FindFirstChild('KingdomShopStock')or Instance.new('Folder');folder.Name='KingdomShopStock';folder.Parent=RS
 return setmetatable({Owner=owner,Folder=folder},M)
end
function M:Tick()
 local rotation=Defs.Rotation(now());if self.Rotation==rotation then return end
 local first=self.Rotation==nil;self.Rotation=rotation
 self.Folder:SetAttribute('Rotation',rotation);self.Folder:SetAttribute('RestockAt',(rotation+1)*Defs.RotationSeconds)
 self.Folder:SetAttribute('Offers',Http:JSONEncode(Defs.Offers(rotation)))
 if not first then service('NotificationService'):Announce('Shop:'..rotation,'The Kingdom Shop has restocked. Browse anywhere; purchase at the Town store.',45,'Shop')end
end
function M:Buy(player,id,rotation,requestId)
 return service('PetService'):Transaction(player,function()
  local d=service('PlayerDataService'):Get(player);local _,s=P.Ensure(d)
  local key=tostring(rotation);local saved=s.Rotations[key]
  local receipt=saved and saved.Receipts and saved.Receipts[requestId]
  if not receipt then for _,previous in pairs(s.Rotations)do if previous.Receipts and previous.Receipts[requestId]then receipt=previous.Receipts[requestId];break end end end
  if receipt then
   if receipt.OfferId~=id then return false,'This request already belongs to another offer.'end
   return true,receipt
  end
  if rotation~=Defs.Rotation(now())then return false,'Stock changed. Refresh the Shop before purchasing.'end
  if not self.Owner:IsNearShop(player)then return false,'Walk to the Town General Store to purchase. You can browse stock from anywhere.'end
  if not d.TutorialCompleted then return false,'Finish the tutorial before buying boosts.'end
  local offer;for _,o in ipairs(Defs.Offers(rotation))do if o.Id==id then offer=o;break end end
  if not offer then return false,'This offer is not in the current stock.'end
  local def=Defs[offer.EffectId];saved=saved or {Counts={},Receipts={}}
  if (saved.Counts[id]or 0)>=offer.Limit then return false,'You have bought this rotation’s personal limit.'end
  if def.Seconds and P.Active(d,offer.EffectId,now())then return false,'This effect is already active. Wait for it to expire; purchases do not refresh or extend it.'end
  if offer.EffectId=='Fertilizer'and s.Fertilizer>=1 then return false,'Your next-trip Fertilizer is already pending. Start a valid expedition before buying another.'end
  if offer.EffectId=='Blessing'and d.UncollectedSanctuaryCoins>=9e15 then return false,'Your Sanctuary collector is full. Make room before buying a Blessing.'end
  local economy=service('EconomyService')
  if not economy:CanAfford(player,offer.Currency,offer.Price)then return false,'You need '..offer.Price..' '..(offer.Currency=='Coins'and 'Forest Coins'or 'Friendship Tokens')..' for this offer.'end
  -- Settle the old income interval before changing the boost boundary.
  if offer.EffectId=='Blessing'then service('SanctuaryService'):Accrue(player)end
  local at=now();local result={Kind='KingdomPurchase',RequestId=requestId,OfferId=id,EffectId=offer.EffectId,Rotation=rotation,Price=offer.Price,Currency=offer.Currency,PurchasedAt=at,Text=def.Name..' purchased.'}
  if not economy:Spend(player,offer.Currency,offer.Price,'KingdomShop')then return false,'Not enough currency.'end
  if def.Seconds then
   s.Active[offer.EffectId]={StartedAt=at,ExpiresAt=at+def.Seconds};result.ExpiresAt=at+def.Seconds
  else s.Fertilizer=1 end
  saved.Counts[id]=(saved.Counts[id]or 0)+1;saved.Receipts[requestId]=result;s.Rotations[key]=saved
  -- Previous rotations cannot be bought again even after receipt pruning.
  for old in pairs(s.Rotations)do if (tonumber(old)or 0)<rotation-144 then s.Rotations[old]=nil end end
  service('PlayerDataService'):Publish(player,'KingdomShop');service('ModifierService'):PublishOdds(player);service('PetService'):RequestSave(player)
  return true,result
 end)
end
return M
