-- Edit-time visual build only. No runtime scripts or gameplay tuning changes.
assert(not game:GetService('RunService'):IsRunning(), 'Stop the playtest first')
local W, SS, CS = workspace, game.ServerStorage, game:GetService('CollectionService')
local g = W.PetGardenRealm
local assets = SS.GardenVisualAssets_20260922
local backup = SS.GardenVisualRedesign_Backup_20260922
assert(not g:FindFirstChild('GardenLandscape'), 'Visual build already exists')
local playerPlots = {}
for _,v in W.PlayerPlots:GetChildren() do if v.Name:match('^Plot%d+Floor$') then table.insert(playerPlots,v) end end
assert(#playerPlots == 4, 'Reinspect player count before building')
local V, CF, rgb = Vector3.new, CFrame.new, Color3.fromRGB
local palette = {grass=rgb(107,148,82), stone=rgb(213,201,165), trim=rgb(240,226,183), soil=rgb(92,63,43), furrow=rgb(107,75,49), wood=rgb(145,102,65), dark=rgb(40,83,69), gold=rgb(224,185,106)}
local function folder(name,parent) local f=Instance.new('Folder'); f.Name=name; f.Parent=parent; return f end
local design=folder('GardenLandscape',g)
local ground=folder('TerracedIsland',design)
local paths=folder('GardenWalks',design)
local plants=folder('Planting',design)
local decor=folder('GardenDetails',design)
local fences=folder('FenceSections',design)
local water=folder('PondWalk',design)
local nursery=folder('VegetableParterre',design)
local function pos(x,y,z) return V(2000+x,y,2000+z) end
local function part(name,size,x,y,z,color,mat,parent,collide)
 local p=Instance.new('Part'); p.Name=name; p.Size=size; p.CFrame=CF(pos(x,y,z)); p.Color=color; p.Material=mat or Enum.Material.SmoothPlastic
 p.Anchored=true; p.CanCollide=collide==true; p.CanTouch=false; p.CanQuery=collide==true; p.TopSurface=Enum.SurfaceType.Smooth; p.BottomSurface=Enum.SurfaceType.Smooth; p.Parent=parent; return p
end
local function disk(name,x,y,z,d,h,color,parent,collide)
 local p=part(name,V(h,d,d),x,y,z,color,Enum.Material.SmoothPlastic,parent,collide);p.Shape=Enum.PartType.Cylinder;p.CFrame=CF(p.Position)*CFrame.Angles(0,0,math.pi/2);return p
end
local function clean(m)
 for _,v in {m,table.unpack(m:GetDescendants())} do
  for _,t in CS:GetTags(v) do CS:RemoveTag(v,t) end
  for k in v:GetAttributes() do v:SetAttribute(k,nil) end
  if v:IsA('LuaSourceContainer') or v:IsA('ProximityPrompt') or v:IsA('ClickDetector') or v:IsA('PackageLink') or v:IsA('TouchTransmitter') then v:Destroy()
  elseif v:IsA('BasePart') then v.Anchored=true;v.CanCollide=false;v.CanTouch=false;v.CanQuery=false end
 end
end
local function cloneAt(src,name,x,z,bottom,height,yaw,parent)
 local m=src:Clone(); clean(m);m.Name=name;m.Parent=parent
 local _,s=m:GetBoundingBox();if height then m:ScaleTo(m:GetScale()*height/s.Y) end
 m:PivotTo(CF(pos(x,0,z))*CFrame.Angles(0,math.rad(yaw or 0),0))
 local cf,sz=m:GetBoundingBox();m:PivotTo(m:GetPivot()+V(2000+x-cf.Position.X,bottom-(cf.Position.Y-sz.Y/2),2000+z-cf.Position.Z))
 m:SetAttribute('GardenVisualOnly',true); m:SetAttribute('SourceAssetName',src.Name);return m
end
local function label(p,text,face,size)
 local gui=Instance.new('SurfaceGui');gui.Name='GardenLabel';gui.Face=face or Enum.NormalId.Front;gui.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud;gui.PixelsPerStud=45;gui.LightInfluence=0.25;gui.Parent=p
 local t=Instance.new('TextLabel');t.Size=UDim2.fromScale(0.9,0.84);t.Position=UDim2.fromScale(0.05,0.08);t.BackgroundTransparency=1;t.Text=text;t.TextColor3=palette.trim;t.Font=Enum.Font.GothamBold;t.TextScaled=true;t.Parent=gui
 return t
end
local function board(name,text,x,z,w)
 local p=part(name,V(w,2.5,0.45),x,34.5,z,palette.dark,Enum.Material.Wood,decor,false);p.CFrame=CF(p.Position)*CFrame.Angles(0,math.pi,0);label(p,text)
 for _,dx in {-w*.35,w*.35} do part(name..'Post',V(.35,3,.4),x+dx,32.6,z,palette.wood,Enum.Material.Wood,decor,false) end;return p
end
local function path(name,x,z,sx,sz)
 part(name..'Border',V(sx+1.2,.25,sz+1.2),x,31.11,z,palette.trim,Enum.Material.Limestone,paths,false)
 return part(name,V(sx,.28,sz),x,31.25,z,palette.stone,Enum.Material.Limestone,paths,true)
end
local function segment(name,x1,z1,x2,z2,width)
 local dx,dz=x2-x1,z2-z1;local len=math.sqrt(dx*dx+dz*dz)
 local p=path(name,(x1+x2)/2,(z1+z2)/2,width,len);local rot=CFrame.Angles(0,math.atan2(dx,dz),0)
 p.CFrame=CF(p.Position)*rot;paths[name..'Border'].CFrame=CF(paths[name..'Border'].Position)*rot
end
-- Retain compatibility instances; archive only old visual dressing.
local keep={RealmBase=true,GardenArrival=true,GardenReturnFallback=true,ReturnPortal=true,GardenMainSign=true,ShopCounter=true,ShopSign=true,ShopAwning=true,PreviewStage=true,PreviewSign=true}
local archive=folder('PreviousVisualDressing',backup)
for _,v in g:GetChildren() do if v~=design and not keep[v.Name] and not v.Name:match('^GardenPlot%d+$') then v.Parent=archive end end
local base=g.RealmBase;base.Size=V(192,4,216);base.Position=pos(0,29,0);base.Color=palette.grass;base.Material=Enum.Material.Grass;base.CanTouch=false
part('LawnWings',V(224,4,184),0,29,0,palette.grass,Enum.Material.Grass,ground,true)
part('StoneIslandCore',V(194,7,218),0,24.8,0,rgb(126,123,96),Enum.Material.Limestone,ground,true)
part('StoneIslandWings',V(226,7,186),0,24.8,0,rgb(126,123,96),Enum.Material.Limestone,ground,true)
for _,x in {-96,96} do for _,z in {-92,92} do
 local p=disk('RoundedLawnCorner',x,29,z,32,4,palette.grass,ground,true);p.Material=Enum.Material.Grass
 p=disk('RoundedStoneCorner',x,24.8,z,34,7,rgb(126,123,96),ground,true);p.Material=Enum.Material.Limestone
end end
-- Broad connected walks. Primary destinations remain inside the existing 90-stud check.
path('ArrivalWalk',0,50,14,83)
path('NorthWalk',0,-49,14,64)
path('SouthPlotPromenade',0,27,141,11)
path('NorthPlotPromenade',0,-20,136,10)
path('RearOrchardWalk',0,-65,130,8)
path('WestPlotWalk',-66,-18,8,98)
path('EastPlotWalk',66,-18,8,98)
disk('GardenCourtBorder',0,31.15,-1,39,.32,palette.trim,paths,false)
disk('GardenCourtStone',0,31.31,-1,37,.3,palette.stone,paths,true)
-- Central oak court, with a generous ring to walk around.
disk('CourtPlanterFoot',0,31.65,-1,12,1.2,palette.trim,decor,false)
disk('CourtPlanter',0,32.2,-1,10.5,1.5,palette.dark,decor,false)
disk('CourtSoil',0,33,-1,9.5,.25,palette.soil,decor,false)
cloneAt(W.Tree_Oak_5_V5_011,'CourtOak',0,-1,33.1,18,30,plants)
-- Four matching plots retain their original anchor instances and names.
local coords={{-37,4},{37,4},{-37,-43},{37,-43}}
local template=g.GardenPlot1
for i=1,#playerPlots do
 local plot=g:FindFirstChild('GardenPlot'..i)
 if not plot then plot=template:Clone();plot.Name='GardenPlot'..i;plot.Parent=g end
 plot:SetAttribute('PlotIndex',i);plot:SetAttribute('SlotId',i)
 local x,z=coords[i][1],coords[i][2]
 local detail=folder('VisualTrim',plot)
 part('PlotTerrace',V(37,.24,31),x,31.13,z,rgb(139,164,98),Enum.Material.Grass,detail,false)
 local soil=plot.SoilBase;soil.Size=V(30,.7,24);soil.CFrame=CF(pos(x,31.5,z));soil.Material=Enum.Material.Ground;soil.Color=palette.soil
 for _,v in plot:GetChildren() do if v:IsA('BasePart') then v.Anchored=true;v.CanTouch=false end end
 local borders={{'BorderN',V(32,.8,1),x,z-12.4},{'BorderS',V(32,.8,1),x,z+12.4},{'BorderW',V(1,.8,24),x-15.5,z},{'BorderE',V(1,.8,24),x+15.5,z}}
 for _,b in borders do local p=plot[b[1]];p.Size=b[2];p.CFrame=CF(pos(b[3],31.75,b[4]));p.Color=palette.wood;p.Material=Enum.Material.Wood;p.CanCollide=false;p.CanQuery=false end
 for row=0,1 do for col=0,2 do local a=plot['CropAnchor'..row..'_'..col];a.CFrame=CF(pos(x+(col-1)*9,32.15,z-6+row*11));a.Transparency=1;a.CanCollide=false;a.CanTouch=false;a.CanQuery=false end end
 for r=1,6 do part('TilledSoilRow'..r,V(27,.08,1.7),x,31.89,z-10+(r-1)*4,palette.furrow,Enum.Material.Ground,detail,false) end
 for _,dx in {-15.5,15.5} do for _,dz in {-12.4,12.4} do part('CornerCap',V(1.5,1,1.5),x+dx,31.9,z+dz,palette.trim,Enum.Material.Limestone,detail,false) end end
 local pad=plot.PetPad;pad.Size=V(6,.24,5);pad.CFrame=CF(pos(x,32,z));pad.Color=rgb(145,158,101);pad.Material=Enum.Material.SmoothPlastic;pad.CanCollide=false
 local sign=plot.PlotSign;sign.Size=V(8.2,2.7,.5);sign.CFrame=CF(pos(x-9,34.1,z+16.3))*CFrame.Angles(0,math.pi,0);sign.Color=palette.dark;sign.Material=Enum.Material.Wood;sign.CanCollide=false;sign.CanQuery=false
 local gui=sign:FindFirstChildOfClass('SurfaceGui');if gui then gui.Face=Enum.NormalId.Front;gui.LightInfluence=.25;local text=gui:FindFirstChildWhichIsA('TextLabel');if text then text.Text=string.format('GARDEN  %02d',i);text.Font=Enum.Font.GothamBold;text.TextColor3=palette.trim;text.BackgroundTransparency=1 end end
 for _,dx in {-11.7,-6.3} do part('SignPost',V(.45,2.8,.45),x+dx,32.5,z+16.3,palette.wood,Enum.Material.Wood,detail,false) end
 path('Plot'..i..'Apron',x,z+16.4,35,5.2)
 -- Clear front-right pocket for future plot props.
 for _,dz in {-8,0,8} do part('SidePaver',V(2.1,.12,3.5),x+18,31.15,z+dz,palette.trim,Enum.Material.Limestone,detail,false) end
end
-- Pond asset and bridge aligned across water, with both ends joining paths.
local pond=cloneAt(assets['Basic Pond'],'Basic Pond',49,53,30.8,3.75,0,water)
for _,v in pond:GetDescendants() do if v:IsA('BasePart') then
 if v.Name=='Water' then v.Color=rgb(78,172,178);v.Material=Enum.Material.Glass;v.Transparency=.16;v.Reflectance=.08
 elseif v.Name=='Rocks' then v.Color=rgb(153,158,137);v.Material=Enum.Material.Slate
 elseif v.Name=='Dirt' then v.Color=rgb(129,115,86) end
end end
local bridge=cloneAt(assets['Koi Pond Bridge'],'Koi Pond Bridge',49,53,31.28,8.3,0,water)
for _,v in bridge:GetDescendants() do if v:IsA('BasePart') then v.Color=rgb(157,111,73);v.CanCollide=true;v.CanQuery=true end end
path('PondApproach',20,53,23,8.5)
path('PondFarLanding',71,53,9,10)
path('PondLoop',71,40,8,27)
board('PondWalkSign','POND WALK',25,43,10)
-- Supplied vegetable garden forms a dedicated small kitchen-garden parterre.
local veg=cloneAt(assets['Vegetable Garden'],'Vegetable Garden',-46,55,31.05,1.72,0,nursery)
veg:SetAttribute('SourceAssetId',93660859808046)
path('KitchenGardenWalk',-24,56,8,40)
path('KitchenGardenApproach',-34,77,27,7)
board('KitchenGardenSign','KITCHEN GARDEN',-46,79,14)
-- Low-cost stylized vegetables occupy the supplied soil rows.
for _,x in {-59,-53,-39,-33} do for r=0,5 do local z=41+r*5.2
 if (r+math.floor(x))%2==0 then
  local p=part('Cabbage',V(1.65,1.25,1.65),x,32.45,z,rgb(133,177,84),Enum.Material.SmoothPlastic,nursery,false);p.Shape=Enum.PartType.Ball
  local leaf=part('CabbageLeaf',V(2.1,.42,1.4),x,32.05,z,rgb(75,125,64),Enum.Material.SmoothPlastic,nursery,false);leaf.Shape=Enum.PartType.Ball
 else
  local p=part('CarrotTop',V(.8,.9,.8),x,32.23,z,rgb(230,145,64),Enum.Material.SmoothPlastic,nursery,false);p.Shape=Enum.PartType.Ball
  local leaf=part('CarrotLeaves',V(1.35,1.25,.5),x,33,z,rgb(89,153,70),Enum.Material.SmoothPlastic,nursery,false);leaf.Shape=Enum.PartType.Ball
 end
end end
-- Arrival arbor: warm cedar, cream lettering, and clear headroom.
for _,x in {-10,10} do
 part('ArborStoneFoot',V(2,1.1,2),x,31.55,84,palette.trim,Enum.Material.Limestone,decor,false)
 part('ArborPost',V(1.05,12,1.05),x,37,84,palette.wood,Enum.Material.Wood,decor,false)
end
part('ArborBeam',V(24,1,1.6),0,42.5,84,palette.dark,Enum.Material.Wood,decor,false)
for _,x in {-10,-5,0,5,10} do part('ArborRafter',V(.6,.5,5.5),x,43.2,84,palette.wood,Enum.Material.Wood,decor,false) end
local main=g.GardenMainSign;main.Size=V(17.5,3,.6);main.CFrame=CF(pos(0,40.7,84))*CFrame.Angles(0,math.pi,0);main.Color=palette.dark;main.Material=Enum.Material.Wood;main.CanCollide=false
local gui=main:FindFirstChildOfClass('SurfaceGui');gui.Face=Enum.NormalId.Front;local t=gui:FindFirstChildWhichIsA('TextLabel');t.Text='THE GARDEN';t.Font=Enum.Font.GothamBold;t.TextColor3=palette.trim;t.BackgroundTransparency=1
label(main,'THE GARDEN',Enum.NormalId.Back)
g.GardenArrival.CFrame=CF(pos(0,31.65,76));g.GardenReturnFallback.CFrame=CF(pos(0,31.65,72))
-- Keep the existing return portal and prompt together.
local gate=g.ReturnPortal;gate.Size=V(6,7,.5);gate.CFrame=CF(pos(0,34.8,-76));gate.Color=rgb(137,192,177);gate.Transparency=.45;gate.CanCollide=false
for _,x in {-4.3,4.3} do part('ReturnGatePost',V(1.3,9,1.5),x,35.5,-76,palette.dark,Enum.Material.Wood,decor,false) end
part('ReturnGateCap',V(11,1.3,2),0,40,-76,palette.wood,Enum.Material.Wood,decor,false)
board('ReturnWayfinding','RETURN TO KINGDOM',0,-76,15).Position=pos(0,42.1,-76)
-- Existing shop and preview props get a compact potting shelter in the rear.
local counter=g.ShopCounter;counter.Size=V(10,2.6,3);counter.CFrame=CF(pos(-28,32.5,-74));counter.Color=palette.wood;counter.Material=Enum.Material.Wood
local awning=g.ShopAwning;awning.Size=V(13,.6,8);awning.CFrame=CF(pos(-28,38.6,-75));awning.Color=palette.dark;awning.Material=Enum.Material.Wood
for _,x in {-33.5,-22.5} do part('PottingShelterPost',V(.55,7,.55),x,34.5,-77,palette.wood,Enum.Material.Wood,decor,false) end
local ss=g.ShopSign;ss.Size=V(10,2,.4);ss.CFrame=CF(pos(-28,37,-72))*CFrame.Angles(0,math.pi,0);ss.Color=palette.dark;ss.CanCollide=false
local sg=ss:FindFirstChildOfClass('SurfaceGui');sg.Face=Enum.NormalId.Front;local st=sg:FindFirstChildWhichIsA('TextLabel');st.TextColor3=palette.trim;st.BackgroundTransparency=1
path('PottingShelterApron',-28,-72,15,10)
local preview=g.PreviewStage;preview.Size=V(10,.5,8);preview.CFrame=CF(pos(28,31.5,-74));preview.Color=palette.stone;preview.Material=Enum.Material.Limestone
local ps=g.PreviewSign;ps.Size=V(11,2,.5);ps.CFrame=CF(pos(28,34.5,-79))*CFrame.Angles(0,math.pi,0);ps.Color=palette.dark;ps.CanCollide=false
local pg=ps:FindFirstChildOfClass('SurfaceGui');pg.Face=Enum.NormalId.Front;local pt=pg:FindFirstChildWhichIsA('TextLabel');pt.TextColor3=palette.trim;pt.BackgroundTransparency=1
-- Short fence runs vary with the planting pockets, leaving destinations open.
local function fence(x,z,yaw) return cloneAt(assets['Wooden Fence'],'Wooden Fence',x,z,31,4.7,yaw,fences) end
for _,x in {-75,-65,-55,-35,-25,25,35,55,65,75} do fence(x,-87,0) end
for _,z in {-60,-50,-15,-5,30,40,70} do fence(-86,z,90);fence(86,z,90) end
for _,x in {-68,-58,58,68} do fence(x,86,0) end
-- Existing imported oak/willow assets frame the garden without covering plot fronts.
local treePositions={{-94,-80,29},{-77,-96,32},{-51,-97,30},{-8,-98,31},{19,-99,34},{50,-97,29},{77,-96,33},{96,-78,28},{-98,-50,29},{-97,-22,33},{-98,8,30},{-98,42,32},{-94,76,30},{-75,98,29},{-42,96,25},{-20,97,23},{20,97,24},{42,98,26},{73,97,31},{97,72,29},{98,38,31},{97,8,30},{97,-24,33},{97,-53,29}}
for i,p in treePositions do
 local src=(i%4==0) and W.Tree_Oak_5_V5_011 or W.Tree_Oak_1_V5_030
 cloneAt(src,'PerimeterOak_'..i,p[1],p[2],31,p[3],i*71,plants)
end
cloneAt(W.Willow_2_V5_006,'PondWillow',79,74,31,27,195,plants)
cloneAt(W.Willow_5_V5_035,'PondWillowSmall',80,10,31,24,50,plants)
cloneAt(W.Tree_Oak_5_V5_011,'KitchenGardenOak',-77,65,31,23,90,plants)
local function bush(x,z,h,yaw) return cloneAt(W.Forest_Decor_plant_bushDetailed_51,'GardenShrub',x,z,31,h or 3.5,yaw or 0,plants) end
for _,p in {{-76,-77},{-58,-82},{-45,-79},{48,-79},{61,-82},{77,-78},{-79,-40},{-77,3},{-77,35},{-76,79},{-58,88},{-29,85},{28,85},{54,84},{79,33},{81,-35},{-18,66},{18,66},{-16,36},{16,36}} do bush(p[1],p[2],3.3,(p[1]*7)%360) end
local flowerSource=W.MagicalForest_Decor_Flower_Violet_2_35
for i,p in {{-18,76},{18,76},{-17,40},{17,40},{-75,24},{75,24},{-76,-18},{76,-18},{-16,-59},{16,-59},{-59,-77},{58,-77},{35,70},{62,72},{32,35},{-70,77}} do
 cloneAt(flowerSource,'VioletCluster_'..i,p[1],p[2],31,2.8,i*43,plants)
 cloneAt(W.Flower_Daisy_3_V5_009,'DaisyCluster_'..i,p[1]+2,p[2]+1.6,31,2.4,i*67,plants)
end
-- Flower urns flank the court and arrival, away from circulation.
for i,p in {{-13,84},{13,84},{-16,-1},{16,-1}} do
 disk('PlanterFoot',p[1],31.25,p[2],3.4,.4,palette.trim,decor,false)
 disk('TerracottaPlanter',p[1],32,p[2],2.8,1.4,rgb(184,123,90),decor,false)
 cloneAt(flowerSource,'PlanterBlooms_'..i,p[1],p[2],32.75,3.2,i*70,plants)
end
-- A few existing lantern meshes, with restrained local lighting.
for i,p in {{-11,65},{11,65},{-12,27},{12,27},{-13,-20},{13,-20},{-65,-64},{65,-64},{28,53},{71,39}} do
 local lamp=cloneAt(W.LampR2,'GardenLantern_'..i,p[1],p[2],31,6.5,0,decor)
 local lpart=lamp:FindFirstChildWhichIsA('BasePart',true)
 local a=Instance.new('Attachment');a.Position=V(0,2.4,0);a.Parent=lpart
 local light=Instance.new('PointLight');light.Color=rgb(255,222,158);light.Range=11;light.Brightness=.35;light.Shadows=false;light.Parent=a
end
-- Two quiet seats along the open court, using a compact six-part construction.
for _,x in {-24,24} do local z=-3
 part('GardenBenchSeat',V(2.8,.4,8),x,33,z,palette.wood,Enum.Material.Wood,decor,false)
 part('GardenBenchBack',V(.35,2,8),x+(x<0 and -1.3 or 1.3),34,z,palette.dark,Enum.Material.Wood,decor,false)
 for _,dz in {-2.8,2.8} do part('GardenBenchLeg',V(2.3,1.7,.55),x,31.95,z+dz,palette.dark,Enum.Material.Wood,decor,false) end
end
-- Clean preview staging and mark the edit as one reviewable visual checkpoint.
if W:FindFirstChild('GardenAssetPreview_TEMP') then W.GardenAssetPreview_TEMP:Destroy() end
g:SetAttribute('GardenVisualDesign','Cedar and Willow Garden / 2026-09-22')
g:SetAttribute('PhysicalGardenPlotCount',#playerPlots)
g:SetAttribute('VisualOnlyRedesign',true)
local n=0;for _,v in g:GetDescendants() do if v:IsA('BasePart') then n+=1 end end
game:GetService('ChangeHistoryService'):SetWaypoint('Garden Visual Redesign - Four Plots')
return {playerPlots=#playerPlots,gardenPlots=#coords,parts=n,footprint='224 x 216',soil='30 x 24',scriptsAdded=0}
