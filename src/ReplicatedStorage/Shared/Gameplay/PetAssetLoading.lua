-- Preflight the actual mesh and texture dependencies before a paid reward is offered.
local Models=require(script.Parent.PetModelResolver)
local Definitions=require(script.Parent.Definitions.PetDefinitions)
local M={}
function M.Resolve(id)
 local def=Definitions[id]
 if not def or def.LegacyOnly or def.RetiredFromRewards then return nil,'Not an active imported species' end
 local template,issue=Models.Resolve(id)
 if not template then return nil,issue end
 local assets,seen={},{}
 local function add(id)
  if type(id)=='string'and id~=''and not seen[id]then seen[id]=true;table.insert(assets,id)end
 end
 local objects=template:GetDescendants();if template:IsA('BasePart')then table.insert(objects,template)end
 for _,part in ipairs(objects)do
  if part:IsA('MeshPart')then add(part.MeshId);add(part.TextureID)
  elseif part:IsA('SurfaceAppearance')then
   for _,property in ipairs({'ColorMap','NormalMap','MetalnessMap','RoughnessMap'})do
    local ok,uri=pcall(function()return part[property..'Content'].Uri end)
    if ok then add(uri)end
   end
  end
 end
 table.sort(assets)
 return template,nil,assets,table.concat(assets,'|')
end
function M.Preload(id)
 local template,issue,assets,signature=M.Resolve(id)
 if not template then return false,issue end
 local targets,proxies,meshIds={template},{},{}
 local objects=template:GetDescendants();if template:IsA('BasePart')then table.insert(objects,template)end
 for _,p in ipairs(objects)do if p:IsA('MeshPart')then meshIds[p.MeshId]=true end end
 for _,id in ipairs(assets)do if not meshIds[id]then
  local proxy=Instance.new('ImageLabel');proxy.Image=id;table.insert(targets,proxy);table.insert(proxies,proxy)
 end end
 local loaded={}
 local ok,err=pcall(function()game:GetService('ContentProvider'):PreloadAsync(targets,function(id,status)loaded[id]=status==Enum.AssetFetchStatus.Success end)end)
 for _,proxy in ipairs(proxies)do proxy:Destroy()end
 if not ok then return false,tostring(err)end
 for _,asset in ipairs(assets)do if not loaded[asset]then return false,id..': asset failed to load '..asset end end
 return true,signature
end
return M
