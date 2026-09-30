local RS=game:GetService("ReplicatedStorage")
local Knit=require(RS.Packages.Knit)
local Signal=require(RS.Packages.Signal)
local Definitions=require(RS.Shared.Gameplay.Definitions.CurrencyDefinitions)
local Economy=Knit.CreateService({Name="EconomyService",Client={},Changed=Signal.new()})
local Data
local function valid(amount)
 return type(amount)=="number" and amount==amount and amount>=0 and amount<math.huge and amount%1==0
end
local function canonical(id) return id=="ForestCoins" and "Coins" or id end
function Economy:GetBalance(player,currency)
 currency=canonical(currency)
 local data=Data:Get(player)
 return data and Definitions[currency] and (data.Currencies[currency] or 0) or nil
end
function Economy:CanAfford(player,currency,amount)
 local balance=self:GetBalance(player,currency)
 return valid(amount) and balance~=nil and balance>=amount
end
function Economy:Add(player,currency,amount,reason)
 currency=canonical(currency)
 if not Definitions[currency] or not valid(amount) or amount==0 then return false end
 local data=Data:Get(player)
 if not data then return false end
 local old=data.Currencies[currency] or 0
 local credited=math.min(amount,Definitions[currency].MaxBalance-old)
 if credited<=0 then return false end
 data.Currencies[currency]=old+credited
 self:Publish(player,currency)
 self.Changed:Fire(player,currency,credited,reason or "Reward")
 return true,credited
end
-- Fixed feature rewards must fit in full. Never consume a claim for a clipped payout.
function Economy:CanReceive(player,rewards)
 local data=Data:Get(player);if not data then return false,"Profile is loading" end
 for currency,amount in pairs(rewards)do
  if not Definitions[currency] or not valid(amount)then return false,"Invalid reward" end
  if (data.Currencies[currency] or 0)+amount>Definitions[currency].MaxBalance then return false,"Make room for the full reward in your "..Definitions[currency].DisplayName.." balance." end
 end
 return true
end
function Economy:GrantExact(player,rewards,reason,commit)
 local ok,why=self:CanReceive(player,rewards);if not ok then return false,why end
 local data=Data:Get(player)
 -- The caller holds the existing per-player transaction lock. This section cannot yield.
 for currency,amount in pairs(rewards)do data.Currencies[currency]=(data.Currencies[currency] or 0)+amount end
 if commit then commit()end
 for currency,amount in pairs(rewards)do
  self:Publish(player,currency)
  if amount>0 then self.Changed:Fire(player,currency,amount,reason)end
 end
 return true
end
function Economy:Spend(player,currency,amount,reason)
 currency=canonical(currency)
 if not self:CanAfford(player,currency,amount) then return false end
 local data=Data:Get(player)
 data.Currencies[currency]-=amount
 self:Publish(player,currency)
 self.Changed:Fire(player,currency,-amount,reason or "Purchase")
 return true
end
function Economy:Publish(player,currency)
 local data=Data:Get(player)
 if currency=="Coins" then data.ForestCoins=data.Currencies.Coins
 elseif currency=="FriendshipTokens" then data.FriendshipTokens=data.Currencies.FriendshipTokens end
 Data:Publish(player,"Currencies","ForestCoins","FriendshipTokens")
end
function Economy:KnitInit() Data=Knit.GetService("PlayerDataService") end
return Economy
