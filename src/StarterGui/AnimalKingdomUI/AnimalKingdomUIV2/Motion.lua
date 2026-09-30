local TweenService=game:GetService("TweenService")
local Players=game:GetService("Players")
local Theme=require(script.Parent.Theme)
local M={}
local running=setmetatable({},{__mode="k"})
function M.Reduced() local p=Players.LocalPlayer;return p and p:GetAttribute("AKReducedMotion")==true end
function M.Tween(object,kind,properties)
 local slots=running[object] or {};running[object]=slots
 if slots[kind] then slots[kind]:Cancel() end
 local t=TweenService:Create(object,TweenInfo.new(M.Reduced() and .01 or Theme.Motion[kind] or .2,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),properties)
 slots[kind]=t;t.Completed:Once(function()if slots[kind]==t then slots[kind]=nil end end);t:Play();return t
end
function M.Scale(object)
 local scale=object:FindFirstChild("MotionScale")
 if not scale then scale=Instance.new("UIScale");scale.Name="MotionScale";scale.Parent=object end
 return scale
end
function M.WindowOpen(object) object.Visible=true;local s=M.Scale(object);s.Scale=M.Reduced() and 1 or .96;return M.Tween(s,"WindowOpen",{Scale=1}) end
function M.WindowClose(object,done)
 local t=M.Tween(M.Scale(object),"WindowClose",{Scale=.96})
 t.Completed:Once(function(state) if state==Enum.PlaybackState.Completed then object.Visible=false;if done then done() end end end);return t
end
function M.ButtonHover(object,over) return M.Tween(M.Scale(object),"ButtonHover",{Scale=over and 1.035 or 1}) end
function M.ButtonPress(object) local t=M.Tween(M.Scale(object),"ButtonPress",{Scale=.965});t.Completed:Once(function()if object.Parent then M.ButtonHover(object,false) end end);return t end
function M.TabSelected(object,selected) return M.Tween(object,"TabSelected",{BackgroundColor3=selected and Theme.Color.Green or Theme.Color.Wood}) end
M.CardHover=M.ButtonHover
M.ModalOpen=M.WindowOpen;M.ModalClose=M.WindowClose
M.ToastIn=M.WindowOpen;M.ToastOut=M.WindowClose
function M.CounterChange(label,value,format)
 local previous=label:GetAttribute("CounterValue");label:SetAttribute("CounterValue",value);label.Text=format(value)
 if previous and value~=previous then M.ButtonPress(label) end
end
function M.ProgressChange(fill,value) return M.Tween(fill,"ProgressChange",{Size=UDim2.fromScale(math.clamp(value,0,1),1)}) end
function M.PetReveal(object) local s=M.Scale(object);s.Scale=M.Reduced() and 1 or .84;return M.Tween(s,"PetReveal",{Scale=1}) end
function M.UnlockReveal(object) return M.ButtonPress(object) end
return M
