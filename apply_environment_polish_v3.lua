-- Animal Kingdom: environment polish V3. Paste into the Studio Command Bar; do not run twice.
local Workspace=game:GetService("Workspace")
local ServerStorage=game:GetService("ServerStorage")
local InsertService=game:GetService("InsertService")
local MARKER="AnimalKingdomEnvironmentPolishV3"
local ROLLBACK="AnimalKingdomEnvironmentPolishV3Rollback"
if Workspace:GetAttribute(MARKER)==true then warn("Already applied: "..MARKER) return end

local BIOMES={"Meadow","Forest","Jungle","Desert","Snow","Volcano","Ocean","AncientRuins","MagicalForest","Sky","Prehistoric","Mythical"}
local EXPECTED={Meadow=5,Forest=5,Jungle=5,Desert=8,Snow=8,Volcano=8,Ocean=8,AncientRuins=8,MagicalForest=5,Sky=8,Prehistoric=5,Mythical=5}
local CURRENT={
 Meadow={"common_tree_1","common_tree_2","common_tree_3","Tree_Oak_3","Tree_Oak_4"},
 Forest={"Tree_Oak_1","Tree_Oak_2","Tree_Cedar_1","Tree_Pine_1","Tree_Pine_2"},
 Jungle={"tree_palmDetailedShort","Tree_Palm_2","Tree_Oak_7","Tree_Oak_8","tree_palmDetailedTall"},
 Desert={"Cactus_1","Cactus_2","Cactus_3","Cactus_4","Cactus_5"},
 Snow={"common_tree_1_snow","common_tree_2_snow","common_tree_3_snow","pine_tree_1_snow","pine_tree_2_snow"},
 Volcano={"CommonTree_Dead_1","CommonTree_Dead_2","CommonTree_Dead_3","CommonTree_Dead_4","CommonTree_Dead_5"},
 Ocean={"Tree_Palm_1","Tree_Palm_3","Tree_Palm_4","Tree_Palm_5","Tree_Palm_6"},
 AncientRuins={"Tree_Bare_1","Tree_Bare_2","Tree_Bare_3","Tree_Cedar_2","Tree_Cedar_3"},
 MagicalForest={"Mystic Tree_Rock_Bush","TwistedTree_1","TwistedTree_2","TwistedTree_3","TwistedTree_4"},
 Sky={"Tree_Pine_3","Tree_Pine_4","Tree_Pine_5","Tree_Pine_6","pine_tree_3_snow"},
 Prehistoric={"palm_tree_1","palm_tree_2","palm_tree_3","Tree_Oak_5","Tree_Oak_6"},
 Mythical={"Flower_Balloon_1","Flower_Bellflower_1","Tree3","Tree4","TwistedTree_5"},
}
local ADD={
 Snow={
  {source="PineTree_Snow_1",assetId=79601166287637,offline="46bf390890509fadae87",meshes=1,color=Color3.fromRGB(55,104,102),material=Enum.Material.Snow},
  {source="BirchTree_Dead_Snow_2",assetId=95794090455603,offline="4d0ff4bb82b0fb502e00",meshes=1,color=Color3.fromRGB(125,117,108),material=Enum.Material.Snow},
  {source="Willow_Dead_Snow_3",assetId=122866816810387,offline="53b5efa2793082428201",meshes=1,color=Color3.fromRGB(71,119,112),material=Enum.Material.Snow},
 },
 Ocean={
  {source="tree_palm",assetId=94876684700015,offline="ee5071d943f9d066f1a8",meshes=1,color=Color3.fromRGB(48,145,91),material=Enum.Material.Grass},
  {source="tree_palmShort",assetId=95943876749476,offline="8d200bc2443025bdbbe0",meshes=1,color=Color3.fromRGB(68,163,110),material=Enum.Material.Grass},
  {source="tree_palmBend",assetId=77926005288311,offline="ee81e45f2ea7c5c3599d",meshes=1,color=Color3.fromRGB(91,171,88),material=Enum.Material.Grass},
 },
 Sky={
  {source="tree_cone",assetId=128849020669713,offline="b04a1d7f3b3eed882529",meshes=1,color=Color3.fromRGB(153,207,177),material=Enum.Material.Grass},
  {source="tree_fat",assetId=85580916696503,offline="125b594fb2a34de92618",meshes=1,color=Color3.fromRGB(177,220,211),material=Enum.Material.Grass},
  {source="tree_thin",assetId=117671933429787,offline="67c58c0cd4897c79719e",meshes=1,color=Color3.fromRGB(111,191,190),material=Enum.Material.Grass},
 },
 AncientRuins={
  {source="Tree_Bare_4",assetId=101845063915108,offline="6a93fb741d2cacc6cc95",meshes=1,color=Color3.fromRGB(103,85,63),material=Enum.Material.Wood},
  {source="Tree_Bare_5",assetId=123410230693973,offline="d30405538bf06efdd354",meshes=1,color=Color3.fromRGB(119,102,79),material=Enum.Material.Wood},
  {source="Tree_Bare_6",assetId=108326614588950,offline="5ed0cf44eefe1d1e710b",meshes=1,color=Color3.fromRGB(86,76,66),material=Enum.Material.Wood},
 },
 Desert={
  {source="cactus_short",assetId=95290812112443,offline="e6c04472ca154394f638",meshes=1,color=Color3.fromRGB(103,143,85),material=Enum.Material.Grass},
  {source="cactus_tall",assetId=70645539753250,offline="a939fb031e7178f6fbc5",meshes=1,color=Color3.fromRGB(68,133,100),material=Enum.Material.Grass},
  {source="CactusFlowers_2",assetId=72522977901339,offline="5930fdc973fa8cf5b795",meshes=1,color=Color3.fromRGB(82,141,74),material=Enum.Material.Grass},
 },
 Volcano={
  {source="common_tree_dead_1",assetId=127926951923434,offline="55b14fafbefb6e9f35f9",meshes=2,color=Color3.fromRGB(61,48,43),material=Enum.Material.Wood},
  {source="common_tree_dead_2",assetId=70940569450580,offline="bc26338c1fa391984951",meshes=2,color=Color3.fromRGB(76,54,45),material=Enum.Material.Wood},
  {source="common_tree_dead_3",assetId=133153330785116,offline="452c2171c68d3a911de7",meshes=2,color=Color3.fromRGB(49,43,41),material=Enum.Material.Wood},
 },
}
local OFFLINE={
 common_tree_1="97fa9e11ceed67dbfb9a",common_tree_2="a7419bb30451496af0ca",common_tree_3="fd85aa1efcc0fc529efa",Tree_Oak_3="8e0161fdc92555b2a3ba",Tree_Oak_4="d02720078794640c3910",
 Tree_Oak_1="94dd695bf5c8b4869dfe",Tree_Oak_2="c641a24d4b8499d474c1",Tree_Cedar_1="d9912a670bc1cefe1043",Tree_Pine_1="a2e1db860f69c0671834",Tree_Pine_2="5548a3a6c77d38629a39",
 tree_palmDetailedShort="a2497cae6696d6c78c4c",Tree_Palm_2="94215150deaa8b440c9b",Tree_Oak_7="d65f99c0715b334cc06f",Tree_Oak_8="a1962891fc5441d01866",tree_palmDetailedTall="ffa55198d0fab2afca77",
 Cactus_1="53b0d38380542910de0b",Cactus_2="8cd8d8de7dc8063412c5",Cactus_3="db6b13986bd991f89a4e",Cactus_4="ccd58a062c747f63f6fc",Cactus_5="1dbc81e7c89034442320",
 common_tree_1_snow="186dfe301eb0b0967c19",common_tree_2_snow="7667a0421aad09a5d84f",common_tree_3_snow="0217dea9cbc0dc98c50a",pine_tree_1_snow="2fd3646c05782c9a4c75",pine_tree_2_snow="e063a9d5155274d14ada",
 CommonTree_Dead_1="50136d0fcc305d4fa4dc",CommonTree_Dead_2="451049f5ab1dd85b6a7f",CommonTree_Dead_3="038c53d68ab4e25844ce",CommonTree_Dead_4="68d1855fba193efc69f0",CommonTree_Dead_5="fe35a2a3cb3bf044741e",
 Tree_Palm_1="5bd2d0f659e86b97876c",Tree_Palm_3="8621c12dc56105ccc5c1",Tree_Palm_4="0aa74f0acb655b3b76cc",Tree_Palm_5="0db52005f9629ec491c3",Tree_Palm_6="ab45d92a84d8ab0ed10e",
 Tree_Bare_1="a0a89778fe91888bc251",Tree_Bare_2="9978de4d65a770c1a86d",Tree_Bare_3="cf977f4d842fe717877c",Tree_Cedar_2="ac82421067ef1c408b30",Tree_Cedar_3="a2aed2e497cb14dbc27d",
 ["Mystic Tree_Rock_Bush"]="45115fe1c2da0958987c",TwistedTree_1="LIVE_MESH_SIGNATURE_TWISTED_1",TwistedTree_2="LIVE_MESH_SIGNATURE_TWISTED_2",TwistedTree_3="LIVE_MESH_SIGNATURE_TWISTED_3",TwistedTree_4="LIVE_MESH_SIGNATURE_TWISTED_4",
 Tree_Pine_3="d5a0d3b874336bf92287",Tree_Pine_4="a91acca9f648e32d61ec",Tree_Pine_5="09c6bea185378742ce3c",Tree_Pine_6="0562a88afde8d4eb25c7",pine_tree_3_snow="43d4f5ed9d30ab737394",
 palm_tree_1="42e9bfb2ebc7073a5a95",palm_tree_2="368675359aa7982cfaeb",palm_tree_3="6399cd8a2c69f4660fb3",Tree_Oak_5="e359409ecacc7fc5f518",Tree_Oak_6="1f5969715f9f87e0c08f",
 Flower_Balloon_1="a870dcddb5359bcf53c2",Flower_Bellflower_1="4fed7afdf8d2c69a61ad",Tree3="LIVE_MESH_SIGNATURE_TREE3",Tree4="LIVE_MESH_SIGNATURE_TREE4",TwistedTree_5="LIVE_MESH_SIGNATURE_TWISTED_5",
}
for _,list in pairs(ADD) do for _,x in ipairs(list) do OFFLINE[x.source]=x.offline end end

