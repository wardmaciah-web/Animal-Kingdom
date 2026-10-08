local A=game:GetService("AssetService")
local M={meshes={}}
function M.Apply(root)
 local p=root.RainstripeTapir:FindFirstChild("body_geom",true)
 local em=assert(A:CreateEditableMeshAsync(p.MeshContent,{FixedSize=false}));local count=0
 for _,v in em:GetVertices()do local pos=em:GetPosition(v);local cap=.48-.20*math.max(0,pos.Z)
 if math.abs(pos.X)<.38 and pos.Z>.10 and pos.Y>cap then em:SetPosition(v,Vector3.new(pos.X,cap,pos.Z));count+=1 end end
 for _,n in em:GetNormals()do em:ResetNormal(n)end
 local size,cf,ms,tex=p.Size,p.CFrame,p.MeshSize,p.TextureID;local fresh=A:CreateMeshPartAsync(Content.fromObject(em))
 local ns=size*fresh.MeshSize/ms;p:ApplyMesh(fresh);p.Size=ns;p.CFrame=cf;p.TextureID=tex;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false
 fresh:Destroy();table.insert(M.meshes,em);return {changedVertices=count}
end
return M