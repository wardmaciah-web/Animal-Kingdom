assert(game:GetService("RunService"):IsStudio())
local RS=game:GetService("ReplicatedStorage");local player=game.Players.LocalPlayer
local remotes=RS:WaitForChild("AnimalKingdomRemotes");local harness=RS:WaitForChild("AKTreeLoopHarness",180)
if not harness then warn("AK_TREE_CLIENT_FAIL missing harness");return end
local checks,failures=0,0;local seen={};local hatches=0
local function check(ok,message) checks+=1;if not ok then failures+=1 end;print("AK_TREE_CLIENT "..(ok and "PASS " or "FAIL ")..message) end
remotes.GameplayFeedback.OnClientEvent:Connect(function(payload)
 if payload.Action~="TreeHatch" or not payload.Success then return end
 hatches+=1
 check(payload.Result.EggId=="MeadowEgg" and #payload.Result.Results==1,"actual tree result shows one biome egg/pet")
 task.delay(.3,function()
  local gui=player.PlayerGui:FindFirstChild("AnimalKingdomUI")
  local reveal=gui and gui:FindFirstChild("HatchReveal")
  check(reveal~=nil,"immediate hatch view appears without world egg")
 end)
 task.delay(payload.Result.Duration+.4,function()
  local gui=player.PlayerGui:FindFirstChild("AnimalKingdomUI");local reveal=gui and gui:FindFirstChild("HatchReveal")
  local named=false
  if reveal then for _,v in ipairs(reveal:GetDescendants()) do if v:IsA("TextLabel") and v.Text:find("\n",1,true) then named=true end end end
  check(named,"pet name/rarity reveal rendered")
 end)
end)
local function stage()
 local name=harness:GetAttribute("Stage");if not name or seen[name] then return end;seen[name]=true
 local target=harness:FindFirstChild(tostring(player.UserId))
 if name=="Full" then
  if player.UserId==harness:GetAttribute("FullUserId") then remotes.UIRequest:FireServer("Gather",{Target=target.Value}) end
 elseif name=="Race" or name=="Independent" then
  remotes.UIRequest:FireServer("Gather",{Target=target.Value})
  if name=="Race" then task.delay(.4,function() remotes.UIRequest:FireServer("Gather",{Target=target.Value}) end) end
 elseif name=="Complete" then
  print("AK_TREE_CLIENT_DONE player="..player.Name.." hatches="..hatches.." assertions="..checks.." failures="..failures)
 end
end
harness:GetAttributeChangedSignal("Stage"):Connect(stage);stage()
