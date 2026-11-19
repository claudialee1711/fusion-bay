-- Fusion Bay v3.0 — client gameplay. Menghubungkan Slap tool ke server.
-- Semua validasi (jarak, cooldown, knockback) ada di StealSystem server;
-- client di sini hanya meneruskan aktivasi tool.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local events = remotes:WaitForChild("RemoteEvents")
local slapEvent = events:WaitForChild("SlapEvent")

local function wireTool(tool)
	if tool.Name ~= "Slap" then
		return
	end
	tool.Activated:Connect(function()
		slapEvent:FireServer()
	end)
end

local backpack = player:WaitForChild("Backpack")
for _, tool in ipairs(backpack:GetChildren()) do
	wireTool(tool)
end
backpack.ChildAdded:Connect(wireTool)

-- Tool diberikan ulang saat respawn; sambungkan lagi.
player.CharacterAdded:Connect(function()
	task.wait(0.5)
	for _, tool in ipairs(backpack:GetChildren()) do
		wireTool(tool)
	end
end)
