local RS=game:GetService("ReplicatedStorage")
local Knit=require(RS.Packages.Knit)
local Definitions=require(RS.Shared.Gameplay.Definitions.ShopDefinitions)
local StockDefs=require(RS.Shared.Gameplay.Definitions.KingdomShopDefinitions)
local Progress=require(RS.Shared.Gameplay.KingdomProgress)
local Town=require(script.Parent.Parent.Utilities.TownInteractions)
local Service=Knit.CreateService({Name="ShopService",Client={}})
function Service:IsNearShop(player)return Town.Near(player,'Shop',StockDefs.Distance)end
function Service:BuyBoost(player,id,rotation,requestId)return self.Stock:Buy(player,id,rotation,requestId)end
function Service:Buy(player,id,requestId,rotation)
 return Knit.GetService('PetService'):Transaction(player,function()
 local def=Definitions[id];local data=Knit.GetService("PlayerDataService"):Get(player)
 if not def or not data then return false,"Invalid item" end
 local _,s=Progress.Ensure(data);local receipt=s.Receipts[requestId]
 if receipt then if receipt.ItemId~=id then return false,'Request identity belongs to another item.'end;return true,receipt.Text end
 if rotation~=StockDefs.Rotation(workspace:GetServerTimeNow())then return false,'Please refresh the Shop before purchasing.'end
 if not self:IsNearShop(player)then return false,'Walk to the Town General Store to purchase. Browsing is available anywhere.'end
 if def.Season and not Knit.GetService("SeasonalService"):IsActive(def.Season) then return false,"Season is inactive" end
 if def.UpgradeId then return Knit.GetService("UpgradeService"):Purchase(player,def.UpgradeId) end
 local assets=RS:FindFirstChild('Assets');local category=assets and assets:FindFirstChild(def.Category);local template=category and category:FindFirstChild(def.ModelName)
 if not template or template:GetAttribute('Placeholder') or not(template:IsA('BasePart')or template:FindFirstChildWhichIsA('BasePart',true))then return false,'This item is temporarily unavailable.'end
 if (data.Items[id] or 0)>=def.MaxOwned then return false,"Item capacity reached" end
 if not Knit.GetService("EconomyService"):Spend(player,def.Currency,def.Cost,"Shop") then return false,"Not Enough "..def.Currency end
 data.Items[id]=(data.Items[id] or 0)+1
 s.Receipts[requestId]={ItemId=id,Rotation=rotation,Text=def.DisplayName..' purchased!'}
 for key,r in pairs(s.Receipts)do if r.Rotation<rotation-144 then s.Receipts[key]=nil end end
 Knit.GetService("PlayerDataService"):Publish(player,"Items","KingdomShop");Knit.GetService('PetService'):RequestSave(player)
 return true,def.DisplayName.." purchased!"
 end)
end
function Service:KnitStart()
 self.Stock=require(script.Parent.Parent.Utilities.KingdomShopStock).new(self)
 Town.Start();self.Stock:Tick()
 task.spawn(function()while task.wait(1)do self.Stock:Tick()end end)
end
return Service
