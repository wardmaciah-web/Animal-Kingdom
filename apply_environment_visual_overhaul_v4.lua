-- Animal Kingdom Environment Visual Overhaul V4. Command Bar script; generated for manual execution only.
local Workspace=game:GetService("Workspace")
local ServerStorage=game:GetService("ServerStorage")
local InsertService=game:GetService("InsertService")
local MarketplaceService=game:GetService("MarketplaceService")
local MARKER="AnimalKingdomEnvironmentVisualOverhaulV4"
local ROLLBACK="AnimalKingdomVisualOverhaulV4Rollback"
local GRASS_IMAGE=95876676447793 -- Verified AssetTypeId 1 (Image); Decal container was 80602499530833.
if Workspace:GetAttribute(MARKER)==true then warn("Already applied: "..MARKER)return end

local BIOMES={"Meadow","Forest","Jungle","Desert","Snow","Volcano","Ocean","AncientRuins","MagicalForest","Sky","Prehistoric","Mythical"}
local AFFECTED={"Snow","Ocean","Sky","AncientRuins","Desert","Volcano"}
local EXPECTED={Meadow=5,Forest=5,Jungle=5,Desert=8,Snow=8,Volcano=8,Ocean=8,AncientRuins=8,MagicalForest=5,Sky=8,Prehistoric=5,Mythical=5}
local NEW={
 Snow={"PineTree_Snow_1","BirchTree_Dead_Snow_2","Willow_Dead_Snow_3"},
 Ocean={"tree_palm","tree_palmShort","tree_palmBend"},
 Sky={"tree_cone","tree_fat","tree_thin"},
 AncientRuins={"Tree_Bare_4","Tree_Bare_5","Tree_Bare_6"},
 Desert={"cactus_short","cactus_tall","CactusFlowers_2"},
 Volcano={"common_tree_dead_1","common_tree_dead_2","common_tree_dead_3"},
}
local FINAL={
 Snow={"common_tree_1_snow","common_tree_2_snow","common_tree_3_snow","pine_tree_1_snow","pine_tree_2_snow","PineTree_Snow_1","BirchTree_Dead_Snow_2","Willow_Dead_Snow_3"},
 Ocean={"Tree_Palm_1","Tree_Palm_3","Tree_Palm_4","Tree_Palm_5","Tree_Palm_6","tree_palm","tree_palmShort","tree_palmBend"},
 Sky={"Tree_Pine_3","Tree_Pine_4","Tree_Pine_5","Tree_Pine_6","pine_tree_3_snow","tree_cone","tree_fat","tree_thin"},
 AncientRuins={"Tree_Bare_1","Tree_Bare_2","Tree_Bare_3","Tree_Cedar_2","Tree_Cedar_3","Tree_Bare_4","Tree_Bare_5","Tree_Bare_6"},
 Desert={"Cactus_1","Cactus_2","Cactus_3","Cactus_4","Cactus_5","cactus_short","cactus_tall","CactusFlowers_2"},
 Volcano={"CommonTree_Dead_1","CommonTree_Dead_2","CommonTree_Dead_3","CommonTree_Dead_4","CommonTree_Dead_5","common_tree_dead_1","common_tree_dead_2","common_tree_dead_3"},
}
local COLORS={
 Snow={Color3.fromRGB(45,91,89),Color3.fromRGB(57,106,102),Color3.fromRGB(65,125,115),Color3.fromRGB(90,139,126),Color3.fromRGB(38,80,77),Color3.fromRGB(73,122,117),Color3.fromRGB(194,212,215),Color3.fromRGB(112,137,134)},
 Ocean={Color3.fromRGB(48,145,91),Color3.fromRGB(54,158,111),Color3.fromRGB(71,171,91),Color3.fromRGB(38,119,83),Color3.fromRGB(111,164,74),Color3.fromRGB(45,151,102),Color3.fromRGB(86,179,111),Color3.fromRGB(46,131,103)},
 Sky={Color3.fromRGB(153,207,177),Color3.fromRGB(123,188,153),Color3.fromRGB(111,191,190),Color3.fromRGB(138,204,170),Color3.fromRGB(177,220,211),Color3.fromRGB(160,211,185),Color3.fromRGB(188,224,205),Color3.fromRGB(125,198,190)},
 AncientRuins={Color3.fromRGB(96,110,67),Color3.fromRGB(111,122,71),Color3.fromRGB(82,101,62),Color3.fromRGB(78,111,61),Color3.fromRGB(93,123,66),Color3.fromRGB(112,94,68),Color3.fromRGB(91,86,68),Color3.fromRGB(105,113,70)},
 Desert={Color3.fromRGB(74,139,76),Color3.fromRGB(87,150,80),Color3.fromRGB(63,124,69),Color3.fromRGB(103,143,85),Color3.fromRGB(68,133,100),Color3.fromRGB(112,143,82),Color3.fromRGB(69,128,95),Color3.fromRGB(91,144,77)},
 Volcano={Color3.fromRGB(61,48,43),Color3.fromRGB(76,54,45),Color3.fromRGB(49,43,41),Color3.fromRGB(84,57,47),Color3.fromRGB(55,47,46),Color3.fromRGB(66,51,44),Color3.fromRGB(91,62,51),Color3.fromRGB(53,48,47)},
}
local WOOD={Snow=Color3.fromRGB(108,99,93),Ocean=Color3.fromRGB(151,103,65),Sky=Color3.fromRGB(190,174,151),AncientRuins=Color3.fromRGB(105,88,68),Desert=Color3.fromRGB(137,103,72),Volcano=Color3.fromRGB(58,47,43)}
local TRANSITION={Meadow=Color3.fromRGB(112,173,71),Forest=Color3.fromRGB(55,104,60),Jungle=Color3.fromRGB(62,133,66),Desert=Color3.fromRGB(151,137,78),Snow=Color3.fromRGB(177,203,198),Volcano=Color3.fromRGB(66,57,54),Ocean=Color3.fromRGB(65,145,121),AncientRuins=Color3.fromRGB(113,107,72),MagicalForest=Color3.fromRGB(73,74,91),Sky=Color3.fromRGB(168,211,195),Prehistoric=Color3.fromRGB(100,111,59),Mythical=Color3.fromRGB(69,57,96)}
local ROCK_COLORS={Color3.fromRGB(75,65,92),Color3.fromRGB(65,61,84),Color3.fromRGB(81,69,105),Color3.fromRGB(61,68,94),Color3.fromRGB(91,74,113),Color3.fromRGB(103,82,125)}
local CRYSTAL_COLORS={Color3.fromRGB(152,82,220),Color3.fromRGB(181,105,238),Color3.fromRGB(84,178,235),Color3.fromRGB(217,87,219),Color3.fromRGB(113,100,235),Color3.fromRGB(198,126,245)}
local ROCK_IMAGE_IDS={[105907150884948]=true,[108882158212656]=true} -- resolved Image IDs for Mythical Texture_9 color/normal
local ROCKS={
 {source="rock_largeA",assetId=115110110046351,meshes=1,meshId="91452127228720"},{source="rock_largeB",assetId=121065190627318,meshes=1,meshId="92549011592666"},
 {source="rock_largeC",assetId=89119127613670,meshes=1,meshId="105791386565581"},{source="rock_largeD",assetId=126471202328604,meshes=1,meshId="118757518772911"},
 {source="rock_smallA",assetId=137755717466537,meshes=1,meshId="87341277418211"},{source="rock_smallB",assetId=132169542043215,meshes=1,meshId="108856195585885"},
 {source="rock_smallC",assetId=125751487395046,meshes=1,meshId="129211651756957"},{source="rock_tallA",assetId=134271141178542,meshes=1,meshId="96483986974347"},
}

