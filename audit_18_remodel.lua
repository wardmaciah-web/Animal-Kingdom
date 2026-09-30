local assets = {
 {"PineTree_Snow_1",79601166287637},{"BirchTree_Dead_Snow_2",95794090455603},{"Willow_Dead_Snow_3",122866816810387},
 {"tree_palm",94876684700015},{"tree_palmShort",95943876749476},{"tree_palmBend",77926005288311},
 {"tree_cone",128849020669713},{"tree_fat",85580916696503},{"tree_thin",117671933429787},
 {"Tree_Bare_4",101845063915108},{"Tree_Bare_5",123410230693973},{"Tree_Bare_6",108326614588950},
 {"cactus_short",95290812112443},{"cactus_tall",70645539753250},{"CactusFlowers_2",72522977901339},
 {"common_tree_dead_1",127926951923434},{"common_tree_dead_2",70940569450580},{"common_tree_dead_3",133153330785116},
}
local function norm(v) return tostring(v or ""):match("(%d+)") or "" end
for _, row in ipairs(assets) do
 local ok, roots = pcall(function() return remodel.readModelAsset(row[2]) end)
 if not ok then print("AUDIT_ERROR|"..row[1].."|"..row[2].."|"..tostring(roots))
 else
  local all={} for _,r in ipairs(roots) do table.insert(all,r) for _,d in ipairs(r:GetDescendants()) do table.insert(all,d) end end
  local models,base,mesh,ids=0,0,0,{}
  local baseClasses={Part=true,MeshPart=true,UnionOperation=true,WedgePart=true,CornerWedgePart=true,TrussPart=true,SpawnLocation=true,Seat=true,VehicleSeat=true}
  for _,d in ipairs(all) do if d.ClassName=="Model" then models=models+1 end if baseClasses[d.ClassName] then base=base+1 end if d.ClassName=="MeshPart" then mesh=mesh+1 local okId,id=pcall(function()return d.MeshID end)table.insert(ids,okId and norm(id)or"UNAVAILABLE") end end
  table.sort(ids)
  local top={} for _,r in ipairs(roots) do table.insert(top,r.ClassName..":"..r.Name) end
  remodel.writeModelFile("/private/tmp/ak_audit_"..row[1]..".rbxmx",roots[1])
  print(table.concat({"AUDIT",row[1],tostring(row[2]),table.concat(top,","),tostring(models),tostring(base),tostring(mesh),table.concat(ids,",")},"|"))
 end
end
