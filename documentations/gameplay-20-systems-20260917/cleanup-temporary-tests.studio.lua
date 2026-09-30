-- Run once in the authored place EDIT-mode Command Bar after unlocking macOS.
-- Removes only the two temporary audit objects, never production gameplay scripts.
assert(game:GetService("RunService"):IsStudio() and not game:GetService("RunService"):IsRunning(), "Studio Edit mode required")
for _,entry in ipairs({{game.ServerScriptService,"AK_GameplayReleaseTest"},{game.StarterPlayer.StarterPlayerScripts,"AK_GameplayClientTest"}}) do
 local object=entry[1]:FindFirstChild(entry[2])
 if object then assert(object:GetAttribute("TemporaryAudit")==true,"Unexpected non-audit object");object:Destroy() end
end
workspace:SetAttribute("AK_GameplayTestStage",nil)
workspace:SetAttribute("AK_MultiplayerExpected",nil)
print("AK_GAMEPLAY_TEMP_TESTS_REMOVED")
