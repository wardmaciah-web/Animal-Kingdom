local A=game:GetService("AssetService")
local M={meshes={},report={}}
function M.Apply(model)
 for _,p in model:GetDescendants()do if p:IsA("MeshPart") and (p.Name=="body_geom" or p.Name:find("wing"))then
  local mesh=assert(A:CreateEditableMeshAsync(Content.fromUri(p.MeshId),{FixedSize=false}))
  local faces=mesh:GetFaces();local count=0
  for i,f in faces do if i%11==0 and count<110 then
   local ids=mesh:GetFaceVertices(f);local a,b,c=mesh:GetPosition(ids[1]),mesh:GetPosition(ids[2]),mesh:GetPosition(ids[3])
   local cross=(b-a):Cross(c-a);local edge=math.min((b-a).Magnitude,(c-b).Magnitude,(a-c).Magnitude)
   if cross.Magnitude>1e-6 and edge>.025 then
    local n=cross.Unit;local center=(a+b+c)/3
    local along=Vector3.yAxis-n*n.Y
    if along.Magnitude>.3 then
     along=along.Unit;local across=n:Cross(along).Unit;local radius=math.min(.07,edge*.32);center+=n*.002
     local uids=mesh:GetFaceUVs(f);local uv=(mesh:GetUV(uids[1])+mesh:GetUV(uids[2])+mesh:GetUV(uids[3]))/3
     local positions={center+along*radius,center+across*radius*.6,center-along*radius*1.35,center-across*radius*.6,center+n*radius*.28}
     local vs={};for _,pos in positions do table.insert(vs,mesh:AddVertex(pos))end
     local u=mesh:AddUV(uv)
     for j=1,4 do local face=mesh:AddTriangle(vs[j],vs[j%4+1],vs[5]);mesh:SetFaceUVs(face,{u,u,u})end
     count+=1
    end
   end
  end end
  local size,cf,ms,tex=p.Size,p.CFrame,p.MeshSize,p.TextureID
  local fresh=A:CreateMeshPartAsync(Content.fromObject(mesh));local newSize=size*fresh.MeshSize/ms
  p:ApplyMesh(fresh);p.Size=newSize;p.CFrame=cf;p.TextureID=tex;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false
  fresh:Destroy();table.insert(M.meshes,mesh);table.insert(M.report,{part=p.Name,featherOverlays=count,faces=#mesh:GetFaces()})
 end end
 return M.report
end
return M