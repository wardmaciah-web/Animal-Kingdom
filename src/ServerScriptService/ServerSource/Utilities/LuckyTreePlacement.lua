-- Fail closed until real special templates and their fitted trunk are configured.
local RS=game:GetService("ReplicatedStorage")
local Config=require(RS.Shared.Gameplay.Definitions.LuckyTreeDefinitions)
local Geometry=require(RS.Shared.Gameplay.PetVisualGeometry)
local Landing=require(game.ServerScriptService.BiomeTeleport.Landing)
local M={}
local function path(root,value)
 for name in string.gmatch(value or "","[^.]+")do root=root and root:FindFirstChild(name)end
 return root
end
function M.Prepare(biome)
 local def=Config.Biomes[biome]
 if not def.TemplatePath then return nil,def.TemplateName..": no verified special template configured (LuckyTreeAssetId unset)."end
 local template=path(game,def.TemplatePath)
 if not template or not template:IsA("Model") or template.Name~=def.TemplateName then return nil,def.TemplateName..": configured template missing or ambiguous."end
 if def.LuckyTreeAssetId and template:GetAttribute("SourceAssetId")~=def.LuckyTreeAssetId then return nil,"Special tree asset provenance mismatch."end
 local trunk=def.TrunkPartName and template:FindFirstChild(def.TrunkPartName,true)
 if not trunk or not trunk:IsA("BasePart")then return nil,def.TemplateName..": fitted trunk part must be configured."end
 for _,part in ipairs(template:GetDescendants())do if part:IsA("LuaSourceContainer")then return nil,"Lucky templates must not contain reward scripts."end end
 local clone=template:Clone();clone:SetAttribute("GameplayGenerated",true);clone:SetAttribute("LuckyTree",true)
 for _,part in ipairs(clone:GetDescendants())do
  if part:IsA("ProximityPrompt")then part:Destroy()
  elseif part:IsA("BasePart")then part.Anchored=true;part.CanCollide=false;part.CanTouch=false end
  game:GetService("CollectionService"):RemoveTag(part,"GatherableTree")
  game:GetService("CollectionService"):RemoveTag(part,"GatherableResource")
 end
 for _,tag in ipairs(game:GetService("CollectionService"):GetTags(clone))do game:GetService("CollectionService"):RemoveTag(clone,tag)end
 local fitted=clone:FindFirstChild(def.TrunkPartName,true);fitted.CanCollide=true;fitted.CanQuery=true
 -- Only a separately fitted trunk is solid, never a whole canopy mesh hull.
 if fitted:IsA("MeshPart")then fitted.CollisionFidelity=Enum.CollisionFidelity.PreciseConvexDecomposition end
 local bounds=Geometry.Measure(clone)
 if not bounds then clone:Destroy();return nil,"Lucky template has no visible geometry."end
 return clone
end
local function authoredTree(part)
 local root=part
 while root and root~=workspace do
  if root:GetAttribute("AuthoredGatherableTree")==true then return root end
  root=root.Parent
 end
end
local function fittedTreeVisual(part)
 -- Imported canopy bounds can cover a clearing while its fitted trunk is far
 -- away. Keep trunk collision authoritative; never ignore an unfitted tree.
 local root=authoredTree(part)
 local trunk=root and (root:FindFirstChild("AK_TrunkCollider",true)or root:FindFirstChild("TrunkCollider",true))
 return trunk~=nil and trunk:IsA("BasePart")
end
local function reservedBounds()
 local boxes={}
 for _,part in ipairs(workspace:GetDescendants())do
  local normalTrunk=part:IsA("BasePart")and (part.Name=="AK_TrunkCollider"or part.Name=="TrunkCollider")and fittedTreeVisual(part)
  local unfittedNormal=part:IsA("MeshPart")and authoredTree(part)and not fittedTreeVisual(part)
  -- A normal trunk remains reserved while its cooldown hides/disables collision.
  if normalTrunk or unfittedNormal or (part:IsA("MeshPart")and not part.CanQuery and part.Transparency<.95 and not fittedTreeVisual(part))then
   local low=Vector3.new(math.huge,math.huge,math.huge);local high=-low
   for x=-1,1,2 do for y=-1,1,2 do for z=-1,1,2 do
    local corner=part.CFrame:PointToWorldSpace(part.Size*Vector3.new(x,y,z)/2)
    low=low:Min(corner);high=high:Max(corner)
   end end end
   table.insert(boxes,{Low=low,High=high})
  end
 end
 return boxes
