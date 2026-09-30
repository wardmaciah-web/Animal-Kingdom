local Players=game:GetService("Players")
local Guard={}
local calls=setmetatable({},{__mode="k"})
function Guard.IsPlayer(player)
 return typeof(player)=="Instance" and player:IsA("Player") and player.Parent==Players
end
function Guard.Finite(value) return type(value)=="number" and value==value and math.abs(value)<math.huge end
function Guard.Id(value) return type(value)=="string" and #value>0 and #value<=80 end
function Guard.RateLimit(player,key,interval)
 if not Guard.IsPlayer(player) then return false end
 local now=os.clock();local record=calls[player] or {};calls[player]=record
 if record[key] and now-record[key]<interval then return false end
 record[key]=now;return true
end
function Guard.Alive(player)
 if not Guard.IsPlayer(player) then return nil end
 local character=player.Character
 local root=character and character:FindFirstChild("HumanoidRootPart")
 local humanoid=character and character:FindFirstChildOfClass("Humanoid")
 if not root or not root:IsA("BasePart") or not humanoid or humanoid.Health<=0 then return nil end
 return root
end
function Guard.IsNear(player,instance,maxDistance)
 local root=Guard.Alive(player)
 if not root or typeof(instance)~="Instance" or not instance:IsDescendantOf(workspace) then return false end
 local position
 if instance:IsA("Model") then position=instance:GetPivot().Position
 elseif instance:IsA("BasePart") then position=instance.Position
 else return false end
 return (root.Position-position).Magnitude<=maxDistance
end
function Guard.Shape(payload,fields)
 if type(payload)~="table" then return false end
 local count=0
 for key,value in pairs(payload) do
  count+=1
  if count>8 or type(key)~="string" or not fields[key] or not fields[key](value) then return false end
 end
 for key in pairs(fields) do if payload[key]==nil then return false end end
 return true
end
return Guard
