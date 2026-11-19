-- Fusion Bay v3.0 (recorded rebuild) — pusat balancing.
-- Semua angka gameplay hidup di sini. Server menghitung harga, income,
-- dan syarat dari tabel ini; client tidak pernah dipercaya untuk itu.

local Config = {}

Config.GameName = "Fusion Bay"
Config.BuildVersion = "v3.0"
Config.StartCoins = 100
Config.DataStoreName = "FusionBayDataV1"
Config.LeaderboardStoreName = "FusionBay_Earned_V1"
Config.AutosaveSeconds = 180

Config.IncomeTickSeconds = 1
Config.MaxBaseSlots = 6
Config.MaxPlayers = 8
Config.RebirthIncomeBonus = 0.25 -- fallback kalau rebirth melewati tabel

-- Tangga rebirth: level ke-n memakai RebirthLevels[n].
-- Mult adalah pengali income TOTAL setelah rebirth itu, bukan tambahan.
Config.RebirthLevels = {
	{ Cost = 10000, NeedEpic = 5, NeedLegendary = 0, Mult = 2 },
	{ Cost = 50000, NeedEpic = 0, NeedLegendary = 2, Mult = 3 },
	{ Cost = 200000, NeedEpic = 0, NeedLegendary = 5, Mult = 4 },
}

function Config.rebirthMult(rebirths)
	local level = Config.RebirthLevels[rebirths]
	if level then
		return level.Mult
	elseif rebirths > 0 then
		return 1 + Config.RebirthIncomeBonus * rebirths
	end
	return 1
end

function Config.nextRebirth(playerRebirths)
	local level = Config.RebirthLevels[playerRebirths + 1]
	if not level then
		return nil
	end
	return {
		Level = playerRebirths + 1,
		Cost = level.Cost,
		NeedEpic = level.NeedEpic,
		NeedLegendary = level.NeedLegendary,
		Mult = level.Mult,
	}
end

-- Dua Common gratis untuk pemain baru: base langsung berisi dan
-- income langsung terasa dalam 30 detik pertama.
Config.StarterBrainrots = { "pisang-kucing", "kayu-sahur" }

-- Conveyor (v3.0: jalur z=30, dekat spawn)
Config.SpawnIntervalSeconds = 6
Config.MaxOnConveyor = 10
Config.ConveyorSpeed = 6 -- stud per detik
Config.ConveyorStartX = -90
Config.ConveyorEndX = 90
Config.ConveyorLaneZ = 30
Config.BuyDistance = 14
Config.BuyCooldownSeconds = 1 -- rate limit beli per pemain

-- Steal / slap (fair steal)
Config.NormalWalkSpeed = 16
Config.CarryWalkSpeed = 12 -- pembawa curian 25% lebih lambat
Config.BootsWalkSpeed = 20
Config.SlapCooldownSeconds = 2
Config.SlapRange = 10
Config.SlapKnockback = 40
Config.PickupDistance = 4
Config.StealCooldownSeconds = 20 -- jeda antar steal oleh pemain yang sama
Config.StealSameVictimSeconds = 60 -- tidak boleh curi 2x dari korban sama
Config.SpawnProtectionSeconds = 60 -- base pemain baru kebal curi
Config.AutoLockAfterStealSeconds = 30 -- base korban terkunci otomatis

-- Base lock
Config.LockCost = 500
Config.LockDurationSeconds = 30
Config.LockCooldownSeconds = 60

-- Wave (tsunami)
Config.WaveIntervalSeconds = 90
Config.WaveWarningSeconds = 10
Config.WaveSweepSeconds = 8
Config.WaveCoinLoss = 0.10 -- 10% coin hilang kalau kena ombak di luar base
Config.WaveSurvivorReward = 50 -- coin untuk yang selamat di base sendiri

-- Misi (v3.5): hadiah hanya diklaim server setelah validasi
-- (beli / fusion / selamat tsunami) — client tidak bisa memberi
-- coin ke dirinya sendiri. Urutan misi 1 -> 2 -> 3.
Config.MissionRewards = { 100, 250, 150 }

-- Shop
Config.ShopItems = {
	{ Id = "boots", Name = "Speed Boots", Price = 1500, Desc = "+4 WalkSpeed permanen" },
	{ Id = "lock", Name = "Base Lock 30s", Price = 500, Desc = "Kunci basemu 30 detik" },
	{ Id = "lucky", Name = "Lucky Ticket", Price = 2000, Desc = "Spawn berikut min. Golden" },
}

-- Skala model 3D per rarity (sebelum pengali visual 2.0x di factory).
Config.RarityScale = {
	Common = 1.0,
	Rare = 1.1,
	Epic = 1.2,
	Legendary = 1.35,
	Mythic = 1.5,
}

-- Warna label rarity.
Config.Rarities = {
	Common = Color3.fromRGB(200, 200, 200),
	Rare = Color3.fromRGB(80, 180, 255),
	Epic = Color3.fromRGB(180, 90, 255),
	Legendary = Color3.fromRGB(255, 170, 0),
	Mythic = Color3.fromRGB(255, 60, 90),
}

-- Mutation: {nama, pengali income, peluang, warna label}
Config.Mutations = {
	{ Name = "Normal", Mult = 1, Chance = 0.85, Color = Color3.fromRGB(255, 255, 255) },
	{ Name = "Golden", Mult = 2, Chance = 0.10, Color = Color3.fromRGB(255, 215, 0) },
	{ Name = "Diamond", Mult = 5, Chance = 0.04, Color = Color3.fromRGB(120, 220, 255) },
	{ Name = "Rainbow", Mult = 10, Chance = 0.01, Color = Color3.fromRGB(255, 120, 220) },
}

-- FUSION: gabung 2 brainrot rarity sama -> 1 brainrot satu tingkat di
-- atas, mutation dijamin minimal Golden. Mythic + Mythic = Mythic Rainbow.
Config.FusionTiers = { "Common", "Rare", "Epic", "Legendary", "Mythic" }
Config.FusionCooldownSeconds = 10

function Config.nextRarity(rarity)
	for i, r in ipairs(Config.FusionTiers) do
		if r == rarity then
			return Config.FusionTiers[math.min(i + 1, #Config.FusionTiers)]
		end
	end
	return rarity
end

-- Roll mutation hasil fusion: Golden 70%, Diamond 25%, Rainbow 5%.
function Config.rollFusionMutation()
	local r = math.random()
	if r < 0.70 then
		return Config.Mutations[2]
	elseif r < 0.95 then
		return Config.Mutations[3]
	else
		return Config.Mutations[4]
	end
end

function Config.rollMutation(lucky)
	if lucky then
		local r = math.random()
		if r < 0.10 then
			return Config.Mutations[4] -- Rainbow
		elseif r < 0.45 then
			return Config.Mutations[3] -- Diamond
		else
			return Config.Mutations[2] -- Golden
		end
	end
	local r = math.random()
	local acc = 0
	for _, m in ipairs(Config.Mutations) do
		acc += m.Chance
		if r <= acc then
			return m
		end
	end
	return Config.Mutations[1]
end

function Config.formatMoney(n)
	n = math.floor(n + 0.5)
	if n >= 1000000 then
		return string.format("$%.1fM", n / 1000000)
	elseif n >= 1000 then
		return string.format("$%.1fK", n / 1000)
	else
		return "$" .. tostring(n)
	end
end

return Config