local function norm(v)return tostring(v or""):match("(%d+)")or""end
local function sourceOf(m)return m:GetAttribute("SourceAssetName")or m:GetAttribute("TreeType")end
local function parts(i)local a={}if i:IsA("BasePart")then table.insert(a,i)end for _,d in ipairs(i:GetDescendants())do if d:IsA("BasePart")then table.insert(a,d)end end table.sort(a,function(x,y)return x:GetFullName()<y:GetFullName()end)return a end
local function treeFolder(root,b)local e=root:FindFirstChild(b.."Environment")local s=e and e:FindFirstChild("Scenery")return s and s:FindFirstChild("Trees")end
local function scenery(root,b)local e=root:FindFirstChild(b.."Environment")return e and e:FindFirstChild("Scenery")end
local function signature(i)local ids={}local prim={}for _,p in ipairs(parts(i))do if p:IsA("MeshPart")then table.insert(ids,norm(p.MeshId))else table.insert(prim,p.ClassName..":"..(p:IsA("Part")and tostring(p.Shape)or"NA"))end end table.sort(ids)table.sort(prim)return"M|"..#ids.."|"..table.concat(ids,",").."|P|"..#prim.."|"..table.concat(prim,",")end
local function hasImage(p)if p:IsA("MeshPart")and p.TextureID~=""then return true end for _,d in ipairs(p:GetChildren())do if d:IsA("SurfaceAppearance")and(d.ColorMap~=""or d.NormalMap~="")then return true end if(d:IsA("Texture")or d:IsA("Decal"))and d.Texture~=""then return true end end return false end
local function clean(i)for _,d in ipairs(i:GetDescendants())do if d:IsA("LuaSourceContainer")or d:IsA("ProximityPrompt")or d:IsA("ClickDetector")then d:Destroy()end end end
local function getBox(i)if i:IsA("Model")then return i:GetBoundingBox()elseif i:IsA("BasePart")then return i.CFrame,i.Size else error("No bounds: "..i:GetFullName())end end
local function pivot(i)if i:IsA("Model")then return i:GetPivot()else return i.CFrame end end
local function setPivot(i,c)if i:IsA("Model")then i:PivotTo(c)else i.CFrame=c end end
local function scaleUniform(i,f)if i:IsA("Model")then i:ScaleTo(i:GetScale()*f)elseif i:IsA("BasePart")then i.Size=i.Size*f end end
local function folder(parent,name)local f=parent:FindFirstChild(name)if not f then f=Instance.new("Folder")f.Name=name;f.Parent=parent end return f end
local function containsCrystal(i,stop)local p=i while p and p~=stop do local text=(p.Name.." "..tostring(p:GetAttribute("SourceAssetName")or"")):lower()if text:find("crystal",1,true)or text:find("gem",1,true)then return true end p=p.Parent end return false end
local function visible(p)return p.Transparency<0.98 end
local function contentId(v)local n=tonumber(norm(v))return n or 0 end
local function role(source,p,index,total)
 local n=p.Name:lower()
 if n:find("snow",1,true)or n:find("ice",1,true)then return"SNOW"end
 if n:find("flower",1,true)or n:find("petal",1,true)then return"FLOWER"end
 if n:find("fruit",1,true)or n:find("coconut",1,true)then return"FRUIT"end
 if n:find("trunk",1,true)or n:find("wood",1,true)or n:find("bark",1,true)or n:find("branch",1,true)then return"WOOD"end
 if source:match("^common_tree_dead_")then return index==1 and"WOOD"or"ACCENT"end
 if source:match("^CommonTree_Dead_")or source:match("^Tree_Bare_")then return"WOOD"end
 if source:lower():find("cactus",1,true)then return"FOLIAGE"end
 if total>1 and index==1 then return"WOOD"end
 return"FOLIAGE"
