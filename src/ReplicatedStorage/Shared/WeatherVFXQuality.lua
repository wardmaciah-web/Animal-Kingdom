-- Cosmetic-only controls. Server weather state and audio never depend on these.
local Players = game:GetService("Players")
local Quality = {}
local SCALES = { Low = 0.25, Medium = 0.55, High = 0.8, Ultra = 1 }
function Quality.Resolve()
 local player = Players.LocalPlayer
 local setting = player and player:GetAttribute("WeatherVFXQuality")
 local scale = type(setting) == "number" and math.clamp(setting, 0.25, 1) or SCALES[setting] or (game:GetService('UserInputService').TouchEnabled and SCALES.Medium or SCALES.Ultra)
 local intensity = player and player:GetAttribute("WeatherEventIntensity")
 intensity = type(intensity) == "number" and math.clamp(intensity, 0.35, 1) or 1
 return {qualityScale = scale, intensity = intensity}
end
return Quality
