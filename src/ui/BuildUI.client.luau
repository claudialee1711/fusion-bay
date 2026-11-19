-- Fusion Bay v3.0 — semua UI. HUD, Shop, Fusion, Rebirth, Leaderboard,
-- Bantuan, toast notifikasi, banner wave, tutorial awal. Client hanya
-- menampilkan; semua keputusan ekonomi ada di server.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local events = remotes:WaitForChild("RemoteEvents")
local functions = remotes:WaitForChild("RemoteFunctions")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local BrainrotDefs = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotDefs"))

local updateUIEvent = events:WaitForChild("UpdateUIEvent")
local notifyEvent = events:WaitForChild("NotifyEvent")
local waveEvent = events:WaitForChild("WaveEvent")
local buyItemEvent = events:WaitForChild("BuyItemEvent")
local rebirthEvent = events:WaitForChild("RebirthEvent")
local fuseEvent = events:WaitForChild("FuseEvent")
local missionEvent = events:WaitForChild("MissionEvent")
local getLeaderboard = functions:WaitForChild("GetLeaderboard")

-- ============ Pembangun widget ============
local function makeLabel(parent, text, size, pos, color)
	local l = Instance.new("TextLabel")
	l.Size = size
	l.Position = pos
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextColor3 = color or Color3.fromRGB(255, 255, 255)
	l.TextSize = 20
	l.Font = Enum.Font.SourceSansBold
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Parent = parent
	return l
end

local function makeButton(parent, text, size, pos, color)
	local b = Instance.new("TextButton")
	b.Size = size
	b.Position = pos
	b.BackgroundColor3 = color or Color3.fromRGB(60, 60, 80)
	b.Text = text
	b.TextColor3 = Color3.fromRGB(255, 255, 255)
	b.TextSize = 20
	b.Font = Enum.Font.SourceSansBold
	b.BorderSizePixel = 0
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = b
	b.Parent = parent
	return b
end

local function makeFrame(parent, size, pos)
	local f = Instance.new("Frame")
	f.Size = size
	f.Position = pos
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
	f.BackgroundTransparency = 0.1
	f.BorderSizePixel = 0
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = f
	f.Visible = false
	f.Parent = parent
	return f
end

-- ============ Root ============
local gui = Instance.new("ScreenGui")
gui.Name = "FusionBayUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.Parent = playerGui

-- ============ Pil uang tengah atas (v3.5, ala rank 1) ============
-- Dulu panel koin di kanan atas; sekarang pil navy tengah atas:
-- angka cash hijau besar, di bawahnya 3 pil kecil (income / mult /
-- rebirth), lalu baris status wave. Pil digeser 40px ke kanan dari
-- tengah supaya tidak menumpuk bar objektif di kiri atas.
local hud = Instance.new("Frame")
hud.Size = UDim2.new(0, 320, 0, 88)
hud.Position = UDim2.new(0.5, 40, 0, 12)
hud.AnchorPoint = Vector2.new(0.5, 0)
hud.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
hud.BackgroundTransparency = 0.15
hud.BorderSizePixel = 0
local hudCorner = Instance.new("UICorner")
hudCorner.CornerRadius = UDim.new(0, 12)
hudCorner.Parent = hud
hud.Parent = gui

local coinsLabel = Instance.new("TextLabel")
coinsLabel.Size = UDim2.new(1, 0, 0, 34)
coinsLabel.Position = UDim2.new(0, 0, 0, 4)
coinsLabel.BackgroundTransparency = 1
coinsLabel.Text = "$0"
coinsLabel.TextColor3 = Color3.fromRGB(120, 255, 140)
coinsLabel.TextSize = 28
coinsLabel.Font = Enum.Font.SourceSansBold
coinsLabel.TextXAlignment = Enum.TextXAlignment.Center
coinsLabel.Parent = hud

local function makePill(text, pos, width, color)
	local p = Instance.new("TextLabel")
	p.Size = UDim2.new(0, width, 0, 20)
	p.Position = pos
	p.BackgroundColor3 = color
	p.Text = text
	p.TextColor3 = Color3.fromRGB(255, 255, 255)
	p.TextSize = 15
	p.Font = Enum.Font.SourceSansBold
	p.TextXAlignment = Enum.TextXAlignment.Center
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 10)
	c.Parent = p
	p.Parent = hud
	return p
