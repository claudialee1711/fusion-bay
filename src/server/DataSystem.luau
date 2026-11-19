-- Fusion Bay v3.0 — data pemain (DataStore + pcall, autosave, BindToClose).
--
-- PELAJARAN PLAYTEST v2: GetDataStore THROW di place yang belum publish
-- ("You must publish this place to the web to access DataStore").
-- Kalau dilempar di top-level, script mati sebelum MapBuilder jalan dan
-- map jadi baseplate kosong. Jadi BOTH GetDataStore dan
-- GetOrderedDataStore dibungkus pcall; kalau gagal, store = nil dan game
-- tetap jalan penuh dengan data sesi saja (peringatan kuning, bukan error).

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local DataSystem = {}

local _storeOk, _store = pcall(function()
	return DataStoreService:GetDataStore(Config.DataStoreName)
end)
local store = _storeOk and _store or nil
if not store then
	warn("[FusionBay] DataStore tidak tersedia (place belum publish / API Services mati) — data tidak tersimpan antar sesi, game tetap jalan.")
end

local sessionData = {}

function DataSystem.default()
	return {
		Coins = Config.StartCoins,
		TotalEarned = 0,
		Rebirths = 0,
		Owned = {}, -- {DefId, Mutation, Fused}
		Items = { boots = false, lucky = false },
		Steals = 0,
		Bought = 0, -- brainrot yang DIBELI di conveyor (starter gratis tidak dihitung)
		SurvivedWave = false, -- pernah selamat dari tsunami
		MissionsClaimed = {}, -- id misi yang hadiahnya sudah diklaim (1, 2, 3)
	}
end

function DataSystem.load(player)
	local data = DataSystem.default()
	if not store then
		sessionData[player] = data
		return data
	end
	local success, saved = pcall(function()
		return store:GetAsync(tostring(player.UserId))
	end)
	if success and type(saved) == "table" then
		for key, value in pairs(saved) do
			if data[key] ~= nil then
				data[key] = value
			end
		end
		if type(data.Owned) ~= "table" then
			data.Owned = {}
		end
		if type(data.Items) ~= "table" then
			data.Items = { boots = false, lucky = false }
		end
	end
	sessionData[player] = data
	return data
end

function DataSystem.get(player)
	return sessionData[player]
end

function DataSystem.save(player)
	local data = sessionData[player]
	if not data or not store then
		return
	end
	local clean = {
		Coins = data.Coins,
		TotalEarned = data.TotalEarned,
		Rebirths = data.Rebirths,
		Owned = data.Owned,
		Items = data.Items,
		Steals = data.Steals,
		Bought = data.Bought or 0,
		SurvivedWave = data.SurvivedWave or false,
		MissionsClaimed = data.MissionsClaimed or {},
	}
	pcall(function()
		store:SetAsync(tostring(player.UserId), clean)
	end)
end

function DataSystem.clear(player)
	sessionData[player] = nil
end

function DataSystem.addOwned(player, defId, mutationName, fused)
	local data = sessionData[player]
	if not data then
		return false
	end
	table.insert(data.Owned, { DefId = defId, Mutation = mutationName, Fused = fused or false })
	return true
end

function DataSystem.removeOwned(player, defId, mutationName, fused)
	local data = sessionData[player]
	if not data then
		return false
	end
	for i, owned in ipairs(data.Owned) do
		if owned.DefId == defId and owned.Mutation == mutationName
			and (fused == nil or owned.Fused == fused) then
			table.remove(data.Owned, i)
			return true
		end
	end
	return false
end

-- Autosave berkala + simpan saat server mati. Keduanya nil-guarded
-- lewat DataSystem.save (no-op kalau store nil).
task.spawn(function()
	while true do
		task.wait(Config.AutosaveSeconds)
		for _, player in ipairs(Players:GetPlayers()) do
			DataSystem.save(player)
		end
	end
end)

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		DataSystem.save(player)
	end
end)

return DataSystem
