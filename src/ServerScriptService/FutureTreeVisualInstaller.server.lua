-- Uses bundled native templates; no network generation, gameplay registration or paid calls.
local visuals=require(game:GetService("ServerStorage"):WaitForChild("FutureTreeVisuals"))
local report=visuals.Apply()
print(string.format("[FutureTreeVisuals] Installed %d; retained %d existing visual replacements.",report.replaced,report.skipped))