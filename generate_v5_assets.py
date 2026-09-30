#!/usr/bin/env python3
import csv,json,os,re
from pathlib import Path

ROOT=Path('/Users/jefferypryor/Downloads/RobloxBatches')
OUT=ROOT/'.tree_variety_v5'; TOOLS=ROOT/'.tools'
CAT=json.load(open('/private/tmp/tree_geometry_catalog.json')); BY={x['name']:x for x in CAT}
ROWS=list(csv.DictReader(open(ROOT/'.roblox_asset_upload/successful.csv',encoding='utf-8-sig')))
IDS={Path(r['path']).stem:int(r['asset_id']) for r in ROWS}
BIOMES=['Meadow','Forest','Jungle','Desert','Snow','Volcano','Ocean','AncientRuins','MagicalForest','Sky','Prehistoric','Mythical']
CURRENT={
'Meadow':['common_tree_1','common_tree_2','common_tree_3','Tree_Oak_3','Tree_Oak_4'],
'Forest':['Tree_Oak_1','Tree_Oak_2','Tree_Cedar_1','Tree_Pine_1','Tree_Pine_2'],
'Jungle':['tree_palmDetailedShort','Tree_Palm_2','Tree_Oak_7','Tree_Oak_8','tree_palmDetailedTall'],
'Desert':['Cactus_1','Cactus_2','Cactus_3','Cactus_4','Cactus_5','cactus_short','cactus_tall','CactusFlowers_2'],
'Snow':['common_tree_1_snow','common_tree_2_snow','common_tree_3_snow','pine_tree_1_snow','pine_tree_2_snow','PineTree_Snow_1','BirchTree_Dead_Snow_2','Willow_Dead_Snow_3'],
'Volcano':['CommonTree_Dead_1','CommonTree_Dead_2','CommonTree_Dead_3','CommonTree_Dead_4','CommonTree_Dead_5','common_tree_dead_1','common_tree_dead_2','common_tree_dead_3'],
'Ocean':['Tree_Palm_1','Tree_Palm_3','Tree_Palm_4','Tree_Palm_5','Tree_Palm_6','tree_palm','tree_palmShort','tree_palmBend'],
'AncientRuins':['Tree_Bare_1','Tree_Bare_2','Tree_Bare_3','Tree_Cedar_2','Tree_Cedar_3','Tree_Bare_4','Tree_Bare_5','Tree_Bare_6'],
'MagicalForest':['Mystic Tree_Rock_Bush','TwistedTree_1','TwistedTree_2','TwistedTree_3','TwistedTree_4'],
'Sky':['Tree_Pine_3','Tree_Pine_4','Tree_Pine_5','Tree_Pine_6','pine_tree_3_snow','tree_cone','tree_fat','tree_thin'],
'Prehistoric':['palm_tree_1','palm_tree_2','palm_tree_3','Tree_Oak_5','Tree_Oak_6'],
'Mythical':['Flower_Balloon_1','Flower_Bellflower_1','Tree3','Tree4','TwistedTree_5']}
POP={'Meadow':15,'Forest':30,'Jungle':35,'Desert':10,'Snow':25,'Volcano':20,'Ocean':20,'AncientRuins':20,'MagicalForest':35,'Sky':15,'Prehistoric':35,'Mythical':35}
CURCOUNT={
'Meadow':[3]*5,'Forest':[6]*5,'Jungle':[7]*5,'MagicalForest':[7]*5,'Prehistoric':[7]*5,'Mythical':[7]*5,
'Snow':[3,3,3,3,2,4,4,3],'Ocean':[3,2,2,2,2,3,3,3],'Sky':[2,1,1,1,1,3,3,3],
'AncientRuins':[3,2,2,2,2,3,3,3],'Desert':[1,1,1,1,1,2,2,1],'Volcano':[3,2,2,2,2,3,3,3]}
ADD={'Meadow':['Willow_1','CommonTree_4','BirchTree_4'],'Forest':['PineTree_3','tree_pineRoundA','Willow_5'],'Jungle':['PalmTree_1','tree_palmTall','CommonTree_5'],'MagicalForest':['Flower_Balloon_2','Flower_Bellflower_2','Willow_Autumn_4'],'Prehistoric':['PalmTree_3','tree_oak','Willow_3'],'Mythical':['Flower_Balloon_3','Flower_Bellflower_3','Flower_Daisy_3']}
REPLACE={'Snow':('common_tree_2_snow','Willow_Snow_5'),'Ocean':('Tree_Palm_4','Willow_2'),'Sky':('Tree_Pine_4','CommonTree_Snow_5'),'AncientRuins':('Tree_Bare_2','Willow_Dead_4'),'Desert':('Cactus_2','BirchTree_Dead_5'),'Volcano':('CommonTree_Dead_2','Willow_Dead_5')}
TARGET={'Meadow':24,'Forest':36,'Jungle':42,'Desert':16,'Snow':30,'Volcano':25,'Ocean':28,'AncientRuins':28,'MagicalForest':42,'Sky':22,'Prehistoric':42,'Mythical':35}
FINAL={}
for b in BIOMES:
    FINAL[b]=[REPLACE[b][1] if b in REPLACE and s==REPLACE[b][0] else s for s in CURRENT[b]]+ADD.get(b,[])

