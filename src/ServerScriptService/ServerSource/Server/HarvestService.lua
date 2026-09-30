-- Legacy remote forwards only to registered gatherables; paid pet rolls moved to eggs.
local Knit=require(game:GetService("ReplicatedStorage").Packages.Knit)
local Service=Knit.CreateService({Name="HarvestService",Client={}})
function Service.Client:Shake(player,target)
 if typeof(target)~="Instance" then return false end
 return Knit.GetService("ResourceService"):Gather(player,target)
end
return Service
