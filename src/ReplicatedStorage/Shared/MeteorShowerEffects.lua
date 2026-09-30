-- Client-rendered, server-clock meteor choreography. Never excavates authored floors.
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Effects = {}
local STEP = 0.48
local BIG_INTERVAL = 14
local FIRST_BIG = 5
local BIG_FLIGHT = 2.25
local IMPACT_LIFETIME = 30
local MAX_METEORS = 18
local BIOMES = {"Meadow", "Forest", "Jungle", "Desert", "Snow", "Volcano", "Ocean", "AncientRuins", "MagicalForest", "Sky", "Prehistoric", "Mythical"}

local function part(parent, name, size, cf, tint, material, alpha)
 local p = Instance.new("Part")
 p.Name = name; p.Size = size; p.CFrame = cf; p.Color = tint
 p.Material = material or Enum.Material.Neon; p.Transparency = alpha or 0
 p.Anchored = true; p.CanCollide = false; p.CanTouch = false; p.CanQuery = false; p.CastShadow = false
 p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
 p.Parent = parent
 return p
end

local function emitter(parent, name, tint, size, life, speed)
 local e = Instance.new("ParticleEmitter")
 e.Name = name; e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
 e.Color = ColorSequence.new(tint); e.LightEmission = 0.85; e.LightInfluence = 0
 e.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, size), NumberSequenceKeypoint.new(1, 0)})
 e.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1)})
 e.Lifetime = NumberRange.new(life * 0.65, life); e.Speed = NumberRange.new(speed * 0.5, speed)
 e.SpreadAngle = Vector2.new(180, 180); e.Rate = 0; e.Parent = parent
 return e
end

