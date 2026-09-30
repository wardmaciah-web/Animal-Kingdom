-- Run in a fresh Studio CLIENT command bar. Changes only local visual test state.
assert(game:GetService("RunService"):IsStudio() and game:GetService("RunService"):IsClient(), "Studio client required")
task.spawn(function()
 local state = game:GetService("ReplicatedStorage"):WaitForChild("WeatherState")
 local players, lighting, soundService = game:GetService("Players"), game:GetService("Lighting"), game:GetService("SoundService")
 local ids = {"SunnySkies","RainyDay","Thunderstorm","Snowfall","Foggy","Windy","Heatwave","Aurora","BloodMoon","MeteorShower","SpiritNight","Rainbow","Chaos","Inverted","Nightmare","Void","Golden","AdminAbuse"}
 local player = players.LocalPlayer
 local camera = workspace.CurrentCamera
 local savedCamera, savedType = camera.CFrame, camera.CameraType
 local savedState = state:GetAttributes()
 local originalQuality = player:GetAttribute("WeatherVFXQuality")
 local character = player.Character or player.CharacterAdded:Wait()
 local root, humanoid = character:WaitForChild("HumanoidRootPart"), character:WaitForChild("Humanoid")
 local savedPivot = character:GetPivot()
 local failures, assertions = 0, 0
 local function check(ok, message)
  assertions += 1
  if not ok then failures += 1 end
  print("AK_POLISH_" .. (ok and "PASS " or "FAIL ") .. message)
 end
 local function phase(id)
  local now = workspace:GetServerTimeNow()
  state:SetAttribute("Phase", "Break")
  state:SetAttribute("EventId", id or "")
  state:SetAttribute("StartedAt", now)
  state:SetAttribute("EndsAt", now + (id and 420 or 300))
  state:SetAttribute("Phase", id and "Event" or "Break")
 end
 local function stats(runtime)
  local parts, emitters, rate, beams, sounds = 0, 0, 0, 0, 0
  local safe = true
  for _, obj in ipairs(runtime:GetDescendants()) do
   if obj:IsA("BasePart") then parts += 1; safe = safe and obj.Anchored and not obj.CanCollide and not obj.CanTouch and not obj.CanQuery end
   if obj:IsA("ParticleEmitter") then emitters += 1; if obj.Enabled then rate += obj.Rate end end
   if obj:IsA("Beam") then beams += 1 end
   if obj:IsA("Sound") then sounds += 1 end
  end
  local audio = soundService:FindFirstChild("AK_WeatherAudio")
  if audio then for _, obj in ipairs(audio:GetDescendants()) do if obj:IsA("Sound") then sounds += 1 end end end
  return {parts=parts, emitters=emitters, rate=rate, beams=beams, sounds=sounds, safe=safe}
 end
 local ok, err = xpcall(function()
  phase(nil); task.wait(2.4)
  local initial = {Brightness=lighting.Brightness, ClockTime=lighting.ClockTime, FogEnd=lighting.FogEnd, Wind=workspace.GlobalWind}
  player:SetAttribute("WeatherVFXQuality", "High")
  camera.CameraType = Enum.CameraType.Scriptable
  -- A known clear Town-to-plot corridor, used for real Humanoid walking checks.
  local routeA, routeB = Vector3.new(-470, 13, 395), Vector3.new(-470,13,365)
  for _, id in ipairs(ids) do
   character:PivotTo(CFrame.new(routeA))
   phase(id)
   task.wait(2.4)
   local runtime = workspace:FindFirstChild("WeatherWorldEffects")
   check(runtime ~= nil and runtime:GetAttribute("EventId") == id, id .. " starts")
   assert(runtime, "Missing runtime for " .. id)
   local anchors = {}
   for _, obj in ipairs(runtime:GetDescendants()) do
    if obj:IsA("BasePart") and obj:GetAttribute("FixedWorldPosition") then anchors[obj] = obj.Position end
   end
   local eye = Vector3.new(-430, 25, 385)
   for quarter = 0, 4 do
    camera.CFrame = CFrame.new(eye) * CFrame.Angles(0, quarter * math.pi/2, 0)
    task.wait(0.12)
   end
   local fixed = true
   for obj, p in pairs(anchors) do fixed = fixed and obj.Parent ~= nil and (obj.Position-p).Magnitude < 0.01 end
   check(fixed, id .. " world anchors unchanged after 360-degree camera rotation")
   local aim = Vector3.new(-470, 26, -300)
   if id == "BloodMoon" then aim = Vector3.new(-6338,8008,-23752) end
   if id == "Aurora" then aim = Vector3.new(-500,1050,-1700) end
   if id == "Rainbow" or id == "AdminAbuse" then aim = Vector3.new(-500,600,-2200) end
   if id == "Void" then aim = Vector3.new(-2700,1300,-7000) end
   if id == "MeteorShower" then aim = Vector3.new(-338,180,248) end
   camera.CFrame = CFrame.lookAt(eye, aim)
   print("AK_POLISH_CAPTURE " .. id)
   local beforeWalk = root.Position
   humanoid:MoveTo(routeB)
   task.wait(2.5)
   local traveled = (root.Position-beforeWalk).Magnitude
   check(traveled > 8 and root.Position.Y > 5 and humanoid.Health > 0, id .. " real player walking remains safe (" .. math.floor(traveled) .. " studs)")
   task.wait(2.2)
   local report = stats(runtime)
   check(report.safe, id .. " all cosmetic parts anchored and noninteractive")
   check(report.parts <= 320 and report.emitters <= 100 and report.rate <= 1600 and report.sounds <= 11, id .. " bounded object/particle/audio budgets")
   print("AK_POLISH_STATS " .. id .. " " .. game:GetService("HttpService"):JSONEncode(report))
   phase(nil)
   task.wait(2.35)
   check(workspace:FindFirstChild("WeatherWorldEffects") == nil, id .. " world cleanup")
   check(soundService:FindFirstChild("AK_WeatherAudio") == nil, id .. " audio cleanup after fade")
   check(math.abs(lighting.ClockTime-initial.ClockTime)<0.05 and math.abs(lighting.FogEnd-initial.FogEnd)<1, id .. " restores baseline Lighting")
   check((workspace.GlobalWind-initial.Wind).Magnitude<0.05, id .. " restores baseline wind")
  end
  -- All18 effects at Low, no separate/drifting gameplay timer or audio muting.
  player:SetAttribute("WeatherVFXQuality", "Low")
  for _, id in ipairs(ids) do
   phase(id); task.wait(0.35)
   local runtime = workspace:FindFirstChild("WeatherWorldEffects")
   check(runtime ~= nil and runtime:GetAttribute("QualityScale") == 0.35, id .. " Low graphics starts")
   phase(nil); task.wait(0.1)
  end
  task.wait(2.4)
  check(workspace:FindFirstChild("WeatherWorldEffects") == nil and soundService:FindFirstChild("AK_WeatherAudio") == nil, "rapid Low-quality switching leaves no world or audio objects")
 end, debug.traceback)
 if not ok then check(false, tostring(err)) end
 phase(nil)
 task.wait(2.5)
 player:SetAttribute("WeatherVFXQuality", originalQuality)
 character:PivotTo(savedPivot)
 camera.CameraType = savedType; camera.CFrame = savedCamera
 for key,value in pairs(savedState) do state:SetAttribute(key,value) end
 print("AK_POLISH_DONE assertions=" .. assertions .. " failures=" .. failures)
end)
