local RunService = game:GetService("RunService")
if not RunService:IsStudio() then return end

task.defer(function()
	local RS = game:GetService("ReplicatedStorage")
	local report = require(RS.Shared.Gameplay.PetAssetValidator).Run()
	print(string.format("[PetAssets] %d/%d models available; %d errors, %d warnings", report.Available, report.Definitions, #report.Errors, #report.Warnings))
	-- Keep the full structured report available without flooding Studio Output.
	script:SetAttribute("Report", game:GetService("HttpService"):JSONEncode(report))
	for index = 1, math.min(8, #report.Errors) do
		local issue = report.Errors[index]
		warn("[PetAssets] " .. tostring(issue.PetTypeId) .. ": " .. issue.Message)
	end
end)
