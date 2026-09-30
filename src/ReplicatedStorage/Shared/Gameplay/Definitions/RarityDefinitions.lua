local names={"Common","Uncommon","Rare","Epic","Legendary","Mythical","Secret"}
local colors={Color3.fromRGB(205,217,210),Color3.fromRGB(121,218,123),Color3.fromRGB(94,177,245),Color3.fromRGB(185,125,245),Color3.fromRGB(255,200,78),Color3.fromRGB(255,120,187),Color3.fromRGB(135,249,236)}
local result={Ordered=names}
for i,name in ipairs(names) do result[name]={Order=i,Color=colors[i],LuckExponent=(i-1)*.3,Protected=name=="Secret"} end
result.Mystic=result.Mythical -- Existing saved IDs retain their identity.
return result
