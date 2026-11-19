-- Fusion Bay v3.0 — state bersama semua sistem server.
-- Diisi MapBuilder (Bases), Spawner (Active), StealSystem (Carrying).

local State = {}

State.Bases = {} -- {Index, Center, Slots, Owner, Zone, Platform, NameLabel, LockRing, AltarPos, LockUntil, LockCooldownUntil, Color}
State.Active = {} -- record brainrot: {Id, Model, Def, Mutation, State, Owner, BaseIndex, SlotIndex, Price, Fused}
State.Carrying = {} -- [player] = record yang sedang dibawa
State.NextBrainrotId = 1
State.WaveIn = 90
State.WaveActive = false
State.WaveWall = nil

-- Layout base v3.0: baris utara z=-45, baris selatan z=62 dengan
-- x = -90, -60, 60, 90 — celah tengah x=-45..45 kosong supaya dari
-- spawn (0,75) conveyor (z=30) langsung terlihat tanpa terhalang base.
local BASE_POSITIONS = {
	{ X = -75, Z = -45 }, { X = -25, Z = -45 }, { X = 25, Z = -45 }, { X = 75, Z = -45 },
	{ X = -90, Z = 62 }, { X = -60, Z = 62 }, { X = 60, Z = 62 }, { X = 90, Z = 62 },
}

local BASE_COLORS = {
	Color3.fromRGB(255, 90, 90), Color3.fromRGB(90, 160, 255), Color3.fromRGB(90, 220, 120),
	Color3.fromRGB(255, 200, 60), Color3.fromRGB(200, 110, 255), Color3.fromRGB(90, 220, 220),
	Color3.fromRGB(255, 140, 90), Color3.fromRGB(180, 200, 255),
}

function State.basePositions()
	return BASE_POSITIONS
end

function State.baseColors()
	return BASE_COLORS
end

-- Slot kosong pertama di base (slot terisi = ada record "owned" di sana).
function State.freeSlot(base)
	for i, _slot in ipairs(base.Slots) do
		local taken = false
		for _, rec in ipairs(State.Active) do
			if rec.State == "owned" and rec.BaseIndex == base.Index and rec.SlotIndex == i then
				taken = true
				break
			end
		end
		if not taken then
			return i
		end
	end
	return nil
end

function State.baseForPlayer(player)
	for _, base in ipairs(State.Bases) do
		if base.Owner == player then
			return base
		end
	end
	return nil
end

-- Base kosong yang PALING DEKAT dengan spawn (0,75): pemain pertama
-- dapat base selatan, jadi 2 starter langsung terlihat dari spawn.
function State.assignBase(player)
	local spawnPos = Vector3.new(0, 0, 75)
	local best, bestDist = nil, nil
	for _, base in ipairs(State.Bases) do
		if base.Owner == nil then
			local d = (base.Center - spawnPos).Magnitude
			if not bestDist or d < bestDist then
				best, bestDist = base, d
			end
		end
	end
	if best then
		best.Owner = player
	end
	return best
end

function State.isLocked(base)
	return base.LockUntil and os.clock() < base.LockUntil
end

-- Income per detik pemain: jumlah income brainrot miliknya
-- (income dasar x mutation) dikali pengali rebirth.
function State.incomePerSecond(player, data, Config)
	local mult = Config.rebirthMult(data.Rebirths)
	local total = 0
	for _, rec in ipairs(State.Active) do
		if rec.State == "owned" and rec.Owner == player then
			total += rec.Def.Income * rec.Mutation.Mult * mult
		end
	end
	return math.floor(total + 0.5)
end

return State
