assert(not game:GetService('RunService'):IsRunning(),'Edit mode required')
local store=game:GetService('ServerStorage')
local archive=store:FindFirstChild('AK_AuditRecovery_20260917') or Instance.new('Folder')
archive.Name='AK_AuditRecovery_20260917';archive.Parent=store
local function retain(o,reason)
 local path=o:GetFullName()
 o:SetAttribute('AuditOriginalPath',path);o:SetAttribute('AuditReason',reason)
 if o:IsA('BaseScript') then o.Disabled=true end
 o.Parent=archive
 print('[MapAudit] Archived '..path..' — '..reason)
end
for _,o in ipairs(workspace:GetChildren()) do
 if o:IsA('Script') and o.Source:find('AK_RUNTIME_GeneralStoreVisual',1,true) then retain(o,'Legacy duplicate overlay scales empty canonical model to zero') end
end
local labels={}
for _,o in ipairs(game.ServerScriptService:GetChildren()) do
 if o:IsA('Script') then
  if o.Name=='AK_PlotAssignment' and not o.Source:find('require(script.Parent.PlotLocator)',1,true) and o.Source:find('MAX_PLOTS',1,true) then
   retain(o,'Obsolete duplicate four-plot allocator; modern PlotLocator assignment owns lifecycle')
  elseif o.Source:find('PERMANENTLY REMOVE RUNTIME BIOME BLOCKOUT',1,true) or o.Source:find('REMOVE RUNTIME WORLD PLACEHOLDERS',1,true) or o.Source:find('DELETE RUNTIME WORLD FOLDER',1,true) then
   retain(o,'Legacy cleanup races authored WorldService; source now suppresses blockout safely')
  elseif o.Name=='AK_BiomeLabelRemover' then table.insert(labels,o) end
 end
end
for i=2,#labels do retain(labels[i],'Identical duplicate label-removal watcher') end
print('[MapAudit] Live conflicting script cleanup complete')
