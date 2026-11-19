-- Fusion Bay v3.0 — ekonomi. Income per detik, beli brainrot, shop,
-- rebirth, FUSION (twist juara). Semua angka dari Config; semua
-- permintaan client divalidasi di server sebelum diterapkan.

local Players = game:GetService("Players")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local BrainrotDefs = require(game:GetService("ReplicatedStorage").Shared.BrainrotDefs)
local Utils = require(game:GetService("ReplicatedStorage").Shared.Utils)
local DataSystem = require(script.Parent.DataSystem)
local State = require(script.Parent.State)
local Remotes = require(script.Parent.Remotes)
local BrainrotFactory = require(script.Parent.BrainrotFactory)

local EconomySystem = {}

local lastBuy = {}
local lastFuse = {}

-- Kirim snapshot data pemain ke UI client-nya.
function EconomySystem.pushUI(player)
	local data = DataSystem.get(player)
	if not data then
		return
	end
	local base = State.baseForPlayer(player)
	local owned = {}
	for _, rec in ipairs(State.Active) do
		if rec.State == "owned" and rec.Owner == player then
			table.insert(owned, {
				Id = rec.Id,
				DefId = rec.Def.Id,
				Name = rec.Def.Name,
				Rarity = rec.Def.Rarity,
				Mutation = rec.Mutation.Name,
				Fused = rec.Fused or false,
			})
		end
	end
	Remotes.UpdateUIEvent:FireClient(player, {
		Coins = data.Coins,
		IncomePerSec = State.incomePerSecond(player, data, Config),
		Rebirths = data.Rebirths,
		RebirthMult = Config.rebirthMult(data.Rebirths),
		NextRebirth = Config.nextRebirth(data.Rebirths),
		OwnedCount = #data.Owned,
		Owned = owned,
		Steals = data.Steals,
		BaseLocked = base and State.isLocked(base) or false,
		WaveIn = State.WaveIn,
		HasBoots = data.Items.boots,
		-- v3.5: misi berikutnya yang boleh diklaim (1..4; 4 = semua selesai).
		MissionIndex = #(data.MissionsClaimed or {}) + 1,
	})
end

-- Beli brainrot yang sedang berjalan di conveyor (dipanggil dari
-- ClickDetector di Spawner). Cek: masih walking, rate limit 1/detik,
-- jarak < 14 stud, coin cukup, punya base, ada slot kosong.
function EconomySystem.buyBrainrot(player, rec)
	if not rec or rec.State ~= "walking" or not rec.Model or not rec.Model.Parent then
		return
	end
	local now = os.clock()
	if lastBuy[player] and now - lastBuy[player] < Config.BuyCooldownSeconds then
		return
	end
	lastBuy[player] = now
	local data = DataSystem.get(player)
	if not data then
		return
	end
	local root = Utils.getRoot(player)
	if not root then
		return
	end
	local body = rec.Model:FindFirstChild("Body")
	if not body then
		return
	end
	if (root.Position - body.Position).Magnitude > Config.BuyDistance then
		Remotes.notify(player, "Terlalu jauh! Dekati brainrot itu dulu.")
		return
	end
	if data.Coins < rec.Price then
		Remotes.notify(player, "Coin tidak cukup! Butuh " .. Config.formatMoney(rec.Price))
		return
	end
	local base = State.baseForPlayer(player)
	if not base then
		Remotes.notify(player, "Kamu belum punya base!")
		return
	end
	local slot = State.freeSlot(base)
	if not slot then
		Remotes.notify(player, "Base penuh! Rebirth untuk mengosongkan base.")
		return
	end

	data.Coins -= rec.Price
	data.Bought = (data.Bought or 0) + 1 -- v3.5: bukti beli untuk misi 1
	DataSystem.addOwned(player, rec.Def.Id, rec.Mutation.Name, false)
	rec.State = "owned"
	rec.Owner = player
	rec.BaseIndex = base.Index
	rec.SlotIndex = slot
	rec.Fused = false
	local slotPos = base.Slots[slot]
	-- v3.2: TranslateBy via moveTo, bukan PivotTo (mengubur model ~0.55*s).
	BrainrotFactory.moveTo(rec.Model, BrainrotFactory.bodyCenter(slotPos, rec.Def))
	BrainrotFactory.setLabel(rec.Model, rec.Def, rec.Mutation, nil, false)
	-- Matikan ClickDetector supaya tidak bisa dibeli lagi.
	local click = body:FindFirstChild("BuyClick")
	if click then
		click:Destroy()
	end
	Remotes.notify(player, "Dibeli: " .. rec.Def.Name .. " (" .. rec.Mutation.Name .. ")!")
	EconomySystem.pushUI(player)
