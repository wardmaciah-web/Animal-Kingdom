-- Animal Kingdom Concrete Ground Fill V1. Paste into Studio Command Bar; do not run twice.
local Workspace=game:GetService("Workspace")
local ServerStorage=game:GetService("ServerStorage")
local MARKER="AnimalKingdomConcreteGroundV1"
local OUTPUT_NAME="AnimalKingdomConcreteGround"
local ROLLBACK_NAME="AnimalKingdomConcreteGroundV1Rollback"
local BIOMES={"Meadow","Forest","Jungle","Desert","Snow","Volcano","Ocean","AncientRuins","MagicalForest","Sky","Prehistoric","Mythical"}
if Workspace:GetAttribute(MARKER)==true then warn(MARKER.." is already applied")return end
if Workspace:FindFirstChild(OUTPUT_NAME)then error("Existing Workspace."..OUTPUT_NAME.." found; no changes made")end
if ServerStorage:FindFirstChild(ROLLBACK_NAME)then error("Stale rollback folder found; no changes made")end

local root=Workspace:FindFirstChild("BiomeEnvironments")
if not root then error("Workspace.BiomeEnvironments is missing")end
local grass=Workspace:FindFirstChild("GrassFloor")
if not grass or not grass:IsA("BasePart")then error("Workspace.GrassFloor is missing or is not a BasePart")end

local function treeFolder(env)local scenery=env:FindFirstChild("Scenery")return scenery and scenery:FindFirstChild("Trees")end
local function getTopY(p)
 local cf,s=p.CFrame,p.Size local best=-math.huge
 for _,x in ipairs({-1,1})do for _,y in ipairs({-1,1})do for _,z in ipairs({-1,1})do local q=cf:PointToWorldSpace(Vector3.new(x*s.X*.5,y*s.Y*.5,z*s.Z*.5));best=math.max(best,q.Y)end end end
 return best
end
local function insideXZ(part,point,tolerance)local q=part.CFrame:PointToObjectSpace(point)tolerance=tolerance or 0 return math.abs(q.X)<=part.Size.X*.5+tolerance and math.abs(q.Z)<=part.Size.Z*.5+tolerance end
local EXCLUDED_ANCESTORS={"trees","rocks","decor","plants","transition","presentation","labels","future","marker","helper","debug","crystal"}
local function excludedByHierarchy(i)local p=i while p and p~=Workspace do local n=p.Name:lower()for _,word in ipairs(EXCLUDED_ANCESTORS)do if n:find(word,1,true)then return true end end p=p.Parent end return false end
local function eligibleFloor(p,medianBaseY)
 if not p:IsA("BasePart")or not p.Anchored or p.Transparency>=1 or excludedByHierarchy(p)then return false end
 if math.abs(p.CFrame.UpVector:Dot(Vector3.yAxis))<.88 then return false end
 if p.Size.X*p.Size.Z<100 then return false end
 return math.abs(getTopY(p)-medianBaseY)<=18
end
local function median(values)table.sort(values)local n=#values;if n==0 then return nil end if n%2==1 then return values[(n+1)/2]end return(values[n/2]+values[n/2+1])*.5 end
local function supportPoints(env)
 local points={}local treePoints={}local shakePoints={}local ys={}local trees=treeFolder(env)
 if not trees then return nil,"Trees folder missing"end
 for _,m in ipairs(trees:GetChildren())do if m:IsA("Model")then local cf,s=m:GetBoundingBox()local p=Vector3.new(cf.Position.X,cf.Position.Y-s.Y*.5,cf.Position.Z)table.insert(points,p);table.insert(treePoints,p);table.insert(ys,p.Y)end end
 for _,d in ipairs(env:GetDescendants())do if d:IsA("BasePart")and d.Name:lower():find("futureshakeablespot",1,true)then table.insert(points,d.Position);table.insert(shakePoints,d.Position)end end
 if #treePoints==0 then return nil,"No tree support points"end
 return{all=points,trees=treePoints,shake=shakePoints,medianY=median(ys)}
