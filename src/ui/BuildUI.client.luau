-- Fusion Bay v3.0 — semua UI. HUD, Shop, Fusion, Rebirth, Leaderboard,
-- Bantuan, toast notifikasi, banner wave, tutorial awal. Client hanya
-- menampilkan; semua keputusan ekonomi ada di server.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local events = remotes:WaitForChild("RemoteEvents")
local functions = remotes:WaitForChild("RemoteFunctions")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local updateUIEvent = events:WaitForChild("UpdateUIEvent")
local notifyEvent = events:WaitForChild("NotifyEvent")
local waveEvent = events:WaitForChild("WaveEvent")
local buyItemEvent = events:WaitForChild("BuyItemEvent")
local rebirthEvent = events:WaitForChild("RebirthEvent")
local fuseEvent = events:WaitForChild("FuseEvent")
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

-- ============ HUD (kanan atas, jauh dari menu Roblox kiri atas) ============
local hud = Instance.new("Frame")
hud.Size = UDim2.new(0, 300, 0, 130)
hud.Position = UDim2.new(1, -316, 0, 16)
hud.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
hud.BackgroundTransparency = 0.15
hud.BorderSizePixel = 0
local hudCorner = Instance.new("UICorner")
hudCorner.CornerRadius = UDim.new(0, 12)
hudCorner.Parent = hud
hud.Parent = gui

local coinsLabel = makeLabel(hud, "Coin: 0", UDim2.new(1, -20, 0, 36), UDim2.new(0, 10, 0, 8), Color3.fromRGB(255, 215, 0))
coinsLabel.TextSize = 28
local incomeLabel = makeLabel(hud, "Income: 0/s", UDim2.new(1, -20, 0, 28), UDim2.new(0, 10, 0, 46), Color3.fromRGB(120, 255, 140))
local rebirthLabel = makeLabel(hud, "Rebirth: 0 (x1)", UDim2.new(1, -20, 0, 28), UDim2.new(0, 10, 0, 74))
local waveLabel = makeLabel(hud, "Wave: --", UDim2.new(1, -20, 0, 28), UDim2.new(0, 10, 0, 100), Color3.fromRGB(120, 200, 255))

-- ============ Tombol menu (kanan, di bawah HUD) ============
local menuButtons = {}
local menuDefs = {
	{ Id = "Shop", Text = "SHOP", Color = Color3.fromRGB(40, 120, 200) },
	{ Id = "Fusion", Text = "FUSION", Color = Color3.fromRGB(180, 130, 0) },
	{ Id = "Rebirth", Text = "REBIRTH", Color = Color3.fromRGB(120, 40, 160) },
	{ Id = "Rank", Text = "RANK", Color = Color3.fromRGB(40, 140, 90) },
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

-- Toggle panel: hanya satu yang terbuka.
local function toggleFrame(id)
	for key, frame in pairs(frames) do
		if key == id then
			frame.Visible = not frame.Visible
			if frame.Visible and key == "Rank" then
				refreshRank()
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

-- ============ Banner wave ============
local waveBanner = Instance.new("TextLabel")
waveBanner.Size = UDim2.new(0, 640, 0, 64)
waveBanner.Position = UDim2.new(0.5, -320, 0, 24)
waveBanner.AnchorPoint = Vector2.new(0.5, 0)
waveBanner.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
waveBanner.BackgroundTransparency = 0.15
waveBanner.TextColor3 = Color3.fromRGB(255, 255, 255)
waveBanner.TextSize = 30
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
	coinsLabel.Text = "Coin: " .. Config.formatMoney(data.Coins)
	incomeLabel.Text = "Income: " .. Config.formatMoney(data.IncomePerSec) .. "/s"
	rebirthLabel.Text = "Rebirth: " .. tostring(data.Rebirths) .. " (x" .. tostring(data.RebirthMult) .. ")"
	if data.WaveIn and data.WaveIn > 0 then
		waveLabel.Text = "Wave: " .. tostring(data.WaveIn) .. "s"
	else
		waveLabel.Text = "Wave: TSUNAMI!"
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
