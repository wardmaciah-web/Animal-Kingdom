assert(game:GetService("RunService"):IsStudio())
local RS=game:GetService("ReplicatedStorage")
local harness=RS:WaitForChild("AK_MultiplayerHarness",180);if not harness then warn("AK_MULTI_CLIENT_FAIL no harness");return end
local remote=RS:WaitForChild("AnimalKingdomRemotes"):WaitForChild("UIRequest")
local seen={}
local function stage()
 local state=harness:GetAttribute("Stage");if not state or seen[state] then return end;seen[state]=true
 local target=harness.Target.Value
 if state=="Race" then remote:FireServer("Gather",{Target=target});task.delay(.4,function() remote:FireServer("Gather",{Target=target}) end)
 elseif state=="Hatch" then remote:FireServer("Hatch",{Target=target,Count=3})
 elseif state=="Complete" then print("AK_MULTI_CLIENT_DONE "..game.Players.LocalPlayer.Name) end
end
harness:GetAttributeChangedSignal("Stage"):Connect(stage);stage()