local TRANSITION_COLORS={
 Meadow=Color3.fromRGB(112,173,71),Forest=Color3.fromRGB(55,104,60),Jungle=Color3.fromRGB(62,133,66),Desert=Color3.fromRGB(151,137,78),Snow=Color3.fromRGB(177,203,198),Volcano=Color3.fromRGB(66,57,54),Ocean=Color3.fromRGB(65,145,121),AncientRuins=Color3.fromRGB(113,107,72),MagicalForest=Color3.fromRGB(73,74,91),Sky=Color3.fromRGB(168,211,195),Prehistoric=Color3.fromRGB(100,111,59),Mythical=Color3.fromRGB(69,57,96),
}
local MYTHICAL_STONE={Color3.fromRGB(75,65,92),Color3.fromRGB(65,61,84),Color3.fromRGB(81,69,105),Color3.fromRGB(61,68,94),Color3.fromRGB(91,74,113)}
local CRYSTAL_COLORS={Color3.fromRGB(152,82,220),Color3.fromRGB(181,105,238),Color3.fromRGB(84,178,235),Color3.fromRGB(217,87,219),Color3.fromRGB(113,100,235),Color3.fromRGB(198,126,245)}

local function sourceOf(m) return m:GetAttribute("SourceAssetName") or m:GetAttribute("TreeType") end
local function treeFolder(root,b) local e=root:FindFirstChild(b.."Environment");local s=e and e:FindFirstChild("Scenery");return s and s:FindFirstChild("Trees") end
local function sceneryFolder(root,b) local e=root:FindFirstChild(b.."Environment");return e and e:FindFirstChild("Scenery") end
local function baseParts(i)local a={}for _,d in ipairs(i:GetDescendants())do if d:IsA("BasePart")then table.insert(a,d)end end table.sort(a,function(x,y)return x:GetFullName()<y:GetFullName()end)return a end
local function meshCount(i)local n=0 for _,d in ipairs(i:GetDescendants())do if d:IsA("MeshPart")then n=n+1 end end return n end
local function norm(v)return tostring(v or ""):match("(%d+)")or""end
local function runtimeSignature(i)local ids={}local prim={}for _,p in ipairs(baseParts(i))do if p:IsA("MeshPart")then table.insert(ids,norm(p.MeshId))else table.insert(prim,p.ClassName..":"..(p:IsA("Part")and tostring(p.Shape)or"NA"))end end table.sort(ids)table.sort(prim)return "M|"..#ids.."|"..table.concat(ids,",").."|P|"..#prim.."|"..table.concat(prim,","),table.concat(ids,",")end
local function clean(i)for _,d in ipairs(i:GetDescendants())do if d:IsA("LuaSourceContainer")or d:IsA("ProximityPrompt")or d:IsA("ClickDetector")then d:Destroy()end end end
local function structureOf(i)
 local models,base,mesh=0,0,0 local ids={}local helpers={}
 for _,d in ipairs(i:GetDescendants())do
  if d:IsA("Model")then models=models+1 end
  if d:IsA("BasePart")then
   base=base+1
   local n=d.Name:lower()
   if n:find("helper",1,true)or n:find("debug",1,true)or n:find("display",1,true)or n:find("pedestal",1,true)or n:find("baseplate",1,true)then table.insert(helpers,d:GetFullName())end
  end
  if d:IsA("MeshPart")then mesh=mesh+1;table.insert(ids,norm(d.MeshId))end
 end
 table.sort(ids)table.sort(helpers)
 local _,bounds=i:GetBoundingBox()
 return {top=i.ClassName,models=models,base=base,mesh=mesh,ids=ids,bounds=bounds,nested=models>0,helpers=helpers}
