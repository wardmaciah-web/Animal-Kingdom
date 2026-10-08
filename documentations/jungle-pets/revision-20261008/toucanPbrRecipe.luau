local A=game:GetService("AssetService")
local H=game:GetService("HttpService")
local M={images={},meshes={},report={}}
local function constant(value)
 local im=assert(A:CreateEditableImage({Size=Vector2.new(16,16)}))
 local b=buffer.create(1024)
 for i=0,255 do for c=0,2 do buffer.writeu8(b,i*4+c,value)end;buffer.writeu8(b,i*4+3,255)end
 im:WritePixelsBuffer(Vector2.zero,im.Size,b);table.insert(M.images,im);return im
end
function M.Apply(root)
 local rough,metal=constant(238),constant(0)
 for _,name in {"CanopyToucan"} do
  local model=root[name]
  for _,p in model:GetDescendants() do if p:IsA("MeshPart") then
   local source=assert(A:CreateEditableImageAsync(Content.fromUri(p.TextureID)))
   local input=source:ReadPixelsBuffer(Vector2.zero,source.Size);local sw,sh=source.Size.X,source.Size.Y
   local size=512;local color=assert(A:CreateEditableImage({Size=Vector2.new(size,size)}));local normal=assert(A:CreateEditableImage({Size=Vector2.new(size,size)}))
   local cb,nb=buffer.create(size*size*4),buffer.create(size*size*4)
   local function luminance(x,y)
    local sx=math.clamp(math.floor(x*sw/size),0,sw-1);local sy=math.clamp(math.floor(y*sh/size),0,sh-1);local i=(sy*sw+sx)*4
    return (buffer.readu8(input,i)*.2126+buffer.readu8(input,i+1)*.7152+buffer.readu8(input,i+2)*.0722)/255
   end
   for y=0,size-1 do for x=0,size-1 do
    local si=(math.floor(y*sh/size)*sw+math.floor(x*sw/size))*4;local i=(y*size+x)*4
    local dark=math.max(buffer.readu8(input,si),buffer.readu8(input,si+1),buffer.readu8(input,si+2))<45
    local strand=math.sin(x*2.3+y*.18)*math.sin(y*.9+x*.05)
    local grain=((x*73+y*151+x*y*3)%29)/28-.5
    local variation=dark and 0 or strand*8+grain*5
    for c=0,2 do buffer.writeu8(cb,i+c,math.clamp(math.floor(buffer.readu8(input,si+c)+variation),0,255))end;buffer.writeu8(cb,i+3,255)
    local dx=(luminance(x+1,y)-luminance(x-1,y))*.3+(dark and 0 or math.cos(x*2.3+y*.18)*.045)
    local dy=(luminance(x,y+1)-luminance(x,y-1))*.3+(dark and 0 or strand*.02)
    local n=Vector3.new(-dx,-dy,1).Unit
    buffer.writeu8(nb,i,math.floor((n.X*.5+.5)*255));buffer.writeu8(nb,i+1,math.floor((n.Y*.5+.5)*255));buffer.writeu8(nb,i+2,math.floor((n.Z*.5+.5)*255));buffer.writeu8(nb,i+3,255)
   end end
   color:WritePixelsBuffer(Vector2.zero,color.Size,cb);normal:WritePixelsBuffer(Vector2.zero,normal.Size,nb);source:Destroy()
   for _,sa in p:GetChildren()do if sa:IsA("SurfaceAppearance")then sa:Destroy()end end
   local sa=Instance.new("SurfaceAppearance");sa.Name="AK_JungleReviewPBR"
   sa.ColorMapContent=Content.fromObject(color);sa.NormalMapContent=Content.fromObject(normal);sa.RoughnessMapContent=Content.fromObject(rough);sa.MetalnessMapContent=Content.fromObject(metal);sa.Parent=p
   table.insert(M.images,color);table.insert(M.images,normal)
   table.insert(M.report,{pet=name,part=p.Name,sourceMesh=p.MeshId,sourceTexture=p.TextureID,pbrResolution=size,roughness=238/255,metalness=0})
  end end
 end
 return M.report
end
return M