function Effects.Start(runtime, startedAt, isCurrent, context)
 context = context or {}
 local quality = context.qualityScale or 1
 local intensity = context.intensity or 1
 local audio = context.audio
 local mode = context.meteorMode or "MeteorShower"
 local step = STEP * (mode == "Chaos" and 3 or mode == "AdminAbuse" and 1.4 or 1)
 local bigInterval = mode == "Chaos" and 28 or BIG_INTERVAL
 local maxMeteors = math.max(5, math.floor(MAX_METEORS * quality))
 local folder = Instance.new("Folder"); folder.Name = "MeteorShowerEffects"; folder.Parent = runtime
 folder:SetAttribute("ImpactLifetime", IMPACT_LIFETIME); folder:SetAttribute("LargeStrikeInterval", bigInterval); folder:SetAttribute("MeteorLimit", maxMeteors)
 local ground = workspace:FindFirstChild("AnimalKingdomConcreteGround") or workspace:FindFirstChild("GrassFloor")
 if ground and not ground:IsA("BasePart") then ground = nil end
 local center = ground and ground.Position or Vector3.new(-338, 8, 248)
 local extent = ground and ground.Size * 0.5 or Vector3.new(650, 0, 650)
 local seed = math.floor(startedAt * 1000) % 2147483647
 local flights, impacts, flashes = {}, {}, {}
 local live, connection, destroying = true, nil, nil
 local lastSmall, lastBig = -1, -1
 local function randomFor(index, salt)
  return Random.new((seed + index * 104729 + salt) % 2147483647)
 end
 local function active() return live and runtime.Parent ~= nil and isCurrent() end
 local function cleanup()
  if not live then return end
  live = false
  if connection then connection:Disconnect() end
  if destroying then destroying:Disconnect() end
  table.clear(flights); table.clear(impacts); table.clear(flashes)
  folder:Destroy()
 end
 destroying = runtime.Destroying:Connect(cleanup)

 local function launch(index, big, start, finish, launchAt, duration, size)
  if #flights >= maxMeteors then return end
  local meteor = part(folder, big and "LargeMeteor" or "Meteor", Vector3.one * size,
   CFrame.lookAt(start, finish), Color3.fromRGB(255, 158, 65), Enum.Material.Neon)
  meteor.Shape = Enum.PartType.Ball
  meteor:SetAttribute("LaunchAt", launchAt); meteor:SetAttribute("StrikeIndex", index)
  meteor:SetAttribute("StartPosition", start); meteor:SetAttribute("TargetPosition", finish)
  local a = Instance.new("Attachment"); a.Position = Vector3.new(-size * 0.35, 0, 0); a.Parent = meteor
  local b = Instance.new("Attachment"); b.Position = Vector3.new(size * 0.35, 0, 0); b.Parent = meteor
  local trail = Instance.new("Trail"); trail.Name = "FireTrail"; trail.Attachment0 = a; trail.Attachment1 = b
  trail.Color = ColorSequence.new(Color3.fromRGB(255, 231, 166), Color3.fromRGB(255, 71, 26))
  trail.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.05), NumberSequenceKeypoint.new(1, 1)})
  trail.Lifetime = big and 0.9 or 0.55; trail.MinLength = 0.1; trail.LightEmission = 1; trail.FaceCamera = true; trail.Parent = meteor
  local fire = emitter(meteor, "FireSparks", Color3.fromRGB(255, 131, 44), big and 5 or 1.5, 0.6, big and 12 or 4)
  fire.Rate = (big and 42 or 8) * quality * intensity
  local smoke = emitter(meteor, "SmokeTrail", Color3.fromRGB(97, 83, 79), big and 6 or 2, big and 1.3 or 0.7, 1)
  smoke.Texture = "rbxasset://textures/particles/smoke_main.dds"; smoke.LightEmission = 0.08
  smoke.Rate = (big and 14 or 3) * quality * intensity
  -- Each visible flight requests an appropriately sized cue; the central mixer
  -- bounds simultaneous voices without making audio depend on graphics quality.
  if audio then audio:PlayCue(big and "MeteorFlybyLarge" or "MeteorFlybySmall", meteor) end
  if big then
   local rock = part(meteor, "RockCore", Vector3.one * (size * 0.74), meteor.CFrame, Color3.fromRGB(59, 39, 31), Enum.Material.Slate)
   rock.Shape = Enum.PartType.Ball
   local light = Instance.new("PointLight"); light.Color = Color3.fromRGB(255, 133, 63); light.Range = 45; light.Brightness = 2; light.Parent = meteor
  end
  table.insert(flights, {part = meteor, start = start, finish = finish, launchAt = launchAt, duration = duration, big = big})
 end

 local function impactTarget(index)
  local random = randomFor(index, 9187)
  local surfaces = {}
  if ground then table.insert(surfaces, ground) end
  for _,id in ipairs(BIOMES) do
   local model = workspace:FindFirstChild(id)
   local floor = model and model:FindFirstChild(id .. "Floor")
   if floor and floor:IsA("BasePart") then table.insert(surfaces, floor) end
  end
  if #surfaces == 0 then table.insert(surfaces, workspace.Terrain) end
  local query = RaycastParams.new(); query.FilterType = Enum.RaycastFilterType.Include; query.FilterDescendantsInstances = surfaces; query.RespectCanCollide = true
  local clear = RaycastParams.new(); clear.FilterType = Enum.RaycastFilterType.Exclude; clear.RespectCanCollide = true
  local exclude = {runtime}
  for _,player in ipairs(Players:GetPlayers()) do if player.Character then table.insert(exclude, player.Character) end end
  clear.FilterDescendantsInstances = exclude
  for _ = 1, 12 do
   local pos = center + Vector3.new(random:NextNumber(-math.max(0, extent.X - 50), math.max(0, extent.X - 50)), 1200, random:NextNumber(-math.max(0, extent.Z - 50), math.max(0, extent.Z - 50)))
   local hit = workspace:Raycast(pos, Vector3.new(0, -2400, 0), query)
   if hit and hit.Normal.Y > 0.95 then
    local open = true
    -- Leave buildings/tree trunks alone and keep every crater rim on real support.
    for _,offset in ipairs({Vector3.zero, Vector3.new(16, 0, 0), Vector3.new(-16, 0, 0), Vector3.new(0, 0, 16), Vector3.new(0, 0, -16)}) do
     local down = workspace:Raycast(hit.Position + offset + Vector3.new(0, 150, 0), Vector3.new(0, -154, 0), clear)
     if not down or not table.find(surfaces, down.Instance) or math.abs(down.Position.Y - hit.Position.Y) > 1 then open = false; break end
    end
    if open then return hit.Position end
   end
  end
  return nil -- skip a blocked strike rather than damage a structure
 end

 local function makeImpact(index, position, impactAt, now)
  if now >= impactAt + IMPACT_LIFETIME then return end
  local random = randomFor(index, 4701)
  local model = Instance.new("Model"); model.Name = "MeteorImpact"
  model:SetAttribute("ImpactAt", impactAt); model:SetAttribute("ExpiresAt", impactAt + IMPACT_LIFETIME)
  model:SetAttribute("StrikeIndex", index); model:SetAttribute("WorldPosition", position); model.Parent = folder
  local surface = position.Y + 0.045
  local scorch = part(model, "ScorchedGround", Vector3.new(0.08, 28, 28), CFrame.new(position.X, surface, position.Z) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(31, 28, 30), Enum.Material.Slate, 0.1)
  scorch.Shape = Enum.PartType.Cylinder
  local molten = part(model, "CoolingImpact", Vector3.new(0.09, 12, 12), CFrame.new(position.X, surface + 0.06, position.Z) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(255, 99, 27), Enum.Material.Neon, 0.1)
  molten.Shape = Enum.PartType.Cylinder
  local rubbleCount = quality < 0.5 and 6 or 12
  for i = 1, rubbleCount do
   local angle = i / rubbleCount * math.pi * 2
   local radius = random:NextNumber(11.7, 13.2)
   local height = random:NextNumber(1.2, 2.7)
   part(model, "CraterRubble", Vector3.new(random:NextNumber(3, 5), height, random:NextNumber(2, 4)), CFrame.new(position + Vector3.new(math.cos(angle) * radius, height * 0.5 + 0.04, math.sin(angle) * radius)) * CFrame.Angles(0, -angle, 0), Color3.fromRGB(70, 59, 54), Enum.Material.Slate)
   if i % 2 == 0 then
    local length = random:NextNumber(5, 9)
    part(model, "GroundCrack", Vector3.new(length, 0.065, 0.32), CFrame.new(position + Vector3.new(math.cos(angle) * 7, 0.13, math.sin(angle) * 7)) * CFrame.Angles(0, -angle, 0), Color3.fromRGB(246, 102, 32), Enum.Material.Neon, 0.1)
   end
  end
  local smoke = emitter(scorch, "ImpactEmbers", Color3.fromRGB(255, 139, 60), 0.55, 2, 7)
  smoke.Acceleration = Vector3.new(0, 6, 0); smoke.Rate = 12 * quality * intensity
  if now - impactAt < 0.6 then
   local burst = part(folder, "ImpactFlash", Vector3.one * 7, CFrame.new(position + Vector3.new(0, 2, 0)), Color3.fromRGB(255, 187, 80), Enum.Material.Neon, 0.2)
   burst.Shape = Enum.PartType.Ball
   table.insert(flashes, {part = burst, at = now})
   smoke:Emit(math.floor(65 * quality * intensity))
   if audio then
    audio:PlayCue("MeteorImpactLarge", position)
    audio:PlayCue("FireBurst", position)
   end
   local ring = part(folder, "ImpactShockwave", Vector3.new(0.08, 4, 4), CFrame.new(position + Vector3.new(0, 0.18, 0)) * CFrame.Angles(0, 0, math.pi/2), Color3.fromRGB(255, 195, 120), Enum.Material.Neon, 0.4)
   ring.Shape = Enum.PartType.Cylinder
   table.insert(flashes, {part = ring, at = now, ring = true})
   local fire = emitter(scorch, "ImpactFire", Color3.fromRGB(255, 172, 58), 6, 0.7, 20)
   fire.Texture = "rbxasset://textures/particles/fire_main.dds"; fire:Emit(math.floor(25 * quality * intensity))
   local dust = emitter(scorch, "ImpactDust", Color3.fromRGB(167, 139, 112), 3, 1.2, 34)
   dust.Texture = "rbxasset://textures/particles/smoke_main.dds"; dust.Acceleration = Vector3.new(0, -12, 0); dust:Emit(math.floor(35 * quality * intensity))
  end
  local parts = {}
  for _,p in ipairs(model:GetChildren()) do if p:IsA("BasePart") then table.insert(parts, {part = p, alpha = p.Transparency}) end end
  table.insert(impacts, {model = model, at = impactAt, parts = parts, smoke = smoke, molten = molten})
 end

 local function small(index)
  local random = randomFor(index, 1201)
  local at = startedAt + index * step
  for lane = 1, (quality < 0.5 and 1 or 2) do
   local aim = center + Vector3.new(random:NextNumber(-extent.X * 0.8, extent.X * 0.8), random:NextNumber(110, 280), random:NextNumber(-extent.Z * 0.8, extent.Z * 0.8))
   local direction = Vector3.new(random:NextNumber(430, 850), -random:NextNumber(65, 150), random:NextNumber(-260, 260))
   launch(index * 2 + lane, false, aim - direction * 0.5, aim + direction * 0.5, at, random:NextNumber(0.8, 1.3), random:NextNumber(3.5, 7))
  end
 end
 local function big(index, now)
  local at = startedAt + FIRST_BIG + index * bigInterval
  local position = impactTarget(index)
  if not position then return end
  local impactAt = at + BIG_FLIGHT
  if now < impactAt then
   local random = randomFor(index, 8039)
   local start = position + Vector3.new(-random:NextNumber(230, 420), 570, random:NextNumber(-170, 170))
   launch(index, true, start, position + Vector3.new(0, 5, 0), at, BIG_FLIGHT, 13)
  else makeImpact(index, position, impactAt, now) end
 end
 local accumulator = 0
 local function update()
  if not active() then cleanup(); return end
  local now = workspace:GetServerTimeNow()
  local elapsed = math.max(0, now - startedAt)
  local smallIndex = math.floor(elapsed / step)
  if smallIndex > lastSmall then
   -- Reconstruct only still-visible flight slots after a late join/frame stall.
   for index = math.max(lastSmall + 1, smallIndex - 2), smallIndex do if quality >= 0.7 or index % (quality < 0.5 and 3 or 2) == 0 then small(index) end end
   lastSmall = smallIndex
  end
  local bigIndex = math.floor((elapsed - FIRST_BIG) / bigInterval)
  if bigIndex > lastBig then
   for index = math.max(lastBig + 1, math.ceil((elapsed - FIRST_BIG - BIG_FLIGHT - IMPACT_LIFETIME) / bigInterval), 0), bigIndex do big(index, now) end
   lastBig = bigIndex
  end
  for i = #flights, 1, -1 do
   local flight = flights[i]
   local alpha = math.clamp((now - flight.launchAt) / flight.duration, 0, 1)
   if alpha >= 1 then
    if flight.big then makeImpact(flight.part:GetAttribute("StrikeIndex"), flight.finish - Vector3.new(0, 5, 0), flight.launchAt + flight.duration, now) end
    flight.part:Destroy(); table.remove(flights, i)
   else
    local p = flight.start:Lerp(flight.finish, alpha)
    flight.part.CFrame = CFrame.lookAt(p, flight.finish)
    local core = flight.part:FindFirstChild("RockCore")
    if core then core.CFrame = flight.part.CFrame * CFrame.Angles(alpha * 8, alpha * 6, alpha * 3) end
   end
  end
  for i = #impacts, 1, -1 do
   local impact = impacts[i]; local age = now - impact.at
   if age >= IMPACT_LIFETIME then impact.model:Destroy(); table.remove(impacts, i)
   else
    local fade = math.clamp((age - 26) / 4, 0, 1)
    for _,entry in ipairs(impact.parts) do entry.part.Transparency = entry.alpha + (1 - entry.alpha) * fade end
    impact.molten.Transparency = math.max(impact.molten.Transparency, math.clamp(age / 12, 0.1, 1))
    impact.smoke.Enabled = age < 9
   end
  end
  for i = #flashes, 1, -1 do
   local flash = flashes[i]; local alpha = (now - flash.at) / 0.65
   if alpha >= 1 then flash.part:Destroy(); table.remove(flashes, i)
   else
    flash.part.Size = flash.ring and Vector3.new(0.08, 4 + 75 * alpha, 4 + 75 * alpha) or Vector3.one * (7 + 36 * alpha)
    flash.part.Transparency = (flash.ring and 0.4 or 0.2) + alpha * (flash.ring and 0.6 or 0.8)
   end
  end
 end
 update()
 if live then
  connection = RunService.Heartbeat:Connect(function(dt) accumulator += dt; if accumulator >= 1/30 then accumulator = 0; update() end end)
 end
 return cleanup
end

return Effects
