assert(game:GetService("RunService"):IsStudio())
local RS=game.ReplicatedStorage;local p=game.Players.LocalPlayer;local H=game.HttpService
local K=require(RS.Packages.Knit);K.OnStart():await()
local data=K.GetController("DataController"):GetPlayerData()
local defs=require(RS.Shared.Gameplay.Definitions.PetDefinitions)
local menu=require(p.PlayerGui.AnimalKingdomUI.PetMenus)
local old={menu.Page,menu.Sort,menu.Filter,menu.Biome,menu.IndexPage}
local screen=Instance.new("ScreenGui");screen.Name="MeadowMenuVerification";screen.DisplayOrder=90;screen.Parent=p.PlayerGui
local content=Instance.new("ScrollingFrame");content.Size=UDim2.fromOffset(800,650);content.Position=UDim2.fromScale(.25,.1);content.AutomaticCanvasSize=Enum.AutomaticSize.Y;content.BackgroundColor3=Color3.fromRGB(249,247,237);content.Parent=screen
local result={}
local ctx={Data=data,Content=content,Request=function()end,Refresh=function()end}
local function inspect(which)
 for _,card in ipairs(content:GetChildren()) do
  local id=card:GetAttribute("PetTypeId");local def=id and defs[id]
  if def and def.IsMeadowPet then
   local row=result[id] or {};result[id]=row
   local view=card:FindFirstChildWhichIsA("ViewportFrame")
   local world=view and view:FindFirstChildWhichIsA("WorldModel")
   local model=world and world:FindFirstChildWhichIsA("Model")
   local part=model and model:FindFirstChildWhichIsA("MeshPart",true)
   row[which]=part~=nil and part.MeshId==def.ModelAssets[1].MeshId and model:GetAttribute("PetTypeId")==id
   if which=="inventory" then
    row.incomeText=false;row.nameText=false
    for _,label in ipairs(card:GetChildren()) do if label:IsA("TextLabel") then
     if label.Text==def.DisplayName then row.nameText=true end
     if label.Text==string.format("%.2f Forest Coins/sec · when displayed",def.BaseIncomePerSecond) then row.incomeText=true end
    end end
    row.owned=type(card:GetAttribute("OwnedPetUID"))=="string"
   else row.discovered=card:GetAttribute("Discovered") end
  end
 end
end
menu.Sort="Name";menu.Filter="All"
for page=1,math.ceil(#data.Pets/12) do menu.Page=page;content:ClearAllChildren();menu.Pets(ctx);task.wait(.1);inspect("inventory")end
menu.Biome="Meadow"
for page=1,3 do menu.IndexPage=page;content:ClearAllChildren();menu.Index(ctx);task.wait(.1);inspect("index") end
menu.Page,menu.Sort,menu.Filter,menu.Biome,menu.IndexPage=table.unpack(old)
screen:Destroy()
p:SetAttribute("MeadowUITestResults",H:JSONEncode(result))
