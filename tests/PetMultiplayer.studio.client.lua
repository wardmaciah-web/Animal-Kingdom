if not game:GetService('RunService'):IsStudio() then return end
local RS=game.ReplicatedStorage;local remote=RS:WaitForChild('AKPetMultiplayerQA',120);if not remote then return end
local K=require(RS.Packages.Knit);K.OnStart():await()
remote.OnClientInvoke=function()
 local p=game.Players.LocalPlayer;local d=K.GetController('DataController'):GetPlayerData();local ui=p.PlayerGui.AnimalKingdomUI
 local pets={};for _,pet in ipairs(d.Pets)do pets[pet.UID]={PetId=pet.PetId,Weight=pet.Weight,Location=pet.Location,Income=pet.CoinsPerSecond}end
 local reveal=ui:FindFirstChild('CompanionReveal');local held=ui.Interface.HeldPets
 return {UserId=p.UserId,Pets=pets,Coins=d.Currencies.Coins,Held=d.HeldPetSlots,Sanctuary=d.SanctuaryPetSlots,Garden=d.GardenExpeditions,RevealPet=reveal and reveal:GetAttribute('PetTypeId'),Camera=workspace.CurrentCamera.CameraType.Name,HeldBar=held~=nil,Plot=p:GetAttribute('PlotId'),GardenPlot=p:GetAttribute('GardenPlotId')}
end
