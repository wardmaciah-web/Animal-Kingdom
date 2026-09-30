-- Animal Kingdom Concrete Texture V1. Set CONCRETE_IMAGE_ID to a verified Roblox Image asset ID before running.
local CONCRETE_IMAGE_ID=72757684220187
local TEXTURE_NAME="AK_ConcreteTextureV1"
local TILE_STUDS=14
local Workspace=game:GetService("Workspace")
local ServerStorage=game:GetService("ServerStorage")
local MarketplaceService=game:GetService("MarketplaceService")
local MARKER="AnimalKingdomConcreteTextureV1"
local ROLLBACK_NAME="AnimalKingdomConcreteTextureV1Rollback"
if Workspace:GetAttribute(MARKER)==true then warn(MARKER.." already applied")return end
if type(CONCRETE_IMAGE_ID)~="number"or CONCRETE_IMAGE_ID<=0 or CONCRETE_IMAGE_ID%1~=0 then error("Set CONCRETE_IMAGE_ID to the verified underlying Roblox Image asset ID before running; no changes made")end
local okInfo,info=pcall(function()return MarketplaceService:GetProductInfo(CONCRETE_IMAGE_ID,Enum.InfoType.Asset)end)
if not okInfo or not info or info.AssetTypeId~=1 then error("CONCRETE_IMAGE_ID is not a verified Roblox Image asset (AssetTypeId 1); no changes made")end
local root=Workspace:FindFirstChild("AnimalKingdomConcreteGround")
if not root then error("Workspace.AnimalKingdomConcreteGround is missing")end
if ServerStorage:FindFirstChild(ROLLBACK_NAME)then error("Stale rollback folder exists; no changes made")end
local concreteParts={}
if root:IsA("BasePart")then table.insert(concreteParts,root)end
for _,d in ipairs(root:GetDescendants())do if d:IsA("BasePart")then table.insert(concreteParts,d)end end
if #concreteParts==0 then error("No concrete BaseParts found; no changes made")end
table.sort(concreteParts,function(a,b)return a:GetFullName()<b:GetFullName()end)
local sample=concreteParts[1]local sampleArea=0
for _,p in ipairs(concreteParts)do local area=p.Size.X*p.Size.Z;if area>sampleArea then sampleArea=area;sample=p end end
local colorsDiffer=false for _,p in ipairs(concreteParts)do if p.Color~=sample.Color then colorsDiffer=true break end end
local consistentColor=colorsDiffer and Color3.fromRGB(150,150,150)or sample.Color
local geometry={}
for _,p in ipairs(concreteParts)do geometry[p]={CFrame=p.CFrame,Size=p.Size,Anchored=p.Anchored,CanCollide=p.CanCollide,CanTouch=p.CanTouch,CanQuery=p.CanQuery,Orientation=p.Orientation}end
print("AK_CONCRETE_TEXTURE_PREFLIGHT parts="..#concreteParts.." imageId="..CONCRETE_IMAGE_ID.." tile="..TILE_STUDS)

local rollback=Instance.new("Folder")rollback.Name=ROLLBACK_NAME;rollback.Parent=ServerStorage
local changed={}local topTextures=0 local sideTextures=0
local function makeBackup(p)
 local entry=Instance.new("Folder")entry.Name="Concrete_"..string.format("%04d",#changed+1);entry.Parent=rollback
 local target=Instance.new("ObjectValue")target.Name="Target";target.Value=p;target.Parent=entry
 entry:SetAttribute("Color",p.Color)entry:SetAttribute("Material",p.Material.Name)
 for _,c in ipairs(p:GetChildren())do if c:IsA("Texture")and(c.Name==TEXTURE_NAME or c.Name:sub(1,18)=="AK_ConcreteTexture")then local clone=c:Clone();clone.Name="Backup_"..c.Name;clone.Parent=entry end end
 table.insert(changed,{part=p,entry=entry})
end
local function restore()
 for i=#changed,1,-1 do local p,e=changed[i].part,changed[i].entry;if p and p.Parent then p.Color=e:GetAttribute("Color")local materialName=e:GetAttribute("Material")local material=Enum.Material[materialName]if material then p.Material=material end for _,c in ipairs(p:GetChildren())do if c:IsA("Texture")and(c.Name==TEXTURE_NAME or c.Name:sub(1,18)=="AK_ConcreteTexture")then c:Destroy()end end for _,c in ipairs(e:GetChildren())do if c:IsA("Texture")then local clone=c:Clone();clone.Name=c.Name:gsub("^Backup_","");clone.Parent=p end end end end
 rollback:Destroy()Workspace:SetAttribute(MARKER,nil)
end
local success,mutationError=pcall(function()
 for _,p in ipairs(concreteParts)do
  makeBackup(p)p.Color=consistentColor;p.Material=Enum.Material.Concrete
  local keep=nil local duplicates={}
  for _,c in ipairs(p:GetChildren())do if c:IsA("Texture")and(c.Name==TEXTURE_NAME or c.Name:sub(1,18)=="AK_ConcreteTexture")then if not keep then keep=c else table.insert(duplicates,c)end end end
  for _,c in ipairs(duplicates)do c:Destroy()end
  if not keep then keep=Instance.new("Texture")keep.Name=TEXTURE_NAME;keep.Parent=p end
  keep.Name=TEXTURE_NAME;keep.Face=Enum.NormalId.Top;keep.Texture="rbxassetid://"..CONCRETE_IMAGE_ID;keep.StudsPerTileU=TILE_STUDS;keep.StudsPerTileV=TILE_STUDS;keep.Transparency=0;keep.Color3=Color3.new(1,1,1);topTextures=topTextures+1
 end
end)
if not success then restore()error("Concrete texture rollback: "..tostring(mutationError))end
local missing=0 local duplicates=0
for _,p in ipairs(concreteParts)do local found=0 for _,c in ipairs(p:GetChildren())do if c:IsA("Texture")and c.Name==TEXTURE_NAME then found=found+1;if c.Face~=Enum.NormalId.Top or c.Texture~="rbxassetid://"..CONCRETE_IMAGE_ID or c.StudsPerTileU~=TILE_STUDS or c.StudsPerTileV~=TILE_STUDS or c.Transparency~=0 or c.Color3~=Color3.new(1,1,1)then missing=missing+1 end end end if found==0 then missing=missing+1 elseif found>1 then duplicates=duplicates+found-1 end local g=geometry[p]if p.CFrame~=g.CFrame or p.Size~=g.Size or p.Anchored~=g.Anchored or p.CanCollide~=g.CanCollide or p.CanTouch~=g.CanTouch or p.CanQuery~=g.CanQuery or p.Orientation~=g.Orientation then restore()error("Concrete geometry changed unexpectedly: "..p:GetFullName())end end
if missing>0 or duplicates>0 then restore()error("Concrete texture validation failed missing="..missing.." duplicates="..duplicates)end
Workspace:SetAttribute(MARKER,true)
print("ANIMAL KINGDOM CONCRETE TEXTURE V1 COMPLETE")print("Concrete Parts found: "..#concreteParts)print("Concrete Parts textured: "..#concreteParts)print("Top textures: "..topTextures)print("Side textures: "..sideTextures)print("Texture Image ID: "..CONCRETE_IMAGE_ID)print("StudsPerTileU: "..TILE_STUDS)print("StudsPerTileV: "..TILE_STUDS)print("Concrete geometry changes: 0")print("Biome changes: 0")print("Tree changes: 0")print("Gameplay changes: 0")print("Script Source writes: 0")print("Missing texture applications: 0")print("Failures: 0")
