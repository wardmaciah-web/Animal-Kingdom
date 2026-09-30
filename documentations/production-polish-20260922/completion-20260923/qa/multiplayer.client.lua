-- Temporary Studio QA only. It is not part of the Rojo project.
if not game:GetService('RunService'):IsStudio() then return end
local RS=game:GetService('ReplicatedStorage');local remote=RS:WaitForChild('AKMultiplayerQA',120);if not remote then return end
local K=require(RS.Packages.Knit);K.OnStart():await()
remote.OnClientInvoke=function(action)
 local p=game.Players.LocalPlayer;local d=K.GetController('DataController'):GetPlayerData();local ui=p.PlayerGui:FindFirstChild('AnimalKingdomUI');local reveal=ui and ui:FindFirstChild('CompanionReveal');local owned,garden={},{}
 for _,pet in ipairs(d.Pets)do owned[pet.UID]=pet.PetId end
 for _,trip in ipairs(d.GardenExpeditions)do garden[trip.UID]=trip.PetId end
 local followers={};local folder=workspace:FindFirstChild('LocalPetFollowers');if folder then for _,m in ipairs(folder:GetChildren())do table.insert(followers,m:GetAttribute('PetTypeId'))end end
 local display={};local folder=workspace:FindFirstChild('Sanctuaries');folder=folder and folder:FindFirstChild(tostring(p.UserId));folder=folder and folder:FindFirstChild('DisplayedPets');if folder then for _,m in ipairs(folder:GetChildren())do display[m.Name]=m:GetAttribute('PetTypeId')end end
 return {Player=p.Name,UserId=p.UserId,PlaceId=game.PlaceId,Owned=owned,Garden=garden,Currencies=d.Currencies,Equipped=d.EquippedPets,Followers=followers,Display=display,RevealPet=reveal and reveal:GetAttribute('PetTypeId'),Camera=tostring(workspace.CurrentCamera.CameraType),Mouse=tostring(game:GetService('UserInputService').MouseBehavior),Ready=p:GetAttribute('AKImportedPetsReady'),Plot=p:GetAttribute('PlotId'),GardenPlot=p:GetAttribute('GardenPlotId')}
end
