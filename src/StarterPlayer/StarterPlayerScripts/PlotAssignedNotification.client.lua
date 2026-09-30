-- Plot assignment uses the shared V2 toast and notification history.
local player=game.Players.LocalPlayer
local remote=game.ReplicatedStorage:WaitForChild('AnimalKingdomRemotes'):WaitForChild('AK_PlotAssigned')
local notice=player:WaitForChild('PlayerGui'):WaitForChild('AnimalKingdomUI'):WaitForChild('PresentationNotice')
local shown
local function show(id)
 if id==nil or tostring(id)=='' or id==shown then return end
 shown=id;notice:Fire('Your Sanctuary is ready. Open Plot to visit!')
end
remote.OnClientEvent:Connect(show)
player:GetAttributeChangedSignal('PlotId'):Connect(function()show(player:GetAttribute('PlotId'))end)
show(player:GetAttribute('PlotId'))
