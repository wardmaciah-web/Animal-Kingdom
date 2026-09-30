-- Server-filtered announcements share the V2 toast and scrollable history.
local remote=game.ReplicatedStorage:WaitForChild('AnimalKingdomRemotes'):WaitForChild('GlobalAnnouncement')
local notice=game.Players.LocalPlayer:WaitForChild('PlayerGui'):WaitForChild('AnimalKingdomUI'):WaitForChild('PresentationNotice')
remote.OnClientEvent:Connect(function(payload)
 if type(payload)=='table' and type(payload.Message)=='string' and #payload.Message<=2000 then
  payload.World=true;notice:Fire(payload)
 end
end)
