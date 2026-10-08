-- Visual-only, idempotent replacement. Never registers rewards or unlocks a biome.
local Collection=game:GetService("CollectionService")
local Templates=game:GetService("ServerStorage"):WaitForChild("AK_FutureTreeTemplates")
local AdditionalTemplates=game:GetService("ServerStorage"):FindFirstChild("AK_FinalEightTreeTemplates")
local function findTemplate(name) return Templates:FindFirstChild(name) or (AdditionalTemplates and AdditionalTemplates:FindFirstChild(name)) end
local M={}
local recipes={
 Jungle={"Jungle1","Jungle2","Jungle3","Jungle4","Jungle5"},
 Desert={"TexturedTree09","Cactus5","Cactus4","Cactus3","Cactus2","Cactus1","TexturedTree12","TexturedTree14"},
 Snow={"TexturedTree08","TexturedTree10","TexturedTree11","TexturedTree20","TexturedTree16","TexturedTree13"},
 Volcano={"TexturedTree01","TexturedTree03","TexturedTree07","TexturedTree19","TexturedTree17"},
 Ocean={"Coral","Kelp","TexturedTree09","TexturedTree13","TexturedTree14","Jungle3"},
 AncientRuins={"TexturedTree06","TexturedTree15","TexturedTree19","TexturedTree04","TexturedTree17"},
 MagicalForest={"Mushroom1","TexturedTree12","Mushroom2","TexturedTree17","Mushroom3","TexturedTree18"},
 Sky={"TexturedTree02","TexturedTree04","TexturedTree06","TexturedTree09","TexturedTree13"},
 Prehistoric={"TexturedTree20","Fern","Jungle3","TexturedTree08","TexturedTree10"},
 Mythical={"TexturedTree19","TexturedTree15","TexturedTree06"},
}
local qualityRecipes={
 Snow={PineTree_Snow_1="SnowPine",pine_tree_2_snow="SnowFir",BirchTree_Dead_Snow_2="SnowBirch",pine_tree_1_snow="SnowLarch",Willow_Snow_5="SnowCedar",common_tree_3_snow="SnowAspen",Willow_Dead_Snow_3="SnowCrystal",common_tree_1_snow="SnowSpruce"},
 Volcano={CommonTree_Dead_1="VolcanoEmber",Willow_Dead_5="VolcanoWillow",common_tree_dead_2="VolcanoCinder",CommonTree_Dead_5="VolcanoBanyan",common_tree_dead_3="VolcanoThorn",CommonTree_Dead_3="VolcanoPhoenix",CommonTree_Dead_4="VolcanoBaobab",common_tree_dead_1="VolcanoIronwood",["Palm tree_1"]="VolcanoPalm",["Palm tree_2"]="VolcanoDrake"},
}
local palettes={
 Jungle={{78,145,64},{106,170,79},{64,123,87},{185,135,80},{87,169,94}},
 Desert={{187,166,79},{139,175,90},{177,153,84},{97,156,116}},
 Snow={{212,239,244},{163,211,225},{235,247,255},{151,199,218}},
 Volcano={{237,94,37},{164,63,48},{255,147,56},{100,79,98}},
 Ocean={{91,211,194},{108,170,227},{216,133,217},{142,225,162}},
 AncientRuins={{107,143,94},{145,164,98},{74,118,102}},
 MagicalForest={{182,110,224},{132,119,225},{219,130,191},{115,197,188}},
 Sky={{222,235,249},{246,190,212},{174,215,229},{251,224,164}},
 Prehistoric={{96,133,82},{127,153,85},{64,113,88}},
 Mythical={{228,183,100},{175,127,230},{122,212,220}},
}
local function biomeOf(tree)
 local biome=tree:GetAttribute("BiomeId")
 if not biome and tree.Parent and tree.Parent.Name=="Volcano island lowpoly" and (tree.Name=="Palm tree_1" or tree.Name=="Palm tree_2") then return "Volcano" end
 return biome
end
local function special(tree)
 return tree.Parent and tree.Parent.Name=="Volcano island lowpoly" and (tree.Name=="Palm tree_1" or tree.Name=="Palm tree_2")