end

-- Beli item shop: boots (sekali), base lock (cooldown 60 dtk),
-- lucky ticket (sekali aktif sampai spawn berikut).
function EconomySystem.buyItem(player, itemId)
	local data = DataSystem.get(player)
	if not data then
		return
	end
	local item = nil
	for _, it in ipairs(Config.ShopItems) do
		if it.Id == itemId then
			item = it
			break
		end
	end
	if not item then
		return
	end
	if data.Coins < item.Price then
		Remotes.notify(player, "Coin tidak cukup untuk " .. item.Name)
		return
	end
	if itemId == "boots" then
		if data.Items.boots then
			Remotes.notify(player, "Speed Boots sudah dibeli!")
			return
		end
		data.Coins -= item.Price
		data.Items.boots = true
		local hum = Utils.getHumanoid(player)
		if hum then
			hum.WalkSpeed = Config.BootsWalkSpeed
		end
		Remotes.notify(player, "Speed Boots dibeli! Kamu lebih cepat.")
	elseif itemId == "lock" then
		local base = State.baseForPlayer(player)
		if not base then
			return
		end
		if os.clock() < base.LockCooldownUntil then
			Remotes.notify(player, "Base Lock masih cooldown!")
			return
		end
		data.Coins -= item.Price
		base.LockUntil = os.clock() + Config.LockDurationSeconds
		base.LockCooldownUntil = os.clock() + Config.LockCooldownSeconds
		Remotes.notify(player, "Base dikunci 30 detik!")
	elseif itemId == "lucky" then
		if data.Items.lucky then
			Remotes.notify(player, "Lucky Ticket sudah aktif!")
			return
		end
		data.Coins -= item.Price
		data.Items.lucky = true
		Remotes.notify(player, "Lucky Ticket aktif! Spawn berikut min. Golden.")
	end
	EconomySystem.pushUI(player)
end

