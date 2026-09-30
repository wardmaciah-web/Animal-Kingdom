-- Run in the CLIENT Command Bar during a local Studio Play test as an authorized admin.
-- Exercises real remotes and real map landing points; does not change saved map objects.
assert(game:GetService("RunService"):IsStudio() and game:GetService("RunService"):IsRunning() and game:GetService("RunService"):IsClient(), "Client Play context required")
task.spawn(function()
 local player=game.Players.LocalPlayer
 local storage=game.ReplicatedStorage
 local remotes=storage:WaitForChild("AnimalKingdomRemotes")
 local definitions=require(storage.Shared.AdminCommandDefinitions)
 local weather=storage.WeatherState
 local latest,announcement,lastState
 local response=remotes.AdminCommandResponse.OnClientEvent:Connect(function(value) latest=value end)
 local message=remotes.GlobalAnnouncement.OnClientEvent:Connect(function(value) announcement=value.Message end)
 local state=remotes.AdminCommandState.OnClientEvent:Connect(function(value) lastState=value end)
 local failures=0
 local function check(ok,name,detail)
  print("AK_P2_LIVE "..(ok and "PASS " or "FAIL ")..name.." "..tostring(detail or ""))
  if not ok then failures+=1 end
 end
 local function send(payload)
  task.wait(0.55)
  latest=nil
  remotes.AdminCommandRequest:FireServer(payload)
  local deadline=os.clock()+10
  repeat task.wait(.1) until latest or os.clock()>deadline
  return latest
 end
 local ok,err=pcall(function()
  task.wait(1.2)
  assert(lastState and lastState.Authorized,"Authorized account required")
  local r=send({Action="Teleport",Destination="AdminRoom"})
  assert(r and r.Success,"Cannot enter Admin Room")
  task.wait(1.2)
  check(#workspace.WeatherAdminRoom.AdminCommandCenter:GetChildren()==6,"six room panels")
  local titles=0
  for _,obj in ipairs(workspace.WeatherAdminRoom.CameraWallPanels:GetDescendants()) do
   if obj:IsA("SurfaceGui") and obj.Name=="CameraTitleSurface" then titles+=1 end
  end
  check(titles==15,"camera labels preserved",titles)
  check(lastState.Plots.Available,"authoritative plots",lastState.Plots.Claimed.." / "..lastState.Plots.Total)
  for _,destination in ipairs(definitions.Destinations) do
   local result=send({Action="Teleport",Destination=destination.Id})
   check(result and result.Success,"teleport "..destination.Id,result and result.Message)
   if result and result.Success then
    local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    print("AK_P2_POSITION "..destination.Id.." "..tostring(root and root.Position))
   end
   local back=send({Action="Teleport",Destination="AdminRoom"})
   assert(back and back.Success,"Cannot return to admin room")
  end
  r=send({Action="Announce",Message="Welcome to Animal Kingdom!"})
  check(r and r.Success and announcement~=nil,"filtered announcement",announcement or (r and r.Message))
  task.wait(.6)
  remotes.WeatherAdminAction:FireServer({Action="StartEvent",EventId="RainyDay"})
  task.wait(1)
  r=send({Action="QueueEvent",EventId="MeteorShower"})
  check(r and r.Success and weather:GetAttribute("EventId")=="RainyDay","queue preserves current event")
  check(weather:GetAttribute("EndsAt")-weather:GetAttribute("StartedAt")==420,"production event duration")
  remotes.WeatherAdminAction:FireServer({Action="EndEvent"})
  local deadline=os.clock()+10
  repeat task.wait(.25) until weather:GetAttribute("EventId")=="MeteorShower" or os.clock()>deadline
  check(weather:GetAttribute("EventId")=="MeteorShower" and weather:GetAttribute("QueuedEventId")=="","queued event starts and clears")
  r=send({Action="EmergencyReset"})
  check(r and r.Kind=="Confirm","reset requires confirmation")
  if r and r.Kind=="Confirm" then
   r=send({Action="Confirm",Token=r.Token})
   task.wait(1)
   check(r and r.Success and weather:GetAttribute("Phase")=="Break" and not weather:GetAttribute("AutomaticPaused"),"reset returns to normal break")
   local remaining=weather:GetAttribute("BreakEndsAt")-workspace:GetServerTimeNow()
   check(weather:GetAttribute("Phase")=="Break" and remaining>295 and remaining<=300,"production break restarts after reset",remaining)
   check(weather:GetAttribute("TestMode")==false,"production test mode off")
  end
 end)
 if not ok then check(false,"smoke test error",err) end
 response:Disconnect();message:Disconnect();state:Disconnect()
 print("AK_P2_LIVE_DONE failures="..failures)
end)