end
local incomeLabel = makePill("+$0/s", UDim2.new(0, 10, 0, 42), 120, Color3.fromRGB(40, 140, 70))
local multLabel = makePill("x1", UDim2.new(0, 138, 0, 42), 56, Color3.fromRGB(200, 120, 0))
local rebirthLabel = makePill("REBIRTH 0", UDim2.new(0, 202, 0, 42), 108, Color3.fromRGB(160, 40, 160))
local waveLabel = Instance.new("TextLabel")
waveLabel.Size = UDim2.new(1, 0, 0, 18)
waveLabel.Position = UDim2.new(0, 0, 0, 66)
waveLabel.BackgroundTransparency = 1
waveLabel.Text = "Wave: --"
waveLabel.TextColor3 = Color3.fromRGB(120, 200, 255)
waveLabel.TextSize = 14
waveLabel.Font = Enum.Font.SourceSansBold
waveLabel.TextXAlignment = Enum.TextXAlignment.Center
waveLabel.Parent = hud

-- ============ Objektif permanen (v3.4, kiri atas, selalu terlihat) ============
-- Alur game dalam satu baris — pemain baru langsung tahu yang harus
-- dilakukan tanpa membuka panel BANTUAN. Di bawah bar ini tidak ada
-- apa-apa lagi: banner wave dipindah ke y=56 supaya tidak menumpuk.
local objective = Instance.new("TextLabel")
objective.Size = UDim2.new(0, 360, 0, 44)
objective.Position = UDim2.new(0, 12, 0, 12)
objective.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
objective.BackgroundTransparency = 0.3
objective.Text = "1. Beli di conveyor  2. Kumpulkan $/detik\n3. Fusion 2 sama  4. Lari ke base saat tsunami"
objective.TextColor3 = Color3.fromRGB(255, 255, 255)
objective.TextSize = 13
objective.Font = Enum.Font.SourceSansBold
objective.TextXAlignment = Enum.TextXAlignment.Left
objective.TextWrapped = true
local objectiveCorner = Instance.new("UICorner")
objectiveCorner.CornerRadius = UDim.new(0, 8)
objectiveCorner.Parent = objective
objective.Parent = gui

-- ============ Tombol menu (kanan, di bawah HUD) ============
local menuButtons = {}
local menuDefs = {
	{ Id = "Shop", Text = "SHOP", Color = Color3.fromRGB(40, 120, 200) },
	{ Id = "Fusion", Text = "FUSION", Color = Color3.fromRGB(180, 130, 0) },
	{ Id = "Rebirth", Text = "REBIRTH", Color = Color3.fromRGB(120, 40, 160) },
	{ Id = "Rank", Text = "RANK", Color = Color3.fromRGB(40, 140, 90) },
	{ Id = "Index", Text = "INDEX", Color = Color3.fromRGB(40, 120, 220) },
	{ Id = "Help", Text = "BANTUAN", Color = Color3.fromRGB(80, 80, 100) },
}
for i, def in ipairs(menuDefs) do
	local b = makeButton(gui, def.Text, UDim2.new(0, 130, 0, 44),
		UDim2.new(1, -146, 0, 160 + (i - 1) * 52), def.Color)
	menuButtons[def.Id] = b
end

-- ============ Panel-panel ============
local frames = {}

-- SHOP
local shopFrame = makeFrame(gui, UDim2.new(0, 420, 0, 300), UDim2.new(0.5, 0, 0.5, 0))
frames.Shop = shopFrame
makeLabel(shopFrame, "SHOP", UDim2.new(1, -20, 0, 36), UDim2.new(0, 10, 0, 8), Color3.fromRGB(255, 215, 0)).TextSize = 26
for i, item in ipairs(Config.ShopItems) do
	local y = 52 + (i - 1) * 72
	makeLabel(shopFrame, item.Name .. " - " .. Config.formatMoney(item.Price),
		UDim2.new(1, -140, 0, 28), UDim2.new(0, 10, 0, y)).TextSize = 20
	local desc = makeLabel(shopFrame, item.Desc, UDim2.new(1, -140, 0, 28),
		UDim2.new(0, 10, 0, y + 28), Color3.fromRGB(200, 200, 210))
	desc.TextSize = 17
	local buy = makeButton(shopFrame, "BELI", UDim2.new(0, 110, 0, 44), UDim2.new(1, -120, 0, y), Color3.fromRGB(40, 160, 70))
	buy.MouseButton1Click:Connect(function()
		buyItemEvent:FireServer(item.Id)
	end)
