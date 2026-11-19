-- Fusion Bay v3.1 (recorded rebuild) — server utama.
-- Bangun map, muat sistem, urus pemain masuk/keluar.
--
-- PENTING (pelajaran playtest v2): script ini ADALAH Script "Server"
-- hasil Rojo (init.server.luau), jadi modul-modul lain adalah ANAK
-- script ini, bukan anak ServerScriptService. require(script.X) benar;
-- require(script.Parent.X) SALAH di sini — itu yang dulu bikin error
-- "MapBuilder is not a valid member of ServerScriptService" dan map kosong.
-- ModuleScript lain (bukan init) memakai script.Parent.X dengan benar,
-- karena Parent mereka adalah Script "Server" ini.

local Players = game:GetService("Players")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local BrainrotDefs = require(game:GetService("ReplicatedStorage").Shared.BrainrotDefs)
local MapBuilder = require(script.MapBuilder)
local BrainrotFactory = require(script.BrainrotFactory)
local DataSystem = require(script.DataSystem)
local State = require(script.State)
local Spawner = require(script.Spawner)
local EconomySystem = require(script.EconomySystem)
local StealSystem = require(script.StealSystem)
local WaveSystem = require(script.WaveSystem)
local LeaderboardSystem = require(script.LeaderboardSystem)
local Remotes = require(script.Remotes)

-- Remotes dibuat saat modul Remotes di-require (tidak dipakai langsung di sini).
_ = Remotes

MapBuilder.build()

-- Bangun kembali model brainrot milik pemain dari data simpanan
-- (setelah load / rejoin). Model memakai bodyCenter() supaya menapak.
local function spawnOwnedBrainrots(player, data)
	local base = State.baseForPlayer(player)
	if not base then
		return
	end
	for _, owned in ipairs(data.Owned) do
		local def = BrainrotDefs.ById[owned.DefId]
		if def then
			local mutation = Config.Mutations[1]
			for _, m in ipairs(Config.Mutations) do
				if m.Name == owned.Mutation then
					mutation = m
					break
				end
			end
			local slot = State.freeSlot(base)
			if slot then
				local fused = owned.Fused or false
				local model = BrainrotFactory.build(def, mutation, BrainrotFactory.bodyCenter(base.Slots[slot], def), fused)
				model.Parent = game:GetService("Workspace")
				BrainrotFactory.setLabel(model, def, mutation, nil, fused)
				local click = model:FindFirstChild("Body") and model.Body:FindFirstChild("BuyClick")
				if click then
					click:Destroy()
				end
				table.insert(State.Active, {
					Id = State.NextBrainrotId,
					Model = model,
					Def = def,
					Mutation = mutation,
					State = "owned",
					Owner = player,
					BaseIndex = base.Index,
					SlotIndex = slot,
					Fused = fused,
					Price = def.Price,
					X = 0,
				})
				State.NextBrainrotId += 1
			end
		end
	end
end

-- Pemain baru (belum pernah rebirth, belum pernah dapat income) diberi
-- 2 brainrot Common gratis supaya base tidak kosong di screenshot
-- pertama dan loop income langsung terasa. Setelah rebirth tidak dapat
-- starter lagi, karena rebirth memang mengosongkan base.
local function grantStarterBrainrots(player, data)
	if data.Rebirths > 0 or data.TotalEarned > 0 or #data.Owned > 0 then
		return
	end
	for _, starterId in ipairs(Config.StarterBrainrots) do
		table.insert(data.Owned, { DefId = starterId, Mutation = "Normal", Fused = false })
	end
end

-- Judul rebirth di atas kepala: "REBIRTH xN" — status sosial di server.
local function updateRebirthTitle(player, data)
	local character = player.Character
	if not character then
		return
	end
	local head = character:FindFirstChild("Head")
	if not head then
		return
	end
	local old = head:FindFirstChild("RebirthTitle")
	if old then
		old:Destroy()
	end
	if data.Rebirths <= 0 then
		return
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

