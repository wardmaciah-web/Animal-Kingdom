local p=game.Players.LocalPlayer;local ui=p.PlayerGui:WaitForChild("AnimalKingdomUI")
local H=game.HttpService;local report={Reveals={},Showcases={},Labels={}};local shown={}
game.ReplicatedStorage.AnimalKingdomRemotes.GameplayFeedback.OnClientEvent:Connect(function(payload)
 if payload.Action=="TreeHatch" and payload.Success then local r=payload.Result;table.insert(report.Reveals,{Id=r.PoolId,Cost=r.Cost,UID=r.Results[1].Pet.UID})end
end)
while true do
 local gui=ui:FindFirstChild("CompanionReveal")
 if gui and gui:GetAttribute("Phase")=="Showcase" then local uid=gui:GetAttribute("OwnedPetInstanceId");if not shown[uid]then shown[uid]=true;table.insert(report.Showcases,{PetId=gui:GetAttribute("PetTypeId"),UID=uid,ViewportPresent=gui:FindFirstChild("EarnedPet",true)~=nil})end end
 local labels={};for _,x in ipairs(workspace:GetDescendants())do if x:IsA("TextLabel") and x.Name=="PetIncome" then table.insert(labels,{Text=x.Text,Path=x:GetFullName()})end end
 report.Labels=labels;ui:SetAttribute("AKEconomyClient",H:JSONEncode(report));task.wait(.5)
end
