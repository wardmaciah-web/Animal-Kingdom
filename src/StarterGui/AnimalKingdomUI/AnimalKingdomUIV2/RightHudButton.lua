local W=require(script.Parent.Components)
local RightHudButton={}

local NORMAL=Color3.fromRGB(115,63,30)
local HOVER=Color3.fromRGB(132,76,38)
local PRESSED=Color3.fromRGB(94,49,24)
local BORDER=Color3.fromRGB(235,158,48)
local FOCUS=Color3.fromRGB(255,210,104)
local TEXT=Color3.fromRGB(255,245,220)

function RightHudButton.new(parent,name,icon,callback)
 -- Only the right HUD trio uses this shell. The old nested shells/highlights
 -- produced split edges; the button itself now owns the only fill and border.
 -- Keep every state solid: no image shell, gradient, backplate or focus overlay.
 local button=W.New('TextButton',{
  Name='Nav_'..name,Size=UDim2.fromOffset(62,62),Text='',
  BackgroundColor3=NORMAL,BackgroundTransparency=0,BorderSizePixel=0,
  ClipsDescendants=true,AutoButtonColor=false,ZIndex=3,
 },parent)
 button:SetAttribute('Component','RightHudButton')
 W.Round(button,12)
 local border=W.Stroke(button,BORDER,2)
 local artwork=W.Icon(button,icon,UDim2.fromOffset(34,34),UDim2.new(.5,-17,0,5))
 artwork.ZIndex=4
 local label=W.Heading(button,name,UDim2.new(1,-6,0,18),UDim2.fromOffset(3,40),12,TEXT)
 label.TextXAlignment=Enum.TextXAlignment.Center
 label.TextWrapped=false
 label.ZIndex=4

 local hovered,pressed,focused=false,false,false
 local function refresh()
  local enabled=button.Active and not button:GetAttribute('Disabled') and not button:GetAttribute('Pending')
  local highlighted=hovered or focused or button:GetAttribute('Selected')
  local color=enabled and (pressed and PRESSED or highlighted and HOVER) or NORMAL
  W.Motion.Tween(button,'SideActionState',{BackgroundColor3=color or NORMAL})
  W.Motion.Tween(border,'SideActionState',{Color=enabled and focused and FOCUS or BORDER})
 end
 for _,attribute in ipairs({'Selected','Disabled','Pending'})do
  button:GetAttributeChangedSignal(attribute):Connect(refresh)
 end
 button:GetPropertyChangedSignal('Active'):Connect(refresh)
 -- Reuse the existing click/controller/audio binding without its extra focus shell.
 return W.Bind(button,callback,{
  FocusManaged=true,
  Hover=function(value)hovered=value;refresh()end,
  Press=function(value)pressed=value;refresh()end,
  FocusChanged=function(value)focused=value;refresh()end,
  Activate=function()pressed=false;refresh()end,
 })
end

return RightHudButton
