local RS=game.ReplicatedStorage
local K=require(RS.Packages.Knit)
local d=K.GetController('DataController'):GetPlayerData()
local pet=d.Pets[1];local original={Weight=pet.Weight,Location=pet.Location,Income=pet.CoinsPerSecond,Value=pet.SellValue}
local feedback={}
local c=RS.AnimalKingdomRemotes.GameplayFeedback.OnClientEvent:Connect(function(v)if v.RequestId and v.RequestId:sub(1,9)=='qa-spoof-'then feedback[v.RequestId]=v end end)
for i,extra in ipairs({'Weight','CoinsPerSecond','SellValue','PetId'})do
 local payload={UID=pet.UID,Location='Inventory',Slot=0};payload[extra]=extra=='PetId'and 'ForestEmeraldWing'or 1e9
 RS.AnimalKingdomRemotes.UIRequest:FireServer('MovePet',payload,'qa-spoof-'..i)
 task.wait(.3)
end
c:Disconnect()
for i=1,4 do assert(feedback['qa-spoof-'..i]and not feedback['qa-spoof-'..i].Success,'Spoof must fail')end
assert(pet.Weight==original.Weight and pet.Location==original.Location and pet.CoinsPerSecond==original.Income and pet.SellValue==original.Value,'Spoof changed owned data')
return {Attempts=4,ClientWeightIncomeValueSpeciesRejected=true,OwnedStatsUnchanged=true,Feedback=feedback}
