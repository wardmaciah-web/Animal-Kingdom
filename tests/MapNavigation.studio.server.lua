assert(game:GetService('RunService'):IsRunning() and game:GetService('RunService'):IsServer(),'Server Play context required')
task.spawn(function()
 local Landing=require(game.ServerScriptService.BiomeTeleport.Landing)
 local names=require(game.ServerScriptService.BiomeTeleport.Destinations)
 local Pathfinder=game:GetService('PathfindingService')
 local failures=0
 local destination=workspace.TownPlaza.Position+Vector3.new(0,4,100)
 local common=workspace:GetAttribute('AK_CommonPlayableFloorY')
 local markerFolder=workspace.BiomeTeleportPoints
 for name,id in pairs(names) do
  local floor=Landing.FindFloor(id)
  local marker=markerFolder:FindFirstChild(name)
  local point=marker and Landing.Check(marker.Position,floor)
  local clear=point~=nil
  print('[MapNavigation] '..(clear and 'PASS ' or 'FAIL ')..id..' teleport clearance')
  if not clear then failures+=1 end
  assert(math.abs(floor.Position.Y+floor.Size.Y/2-common)<.001,id..' floor alignment')
  if point then
   local path=Pathfinder:CreatePath({AgentRadius=2,AgentHeight=6,AgentCanJump=true,WaypointSpacing=8})
   local ok,err=pcall(function() path:ComputeAsync(point+Vector3.new(0,3,0),destination) end)
   local passed=ok and path.Status==Enum.PathStatus.Success
   print('[MapNavigation] '..(passed and 'PASS ' or 'FAIL ')..id..' route to Town '..tostring(path.Status)..' '..tostring(err or ''))
   if not passed then failures+=1 end
   path:Destroy()
  end
 end
 for _,p in ipairs(require(game.ServerScriptService.PlotLocator).getPlots()) do
  local path=Pathfinder:CreatePath({AgentRadius=2,AgentHeight=6,AgentCanJump=true})
  local ok=pcall(function() path:ComputeAsync(p.Position+Vector3.new(0,4,0),destination) end)
  local passed=ok and path.Status==Enum.PathStatus.Success
  print('[MapNavigation] '..(passed and 'PASS ' or 'FAIL ')..p.Name..' route to Town '..tostring(path.Status))
  if not passed then failures+=1 end
  path:Destroy()
 end
 print('[MapNavigation] COMPLETE failures='..failures)
end)
