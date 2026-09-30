-- Read-only discovery: never renames, reparents, clones or replaces authored geometry.
local RS=game:GetService("ReplicatedStorage")
local Landing=require(game:GetService("ServerScriptService").BiomeTeleport.Landing)
local Biomes=require(RS.Shared.Gameplay.Definitions.BiomeDefinitions)
local Assets=require(RS.Shared.Gameplay.Definitions.AuthoredTreeDefinitions)
local Discovery={}
function Discovery.IsTree(object)
 if not (object:IsA("Model") or object:IsA("BasePart")) or object:GetAttribute("GameplayGenerated")==true then return false end
 if object:GetAttribute("ForestDecorationOnly")==true then return false end
 local source=object:GetAttribute("SourceAssetName") or object:GetAttribute("TreeType")
 if source then return Assets[source]==true end
 -- These specific authored families have no source metadata; inspected as whole trees.
 local name=object.Name
 return name:match("^MagicalForestTree_%d+_AK_MagicTree$")~=nil
  or name:match("^MagicalForestTree_%d+_AK_LowpolyWillow$")~=nil
  or name:match("^MagicalForestTree_%d+_AK_NimbusWillow$")~=nil
  or name:match("^AncientRuinsTree_%d+_Type[123]$")~=nil
  or name=="AK_AncientRuins_CypressTree" or name=="AK_AncientRuins_StylizedTree"
  or (object.Parent==workspace and name:match("^DecorTree[1-6]$")~=nil)
  or (object.Parent and object.Parent.Name=="Volcano island lowpoly" and (name=="Palm tree_1" or name=="Palm tree_2"))
end
function Discovery.Scan()
 local floors={}
 for _,def in ipairs(Biomes.Ordered) do local floor=Landing.FindFloor(def.Id);if floor then table.insert(floors,{Id=def.Id,Part=floor}) end end
 local found={}
 for _,object in ipairs(workspace:GetDescendants()) do
  if not Discovery.IsTree(object) then continue end
  local nested=false;local parent=object.Parent
  while parent and parent~=workspace do
   if Discovery.IsTree(parent) or parent:GetAttribute("GameplayGenerated")==true then nested=true;break end
   parent=parent.Parent
  end
  if nested then continue end
  local root=object:IsA("BasePart") and object or object.PrimaryPart or object:FindFirstChildWhichIsA("BasePart",true)
  if not root then continue end
  local pivot=object:GetPivot()
  local bounds,size;if object:IsA("Model") then bounds,size=object:GetBoundingBox() else bounds,size=object.CFrame,object.Size end
  local halfHeight=(math.abs(bounds.RightVector.Y)*size.X+math.abs(bounds.UpVector.Y)*size.Y+math.abs(bounds.LookVector.Y)*size.Z)/2
  local bottom=bounds.Position.Y-halfHeight
  local hint=object:GetAttribute("Biome") or object:GetAttribute("BiomeName")
  local selected;local score=math.huge
  for _,floor in ipairs(floors) do
   local point=floor.Part.CFrame:PointToObjectSpace(Vector3.new(pivot.Position.X,bottom,pivot.Position.Z))
   local vertical=math.abs(point.Y-floor.Part.Size.Y/2)
   if math.abs(point.X)<=floor.Part.Size.X/2 and math.abs(point.Z)<=floor.Part.Size.Z/2 and vertical<=30 then
    local priority=vertical+(hint==floor.Id and -100 or 0)
    if priority<score then selected=floor;score=priority end
   end
  end
  if not selected then continue end -- Town/admin/set dressing outside real biome floors stays inert.
  local anchored=true
  local parts=object:GetDescendants();if object:IsA("BasePart") then table.insert(parts,object) end
  for _,part in ipairs(parts) do if part:IsA("BasePart") and not part.Anchored then anchored=false;break end end
  if not anchored then warn("[TreeDiscovery] Unanchored authored tree skipped: "..object:GetFullName());continue end
  -- Prompt stays at reachable trunk height even if PrimaryPart is a canopy mesh.
  local floorTop=selected.Part.Position.Y+selected.Part.Size.Y/2
  local interaction=Vector3.new(pivot.Position.X,math.max(bottom,floorTop)+3,pivot.Position.Z)
  -- Forest remodel anchors are authored after scale, grounding and trunk collision.
  -- Read their world position so the prompt follows each final tree transform.
  if selected.Id=="Forest" and object:GetAttribute("ForestRemodelVersion")==2 then
   local authored=object:FindFirstChild("AuthoredTreeInteraction",true)
   if authored and authored:IsA("Attachment") then interaction=authored.WorldPosition end
  end
  table.insert(found,{Object=object,Biome=selected.Id,Root=root,Pivot=pivot,InteractionPosition=interaction})
 end
 return found
end
return Discovery