end
makeButton(shopFrame, "TUTUP", UDim2.new(0, 110, 0, 40), UDim2.new(1, -120, 1, -50), Color3.fromRGB(120, 40, 40)).MouseButton1Click:Connect(function()
	shopFrame.Visible = false
end)

-- FUSION
local fusionFrame = makeFrame(gui, UDim2.new(0, 460, 0, 380), UDim2.new(0.5, 0, 0.5, 0))
frames.Fusion = fusionFrame
makeLabel(fusionFrame, "FUSION ALTAR", UDim2.new(1, -20, 0, 36), UDim2.new(0, 10, 0, 8), Color3.fromRGB(255, 215, 0)).TextSize = 26
local fusionInfo = makeLabel(fusionFrame, "Pilih 2 brainrot dengan rarity SAMA dari basemu.\nHasil: 1 brainrot rarity di atasnya, min. Golden.\nMythic + Mythic = Mythic Rainbow!",
	UDim2.new(1, -20, 0, 66), UDim2.new(0, 10, 0, 44), Color3.fromRGB(220, 220, 230))
fusionInfo.TextSize = 17
local ownedScroll = Instance.new("ScrollingFrame")
ownedScroll.Size = UDim2.new(1, -20, 0, 190)
ownedScroll.Position = UDim2.new(0, 10, 0, 118)
ownedScroll.BackgroundTransparency = 1
ownedScroll.BorderSizePixel = 0
ownedScroll.ScrollBarThickness = 6
ownedScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
ownedScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 6)
listLayout.Parent = ownedScroll
ownedScroll.Parent = fusionFrame
local fuseButton = makeButton(fusionFrame, "FUSE (pilih 2 dulu)", UDim2.new(0, 220, 0, 48), UDim2.new(0.5, -110, 1, -58), Color3.fromRGB(180, 130, 0))
local fusionHint = makeLabel(fusionFrame, "", UDim2.new(1, -20, 0, 24), UDim2.new(0, 10, 1, -96), Color3.fromRGB(255, 200, 100))
fusionHint.TextSize = 17

-- REBIRTH
local rebirthFrame = makeFrame(gui, UDim2.new(0, 420, 0, 300), UDim2.new(0.5, 0, 0.5, 0))
frames.Rebirth = rebirthFrame
makeLabel(rebirthFrame, "REBIRTH", UDim2.new(1, -20, 0, 36), UDim2.new(0, 10, 0, 8), Color3.fromRGB(200, 140, 255)).TextSize = 26
local rebirthInfo = makeLabel(rebirthFrame, "", UDim2.new(1, -20, 0, 120), UDim2.new(0, 10, 0, 52), Color3.fromRGB(220, 220, 230))
rebirthInfo.TextSize = 19
local rebirthButton = makeButton(rebirthFrame, "REBIRTH SEKARANG", UDim2.new(0, 240, 0, 48), UDim2.new(0.5, -120, 0, 190), Color3.fromRGB(120, 40, 160))
rebirthButton.MouseButton1Click:Connect(function()
	rebirthEvent:FireServer()
end)
makeButton(rebirthFrame, "TUTUP", UDim2.new(0, 110, 0, 40), UDim2.new(1, -120, 1, -50), Color3.fromRGB(120, 40, 40)).MouseButton1Click:Connect(function()
	rebirthFrame.Visible = false
end)

