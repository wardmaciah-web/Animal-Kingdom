-- Extension of TreePresentation's existing pool/tick/budget, with no extra heartbeat.
local M={}
local palette={
 Jungle={Color3.fromRGB(213,233,148),-1.1,"LeavesAndPollen"},
 Desert={Color3.fromRGB(226,192,135),.1,"DriftingSand"},
 Snow={Color3.fromRGB(220,244,255),-1.4,"SnowAndIce"},
 Volcano={Color3.fromRGB(255,149,65),1.5,"EmbersAndAsh"},
 Ocean={Color3.fromRGB(152,230,247),1.1,"Bubbles"},
 AncientRuins={Color3.fromRGB(215,198,151),.05,"SacredDust"},
 MagicalForest={Color3.fromRGB(184,167,255),.1,"SporesAndFireflies"},
 Sky={Color3.fromRGB(246,216,240),-.4,"CloudPetals"},
 Prehistoric={Color3.fromRGB(174,204,141),-.7,"AncientLeaves"},
 Mythical={Color3.fromRGB(232,198,255),.25,"CelestialGlints"},
}
local pool={};local lastBiome;local owner;local delegatedMotion=false
local motion=setmetatable({}, {__mode="k"})
local Tween=game:GetService("TweenService")
function M.Init(folder,hasExistingVegetationMotion)
 owner=folder;delegatedMotion=hasExistingVegetationMotion==true
 for i=1,4 do
  local p=Instance.new("Part");p.Name="FutureBiomeAir"..i;p.Size=Vector3.new(12,7,12);p.Anchored=true;p.Transparency=1;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.CastShadow=false;p.Parent=folder
  local e=Instance.new("ParticleEmitter");e.Name="FutureBiomeParticles";e.Texture="rbxasset://textures/particles/sparkles_main.dds";e.Rate=0;e.Lifetime=NumberRange.new(2.5,4);e.Speed=NumberRange.new(.4,1.4);e.SpreadAngle=Vector2.new(180,180);e.Rotation=NumberRange.new(0,360);e.RotSpeed=NumberRange.new(-25,25)
  e.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,.06),NumberSequenceKeypoint.new(.2,.22),NumberSequenceKeypoint.new(1,.04)})
  e.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.18,.15),NumberSequenceKeypoint.new(.75,.45),NumberSequenceKeypoint.new(1,1)});e.Parent=p
  pool[i]={Anchor=p,Emitter=e}
 end
end
function M.Update(root,biome,quality,wind,time)
 local style=palette[biome]
 if biome~=lastBiome then for _,p in pool do p.Emitter:Clear() end;lastBiome=biome end
 for _,p in pool do p.Emitter.Rate=0 end
 if not style then
  for part,entry in motion do if entry.Tween then entry.Tween:Cancel();entry.Tween:Destroy() end;if part.Parent then part.CFrame=entry.Base end;motion[part]=nil end
  if owner then owner:SetAttribute("FutureParticleRate",0) end;return 0
 end
 local Collection=game:GetService("CollectionService")
 local nearest={}
 for _,visual in Collection:GetTagged("FutureBiomeTreeVisual") do
  if visual:IsDescendantOf(workspace) and visual:GetAttribute("BiomeId")==biome then
   local cf,size=visual:GetBoundingBox();local delta=cf.Position-root.Position
   local d=Vector2.new(delta.X,delta.Z).Magnitude
   if d<85 then table.insert(nearest,{Position=cf.Position,Size=size,Distance=d,Visual=visual}) end
  end
 end
 table.sort(nearest,function(a,b)return a.Distance<b.Distance end)
 local active={}
 if not delegatedMotion and (biome=="Snow" or biome=="Volcano") then
  local reduced=game.Players.LocalPlayer and game.Players.LocalPlayer:GetAttribute("AKReducedMotion")
  for i=1,math.min(#nearest,math.ceil(8*quality)) do
   for _,part in nearest[i].Visual:GetDescendants() do if part:IsA("MeshPart") and part.Name:find("Leaves_",1,true) then
    active[part]=true;local entry=motion[part];if not entry then entry={Base=part.CFrame};motion[part]=entry end
    if entry.Tween then entry.Tween:Cancel();entry.Tween:Destroy() end
    local amplitude=(reduced and .001 or .009)*math.min(1.5,math.max(.3,wind))
    local phase=time*.85+entry.Base.X*.08+entry.Base.Z*.04
    entry.Tween=Tween:Create(part,TweenInfo.new(.24,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{CFrame=entry.Base*CFrame.Angles(math.sin(phase)*amplitude,0,math.cos(phase*.7)*amplitude*.65)})
    entry.Tween:Play()
   end end
  end
 end
 for part,entry in motion do if not active[part] then if entry.Tween then entry.Tween:Cancel();entry.Tween:Destroy() end;if part.Parent then part.CFrame=entry.Base end;motion[part]=nil end end
 local sum=0
 for i,p in pool do local tree=nearest[i]
  if tree then
   p.Anchor.Position=Vector3.new(tree.Position.X,root.Position.Y+math.min(9,tree.Size.Y*.45),tree.Position.Z)
   local e=p.Emitter;e.Name=style[3];e.Color=ColorSequence.new(style[1]);e.Acceleration=Vector3.new(wind*.35,style[2],wind*.12)
   e.LightEmission=(biome=="Volcano" or biome=="MagicalForest" or biome=="Mythical" or biome=="Ocean") and .8 or .15
   e.Texture=(biome=="Desert" or biome=="AncientRuins" or biome=="Prehistoric") and "rbxasset://textures/particles/smoke_main.dds" or "rbxasset://textures/particles/sparkles_main.dds"
   if biome=="Mythical" then e.Color=ColorSequence.new(style[1],Color3.fromRGB(125,224,224)) end
   e.Rate=math.max(0,1-tree.Distance/100)*12*quality;sum+=e.Rate
  end
 end
 owner:SetAttribute("FutureParticleRate",sum);owner:SetAttribute("FutureBiomeStyle",style[3])
 return sum
end
function M.FoliageCount(biome,quality)
 return (biome=="Jungle" or biome=="Prehistoric" or biome=="Sky") and math.ceil(16*quality) or 0
end
function M.StyleLeaf(item,biome)
 if not palette[biome] then return end
 item.Art.ImageColor3=palette[biome][1]
 if biome=="Sky" then item.IsLeaf=false;item.Art.Visible=false;item.Leaf.BackgroundColor3=Color3.fromRGB(245,215,234) end
end
return M