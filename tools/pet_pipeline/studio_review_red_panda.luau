-- Exact 21b30d9 GLB native import. Review only; no rewards, unlocks or publication.
assert(game.PlaceId == 132313449035787 and game.GameId == 10764288431, "Wrong place")
assert(not game:GetService("RunService"):IsRunning(), "Edit mode only")
local root = assert(workspace:FindFirstChild("AK_JunglePetReview"))
local prior = assert(root:FindFirstChild("PlushStylizedReview"))
local folder = root:FindFirstChild("RedPandaTextureReview")
if not folder then folder=Instance.new("Folder"); folder.Name="RedPandaTextureReview"; folder.Parent=root end
local panda = folder:FindFirstChild("JungleRedPanda_Review")
if not panda then
    for _, model in workspace:GetChildren() do
        if model:IsA("Model") then
            for _, p in model:GetDescendants() do
                if p:IsA("MeshPart") and p.MeshId == "rbxassetid://101125666523290" then
                    assert(not panda, "Duplicate Red Panda native import")
                    panda=model
                end
            end
        end
    end
    assert(panda, "Native import missing; never fabricate a substitute")
    panda.Name="JungleRedPanda_Review"; panda.Parent=folder
end
local expected={ ["rbxassetid://101125666523290"]=true, ["rbxassetid://114629416154775"]=true }
local meshes={}
for _, p in panda:GetDescendants() do
    assert(not p:IsA("LuaSourceContainer"), "Unexpected script")
    if p:IsA("MeshPart") then
        assert(expected[p.MeshId], "Unexpected mesh")
        local s=p:FindFirstChildOfClass("SurfaceAppearance")
        assert((s and s.ColorMap or p.TextureID)=="rbxassetid://91899617902182", "Wrong color texture")
        if p.MeshId=="rbxassetid://101125666523290" then
            assert(s and s.NormalMap=="rbxassetid://86440326379848", "Missing body normal map")
        else p.CastShadow=false end
        table.insert(meshes,{mesh=p.MeshId,texture=p.TextureID,color=s and s.ColorMap,normal=s and s.NormalMap})
    end
end
assert(#meshes==2,"Expected two meshes")
panda:SetAttribute("SourceGLBSHA256","a9388ee117900de354169310c9396e7697009e5e5e26c410a9672db800a791fd")
panda:SetAttribute("ReviewOnly",true)
local function reference(name, source)
    local model=folder:FindFirstChild(name)
    if not model then model=source:Clone(); model.Name=name; model.Parent=folder end
    model:SetAttribute("ReviewOnly",true)
    return model
end
local bear=reference("OriginalBlackBear_Reference",assert(prior:FindFirstChild("OriginalBlackBear_StyleReference")))
local ocelot=reference("ApprovedOcelot_Reference",assert(prior:FindFirstChild("JungleOcelot_D_FreeReview")))
local floor=folder:FindFirstChild("NeutralComparisonFloor")
if not floor then floor=prior.NeutralComparisonFloor:Clone();floor.Parent=folder end
floor.Position=Vector3.new(44,999.9,140)
local rows={}
for i,model in {bear,panda,ocelot} do
    for _,p in model:GetDescendants() do
        assert(not p:IsA("LuaSourceContainer"), "Script in reference")
        if p:IsA("BasePart") then p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false end
    end
    local _,size=model:GetBoundingBox()
    model:ScaleTo(model:GetScale()*2.8/size.Y)
    local bounds,newSize=model:GetBoundingBox()
    local destination=Vector3.new(36+i*4,1000+newSize.Y/2,140)
    model:PivotTo(model:GetPivot()+destination-bounds.Position)
    local cf,s=model:GetBoundingBox()
    table.insert(rows,{name=model.Name,path=model:GetFullName(),height=s.Y,bottom=cf.Position.Y-s.Y/2})
end
workspace.CurrentCamera.CFrame=CFrame.lookAt(Vector3.new(44,1002.7,152),Vector3.new(44,1001.4,140))
game:GetService("Selection"):Set({panda})
return {place_id=string.format("%.0f",game.PlaceId),models=rows,meshes=meshes,folder=folder:GetFullName(),
    review_only=true,registered=false,published=false,lighting="shared existing world lighting, unchanged"}
