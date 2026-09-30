local Formation = require("../src/ReplicatedStorage/Shared/Gameplay/FollowerFormation")
local function near(a,b) assert(math.abs(a-b)<1e-7, tostring(a).." ~= "..tostring(b)) end
for count=1,12 do
 local points={};local sum=0
 for i=1,count do
  local x,z=Formation.Offset(i,count,3.5);sum+=x
  assert(z>=4.5)
  for _,p in ipairs(points) do assert(math.sqrt((x-p[1])^2+(z-p[2])^2)>=3.49,"followers overlap") end
  table.insert(points,{x,z})
 end
 near(sum,0)
end
local function approach(fps)
 local p=0
 for _=1,fps do p=p+(1-p)*Formation.Alpha(9,1/fps) end
 return p
end
near(approach(30),approach(60));near(approach(60),approach(144))
assert(Formation.Phase("a")==Formation.Phase("a"))
assert(Formation.Phase("a")~=Formation.Phase("b"))
print("PASS centered and separated formations 1–12, stable phases, equivalent 30/60/144 Hz smoothing")
