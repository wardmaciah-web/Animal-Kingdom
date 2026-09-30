-- One visual authority for HUD, screens, overlays and reusable controls.
local T = {}
T.Color = {
 Panel=Color3.fromRGB(255,241,209), Card=Color3.fromRGB(255,247,225),
 Ink=Color3.fromRGB(77,44,25), Muted=Color3.fromRGB(135,103,68),
 Wood=Color3.fromRGB(116,64,32), WoodDark=Color3.fromRGB(65,34,21),
 Green=Color3.fromRGB(58,140,66), GreenDark=Color3.fromRGB(30,90,44),
 Gold=Color3.fromRGB(255,207,88), Pink=Color3.fromRGB(240,133,158),
 Red=Color3.fromRGB(185,65,57), White=Color3.fromRGB(255,250,232),
 Garden=Color3.fromRGB(240,246,214), Line=Color3.fromRGB(205,161,101),
}
T.Size={Header=26,Subheader=20,Body=15,Small=12,Button=46,TouchButton=48}
T.Spacing={Tiny=4,Small=8,Normal=12,Large=20,Panel=26}
T.Radius={Button=12,Card=14,Panel=18}
T.Stroke={Normal=1.5,Button=2,Focus=3}
T.Shadow={Color=Color3.fromRGB(39,25,17),Transparency=.65,Offset=5}
-- Side actions keep their entire shell, focus and badge inside the hit target.
T.SideAction={Radius=14,Inset=2,Stroke=2,FocusStroke=3,Gap=8,LabelMax=14,BadgeMin=16,BadgeMax=21,
 Body=Color3.fromRGB(148,86,43),Rim=Color3.fromRGB(224,166,86),ShadowTransparency=.28}
T.Rarities=require(game:GetService('ReplicatedStorage').Shared.Gameplay.Definitions.RarityDefinitions)
T.Font=Enum.Font.FredokaOne
T.Body=Enum.Font.GothamMedium
T.Assets={Icons="rbxassetid://92399661199946",Wood="rbxassetid://111463473227476",Paper="rbxassetid://96554661989239"}
T.Icons={Pets=0,Index=1,Garden=2,Biomes=3,Challenges=4,Upgrades=5,Plot=6,Settings=7,Shop=8,FriendshipTokens=9,Coins=10,Teleport=11,Leaf=12,Flower=13,Crown=14,Harvest=15,Daily=4}
T.Layers={HUD=1,Menu=20,Modal=50,Tooltip=65,Toast=70,Transition=90}
T.Motion={WindowOpen=.23,WindowClose=.18,ButtonHover=.11,ButtonPress=.08,TabSelected=.12,CardHover=.12,ModalOpen=.2,ModalClose=.16,ToastIn=.2,ToastOut=.18,CounterChange=.22,ProgressChange=.2,PetReveal=.26,UnlockReveal=.24}
T.Motion.SideActionState=.1
T.Currency={Coins="Forest Coins",FriendshipTokens="Friendship Tokens",GardenHarvest="Harvest",HarvestCandy="Harvest Candy"}
function T.CurrencyName(id) return T.Currency[id] or id end
return T
