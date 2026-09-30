local Players=game:GetService("Players")
local Input=game:GetService("UserInputService")
local player=Players.LocalPlayer
local C={};local owner;local serial=0
function C.RestorePlayer()
 if owner then return false end
 local camera=workspace.CurrentCamera
 local humanoid=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
 if camera then camera.CameraType=Enum.CameraType.Custom;camera.CameraSubject=humanoid end
 Input.MouseBehavior=Enum.MouseBehavior.Default;Input.MouseIconEnabled=true
 return true
end
function C.Acquire(name,apply,onRevoked)
 if owner and owner.Revoked then owner.Revoked() end
 serial+=1;local token={Id=serial,Name=name,Apply=apply,Revoked=onRevoked};owner=token
 apply(workspace.CurrentCamera)
 return token
end
function C.Release(token)
 if owner~=token then return false end
 owner=nil;return C.RestorePlayer()
end
function C.Current()return owner and owner.Name end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()if owner then owner.Apply(workspace.CurrentCamera)else C.RestorePlayer()end end)
player.CharacterRemoving:Connect(function()local old=owner;owner=nil;if old and old.Revoked then old.Revoked()end;C.RestorePlayer()end)
player.CharacterAdded:Connect(function(char)task.spawn(function()char:WaitForChild("Humanoid",8);if char==player.Character then C.RestorePlayer()end end)end)
return C