-- v3.1: PAKSA karakter menghadap UTARA (-Z, ke conveyor/base).
-- SpawnLocation Orientation Y=0 saja TIDAK cukup: di playtest v2.2,
-- v2.3 DAN v3.0 karakter tetap spawn menghadap SELATAN (+Z, ke tepi
-- map kosong) dan kamera ikut menghadap selatan, jadi conveyor, sign,
-- dan base (semuanya di utara) tidak terlihat. Karena itu arah hadap
-- dipaksa di sini lewat HumanoidRootPart.CFrame — bukan lewat
-- SpawnLocation. Dipanggil sekali saat spawn DAN sekali lagi setelah
-- 0.5 detik, karena Roblox kadang mengorientasi ulang karakter sesaat
-- setelah spawn. SpawnLocation tetap Y=0 (jangan dibalik ke 180).
local function faceNorth(character)
	local hrp = character:WaitForChild("HumanoidRootPart", 10)
	if not hrp then
		return
	end
	local pos = hrp.Position
	hrp.CFrame = CFrame.new(pos, pos + Vector3.new(0, 0, -1))
	print("[FusionBay] SPAWN menghadap utara")
end

local function onPlayerAdded(player)
	local data = DataSystem.load(player)
	LeaderboardSystem.setupPlayer(player)
	StealSystem.noteJoin(player)
	local base = State.assignBase(player)
	if base then
		base.NameLabel.Text = "Base " .. player.Name
		base.NameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		print("[FusionBay] BASE v2: " .. player.Name .. " -> Base " .. base.Index .. " di (" .. base.Center.X .. ", " .. base.Center.Z .. ")")
	end
	grantStarterBrainrots(player, data)
	spawnOwnedBrainrots(player, data)
	print("[FusionBay] PLAYER v2: " .. player.Name .. " starter=" .. #data.Owned .. " brainrot, base=" .. (base and base.Index or 0))
	StealSystem.giveSlapTool(player)
	-- Terapkan Speed Boots saat karakter spawn + judul rebirth.
	player.CharacterAdded:Connect(function(character)
		faceNorth(character)
		task.delay(0.5, function()
			faceNorth(character)
		end)
		task.wait(0.5)
		local hum = character:FindFirstChildOfClass("Humanoid")
		if hum and data.Items.boots then
			hum.WalkSpeed = Config.BootsWalkSpeed
		end
		updateRebirthTitle(player, data)
		-- Beri lagi Slap tool kalau hilang saat respawn.
		StealSystem.giveSlapTool(player)
	end)
	-- Kalau karakter sudah ada saat onPlayerAdded jalan (rejoin cepat),
	-- CharacterAdded tidak akan fire lagi — paksa hadap utara langsung.
	if player.Character then
		task.spawn(faceNorth, player.Character)
	end
	task.wait(1)
	EconomySystem.pushUI(player)
	Remotes.notify(player, "Selamat datang di Fusion Bay! Klik brainrot di conveyor untuk membeli. Gabungkan 2 brainrot sama di Fusion Altar!")
end

local function onPlayerRemoving(player)
	-- Kembalikan brainrot curian yang sedang dibawa.
	if State.Carrying[player] then
		StealSystem.dropCarried(player, true)
	end
	-- Hapus model brainrot milik pemain dari dunia.
	for i = #State.Active, 1, -1 do
		local rec = State.Active[i]
		if rec.State == "owned" and rec.Owner == player then
			if rec.Model then
				rec.Model:Destroy()
			end
			table.remove(State.Active, i)
		end
	end
	local base = State.baseForPlayer(player)
	if base then
		base.Owner = nil
		base.NameLabel.Text = "Base " .. base.Index .. " (kosong)"
	end
	DataSystem.save(player)
	DataSystem.clear(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

Spawner.start()
EconomySystem.start()
StealSystem.start()
WaveSystem.start()
LeaderboardSystem.start()

-- Penanda versi di Output: kalau baris ini tidak muncul, user membuka
-- file LAMA, bukan build v3.0 ini.
local walking = 0
for _, rec in ipairs(State.Active) do
	if rec.State == "walking" then
		walking += 1
	end
end
print("[FusionBay] BUILD v3.2 recorded rebuild: tanpa PivotTo (model tidak tenggelam), tanah hijau di atas baseplate, spawn dipaksa menghadap utara (server+camera), conveyor z=30, model 2.0x, grounding 1.6x (kaki menapak), sign kecil di spawn, brainrot di conveyor=" .. walking)
print("Fusion Bay server started.")
