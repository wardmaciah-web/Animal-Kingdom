local RS=game:GetService('ReplicatedStorage')
local W=require(script.Parent.GameplayWidgets)
local Biomes=require(RS.Shared.Gameplay.Definitions.BiomeDefinitions)
local Upgrades=require(RS.Shared.Gameplay.Definitions.UpgradeDefinitions)
local Challenges=require(RS.Shared.Gameplay.Definitions.ChallengeDefinitions)
local Rarities=require(RS.Shared.Gameplay.Definitions.RarityDefinitions)
local Images=require(script.Parent.BiomeImages)
local Mastery=require(RS.Shared.Gameplay.BiomeMastery)
local M={}
local function luckyDestination(card,biome)
 local p=game.Players.LocalPlayer
 if p:GetAttribute('LuckyTreeBiome')~=biome or(p:GetAttribute('LuckyTreeEndsAt')or 0)<=workspace:GetServerTimeNow()then return end
 local outline=Instance.new('UIStroke');outline.Name='LuckyDestinationPulse';outline.Color=Color3.fromRGB(237,208,113);outline.Thickness=2;outline.Transparency=.2;outline.Parent=card
 if p:GetAttribute('AKReducedMotion')~=true then
  local tween=game.TweenService:Create(outline,TweenInfo.new(1.5,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true),{Transparency=.7});tween:Play();card.Destroying:Once(function()tween:Cancel()end)
 end
end
local function mastery(ctx,card,biome,y)
 if not Biomes.IsContentReady(biome)then return end
 local state=Mastery.Next(ctx.Data,biome)
 local area=W.New('Frame',{Name='Mastery',Size=UDim2.new(1,-20,0,100),Position=UDim2.fromOffset(10,y),BackgroundTransparency=1},card)
 if not state then W.Text(area,'Mastery complete ✓',UDim2.new(1,0,0,24),nil,13,W.Color.GreenDark);return end
 local g=state.Goal
 W.Text(area,string.format('Mastery %d • %d/%d searches • %d/%d species',g.Level,math.min(state.Searches,g.Searches),g.Searches,math.min(state.Discoveries,g.Discoveries),g.Discoveries),UDim2.new(1,0,0,34),nil,11)
 W.ProgressBar(area,state.Fraction,UDim2.new(1,0,0,5),UDim2.fromOffset(0,35))
 local b=W.Button(area,state.Ready and 'Claim mastery' or (W.Format(g.Coins)..' coins + '..g.Tokens..' tokens'),UDim2.new(1,0,0,44),UDim2.fromOffset(0,46),function()ctx.Request('ClaimMastery',{Biome=biome,Level=g.Level})end)
 b.Name='ClaimMastery_'..biome;W.Disabled(b,not state.Ready or not ctx.Data.UnlockedBiomes[biome])
 if state.Ready then W.Text(area,W.Format(g.Coins)..' coins + '..g.Tokens..' tokens',UDim2.new(1,0,0,18),UDim2.fromOffset(0,91),10)end
