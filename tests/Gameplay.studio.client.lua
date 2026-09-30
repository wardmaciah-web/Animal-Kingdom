-- Temporary Studio LocalScript paired with Gameplay.studio.server.lua.
assert(game:GetService("RunService"):IsStudio())
task.spawn(function()
 local player=game.Players.LocalPlayer;local gui=player:WaitForChild("PlayerGui"):WaitForChild("AnimalKingdomUI",60)
 local checks,failures=0,0
 local function check(ok,name) checks+=1;if not ok then failures+=1 end;print("AK_GAMEPLAY_CLIENT "..(ok and "PASS " or "FAIL ")..name) end
 local deadline=os.clock()+120
 repeat task.wait(.1) until workspace:GetAttribute("AK_GameplayTestStage")=="Equipped" or workspace:GetAttribute("AK_GameplayTestStage")=="Complete" or os.clock()>deadline
 if workspace:GetAttribute("AK_GameplayTestStage")=="Equipped" then
  task.wait(1)
  check(gui and gui:FindFirstChild("HUD")~=nil,"live HUD instantiated")
  check(gui and gui:FindFirstChild("HatchReveal")~=nil,"client received real hatch reveal")
  local folder=workspace:FindFirstChild("LocalPetFollowers")
  check(folder and #folder:GetChildren()>=1,"equipped pet follower rendered")
  local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
  local near,safe=false,true
  if folder then
   for _,model in ipairs(folder:GetChildren()) do
    if root and (model:GetPivot().Position-root.Position).Magnitude<20 then near=true end
    for _,part in ipairs(model:GetDescendants()) do if part:IsA("BasePart") and (not part.Anchored or part.CanCollide or part.CanTouch or part.CanQuery) then safe=false end end
   end
  end
  check(near,"pet interpolation recovers after test teleport")
  check(safe,"pet models are cosmetic and noncolliding")
  task.wait(2.5)
  local hatch=gui:FindFirstChild("HatchReveal");local reveals=0
  if hatch then for _,v in ipairs(hatch:GetChildren()) do if v:IsA("ViewportFrame") then reveals+=1 end end end
  check(reveals==3,"triple hatch displays three pet viewports")
 else check(false,"server did not reach hatch/equip stage") end
 print("AK_GAMEPLAY_CLIENT_DONE assertions="..checks.." failures="..failures)
end)
