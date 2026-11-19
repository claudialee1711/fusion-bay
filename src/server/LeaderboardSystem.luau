-- Fusion Bay v3.0 — leaderboard: leaderstats + OrderedDataStore.
-- GetOrderedDataStore juga dibungkus pcall (pelajaran yang sama seperti
-- DataSystem): di place belum publish ia throw, dan leaderboard kosong
-- saja — game tidak boleh mati karenanya.

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local DataSystem = require(script.Parent.DataSystem)

local LeaderboardSystem = {}

local _earnedOk, _earned = pcall(function()
	return DataStoreService:GetOrderedDataStore(Config.LeaderboardStoreName)
end)
local earnedStore = _earnedOk and _earned or nil
if not earnedStore then
	warn("[FusionBay] OrderedDataStore tidak tersedia — leaderboard Top 5 kosong, game tetap jalan.")
end

local cachedTop = {}
local cachedAt = 0

-- Top 5 Total Earned untuk panel Rank di UI. Cache 10 detik supaya
-- client yang refresh berulang tidak membanjiri DataStore.
function LeaderboardSystem.getTop()
	if not earnedStore then
		return cachedTop
	end
	if os.clock() - cachedAt < 10 and #cachedTop > 0 then
		return cachedTop
	end
	local top = {}
	local ok, pages = pcall(function()
		return earnedStore:GetSortedAsync(false, 5)
	end)
	if ok and pages then
		local items = pages:GetCurrentPage()
		for _, item in ipairs(items) do
			local name = "Pemain"
			pcall(function()
				name = Players:GetNameFromUserIdAsync(tonumber(item.key))
			end)
			table.insert(top, { Name = name, Value = item.value })
		end
	end
	cachedTop = top
	cachedAt = os.clock()
	return top
end

function LeaderboardSystem.setupPlayer(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local cash = Instance.new("IntValue")
	cash.Name = "Cash"
	cash.Value = 0
	cash.Parent = leaderstats

	local brainrots = Instance.new("IntValue")
	brainrots.Name = "Brainrots"
	brainrots.Value = 0
	brainrots.Parent = leaderstats

	local rebirths = Instance.new("IntValue")
	rebirths.Name = "Rebirths"
	rebirths.Value = 0
	rebirths.Parent = leaderstats

	-- Update leaderstats tiap detik dari data sesi.
	task.spawn(function()
		while player.Parent do
			task.wait(1)
			local data = DataSystem.get(player)
			if data then
				cash.Value = math.floor(data.Coins)
				brainrots.Value = #data.Owned
				rebirths.Value = data.Rebirths
			end
		end
	end)
end

function LeaderboardSystem.saveScore(player)
	local data = DataSystem.get(player)
	if not data or not earnedStore then
		return
	end
	pcall(function()
		earnedStore:SetAsync(tostring(player.UserId), math.floor(data.TotalEarned))
	end)
end

function LeaderboardSystem.start()
	local Remotes = require(script.Parent.Remotes)
	Remotes.GetLeaderboard.OnServerInvoke = function(_player)
		return LeaderboardSystem.getTop()
	end
	-- Simpan skor berkala (tiap 60 detik, bukan tiap detik: hemat throttle).
	task.spawn(function()
		while true do
			task.wait(60)
			for _, player in ipairs(Players:GetPlayers()) do
				LeaderboardSystem.saveScore(player)
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		LeaderboardSystem.saveScore(player)
	end)
end

return LeaderboardSystem