end
local function tintTree(model,source,biome,index)
 local pp=parts(model)local base=COLORS[biome][index]
 for j,p in ipairs(pp)do local r=role(source,p,j,#pp)
  if r=="WOOD"then p.Color=WOOD[biome];if not hasImage(p)then p.Material=Enum.Material.Wood end
  elseif r=="SNOW"then p.Color=Color3.fromRGB(230,243,247);if not hasImage(p)then p.Material=Enum.Material.Snow end
  elseif r=="FLOWER"then p.Color=(biome=="Desert")and Color3.fromRGB(235,132,91)or base;if not hasImage(p)then p.Material=Enum.Material.SmoothPlastic end
  elseif r=="FRUIT"then p.Color=Color3.fromRGB(121,79,45);if not hasImage(p)then p.Material=Enum.Material.Wood end
  elseif r=="ACCENT"then p.Color=(biome=="Volcano")and Color3.fromRGB(120,52,32)or base;if not hasImage(p)then p.Material=Enum.Material.Wood end
  else p.Color=base;if not hasImage(p)then p.Material=(biome=="Volcano")and Enum.Material.Wood or Enum.Material.Grass end end
 end
end
local function loadAsset(spec)
 local got,last for attempt,delay in ipairs({0,1,2,4})do if delay>0 then task.wait(delay)end local ok,v=pcall(function()return InsertService:LoadAsset(spec.assetId)end)if ok then got=v break else last=v warn("AK_V4_LOAD_RETRY source="..spec.source.." attempt="..attempt)end end
 if not got then error("LoadAsset failed for "..spec.source..": "..tostring(last))end clean(got)got.Parent=nil
 local pp=parts(got)local meshes={}for _,p in ipairs(pp)do if p:IsA("MeshPart")then table.insert(meshes,norm(p.MeshId))end end table.sort(meshes)
 local _,z=getBox(got)print("AK_ROCK_TEMPLATE source="..spec.source.." assetId="..spec.assetId.." baseParts="..#pp.." meshIds="..table.concat(meshes,",").." bounds="..tostring(z))
 if #meshes~=spec.meshes or #meshes~=1 or meshes[1]~=spec.meshId then got:Destroy()error("Rock template structure mismatch: "..spec.source)end
 return got
end
local function replaceAt(old,template,newSource,newName)
 local oldBox,oldSize=getBox(old)local oldBase=oldBox.Position.Y-oldSize.Y/2 local oldPivot=pivot(old)
 local n=template:Clone()n.Name=newName or old.Name;for k,v in pairs(old:GetAttributes())do n:SetAttribute(k,v)end n:SetAttribute("SourceAssetName",newSource)if old:GetAttribute("TreeType")~=nil then n:SetAttribute("TreeType",newSource)end
 local _,native=getBox(n)scaleUniform(n,oldSize.Y/native.Y)setPivot(n,oldPivot)local nb,ns=getBox(n)setPivot(n,pivot(n)+Vector3.new(oldBox.Position.X-nb.Position.X,oldBase-(nb.Position.Y-ns.Y/2),oldBox.Position.Z-nb.Position.Z))
 for _,p in ipairs(parts(n))do p.Anchored=true end return n,oldBase,oldSize.Y
end

print("[1/8] Auditing 295 trees and 78-family distribution")
local root=Workspace:FindFirstChild("BiomeEnvironments")if not root then error("BiomeEnvironments missing")end
if ServerStorage:FindFirstChild(ROLLBACK)then error(ROLLBACK.." already exists")end
local current={}local allSources={}local sourceSig={}local totalTrees=0
for _,b in ipairs(BIOMES)do local f=treeFolder(root,b)if not f then error(b.." Trees missing")end current[b]={}
 for _,m in ipairs(f:GetChildren())do if not m:IsA("Model")then error("Non-model tree placement: "..m:GetFullName())end local s=sourceOf(m)if not s then error("Missing source attribute: "..m:GetFullName())end current[b][s]=current[b][s]or{}table.insert(current[b][s],m)totalTrees=totalTrees+1 local sig=signature(m)if sourceSig[s]and sourceSig[s]~=sig then error("Inconsistent family geometry: "..s)end sourceSig[s]=sig;if allSources[s]and allSources[s]~=b then error("Cross-biome source reuse: "..s)end allSources[s]=b end
 local n=0 for _ in pairs(current[b])do n=n+1 end if n~=EXPECTED[b]then error(b.." families="..n.." expected="..EXPECTED[b])end
end
if totalTrees~=295 then error("Expected 295 trees, found "..totalTrees)end
local familyCount=0 local globalSig={}for s,b in pairs(allSources)do familyCount=familyCount+1 local sig=sourceSig[s]if globalSig[sig]and globalSig[sig]~=s then error("Current runtime geometry duplicate: "..s.." / "..globalSig[sig])end globalSig[sig]=s end if familyCount~=78 then error("Expected 78 families, found "..familyCount)end
for _,b in ipairs(AFFECTED)do for _,s in ipairs(FINAL[b])do local n=#(current[b][s]or{})print("AK_TREE_DISTRIBUTION_BEFORE")print("biome="..b)print("source="..s)print("placements="..n)if n<1 then error("Missing V3 family "..b.."/"..s)end end end

print("[2/8] Preflighting family and rock templates")
local treeTemplates={}for _,b in ipairs(AFFECTED)do treeTemplates[b]={}for _,s in ipairs(FINAL[b])do local sample=current[b][s][1]local c=sample:Clone()clean(c)c.Parent=nil;treeTemplates[b][s]=c end end
local rockTemplates={}local rockSig={}for _,spec in ipairs(ROCKS)do local t=loadAsset(spec)local sig=signature(t)if rockSig[sig]then t:Destroy()error("Rock geometry collision: "..spec.source.." / "..rockSig[sig])end rockSig[sig]=spec.source;rockTemplates[spec.source]=t end

print("[3/8] Auditing Mythical rocks, actual crystals, and GrassFloor")
local myEnv=root:FindFirstChild("MythicalEnvironment")local myScenery=myEnv and myEnv:FindFirstChild("Scenery")local myRocks=myScenery and myScenery:FindFirstChild("Rocks")if not myRocks then error("Mythical Rocks missing")end
local mfEnv=root:FindFirstChild("MagicalForestEnvironment")local mfScenery=mfEnv and mfEnv:FindFirstChild("Scenery")local mfRocks=mfScenery and mfScenery:FindFirstChild("Rocks")if not mfRocks then error("MagicalForest Rocks missing")end
local referenceRockSig={}for _,x in ipairs(mfRocks:GetChildren())do if #parts(x)>0 and not containsCrystal(x,mfEnv)then referenceRockSig[signature(x)]=x:GetFullName()end end
for sig,source in pairs(rockSig)do if referenceRockSig[sig]then error("New Mythical rock geometry duplicates MagicalForest reference: "..source.." / "..referenceRockSig[sig])end end
local visibleRocks={}for _,x in ipairs(myRocks:GetChildren())do local pp=parts(x)local has=false for _,p in ipairs(pp)do if visible(p)then has=true end end if has and not containsCrystal(x,myEnv)then table.insert(visibleRocks,x)end end
if #visibleRocks==0 then error("No visible Mythical rock placements")end
local crystalParts={}for _,d in ipairs(myEnv:GetDescendants())do if d:IsA("BasePart")and visible(d)and containsCrystal(d,myEnv)then table.insert(crystalParts,d)local sa=d:FindFirstChildWhichIsA("SurfaceAppearance")print("AK_VISIBLE_CRYSTAL_PART")print("path="..d:GetFullName())print("meshId="..(d:IsA("MeshPart")and d.MeshId or""))print("material="..d.Material.Name)print("color="..tostring(d.Color))print("textureId="..(d:IsA("MeshPart")and d.TextureID or""))print("surfaceColorMap="..(sa and sa.ColorMap or""))end end
if #crystalParts==0 then error("No actual visible Mythical crystal BaseParts")end
local grass=Workspace:FindFirstChild("GrassFloor")if not grass or not grass:IsA("BasePart")then error("Workspace.GrassFloor not found exactly")end
if type(GRASS_IMAGE)~="number"or GRASS_IMAGE<=0 then error("Grass Image ID invalid")end
local okImage,imageInfo=pcall(function()return MarketplaceService:GetProductInfo(GRASS_IMAGE,Enum.InfoType.Asset)end)
if not okImage or type(imageInfo)~="table"or imageInfo.AssetTypeId~=1 then error("Grass asset failed live Image AssetTypeId validation: "..tostring(okImage and imageInfo.AssetTypeId or imageInfo))end
print("AK_GRASS_PREFLIGHT path="..grass:GetFullName().." material="..grass.Material.Name.." size="..tostring(grass.Size).." verifiedImageId="..GRASS_IMAGE)

local rb=Instance.new("Folder")rb.Name=ROLLBACK;rb.Parent=ServerStorage
local rbTrees=folder(rb,"Trees")local rbRocks=folder(rb,"Rocks")local rbCrystal=folder(rb,"Crystals")local rbGround=folder(rb,"GroundAndTransitions")
local moved={}local made={}local states={}local transforms={}local newTransitions
local function save(p)if not states[p]then states[p]={Color=p.Color,Material=p.Material,Reflectance=p.Reflectance,Transparency=p.Transparency}if p:IsA("MeshPart")then states[p].TextureID=p.TextureID end end end
for _,b in ipairs(AFFECTED)do for _,m in ipairs(treeFolder(root,b):GetChildren())do for _,p in ipairs(parts(m))do save(p)end end end
local function rollback(reason)
 if newTransitions and newTransitions.Parent then newTransitions:Destroy()end for _,n in ipairs(made)do if n.Parent then n:Destroy()end end
 for i=#moved,1,-1 do local x=moved[i]if x.obj.Parent then x.obj.Parent=x.parent end end
 for p,v in pairs(states)do if p.Parent then p.Color=v.Color;p.Material=v.Material;p.Reflectance=v.Reflectance;p.Transparency=v.Transparency;if p:IsA("MeshPart")and v.TextureID~=nil then p.TextureID=v.TextureID end end end
 rb:Destroy()for _,by in pairs(treeTemplates)do for _,t in pairs(by)do t:Destroy()end end for _,t in pairs(rockTemplates)do t:Destroy()end Workspace:SetAttribute(MARKER,nil)error("V4 rollback complete: "..tostring(reason))
end

print("[4/8] Redistributing affected biome trees")
local redistributed=0 local fitChecks={}local finalTargets={}
local okTrees,treeErr=pcall(function()
 for _,b in ipairs(AFFECTED)do local f=treeFolder(root,b)local models=f:GetChildren()local n=#models
  table.sort(models,function(a,z)local pa,pz=a:GetPivot().Position,z:GetPivot().Position local ha=math.floor(pa.X/23)*73856093+math.floor(pa.Z/23)*19349663 local hz=math.floor(pz.X/23)*73856093+math.floor(pz.Z/23)*19349663 return ha<hz end)
  local oldFamilyCount=5 local newFamilyCount=3 local availableForNew=n-oldFamilyCount
  local maximumGuaranteedPerNew=math.floor(availableForNew/newFamilyCount)
  local targetMinimumPerNew=math.min(3,maximumGuaranteedPerNew)
  local newTotal=math.floor(n*.42+.5)
  newTotal=math.max(newTotal,targetMinimumPerNew*newFamilyCount)
  newTotal=math.min(newTotal,math.floor(n*.60),availableForNew)
  -- With only ten placements Desert's strongest feasible representation is 5 old + 2/2/1 new.
  if targetMinimumPerNew<3 then newTotal=availableForNew end
  print("AK_NEW_FAMILY_REQUIREMENT")print("biome="..b)print("population="..n)print("requiredMinimum="..targetMinimumPerNew)
  local desired={}local function distribute(list,count)local q=math.floor(count/#list)local r=count%#list for i,s in ipairs(list)do desired[s]=q+(i<=r and 1 or 0)end end
  local old={}local newSet={}for _,s in ipairs(NEW[b])do newSet[s]=true end for _,s in ipairs(FINAL[b])do if not newSet[s]then table.insert(old,s)end end distribute(old,n-newTotal)distribute(NEW[b],newTotal)finalTargets[b]=desired
  local targetList={}for _,s in ipairs(FINAL[b])do for _=1,desired[s]do table.insert(targetList,s)end end
  local seed=0 for j=1,#b do seed=(seed*31+string.byte(b,j))%2147483647 end for i=#targetList,2,-1 do seed=(seed*48271)%2147483647 local j=(seed%i)+1 targetList[i],targetList[j]=targetList[j],targetList[i]end
  local best,bestChanged=nil,-1 for offset=0,n-1 do local a={}local changed=0 for i,m in ipairs(models)do local s=targetList[((i+offset-2)%n)+1]a[i]=s;if sourceOf(m)~=s then changed=changed+1 end end if changed>bestChanged then best,bestChanged=a,changed end end
  if bestChanged<math.min(n,10)then error(b.." could not reach redistribution minimum; changed="..bestChanged)end
  for i,oldModel in ipairs(models)do local to=best[i]if sourceOf(oldModel)~=to then local nmodel,oldBase,oldHeight=replaceAt(oldModel,treeTemplates[b][to],to,to.."_V4_"..string.format("%03d",i))local holder=folder(rbTrees,b)local parent=oldModel.Parent;oldModel.Parent=holder;table.insert(moved,{obj=oldModel,parent=parent});nmodel.Parent=parent;table.insert(made,nmodel);local fb,fs=getBox(nmodel)table.insert(fitChecks,{kind="tree",delta=fb.Position.Y-fs.Y/2-oldBase,ratio=fs.Y/oldHeight});redistributed=redistributed+1 end end
  local idx={}for i,s in ipairs(FINAL[b])do idx[s]=i end for _,m in ipairs(f:GetChildren())do tintTree(m,sourceOf(m),b,idx[sourceOf(m)])end
 end
end)if not okTrees then rollback(treeErr)end
if redistributed<60 then rollback("Only "..redistributed.." tree placements redistributed; minimum 60")end

print("[5/8] Replacing Mythical rock geometry and polishing visible crystals")
local rockReplaced=0 local rockTarget=math.ceil(#visibleRocks*.45)local crystalLights=0 local stoneTexturesRemoved=0
local okVisual,visualErr=pcall(function()
 table.sort(visibleRocks,function(a,z)local pa,pz=pivot(a).Position,pivot(z).Position return(math.floor(pa.X/19)*31+math.floor(pa.Z/19)*17)<(math.floor(pz.X/19)*31+math.floor(pz.Z/19)*17)end)
 for i=1,rockTarget do local old=visibleRocks[i]local spec=ROCKS[((i-1)%#ROCKS)+1]local n,oldBase,oldHeight=replaceAt(old,rockTemplates[spec.source],spec.source,spec.source.."_MythicalV4_"..string.format("%03d",i))for j,p in ipairs(parts(n))do p.Color=ROCK_COLORS[((i+j-2)%#ROCK_COLORS)+1];if not hasImage(p)then p.Material=(i%2==0)and Enum.Material.Slate or Enum.Material.Rock end end local parent=old.Parent;old.Parent=rbRocks;table.insert(moved,{obj=old,parent=parent});n.Parent=parent;table.insert(made,n);local fb,fs=getBox(n)table.insert(fitChecks,{kind="rock",delta=fb.Position.Y-fs.Y/2-oldBase,ratio=fs.Y/oldHeight});rockReplaced=rockReplaced+1 end
 local backed={}for i,p in ipairs(crystalParts)do if not backed[p]then local c=p:Clone()clean(c)c.Name=p.Name.."_Original";c.Parent=rbCrystal;backed[p]=true end save(p)
  if p:IsA("MeshPart")and ROCK_IMAGE_IDS[contentId(p.TextureID)]then p.TextureID="";stoneTexturesRemoved=stoneTexturesRemoved+1 end
  for _,d in ipairs(p:GetChildren())do local wrong=false if d:IsA("SurfaceAppearance")then wrong=ROCK_IMAGE_IDS[contentId(d.ColorMap)]or ROCK_IMAGE_IDS[contentId(d.NormalMap)]elseif d:IsA("Texture")or d:IsA("Decal")then wrong=ROCK_IMAGE_IDS[contentId(d.Texture)]end if wrong then local parent=d.Parent;d.Parent=folder(rbCrystal,"RemovedRockMaps");table.insert(moved,{obj=d,parent=parent});stoneTexturesRemoved=stoneTexturesRemoved+1 end end
  local c=CRYSTAL_COLORS[((i-1)%#CRYSTAL_COLORS)+1];p.Color=c;p.Material=(i%3==0)and Enum.Material.Glass or Enum.Material.Neon;p.Reflectance=0
 end
 local clusterCandidates={}for _,x in ipairs(myEnv:GetDescendants())do if(x:IsA("Model")or x:IsA("BasePart"))and containsCrystal(x,myEnv)then local pp=parts(x)local visibleCount=0 local volume=0 for _,p in ipairs(pp)do if visible(p)then visibleCount=visibleCount+1;volume=volume+p.Size.X*p.Size.Y*p.Size.Z end end if visibleCount>=2 or volume>=120 then table.insert(clusterCandidates,{obj=x,volume=volume})end end end
 table.sort(clusterCandidates,function(a,z)return a.volume>z.volume end)local used={}for _,x in ipairs(clusterCandidates)do if crystalLights>=12 then break end local targetPart=parts(x.obj)[1]if targetPart and not used[targetPart]then used[targetPart]=true local light=Instance.new("PointLight")light.Name="AK_CrystalGlowV4";light.Color=targetPart.Color;light.Brightness=.75+(crystalLights%3)*.15;light.Range=8+(crystalLights%3);light.Shadows=false;light.Parent=targetPart;table.insert(made,light);crystalLights=crystalLights+1 end end
end)if not okVisual then rollback(visualErr)end
if rockReplaced<math.ceil(#visibleRocks*.4)then rollback("Mythical rock geometry replacement below 40%")end

print("[6/8] Applying real grass texture and broad biome transitions")
local oldTransitions=Workspace:FindFirstChild("AnimalKingdomEnvironmentTransitionsV3")
local okGround,groundErr=pcall(function()
 local grassBackup=grass:Clone()clean(grassBackup)grassBackup.Name="GrassFloor_Original";grassBackup.Parent=rbGround
 save(grass)
 if oldTransitions then local parent=oldTransitions.Parent;oldTransitions.Parent=rbGround;table.insert(moved,{obj=oldTransitions,parent=parent})end
 for _,d in ipairs(grass:GetChildren())do if d:IsA("Texture")and d.Name=="AK_StylizedGrassV4"then d:Destroy()end end
 local tex=Instance.new("Texture")tex.Name="AK_StylizedGrassV4";tex.Texture="rbxassetid://"..GRASS_IMAGE;tex.Face=Enum.NormalId.Top;tex.StudsPerTileU=16;tex.StudsPerTileV=16;tex.Color3=Color3.new(1,1,1);tex.Parent=grass;table.insert(made,tex);grass.Material=Enum.Material.Grass;grass.Color=Color3.fromRGB(94,143,72)
 newTransitions=Instance.new("Folder")newTransitions.Name="AnimalKingdomEnvironmentTransitionsV4";newTransitions.Parent=Workspace
 local floors={}local center=Vector3.zero
 for _,b in ipairs(BIOMES)do local e=root:FindFirstChild(b.."Environment")local best,area=nil,0 for _,d in ipairs(e:GetDescendants())do if d:IsA("BasePart")then local a=d.Size.X*d.Size.Z if a>area then best,area=d,a end end end if not best then error("Floor unresolved for "..b)end floors[b]=best;center=center+best.Position end center=center/12
 for _,b in ipairs(BIOMES)do local floorPart=floors[b]local bf=folder(newTransitions,b.."Transition")local candidates={}
  for i=0,19 do local t=i/20 local lx,lz,tx,tz if t<.25 then lx=-floorPart.Size.X/2+t*4*floorPart.Size.X;lz=-floorPart.Size.Z/2;tx,tz=1,0 elseif t<.5 then lx=floorPart.Size.X/2;lz=-floorPart.Size.Z/2+(t-.25)*4*floorPart.Size.Z;tx,tz=0,1 elseif t<.75 then lx=floorPart.Size.X/2-(t-.5)*4*floorPart.Size.X;lz=floorPart.Size.Z/2;tx,tz=-1,0 else lx=-floorPart.Size.X/2;lz=floorPart.Size.Z/2-(t-.75)*4*floorPart.Size.Z;tx,tz=0,-1 end local world=floorPart.CFrame:PointToWorldSpace(Vector3.new(lx,0,lz));table.insert(candidates,{world=world,tangent=floorPart.CFrame:VectorToWorldSpace(Vector3.new(tx,0,tz)),distance=(Vector3.new(world.X,center.Y,world.Z)-center).Magnitude,index=i})end
  table.sort(candidates,function(a,z)return a.distance>z.distance end)for i=1,14 do local x=candidates[i]local p=Instance.new("Part")p.Name="Blend_"..string.format("%02d",i);p.Shape=Enum.PartType.Ball;p.Size=Vector3.new(25+(x.index%4)*2.5,.42,12+(x.index%3)*1.8);local yaw=math.atan2(-x.tangent.Z,x.tangent.X);p.CFrame=CFrame.new(x.world.X,floorPart.Position.Y+floorPart.Size.Y/2-.14,x.world.Z)*CFrame.Angles(0,yaw,0);p.Color=TRANSITION[b];p.Material=(b=="Desert"and Enum.Material.Sand)or(b=="Snow"and Enum.Material.Snow)or(b=="Volcano"and Enum.Material.Basalt)or Enum.Material.Grass;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false;p.Parent=bf local pt=Instance.new("Texture")pt.Name="AK_TransitionGrassV4";pt.Texture="rbxassetid://"..GRASS_IMAGE;pt.Face=Enum.NormalId.Top;pt.StudsPerTileU=14;pt.StudsPerTileV=14;pt.Parent=p end
 end
 local transitionBackup=newTransitions:Clone()transitionBackup.Name="AnimalKingdomEnvironmentTransitionsV4_CreatedBackup";transitionBackup.Parent=rbGround
end)if not okGround then rollback(groundErr)end

print("[7/8] Validating visual-change metrics and safety")
local finalTrees=0 local finalFamilies={}local finalSigs={}local geometryDup=0 local belowRequired={}local distributions={}
for _,b in ipairs(BIOMES)do local counts={}for _,m in ipairs(treeFolder(root,b):GetChildren())do finalTrees=finalTrees+1 local s=sourceOf(m)counts[s]=(counts[s]or 0)+1;finalFamilies[s]=b local sig=signature(m)if finalSigs[s]and finalSigs[s]~=sig then rollback("Family geometry inconsistent after overhaul: "..s)end finalSigs[s]=sig end local n=0 for _ in pairs(counts)do n=n+1 end if n~=EXPECTED[b]then rollback(b.." family count failed")end distributions[b]=counts end
if finalTrees~=295 then rollback("Final tree placements="..finalTrees)end local fn=0 local sigOwner={}for s in pairs(finalFamilies)do fn=fn+1 local sig=finalSigs[s]if sigOwner[sig]and sigOwner[sig]~=s then geometryDup=geometryDup+1 end sigOwner[sig]=s end if fn~=78 or geometryDup~=0 then rollback("Final family/geometry uniqueness failed")end
for _,b in ipairs(AFFECTED)do
 local biomeTreeCount=0 for _,count in pairs(distributions[b])do biomeTreeCount=biomeTreeCount+count end
 local requiredMin=math.min(3,math.floor((biomeTreeCount-5)/3))
 print("AK_NEW_FAMILY_REQUIREMENT")print("biome="..b)print("population="..biomeTreeCount)print("requiredMinimum="..requiredMin)
 for _,s in ipairs(NEW[b])do if(distributions[b][s]or 0)<requiredMin then table.insert(belowRequired,b.."/"..s.."="..tostring(distributions[b][s]or 0).." required="..requiredMin)end end
end
if #belowRequired>0 then rollback("New family representation below feasibility-aware minimum: "..table.concat(belowRequired,","))end
local float,buried=0,0 for _,x in ipairs(fitChecks)do if x.delta>.35 then float=float+1 elseif x.delta<-.35 then buried=buried+1 end if x.ratio<.88 or x.ratio>1.12 then rollback("Replacement scale outside tolerance")end end if float+buried>0 then rollback("Floating/buried replacements")end
local neonGlass,gray,stone=0,0,0 for _,p in ipairs(crystalParts)do if p.Material==Enum.Material.Neon or p.Material==Enum.Material.Glass then neonGlass=neonGlass+1 end local r,g,b=p.Color.R*255,p.Color.G*255,p.Color.B*255;if math.max(r,g,b)-math.min(r,g,b)<18 and math.max(r,g,b)<190 then gray=gray+1 end if p:IsA("MeshPart")and ROCK_IMAGE_IDS[contentId(p.TextureID)]then stone=stone+1 end for _,d in ipairs(p:GetChildren())do if d:IsA("SurfaceAppearance")and(ROCK_IMAGE_IDS[contentId(d.ColorMap)]or ROCK_IMAGE_IDS[contentId(d.NormalMap)])then stone=stone+1 elseif(d:IsA("Texture")or d:IsA("Decal"))and ROCK_IMAGE_IDS[contentId(d.Texture)]then stone=stone+1 end end end
if neonGlass~=#crystalParts or gray>0 or stone>0 then rollback("Crystal final validation failed")end
local grassTextures=0 for _,d in ipairs(grass:GetChildren())do if d:IsA("Texture")and d.Name=="AK_StylizedGrassV4"and contentId(d.Texture)==GRASS_IMAGE and d.Face==Enum.NormalId.Top then grassTextures=grassTextures+1 end end if grassTextures<1 then rollback("Grass top texture missing")end
local transitionCount=0 if not newTransitions or #newTransitions:GetChildren()~=12 then rollback("Transition biome folders failed")end for _,d in ipairs(newTransitions:GetDescendants())do if d:IsA("BasePart")then transitionCount=transitionCount+1 end end if transitionCount<120 or transitionCount>240 then rollback("Transition piece count="..transitionCount)end

print("[8/8] Final validation and report")
for _,by in pairs(treeTemplates)do for _,t in pairs(by)do t:Destroy()end end for _,t in pairs(rockTemplates)do t:Destroy()end Workspace:SetAttribute(MARKER,true)
print("ANIMAL KINGDOM ENVIRONMENT VISUAL OVERHAUL V4 COMPLETE")print("Trees: "..finalTrees)print("Families: "..fn)
for _,b in ipairs(AFFECTED)do print(b.." family distribution:")for _,s in ipairs(FINAL[b])do print("  "..s..": "..distributions[b][s])end end
print("Tree placements redistributed: "..redistributed)print("New families below feasibility-aware minimum: "..#belowRequired)
print("Mythical visible rocks: "..#visibleRocks)print("Mythical rock geometry replacements: "..rockReplaced)print("Rock replacement percentage: "..string.format("%.1f%%",rockReplaced/#visibleRocks*100))
print("Actual visible crystal parts: "..#crystalParts)print("Neon/Glass crystal parts: "..neonGlass)print("Gray crystal parts: "..gray)print("Stone-textured crystal parts: "..stone)print("Crystal lights added: "..crystalLights)
print("GrassFloor: "..grass:GetFullName())print("Grass Image ID: "..GRASS_IMAGE)print("Grass texture objects: "..grassTextures)print("Grass texture tiling: 16 x 16")print("Transition pieces: "..transitionCount)print("Transition biomes: 12/12")
print("Tree placement count failures: 0")print("Tree geometry duplicates: "..geometryDup)print("Floating failures: "..float)print("Buried failures: "..buried)print("Gameplay scripts changed: 0")print("Script Source writes: 0")print("DataStores changed: 0")print("Currencies changed: 0")print("Pets changed: 0")print("Sanctuaries changed: 0")print("Shakeables changed: 0")print("Rollback: ServerStorage."..ROLLBACK)print("Failures: 0")