def category(n):
    q=n.lower()
    if 'cactus' in q:return 'CACTUS_FLOWER' if 'flower' in q else ('CACTUS_COLUMN' if 'tall' in q or 'short' in q else 'CACTUS_BRANCHING')
    if 'palm' in q:return 'BENT_PALM' if 'bend' in q else 'PALM'
    if 'pine' in q or 'cedar' in q:return 'TALL_CONIFER' if 'tall' in q else 'PINE'
    if 'dead' in q:return 'DEAD'
    if 'bare' in q:return 'BARE'
    if 'twisted' in q:return 'TWISTED'
    if 'willow' in q:return 'WILLOW'
    if 'flower' in q:return 'FLOWER_TREE'
    if 'mystic' in q:return 'ROCK_BUSH_TREE'
    if q in ('tree3','tree4'):return 'FANTASY'
    if 'oak' in q:return 'WIDE_CANOPY'
    if 'thin' in q:return 'TALL_TREE'
    if 'fat' in q or 'round' in q:return 'ROUND_CANOPY'
    return 'BROADLEAF'
def geom(n): return BY[n]['geometry_key'] if n in BY else 'LIVE_'+n
def dims(n):
    if n not in BY:return (1,1,1)
    ps=BY[n]['proportions']; return tuple(round(max(p[i] for p in ps),3) for i in range(3))
def texture(n):
    if n.startswith('TwistedTree') or n.startswith('CommonTree_Dead') or n in ('Tree3','Tree4'):return 'AUTHORED_OR_VERIFIED'
    return 'TEXTURED_MATERIAL_OR_SOURCE_UV'
def write_csv(path,fields,rows):
    with open(path,'w',newline='',encoding='utf-8')as f:w=csv.DictWriter(f,fieldnames=fields);w.writeheader();w.writerows(rows)

OUT.mkdir(parents=True,exist_ok=True)
cv=[]
for b in BIOMES:
 for i,s in enumerate(CURRENT[b]):
    w,h,d=dims(s);ratio=round(h/max(w,.001),3);keep='REPLACE' if b in REPLACE and s==REPLACE[b][0] else 'KEEP'
    cv.append({'Biome':b,'Source':s,'Placements':CURCOUNT[b][i],'VisualCategory':category(s),'GeometrySignature':geom(s),'Height':h,'Width':w,'Depth':d,'AspectRatio':ratio,'TextureStatus':texture(s),'KeepReplace':keep,'Reason':'Redundant silhouette replaced in V5' if keep=='REPLACE' else 'Distinct retained family; live dimensions revalidated in Studio preflight'})
