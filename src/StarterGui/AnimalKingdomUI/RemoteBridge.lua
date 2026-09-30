local RS=game:GetService('ReplicatedStorage')
local Http=game:GetService('HttpService')
local W=require(script.Parent.GameplayWidgets)
local Bridge={Pending=nil}
local requested=Instance.new('BindableEvent');Bridge.Requested=requested.Event
local completed=Instance.new('BindableEvent');Bridge.Completed=completed.Event
local garden={StartExpedition=true,ClaimExpedition=true,CancelExpedition=true,ClaimAllExpeditions=true,BuyGardenSupply=true,UpgradeGarden=true,BuyGardenCosmetic=true,EquipGardenCosmetic=true}
local cooldown=0
local seen,receiptOrder={},{}
local unresolvedShop={}
local function release(record)
 if Bridge.Pending~=record then return end;Bridge.Pending=nil
 local b=record.Button
 if b and b.Parent then b:SetAttribute('Pending',false);b.Active=true;b.Text=record.Text end
end
function Bridge.Request(action,payload)
 if Bridge.Pending or os.clock()<cooldown then return false end
 local folder=RS:FindFirstChild('AnimalKingdomRemotes');local remote=folder and folder:FindFirstChild('UIRequest')
 if not remote then completed:Fire({Action=action,Success=false,Result='Still connecting. Please try again shortly.'});return false end
 local id=Http:GenerateGUID(false);payload=table.clone(payload or {})
 local shopKey
 if action=='ShopBuy'or action=='KingdomBuy'then
  shopKey=action..':'..tostring(payload.Id)
  local unresolved=unresolvedShop[shopKey]
  if unresolved then id=unresolved.RequestId;payload.RequestId=id;payload.Rotation=unresolved.Rotation
  else payload.RequestId=id;payload.Rotation=payload.Rotation or math.floor(workspace:GetServerTimeNow()/600);unresolvedShop[shopKey]={RequestId=id,Rotation=payload.Rotation}end
 end
 if garden[action] or action=="LuckyTry" then payload.RequestId=payload.RequestId or id end
 local b=W.CurrentButton;local record={Action=action,Id=id,ShopKey=shopKey,Button=b,Text=b and b:IsA('TextButton') and b.Text or nil}
 if not record.Text then record.Button=nil end
 Bridge.Pending=record;cooldown=os.clock()+((action=='VisitGarden' or action=='ReturnGarden' or action=='ClaimAllExpeditions') and 1.6 or .55)
 if record.Button then b:SetAttribute('Pending',true);b.Active=false;b.Text='Working…' end
 requested:Fire(action,payload);remote:FireServer(action,payload,id)
 task.delay(12,function()
  if Bridge.Pending==record then release(record);completed:Fire({Action=action,Success=false,Result='Taking longer than expected. Check your balance or inventory before trying again.'}) end
 end)
 return true
end
local folder=RS:WaitForChild('AnimalKingdomRemotes')
local connection=folder:WaitForChild('GameplayFeedback').OnClientEvent:Connect(function(payload)
 if payload.RequestId then for key,r in pairs(unresolvedShop)do if r.RequestId==payload.RequestId then unresolvedShop[key]=nil end end end
 local record=Bridge.Pending
 if record and payload.RequestId==record.Id then release(record) end
 if payload.RequestId then
  if seen[payload.RequestId]then return end
  seen[payload.RequestId]=true;table.insert(receiptOrder,payload.RequestId)
  if #receiptOrder>64 then seen[table.remove(receiptOrder,1)]=nil end
 end
 completed:Fire(payload)
end)
script.Destroying:Once(function()connection:Disconnect();requested:Destroy();completed:Destroy()end)
return Bridge
