local A=game:GetService("AssetService")
local M={meshes={},report={}}
function M.Apply(root)
 for _,name in {"RainstripeTapir","CanopyToucan"} do
  local model=root[name]
  for _,p in model:GetDescendants() do if p:IsA("MeshPart") and (p.Name=="head_geom" or (name=="RainstripeTapir" and p.Name=="body_geom")) then
   local em=assert(A:CreateEditableMeshAsync(Content.fromUri(p.MeshId),{FixedSize=false}))
   local changed,crest=0,0
   for _,v in em:GetVertices() do
    local pos=em:GetPosition(v);local q=pos
    if name=="RainstripeTapir" then
     if p.Name=="head_geom" and math.abs(pos.X)<.145 and pos.Z>-.42 then
      local cap=.40-.40*math.max(0,pos.Z)
      if pos.Y>cap then q=Vector3.new(pos.X,cap,pos.Z);crest+=1 end
     end
     if p.Name=="head_geom" then
      local center=Vector3.new(pos.X<0 and -.40 or .40,.015,-.57)
      local d=Vector3.new((pos.X-center.X)/.22,(pos.Y-center.Y)/.24,(pos.Z-center.Z)/.28).Magnitude
      if d<1.3 then local t=math.max(0,1-d/1.3);local scale=1+.85*t
       q=Vector3.new(q.X+(pos.X<0 and -.025 or .025)*t,center.Y+(q.Y-center.Y)*scale,center.Z+(q.Z-center.Z)*scale)
      end
     elseif math.abs(pos.X)<.14 and pos.Y>.65 then q=Vector3.new(pos.X,.65,pos.Z);crest+=1 end
    elseif p.Name=="head_geom" then
     local center=Vector3.new(pos.X<0 and -.50 or .50,-.04,.50)
     local d=Vector3.new((pos.X-center.X)/.22,(pos.Y-center.Y)/.22,(pos.Z-center.Z)/.22).Magnitude
     if d<1.5 then local t=math.max(0,1-d/1.5);local scale=1+.75*t;q=Vector3.new(q.X+(pos.X<0 and -.02 or .02)*t,center.Y+(q.Y-center.Y)*scale,center.Z+(q.Z-center.Z)*scale)end
    end
    if (q-pos).Magnitude>1e-6 then em:SetPosition(v,q);changed+=1 end
   end
   for _,n in em:GetNormals()do em:ResetNormal(n)end
   local originalSize,originalCF,texture=p.Size,p.CFrame,p.TextureID
   local originalMeshSize=p.MeshSize
   local fresh=A:CreateMeshPartAsync(Content.fromObject(em))
   local targetSize=originalSize*fresh.MeshSize/originalMeshSize
   p:ApplyMesh(fresh);p.Size=targetSize;p.CFrame=originalCF;p.TextureID=texture
   p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false
   fresh:Destroy();table.insert(M.meshes,em)
   table.insert(M.report,{pet=name,part=p.Name,changedVertices=changed,crestVertices=crest,faces=#em:GetFaces(),vertices=#em:GetVertices()})
  end end
 end
 return M.report
end
return M