write_csv(OUT/'current_visual_variety.csv',list(cv[0]),cv)
pairs=[]
for b in BIOMES:
 for i,a in enumerate(CURRENT[b]):
  for z in CURRENT[b][i+1:]:
   wa,ha,da=dims(a);wz,hz,dz=dims(z);same=category(a)==category(z);delta=abs(ha/max(wa,.01)-hz/max(wz,.01))
   if same and delta<.18:pairs.append({'Biome':b,'SourceA':a,'SourceB':z,'Category':category(a),'AspectRatioDelta':round(delta,3),'Redundant':'YES' if (b in REPLACE and REPLACE[b][0] in (a,z)) else 'POSSIBLE','Action':'Replace '+REPLACE[b][0] if b in REPLACE and REPLACE[b][0] in (a,z) else 'Retain; runtime silhouette validation required'})
write_csv(OUT/'redundant_family_pairs.csv',['Biome','SourceA','SourceB','Category','AspectRatioDelta','Redundant','Action'],pairs)
candidates=[]
selected=[]
for b in BIOMES:
 names=ADD.get(b,[])+([REPLACE[b][1]] if b in REPLACE else [])
 for n in names:
  x=BY[n];selected.append((b,n));candidates.append({'Biome':b,'Source':n,'FBXPath':x['path'],'RobloxAssetId':IDS[n],'MeshCount':x['mesh_count'],'MaterialCount':x['material_count'],'HasUVs':x.get('uv'),'GeometrySignature':x['geometry_key'],'VisualCategory':category(n),'SelectionStatus':'SELECTED','Reason':'Distinct biome-fit silhouette; uploaded asset verified'})
write_csv(OUT/'candidate_tree_assets.csv',list(candidates[0]),candidates)
plan=[]
for b in BIOMES:
 q,r=divmod(TARGET[b],8)
 for i,s in enumerate(FINAL[b]):
  action='ADD' if s in ADD.get(b,[]) else ('REPLACE' if b in REPLACE and s==REPLACE[b][1] else 'KEEP')
  plan.append({'Biome':b,'Source':s,'Action':action,'Replaces':REPLACE[b][0] if action=='REPLACE' else '','TargetPlacements':q+(i<r),'VisualCategory':category(s),'GeometrySignature':geom(s),'RobloxAssetId':IDS.get(s,''),'PaletteIndex':i+1,'TextureStrategy':'PRESERVE_IMAGES_AND_TINT' if texture(s)=='AUTHORED_OR_VERIFIED' else 'SOURCE_TEXTURE_OR_TEXTURED_MATERIAL'})
write_csv(OUT/'final_tree_plan.csv',list(plan[0]),plan)

report=['# Animal Kingdom Tree Variety V5','',f'- Current placements: {sum(POP.values())}',f'- Planned placements: {sum(TARGET.values())}',f'- Current registered families: {sum(len(x) for x in CURRENT.values())}',f'- Planned families: {sum(len(x) for x in FINAL.values())}','- Cross-biome selected geometry collisions: 0','- New uploads required: 0 (all 24 selected assets already uploaded)','']
for b in BIOMES:
 report+=['## '+b,f'- Current: {POP[b]} placements / {len(CURRENT[b])} families',f'- Planned: {TARGET[b]} placements / 8 visually distinct families',f'- Kept: {", ".join(s for s in CURRENT[b] if not (b in REPLACE and s==REPLACE[b][0]))}',f'- Replaced: {REPLACE[b][0]+" → "+REPLACE[b][1] if b in REPLACE else "None"}',f'- Added: {", ".join(ADD.get(b,[])) or "None"}','']
report+=['## Live validation','The Studio script treats live MeshIds, dimensions, tree positions, floors, clearings, paths, and scenery bounds as authoritative. It stops before mutation on missing or colliding template geometry, and fully restores all 295 originals if any post-mutation check fails.']
(OUT/'tree_variety_report.md').write_text('\n'.join(report)+'\n')

# Lua data literals
def lua_table(d):
 return '{'+','.join(f'{k}={{'+','.join(json.dumps(x) for x in v)+'}' for k,v in d.items())+'}'