-- RANK / LEADERBOARD
local rankFrame = makeFrame(gui, UDim2.new(0, 420, 0, 320), UDim2.new(0.5, 0, 0.5, 0))
frames.Rank = rankFrame
makeLabel(rankFrame, "TOP 5 - TOTAL EARNED", UDim2.new(1, -20, 0, 36), UDim2.new(0, 10, 0, 8), Color3.fromRGB(120, 255, 140)).TextSize = 26
local rankList = makeLabel(rankFrame, "Tekan REFRESH untuk memuat.", UDim2.new(1, -20, 0, 180), UDim2.new(0, 10, 0, 52), Color3.fromRGB(220, 220, 230))
rankList.TextSize = 20
local function refreshRank()
	local ok, top = pcall(function()
		return getLeaderboard:InvokeServer()
	end)
	if not ok or not top or #top == 0 then
		rankList.Text = "Belum ada data ranking."
		return
	end
	local lines = {}
	for i, entry in ipairs(top) do
		table.insert(lines, i .. ". " .. entry.Name .. " - " .. Config.formatMoney(entry.Value))
	end
	rankList.Text = table.concat(lines, "\n")
end
makeButton(rankFrame, "REFRESH", UDim2.new(0, 140, 0, 44), UDim2.new(0, 10, 1, -54), Color3.fromRGB(40, 140, 90)).MouseButton1Click:Connect(refreshRank)
makeButton(rankFrame, "TUTUP", UDim2.new(0, 110, 0, 40), UDim2.new(1, -120, 1, -50), Color3.fromRGB(120, 40, 40)).MouseButton1Click:Connect(function()
	rankFrame.Visible = false
end)

-- INDEX (v3.5, ala rank 1): grid 10 karakter, 2 baris x 5 kolom.
-- Kartu milik pemain yang ada di base dapat tag hijau "ON BASE".
local indexFrame = makeFrame(gui, UDim2.new(0, 580, 0, 420), UDim2.new(0.5, 0, 0.5, 0))
frames.Index = indexFrame
local indexTitle = makeLabel(indexFrame, "FUSION BAY INDEX — 0 / 10", UDim2.new(1, -20, 0, 36), UDim2.new(0, 10, 0, 8), Color3.fromRGB(120, 200, 255))
indexTitle.TextSize = 26
local indexGrid = Instance.new("Frame")
indexGrid.Size = UDim2.new(1, -20, 1, -100)
indexGrid.Position = UDim2.new(0, 10, 0, 52)
indexGrid.BackgroundTransparency = 1
indexGrid.Parent = indexFrame
local indexLayout = Instance.new("UIGridLayout")
indexLayout.CellSize = UDim2.new(0, 104, 0, 140)
indexLayout.CellPadding = UDim2.new(0, 6, 0, 6)
indexLayout.SortOrder = Enum.SortOrder.LayoutOrder
indexLayout.Parent = indexGrid
makeButton(indexFrame, "TUTUP [X]", UDim2.new(0, 140, 0, 40), UDim2.new(0.5, -70, 1, -50), Color3.fromRGB(120, 40, 40)).MouseButton1Click:Connect(function()
	indexFrame.Visible = false
end)

-- BANTUAN / TUTORIAL
local helpFrame = makeFrame(gui, UDim2.new(0, 480, 0, 380), UDim2.new(0.5, 0, 0.5, 0))
frames.Help = helpFrame
makeLabel(helpFrame, "CARA MAIN - FUSION BAY", UDim2.new(1, -20, 0, 36), UDim2.new(0, 10, 0, 8), Color3.fromRGB(255, 215, 0)).TextSize = 26
local helpText = makeLabel(helpFrame,
	"1. Brainrot berjalan di conveyor tengah.\n   Klik brainrot untuk membeli (harus dekat).\n"
	.. "2. Brainrot di basemu menghasilkan coin tiap detik.\n   Semakin langka, semakin besar income.\n"
	.. "3. FUSION: gabung 2 brainrot rarity sama di\n   panel FUSION jadi 1 rarity di atasnya.\n"
	.. "4. CURI brainrot dari base pemain lain, tapi\n   hati-hati: kamu jadi lambat dan terlihat!\n   Slap pemain yang mencuri darimu.\n"
	.. "5. TSUNAMI tiap 90 detik: lari pulang ke base\n   atau kamu kehilangan 10% coin.\n"
	.. "6. REBIRTH: reset base, income berlipat ganda.",
	UDim2.new(1, -20, 0, 260), UDim2.new(0, 10, 0, 52), Color3.fromRGB(220, 220, 230))
