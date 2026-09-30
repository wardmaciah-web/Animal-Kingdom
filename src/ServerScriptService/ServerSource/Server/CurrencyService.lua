-- Compatibility adapter: one economy owns every currency write.
local Knit=require(game:GetService("ReplicatedStorage").Packages.Knit)
local Service=Knit.CreateService({Name="CurrencyService",Client={}})
local Economy
function Service:Get(...) return Economy:GetBalance(...) end
function Service:Add(...) return Economy:Add(...) end
function Service:Spend(...) return Economy:Spend(...) end
function Service:KnitInit() Economy=Knit.GetService("EconomyService") end
return Service
