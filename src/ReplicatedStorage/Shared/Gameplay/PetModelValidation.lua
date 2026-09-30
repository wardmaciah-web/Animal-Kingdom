-- The existing pet catalog owns identity and template provenance.
local RS=game:GetService("ReplicatedStorage")
local Pets=require(script.Parent.Definitions.PetDefinitions)
local M={}
local function asset(value) return type(value)=="string" and value:match("^rbxassetid://[1-9]%d*$")~=nil end
function M.Resolve(id)
 local def=Pets[id]
 if not def or not def.IsMeadowPet then return nil,"Not a canonical Meadow species" end
 local node=RS
 for segment in string.gmatch(def.RealModelTemplate,"[^.]+") do node=node:FindFirstChild(segment);if not node then return nil,def.DisplayName..": imported model unavailable" end end
 if not node:IsA("Model") or node:GetAttribute("Placeholder") then return nil,def.DisplayName..": invalid model template" end
 local parts={}
 for _,p in ipairs(node:GetDescendants()) do
  if p:IsA("LuaSourceContainer") then return nil,def.DisplayName..": unexpected template script" end
  if p:IsA("BasePart") then
   if not p:IsA("MeshPart") or p.Transparency>=1 then return nil,def.DisplayName..": real visible mesh required" end
   table.insert(parts,p)
  end
 end
 if #parts==0 or #parts~=#def.ModelAssets then return nil,def.DisplayName..": mesh count mismatch" end
 table.sort(parts,function(a,b)return a.MeshId<b.MeshId end)
 local assets,seen={},{}
 local function add(value)
  if not asset(value) then return false end
  if not seen[value] then seen[value]=true;table.insert(assets,value) end
  return true
 end
 for i,p in ipairs(parts) do
  local expected=def.ModelAssets[i]
  if p.MeshId~=expected.MeshId or not add(p.MeshId) then return nil,def.DisplayName..": mesh binding mismatch" end
  local surface=p:FindFirstChildWhichIsA("SurfaceAppearance")
  if not surface then return nil,def.DisplayName..": SurfaceAppearance missing" end
  if p.TextureID~=expected.ColorMap then return nil,def.DisplayName..": albedo texture binding mismatch" end
  for _,property in ipairs({"ColorMap","NormalMap","RoughnessMap","MetalnessMap"}) do
   local target=expected[property]
   if not add(target) then return nil,def.DisplayName..": "..property.." unavailable" end
   -- The legacy *Map string properties are PluginSecurity. The corresponding
   -- Content properties expose the actual authored URI to normal game scripts.
   local readable,content=pcall(function() return surface[property.."Content"].Uri end)
   if not readable or content~=target then return nil,def.DisplayName..": "..property.." binding mismatch" end
  end
  if p.Size.X<=0 or p.Size.Y<=0 or p.Size.Z<=0 then return nil,def.DisplayName..": empty mesh bounds" end
 end
 table.sort(assets)
 return node,nil,assets,table.concat(assets,"|")
end
function M.Clone(id)
 local template,issue=M.Resolve(id)
 if not template then return nil,issue end
 local model=template:Clone();model.Name=id;model:SetAttribute("PetTypeId",id);model:SetAttribute("CanonicalMeadowPet",true)
 for _,part in ipairs(model:GetDescendants()) do
  if part:IsA("BasePart") then part.Anchored=true;part.CanCollide=false;part.CanTouch=false;part.CanQuery=false end
 end
 return model
end
-- Explicit image proxies preload PBR maps, which are not covered by mesh-only preloading.
function M.Preload(id)
 local template,issue,assets,signature=M.Resolve(id)
 if not template then return false,issue end
 local targets={template};local proxies={};local meshIds={}
 for _,p in ipairs(template:GetDescendants()) do if p:IsA("MeshPart") then meshIds[p.MeshId]=true end end
 for _,content in ipairs(assets) do if not meshIds[content] then
  local proxy=Instance.new("ImageLabel");proxy.Image=content;table.insert(proxies,proxy);table.insert(targets,proxy)
 end end
 local loaded={}
 local ok,err=pcall(function()
  game:GetService("ContentProvider"):PreloadAsync(targets,function(content,status)
   loaded[content]=status==Enum.AssetFetchStatus.Success
  end)
 end)
 for _,proxy in ipairs(proxies) do proxy:Destroy() end
 if not ok then return false,tostring(err) end
 for _,content in ipairs(assets) do if not loaded[content] then return false,id..": asset failed to load "..content end end
 return true,signature
end
return M
