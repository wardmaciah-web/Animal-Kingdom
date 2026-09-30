local p=game.Players.LocalPlayer;local ui=p.PlayerGui:WaitForChild("AnimalKingdomUI")
local G=game.ReplicatedStorage.Shared.Gameplay;local H=game.HttpService
local clone=ui.PetMenus:Clone();clone.Name="AKEconomyIndexRenderer";clone.Parent=ui
local M=require(clone);local F=require(G.Definitions.TreeFamilyDefinitions);local E=require(G.Definitions.EggDefinitions);local O=require(G.NormalTreeOdds);local Format=require(G.PetNumberFormat)
local screen=Instance.new("ScreenGui");screen.Name="AKEconomyIndexQA";screen.Enabled=false;screen.Parent=p.PlayerGui
local content=Instance.new("ScrollingFrame");content.Size=UDim2.fromOffset(1200,650);content.Parent=screen
local result={Checks=0,Families={}}
local ok,err=xpcall(function()
for _,f in ipairs(F.Ordered)do if f.Biome=="Meadow"or f.Biome=="Forest"then
 content:ClearAllChildren();M.Biome=f.Biome;M.SelectedIndex=f.PetIds[1];M.IndexPage=1
 local context={Luck=1.55}
 local ctx={Content=content,Data={PetIndex={},IndexRewards={},NormalTreeModifiers={[f.Biome]=context},WeightRecords={}},Compact=false,Short=false,Narrow=false,Request=function()end,Refresh=function()end}
 M.Index(ctx);task.wait(.1)
 local needle=f.DisplayName.." • "..Format.Number(E[f.Id].Cost).." Forest Coins";local found
 for _,x in ipairs(content:GetDescendants())do if x:IsA("TextLabel")and x.Text:find(needle,1,true)then found=x;break end end
 assert(found,"Missing Index price "..f.Id);result.Checks+=1
 assert(found.Text:find("Base chance: "..O.Format(O.Chance(E[f.Id],f.PetIds[1])),1,true),"Wrong base Index probability");result.Checks+=1
 assert(found.Text:find("Your chance: "..O.Format(O.Chance(E[f.Id],f.PetIds[1],context)),1,true),"Wrong effective Index probability");result.Checks+=1
 table.insert(result.Families,{Id=f.Id,Text=found.Text})
end end
end,debug.traceback)
screen:Destroy();clone:Destroy();result.Passed=ok;result.Error=not ok and err or nil
ui:SetAttribute("AKEconomyIndex",H:JSONEncode(result))
