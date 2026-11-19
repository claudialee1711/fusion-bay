-- Fusion Bay v3.1 — client gameplay. Menghubungkan Slap tool ke server.
-- Semua validasi (jarak, cooldown, knockback) ada di StealSystem server;
-- client di sini hanya meneruskan aktivasi tool.
--
-- v3.1: kamera awal DIPAKSA menghadap utara. Di playtest v2.2, v2.3 dan
-- v3.0 kamera selalu mulai di depan karakter menghadap selatan (+Z, ke
-- tepi map kosong), jadi conveyor/sign/base tidak terlihat saat masuk.
-- Kamera ditaruh sekali di selatan pemain (pos + (0,8,18)) dan diarahkan
-- ke utara (pos + (0,2,-30)), lalu dikembalikan ke Custom setelah 0.5
-- detik supaya pemain bisa mengendalikan kameranya sendiri sesudahnya.
-- Hanya sekali di spawn pertama — tidak melawan kontrol kamera pemain.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local cameraDone = false

local function faceCameraNorth(character)
	if cameraDone then
		return
	end
	cameraDone = true
	local hrp = character:WaitForChild("HumanoidRootPart", 10)
	if not hrp then
		return
	end
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	local pos = hrp.Position
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = CFrame.new(pos + Vector3.new(0, 8, 18), pos + Vector3.new(0, 2, -30))
	task.delay(0.5, function()
		camera.CameraType = Enum.CameraType.Custom
	end)
end
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
player.CharacterAdded:Connect(function(character)
	faceCameraNorth(character)
	task.wait(0.5)
	for _, tool in ipairs(backpack:GetChildren()) do
		wireTool(tool)
	end
end)

-- Kalau karakter sudah ada saat script ini jalan, arahkan kamera langsung.
if player.Character then
	task.spawn(faceCameraNorth, player.Character)
end
