-- Shared pose math only. ResourceService retains its existing reward/cooldown lifecycle.
local M={Duration=.8}
function M.Pose(pivot,elapsed)
 local t=math.clamp(elapsed,0,M.Duration)
 return pivot*CFrame.Angles(0,0,math.sin(t*30)*.035*(1-t/M.Duration))
end
function M.Capture(model)
 local state={Object=model,Pivot=model:GetPivot(),Parts={}}
 for _,part in ipairs(model:GetDescendants())do if part:IsA("BasePart")then state.Parts[part]=part.CFrame end end
 return state
end
function M.Restore(state)
 if not state.Object.Parent then return end
 state.Object:PivotTo(state.Pivot)
 for part,cf in pairs(state.Parts)do if part.Parent then part.CFrame=cf end end
end
return M
