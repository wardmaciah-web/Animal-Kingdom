local RS=game:GetService('ReplicatedStorage')
local W=require(script.Parent.GameplayWidgets)
local Pets=require(RS.Shared.Gameplay.Definitions.PetDefinitions)
local Rarities=require(RS.Shared.Gameplay.Definitions.RarityDefinitions)
local Rewards=require(RS.Shared.Gameplay.Definitions.IndexRewardDefinitions)
local Biomes=require(RS.Shared.Gameplay.Definitions.BiomeDefinitions)
local Models=require(RS.Shared.Gameplay.PetModelResolver)
local Catalog=require(RS.Shared.Gameplay.IndexCatalog)
local Odds=require(RS.Shared.Gameplay.NormalTreeOdds)
local Format=require(RS.Shared.Gameplay.PetNumberFormat)
local M={Biome='Meadow',IndexPage=1,SelectedIndex=nil,DetailMode=false}
local function name(def)
 if not def then return 'Archived companion' end
 if def.DisplayName:match('%d%d$') then return (Biomes[def.Biome] and Biomes[def.Biome].DisplayName or def.Biome)..' companion' end
 return def.DisplayName
end
M.Name=name
local function pager(ctx,p,page,total,set)
 local bar=W.New('Frame',{Size=UDim2.new(1,-8,0,46),BackgroundTransparency=1},p)
 local prev=W.Button(bar,'‹ Previous',UDim2.new(.3,0,1,0),nil,function()set(page-1);ctx.Refresh()end)
 W.Disabled(prev,page<=1)
 local l=W.Text(bar,page..' / '..math.max(1,total),UDim2.fromScale(.35,1),UDim2.fromScale(.33,0));l.TextXAlignment=Enum.TextXAlignment.Center
 local next=W.Button(bar,'Next ›',UDim2.fromScale(.3,1),UDim2.fromScale(.7,0),function()set(page+1);ctx.Refresh()end)
 W.Disabled(next,page>=total)