end
local function supportedClearance(point,floor,size,visuals)
 local ray=RaycastParams.new();ray.FilterType=Enum.RaycastFilterType.Include;ray.FilterDescendantsInstances={floor}
 local surface
 for _,offset in ipairs({Vector3.zero,Vector3.new(-size.X/2,0,-size.Z/2),Vector3.new(size.X/2,0,-size.Z/2),Vector3.new(-size.X/2,0,size.Z/2),Vector3.new(size.X/2,0,size.Z/2)})do
  local hit=workspace:Raycast(point+offset+Vector3.new(0,4,0),Vector3.new(0,-8,0),ray)
  if not hit or hit.Normal.Y<.95 or hit.Material==Enum.Material.Water then return nil end
  if offset==Vector3.zero then surface=hit.Position end
 end
 local overlap=OverlapParams.new();overlap.FilterType=Enum.RaycastFilterType.Exclude;overlap.FilterDescendantsInstances={floor}
 local center=surface+Vector3.new(0,size.Y/2+.3,0)
 for _,part in ipairs(workspace:GetPartBoundsInBox(CFrame.new(center),size,overlap))do
  if part.CanCollide or (part:IsA("MeshPart")and part.Transparency<.95 and not fittedTreeVisual(part))then return nil end
 end
 -- Some imported structures deliberately disable queries on their visual mesh.
 -- They still occupy space: never place an event inside that visible building.
 local low,high=center-size/2,center+size/2
 for _,box in ipairs(visuals)do
  if low.X<box.High.X and high.X>box.Low.X and low.Y<box.High.Y and high.Y>box.Low.Y and low.Z<box.High.Z and high.Z>box.Low.Z then return nil end
 end
 overlap.RespectCanCollide=true
 for _,part in ipairs(workspace:GetPartBoundsInBox(CFrame.new(center),size,overlap))do if part.CanCollide then return nil end end
 return surface
end
function M.Candidates(biome,template)
 local floor=Landing.FindFloor(biome);if not floor then return {}end
 local bounds=Geometry.Measure(template);if not bounds then return {}end
 local clearance=Config.Biomes[biome].ApproachClearance or Config.ApproachClearance
 local size=Vector3.new(bounds.Size.X+clearance*2,math.max(8,bounds.Size.Y),bounds.Size.Z+clearance*2)
 local valid={};local markers=workspace:FindFirstChild("BiomeTeleportPoints");local visuals=reservedBounds()
 for _,fraction in ipairs(Config.CandidateFractions)do
  local point=floor.CFrame:PointToWorldSpace(Vector3.new(fraction[1]*floor.Size.X,floor.Size.Y/2,fraction[2]*floor.Size.Z))
  local nearLanding=false
  if markers then for _,marker in ipairs(markers:GetChildren())do if marker:IsA("BasePart") and (Vector3.new(marker.Position.X,0,marker.Position.Z)-Vector3.new(point.X,0,point.Z)).Magnitude<Config.TeleportClearance+math.max(size.X,size.Z)/2 then nearLanding=true;break end end end
  if not nearLanding then local ground=supportedClearance(point,floor,size,visuals);if ground then table.insert(valid,ground)end end
 end
 return valid
end
function M.Place(biome,template,rng)
 local candidates=M.Candidates(biome,template)
 if #candidates==0 then return nil,"No safe supported Lucky Tree location in "..biome end
 local surface=candidates[rng:NextInteger(1,#candidates)]
 local tree=template:Clone();local bounds=Geometry.Measure(tree)
 tree:PivotTo(Geometry.GroundCFrame(bounds,surface,tree:GetPivot().Rotation,0))
 local position=surface+Vector3.new(0,3,0)
 tree:SetAttribute("InteractionPosition",position);tree:SetAttribute("BiomeId",biome)
 local root=tree:FindFirstChild(Config.Biomes[biome].TrunkPartName,true)
 local anchor=Instance.new("Attachment");anchor.Name="LuckyInteraction";anchor.Parent=root;anchor.WorldPosition=position
 local prompt=Instance.new("ProximityPrompt");prompt.Name="LuckyTreePrompt";prompt.ActionText="TRY YOUR LUCK";prompt.ObjectText=biome.." Lucky Tree"
 prompt.HoldDuration=.2;prompt.RequiresLineOfSight=false;prompt.MaxActivationDistance=Config.InteractionDistance;prompt.Parent=anchor
 return tree,prompt,position
end
return M
