assert(game:GetService("RunService"):IsStudio(),"Studio only")
local RS=game.ReplicatedStorage
local Http=game.HttpService
local p=game.Players.LocalPlayer
local K=require(RS.Packages.Knit)
K.OnStart():await()
local controller=K.GetController("DataController")
local data=controller:GetPlayerData()
local defs=require(RS.Shared.Gameplay.Definitions.PetDefinitions)
local audit=RS:WaitForChild("MeadowLiveAudit")
assert(audit:GetAttribute("Mock")==true)
local results={}
local function save() p:SetAttribute("MeadowClientResults",Http:JSONEncode(results)) end
local function modelCheck(model,id)
 local def=defs[id]
 if not model or model:GetAttribute("PetTypeId")~=id or model:GetAttribute("Placeholder") then return false end
 local part=model:FindFirstChildWhichIsA("MeshPart",true)
 local sa=part and part:FindFirstChildWhichIsA("SurfaceAppearance")
 if not part or part.MeshId~=def.ModelAssets[1].MeshId or not sa then return false end
 for _,key in ipairs({"ColorMap","NormalMap","RoughnessMap","MetalnessMap"}) do
  if sa[key.."Content"].Uri~=def.ModelAssets[1][key] then return false end
 end
 return true
end
local function framing(view,model)
 local camera=view.CurrentCamera;if not camera or view.AbsoluteSize.Y<=0 then return false end
 local cf,size=model:GetBoundingBox()
 local ty=math.tan(math.rad(camera.FieldOfView/2));local tx=ty*view.AbsoluteSize.X/view.AbsoluteSize.Y
 for _,x in ipairs({-1,1}) do for _,y in ipairs({-1,1}) do for _,z in ipairs({-1,1}) do
  local point=camera.CFrame:PointToObjectSpace(cf:PointToWorldSpace(size*Vector3.new(x,y,z)/2))
  if point.Z>=0 or math.abs(point.X)/-point.Z>tx or math.abs(point.Y)/-point.Z>ty then return false end
 end end end
 return true
end
local snapshots=Instance.new("Folder");snapshots.Name="MeadowRevealSnapshots";snapshots.Parent=p.PlayerGui
RS.AnimalKingdomRemotes.GameplayFeedback.OnClientEvent:Connect(function(payload)
 local result=payload.Result
 if not payload.Success or type(result)~="table" or result.Kind~="Hatch" then return end
 local pet=result.Results[1].Pet
 if not defs[pet.PetId] or not defs[pet.PetId].IsMeadowPet then return end
 task.spawn(function()
  local row=results[pet.PetId] or {};results[pet.PetId]=row
  local deadline=os.clock()+7
  local screen=p.PlayerGui:WaitForChild("AnimalKingdomUI")
  local view,model
  repeat
   local reveal=screen:FindFirstChild("HatchReveal")
   if reveal then for _,v in ipairs(reveal:GetDescendants()) do
    if v:IsA("ViewportFrame") then local w=v:FindFirstChildWhichIsA("WorldModel");local m=w and w:FindFirstChildWhichIsA("Model");if m and m:GetAttribute("PetTypeId")==pet.PetId then view=v;model=m;break end end
   end end
   if not model then task.wait(.05) end
  until model or os.clock()>=deadline
  row.reveal=modelCheck(model,pet.PetId)
  row.framing=model and framing(view,model) or false
  row.name=false;row.rarity=false
  local reveal=screen:FindFirstChild("HatchReveal")
  if reveal then for _,v in ipairs(reveal:GetDescendants()) do if v:IsA("TextLabel") then
   row.name=row.name or string.find(v.Text,defs[pet.PetId].DisplayName,1,true)~=nil
   row.rarity=row.rarity or string.find(v.Text,defs[pet.PetId].Rarity,1,true)~=nil
  end end end
  row.textures=true
  for _,asset in ipairs(select(3,require(RS.Shared.Gameplay.PetModelValidation).Resolve(pet.PetId)) or {}) do
   if game.ContentProvider:GetAssetFetchStatus(asset)~=Enum.AssetFetchStatus.Success then row.textures=false end
  end
  if model and not snapshots:FindFirstChild(pet.PetId) then local clone=model:Clone();clone.Name=pet.PetId;clone.Parent=snapshots end
  save()
 end)
end)
audit:GetAttributeChangedSignal("DisplayCheck"):Connect(function()
 local id=audit:GetAttribute("DisplayCheck")
 task.wait(.4)
 local row=results[id] or {};results[id]=row
 local followers=workspace:FindFirstChild("LocalPetFollowers")
 row.equipped=false
 if followers then for _,model in ipairs(followers:GetChildren()) do if modelCheck(model,id) then row.equipped=true end end end
 local f=workspace:FindFirstChild("Sanctuaries")
 local d=f and f:FindFirstChild(tostring(p.UserId))
 d=d and d:FindFirstChild("DisplayedPets")
 row.sanctuary=false
 if d then for _,model in ipairs(d:GetChildren()) do if modelCheck(model,id) then row.sanctuary=true end end end
 save()
end)
p:SetAttribute("MeadowObserverReady",true)