end
function M.Biomes(ctx)
 local current=game.Players.LocalPlayer:GetAttribute('CurrentBiome')
 local content=ctx.Content;W.List(content)
 local destinations=W.New('Frame',{Name='SpecialDestinations',Size=UDim2.new(1,-8,0,44),BackgroundTransparency=1},content)
 local plot=W.Button(destinations,'Your Sanctuary',UDim2.new(.5,-5,1,0),nil,ctx.PlotTravel);plot.Name='Travel_Plot'
 local garden=W.Button(destinations,'Your Garden',UDim2.new(.5,-5,1,0),UDim2.fromScale(.5,0),function()ctx.GardenTravel('VisitGarden')end);garden.Name='Travel_Garden'

 if ctx.Short then
  for _,d in ipairs(Biomes.Ordered)do
   local ready=Biomes.IsContentReady(d.Id)
   local owned=ctx.Data.UnlockedBiomes[d.Id];local card=W.Card(content,ready and 250 or 136);card.Name='Biome_'..d.Id;card.LayoutOrder=d.Order
   local thumbnail=W.Image(card,Images[d.DisplayName] or '',UDim2.new(.23,-12,0,120),UDim2.fromOffset(8,8));thumbnail.ScaleType=Enum.ScaleType.Crop;W.Round(thumbnail,12)
   if not owned then thumbnail.ImageColor3=Color3.fromRGB(132,128,116);W.LockedOverlay(thumbnail)end
   W.Heading(card,d.DisplayName,UDim2.new(.47,-16,0,30),UDim2.new(.24,0,0,9),20)
   W.Text(card,not ready and 'Companions for this region are coming soon.' or d.Description or ('Explore '..d.DisplayName..' and discover its companions.'),UDim2.new(.47,-16,0,56),UDim2.new(.24,0,0,43),13,W.Color.Muted)
   local previous=d.PreviousBiome and Biomes[d.PreviousBiome]
   W.Text(card,not ready and 'COMING SOON' or owned and (current==d.Id and 'YOU ARE HERE' or '✓ Unlocked') or (W.Format(d.Cost)..' Forest Coins'..(previous and '\nRequires '..previous.DisplayName or '')),UDim2.new(.29,-16,0,52),UDim2.new(.71,0,0,12),12,ready and owned and W.Color.GreenDark or W.Color.Ink)
   if ready then
   local b=W.Button(card,owned and 'Travel ›' or 'Unlock',UDim2.new(.29,-16,0,44),UDim2.new(.71,0,0,78),function()if owned then ctx.Travel(d.DisplayName)else ctx.Request('UnlockBiome',{Id=d.Id})end end,owned and W.Color.Green or W.Color.Wood);b.Name=(owned and 'Travel_' or 'Unlock_')..d.Id;W.Disabled(b,not owned and ((d.PreviousBiome and not ctx.Data.UnlockedBiomes[d.PreviousBiome]) or (ctx.Data.Currencies.Coins or 0)<d.Cost))
   end
   mastery(ctx,card,d.Id,136);luckyDestination(card,d.Id)
  end
  return
 end
 local intro=W.Text(content,'Unlock regions and choose where to travel. Future collections arrive as companions become available.',UDim2.new(1,-12,0,32),nil,16,W.Color.Muted);intro.TextXAlignment=Enum.TextXAlignment.Center
 local cardHeight=math.clamp(content.AbsoluteSize.Y-60,280,352);local imageHeight=cardHeight-178
 local grid=W.New('Frame',{Name='BiomeCards',Size=UDim2.new(1,-8,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1},content);W.Grid(grid,175,cardHeight+114,12)
 for _,d in ipairs(Biomes.Ordered) do
  local ready=Biomes.IsContentReady(d.Id)
  local owned=ctx.Data.UnlockedBiomes[d.Id];local card=W.Card(grid,cardHeight+114);card.Name='Biome_'..d.Id;card.LayoutOrder=d.Order
  local image=W.Image(card,Images[d.DisplayName] or '',UDim2.new(1,-14,0,imageHeight),UDim2.fromOffset(7,8));image.ScaleType=Enum.ScaleType.Crop;W.Round(image,12)
  if not owned then
   image.ImageColor3=Color3.fromRGB(132,128,116)
   local lock=W.LockedOverlay(image)
  end
  local ribbon=W.Surface(card,'NameRibbon',UDim2.new(1,-6,0,36),UDim2.fromOffset(3,imageHeight-9),'Paper')
  local title=W.Heading(ribbon,d.DisplayName,UDim2.new(1,-10,1,0),UDim2.fromOffset(5,0),18);title.TextXAlignment=Enum.TextXAlignment.Center
  local description=W.Text(card,not ready and 'Companions for this region are coming soon.' or d.Description or ('Explore '..d.DisplayName..' and discover its companions.'),UDim2.new(1,-24,0,49),UDim2.fromOffset(12,imageHeight+33),13,W.Color.Muted);description.TextXAlignment=Enum.TextXAlignment.Center
  local previous=d.PreviousBiome and Biomes[d.PreviousBiome]
  local req=not ready and 'COMING SOON' or owned and (current==d.Id and 'YOU ARE HERE' or '✓ Unlocked') or (W.Format(d.Cost)..' Forest Coins\n'..(previous and 'Requires '..previous.DisplayName or ''))
  local status=W.Text(card,req,UDim2.new(1,-20,0,37),UDim2.fromOffset(10,cardHeight-92),12,ready and owned and W.Color.GreenDark or W.Color.Ink);status.TextXAlignment=Enum.TextXAlignment.Center
  if ready then
  local b=W.Button(card,owned and 'Travel ›' or 'Unlock',UDim2.new(1,-22,0,44),UDim2.fromOffset(11,cardHeight-56),function()
   if owned then ctx.Travel(d.DisplayName) else ctx.Request('UnlockBiome',{Id=d.Id})end
  end,owned and W.Color.Green or W.Color.Wood);b.Name=(owned and 'Travel_' or 'Unlock_')..d.Id;W.Disabled(b,not owned and ((d.PreviousBiome and not ctx.Data.UnlockedBiomes[d.PreviousBiome]) or (ctx.Data.Currencies.Coins or 0)<d.Cost))
  end
  mastery(ctx,card,d.Id,cardHeight);luckyDestination(card,d.Id)
 end
 local footer=W.Text(content,'A brighter kingdom grows together.',UDim2.new(1,-8,0,30),nil,15,W.Color.Muted);footer.TextXAlignment=Enum.TextXAlignment.Center
end
local upgradeDescriptions={
 PetStorage='Inventory capacity; Garden pets reserve their return space. Existing larger capacity is preserved.',
 Luck='+15% Luck per level. Improves rarer species in mixed-rarity tree pools, weight tails and Prismatic chance. See your odds in the Index.',
 HatchSpeed='+15% hatch speed per level. Shorter reveal and server hatch cooldown; tree shake time stays the same.',
 WalkSpeed='+6% base movement per level, through the existing movement modifiers.',
 Coins='+15% per level on applicable coin loot. Excludes Sanctuary income, sales and fixed rewards.',
 FriendshipTokens='+15% per level on applicable token loot. Fixed Index and Challenge rewards stay the same.',
 GatheringPower='+20% per level to gathering power from all five Held slots. Improves resource rewards, not tree shake speed.',
 ResourceRewards='+15% per level on secondary resource loot. Does not grant extra primary tree pets.',
}
function M.Upgrades(ctx)
 if ctx.Short then W.List(ctx.Content)else W.Grid(ctx.Content,270,304,14)end
 local function upgradeCard(id,title,level,max,description,price,action)
  local c=W.Card(ctx.Content,ctx.Short and 260 or 304);c.Name=id;c.LayoutOrder=id=='DecorationCapacity' and 0 or 1
  W.Heading(c,title,UDim2.new(1,-28,0,48),UDim2.fromOffset(14,10),20)
  W.Text(c,'Level '..level..' / '..max,UDim2.new(1,-28,0,24),UDim2.fromOffset(14,59),13,W.Color.Muted)
  W.Text(c,description,UDim2.new(1,-28,0,ctx.Short and 74 or 110),UDim2.fromOffset(14,86),13)
  W.Text(c,price,UDim2.new(1,-28,0,24),UDim2.new(0,14,1,-82),13,W.Color.Muted)
  local button=W.Button(c,level>=max and 'MAXIMUM' or 'UPGRADE',UDim2.new(1,-28,0,44),UDim2.new(0,14,1,-52),action);button.Name='Upgrade_'..id;W.Disabled(button,level>=max)
 end
 local level=ctx.Data.PlotProgression.Level;local limit=25+level*5
 upgradeCard('DecorationCapacity','Decoration Capacity',level,10,limit..' maximum placed decorations.'..(level<10 and (' Next: '..(limit+5)..'. Purchase while at your plot.') or ''),level>=10 and 'Complete' or W.Format(math.floor(2500*2^level))..' Forest Coins',function()ctx.Request('PlotUpgrade',{})end)
 local ids={};for id,d in pairs(Upgrades)do if not d.Retired then table.insert(ids,id)end end;table.sort(ids)
 for _,id in ipairs(ids)do
  local d=Upgrades[id];local current=ctx.Data.Upgrades[id] or 0;local description=upgradeDescriptions[id]
  if id=='PetStorage' then description='Capacity '..ctx.Data.PetStorageCapacity..(current<d.MaxLevel and (' → '..math.max(ctx.Data.PetStorageCapacity,50+25*(current+1))) or '')..'. '..description end
  upgradeCard(id,d.DisplayName,current,d.MaxLevel,description,current>=d.MaxLevel and 'Complete' or W.Format(d.Costs[current+1])..' '..W.Theme.CurrencyName(d.Currency),function()ctx.Request('Upgrade',{Id=id})end)
 end
end
-- Legacy callers retain the same route and shared Activities renderer.
function M.Challenges(ctx)return require(script.Parent.ActivityMenus).Render(ctx)end
function M.Settings(ctx)
 W.List(ctx.Content)
 for _,e in ipairs({{'ReducedMotion','Reduced Motion','Use softer reveals and reduced motion.'},{'ShowOtherPets','Show Other Players’ Held Pets','Show the pet held above other players. Garden and Sanctuary displays stay visible.'}})do
  local value=ctx.Data.Settings[e[1]];local c=W.Card(ctx.Content,142)
  W.Heading(c,e[2],UDim2.new(.7,-28,0,52),UDim2.fromOffset(16,14),20)
  W.Text(c,e[3],UDim2.new(.7,-28,0,58),UDim2.fromOffset(16,70),13,W.Color.Muted)
  W.Button(c,value and 'ON' or 'OFF',UDim2.new(.26,-8,0,44),UDim2.new(.73,0,.5,-22),function()ctx.Request('Setting',{Id=e[1],Value=not value})end,value and W.Color.Green or W.Color.Wood)
 end

end
return M
