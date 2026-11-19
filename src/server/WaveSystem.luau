-- Fusion Bay v3.0 — gelombang tsunami berkala.
-- Tiap 90 detik: peringatan 10 detik (langit meredup), lalu dinding air
-- menyapu map dari utara (z=-130) ke selatan (z=+120). Pemain di luar
-- base saat dinding lewat terpental ke spawn dan kehilangan 10% coin;
-- brainrot di conveyor hanyut (dihapus). Pemain yang bertahan di base
-- sendiri dapat hadiah 50 coin.
--
-- WaveWall adalah Part: disembunyikan dengan Transparency = 1, bukan
-- Visible (Part tidak punya properti Visible).

local Players = game:GetService("Players")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local Utils = require(game:GetService("ReplicatedStorage").Shared.Utils)
local DataSystem = require(script.Parent.DataSystem)
local State = require(script.Parent.State)
local Remotes = require(script.Parent.Remotes)
local Spawner = require(script.Parent.Spawner)

local WaveSystem = {}

local function playerInOwnBase(player)
	local root = Utils.getRoot(player)
	local base = State.baseForPlayer(player)
	if not root or not base then
		return false
	end
	return Utils.insideBase(root.Position, base.Center, 15, 12)
end

function WaveSystem.start()
	task.spawn(function()
		while true do
			-- Hitung mundur antar wave.
			for t = Config.WaveIntervalSeconds, 1, -1 do
				State.WaveIn = t
				task.wait(1)
			end
			-- Peringatan: langit meredup supaya ketegangan terasa.
			local Lighting = game:GetService("Lighting")
			local oldBrightness = Lighting.Brightness
			local oldAmbient = Lighting.Ambient
			Lighting.Brightness = 1.1
			Lighting.Ambient = Color3.fromRGB(60, 70, 110)
			State.WaveIn = 0
			Remotes.WaveEvent:FireAllClients("warning", Config.WaveWarningSeconds)
			Remotes.notifyAll("TSUNAMI datang dalam 10 detik! Lari pulang ke base!")
			task.wait(Config.WaveWarningSeconds)

			-- Sapuan ombak.
			State.WaveActive = true
			Remotes.WaveEvent:FireAllClients("start")
			Spawner.clearConveyor()
			local wall = State.WaveWall
			local hitPlayers = {}
			if wall then
				wall.Transparency = 0.35
				local steps = 40
				for i = 1, steps do
					local z = -130 + (250 * i / steps)
					wall.Position = Vector3.new(0, 12, z)
					-- Siapa pun di luar base saat dinding lewat: kena.
					for _, player in ipairs(Players:GetPlayers()) do
						if not hitPlayers[player] and not playerInOwnBase(player) then
							local root = Utils.getRoot(player)
							if root and math.abs(root.Position.Z - z) < 8 then
								hitPlayers[player] = true
								local data = DataSystem.get(player)
								if data then
									local loss = math.floor(data.Coins * Config.WaveCoinLoss)
									data.Coins -= loss
								end
								local spawn = game:GetService("Workspace"):FindFirstChild("SpawnLocation")
								if spawn then
									root.CFrame = CFrame.new(spawn.Position + Vector3.new(0, 3, 0))
								end
								Remotes.notify(player, "Kamu kena tsunami! -10% coin. Sembunyi di base lain kali!")
							end
						end
					end
					task.wait(Config.WaveSweepSeconds / steps)
				end
				wall.Transparency = 1
				wall.Position = Vector3.new(0, 12, -130)
			end
			State.WaveActive = false
			Lighting.Brightness = oldBrightness
			Lighting.Ambient = oldAmbient
			Remotes.WaveEvent:FireAllClients("end")
			-- Hadiah 50 coin untuk pemain yang bertahan di base sendiri.
			for _, player in ipairs(Players:GetPlayers()) do
				if not hitPlayers[player] and playerInOwnBase(player) then
					local data = DataSystem.get(player)
					if data then
						data.Coins += Config.WaveSurvivorReward
						data.TotalEarned += Config.WaveSurvivorReward
						data.SurvivedWave = true -- v3.5: bukti selamat untuk misi 3
						Remotes.notify(player, "Kamu selamat dari tsunami! +" .. Config.WaveSurvivorReward .. " coin.")
					end
				end
			end
			Remotes.notifyAll("Tsunami lewat! Conveyor mulai lagi.")
		end
	end)
end

return WaveSystem
