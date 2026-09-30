local Config = require(script.Parent.AnimalKingdomConfig)
local colors = {
	Normal = Color3.fromRGB(176, 145, 110), Golden = Color3.fromRGB(255, 198, 48),
	Leafy = Color3.fromRGB(83, 177, 86), Frosted = Color3.fromRGB(180, 232, 255),
	Lava = Color3.fromRGB(255, 80, 35), Shadow = Color3.fromRGB(54, 47, 71),
	Electric = Color3.fromRGB(255, 238, 63), Crystal = Color3.fromRGB(151, 238, 232),
	Rainbow = Color3.fromRGB(230, 95, 185),
}
local database = {}
for _, mutation in ipairs(Config.Mutations) do
	database[mutation] = table.freeze({ Id = mutation, Weight = Config.MutationWeights[mutation], IncomeMultiplier = 1, Color = colors[mutation] })
end
return table.freeze(database)
