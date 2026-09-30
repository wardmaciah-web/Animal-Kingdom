-- Read-only current authored-map inspection. Run in Edit-mode Command Bar.
assert(not game:GetService("RunService"):IsRunning(),"Edit mode required")
local function candidate(o)
 if not (o:IsA("Model") or o:IsA("BasePart")) then return false end
 local n=string.lower(o.Name)
 return o:GetAttribute("TreeType")~=nil or o:GetAttribute("Category")=="Trees" or n:find("tree") or n:find("palm") or n:find("willow") or n:find("birch") or n:find("pine") or n:find("cactus") or n:find("flower")
end
local rows={};local floors={};local generated={}
for _,o in ipairs(workspace:GetDescendants()) do
 if o:GetAttribute("GameplayGenerated")==true then table.insert(generated,{Path=o:GetFullName(),Category=o:GetAttribute("AssetCategory"),Id=o:GetAttribute("AssetId")}) end
 if o:IsA("BasePart") and o.Name:match("Floor$") then table.insert(floors,{Path=o:GetFullName(),CF={o.CFrame:GetComponents()},Size={o.Size.X,o.Size.Y,o.Size.Z}}) end
 if not candidate(o) then continue end
 local parent=o.Parent;local nested=false
 while parent and parent~=workspace do if candidate(parent) then nested=true;break end;parent=parent.Parent end
 if nested then continue end
 local cf,size;if o:IsA("Model") then cf,size=o:GetBoundingBox() else cf,size=o.CFrame,o.Size end
 local parts={};local objects=o:GetDescendants();if o:IsA("BasePart") then table.insert(objects,o) end
 for _,p in ipairs(objects) do if p:IsA("BasePart") then table.insert(parts,{Name=p.Name,Path=p:GetFullName(),Class=p.ClassName,Position={p.Position.X,p.Position.Y,p.Position.Z},Size={p.Size.X,p.Size.Y,p.Size.Z},Anchored=p.Anchored}) end end
 table.insert(rows,{Path=o:GetFullName(),Name=o.Name,Class=o.ClassName,Attributes=o:GetAttributes(),Pivot={o:GetPivot():GetComponents()},Bounds={cf:GetComponents()},Size={size.X,size.Y,size.Z},PrimaryPart=o:IsA("Model") and o.PrimaryPart and o.PrimaryPart:GetFullName() or nil,Parts=parts})
end
local payload=game.HttpService:JSONEncode({PlaceId=game.PlaceId,Trees=rows,Floors=floors,Generated=generated})
print("AK_TREE_DISCOVERY_BEGIN")
for i=1,#payload,500 do print("AK_TREE_DISCOVERY_CHUNK "..payload:sub(i,i+499)) end
print("AK_TREE_DISCOVERY_END")
