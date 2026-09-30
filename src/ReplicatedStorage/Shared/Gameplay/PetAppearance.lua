local Resolver=require(script.Parent.AssetResolver)
local Pets=require(script.Parent.Definitions.PetDefinitions)
local Rarities=require(script.Parent.Definitions.RarityDefinitions)
local Variants=require(script.Parent.Definitions.VariantDefinitions)
local Models=require(script.Parent.PetModelResolver)
local Geometry=require(script.Parent.PetVisualGeometry)
local Weight=require(script.Parent.PetWeight)
local Labels=require(script.Parent.PetLabel)
local A={}
function A.Create(pet,context)
 if type(pet)~="table" then return nil,"Pet unavailable" end
 local def=Pets[pet.PetId];if not def then return nil end
 local rarity=Rarities[def.Rarity];local mutation=Variants.Mutations[pet.Mutation]
 local color=(mutation and mutation.Color) or (rarity and rarity.Color) or Color3.fromRGB(120,170,100)
 local variant=pet.Prismatic and "Prismatic " or pet.Shiny and "Shiny " or ""
 local model,issue=Models.Clone(def.PetId)
 if not model then return nil,issue end
 if not Geometry.Normalize(model,def,context) then model:Destroy();return nil,"Pet model bounds unavailable" end
 local weightScale=Weight.Scale(pet,def)
 model:ScaleTo(model:GetScale()*weightScale)
 model:SetAttribute('Weight',pet.Weight or def.BaseWeight)
 model:SetAttribute('WeightVisualScale',weightScale)
 model:SetAttribute('CoinsPerSecond',pet.CoinsPerSecond or 0)
 model:SetAttribute('OwnedPetInstanceId',pet.UID)
 model:SetAttribute("VisualContext",context or "Follower")
 if pet.Prismatic or (pet.Mutation and pet.Mutation~="Normal") then
  local attachment=Instance.new("Attachment");attachment.Name="VariantEffect";attachment.Parent=model.PrimaryPart
  local spark=Instance.new("ParticleEmitter");spark.Color=ColorSequence.new(color);spark.Rate=2;spark.Lifetime=NumberRange.new(.4,.7)
  spark.Speed=NumberRange.new(.3,.6);spark.Size=NumberSequence.new(.12);spark.LightEmission=.5;spark.Parent=attachment
 end
 A.ApplyCosmetic(model, type(pet.Cosmetic) == "string" and pet.Cosmetic or nil)
 Labels.Attach(model,pet,context)
 return model
end
function A.ApplyCosmetic(model, cosmeticId)
 if type(cosmeticId) ~= "string" or cosmeticId == "" then return end
 local root = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
 if not root then return end
 local bounds = Geometry.Measure(model,root.CFrame)
 if not bounds then return end
 local top = bounds.Max.Y
 local center = Vector3.new(bounds.Center.X,0,bounds.Center.Z)
 local cosmeticScale = math.clamp(math.max(bounds.Size.X,bounds.Size.Y,bounds.Size.Z)/2.8,.4,2)
 local function solid(name, size, color, offset, shape, material)
  local part = Instance.new("Part")
  part.Name = name
  part.Size = size*cosmeticScale
  part.Color = color
  part.Shape = shape or Enum.PartType.Ball
  part.Material = material or Enum.Material.SmoothPlastic
  part.Anchored = true
  part.CanCollide = false
  part.CanTouch = false
  part.CanQuery = false
  part.CFrame = root.CFrame * CFrame.new(center+Vector3.new(offset.X*cosmeticScale,top+(offset.Y-top)*cosmeticScale,offset.Z*cosmeticScale))
  part:SetAttribute("PetCosmetic",true)
  part.Parent = model
  return part
 end
 local function aura(color, rate)
  local attachment = Instance.new("Attachment")
  attachment.Name = "GardenCosmetic"
  attachment.Position = center+Vector3.new(0, top, 0)
  attachment.Parent = root
  local emitter = Instance.new("ParticleEmitter")
  emitter.Name = "CosmeticSparkles"
  emitter.Color = ColorSequence.new(color)
  emitter.Rate = rate or 4
  emitter.Lifetime = NumberRange.new(0.5, 1)
  emitter.Speed = NumberRange.new(0.6, 1.2)
  emitter.Size = NumberSequence.new(0.14)
  emitter.LightEmission = 0.4
  emitter.Parent = attachment
 end
 if cosmeticId == "FlowerCrown" then
  for i = 0, 5 do
   local angle = math.pi * 2 * i / 6
   local color = i % 2 == 0 and Color3.fromRGB(255, 150, 200) or Color3.fromRGB(255, 255, 255)
   solid("Petal" .. i, Vector3.new(0.32, 0.32, 0.32), color, Vector3.new(math.cos(angle) * 0.85, top + 0.35, math.sin(angle) * 0.85))
  end
 elseif cosmeticId == "StrawberryHat" then
  solid("BerryHat", Vector3.new(1.1, 0.9, 1.1), Color3.fromRGB(235, 60, 70), Vector3.new(0, top + 0.7, 0))
  solid("BerryLeaf", Vector3.new(0.5, 0.25, 0.5), Color3.fromRGB(80, 190, 90), Vector3.new(0, top + 1.2, 0))
 elseif cosmeticId == "LeafyAura" then
  aura(Color3.fromRGB(110, 220, 130), 5)
 elseif cosmeticId == "GoldenBloom" then
  solid("BloomCrown", Vector3.new(1.2, 0.3, 1.2), Color3.fromRGB(244, 188, 70), Vector3.new(0, top + 0.45, 0), Enum.PartType.Cylinder, Enum.Material.Neon)
  aura(Color3.fromRGB(255, 215, 120), 6)
 elseif cosmeticId == "RainbowSprout" then
  local rainbow = ColorSequence.new({
   ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 120, 150)),
   ColorSequenceKeypoint.new(0.5, Color3.fromRGB(120, 220, 255)),
   ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 255, 170)),
  })
  local attachment = Instance.new("Attachment")
  attachment.Name = "GardenCosmetic"
  attachment.Position = center+Vector3.new(0, top, 0)
  attachment.Parent = root
  local emitter = Instance.new("ParticleEmitter")
  emitter.Name = "CosmeticSparkles"
  emitter.Color = rainbow
  emitter.Rate = 7
  emitter.Lifetime = NumberRange.new(0.5, 1)
  emitter.Speed = NumberRange.new(0.8, 1.4)
  emitter.Size = NumberSequence.new(0.16)
  emitter.LightEmission = 0.6
  emitter.Parent = attachment
 end
end
return A