end
local function family(tree)
 return tostring(tree:GetAttribute("TreeTypeId") or tree:GetAttribute("TreeType") or tree:GetAttribute("AK_TreeType") or tree:GetAttribute("SourceAssetName") or tree.Name:match("Type%d+") or tree.Name:match("_AK_(.+)") or tree.Name)
end
local function tint(visual,biome,index)
 local colors=palettes[biome];local rgb=colors[(index-1)%#colors+1];local color=Color3.fromRGB(rgb[1],rgb[2],rgb[3])
 for _,part in visual:GetDescendants() do if part:IsA("BasePart") then
  part.Anchored=true;part.CanCollide=false;part.CanTouch=false;part.CanQuery=false
  local leaf=part.Name:lower():find("canopy")~=nil or not part.Name:lower():find("trunk") and #visual:GetDescendants()<5
  if leaf then part.Name="Leaves_"..part.Name;part.Color=color;local surface=part:FindFirstChildWhichIsA("SurfaceAppearance");if surface then surface.Color=color;part.Color=Color3.new(1,1,1) end
  elseif biome=="Volcano" then part.Color=Color3.fromRGB(56,43,49);local surface=part:FindFirstChildWhichIsA("SurfaceAppearance");if surface then surface.Color=part.Color;part.Color=Color3.new(1,1,1) end
  end
 end end
end
local function applyApprovedLegacy()
 local groups={};local report={replaced=0,skipped=0,biomes={}}
 for _,tree in workspace:GetDescendants() do
  if (tree:IsA("Model") or tree:IsA("BasePart")) and (tree:GetAttribute("AuthoredGatherableTree")==true or special(tree)) then
   local b=biomeOf(tree)
   if (b=="Snow" or b=="Volcano") and recipes[b] then groups[b]=groups[b] or {};table.insert(groups[b],tree) end
  end
 end
 for biome,trees in groups do
  local families={};local seen={}
  for _,tree in trees do local key=family(tree);if not seen[key] then seen[key]=true;table.insert(families,key) end end
  table.sort(families);local indices={};for i,key in families do indices[key]=i end
  report.biomes[biome]={trees=#trees,sourceFamilies=#families,visualFamilies={}}
  for _,tree in trees do
   local qualityName=qualityRecipes[biome] and qualityRecipes[biome][family(tree)]
   local qualityTemplate=qualityName and Templates:FindFirstChild(qualityName)
   if not qualityTemplate then report.skipped+=1;continue end
   local previous=tree:FindFirstChild("AK_FutureTreeVisual")
   if previous then
    if qualityTemplate and previous:GetAttribute("QualityRevision")~=2 then
     local backup=game.ServerStorage:FindFirstChild("AK_FutureTree_QualityCheckpoint") or Instance.new("Folder");backup.Name="AK_FutureTree_QualityCheckpoint";backup.Parent=game.ServerStorage
     local copy=previous:Clone();copy:SetAttribute("OriginalTreePath",tree:GetFullName());copy:SetAttribute("OriginalTreePivot",tree:GetPivot());copy.Parent=backup
     for _,v in copy:GetDescendants() do for _,tag in Collection:GetTags(v) do Collection:RemoveTag(v,tag) end end
     for _,tag in Collection:GetTags(copy) do Collection:RemoveTag(copy,tag) end
     previous:Destroy()
    else report.skipped+=1;continue end
   end
   local index=indices[family(tree)];local name=recipes[biome][(index-1)%#recipes[biome]+1]
   if qualityTemplate then name=qualityName end
   local visual=Templates[name]:Clone();visual.Name="AK_FutureTreeVisual"
   local originalPivot=tree:GetPivot();local bounds,size;local root
   if tree:IsA("Model") then bounds,size=tree:GetBoundingBox();root=tree.PrimaryPart else bounds,size=tree.CFrame,tree.Size;root=tree end
   local cf,newSize=visual:GetBoundingBox()
   if biome=="AncientRuins" or biome=="Sky" or biome=="Mythical" then
    local roots=Templates["Root"..((index-1)%2+1)]:Clone();roots.Name="SculptedRoots"
    local rootCf,rootSize=roots:GetBoundingBox()
    roots:ScaleTo(roots:GetScale()*math.min(newSize.X/rootSize.X,newSize.Z/rootSize.Z)*.7)
    rootCf,rootSize=roots:GetBoundingBox()
    roots:PivotTo(cf*CFrame.new(0,-newSize.Y/2+rootSize.Y*.35,0)*roots:GetPivot():ToObjectSpace(rootCf):Inverse())
    roots.Parent=visual;cf,newSize=visual:GetBoundingBox()
   end
   local scale=qualityTemplate and math.clamp(size.Y,36,56)/newSize.Y or math.min(size.X*.94/newSize.X,size.Y*.98/newSize.Y,size.Z*.94/newSize.Z)
   visual:ScaleTo(visual:GetScale()*scale)
   cf,newSize=visual:GetBoundingBox()
   local visualOffset=qualityTemplate and special(tree) and (tree.Name=="Palm tree_1" and -4.5 or 4.5) or 0
   visual:PivotTo(bounds*CFrame.new(visualOffset,-size.Y/2+newSize.Y/2,0)*visual:GetPivot():ToObjectSpace(cf):Inverse())
   if qualityTemplate then
    for _,p in visual:GetDescendants() do if p:IsA("BasePart") then p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;if p.Name:lower():find("foliage") or p.Name:lower():find("canopy") then p.Name="Leaves_"..p.Name end end end
    visual:SetAttribute("QualityRevision",2)
   else tint(visual,biome,index) end
   -- Original geometry remains the authoritative query/collision/root. Only hide rendering.
   local originalParts=tree:GetDescendants();if tree:IsA("BasePart") then table.insert(originalParts,tree) end
   for _,part in originalParts do
    if part:IsA("BasePart") then if part:GetAttribute("AKFutureOriginalTransparency")==nil then part:SetAttribute("AKFutureOriginalTransparency",part.Transparency);part:SetAttribute("AKFutureOriginalCastShadow",part.CastShadow) end;part.Transparency=1;part.CastShadow=false
    elseif part:IsA("ParticleEmitter") then if part:GetAttribute("AKFutureOriginalEnabled")==nil then part:SetAttribute("AKFutureOriginalEnabled",part.Enabled) end;part.Enabled=false end
   end
   visual:SetAttribute("BiomeId",biome);visual:SetAttribute("VisualTemplate",name);visual:SetAttribute("VisualFamily",family(tree))
   visual:SetAttribute("FutureTreeVisual",true);visual.Parent=tree
   Collection:AddTag(visual,"FutureBiomeTreeVisual")
   if not root then tree.WorldPivot=originalPivot end
   assert((tree:GetPivot().Position-originalPivot.Position).Magnitude<.001,"Tree pivot changed")
   report.biomes[biome].visualFamilies[name]=true;report.replaced+=1
  end
 end
 M.PolishVolcanoEdges()
 report.understory=M.DecorateQuality()
 return report
end


-- Reversible surface polish on the existing Volcano island, never its tree anchors.
function M.PolishVolcanoEdges()
 local island=workspace:FindFirstChild("Volcano island lowpoly");if not island then return end
 local surfaceNames={Volcano_Grass=true,Island_Grass=true,Volacano_Sand=true,Volcano_Base=true,Clouds=true,shrubbery=true}
 for _,p in island:GetChildren() do if p:IsA("MeshPart") and (surfaceNames[p.Name] or p.Name=="Volcanic_lava" or p.Name=="Lava_bubble") then
  if p:GetAttribute("AKQualityOriginalTexture")==nil then
   p:SetAttribute("AKQualityOriginalTexture",p.TextureID);p:SetAttribute("AKQualityOriginalColor",p.Color);p:SetAttribute("AKQualityOriginalMaterial",p.Material.Name)
  end
  p.TextureID=""
  local sa=p:FindFirstChildWhichIsA("SurfaceAppearance")
  if sa then if sa:GetAttribute("AKQualityOriginalColorMap")==nil then sa:SetAttribute("AKQualityOriginalColorMap",sa.ColorMap);sa:SetAttribute("AKQualityOriginalColor",sa.Color) end;sa.ColorMap="";sa.Color=Color3.new(1,1,1) end
  local lava=p.Name=="Volcanic_lava" or p.Name=="Lava_bubble"
  p.Material=lava and Enum.Material.CrackedLava or Enum.Material.Basalt
  p.Color=lava and Color3.fromRGB(200,80,22) or p.Name=="Clouds" and Color3.fromRGB(86,78,76) or p.Name=="Volacano_Sand" and Color3.fromRGB(94,72,60) or Color3.fromRGB(65,57,55)
 end end
end

-- Small native-mesh clusters; no collision or progression ownership.
function M.DecorateQuality()
 if workspace:FindFirstChild("AK_SnowVolcanoUnderstory") then return 0 end
 local folder=Instance.new("Folder");folder.Name="AK_SnowVolcanoUnderstory";folder.Parent=workspace
 local anchors={}
 for _,t in workspace:GetDescendants() do if (t:IsA("Model") or t:IsA("BasePart")) and (t:GetAttribute("AuthoredGatherableTree") or special(t)) then local b=biomeOf(t);if b=="Snow" or b=="Volcano" then table.insert(anchors,t) end end end
 table.sort(anchors,function(a,b) local p,q=a:GetPivot().Position,b:GetPivot().Position;return p.X==q.X and p.Z<q.Z or p.X<q.X end)
 local count=0
 for i,t in anchors do
  local b=biomeOf(t);local p=t:GetPivot().Position
  local cf,sz;if t:IsA("Model") then cf,sz=t:GetBoundingBox() else cf,sz=t.CFrame,t.Size end
  local ground=cf.Y-sz.Y/2
  for j=1,2 do
   local angle=i*2.399963+j*1.7;local pos=Vector3.new(p.X+math.cos(angle)*(12+j*1.5),ground,p.Z+math.sin(angle)*(12+j*1.5))
   local clear=true
   if b=="Snow" then clear=pos.X>-169 and pos.X<3 and pos.Z>608 and pos.Z<783 and (Vector2.new(pos.X+85,pos.Z-695)).Magnitude>16
   else clear=pos.X>-422 and pos.X<-270 and pos.Z>618 and pos.Z<782 and (Vector2.new(pos.X+295,pos.Z-740)).Magnitude>69 end
   for _,other in anchors do local q=other:GetPivot().Position;if (Vector2.new(pos.X-q.X,pos.Z-q.Z)).Magnitude<9 then clear=false;break end end
   if clear then
    local name=b=="Snow" and (j==1 and (i%2==0 and "SnowBushA" or "SnowBushB") or "SnowRockA") or (j==1 and "VolcanoAshShrub" or (i%2==0 and "VolcanoRockA" or "VolcanoRockB"))
    local template=Templates:FindFirstChild(name)
    if template then
     local m=template:Clone();m.Name=b.."_Cluster_"..i.."_"..j
     local mc,ms=m:GetBoundingBox();local target=j==1 and (1.7+(i%3)*.45) or (2.3+(i%4)*.45)
     m:ScaleTo(m:GetScale()*target/ms.Y);mc,ms=m:GetBoundingBox()
     m:PivotTo(CFrame.new(pos+Vector3.new(0,ms.Y/2-.08,0))*CFrame.Angles(0,angle,0)*m:GetPivot():ToObjectSpace(mc):Inverse())
     for _,v in m:GetDescendants() do if v:IsA("LuaSourceContainer") then v:Destroy() elseif v:IsA("BasePart") then v.Anchored=true;v.CanCollide=false;v.CanTouch=false;v.CanQuery=false;if j==1 then v.Name="Leaves_"..v.Name end end end
     m:SetAttribute("BiomeId",b);m:SetAttribute("QualityDecoration",true);m.Parent=folder;count+=1
    end
   end
  end
 end
 return count
end

function M.Restore()
 local n=0
 for _,tree in workspace:GetDescendants() do if (tree:IsA("Model") or tree:IsA("BasePart")) and (biomeOf(tree)=="Snow" or biomeOf(tree)=="Volcano") then
  local visual=tree:FindFirstChild("AK_FutureTreeVisual")
  if visual then visual:Destroy()
   local originalParts=tree:GetDescendants();if tree:IsA("BasePart") then table.insert(originalParts,tree) end
   for _,p in originalParts do
    local old=p:GetAttribute("AKFutureOriginalTransparency");if old~=nil and p:IsA("BasePart") then p.Transparency=old;p.CastShadow=p:GetAttribute("AKFutureOriginalCastShadow");p:SetAttribute("AKFutureOriginalTransparency",nil);p:SetAttribute("AKFutureOriginalCastShadow",nil) end
    local enabled=p:GetAttribute("AKFutureOriginalEnabled");if enabled~=nil and p:IsA("ParticleEmitter") then p.Enabled=enabled;p:SetAttribute("AKFutureOriginalEnabled",nil) end
   end;n+=1
  end
 end end
 local decor=workspace:FindFirstChild("AK_SnowVolcanoUnderstory");if decor then decor:Destroy() end
 local island=workspace:FindFirstChild("Volcano island lowpoly")
 if island then for _,p in island:GetChildren() do if p:IsA("MeshPart") and p:GetAttribute("AKQualityOriginalTexture")~=nil then
  p.TextureID=p:GetAttribute("AKQualityOriginalTexture");p.Color=p:GetAttribute("AKQualityOriginalColor");p.Material=Enum.Material[p:GetAttribute("AKQualityOriginalMaterial")]
  for _,k in {"AKQualityOriginalTexture","AKQualityOriginalColor","AKQualityOriginalMaterial"} do p:SetAttribute(k,nil) end
  local sa=p:FindFirstChildWhichIsA("SurfaceAppearance")
  if sa and sa:GetAttribute("AKQualityOriginalColorMap")~=nil then sa.ColorMap=sa:GetAttribute("AKQualityOriginalColorMap");sa.Color=sa:GetAttribute("AKQualityOriginalColor");sa:SetAttribute("AKQualityOriginalColorMap",nil);sa:SetAttribute("AKQualityOriginalColor",nil) end
 end end end
 return n
end

-- Approved biomes are immutable. Only explicitly enabled unfinished-biome recipes run.
local newRecipes = {
 Desert={cactus_short="DesertBarrelTree",cactus_tall="DesertColumn",Cactus_1="DesertSaguaro",Cactus_5="DesertPalm",Cactus_4="DesertAcacia",CactusFlowers_2="DesertBloom",BirchTree_Dead_5="DesertIronwood",Cactus_3="DesertJoshua"},
 Jungle={Tree_Oak_7="JungleBanyan",Tree_Palm_2="JungleKapok",Tree_Oak_8="JungleFig",CommonTree_5="JungleOrchid",PalmTree_1="JunglePalm",tree_palmDetailedShort="JungleFanPalm",tree_palmDetailedTall="JungleRainTree",tree_palmTall="JungleDragon"},
}
local protected={Meadow=true,Forest=true,Snow=true,Volcano=true}
function M.Apply(scope)
 local report={replaced=0,skipped=0,biomes={}}
 if scope and protected[scope] then return report end
 for _,tree in workspace:GetDescendants() do
  if not (tree:IsA("Model") or tree:IsA("BasePart")) or not tree:GetAttribute("AuthoredGatherableTree") then continue end
  local b=biomeOf(tree);local recipe=newRecipes[b]
  if not recipe or (scope and b~=scope) then continue end
  local name=recipe[family(tree)];local template=name and findTemplate(name)
  if not template then report.skipped+=1;continue end
  local previous=tree:FindFirstChild("AK_FutureTreeVisual")
  if previous and previous:GetAttribute("QualityRevision")==3 and previous:GetAttribute("VisualTemplate")==name then report.skipped+=1;continue end
  local originalPivot=tree:GetPivot()
  if previous then
   local backup=game.ServerStorage:FindFirstChild("AK_FinalEight_Checkpoint_20261008") or Instance.new("Folder")
   backup.Name="AK_FinalEight_Checkpoint_20261008";backup.Parent=game.ServerStorage
   local copy=previous:Clone();copy:SetAttribute("OriginalTreePath",tree:GetFullName());copy:SetAttribute("OriginalTreePivot",originalPivot);copy.Parent=backup
   for _,v in {copy,table.unpack(copy:GetDescendants())} do for _,tag in Collection:GetTags(v) do Collection:RemoveTag(v,tag) end end
   previous:Destroy()
  end
  local bounds,size
  if tree:IsA("Model") then bounds,size=tree:GetBoundingBox() else bounds,size=tree.CFrame,tree.Size end
  local visual=template:Clone();visual.Name="AK_FutureTreeVisual"
  local cf,sz=visual:GetBoundingBox()
  local height=math.clamp(size.Y,36,52)
  visual:ScaleTo(visual:GetScale()*height/sz.Y);cf,sz=visual:GetBoundingBox()
  -- Keep ground contact and orientation; all original gameplay geometry stays intact.
  visual:PivotTo(bounds*CFrame.new(0,-size.Y/2+sz.Y/2,0)*visual:GetPivot():ToObjectSpace(cf):Inverse())
  for _,v in visual:GetDescendants() do
   if v:IsA("LuaSourceContainer") or v:IsA("PackageLink") then v:Destroy()
   elseif v:IsA("BasePart") then v.Anchored=true;v.CanCollide=false;v.CanTouch=false;v.CanQuery=false
    if v.Name:lower():find("foliage") or v.Name:lower():find("canopy") then v.Name="Leaves_"..v.Name end
   end
  end
  local originalParts=tree:GetDescendants();if tree:IsA("BasePart") then table.insert(originalParts,tree) end
  for _,part in originalParts do
   if part:IsA("BasePart") then
    if part:GetAttribute("AKFutureOriginalTransparency")==nil then part:SetAttribute("AKFutureOriginalTransparency",part.Transparency);part:SetAttribute("AKFutureOriginalCastShadow",part.CastShadow) end
    part.Transparency=1;part.CastShadow=false
   elseif part:IsA("ParticleEmitter") then
    if part:GetAttribute("AKFutureOriginalEnabled")==nil then part:SetAttribute("AKFutureOriginalEnabled",part.Enabled) end
    part.Enabled=false
   end
  end
  visual:SetAttribute("BiomeId",b);visual:SetAttribute("VisualTemplate",name);visual:SetAttribute("VisualFamily",family(tree));visual:SetAttribute("FutureTreeVisual",true);visual:SetAttribute("QualityRevision",3)
  visual.Parent=tree;Collection:AddTag(visual,"FutureBiomeTreeVisual")
  if tree:IsA("Model") and not tree.PrimaryPart then tree.WorldPivot=originalPivot end
  assert((tree:GetPivot().Position-originalPivot.Position).Magnitude<.001,"Tree pivot changed")
  report.replaced+=1;report.biomes[b]=(report.biomes[b] or 0)+1
 end
 for b in newRecipes do if not scope or scope==b then report.understory=report.understory or {};report.understory[b]=M.DecorateBiome(b);if b=="Desert" then report.decorativeTrees=M.PolishDesertDecorations() end end end
 return report
end

function M.DecorateBiome(b)
 if protected[b] or not newRecipes[b] then return 0 end
 local name="AK_"..b.."_Understory";if workspace:FindFirstChild(name) then return 0 end
 local template=findTemplate(b.."Understory");if not template then return 0 end
 local anchors={}
 for _,t in workspace:GetDescendants() do if t:GetAttribute("AuthoredGatherableTree") and biomeOf(t)==b and (t:IsA("Model") or t:IsA("BasePart")) then table.insert(anchors,t) end end
 table.sort(anchors,function(a,c) local p,q=a:GetPivot().Position,c:GetPivot().Position;return p.X==q.X and p.Z<q.Z or p.X<q.X end)
 local folder=Instance.new("Folder");folder.Name=name;folder.Parent=workspace
 local n=0
 for i,t in anchors do
  local p=t:GetPivot().Position
  for j=1,2 do
   local angle=i*2.399963+j*1.73;local pos=p+Vector3.new(math.cos(angle)*(12+j*2),0,math.sin(angle)*(12+j*2))
   local clear=true
   for _,other in anchors do local q=other:GetPivot().Position;if Vector2.new(pos.X-q.X,pos.Z-q.Z).Magnitude<10 then clear=false;break end end
   if b=="Jungle" and (pos.X<80 or pos.X>279 or pos.Z<330 or pos.Z>505) then clear=false end
   if b=="Desert" and (pos.X<100 or pos.X>282 or pos.Z<608 or pos.Z>790 or Vector2.new(pos.X-187,pos.Z-705).Magnitude<32) then clear=false end
   local biomeFolder=workspace:FindFirstChild(b);local floor=biomeFolder and biomeFolder:FindFirstChild(b.."Floor")
   if floor and floor:IsA("BasePart") then pos=Vector3.new(pos.X,floor.Position.Y+floor.Size.Y/2,pos.Z) end
   if clear then
    local m=template:Clone();m.Name=b.."_Understory_"..i.."_"..j;local cf,sz=m:GetBoundingBox()
    m:ScaleTo(m:GetScale()*(2.3+(i%4)*.5)/sz.Y);cf,sz=m:GetBoundingBox()
    m:PivotTo(CFrame.new(pos+Vector3.new(0,sz.Y/2-.1,0))*CFrame.Angles(0,angle,0)*m:GetPivot():ToObjectSpace(cf):Inverse())
    for _,d in m:GetDescendants() do if d:IsA("BasePart") then d.Anchored=true;d.CanCollide=false;d.CanTouch=false;d.CanQuery=false;d.Name="Leaves_"..d.Name elseif d:IsA("LuaSourceContainer") or d:IsA("PackageLink") then d:Destroy() end end
    m:SetAttribute("BiomeId",b);m:SetAttribute("QualityDecoration",true);m:SetAttribute("QualityRevision",3);m.Parent=folder;n+=1
   end
  end
 end
 return n
end


function M.PolishDesertDecorations()
 local folder=workspace:FindFirstChild("AK_Desert_NativePalms");if folder then return 0 end
 local wanted={["rbxassetid://91669506494073"]=true,["rbxassetid://115582189664030"]=true,["rbxassetid://132769925644408"]=true}
 local backup=game.ServerStorage:FindFirstChild("AK_FinalEight_Checkpoint_20261008")
 for _,p in workspace:GetDescendants() do
  if p:IsA("MeshPart") and wanted[p.MeshId] and p.Position.X>90 and p.Position.X<300 and p.Position.Z>600 and p.Position.Z<810 then
   if p:GetAttribute("AK8OriginalTransparency")==nil then
    if backup then local c=p:Clone();c:SetAttribute("OriginalPath",p:GetFullName());c.Parent=backup end
    p:SetAttribute("AK8OriginalTransparency",p.Transparency);p:SetAttribute("AK8OriginalCanCollide",p.CanCollide);p:SetAttribute("AK8OriginalCanQuery",p.CanQuery);p:SetAttribute("AK8OriginalCanTouch",p.CanTouch);p:SetAttribute("AK8OriginalCastShadow",p.CastShadow)
   end
   p.Transparency=1;p.CastShadow=false;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false
  end
 end
 local anchors={} for _,t in workspace:GetDescendants() do if t:GetAttribute("AuthoredGatherableTree") and biomeOf(t)=="Desert" and t:IsA("Model") then table.insert(anchors,t:GetPivot().Position) end end
 folder=Instance.new("Folder");folder.Name="AK_Desert_NativePalms";folder.Parent=workspace;local n=0
 for i,pos in {Vector3.new(275,9.05,780),Vector3.new(235,9.05,780),Vector3.new(279,9.05,737),Vector3.new(270,9.05,703),Vector3.new(235,9.05,758),Vector3.new(108,9.05,769),Vector3.new(115,9.05,660),Vector3.new(237,9.05,614),Vector3.new(100,9.05,626),Vector3.new(270,9.05,765),Vector3.new(249,9.05,719),Vector3.new(177,9.05,788)} do
  local clear=true;for _,q in anchors do if Vector2.new(pos.X-q.X,pos.Z-q.Z).Magnitude<10 then clear=false end end
  if clear then
   local name=i%3==0 and "DesertAcacia" or "DesertPalm";local template=findTemplate(name)
   if template then local m=template:Clone();m.Name="Desert_DecorTree_"..i;local cf,sz=m:GetBoundingBox();m:ScaleTo(m:GetScale()*(28+i%4*3)/sz.Y);cf,sz=m:GetBoundingBox()
    m:PivotTo(CFrame.new(pos+Vector3.new(0,sz.Y/2,0))*CFrame.Angles(0,i*2.399963,0)*m:GetPivot():ToObjectSpace(cf):Inverse())
    for _,p in m:GetDescendants() do if p:IsA("BasePart") then p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;if p.Name:lower():find("foliage") then p.Name="Leaves_"..p.Name end end end
    m:SetAttribute("BiomeId","Desert");m:SetAttribute("QualityDecoration",true);m:SetAttribute("QualityRevision",3);m.Parent=folder;n+=1
   end
  end
 end
 return n
end

return M

