local Definitions=require(script.Parent.Definitions.GameplayEffectsDefinitions)
local Debris=game:GetService("Debris")
local Sounds={}
local last={}
function Sounds.Play(id,parent)
 local def=Definitions[id]
 if not def or def.SoundId=="" then return end
 local now=os.clock();if last[id] and now-last[id]<(def.Debounce or .045)then return end;last[id]=now
 local sound=Instance.new("Sound");sound.Name=id; sound.SoundId=def.SoundId;sound.Volume=def.Volume;sound.PlaybackSpeed=def.Pitch or 1
 sound.RollOffMaxDistance=55;sound.Parent=parent;sound:Play();Debris:AddItem(sound,8)
end
return Sounds