helpText.TextSize = 19
makeButton(helpFrame, "MULAI MAIN", UDim2.new(0, 180, 0, 48), UDim2.new(0.5, -90, 1, -60), Color3.fromRGB(40, 160, 70)).MouseButton1Click:Connect(function()
	helpFrame.Visible = false
end)

-- Daftar DefId yang sedang dimiliki di base (diisi dari UpdateUIEvent).
-- Dipakai INDEX untuk tag "ON BASE" — tanpa RemoteFunction baru.
local ownedDefIds = {}
local function rebuildIndex()
	for _, child in ipairs(indexGrid:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	local ownedCount = 0
	for _, def in ipairs(BrainrotDefs.List) do
		local owned = ownedDefIds[def.Id] == true
		if owned then
			ownedCount += 1
		end
		local card = Instance.new("Frame")
		card.Size = UDim2.new(0, 104, 0, 140)
		card.BackgroundColor3 = owned and Color3.fromRGB(40, 90, 50) or Color3.fromRGB(50, 50, 70)
		card.BorderSizePixel = 0
		local cc = Instance.new("UICorner")
		cc.CornerRadius = UDim.new(0, 8)
		cc.Parent = card
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(1, -8, 0, 44)
		nameLabel.Position = UDim2.new(0, 4, 0, 4)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = def.Name
		nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		nameLabel.TextSize = 13
		nameLabel.TextWrapped = true
		nameLabel.Font = Enum.Font.SourceSansBold
		nameLabel.Parent = card
		local rarityLabel = Instance.new("TextLabel")
		rarityLabel.Size = UDim2.new(1, -8, 0, 20)
		rarityLabel.Position = UDim2.new(0, 4, 0, 50)
		rarityLabel.BackgroundTransparency = 1
		rarityLabel.Text = def.Rarity
		rarityLabel.TextColor3 = Config.Rarities[def.Rarity] or Color3.fromRGB(255, 255, 255)
		rarityLabel.TextSize = 15
		rarityLabel.Font = Enum.Font.SourceSansBold
		rarityLabel.Parent = card
		local incomeCard = Instance.new("TextLabel")
		incomeCard.Size = UDim2.new(1, -8, 0, 20)
		incomeCard.Position = UDim2.new(0, 4, 0, 72)
		incomeCard.BackgroundTransparency = 1
		incomeCard.Text = Config.formatMoney(def.Income) .. "/s"
		incomeCard.TextColor3 = Color3.fromRGB(120, 255, 140)
		incomeCard.TextSize = 15
		incomeCard.Font = Enum.Font.SourceSansBold
		incomeCard.Parent = card
		local priceLabel = Instance.new("TextLabel")
		priceLabel.Size = UDim2.new(1, -8, 0, 20)
		priceLabel.Position = UDim2.new(0, 4, 0, 94)
		priceLabel.BackgroundTransparency = 1
		priceLabel.Text = "Harga " .. Config.formatMoney(def.Price)
		priceLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
		priceLabel.TextSize = 14
		priceLabel.Font = Enum.Font.SourceSansBold
		priceLabel.Parent = card
		if owned then
			local tag = Instance.new("TextLabel")
			tag.Size = UDim2.new(1, -8, 0, 18)
			tag.Position = UDim2.new(0, 4, 0, 116)
			tag.BackgroundColor3 = Color3.fromRGB(40, 160, 70)
			tag.Text = "ON BASE"
			tag.TextColor3 = Color3.fromRGB(255, 255, 255)
			tag.TextSize = 13
			tag.Font = Enum.Font.SourceSansBold
			local tc = Instance.new("UICorner")
			tc.CornerRadius = UDim.new(0, 6)
			tc.Parent = tag
			tag.Parent = card
		end
		card.Parent = indexGrid
	end
	indexTitle.Text = "FUSION BAY INDEX — " .. ownedCount .. " / 10"
end

-- Toggle panel: hanya satu yang terbuka.
local function toggleFrame(id)
	for key, frame in pairs(frames) do
		if key == id then
			frame.Visible = not frame.Visible
			if frame.Visible and key == "Rank" then
				refreshRank()
			elseif frame.Visible and key == "Index" then
				rebuildIndex()
			end
		else
			frame.Visible = false
		end
	end
end
for id, button in pairs(menuButtons) do
	button.MouseButton1Click:Connect(function()
		toggleFrame(id)
	end)
end

-- Tombol I (v3.5): buka/tutup INDEX. UI ini sebelumnya tidak punya
-- key binding sama sekali — hanya tombol mouse.
ContextActionService:BindAction("ToggleIndex", function(_, state)
	if state == Enum.UserInputState.Begin then
		toggleFrame("Index")
	end
	return Enum.ContextActionResult.Sink
end, false, Enum.KeyCode.I)

-- ============ Toast notifikasi ============
local toast = Instance.new("TextLabel")
toast.Size = UDim2.new(0, 520, 0, 44)
toast.Position = UDim2.new(0.5, -260, 1, -90)
toast.AnchorPoint = Vector2.new(0.5, 0)
toast.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
toast.BackgroundTransparency = 0.1
toast.TextColor3 = Color3.fromRGB(255, 255, 255)
toast.TextSize = 19
toast.Font = Enum.Font.SourceSansBold
toast.Visible = false
local toastCorner = Instance.new("UICorner")
toastCorner.CornerRadius = UDim.new(0, 10)
toastCorner.Parent = toast
toast.Parent = gui

local toastToken = 0
notifyEvent.OnClientEvent:Connect(function(message)
	toastToken += 1
	local myToken = toastToken
	toast.Text = tostring(message)
	toast.Visible = true
	task.delay(3, function()
		if myToken == toastToken then
			toast.Visible = false
		end
	end)
end)

-- ============ Mission bar (v3.5, ala rank 1) ============
-- Bar navy di bawah tengah layar, selalu terlihat. Misi berurutan
-- 1 -> 2 -> 3; hadiah TIDAK diberikan client — client hanya meminta
-- klaim ke server (MissionEvent), server memvalidasi dari datanya
-- sendiri (Bought / Fused / SurvivedWave) sebelum memberi coin.
local missionDefs = {
	{ Text = "MISSION: Beli brainrot di conveyor (0/1) +$100", Reward = 100 },
	{ Text = "MISSION: Fusion 1 brainrot (0/1) +$250", Reward = 250 },
	{ Text = "MISSION: Selamat dari 1 tsunami (0/1) +$150", Reward = 150 },
}
local missionIndex = 1 -- 1..3 aktif, 4 = semua selesai
local missionBar = Instance.new("TextLabel")
missionBar.Size = UDim2.new(0, 640, 0, 36)
missionBar.Position = UDim2.new(0.5, 0, 1, -44)
missionBar.AnchorPoint = Vector2.new(0.5, 0)
missionBar.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
missionBar.BackgroundTransparency = 0.1
missionBar.TextColor3 = Color3.fromRGB(255, 255, 255)
missionBar.TextSize = 18
missionBar.Font = Enum.Font.SourceSansBold
missionBar.TextXAlignment = Enum.TextXAlignment.Center
local missionCorner = Instance.new("UICorner")
missionCorner.CornerRadius = UDim.new(0, 10)
missionCorner.Parent = missionBar
missionBar.Parent = gui

local function updateMissionBar()
	if missionIndex > #missionDefs then
		missionBar.Text = "MISSION: Semua misi selesai!"
		missionBar.BackgroundColor3 = Color3.fromRGB(40, 140, 70)
	else
		missionBar.Text = missionDefs[missionIndex].Text
		missionBar.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
	end
end
updateMissionBar()

local missionToken = 0
local function completeMission(id)
	if id ~= missionIndex or id > #missionDefs then
		return
	end
	missionToken += 1
	local myToken = missionToken
	missionEvent:FireServer(id)
	missionBar.Text = "SELESAI! +" .. Config.formatMoney(missionDefs[id].Reward) .. " coin"
	missionBar.BackgroundColor3 = Color3.fromRGB(40, 160, 70)
	task.delay(3, function()
		if myToken ~= missionToken then
			return
		end
		missionIndex = id + 1
		updateMissionBar()
	end)
end

-- Deteksi penyelesaian dari notifikasi PRIBADI server (bukan notifyAll
-- pemain lain): "Dibeli: ..." = beli sendiri, "FUSION! ..." = fusion
-- sendiri, "Kamu selamat dari tsunami! ..." = selamat wave sendiri.
notifyEvent.OnClientEvent:Connect(function(message)
	local msg = tostring(message)
	if missionIndex == 1 and string.sub(msg, 1, 8) == "Dibeli: " then
		completeMission(1)
	elseif missionIndex == 2 and string.sub(msg, 1, 8) == "FUSION! " then
		completeMission(2)
	elseif missionIndex == 3 and string.sub(msg, 1, 25) == "Kamu selamat dari tsunami" then
		completeMission(3)
	end
end)

-- ============ Banner wave (v3.4: kecil, 60% lebar, 48px, transparan,
-- dan HILANG sendiri setelah warning berakhir — tidak menutupi layar
-- selama tsunami berjalan. v3.5: dipindah ke y=108, di bawah pil uang
-- tengah atas, supaya ketiganya tidak menumpuk.)
local waveBanner = Instance.new("TextLabel")
waveBanner.Size = UDim2.new(0.6, 0, 0, 48)
waveBanner.Position = UDim2.new(0.5, 0, 0, 108)
waveBanner.AnchorPoint = Vector2.new(0.5, 0)
waveBanner.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
waveBanner.BackgroundTransparency = 0.3
waveBanner.TextColor3 = Color3.fromRGB(255, 255, 255)
waveBanner.TextSize = 22
waveBanner.Font = Enum.Font.SourceSansBold
waveBanner.Visible = false
local bannerCorner = Instance.new("UICorner")
bannerCorner.CornerRadius = UDim.new(0, 12)
bannerCorner.Parent = waveBanner
waveBanner.Parent = gui

local bannerToken = 0
waveEvent.OnClientEvent:Connect(function(kind, seconds)
	bannerToken += 1
	local myToken = bannerToken
	if kind == "warning" then
		waveBanner.Text = "TSUNAMI DALAM " .. tostring(seconds) .. " DETIK! LARI KE BASE!"
		waveBanner.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
		waveBanner.Visible = true
	elseif kind == "start" then
		waveBanner.Text = "TSUNAMI! SEMBUNYI DI BASE!"
		waveBanner.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
		waveBanner.Visible = true
		-- v3.4: peringatan 10 detik sudah berakhir — banner hilang
		-- sendiri 3 detik setelah tsunami mulai, jangan menutupi
		-- layar selama tsunami berjalan (status tetap ada di HUD).
		task.delay(3, function()
			if myToken == bannerToken then
				waveBanner.Visible = false
			end
		end)
	elseif kind == "end" then
		waveBanner.Text = "Tsunami lewat!"
		waveBanner.BackgroundColor3 = Color3.fromRGB(40, 140, 90)
		waveBanner.Visible = true
		task.delay(3, function()
			if myToken == bannerToken then
				waveBanner.Visible = false
			end
		end)
	end
end)

-- ============ Update UI dari server ============
local selectedFusion = {} -- array of record Id, maks 2

local function rebuildOwnedList(owned)
	for _, child in ipairs(ownedScroll:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	if not owned or #owned == 0 then
		fusionHint.Text = "Basemu masih kosong. Beli brainrot dulu!"
		return
	end
	for _, item in ipairs(owned) do
		local label = item.Name .. " | " .. item.Mutation .. " " .. item.Rarity
		if item.Fused then
			label = "FUSED " .. label
		end
		local b = makeButton(ownedScroll, label, UDim2.new(1, -6, 0, 36), UDim2.new(0, 0, 0, 0), Color3.fromRGB(50, 50, 70))
		b.TextSize = 18
		b.TextXAlignment = Enum.TextXAlignment.Left
		-- Tandai yang terpilih.
		for _, selId in ipairs(selectedFusion) do
			if selId == item.Id then
				b.BackgroundColor3 = Color3.fromRGB(180, 130, 0)
			end
		end
		b.MouseButton1Click:Connect(function()
			-- Toggle pilih; maks 2; rarity kedua harus sama dengan pertama.
			local found = nil
			for i, selId in ipairs(selectedFusion) do
				if selId == item.Id then
					found = i
					break
				end
			end
			if found then
				table.remove(selectedFusion, found)
			else
				if #selectedFusion >= 2 then
					selectedFusion = { item.Id }
				elseif #selectedFusion == 1 then
					local firstRarity = nil
					for _, o in ipairs(owned) do
						if o.Id == selectedFusion[1] then
							firstRarity = o.Rarity
							break
						end
					end
					if firstRarity and firstRarity ~= item.Rarity then
						fusionHint.Text = "Rarity harus SAMA! Pilihan pertama: " .. firstRarity
						selectedFusion = { item.Id }
					else
						table.insert(selectedFusion, item.Id)
					end
				else
					table.insert(selectedFusion, item.Id)
				end
			end
			rebuildOwnedList(owned)
			if #selectedFusion == 2 then
				fuseButton.Text = "FUSE SEKARANG!"
				fusionHint.Text = "Siap fusion! Hasil: rarity satu tingkat di atas."
			else
				fuseButton.Text = "FUSE (pilih 2 dulu)"
			end
		end)
	end
end

local lastOwned = {}
updateUIEvent.OnClientEvent:Connect(function(data)
	coinsLabel.Text = Config.formatMoney(data.Coins)
	incomeLabel.Text = "+" .. Config.formatMoney(data.IncomePerSec) .. "/s"
	multLabel.Text = "x" .. tostring(data.RebirthMult)
	rebirthLabel.Text = "REBIRTH " .. tostring(data.Rebirths)
	if data.WaveIn and data.WaveIn > 0 then
		waveLabel.Text = "Wave: " .. tostring(data.WaveIn) .. "s"
	else
		waveLabel.Text = "Wave: TSUNAMI!"
	end
	-- v3.5: sinkron misi dari server (mis. setelah rejoin, misi yang
	-- sudah diklaim tidak diulang lagi) dan daftar owned untuk INDEX.
	if data.MissionIndex and data.MissionIndex > missionIndex then
		missionIndex = data.MissionIndex
		updateMissionBar()
	end
	-- Panel rebirth.
	if data.NextRebirth then
		local n = data.NextRebirth
		rebirthInfo.Text = "Rebirth ke-" .. tostring(n.Level) .. "\n"
			.. "Biaya: " .. Config.formatMoney(n.Cost) .. " coin\n"
			.. "Butuh: " .. tostring(n.NeedEpic) .. " Epic, " .. tostring(n.NeedLegendary) .. " Legendary\n"
			.. "Hadiah: income x" .. tostring(n.Mult) .. " (base direset)"
	else
		rebirthInfo.Text = "Kamu sudah mencapai rebirth maksimal!"
	end
	-- Daftar owned untuk fusion (rebuild hanya jika berubah).
	if data.Owned then
		ownedDefIds = {}
		for _, o in ipairs(data.Owned) do
			ownedDefIds[o.DefId] = true
		end
		if indexFrame.Visible then
			rebuildIndex()
		end
		local changed = #data.Owned ~= #lastOwned
		if not changed then
			for i, o in ipairs(data.Owned) do
				if not lastOwned[i] or lastOwned[i].Id ~= o.Id then
					changed = true
					break
				end
			end
		end
		if changed then
			lastOwned = data.Owned
			-- Bersihkan pilihan yang sudah tidak ada.
			local stillThere = {}
			for _, selId in ipairs(selectedFusion) do
				for _, o in ipairs(data.Owned) do
					if o.Id == selId then
						table.insert(stillThere, selId)
						break
					end
				end
			end
			selectedFusion = stillThere
			rebuildOwnedList(data.Owned)
		end
	end
end)

fuseButton.MouseButton1Click:Connect(function()
	if #selectedFusion == 2 then
		fuseEvent:FireServer(selectedFusion[1], selectedFusion[2])
		selectedFusion = {}
		fuseButton.Text = "FUSE (pilih 2 dulu)"
	end
end)

-- Tutorial: panel bantuan langsung terbuka saat pertama masuk.
helpFrame.Visible = true