end
local function collectionInfo(def,entry,data)
 local eligible,sources=Catalog.Current()
 local variants={};if entry then for v in pairs(entry.Variants or {})do table.insert(variants,v)end;table.sort(variants)end
 local odds={}
 for _,pool in ipairs(Catalog.SourcePools(def.PetId))do
  local base=Odds.Chance(pool,def.PetId);local yours=Odds.Chance(pool,def.PetId,data.NormalTreeModifiers and (data.NormalTreeModifiers[pool.Id]or data.NormalTreeModifiers[def.Biome]))
  table.insert(odds,pool.DisplayName..' • '..Format.Number(pool.Cost)..' Forest Coins\nBase chance: '..Odds.Format(base)..(math.abs(base-yours)>1e-10 and (' • Your chance: '..Odds.Format(yours)) or ''))
  local family=require(RS.Shared.Gameplay.Definitions.TreeFamilyDefinitions)[pool.Id]
  if family then
   local mastery=data.TreeMastery and data.TreeMastery[pool.Id]or {Searches=0,Species={},Heaviest=0}
   local discovered=0;for _,petId in ipairs(family.PetIds)do if mastery.Species[petId]then discovered+=1 end end
   local rank=require(RS.Shared.Gameplay.KingdomProgress).Rank(mastery.Points or mastery.Searches)
   table.insert(odds,string.format('Family mastery %d/5 • +%d%% family Luck\n%d searches • %d/%d species • Heaviest %.2f kg',rank,rank,mastery.Searches,discovered,#family.PetIds,mastery.Heaviest))
   local hot=data.NormalTreeModifiers and data.NormalTreeModifiers['Hot:'..pool.Id]
   if hot then table.insert(odds,'Hot copy chance: '..Odds.Format(Odds.Chance(pool,def.PetId,hot)))end
  end
 end
 return (eligible[def.PetId] and (entry and 'Discovered' or 'Undiscovered') or (entry and 'Archived discovery' or 'Coming Soon'))..' • '..W.Rate(def.BaseIncome)..' base coins/sec\n'..(#odds>0 and table.concat(odds,'\n') or 'Not in current reward pools')..(data.WeightRecords and data.WeightRecords[def.PetId] and string.format('\nYour heaviest: %.2f kg',data.WeightRecords[def.PetId]) or '')..(#variants>0 and ('\n'..table.concat(variants,' • ')) or '')
end
local function selection(ctx,parent,entry,def)
 local scroll=W.Scroll(parent,'SelectedCompanionScroll',UDim2.fromScale(1,1))
 local card=W.Surface(scroll,'SelectedCompanion',UDim2.new(1,-8,0,ctx.Short and 250 or 465),nil,'Paper')
 if not def then W.Empty(card,'Coming Soon','Companions for this biome are not available yet.');return end
 local preview={PetId=def.PetId,Mutation='Normal',Level=1}
 if ctx.Short then
  W.PetPreview(card,preview,UDim2.new(.32,-10,0,100),UDim2.fromOffset(5,0),not entry)
  local label=W.Heading(card,entry and name(def) or '???',UDim2.new(.32,-8,0,40),UDim2.fromOffset(4,103),14);label.TextXAlignment=Enum.TextXAlignment.Center
  W.Heading(card,def.Rarity.." • "..def.Biome,UDim2.new(.64,-18,0,30),UDim2.new(.34,0,0,6),18)
  W.Text(card,collectionInfo(def,entry,ctx.Data),UDim2.new(.64,-18,0,200),UDim2.new(.34,0,0,40),12)
  return
 end
 W.PetPreview(card,preview,UDim2.new(1,-24,0,156),UDim2.fromOffset(12,12),not entry)
 local title=W.Heading(card,entry and name(def) or '???',UDim2.new(1,-24,0,35),UDim2.fromOffset(12,170),22);title.TextXAlignment=Enum.TextXAlignment.Center
 local rarity=W.Text(card,def.Rarity..' • '..(Biomes[def.Biome] and Biomes[def.Biome].DisplayName or def.Biome),UDim2.new(1,-24,0,27),UDim2.fromOffset(12,207),14);rarity.TextXAlignment=Enum.TextXAlignment.Center
 W.Text(card,collectionInfo(def,entry,ctx.Data),UDim2.new(1,-32,0,212),UDim2.fromOffset(16,245),13)
end
local function petCard(ctx,grid,def,entry,eligible)
 local c=W.Card(grid,190);c.Name='Companion_'..def.PetId;c:SetAttribute('PetTypeId',def.PetId)
 W.PetPreview(c,{PetId=def.PetId,Mutation='Normal',Level=1},UDim2.new(1,-12,0,ctx.Compact and 54 or 121),UDim2.fromOffset(6,6),not entry)
 local button=W.New('TextButton',{Name='Select_'..def.PetId,Text='',Size=UDim2.fromScale(1,1),BackgroundTransparency=1,BorderSizePixel=0},c)
 W.Bind(button,function()M.SelectedIndex=def.PetId;if ctx.Compact then M.DetailMode=true end;ctx.Refresh()end)
 if M.SelectedIndex==def.PetId then W.Round(button,12);W.Stroke(button,W.Color.Gold,3)end
 local title=W.Heading(c,entry and name(def) or '???',UDim2.new(1,-14,0,ctx.Compact and 23 or 33),UDim2.fromOffset(7,ctx.Compact and 60 or 126),ctx.Compact and 12 or 16);title.TextXAlignment=Enum.TextXAlignment.Center
 local rarity=W.Text(c,def.Rarity..(not eligible[def.PetId] and (entry and ' • Archived' or ' • Coming Soon') or ''),UDim2.new(1,-12,0,ctx.Compact and 15 or 22),UDim2.fromOffset(6,ctx.Compact and 82 or 162),ctx.Compact and 10 or 12,W.Color.Muted);rarity.TextXAlignment=Enum.TextXAlignment.Center
end
local function regions(ctx)
 local content=ctx.Content;W.List(content)
 local narrow=ctx.Compact
 local body=W.New('Frame',{Name='FieldGuide',Size=UDim2.new(1,-8,0,math.max(70,content.AbsoluteSize.Y-(ctx.CollectionToolsHeight or 80)-12)),BackgroundTransparency=1},content)
 local leftWidth=not narrow and .16 or 0
 local gridWidth=narrow and 1 or .47
 local grid=W.Scroll(body,'PetGrid',UDim2.new(gridWidth,-10,1,ctx.Compact and 0 or -54),UDim2.fromScale(leftWidth,0))
 W.Grid(grid,ctx.Compact and 122 or 135,ctx.Compact and 100 or 190,10)
 local details=W.New('Frame',{Name='CompanionDetails',Size=narrow and UDim2.new(1,-8,1,0) or UDim2.new(1-leftWidth-gridWidth,-8,1,0),Position=narrow and UDim2.new() or UDim2.fromScale(leftWidth+gridWidth,0),BackgroundTransparency=1},body)
 if narrow then grid.Visible=not M.DetailMode;details.Visible=M.DetailMode end
 return body,grid,details
end
function M.Back(ctx)
 if ctx.ActiveName=="Pets" then return require(script.Parent.PetOwnershipMenus).Back(ctx)end
 if ctx.Compact and M.DetailMode then M.DetailMode=false;ctx.Refresh();return true end
 return false
end
local function detailBack(ctx,top)
 if ctx.Compact and M.DetailMode then
  top:ClearAllChildren();top.Size=UDim2.new(1,-8,0,46);ctx.CollectionToolsHeight=46
  W.CreamSecondaryButton(top,'‹ Back to collection',UDim2.new(1,0,0,44),nil,function()M.DetailMode=false;ctx.Refresh()end)
 end
end
function M.Pets(ctx)return require(script.Parent.PetOwnershipMenus).Render(ctx)end
function M.Index(ctx)
 local content=ctx.Content;local data=ctx.Data
 ctx.CollectionToolsHeight=ctx.Compact and 76 or 58
 local count,catalogTotal,completion=Pets.IndexProgress(data.PetIndex)
 local top=W.New('Frame',{Name='DiscoveryProgress',Size=UDim2.new(1,-8,0,58),BackgroundTransparency=1,LayoutOrder=-1},content)
 local progress=W.Heading(top,string.format('%d / %d discovered',count,catalogTotal),UDim2.new(.35,0,1,0),nil,ctx.Compact and 11 or 19)
 if ctx.Compact then progress.Size=UDim2.new(.35,-8,0,24) end
 for i,r in ipairs(Rewards) do
  local claimed=data.IndexRewards[tostring(r.Percent)];local b=W.Button(top,claimed and '✓' or r.Percent..'%',UDim2.new(.16,-6,0,44),UDim2.new(.36+(i-1)*.16,0,0,6),function()ctx.Request('ClaimIndex',{Percent=r.Percent})end)
  W.Disabled(b,claimed or completion<r.Percent)
 end
 local body,grid,details=regions(ctx)
 if not ctx.Compact then
  local nav=W.Scroll(body,'BiomeNavigation',UDim2.new(.16,-10,1,0));W.List(nav)
  for _,d in ipairs(Biomes.Ordered) do local b=W.Button(nav,d.DisplayName,UDim2.new(1,-5,0,44),nil,function()M.Biome=d.Id;M.IndexPage=1;M.SelectedIndex=nil;ctx.Refresh()end,M.Biome==d.Id and W.Color.Green or W.Color.Wood);b.TextSize=13 end
 else
  local filter=W.Button(top,'Biome',UDim2.new(.35,-8,0,44),UDim2.new(0,0,0,58),function()local i=1;for n,d in ipairs(Biomes.Ordered)do if d.Id==M.Biome then i=n end end;M.Biome=Biomes.Ordered[i%#Biomes.Ordered+1].Id;M.IndexPage=1;M.SelectedIndex=nil;ctx.Refresh()end,W.Color.Wood)
  filter.Text=M.Biome;top.Size=UDim2.new(1,-8,0,76);filter.Position=UDim2.new(0,0,0,26);filter.Size=UDim2.new(.35,-8,0,44)
 end
 detailBack(ctx,top)
 if ctx.Compact and M.DetailMode then body.Size=UDim2.new(1,-8,0,math.max(70,content.AbsoluteSize.Y-58))end
 local eligible=Catalog.Current()
 local list={}
 -- Keep historical discoveries visible, but do not advertise unreleased species.
 for _,d in ipairs(Pets.Ordered)do if d.Biome==M.Biome and (eligible[d.PetId] or data.PetIndex[d.PetId]) then table.insert(list,d)end end
 if not Biomes.IsContentReady(M.Biome) then
  local notice=W.Text(grid,'COMING SOON',nil,nil,16,W.Color.Muted);notice.Name='ComingSoon';notice.LayoutOrder=-1;notice.TextXAlignment=Enum.TextXAlignment.Center
 end
 table.sort(list,function(a,b)local aa,bb=Models.Resolve(a.PetId)~=nil,Models.Resolve(b.PetId)~=nil;if aa~=bb then return aa end;local ra,rb=Rarities[a.Rarity].Order,Rarities[b.Rarity].Order;return ra==rb and a.PetId<b.PetId or ra<rb end)
 local total=math.max(1,math.ceil(#list/12));M.IndexPage=math.clamp(M.IndexPage,1,total)
 local selected;for _,d in ipairs(list)do if d.PetId==M.SelectedIndex then selected=d end end;selected=selected or list[(M.IndexPage-1)*12+1];M.SelectedIndex=selected and selected.PetId
 selection(ctx,details,selected and data.PetIndex[selected.PetId],selected)
 for i=ctx.Compact and 1 or (M.IndexPage-1)*12+1,ctx.Compact and #list or math.min(#list,M.IndexPage*12)do local d=list[i];petCard(ctx,grid,d,data.PetIndex[d.PetId],eligible)end
 local foot=W.New('Frame',{Size=UDim2.new(ctx.Narrow and 1 or .47,-10,0,46),Position=UDim2.new(ctx.Narrow and 0 or .16,0,1,-46),BackgroundTransparency=1},body)
 foot.Visible=not ctx.Compact
 pager(ctx,foot,M.IndexPage,total,function(v)M.IndexPage=v end)
end
return M
