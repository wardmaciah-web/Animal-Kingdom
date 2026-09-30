local model = remodel.readModelAsset(103967846891169)
local function visit(instance)
    print("NODE", instance.ClassName, instance.Name)
    local ok, texture = pcall(function() return instance.Texture end)
    if ok and texture then print("CONTENT", texture) end
    for _, child in ipairs(instance:GetChildren()) do
        visit(child)
    end
end
if type(model) == "table" then
    for _, instance in ipairs(model) do visit(instance) end
else
    visit(model)
end
remodel.writeModelFile("/private/tmp/ak_concrete_uploaded.rbxmx", model[1])
