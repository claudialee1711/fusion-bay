-- Fusion Bay v3.0 — bangun dunia 3D di Workspace saat server mulai.
-- Pantai golden hour, conveyor z=30, 8 base, palem, laut, spawn,
-- matahari Neon, papan kecil, Fusion Altar per base, dinding ombak.
--
-- PELAJARAN PLAYTEST v2 yang diterapkan di sini:
-- - Spawn Orientation Y=0 (menghadap utara/-Z ke conveyor). Y=180 salah:
--   itu menghadap selatan (+Z) ke tepi map kosong.
-- - Papan nama KECIL di dekat spawn (0,4,60), bukan papan raksasa di tengah.
-- - WaveWall disembunyikan dengan Transparency = 1 — Part TIDAK punya
--   properti Visible (itu milik GuiObject).
-- - Slot base dan AltarPos menyimpan titik TANAH (y=2.3); pemanggil
--   memakai BrainrotFactory.bodyCenter() untuk titik badan.
-- v3.3: Baseplate di default.project.json DIHAPUS — Ground (atas y=1.0)
--   adalah satu-satunya lantai. Semua yang menapak tanah naik +1.0
--   dari v3.2 supaya tidak ada yang tenggelam relatif ke tanah baru.

local State = require(script.Parent.State)

local MapBuilder = {}

local function newPart(parent, name, size, pos, color, opts)
	opts = opts or {}
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Position = pos
	p.Color = color
	p.Anchored = true
	p.CanCollide = opts.CanCollide ~= false
	p.CanQuery = true
	if opts.Transparency then
		p.Transparency = opts.Transparency
	end
	if opts.Material then
		p.Material = opts.Material
	end
	p.Parent = parent
	return p
end

