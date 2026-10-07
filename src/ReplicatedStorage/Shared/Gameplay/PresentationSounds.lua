local Definitions=require(script.Parent.Definitions.GameplayEffectsDefinitions)
local Debris=game:GetService("Debris")
local Service=game:GetService("SoundService")
local Tween=game:GetService("TweenService")
local Players=game:GetService("Players")
local Sounds={};local last={};local active=0;local duckSerial=0
local groups={}
for _,id in ipairs({"Music","Ambience","SFX"})do
 local group=Service:FindFirstChild(id)
 if not group then group=Instance.new("SoundGroup");group.Name=id;group.Volume=1;group.Parent=Service end
 groups[id]=group
end
function Sounds.Duck(seconds)
 local p=Players.LocalPlayer;if not p then return end
 duckSerial+=1;local serial=duckSerial
 Tween:Create(groups.Music,TweenInfo.new(.18),{Volume=(p:GetAttribute("AKMusicVolume")or 1)*.35}):Play()
 task.delay(seconds or 2,function()if serial==duckSerial then Tween:Create(groups.Music,TweenInfo.new(.6),{Volume=p:GetAttribute("AKMusicVolume")or 1}):Play()end end)
end
function Sounds.Play(id,parent)
 local def=Definitions[id]
 if not def or def.SoundId==""then return end
 local now=os.clock();if active>=16 or(last[id]and now-last[id]<(def.Debounce or .065))then return end;last[id]=now
 local sound=Instance.new("Sound");sound.Name=id;sound.SoundId=def.SoundId;sound.Volume=def.Volume;sound.PlaybackSpeed=def.Pitch or 1
 sound.SoundGroup=groups[def.Group or "SFX"] or groups.SFX;sound.RollOffMinDistance=8;sound.RollOffMaxDistance=55;sound.Parent=parent or Service
 active+=1;local released=false
 local function release()if released then return end;released=true;active=math.max(0,active-1)end
 sound.Destroying:Once(release);sound.Ended:Once(function()release();sound:Destroy()end)
 sound:Play();Debris:AddItem(sound,def.Duration or 8)
 if id=="LegendaryFound"or id=="SecretFound"or id=="MaxWeight"then Sounds.Duck(4)elseif id=="PetReveal"then Sounds.Duck(1)end
end
-- Approved original asset is deliberately unset until generation cost and audio rights are confirmed.
function Sounds.SetMusic(assetId)
 if type(assetId)~="string"or not assetId:match("^rbxassetid://%d+$")then return false end
 local old=Service:FindFirstChild("KingdomSignature")
 if old and old.SoundId==assetId then if not old.IsPlaying then old:Play()end return true end
 local sound=Instance.new("Sound");sound.Name="KingdomSignature";sound.SoundId=assetId;sound.SoundGroup=groups.Music;sound.Looped=true;sound.Volume=0;sound.Parent=Service;sound:Play()
 Tween:Create(sound,TweenInfo.new(1.5),{Volume=.45}):Play()
 if old then old.Name="KingdomMusicFading";Tween:Create(old,TweenInfo.new(1.5),{Volume=0}):Play();Debris:AddItem(old,1.6)end
 return true
end
-- Free Creator Store APM Music: Harp Fantasy. One persistent loop for intro and gameplay.
if game:GetService("RunService"):IsClient()then
 local player=Players.LocalPlayer
 for id,group in pairs(groups)do
  group.Volume=player:GetAttribute("AK"..id.."Volume")or 1
  player:GetAttributeChangedSignal("AK"..id.."Volume"):Connect(function()group.Volume=player:GetAttribute("AK"..id.."Volume")or 1 end)
 end
 task.defer(function()Sounds.SetMusic("rbxassetid://1838853377")end)
end
return Sounds
