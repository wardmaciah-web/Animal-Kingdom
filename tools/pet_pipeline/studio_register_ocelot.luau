-- Restore the verified free Ocelot production template from its durable review import.
-- Run in the known test place in Edit mode. Does not release a biome or publish.
assert(game:GetService("RunService"):IsStudio() and not game:GetService("RunService"):IsRunning(), "Edit mode only")
assert(game.PlaceId == 132313449035787 and game.GameId == 10764288431, "Wrong place")
local RS = game:GetService("ReplicatedStorage")
local assets = assert(RS:FindFirstChild("PetAssets"), "PetAssets missing")
local expected = { ["rbxassetid://86956296653033"]=true, ["rbxassetid://83705741042121"]=true }
local function verify(model)
 local count, seen = 0, {}
 for _, part in model:GetDescendants() do
  assert(not part:IsA("LuaSourceContainer"), "Unexpected template script")
  if part:IsA("MeshPart") then
   assert(expected[part.MeshId] and not seen[part.MeshId], "Unexpected mesh")
   assert(part.TextureID == "rbxassetid://89955741043720", "Texture mismatch")
   count += 1; seen[part.MeshId] = true
  end
 end
 assert(count == 2, "Expected body and fur")
end
local model = assets:FindFirstChild("JungleOcelot")
if model then verify(model) else
 local review = assert(workspace:FindFirstChild("AK_JunglePetReview"))
 local source = assert(review.PlushStylizedReview:FindFirstChild("JungleOcelot_D_FreeReview"))
 verify(source)
 model = source:Clone(); model.Name = "JungleOcelot"
 local bounds, size = model:GetBoundingBox()
 model:PivotTo(model:GetPivot() + Vector3.new(0,size.Y/2,0) - bounds.Position)
 for _, part in model:GetDescendants() do
  if part:IsA("BasePart") then
   part.Anchored=true; part.CanCollide=false; part.CanTouch=false; part.CanQuery=false
  end
 end
 model.PrimaryPart = model:FindFirstChildWhichIsA("BasePart",true)
 model:SetAttribute("PetTypeId","JungleOcelot")
 model:SetAttribute("ProductionRun","ocelot-d-reproduction-001")
 model:SetAttribute("OriginalSpecies","Ocelot")
 model:SetAttribute("CanonicalPet",true)
 model.Parent = assets
end
verify(model)
return {path=model:GetFullName(),meshes=2,biome_released=false,published=false}
