local A=game:GetService("AssetService")
local M={meshes={},report={}}
function M.Apply(root)
 local p=root.RainstripeTapir:FindFirstChild("head_geom",true)
 local em=assert(A:CreateEditableMeshAsync(p.MeshContent,{FixedSize=false}))
 local count=0
 for _,v in em:GetVertices()do local pos=em:GetPosition(v)
  if math.abs(pos.X)<.15 and pos.Z>.2 and pos.Y>-.16 then em:SetPosition(v,Vector3.new(pos.X,math.min(pos.Y,.26),.12));count+=1 end
 end
 for _,n in em:GetNormals()do em:ResetNormal(n)end
 local size,cf,ms,tex=p.Size,p.CFrame,p.MeshSize,p.TextureID
 local fresh=A:CreateMeshPartAsync(Content.fromObject(em));local ns=size*fresh.MeshSize/ms
 p:ApplyMesh(fresh);p.Size=ns;p.CFrame=cf;p.TextureID=tex
 p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false
 fresh:Destroy();table.insert(M.meshes,em);M.report={collapsedCrestVertices=count};return M.report
end
return M