end
local function resolveBiomeFloor(biome)
 local env=root:FindFirstChild(biome.."Environment")if not env then return nil,"Environment missing"end
 local support,why=supportPoints(env)if not support then return nil,why end
 local pool={}local seen={}
 for _,p in ipairs(env:GetDescendants())do if p:IsA("BasePart")then table.insert(pool,p);seen[p]=true end end
 local key=biome:lower()
 for _,p in ipairs(Workspace:GetDescendants())do if p:IsA("BasePart")and not seen[p]then local path=p:GetFullName():lower()local n=p.Name:lower()if path:find(key,1,true)and(n:find("floor",1,true)or n:find("ground",1,true)or n:find("plot",1,true)or path:find("biomeplot",1,true))then table.insert(pool,p);seen[p]=true end end end
 local candidates={}
 for _,p in ipairs(pool)do if eligibleFloor(p,support.medianY)then local treeN,shakeN=0,0 for _,q in ipairs(support.trees)do if insideXZ(p,q,2)then treeN=treeN+1 end end for _,q in ipairs(support.shake)do if insideXZ(p,q,2)then shakeN=shakeN+1 end end local coverage=(treeN+shakeN)/math.max(1,#support.all)local yfit=1-math.min(1,math.abs(getTopY(p)-support.medianY)/18)local score=coverage*100+yfit*8+math.min(4,p.Size.X*p.Size.Z/2500)table.insert(candidates,{part=p,score=score,coverage=coverage})end end
 table.sort(candidates,function(a,b)return a.score>b.score end)
 local chosen={}local covered={}
 for _,c in ipairs(candidates)do local adds=false for i,q in ipairs(support.all)do if not covered[i]and insideXZ(c.part,q,2)then adds=true break end end if adds then table.insert(chosen,c.part)for i,q in ipairs(support.all)do if insideXZ(c.part,q,2)then covered[i]=true end end end local count=0 for _ in pairs(covered)do count=count+1 end if count==#support.all then break end end
 local coveredN=0 for _ in pairs(covered)do coveredN=coveredN+1 end local coverage=coveredN/math.max(1,#support.all)
 if #chosen==0 or coverage<.9 then return nil,"Insufficient support coverage: "..coverage end
 for _,q in ipairs(support.trees)do local yes=false for _,p in ipairs(chosen)do if insideXZ(p,q,3)then yes=true break end end if not yes then return nil,"Existing tree support lies outside resolved floor"end end
 for _,p in ipairs(chosen)do print("AK_CONCRETE_BIOME_FLOOR")print("biome="..biome)print("path="..p:GetFullName())print("size="..tostring(p.Size))print("position="..tostring(p.Position))print("topY="..getTopY(p))print("supportCoverage="..coverage)end
 return{biome=biome,env=env,parts=chosen,coverage=coverage}
end

print("[1/6] Resolving biome floors")
local resolved={}local resolvedCount=0 local floorParts={}local topYs={}local floorSnapshots={}
for _,b in ipairs(BIOMES)do local result,err=resolveBiomeFloor(b)if not result then error("Could not resolve "..b.." floor: "..tostring(err))end resolved[b]=result;resolvedCount=resolvedCount+1 for _,p in ipairs(result.parts)do table.insert(floorParts,p);table.insert(topYs,getTopY(p));floorSnapshots[p]={CFrame=p.CFrame,Size=p.Size,Material=p.Material,Color=p.Color}end end
if resolvedCount~=12 then error("Expected 12 resolved biomes, got "..resolvedCount)end

print("[2/6] Resolving common surface level")
local commonTop=median(table.clone(topYs))local minTop,maxTop=math.huge,-math.huge for _,y in ipairs(topYs)do minTop=math.min(minTop,y);maxTop=math.max(maxTop,y)end
print("AK_CONCRETE_LEVEL")print("medianBiomeTopY="..commonTop)print("minimumBiomeTopY="..minTop)print("maximumBiomeTopY="..maxTop)print("difference="..(maxTop-minTop))
if maxTop-minTop>.75 then warn("Biome-floor height outlier detected; using majority median without moving floors")end

print("[3/6] Resolving total map bounds")
local function floorCorners(p)local a={}for _,x in ipairs({-1,1})do for _,z in ipairs({-1,1})do table.insert(a,p.CFrame:PointToWorldSpace(Vector3.new(x*p.Size.X*.5,0,z*p.Size.Z*.5)))end end return a end
local containsAll=true for _,p in ipairs(floorParts)do for _,q in ipairs(floorCorners(p))do if not insideXZ(grass,q,.5)then containsAll=false end end end
print("AK_CONCRETE_MAP_BOUNDS")print("path="..grass:GetFullName())print("size="..tostring(grass.Size))print("position="..tostring(grass.Position))print("topY="..getTopY(grass))print("containsAllBiomeFloors="..tostring(containsAll))
if not containsAll then error("GrassFloor does not contain all resolved biome floors; no mutation performed")end

local function axisAlignedToOuter(p)local r=math.abs(p.CFrame.RightVector:Dot(grass.CFrame.RightVector))local l=math.abs(p.CFrame.LookVector:Dot(grass.CFrame.LookVector))return r>.9995 and l>.9995 end
local function localBounds(p)local minX,maxX,minZ,maxZ=math.huge,-math.huge,math.huge,-math.huge for _,q in ipairs(floorCorners(p))do local v=grass.CFrame:PointToObjectSpace(q);minX=math.min(minX,v.X);maxX=math.max(maxX,v.X);minZ=math.min(minZ,v.Z);maxZ=math.max(maxZ,v.Z)end return minX,maxX,minZ,maxZ end
local function obbOverlapCell(x0,x1,z0,z1,p,pad)
 local center=grass.CFrame:PointToWorldSpace(Vector3.new((x0+x1)*.5,0,(z0+z1)*.5))local ax,az=grass.CFrame.RightVector,grass.CFrame.LookVector local bx,bz=p.CFrame.RightVector,p.CFrame.LookVector local ahx,ahz=(x1-x0)*.5,(z1-z0)*.5 local bhx,bhz=p.Size.X*.5+pad,p.Size.Z*.5+pad local delta=p.Position-center
 for _,axis in ipairs({ax,az,bx,bz})do local distance=math.abs(delta:Dot(axis))local ra=ahx*math.abs(ax:Dot(axis))+ahz*math.abs(az:Dot(axis))local rb=bhx*math.abs(bx:Dot(axis))+bhz*math.abs(bz:Dot(axis))if distance>=ra+rb then return false end end return true
end

print("[4/6] Building concrete exclusion mask")
local aligned=true for _,p in ipairs(floorParts)do if not axisAlignedToOuter(p)then aligned=false break end end
local halfX,halfZ=grass.Size.X*.5,grass.Size.Z*.5 local xs={-halfX,halfX}local zs={-halfZ,halfZ}local edgePad=.08 local resolution
if aligned then for _,p in ipairs(floorParts)do local x0,x1,z0,z1=localBounds(p)table.insert(xs,math.max(-halfX,x0-edgePad));table.insert(xs,math.min(halfX,x1+edgePad));table.insert(zs,math.max(-halfZ,z0-edgePad));table.insert(zs,math.min(halfZ,z1+edgePad))end resolution=0 else local longest=math.max(grass.Size.X,grass.Size.Z);resolution=longest<=500 and 2 or(longest<=800 and 3 or 4)xs={}zs={}local x=-halfX while x<halfX do table.insert(xs,x);x=math.min(halfX,x+resolution)end table.insert(xs,halfX)local z=-halfZ while z<halfZ do table.insert(zs,z);z=math.min(halfZ,z+resolution)end table.insert(zs,halfZ)end
table.sort(xs)table.sort(zs)local function dedupe(a)local out={}for _,v in ipairs(a)do if #out==0 or math.abs(v-out[#out])>.001 then table.insert(out,v)end end return out end xs=dedupe(xs);zs=dedupe(zs)
local nx,nz=#xs-1,#zs-1 local concrete={}local biomeArea=0
for iz=1,nz do concrete[iz]={}for ix=1,nx do local blocked=false for _,p in ipairs(floorParts)do if obbOverlapCell(xs[ix],xs[ix+1],zs[iz],zs[iz+1],p,edgePad)then blocked=true break end end concrete[iz][ix]=not blocked;if blocked then biomeArea=biomeArea+(xs[ix+1]-xs[ix])*(zs[iz+1]-zs[iz])end end end
local used={}for z=1,nz do used[z]={}end local regions={}
for z=1,nz do for x=1,nx do if concrete[z][x]and not used[z][x]then local x2=x while x2<nx and concrete[z][x2+1]and not used[z][x2+1]do x2=x2+1 end local z2=z local can=true while can and z2<nz do for xx=x,x2 do if not concrete[z2+1][xx]or used[z2+1][xx]then can=false break end end if can then z2=z2+1 end end for zz=z,z2 do for xx=x,x2 do used[zz][xx]=true end end table.insert(regions,{x0=xs[x],x1=xs[x2+1],z0=zs[z],z1=zs[z2+1]})end end end
local concreteArea=0 for _,r in ipairs(regions)do concreteArea=concreteArea+(r.x1-r.x0)*(r.z1-r.z0)end local outerArea=grass.Size.X*grass.Size.Z local uncovered=math.max(0,outerArea-concreteArea-biomeArea)
print("AK_CONCRETE_PREFLIGHT")print("biomesResolved=12")print("commonTopY="..commonTop)print("mapBounds="..tostring(grass.Size))print("maskResolution="..resolution)print("concreteRegionsPlanned="..#regions)print("estimatedConcreteArea="..concreteArea)print("biomeExcludedArea="..biomeArea)print("uncoveredNonBiomeArea="..uncovered)
if #regions==0 or #regions>150 or uncovered>.01 then error("Concrete mask validation failed before mutation: regions="..#regions.." uncovered="..uncovered)end

print("[5/6] Creating optimized concrete regions")
local rollback=Instance.new("Folder")rollback.Name=ROLLBACK_NAME;rollback.Parent=ServerStorage
rollback:SetAttribute("GrassFloorCFrame",grass.CFrame)rollback:SetAttribute("GrassFloorSize",grass.Size)rollback:SetAttribute("GrassFloorMaterial",grass.Material.Name)rollback:SetAttribute("GrassFloorColor",grass.Color)
local output=Instance.new("Folder")output.Name=OUTPUT_NAME
local created={}local thickness=.8 local _,mapYaw,_=grass.CFrame:ToOrientation()local ok,mutationError=pcall(function()
 for i,r in ipairs(regions)do local width,depth=r.x1-r.x0,r.z1-r.z0 local localCenter=Vector3.new((r.x0+r.x1)*.5,0,(r.z0+r.z1)*.5)local world=grass.CFrame:PointToWorldSpace(localCenter)local p=Instance.new("Part")p.Name="ConcreteRegion_"..string.format("%03d",i)p.Anchored=true;p.CanCollide=true;p.CanTouch=true;p.CanQuery=true;p.CastShadow=true;p.Material=Enum.Material.Concrete;p.Color=Color3.fromRGB(125,125,125);p.Size=Vector3.new(width,thickness,depth);p.CFrame=CFrame.new(world.X,commonTop-thickness*.5,world.Z)*CFrame.Angles(0,mapYaw,0);p.Parent=output;table.insert(created,p)end
 output.Parent=Workspace
end)
local function rollbackAll(message)if output.Parent then output:Destroy()end rollback:Destroy()Workspace:SetAttribute(MARKER,nil)error("Concrete V1 rollback: "..tostring(message))end
if not ok then rollbackAll(mutationError)end

print("[6/6] Final validation")
local overlaps=0 local levelFailures=0 local actualArea=0
for _,p in ipairs(created)do actualArea=actualArea+p.Size.X*p.Size.Z;if math.abs(getTopY(p)-commonTop)>.02 then levelFailures=levelFailures+1 end local lp=grass.CFrame:PointToObjectSpace(p.Position)local x0,x1=lp.X-p.Size.X*.5,lp.X+p.Size.X*.5 local z0,z1=lp.Z-p.Size.Z*.5,lp.Z+p.Size.Z*.5 for _,floor in ipairs(floorParts)do if obbOverlapCell(x0,x1,z0,z1,floor,0)then overlaps=overlaps+1 end end end
for p,s in pairs(floorSnapshots)do if p.CFrame~=s.CFrame or p.Size~=s.Size or p.Material~=s.Material or p.Color~=s.Color then rollbackAll("Biome floor changed unexpectedly: "..p:GetFullName())end end
if overlaps>0 or levelFailures>0 or #created~=#regions then rollbackAll("Final geometry validation failed overlaps="..overlaps.." levels="..levelFailures)end
Workspace:SetAttribute(MARKER,true)
print("ANIMAL KINGDOM CONCRETE GROUND V1 COMPLETE")print("Biome floors resolved:")print("12/12")print("Common surface Y:")print(commonTop)print("Concrete regions:")print(#created)print("Concrete total area:")print(actualArea)print("Concrete/biome overlaps:")print(0)print("Visible non-biome ground gaps:")print(0)print("Biome floors moved:")print(0)print("Biome floors resized:")print(0)print("Tree changes:")print(0)print("Gameplay changes:")print(0)print("Rollback:")print("ServerStorage."..ROLLBACK_NAME)print("Failures:")print(0)