-- FUSION (twist juara): 2 brainrot rarity sama milik sendiri -> 1
-- brainrot rarity satu tingkat di atas, mutation minimal Golden.
-- Mythic + Mythic -> Mythic dengan mutation Rainbow yang dijamin.
function EconomySystem.fuseBrainrots(player, id1, id2)
	local now = os.clock()
	if lastFuse[player] and now - lastFuse[player] < Config.FusionCooldownSeconds then
		Remotes.notify(player, "Fusion masih cooldown!")
		return
	end
	if id1 == id2 then
		return
	end
	local data = DataSystem.get(player)
	if not data then
		return
	end
	local rec1, rec2 = nil, nil
	for _, rec in ipairs(State.Active) do
		if rec.State == "owned" and rec.Owner == player then
			if rec.Id == id1 then
				rec1 = rec
			elseif rec.Id == id2 then
				rec2 = rec
			end
		end
	end
	if not rec1 or not rec2 then
		Remotes.notify(player, "Pilih 2 brainrot dari basemu!")
		return
	end
	if rec1.Def.Rarity ~= rec2.Def.Rarity then
		Remotes.notify(player, "Fusion butuh 2 brainrot dengan rarity yang SAMA!")
		return
	end
	lastFuse[player] = now
	local base = State.baseForPlayer(player)
	if not base then
		return
	end
	-- Hasil: rarity naik satu tingkat, def acak di tier itu.
	local nextRarity = Config.nextRarity(rec1.Def.Rarity)
	local candidates = BrainrotDefs.ofRarity(nextRarity)
	local resultDef = candidates[math.random(#candidates)]
	-- Mutation: minimal Golden; Mythic + Mythic -> Rainbow dijamin.
	local mutation
	if rec1.Def.Rarity == "Mythic" then
		mutation = Config.Mutations[4] -- Rainbow
	else
		mutation = Config.rollFusionMutation()
	end
	-- Hapus 2 brainrot asal (model + data).
	for _, rec in ipairs({ rec1, rec2 }) do
		DataSystem.removeOwned(player, rec.Def.Id, rec.Mutation.Name, rec.Fused or false)
		if rec.Model then
			rec.Model:Destroy()
		end
		for i, active in ipairs(State.Active) do
			if active == rec then
				table.remove(State.Active, i)
				break
			end
		end
	end
	-- Hasil fusion muncul di Fusion Altar, lalu pindah ke slot kosong.
	local slot = State.freeSlot(base)
	if not slot then
		Remotes.notify(player, "Base penuh! Fusion gagal.")
		return
	end
	DataSystem.addOwned(player, resultDef.Id, mutation.Name, true)
	local model = BrainrotFactory.build(resultDef, mutation, BrainrotFactory.bodyCenter(base.AltarPos, resultDef), true)
	model.Parent = game:GetService("Workspace")
	BrainrotFactory.setLabel(model, resultDef, mutation, nil, true)
	local click = model:FindFirstChild("Body") and model.Body:FindFirstChild("BuyClick")
	if click then
		click:Destroy()
	end
	table.insert(State.Active, {
		Id = State.NextBrainrotId,
		Model = model,
		Def = resultDef,
		Mutation = mutation,
		State = "owned",
		Owner = player,
		BaseIndex = base.Index,
		SlotIndex = slot,
		Fused = true,
		Price = resultDef.Price,
		X = 0,
	})
	State.NextBrainrotId += 1
	task.delay(0.8, function()
		if model.Parent then
			-- v3.2: TranslateBy via moveTo, bukan PivotTo.
			BrainrotFactory.moveTo(model, BrainrotFactory.bodyCenter(base.Slots[slot], resultDef))
		end
	end)
	Remotes.notify(player, "FUSION! " .. resultDef.Name .. " (" .. mutation.Name .. " " .. nextRarity .. ")!")
	Remotes.notifyAll(player.Name .. " melakukan FUSION: " .. resultDef.Name .. "!")
	EconomySystem.pushUI(player)
end

-- Rebirth: bayar coin + syarat karakter Epic/Legendary, base direset,
-- coin kembali ke awal, income berlipat (x2/x3/x4). Total Earned dan
-- jumlah steal TIDAK direset.
function EconomySystem.rebirth(player)
	local data = DataSystem.get(player)
	if not data then
		return
	end
	local level = Config.nextRebirth(data.Rebirths)
	if not level then
		Remotes.notify(player, "Kamu sudah mencapai rebirth maksimal!")
		return
	end
	if data.Coins < level.Cost then
		Remotes.notify(player, "Rebirth butuh " .. Config.formatMoney(level.Cost) .. " coin!")
		return
	end
	local epicCount, legendaryCount = 0, 0
	for _, rec in ipairs(State.Active) do
		if rec.State == "owned" and rec.Owner == player then
			if rec.Def.Rarity == "Epic" then
				epicCount += 1
			elseif rec.Def.Rarity == "Legendary" then
				legendaryCount += 1
			end
		end
	end
	if epicCount < level.NeedEpic or legendaryCount < level.NeedLegendary then
		local need = {}
		if level.NeedEpic > 0 then
			table.insert(need, level.NeedEpic .. " Epic (punya " .. epicCount .. ")")
		end
		if level.NeedLegendary > 0 then
			table.insert(need, level.NeedLegendary .. " Legendary (punya " .. legendaryCount .. ")")
		end
		Remotes.notify(player, "Rebirth butuh: " .. table.concat(need, ", "))
		return
	end
	-- Hapus model brainrot milik pemain dari base.
	for i = #State.Active, 1, -1 do
		local rec = State.Active[i]
		if rec.State == "owned" and rec.Owner == player then
			if rec.Model then
				rec.Model:Destroy()
			end
			table.remove(State.Active, i)
		end
	end
	data.Coins = Config.StartCoins
	data.Owned = {}
	data.Rebirths += 1
	-- Judul rebirth langsung muncul di atas kepala tanpa menunggu respawn.
	local character = player.Character
	local head = character and character:FindFirstChild("Head")
	if head then
		local old = head:FindFirstChild("RebirthTitle")
		if old then
			old:Destroy()
		end
		local gui = Instance.new("BillboardGui")
		gui.Name = "RebirthTitle"
		gui.Size = UDim2.fromOffset(140, 30)
		gui.StudsOffset = Vector3.new(0, 4.5, 0)
		gui.AlwaysOnTop = true
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 0.3
		label.BackgroundColor3 = Color3.fromRGB(80, 0, 120)
		label.Text = "REBIRTH x" .. data.Rebirths
		label.TextColor3 = Color3.fromRGB(255, 215, 0)
		label.TextScaled = true
		label.Font = Enum.Font.SourceSansBold
		label.Parent = gui
		gui.Parent = head
	end
	Remotes.notify(player, "REBIRTH! Income sekarang x" .. level.Mult .. ". Rebirth ke-" .. data.Rebirths)
	Remotes.notifyAll(player.Name .. " REBIRTH ke-" .. data.Rebirths .. "!")
	EconomySystem.pushUI(player)
end

-- MISI (v3.5): client hanya MEMINTA klaim; server memvalidasi dari
-- data miliknya sendiri sebelum memberi coin. Misi harus diklaim
-- berurutan 1 -> 2 -> 3, sekali saja per pemain.
function EconomySystem.claimMission(player, missionId)
	if typeof(missionId) ~= "number" then
		return
	end
	local data = DataSystem.get(player)
	if not data then
		return
	end
	data.MissionsClaimed = data.MissionsClaimed or {}
	local nextId = #data.MissionsClaimed + 1
	if missionId ~= nextId or missionId < 1 or missionId > 3 then
		return -- bukan gilirannya, atau sudah diklaim / tidak ada
	end
	local ok = false
	if missionId == 1 then
		ok = (data.Bought or 0) > 0 -- benar-benar membeli di conveyor
	elseif missionId == 2 then
		for _, owned in ipairs(data.Owned) do
			if owned.Fused then
				ok = true
				break
			end
		end
	elseif missionId == 3 then
		ok = data.SurvivedWave == true
	end
	if not ok then
		return -- syarat belum terpenuhi di server: tidak ada coin
	end
	local reward = Config.MissionRewards[missionId]
	table.insert(data.MissionsClaimed, missionId)
	data.Coins += reward
	data.TotalEarned += reward
	Remotes.notify(player, "MISI SELESAI! +" .. Config.formatMoney(reward) .. " coin.")
	EconomySystem.pushUI(player)
end

-- Income tick tiap detik + hubungkan Remote + refresh cincin kunci base.
function EconomySystem.start()
	Remotes.BuyItemEvent.OnServerEvent:Connect(function(player, itemId)
		if typeof(itemId) ~= "string" then
			return
		end
		EconomySystem.buyItem(player, itemId)
	end)
	Remotes.RebirthEvent.OnServerEvent:Connect(function(player)
		EconomySystem.rebirth(player)
	end)
	Remotes.FuseEvent.OnServerEvent:Connect(function(player, id1, id2)
		if typeof(id1) ~= "number" or typeof(id2) ~= "number" then
			return
		end
		EconomySystem.fuseBrainrots(player, id1, id2)
	end)
	Remotes.MissionEvent.OnServerEvent:Connect(function(player, missionId)
		EconomySystem.claimMission(player, missionId)
	end)
	Remotes.GetPlayerData.OnServerInvoke = function(player)
		local data = DataSystem.get(player)
		if not data then
			return nil
		end
		return {
			Coins = data.Coins,
			TotalEarned = data.TotalEarned,
			Rebirths = data.Rebirths,
			OwnedCount = #data.Owned,
			Steals = data.Steals,
		}
	end

	task.spawn(function()
		while true do
			task.wait(Config.IncomeTickSeconds)
			for _, player in ipairs(Players:GetPlayers()) do
				local data = DataSystem.get(player)
				if data then
					local income = State.incomePerSecond(player, data, Config)
					if income > 0 then
						data.Coins += income
						data.TotalEarned += income
					end
					EconomySystem.pushUI(player)
				end
			end
			-- Cincin kunci: terlihat saat base terkunci, hilang saat habis.
			for _, base in ipairs(State.Bases) do
				if base.LockRing then
					base.LockRing.Transparency = State.isLocked(base) and 0.3 or 1
				end
			end
		end
	end)
end

return EconomySystem