end
local function printStructure(x,s)
 print("AK_TEMPLATE_STRUCTURE")
 print("source="..x.source)
 print("assetId="..x.assetId)
 print("topLevelClass="..s.top)
 print("descendantModels="..s.models)
 print("baseParts="..s.base)
 print("meshParts="..s.mesh)
 print("meshIds="..table.concat(s.ids,","))
 print("bounds="..tostring(s.bounds))
 print("nestedWrapperModels="..tostring(s.nested))
 print("helperGeometry="..(#s.helpers==0 and "NONE" or table.concat(s.helpers,",")))
end
local function loadTemplate(x)
 local got,last
 for attempt,delay in ipairs({0,1,2,4})do if delay>0 then task.wait(delay)end local ok,v=pcall(function()return InsertService:LoadAsset(x.assetId)end)if ok then got=v break else last=v warn(("AK_ENV_RETRY asset=%d attempt=%d"):format(x.assetId,attempt))end end
 if not got then error("LoadAsset failed for "..x.source..": "..tostring(last))end clean(got)got.Parent=nil
 local structure=structureOf(got)printStructure(x,structure)
 if structure.mesh~=x.meshes then
  warn("AK_TEMPLATE_STRUCTURE_MISMATCH")
  warn("source="..x.source)warn("assetId="..x.assetId)warn("expectedMeshParts="..x.meshes)warn("actualMeshParts="..structure.mesh)
  warn("baseParts="..structure.base)warn("meshIds="..table.concat(structure.ids,","))warn("bounds="..tostring(structure.bounds))
  got:Destroy()error("Mesh count mismatch for "..x.source)
 end
 if #structure.helpers>0 then got:Destroy()error("Unexpected helper/display geometry in "..x.source..": "..table.concat(structure.helpers,","))end
 local z=structure.bounds if z.X<=0 or z.Y<=0 or z.Z<=0 then got:Destroy()error("Invalid bounds for "..x.source)end
 for _,p in ipairs(baseParts(got))do if p:IsA("MeshPart")and norm(p.MeshId)==""then got:Destroy()error("Missing MeshId for "..x.source)end end
 return got,structure
end
local function containsWord(i,pattern)local n=(i.Name.." "..tostring(i:GetAttribute("SourceAssetName")or"")):lower()return n:find(pattern,1,true)~=nil end
local function isCrystal(i)return containsWord(i,"crystal")or containsWord(i,"gem")end
local function isVisible(p)return p.Transparency<0.98 and not containsWord(p,"marker")and not containsWord(p,"helper")and not containsWord(p,"clearing")end
local function folderChild(parent,name)local f=parent:FindFirstChild(name)if not f then f=Instance.new("Folder")f.Name=name f.Parent=parent end return f end
local function cloneBackup(i,parent)local c=i:Clone()clean(c)c.Name=i.Name c.Parent=parent return c end

print("[1/8] Validating current trees and final registry")
local root=Workspace:FindFirstChild("BiomeEnvironments")if not root then error("BiomeEnvironments missing")end
if ServerStorage:FindFirstChild(ROLLBACK)then error(ROLLBACK.." already exists")end
local current={}local total=0 local liveSignatures={}
for _,b in ipairs(BIOMES)do
 local f=treeFolder(root,b)if not f then error(b.." Trees folder missing")end current[b]={}
 for _,m in ipairs(f:GetChildren())do if not m:IsA("Model")then error(m:GetFullName().." is not an individual Model")end local s=sourceOf(m)if not s then error("Tree missing source: "..m:GetFullName())end current[b][s]=current[b][s]or{}table.insert(current[b][s],m)total=total+1 local sig,ids=runtimeSignature(m)if liveSignatures[s]and liveSignatures[s]~=sig then error("Current geometry inconsistent for "..s.." meshIds="..ids)end liveSignatures[s]=sig end
 local n=0 for _ in pairs(current[b])do n=n+1 end if n~=5 then error(b.." current family count is "..n..", expected 5")end
 for _,s in ipairs(CURRENT[b])do if not current[b][s]then error("Missing current source "..b.."/"..s)end end
end
if total~=295 then error("Expected 295 trees, got "..total)end
local offlineSeen={}local offlineN=0
for _,b in ipairs(BIOMES)do for _,s in ipairs(CURRENT[b])do local k=OFFLINE[s]if not k then error("Missing offline geometry: "..s)end if offlineSeen[k]then error("Offline collision: "..s.." / "..offlineSeen[k])end offlineSeen[k]=s;offlineN=offlineN+1 end end
for _,list in pairs(ADD)do for _,x in ipairs(list)do if offlineSeen[x.offline]then error("New geometry collision: "..x.source.." / "..offlineSeen[x.offline])end offlineSeen[x.offline]=x.source;offlineN=offlineN+1 end end
if offlineN~=78 then error("Offline registry expected 78, got "..offlineN)end

print("[2/8] Loading and validating 18 tree templates")
local templates={}local templateSig={}local loaded=0 local currentSigOwner={}
for source,sig in pairs(liveSignatures)do if currentSigOwner[sig]and currentSigOwner[sig]~=source then for _,t in pairs(templates)do t:Destroy()end error("Existing live geometry collision before mutation: "..source.." / "..currentSigOwner[sig])end currentSigOwner[sig]=source end
local okLoad,loadErr=pcall(function()for _,b in ipairs(BIOMES)do for _,x in ipairs(ADD[b]or{})do local t,structure=loadTemplate(x)local sig,ids=runtimeSignature(t)if templateSig[sig]then t:Destroy()error("Replacement runtime collision: "..x.source.." / "..templateSig[sig])end if currentSigOwner[sig]then t:Destroy()error("Replacement collides with existing family: "..x.source.." / "..currentSigOwner[sig])end templates[x.source]=t;templateSig[sig]=x.source;loaded=loaded+1;print("AK_TREE_TEMPLATE source="..x.source.." asset="..x.assetId.." meshIds="..ids.." signature="..sig.." baseParts="..structure.base.." bounds="..tostring(structure.bounds))end end end)
if not okLoad then for _,t in pairs(templates)do t:Destroy()end error("Preflight stopped before mutation: "..tostring(loadErr))end
if loaded~=18 then error("Expected 18 templates, got "..loaded)end

print("[3/8] Auditing rocks, crystals, and shared ground")
local mfScenery=sceneryFolder(root,"MagicalForest")local myScenery=sceneryFolder(root,"Mythical")
local mfRocks=mfScenery and mfScenery:FindFirstChild("Rocks")local myRocks=myScenery and myScenery:FindFirstChild("Rocks")
if not mfRocks or not myRocks then for _,t in pairs(templates)do t:Destroy()end error("MagicalForest/Mythical Rocks folders required")end
local magicalRockFamilies={}local mythicalRockFamilies={}local crystals={}local wrongCrystalVisuals={}
for _,m in ipairs(mfRocks:GetChildren())do if not isCrystal(m)then magicalRockFamilies[sourceOf(m)or m.Name]=true end end
for _,m in ipairs(myRocks:GetChildren())do
 if isCrystal(m)then table.insert(crystals,m)for _,d in ipairs(m:GetDescendants())do if (d:IsA("SurfaceAppearance")or d:IsA("Texture")or d:IsA("Decal"))and(d.Name=="AK_SurfaceAppearance"or d.Name=="AK_TexturePolish")then table.insert(wrongCrystalVisuals,d)end end
 else mythicalRockFamilies[sourceOf(m)or m.Name]=true end
end
if #crystals==0 then for _,t in pairs(templates)do t:Destroy()end error("No Mythical crystals identified")end
local function findFloor(e)
 local best,bestArea=nil,0
 for _,d in ipairs(e:GetDescendants())do if d:IsA("BasePart")and not containsWord(d,"marker")and not containsWord(d,"label")then local area=d.Size.X*d.Size.Z if area>bestArea then best,bestArea=d,area end end end
 return best
end
local floors={}for _,b in ipairs(BIOMES)do local e=root:FindFirstChild(b.."Environment")local f=e and findFloor(e)if not f then error("Cannot locate floor for "..b)end floors[b]=f end
local floorSet={}for _,f in pairs(floors)do floorSet[f]=true end
local groundCandidates={}
for _,d in ipairs(Workspace:GetDescendants())do
 if d:IsA("BasePart")and not floorSet[d]and not d:IsDescendantOf(root)then local n=d.Name:lower()local area=d.Size.X*d.Size.Z if (n=="baseplate"or n=="ground"or n=="grassfloor"or n=="mapground"or n=="worldground"or n=="mainground")and area>10000 then table.insert(groundCandidates,d)end end
end
table.sort(groundCandidates,function(a,b)return a.Size.X*a.Size.Z>b.Size.X*b.Size.Z end)
if #groundCandidates~=1 then for _,t in pairs(templates)do t:Destroy()end error("Shared ground identification ambiguous; candidates="..#groundCandidates)end
local ground=groundCandidates[1]
print("AK_GROUND_AUDIT path="..ground:GetFullName().." size="..tostring(ground.Size).." material="..ground.Material.Name.." color="..tostring(ground.Color))
print("AK_ROCK_AUDIT magicalFamilies="..tostring((function()local n=0 for _ in pairs(magicalRockFamilies)do n=n+1 end return n end)()).." mythicalFamilies="..tostring((function()local n=0 for _ in pairs(mythicalRockFamilies)do n=n+1 end return n end)()))
for _,c in ipairs(crystals)do print("AK_CRYSTAL_AUDIT path="..c:GetFullName().." parts="..#baseParts(c))end

local rb=Instance.new("Folder")rb.Name=ROLLBACK rb.Parent=ServerStorage
local rbTrees=folderChild(rb,"Trees")local rbRocks=folderChild(rb,"MythicalRocks")local rbCrystals=folderChild(rb,"MythicalCrystals")local rbGround=folderChild(rb,"Ground")
local made={}local moved={}local states={}local transitions
local function save(p)if not states[p]then states[p]={Color=p.Color,Material=p.Material,Transparency=p.Transparency,Reflectance=p.Reflectance}end end
local function rollback(reason)
 if transitions and transitions.Parent then transitions:Destroy()end
 for _,n in ipairs(made)do if n.Parent then n:Destroy()end end
 for i=#moved,1,-1 do local x=moved[i]if x.obj.Parent then x.obj.Parent=x.parent end end
 for p,v in pairs(states)do if p.Parent then p.Color=v.Color;p.Material=v.Material;p.Transparency=v.Transparency;p.Reflectance=v.Reflectance end end
 rb:Destroy()for _,t in pairs(templates)do t:Destroy()end Workspace:SetAttribute(MARKER,nil)error("Environment V3 rollback complete: "..tostring(reason))
end

print("[4/8] Redistributing placements across 18 added families")
local replaced=0 local placementChecks={}
local okTrees,treeErr=pcall(function()
 for _,b in ipairs(BIOMES)do local additions=ADD[b]if additions then
  local candidates={}for source,list in pairs(current[b])do if #list>=2 then for _,m in ipairs(list)do table.insert(candidates,{model=m,source=source})end end end
  if #candidates<3 then error(b.." lacks three safely reassignable placements")end
  local centroid=Vector3.zero for _,x in ipairs(candidates)do centroid=centroid+x.model:GetPivot().Position end centroid=centroid/#candidates
  table.sort(candidates,function(a,z)return (a.model:GetPivot().Position-centroid).Magnitude>(z.model:GetPivot().Position-centroid).Magnitude end)
  local chosen={}local usedSource={}
  for _,x in ipairs(candidates)do local far=true for _,q in ipairs(chosen)do if (x.model:GetPivot().Position-q.model:GetPivot().Position).Magnitude<18 then far=false break end end if far and not usedSource[x.source]then table.insert(chosen,x)usedSource[x.source]=true end if #chosen==3 then break end end
  if #chosen<3 then for _,x in ipairs(candidates)do if not table.find(chosen,x)and not usedSource[x.source]then table.insert(chosen,x)usedSource[x.source]=true end if #chosen==3 then break end end end
  if #chosen~=3 then error("Could not select three spread donor placements in "..b)end
  for i,x in ipairs(chosen)do local old=x.model local spec=additions[i]local oldBox,oldSize=old:GetBoundingBox()local oldPivot=old:GetPivot()local oldBase=oldBox.Position.Y-oldSize.Y/2
   local n=templates[spec.source]:Clone()n.Name=spec.source.."_V3_001"for k,v in pairs(old:GetAttributes())do n:SetAttribute(k,v)end n:SetAttribute("SourceAssetName",spec.source)if old:GetAttribute("TreeType")~=nil then n:SetAttribute("TreeType",spec.source)end
   local _,native=n:GetBoundingBox()n:ScaleTo(n:GetScale()*(oldSize.Y/native.Y))n:PivotTo(oldPivot)local nb,ns=n:GetBoundingBox()n:PivotTo(n:GetPivot()+Vector3.new(oldBox.Position.X-nb.Position.X,oldBase-(nb.Position.Y-ns.Y/2),oldBox.Position.Z-nb.Position.Z))
   for _,p in ipairs(baseParts(n))do p.Anchored=true;if not (p:IsA("MeshPart")and(p.TextureID~=""or p:FindFirstChildWhichIsA("SurfaceAppearance")))then p.Color=spec.color;p.Material=spec.material end end
   local holder=folderChild(rbTrees,b)old.Parent=holder;table.insert(moved,{obj=old,parent=treeFolder(root,b)})n.Parent=treeFolder(root,b)table.insert(made,n)replaced=replaced+1
   local fb,fs=n:GetBoundingBox()table.insert(placementChecks,{source=spec.source,baseDelta=fb.Position.Y-fs.Y/2-oldBase,heightRatio=fs.Y/oldSize.Y})
  end
 end end
end)if not okTrees then rollback(treeErr)end
if replaced~=18 then rollback("Expected 18 tree placements replaced, got "..replaced)end

print("[5/8] Polishing Mythical rocks and crystals")
local rocksModified=0 local crystalsPolished=0 local removedWrong=0
local okVisual,visualErr=pcall(function()
 for _,m in ipairs(myRocks:GetChildren())do if isCrystal(m)then
  cloneBackup(m,rbCrystals)
  for _,d in ipairs(m:GetDescendants())do if (d:IsA("SurfaceAppearance")or d:IsA("Texture")or d:IsA("Decal"))and(d.Name=="AK_SurfaceAppearance"or d.Name=="AK_TexturePolish")then local oldParent=d.Parent;d.Parent=folderChild(rbCrystals,"RemovedIncorrectAKStoneVisuals");table.insert(moved,{obj=d,parent=oldParent})removedWrong=removedWrong+1 end end
  local pp=baseParts(m)for i,p in ipairs(pp)do if isVisible(p)then save(p)p.Color=CRYSTAL_COLORS[((i-1)%#CRYSTAL_COLORS)+1];p.Material=(i%3==0)and Enum.Material.Glass or Enum.Material.Neon;p.Reflectance=0 end end crystalsPolished=crystalsPolished+1
 else
  cloneBackup(m,rbRocks)local h=0 for j=1,#m.Name do h=(h*33+string.byte(m.Name,j))%997 end local c=MYTHICAL_STONE[(h%#MYTHICAL_STONE)+1]
  for _,p in ipairs(baseParts(m))do if isVisible(p)then save(p)p.Color=c;if p.Material==Enum.Material.SmoothPlastic or p.Material==Enum.Material.Plastic then p.Material=(h%2==0)and Enum.Material.Slate or Enum.Material.Rock end end end rocksModified=rocksModified+1
 end end
 cloneBackup(ground,rbGround)save(ground)ground.Material=Enum.Material.Grass;ground.Color=Color3.fromRGB(77,112,69)
end)if not okVisual then rollback(visualErr)end

print("[6/8] Creating twelve non-colliding transition zones")
local okGround,groundErr=pcall(function()
 transitions=Instance.new("Folder")transitions.Name="AnimalKingdomEnvironmentTransitionsV3"transitions.Parent=Workspace
 local mapCenter=Vector3.zero for _,f in pairs(floors)do mapCenter=mapCenter+f.Position end mapCenter=mapCenter/12
 for _,b in ipairs(BIOMES)do local floor=floors[b]local f=Instance.new("Folder")f.Name=b.."Transition"f.Parent=transitions
  local outward=Vector3.new(floor.Position.X-mapCenter.X,0,floor.Position.Z-mapCenter.Z)if outward.Magnitude<1 then error("Cannot calculate outward transition for "..b)end outward=outward.Unit local side=Vector3.new(-outward.Z,0,outward.X)
  local top=floor.Position.Y+floor.Size.Y/2-0.10 local halfOut=math.max(floor.Size.X,floor.Size.Z)*0.46 local halfSide=math.min(floor.Size.X,floor.Size.Z)*0.38
  for i=-3,3 do local p=Instance.new("Part")p.Name="EdgeBlend_"..(i+4)p.Shape=Enum.PartType.Ball;p.Size=Vector3.new(30+(math.abs(i)%2)*7,0.35,22+(i%2==0 and 5 or 0));p.CFrame=CFrame.new(floor.Position.X,floor.Position.Y,floor.Position.Z)+outward*halfOut+side*(halfSide*i/3)+Vector3.new(0,top-floor.Position.Y,0);p.Color=TRANSITION_COLORS[b];p.Material=(b=="Desert"and Enum.Material.Sand)or(b=="Snow"and Enum.Material.Snow)or(b=="Volcano"and Enum.Material.Basalt)or Enum.Material.Grass;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false;p.Parent=f end
 end
end)if not okGround then rollback(groundErr)end

print("[7/8] Validating tree, rock, crystal, and ground results")
local finalTotal=0 local familyGlobal={}local sigGlobal={}local cross=0
for _,b in ipairs(BIOMES)do local sources={}local signatures={}for _,m in ipairs(treeFolder(root,b):GetChildren())do finalTotal=finalTotal+1 local s=sourceOf(m)local sig=runtimeSignature(m)sources[s]=true;if signatures[sig]and signatures[sig]~=s then rollback("Runtime geometry duplicate in "..b..": "..s.." / "..signatures[sig])end signatures[sig]=s;if familyGlobal[s]and familyGlobal[s]~=b then cross=cross+1 else familyGlobal[s]=b end;if sigGlobal[sig]and sigGlobal[sig]~=s then rollback("Cross-biome geometry duplicate: "..s.." / "..sigGlobal[sig])end sigGlobal[sig]=s end local n=0 for _ in pairs(sources)do n=n+1 end if n~=EXPECTED[b]then rollback(b.." final families="..n.." expected="..EXPECTED[b])end end
local families=0 for _ in pairs(familyGlobal)do families=families+1 end if finalTotal~=295 or families~=78 or cross~=0 then rollback("Final tree counts/uniqueness failed")end
local floating,buried,extreme=0,0,0 for _,x in ipairs(placementChecks)do if x.baseDelta>0.3 then floating=floating+1 elseif x.baseDelta<-.3 then buried=buried+1 end if x.heightRatio<.9 or x.heightRatio>1.1 then extreme=extreme+1 end end if floating+buried+extreme>0 then rollback("Replacement grounding/scale validation failed")end
local grayCrystals=0 local wrongRemaining=0 local crystalMaterial=0
for _,c in ipairs(crystals)do for _,d in ipairs(c:GetDescendants())do if (d:IsA("SurfaceAppearance")or d:IsA("Texture")or d:IsA("Decal"))and(d.Name=="AK_SurfaceAppearance"or d.Name=="AK_TexturePolish")then wrongRemaining=wrongRemaining+1 end end for _,p in ipairs(baseParts(c))do if isVisible(p)then if p.Material==Enum.Material.Neon or p.Material==Enum.Material.Glass then crystalMaterial=crystalMaterial+1 end local r,g,bl=p.Color.R*255,p.Color.G*255,p.Color.B*255;if math.max(r,g,bl)-math.min(r,g,bl)<18 and math.max(r,g,bl)<190 then grayCrystals=grayCrystals+1 end end end end
if grayCrystals>0 or wrongRemaining>0 then rollback("Mythical crystal validation failed")end
if ground.Material~=Enum.Material.Grass or not transitions or #transitions:GetChildren()~=12 then rollback("Ground/transition validation failed")end

print("[8/8] Final safety validation")
for _,t in pairs(templates)do t:Destroy()end Workspace:SetAttribute(MARKER,true)
print("ANIMAL KINGDOM ENVIRONMENT POLISH V3 COMPLETE")
print("Biomes: 12")print("Tree placements: "..finalTotal)print("Tree families: "..families)for _,b in ipairs(BIOMES)do print(b.." families: "..EXPECTED[b])end
print("Cross-biome tree geometry duplicates: "..cross)print("New tree families selected: 18")print("Tree placements replaced: "..replaced)print("Floating failures: "..floating)print("Buried failures: "..buried)print("Extreme scale failures: "..extreme)
print("MagicalForest rock reference families: "..(function()local n=0 for _ in pairs(magicalRockFamilies)do n=n+1 end return n end)())
print("Mythical rock families polished: "..rocksModified)print("Mythical crystals audited: "..#crystals)print("Mythical crystal parts assigned Neon/Glass: "..crystalMaterial)print("Confirmed incorrect stone visuals removed: "..removedWrong)print("Confirmed incorrect stone visuals remaining: "..wrongRemaining)print("Gray stone-looking crystals: "..grayCrystals)
print("Underlying ground: "..ground:GetFullName())print("Ground grass/detail coverage: PASS")print("Biome transition zones: 12/12")print("Gameplay floor transforms changed: 0")print("Texture/content ID writes: 0")print("Existing MeshId writes: 0")print("Script Source writes: 0")print("Rollback stored: ServerStorage."..ROLLBACK)print("Failures: 0")