function MapBuilder.build()
	local ws = game:GetService("Workspace")
	local Lighting = game:GetService("Lighting")

	-- Golden hour: langit hangat supaya karakter terlihat jelas dan
	-- screenshot terasa hangat, bukan abu-abu siang bolong.
	Lighting.Ambient = Color3.fromRGB(120, 100, 90)
	Lighting.Brightness = 2.5
	Lighting.GlobalShadows = true
	Lighting.OutdoorAmbient = Color3.fromRGB(160, 140, 120)
	Lighting.ClockTime = 16.5
	Lighting.GeographicLatitude = 20
	Lighting.ColorShift_Top = Color3.fromRGB(255, 220, 170)
	Lighting.ColorShift_Bottom = Color3.fromRGB(120, 140, 180)

	-- Matahari golden hour di langit barat (bola Neon besar).
	local sun = Instance.new("Part")
	sun.Name = "Sun"
	sun.Shape = Enum.PartType.Ball
	sun.Size = Vector3.new(30, 30, 30)
	sun.Position = Vector3.new(-90, 55, -105)
	sun.Color = Color3.fromRGB(255, 200, 90)
	sun.Material = Enum.Material.Neon
	sun.Anchored = true
	sun.CanCollide = false
	sun.Parent = ws

	-- Tanah pantai, laut di utara, pasir di tepi laut.
	-- v3.3: Ground Size (220,4,220) pusat y=-1 (atas y=1.0), hijau
	-- terang — TIDAK sejajar lagi dengan apa pun. Baseplate sudah
	-- dihapus dari default.project.json, jadi Ground adalah
	-- satu-satunya lantai dan harus terlihat hijau dari spawn.
	newPart(ws, "Ground", Vector3.new(220, 4, 220), Vector3.new(0, -1, 0),
		Color3.fromRGB(80, 220, 90), { Material = Enum.Material.Grass })
	newPart(ws, "Sea", Vector3.new(220, 1, 22), Vector3.new(0, 0.2, -99),
		Color3.fromRGB(40, 140, 230), { Transparency = 0.25, Material = Enum.Material.Water, CanCollide = false })
	newPart(ws, "Beach", Vector3.new(220, 1, 10), Vector3.new(0, 0.6, -84),
		Color3.fromRGB(240, 220, 160), { Material = Enum.Material.Sand })

	-- Conveyor di z=30: 45 stud dari spawn (z=75), brainrot langsung
	-- terlihat jelas dari spawn tanpa harus jalan jauh.
	-- v3.3: conveyor naik +1.0 (pusat y=1.1, atas y=1.6), warna terang
	-- supaya terbaca sebagai pita di seberang pandangan dari spawn.
	newPart(ws, "Conveyor", Vector3.new(190, 1, 14), Vector3.new(0, 1.1, 30),
		Color3.fromRGB(200, 200, 210), { Material = Enum.Material.SmoothPlastic })
	for x = -90, 90, 15 do
		local arrow = newPart(ws, "ConveyorArrow", Vector3.new(4, 0.2, 6), Vector3.new(x, 1.7, 30),
			Color3.fromRGB(255, 200, 60), { CanCollide = false })
		arrow.Orientation = Vector3.new(0, 90, 0)
	end
	newPart(ws, "RailNorth", Vector3.new(190, 2, 1), Vector3.new(0, 2, 22.5), Color3.fromRGB(40, 40, 50))
	newPart(ws, "RailSouth", Vector3.new(190, 2, 1), Vector3.new(0, 2, 37.5), Color3.fromRGB(40, 40, 50))
	-- v3.3: strip Neon kuning di atas rel — conveyor harus terbaca
	-- sebagai pita terang di seluruh lebar pandangan dari spawn.
	newPart(ws, "ConveyorEdgeNorth", Vector3.new(190, 0.3, 0.6), Vector3.new(0, 3.15, 22.5),
		Color3.fromRGB(255, 215, 0), { CanCollide = false, Material = Enum.Material.Neon })
	newPart(ws, "ConveyorEdgeSouth", Vector3.new(190, 0.3, 0.6), Vector3.new(0, 3.15, 37.5),
		Color3.fromRGB(255, 215, 0), { CanCollide = false, Material = Enum.Material.Neon })

	-- Spawn: menghadap UTARA (-Z, ke conveyor dan base).
	-- Orientation Y=0 = utara. Y=180 = selatan, membelakangi game.
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "SpawnLocation"
	spawn.Size = Vector3.new(16, 1, 12)
	spawn.Position = Vector3.new(0, 1.5, 75)
	spawn.Orientation = Vector3.new(0, 0, 0)
	spawn.Color = Color3.fromRGB(255, 220, 90)
	spawn.Anchored = true
	spawn.Parent = ws

	-- 8 base pemain (posisi dan warna dari State).
	local positions = State.basePositions()
	local colors = State.baseColors()
	for i, pos in ipairs(positions) do
		local center = Vector3.new(pos.X, 0, pos.Z)
		local platform = newPart(ws, "BasePlatform" .. i, Vector3.new(30, 1, 24),
			Vector3.new(pos.X, 1.5, pos.Z), colors[i], { Material = Enum.Material.SmoothPlastic })
		-- Dinding belakang base (penanda visual).
		newPart(ws, "BaseWall" .. i, Vector3.new(30, 6, 1),
			Vector3.new(pos.X, 4, pos.Z + (pos.Z < 0 and -12 or 12)), colors[i], { Transparency = 0.5 })
		-- Zona base (tidak terlihat, untuk deteksi steal/deliver/wave).
		local zone = newPart(ws, "BaseZone" .. i, Vector3.new(30, 8, 24),
			Vector3.new(pos.X, 5, pos.Z), colors[i],
			{ Transparency = 1, CanCollide = false })

	-- 6 slot brainrot: 3 kolom x 2 baris. Slot menyimpan titik TANAH
		-- (y=2.3 = atas pad slot); pemanggil memakai bodyCenter()
		-- (ground + 1.6*s) untuk mengubahnya jadi titik badan.
		local slots = {}
		for row = 1, 2 do
			for col = 1, 3 do
				local sx = pos.X - 10 + (col - 1) * 10
				local sz = pos.Z - 6 + (row - 1) * 12
				newPart(ws, "BaseSlotPad" .. i .. "_" .. #slots + 1, Vector3.new(6, 0.3, 6),
					Vector3.new(sx, 2.1, sz), Color3.fromRGB(255, 255, 255),
					{ Transparency = 0.4, CanCollide = false })
				table.insert(slots, Vector3.new(sx, 2.3, sz))
			end
		end

		-- Label nama pemilik base (160x36, tidak AlwaysOnTop supaya
		-- label base sebelah tidak menumpuk di layar).
		local labelGui = Instance.new("BillboardGui")
		labelGui.Name = "BaseLabel"
		labelGui.Size = UDim2.fromOffset(160, 36)
		labelGui.StudsOffset = Vector3.new(0, 6, 0)
		labelGui.AlwaysOnTop = false
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Text = "Base " .. i .. " (kosong)"
		label.TextColor3 = Color3.fromRGB(255, 255, 255)
		label.TextStrokeTransparency = 0.2
		label.TextScaled = true
		label.Font = Enum.Font.SourceSansBold
		label.Parent = labelGui
		labelGui.Parent = platform

		-- Cincin kunci: terlihat (Neon kuning) saat base dikunci.
		local lockRing = newPart(ws, "BaseLockRing" .. i, Vector3.new(0.4, 32, 32),
			Vector3.new(pos.X, 3, pos.Z), Color3.fromRGB(255, 215, 0),
			{ Transparency = 1, CanCollide = false, Material = Enum.Material.Neon })
		lockRing.Orientation = Vector3.new(0, 0, 90)

		-- FUSION ALTAR (twist juara): pad Neon emas di tengah belakang
		-- base, tempat brainrot hasil fusion muncul. AltarPos adalah
		-- titik TANAH (y=2.3); pemanggil memakai bodyCenter().
		local altarPos = Vector3.new(pos.X, 2.3, pos.Z + (pos.Z < 0 and -9 or 9))
		local altar = newPart(ws, "FusionAltar" .. i, Vector3.new(0.4, 8, 8),
			altarPos, Color3.fromRGB(255, 215, 0),
			{ Transparency = 0.1, CanCollide = false, Material = Enum.Material.Neon })
		altar.Orientation = Vector3.new(0, 0, 90)
		local altarGui = Instance.new("BillboardGui")
		altarGui.Name = "FusionLabel"
		altarGui.Size = UDim2.fromOffset(160, 36)
		altarGui.StudsOffset = Vector3.new(0, 3.5, 0)
		altarGui.AlwaysOnTop = false
		local altarText = Instance.new("TextLabel")
		altarText.Size = UDim2.fromScale(1, 1)
		altarText.BackgroundTransparency = 0.3
		altarText.BackgroundColor3 = Color3.fromRGB(60, 40, 0)
		altarText.Text = "FUSION"
		altarText.TextColor3 = Color3.fromRGB(255, 215, 0)
		altarText.TextScaled = true
		altarText.Font = Enum.Font.SourceSansBold
		altarText.Parent = altarGui
		altarGui.Parent = altar

		table.insert(State.Bases, {
			Index = i,
			Center = center,
			Slots = slots,
			Owner = nil,
			Zone = zone,
			Platform = platform,
			NameLabel = label,
			LockRing = lockRing,
			AltarPos = altarPos,
			LockUntil = 0,
			LockCooldownUntil = 0,
			Color = colors[i],
		})
	end

	-- Plaza spawn: lingkaran ubin warna-warni di sekitar SpawnLocation.
	for ring = 1, 3 do
		local plaza = newPart(ws, "SpawnPlaza" .. ring, Vector3.new(0.3, 22 - ring * 4, 22 - ring * 4),
			Vector3.new(0, 1.4, 75), Color3.fromRGB(255, 200 + ring * 10, 90),
			{ Transparency = 0.2, CanCollide = false, Material = Enum.Material.SmoothPlastic })
		plaza.Orientation = Vector3.new(0, 0, 90)
	end

	-- Payung pantai di dekat spawn + peti kayu di ujung conveyor.
	local umbrellaSpots = { { -14, 62 }, { 14, 62 }, { -14, 88 }, { 14, 88 } }
	for _, spot in ipairs(umbrellaSpots) do
		newPart(ws, "UmbrellaPole", Vector3.new(0.5, 6, 0.5),
			Vector3.new(spot[1], 4, spot[2]), Color3.fromRGB(200, 200, 200))
		local top = newPart(ws, "UmbrellaTop", Vector3.new(0.3, 9, 9),
			Vector3.new(spot[1], 7.2, spot[2]), Color3.fromRGB(255, 90, 120),
			{ Material = Enum.Material.SmoothPlastic })
		top.Orientation = Vector3.new(0, 0, 90)
	end
	for _, cx in ipairs({ -98, 98 }) do
		newPart(ws, "Crate", Vector3.new(4, 4, 4), Vector3.new(cx, 3, 16),
			Color3.fromRGB(170, 120, 60), { Material = Enum.Material.Wood })
		newPart(ws, "Crate", Vector3.new(3, 3, 3), Vector3.new(cx, 2.5, 21),
			Color3.fromRGB(150, 105, 55), { Material = Enum.Material.Wood })
	end

	-- Awan putih melayang (tidak bisa ditabrak).
	local cloudSpots = { { -60, 42, -60 }, { 40, 48, -70 }, { 80, 40, 60 }, { -40, 46, 70 } }
	for _, spot in ipairs(cloudSpots) do
		local cloud = Instance.new("Part")
		cloud.Name = "Cloud"
		cloud.Shape = Enum.PartType.Ball
		cloud.Size = Vector3.new(24, 10, 14)
		cloud.Position = Vector3.new(spot[1], spot[2], spot[3])
		cloud.Color = Color3.fromRGB(255, 255, 255)
		cloud.Transparency = 0.15
		cloud.Anchored = true
		cloud.CanCollide = false
		cloud.Material = Enum.Material.SmoothPlastic
		cloud.Parent = ws
	end

	-- Pohon palem di sudut-sudut.
	local palmSpots = { { -100, -70 }, { 100, -70 }, { -100, 70 }, { 100, 70 }, { -60, 80 }, { 60, -80 } }
	for _, spot in ipairs(palmSpots) do
		local trunk = newPart(ws, "PalmTrunk", Vector3.new(1.5, 10, 1.5),
			Vector3.new(spot[1], 6, spot[2]), Color3.fromRGB(140, 95, 50),
			{ Material = Enum.Material.Wood })
		trunk.Orientation = Vector3.new(0, 0, 8)
		for k = 1, 5 do
			local leaf = newPart(ws, "PalmLeaf", Vector3.new(6, 0.5, 2),
				Vector3.new(spot[1] + math.cos(k * 1.25) * 3, 11.5, spot[2] + math.sin(k * 1.25) * 3),
				Color3.fromRGB(40, 180, 80), { Material = Enum.Material.Grass })
			leaf.Orientation = Vector3.new(0, k * 72, 20)
		end
	end

	-- Dinding ombak (disembunyikan sampai wave datang).
	-- Part TIDAK punya properti Visible — pakai Transparency = 1.
	local wall = newPart(ws, "WaveWall", Vector3.new(220, 30, 4),
		Vector3.new(0, 12, -130), Color3.fromRGB(60, 160, 255),
		{ Transparency = 0.35, Material = Enum.Material.Water, CanCollide = false })
	wall.Transparency = 1
	State.WaveWall = wall

	-- Papan nama game KECIL di dekat spawn (0,5,60) — Part 10x3,
	-- BillboardGui 160x40, AlwaysOnTop=false. Terlihat saat masuk tapi
	-- tidak ada apa pun yang menghalangi pandangan spawn -> conveyor.
	local sign = newPart(ws, "GameSign", Vector3.new(10, 3, 1), Vector3.new(0, 5, 60),
		Color3.fromRGB(255, 200, 60))
	local signGui = Instance.new("BillboardGui")
	signGui.Size = UDim2.fromOffset(160, 40)
	signGui.StudsOffset = Vector3.new(0, 2, 0)
	signGui.AlwaysOnTop = false
	local signText = Instance.new("TextLabel")
	signText.Size = UDim2.fromScale(1, 1)
	signText.BackgroundTransparency = 1
	signText.Text = "FUSION BAY"
	signText.TextColor3 = Color3.fromRGB(40, 40, 90)
	signText.TextStrokeTransparency = 0.5
	signText.TextScaled = true
	signText.Font = Enum.Font.SourceSansBold
	signText.Parent = signGui
	signGui.Parent = sign

	print("[FusionBay] MAP v3.3: conveyor z=30, 8 base, papan kecil di spawn (0,5,60), tanah hijau atas y=1")
	return State.Bases
end

return MapBuilder