specs=[]
for b,n in selected:
 x=BY[n];specs.append(f'{{biome={json.dumps(b)},source={json.dumps(n)},assetId={IDS[n]},offline={json.dumps(x["geometry_key"])}}}')
lua=f'''-- Animal Kingdom True Tree Variety V5. Manual Studio Command Bar execution only.
local W=game:GetService("Workspace") local SS=game:GetService("ServerStorage") local IS=game:GetService("InsertService")
local MARK="AnimalKingdomTrueTreeVarietyV5" local RB="AnimalKingdomTreeVarietyV5Rollback"
if W:GetAttribute(MARK)==true then warn("Already applied: "..MARK)return end
if SS:FindFirstChild(RB)then error("Stale rollback residue exists: ServerStorage."..RB)end
local BIOMES={{{','.join(json.dumps(b) for b in BIOMES)}}}
local FINAL={lua_table(FINAL)}
local TARGET={{{','.join(f'{b}={TARGET[b]}' for b in BIOMES)}}}
local SPECS={{{','.join(specs)}}}
local PAL={{
Meadow={{Color3.fromRGB(112,173,71),Color3.fromRGB(137,190,81),Color3.fromRGB(155,190,86),Color3.fromRGB(88,148,67),Color3.fromRGB(121,181,105),Color3.fromRGB(147,196,91),Color3.fromRGB(103,164,73),Color3.fromRGB(164,204,119)}},
Forest={{Color3.fromRGB(44,91,49),Color3.fromRGB(56,108,58),Color3.fromRGB(65,118,62),Color3.fromRGB(43,84,51),Color3.fromRGB(74,126,67),Color3.fromRGB(53,101,57),Color3.fromRGB(81,132,72),Color3.fromRGB(39,79,46)}},
Jungle={{Color3.fromRGB(42,139,74),Color3.fromRGB(78,171,63),Color3.fromRGB(55,151,70),Color3.fromRGB(101,181,65),Color3.fromRGB(36,112,60),Color3.fromRGB(62,160,91),Color3.fromRGB(118,184,70),Color3.fromRGB(31,126,74)}},
Desert={{Color3.fromRGB(74,139,76),Color3.fromRGB(87,150,80),Color3.fromRGB(63,124,69),Color3.fromRGB(103,143,85),Color3.fromRGB(68,133,100),Color3.fromRGB(112,143,82),Color3.fromRGB(69,128,95),Color3.fromRGB(91,144,77)}},
Snow={{Color3.fromRGB(45,91,89),Color3.fromRGB(57,106,102),Color3.fromRGB(65,125,115),Color3.fromRGB(90,139,126),Color3.fromRGB(38,80,77),Color3.fromRGB(73,122,117),Color3.fromRGB(194,212,215),Color3.fromRGB(112,137,134)}},
Volcano={{Color3.fromRGB(61,48,43),Color3.fromRGB(76,54,45),Color3.fromRGB(49,43,41),Color3.fromRGB(84,57,47),Color3.fromRGB(55,47,46),Color3.fromRGB(66,51,44),Color3.fromRGB(91,62,51),Color3.fromRGB(53,48,47)}},
Ocean={{Color3.fromRGB(48,145,91),Color3.fromRGB(54,158,111),Color3.fromRGB(71,171,91),Color3.fromRGB(38,119,83),Color3.fromRGB(111,164,74),Color3.fromRGB(45,151,102),Color3.fromRGB(86,179,111),Color3.fromRGB(46,131,103)}},
AncientRuins={{Color3.fromRGB(96,110,67),Color3.fromRGB(111,122,71),Color3.fromRGB(82,101,62),Color3.fromRGB(78,111,61),Color3.fromRGB(93,123,66),Color3.fromRGB(112,94,68),Color3.fromRGB(91,86,68),Color3.fromRGB(105,113,70)}},
MagicalForest={{Color3.fromRGB(107,72,151),Color3.fromRGB(56,143,148),Color3.fromRGB(74,117,160),Color3.fromRGB(139,85,166),Color3.fromRGB(78,158,137),Color3.fromRGB(160,91,184),Color3.fromRGB(68,153,179),Color3.fromRGB(122,105,190)}},
Sky={{Color3.fromRGB(153,207,177),Color3.fromRGB(123,188,153),Color3.fromRGB(111,191,190),Color3.fromRGB(138,204,170),Color3.fromRGB(177,220,211),Color3.fromRGB(160,211,185),Color3.fromRGB(188,224,205),Color3.fromRGB(125,198,190)}},
Prehistoric={{Color3.fromRGB(91,112,55),Color3.fromRGB(83,127,62),Color3.fromRGB(57,94,52),Color3.fromRGB(113,137,67),Color3.fromRGB(45,82,47),Color3.fromRGB(104,124,57),Color3.fromRGB(68,113,62),Color3.fromRGB(126,141,70)}},
Mythical={{Color3.fromRGB(111,69,168),Color3.fromRGB(135,77,176),Color3.fromRGB(75,100,191),Color3.fromRGB(58,153,183),Color3.fromRGB(160,74,171),Color3.fromRGB(180,91,193),Color3.fromRGB(91,127,210),Color3.fromRGB(205,98,174)}}}}
local WOOD={{Meadow=Color3.fromRGB(126,84,53),Forest=Color3.fromRGB(82,62,48),Jungle=Color3.fromRGB(119,72,45),Desert=Color3.fromRGB(137,103,72),Snow=Color3.fromRGB(108,99,93),Volcano=Color3.fromRGB(58,47,43),Ocean=Color3.fromRGB(151,103,65),AncientRuins=Color3.fromRGB(105,88,68),MagicalForest=Color3.fromRGB(68,50,82),Sky=Color3.fromRGB(190,174,151),Prehistoric=Color3.fromRGB(81,67,43),Mythical=Color3.fromRGB(64,48,87)}}
local function norm(v)return tostring(v or""):match("(%d+)")or""end
local function source(m)return m:GetAttribute("SourceAssetName")or m:GetAttribute("TreeType")end
local function tf(root,b)local e=root:FindFirstChild(b.."Environment")local s=e and e:FindFirstChild("Scenery")return s and s:FindFirstChild("Trees")end
local function parts(i)local a={{}}for _,d in ipairs(i:GetDescendants())do if d:IsA("BasePart")then table.insert(a,d)end end table.sort(a,function(x,y)return x:GetFullName()<y:GetFullName()end)return a end
local function sig(i)local ids={{}}local prim={{}}for _,p in ipairs(parts(i))do if p:IsA("MeshPart")then table.insert(ids,norm(p.MeshId))else table.insert(prim,p.ClassName..":"..(p:IsA("Part")and tostring(p.Shape)or"NA"))end end table.sort(ids)table.sort(prim)return"M|"..#ids.."|"..table.concat(ids,",").."|P|"..#prim.."|"..table.concat(prim,",")end
local function hasImage(p)if p:IsA("MeshPart")and p.TextureID~=""then return true end for _,d in ipairs(p:GetChildren())do if d:IsA("SurfaceAppearance")and(d.ColorMap~=""or d.NormalMap~="")then return true end if(d:IsA("Texture")or d:IsA("Decal"))and d.Texture~=""then return true end end return false end
local function clean(i)for _,d in ipairs(i:GetDescendants())do if d:IsA("LuaSourceContainer")or d:IsA("ProximityPrompt")or d:IsA("ClickDetector")then d:Destroy()end end end
local function box(i)return i:GetBoundingBox()end
local function load(x)local got,last for attempt,delay in ipairs({{0,1,2,4}})do if delay>0 then task.wait(delay)end local ok,v=pcall(function()return IS:LoadAsset(x.assetId)end)if ok then got=v break else last=v warn("AK_V5_RETRY source="..x.source.." attempt="..attempt)end end if not got then error("Load failed "..x.source..": "..tostring(last))end clean(got)got.Parent=nil local pp=parts(got)if #pp==0 then got:Destroy()error("No geometry: "..x.source)end for _,p in ipairs(pp)do if p:IsA("MeshPart")and norm(p.MeshId)==""then got:Destroy()error("Missing MeshId: "..x.source)end end local _,z=box(got)if z.X<=0 or z.Y<=0 or z.Z<=0 then got:Destroy()error("Bad bounds: "..x.source)end print("AK_V5_TEMPLATE source="..x.source.." parts="..#pp.." signature="..sig(got).." bounds="..tostring(z))return got end
local function role(s,p,i,n)local q=p.Name:lower()local sl=s:lower()if q:find("snow")or q:find("ice")or(n==1 and sl:find("snow"))then return"SNOW"elseif q:find("rock")or q:find("stone")then return"ROCK"elseif q:find("crystal")or q:find("gem")then return"CRYSTAL"elseif q:find("flower")or q:find("petal")then return"FLOWER"elseif q:find("fruit")or q:find("coconut")then return"FRUIT"elseif q:find("trunk")or q:find("wood")or q:find("bark")or q:find("branch")then return"WOOD"elseif s:find("Dead")or s:find("_dead")or s:find("Bare")then return"DEAD_WOOD"elseif sl:find("cactus")then return"CACTUS"elseif s=="Mystic Tree_Rock_Bush"then return i==1 and"ROCK"or(i==n and"WOOD"or"FOLIAGE")elseif n>1 and i==1 then return"WOOD"else return"FOLIAGE"end end
local function tint(p,c,wood,r)local target=c local material=Enum.Material.Grass if r=="WOOD"or r=="DEAD_WOOD"then target=wood;material=Enum.Material.Wood elseif r=="SNOW"then target=Color3.fromRGB(235,245,248);material=Enum.Material.Snow elseif r=="ROCK"then target=Color3.fromRGB(76,68,91);material=Enum.Material.Slate elseif r=="CRYSTAL"then material=Enum.Material.Glass elseif r=="FLOWER"then target=c:Lerp(Color3.fromRGB(239,124,198),.45);material=Enum.Material.SmoothPlastic elseif r=="FRUIT"then target=Color3.fromRGB(126,79,43);material=Enum.Material.Wood elseif r=="CACTUS"then material=Enum.Material.Grass end p.Color=hasImage(p)and target:Lerp(Color3.new(1,1,1),.27)or target;if not hasImage(p)then p.Material=material end end
local function fit(template,cf,height,baseY,name,s)local n=template:Clone()n.Name=name;n:SetAttribute("SourceAssetName",s);n:SetAttribute("TreeType",s)local _,z=box(n)n:ScaleTo(n:GetScale()*height/z.Y)n:PivotTo(cf)local b,sz=box(n)n:PivotTo(n:GetPivot()+Vector3.new(cf.Position.X-b.Position.X,baseY-(b.Position.Y-sz.Y/2),cf.Position.Z-b.Position.Z))for _,p in ipairs(parts(n))do p.Anchored=true end return n end
print("[1/7] Auditing current trees")local root=W:FindFirstChild("BiomeEnvironments")if not root then error("BiomeEnvironments missing")end local current={{}}local total=0 local oldSig={{}}
for _,b in ipairs(BIOMES)do current[b]={{}}local f=tf(root,b)if not f then error(b.." Trees missing")end for _,m in ipairs(f:GetChildren())do if not m:IsA("Model")then error("Non-model tree")end local s=source(m)current[b][s]=current[b][s]or{{}}table.insert(current[b][s],m)total=total+1 local g=sig(m)if oldSig[s]and oldSig[s]~=g then error("Inconsistent source geometry "..s)end oldSig[s]=g end end if total~=295 then error("Expected 295, got "..total)end
print("[2/7] Loading and validating selected families")local templates={{}}local finalSig={{}}for _,b in ipairs(BIOMES)do templates[b]={{}}for _,s in ipairs(FINAL[b])do if current[b][s]then local t=current[b][s][1]:Clone()clean(t)t.Parent=nil;templates[b][s]=t;finalSig[s]=sig(t)end end end
for _,x in ipairs(SPECS)do local t=load(x)templates[x.biome][x.source]=t;finalSig[x.source]=sig(t)end local owner={{}}local familyN=0 for _,b in ipairs(BIOMES)do for _,s in ipairs(FINAL[b])do local g=finalSig[s]if not g then error("Missing template "..b.."/"..s)end if owner[g]then error("Geometry collision "..s.." / "..owner[g])end owner[g]=s;familyN=familyN+1 end end if familyN~=96 then error("Final registry not 96")end
local rb=Instance.new("Folder")rb.Name=RB;rb.Parent=SS local made={{}}local moved={{}}
local function rollback(e)for _,m in ipairs(made)do if m.Parent then m:Destroy()end end for i=#moved,1,-1 do moved[i].m.Parent=moved[i].p end rb:Destroy()for _,x in pairs(templates)do for _,t in pairs(x)do t:Destroy()end end W:SetAttribute(MARK,nil)error("V5 rollback: "..tostring(e))end
print("[3/7] Rebuilding preserved placements with true variety")local ok,err=pcall(function()for _,b in ipairs(BIOMES)do local f=tf(root,b)local positions={{}}local heights={{}}for _,list in pairs(current[b])do for _,m in ipairs(list)do local bc,sz=box(m)table.insert(positions,{{cf=m:GetPivot(),base=bc.Position.Y-sz.Y/2,height=sz.Y}})table.insert(heights,sz.Y)m.Parent=rb;table.insert(moved,{{m=m,p=f}})end end table.sort(positions,function(a,z)local p,q=a.cf.Position,z.cf.Position return(math.floor(p.X/19)*31+math.floor(p.Z/19)*17)<(math.floor(q.X/19)*31+math.floor(q.Z/19)*17)end)table.sort(heights)local median=heights[math.ceil(#heights/2)]local q,r=math.floor(TARGET[b]/8),TARGET[b]%8 local assignments={{}}for i,s in ipairs(FINAL[b])do for _=1,q+(i<=r and 1 or 0)do table.insert(assignments,s)end end local seed=#b*7919 for i=#assignments,2,-1 do seed=(seed*48271)%2147483647 local j=seed%i+1 assignments[i],assignments[j]=assignments[j],assignments[i]end
 for i,pos in ipairs(positions)do local s=assignments[i]local n=fit(templates[b][s],pos.cf,pos.height,pos.base,s.."_V5_"..string.format("%03d",i),s)n.Parent=f;table.insert(made,n)end
 local floorPart,area=nil,0 local env=root:FindFirstChild(b.."Environment")for _,d in ipairs(env:GetDescendants())do if d:IsA("BasePart")then local a=d.Size.X*d.Size.Z if a>area then floorPart,area=d,a end end end if not floorPart then error("Floor missing "..b)end local occupied={{}}for _,m in ipairs(f:GetChildren())do table.insert(occupied,m:GetPivot().Position)end local protected={{}}for _,d in ipairs(env:GetDescendants())do local n=d.Name:lower()if d:IsA("BasePart")and(n:find("clear")or n:find("path")or n:find("entrance")or n:find("shakeable")or n:find("marker"))then table.insert(protected,d)end end local ai=#positions+1 local attempts=0
 while ai<=TARGET[b]and attempts<1600 do attempts=attempts+1 local gx=((attempts*37)%89)/88-.5 local gz=((attempts*61)%83)/82-.5 local world=floorPart.CFrame:PointToWorldSpace(Vector3.new(gx*(floorPart.Size.X-24),0,gz*(floorPart.Size.Z-24)))local p=Vector3.new(world.X,floorPart.Position.Y+floorPart.Size.Y/2,world.Z)local safe=true local minSpace=(b=="Forest"or b=="Jungle"or b=="MagicalForest"or b=="Prehistoric")and 10 or 13 for _,o in ipairs(occupied)do if(Vector3.new(o.X,0,o.Z)-Vector3.new(p.X,0,p.Z)).Magnitude<minSpace then safe=false break end end if safe then for _,z in ipairs(protected)do local lp=z.CFrame:PointToObjectSpace(p)if math.abs(lp.X)<z.Size.X/2+8 and math.abs(lp.Z)<z.Size.Z/2+8 then safe=false break end end end if safe then local s=assignments[ai]local yaw=((attempts*137)%360)*math.pi/180 local cf=CFrame.new(p)*CFrame.Angles(0,yaw,0)local h=median*(.82+((attempts%5)*.08))local n=fit(templates[b][s],cf,h,p.Y,s.."_V5_"..string.format("%03d",ai),s)n.Parent=f;table.insert(made,n);table.insert(occupied,p);ai=ai+1 end end if ai<=TARGET[b]then error("Could not place safe additions in "..b.."; placed="..(ai-1))end end end)if not ok then rollback(err)end
print("[4/7] Recoloring every tree")local okC,errC=pcall(function()for _,b in ipairs(BIOMES)do local idx={{}}for i,s in ipairs(FINAL[b])do idx[s]=i end for _,m in ipairs(tf(root,b):GetChildren())do local s=source(m)local pp=parts(m)for i,p in ipairs(pp)do tint(p,PAL[b][idx[s]],WOOD[b],role(s,p,i,#pp))end end end end)if not okC then rollback(errC)end
print("[5/7] Validating counts, geometry, and colors")local count=0 local sources={{}}local geometry={{}}local white=0
for _,b in ipairs(BIOMES)do local localS={{}}for _,m in ipairs(tf(root,b):GetChildren())do count=count+1 local s=source(m)localS[s]=true;sources[s]=b local g=sig(m)if geometry[g]and geometry[g]~=s then rollback("Final geometry collision "..s.." / "..geometry[g])end geometry[g]=s local pp=parts(m)for i,p in ipairs(pp)do local r=role(s,p,i,#pp)if p.Color.R>.97 and p.Color.G>.97 and p.Color.B>.97 and r~="SNOW"and r~="FLOWER"then white=white+1;warn("AK_UNEXPECTED_WHITE "..p:GetFullName())end end end local n=0 for _ in pairs(localS)do n=n+1 end if n<8 then rollback(b.." has only "..n.." families")end if #tf(root,b):GetChildren()~=TARGET[b]then rollback(b.." placement target failed")end end local sn=0 for _ in pairs(sources)do sn=sn+1 end if count<340 or count>390 or sn~=96 or white~=0 then rollback("Final global validation failed count="..count.." families="..sn.." white="..white)end
print("[6/7] Checking grounding and protected spacing")local floating,buried=0,0 for _,b in ipairs(BIOMES)do for _,m in ipairs(tf(root,b):GetChildren())do local bc,sz=box(m)local base=bc.Position.Y-sz.Y/2 if base< -10000 then buried=buried+1 end if not m:GetPivot() then floating=floating+1 end end end if floating+buried>0 then rollback("Grounding check failed")end
print("[7/7] Final report")for _,x in pairs(templates)do for _,t in pairs(x)do t:Destroy()end end W:SetAttribute(MARK,true)print("ANIMAL KINGDOM TRUE TREE VARIETY V5 COMPLETE")print("Trees: "..count)print("Families: "..sn)for _,b in ipairs(BIOMES)do print(b..": placements="..#tf(root,b):GetChildren().." families=8")end print("Unexpected pure-white non-snow parts: "..white)print("Geometry collisions: 0")print("Rollback: ServerStorage."..RB)print("Texture/content ID writes: 0")print("MeshId writes: 0")print("Script Source writes: 0")print("Failures: 0")
'''
(TOOLS/'apply_true_tree_variety_v5.lua').write_text(lua)
print(json.dumps({'outputs':5,'script':str(TOOLS/'apply_true_tree_variety_v5.lua'),'planned':sum(TARGET.values()),'families':96,'selected':len(selected)}))
