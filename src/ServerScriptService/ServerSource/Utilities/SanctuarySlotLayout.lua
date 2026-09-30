-- Explicit anchors take precedence. Imported display templates have a single measured layout.
local RS=game:GetService("ReplicatedStorage")
local Layouts=require(RS.Shared.Gameplay.Definitions.SanctuaryDisplayDefinitions)
local M={}
function M.FindDisplay(plot)
 if not plot then return nil end
 return plot.Parent:FindFirstChild("Plot"..tostring(plot:GetAttribute("PlotId")).."PetDisplay")
end
function M.Count(plot)
 local display=M.FindDisplay(plot)
 local folder=display and display:FindFirstChild("PetDisplaySlots",true)
 if folder then return #folder:GetChildren() end
 local count=0
 if display then for _,v in ipairs(display:GetChildren())do if v.Name:match("^PetSlot_%d+$")then count+=1 end end end
 return count
end
function M.Bind()
 local plots=workspace:FindFirstChild("PlayerPlots");if not plots then return end
 local floors={}
 for _,floor in ipairs(plots:GetChildren())do if floor:IsA("BasePart") and floor:GetAttribute("PlotId") then table.insert(floors,floor)end end
 local used={}
 for _,part in ipairs(workspace:GetDescendants())do
  local layout=part:IsA("MeshPart") and Layouts[part.MeshId:match("%d+")]
  if layout and part.Size.Magnitude>10 then
   local nearest,distance=nil,math.huge
   for _,floor in ipairs(floors)do local offset=part.Position-floor.Position;local d=Vector3.new(offset.X,0,offset.Z).Magnitude;if d<distance and d<floor.Size.X*.65 then nearest,distance=floor,d end end
   if nearest and not used[nearest] then
    local display=M.FindDisplay(nearest)
    if not display then display=Instance.new("Model");display.Name="Plot"..nearest:GetAttribute("PlotId").."PetDisplay";display.Parent=plots end
    local anchors=display:FindFirstChild("PetDisplaySlots")
    if not anchors then
     anchors=Instance.new("Folder");anchors.Name="PetDisplaySlots";anchors:SetAttribute("GeneratedPlacementAnchors",true);anchors.Parent=display
     local binding=Instance.new("ObjectValue");binding.Name="DisplayGeometry";binding.Value=part;binding.Parent=display
     local scale=part.Size/layout.MeshSize
     local rotation=part.CFrame.Rotation*CFrame.Angles(0,math.rad(layout.FacingYaw),0)
     for row,x in ipairs(layout.RowCenters)do for column,z in ipairs(layout.ColumnCenters)do
      local id=(row-1)*#layout.ColumnCenters+column
      local anchor=Instance.new("Part");anchor.Name=string.format("Slot_%03d",id)
      anchor.Size=Vector3.new(.15,.05,.15);anchor.Anchored=true;anchor.Transparency=1;anchor.CanCollide=false;anchor.CanTouch=false;anchor.CanQuery=false
      anchor.CFrame=CFrame.new(part.CFrame:PointToWorldSpace(Vector3.new(x,layout.SurfaceHeights[row][column],z)*scale))*rotation
      anchor:SetAttribute("SlotId",id);anchor:SetAttribute("Row",row);anchor:SetAttribute("Column",column)
      anchor:SetAttribute("UsableWidth",layout.UsableWidth*scale.Z);anchor:SetAttribute("UsableDepth",layout.UsableDepth*scale.X);anchor:SetAttribute("VisibleHeight",layout.VisibleHeight*scale.Y)
      anchor:SetAttribute("FootprintFill",.82);anchor:SetAttribute("SurfaceSource","MeasuredVisibleMesh");anchor.Parent=anchors
     end end
    end
    display:SetAttribute("SlotCapacity",#anchors:GetChildren());used[nearest]=true
   end
  end
 end
end
return M
