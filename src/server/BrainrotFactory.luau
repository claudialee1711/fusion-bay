-- Fusion Bay v3.0 — bangun model 3D brainrot dari Part (tanpa aset eksternal).
--
-- Yang terlihat di screenshot:
-- - Bentuk badan beda per karakter (box / ball / cylinder dari def.Shape).
-- - Ukuran membesar per rarity (RarityScale x 2.0).
-- - Cincin Neon warna rarity di bawah model.
-- - Mutation terlihat: Golden = trim emas, Diamond = badan Neon
--   transparan, Rainbow = 3 orb warna mengorbit kepala.
-- - Aksesori khas per karakter (pisang, sirip hiu, mahkota, dst).
-- - FUSED: mahkota emas besar + label "FUSED". Mythic: partikel emas.
-- - Label 120x40, MaxDistance 50, AlwaysOnTop=false.
--
-- GROUNDING (pelajaran playtest v2, dikoreksi di v3.0): build()
-- menerima TITIK BADAN. Kaki berpusat di body - 1.3*s dengan tinggi
-- 0.6*s, jadi dasar kaki = body - 1.6*s. Rumus lama (ground + 1.3*s)
-- salah: dasar kaki = ground - 0.3*s, kaki tenggelam 0.6-0.9 stud dan
-- cincin (pusat body - 1.7*s) terkubur total 1.05-1.58 stud.
-- Rumus benar: badan harus 1.6*s di atas tanah supaya dasar kaki
-- tepat menapak. Cincin dipindah ke body - 1.5*s supaya dasarnya
-- ~ di permukaan tanah, bukan terkubur.

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local BrainrotFactory = {}

local function part(parent, name, size, pos, color, shape, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Position = pos
	p.Color = color
	p.Anchored = true
	p.CanCollide = false
	if shape == "ball" then
		p.Shape = Enum.PartType.Ball
	elseif shape == "cylinder" then
		p.Shape = Enum.PartType.Cylinder
	else
		p.Shape = Enum.PartType.Block
	end
	p.Material = material or Enum.Material.SmoothPlastic
	p.Parent = parent
	return p
end

-- Aksesori dibuat relatif terhadap origin (0,0,0), lalu build()
-- menggeser semuanya ke `position`. Ukuran dikali `s` (skala rarity).
local function addAccessory(model, kind, s)
	local function ap(name, size, pos, color)
		return part(model, name, size * s, pos * s, color)
	end
	if kind == "banana" then
		local b1 = ap("Accessory1", Vector3.new(0.5, 1.6, 0.5), Vector3.new(1.4, 1.2, 0), Color3.fromRGB(255, 220, 60))
		b1.Orientation = Vector3.new(0, 0, -25)
		ap("Accessory2", Vector3.new(0.5, 1.2, 0.5), Vector3.new(-1.4, 1.2, 0), Color3.fromRGB(255, 220, 60))
	elseif kind == "log" then
		ap("Accessory1", Vector3.new(2.6, 0.7, 0.7), Vector3.new(0, 2.6, 0), Color3.fromRGB(160, 110, 60))
	elseif kind == "cactus" then
		ap("Accessory1", Vector3.new(0.7, 1.8, 0.7), Vector3.new(0, 1.6, -1.1), Color3.fromRGB(50, 180, 80))
	elseif kind == "sharkfin" then
		local fin = ap("Accessory1", Vector3.new(0.4, 1.6, 1.4), Vector3.new(0, 2.4, -0.4), Color3.fromRGB(70, 120, 220))
		fin.Orientation = Vector3.new(-20, 0, 0)
	elseif kind == "cup" then
		ap("Accessory1", Vector3.new(1, 1, 1), Vector3.new(1.3, 2.2, 0), Color3.fromRGB(255, 255, 255))
		ap("Accessory2", Vector3.new(2.2, 0.4, 0.4), Vector3.new(0, 1.2, 1.2), Color3.fromRGB(200, 200, 210))
	elseif kind == "tutu" then
		ap("Accessory1", Vector3.new(3.2, 0.4, 3.2), Vector3.new(0, 0.4, 0), Color3.fromRGB(255, 190, 220))
		ap("Accessory2", Vector3.new(1.2, 0.8, 1.2), Vector3.new(0, 3.4, 0), Color3.fromRGB(255, 215, 0))
	elseif kind == "plane" then
		ap("Accessory1", Vector3.new(3.4, 0.3, 1.2), Vector3.new(0, 1.8, 0), Color3.fromRGB(220, 220, 230))
		ap("Accessory2", Vector3.new(0.8, 0.8, 0.8), Vector3.new(0, 0.6, 1.6), Color3.fromRGB(40, 40, 40))
	elseif kind == "nose" then
		ap("Accessory1", Vector3.new(0.6, 0.6, 2.2), Vector3.new(0, 2.2, 1.6), Color3.fromRGB(220, 170, 140))
	elseif kind == "crown" then
		ap("Accessory1", Vector3.new(1.8, 0.9, 1.8), Vector3.new(0, 3.5, 0), Color3.fromRGB(255, 215, 0))
		ap("Accessory2", Vector3.new(0.5, 0.7, 0.5), Vector3.new(-0.6, 4.1, 0), Color3.fromRGB(255, 80, 80))
		ap("Accessory3", Vector3.new(0.5, 0.7, 0.5), Vector3.new(0.6, 4.1, 0), Color3.fromRGB(80, 180, 255))
	end
end

-- Skala total model: RarityScale * 2.0.
function BrainrotFactory.scaleFor(def)
	return (Config.RarityScale[def.Rarity] or 1) * 2.0
end

-- Ubah titik TANAH (slot base / altar / conveyor) menjadi titik badan.
-- Verifikasi: dasar kaki = bodyCenter - 1.6*s = ground (tepat menapak).
function BrainrotFactory.bodyCenter(groundPos, def)
	local s = BrainrotFactory.scaleFor(def)
	return groundPos + Vector3.new(0, 1.6 * s, 0)
end

-- Pindah model brainrot ke titik badan baru TANPA PivotTo (v3.2).
-- PivotTo memakai pusat bounding-box model sebagai pivot, bukan Body:
-- bbox membentang dari atas kepala ~+2.7*s sampai dasar cincin ~-1.6*s,
-- jadi pusatnya ~+0.55*s di atas badan — setiap PivotTo menggeser
-- seluruh model KE BAWAH ~0.55*s dan mengubur kaki + cincin, padahal
-- bodyCenter() sudah benar. TranslateBy menggeser semua part dengan
-- vektor yang sama dan tidak punya ambiguitas pivot, jadi ini satu-satunya
-- cara memindah model brainrot. JANGAN pakai PivotTo / MoveTo /
-- SetPrimaryPartCFrame untuk model brainrot di mana pun.
function BrainrotFactory.moveTo(model, bodyCenterPos)
	local pp = model and model.PrimaryPart
	if pp then
		model:TranslateBy(bodyCenterPos - pp.Position)
	end
end

function BrainrotFactory.build(def, mutation, position, fused)
	local s = BrainrotFactory.scaleFor(def)
	local rarityColor = Config.Rarities[def.Rarity] or Color3.fromRGB(255, 255, 255)
	local model = Instance.new("Model")
	model.Name = def.Name

	-- Badan: sumbu silinder Roblox berjalan di X, jadi badan silinder
	-- dibuat memanjang di X lalu diputar 90 derajat di Z agar tegak.
	local bodySize = Vector3.new(2.4 * s, 2.2 * s, 1.6 * s)
	if def.Shape == "cylinder" then
		bodySize = Vector3.new(2.2 * s, 2.4 * s, 2.4 * s)
	end
	local body = part(model, "Body", bodySize, position, def.Body, def.Shape)
	if def.Shape == "cylinder" then
		body.Orientation = Vector3.new(0, 0, 90)
	end
	-- Mutation Diamond: badan Neon transparan. Golden: Neon lembut.
	if mutation.Name == "Diamond" then
		body.Material = Enum.Material.Neon
		body.Transparency = 0.15
	elseif mutation.Name == "Golden" then
		body.Material = Enum.Material.Neon
		body.Transparency = 0.05
	end

	local headSize = Vector3.new(1.8 * s, 1.6 * s, 1.6 * s)
	if def.Shape == "cylinder" then
		headSize = Vector3.new(1.6 * s, 1.8 * s, 1.8 * s)
	end
	local head = part(model, "Head", headSize, position + Vector3.new(0, 1.9 * s, 0), def.Head, def.Shape)
	if def.Shape == "cylinder" then
		head.Orientation = Vector3.new(0, 0, 90)
	end
	-- Mata menghadap +Z (arah kamera dari spawn).
	part(model, "EyeL", Vector3.new(0.35 * s, 0.5 * s, 0.2), position + Vector3.new(-0.45 * s, 2.1 * s, 0.85 * s), Color3.fromRGB(20, 20, 20))
	part(model, "EyeR", Vector3.new(0.35 * s, 0.5 * s, 0.2), position + Vector3.new(0.45 * s, 2.1 * s, 0.85 * s), Color3.fromRGB(20, 20, 20))
	-- Kaki.
	part(model, "FootL", Vector3.new(0.8 * s, 0.6 * s, 1), position + Vector3.new(-0.6 * s, -1.3 * s, 0), Color3.fromRGB(60, 60, 60))
	part(model, "FootR", Vector3.new(0.8 * s, 0.6 * s, 1), position + Vector3.new(0.6 * s, -1.3 * s, 0), Color3.fromRGB(60, 60, 60))

	addAccessory(model, def.Accessory, s)
	-- Geser aksesori (yang dibuat relatif terhadap origin) ke position.
	for _, child in ipairs(model:GetChildren()) do
		if string.sub(child.Name, 1, 9) == "Accessory" then
			child.Position = child.Position + position
		end
	end

	-- Cincin rarity di bawah model (Neon, warna rarity). Pusat di
	-- body - 1.5*s: dasar cincin = ground + 0.1*s - 0.125, jadi
	-- ~ di permukaan tanah (tidak terkubur seperti di -1.7*s).
	local ring = part(model, "RarityRing", Vector3.new(0.25, 3.4 * s, 3.4 * s),
		position + Vector3.new(0, -1.5 * s, 0), rarityColor, "cylinder", Enum.Material.Neon)
	ring.Orientation = Vector3.new(0, 0, 90)

	-- Efek mutation: Golden = trim emas di kepala; Rainbow = 3 orb warna.
	if mutation.Name == "Golden" then
		part(model, "GoldTrim", Vector3.new(2.0 * s, 0.3, 1.8 * s),
			position + Vector3.new(0, 2.9 * s, 0), Color3.fromRGB(255, 215, 0), "box", Enum.Material.Neon)
	elseif mutation.Name == "Rainbow" then
		local orbColors = { Color3.fromRGB(255, 80, 80), Color3.fromRGB(80, 220, 120), Color3.fromRGB(90, 140, 255) }
		for i, c in ipairs(orbColors) do
			local angle = (i - 1) * (2 * math.pi / 3)
			part(model, "RainbowOrb" .. i, Vector3.new(0.6, 0.6, 0.6),
				position + Vector3.new(math.cos(angle) * 1.8 * s, 3.2 * s, math.sin(angle) * 1.8 * s),
				c, "ball", Enum.Material.Neon)
		end
	end

	-- FUSED: mahkota emas besar di atas kepala (hasil Fusion Altar).
	if fused then
		part(model, "FusedCrown", Vector3.new(2.2 * s, 1.0 * s, 2.2 * s),
			position + Vector3.new(0, 3.6 * s, 0), Color3.fromRGB(255, 215, 0), "box", Enum.Material.Neon)
	end

	-- Mythic: partikel emas halus di badan (rate kecil, satu emitter saja).
	if def.Rarity == "Mythic" then
		local emitter = Instance.new("ParticleEmitter")
		emitter.Name = "MythicSparkle"
		emitter.Color = ColorSequence.new(Color3.fromRGB(255, 215, 0))
		emitter.Rate = 4
		emitter.Lifetime = NumberRange.new(0.8, 1.2)
		emitter.Speed = NumberRange.new(1, 2)
		emitter.Size = NumberSequence.new(0.3)
		emitter.Parent = body
	end
	_ = head

	-- Label nama/rarity/income/harga. Offset 2.8*s supaya label duduk di
	-- atas kepala model 2.0x (offset 4.5 akan menembus kepala).
	local gui = Instance.new("BillboardGui")
	gui.Name = "Label"
	gui.Size = UDim2.fromOffset(120, 40)
	gui.StudsOffset = Vector3.new(0, 2.8 * s, 0)
	gui.AlwaysOnTop = false
	gui.MaxDistance = 50
	local text = Instance.new("TextLabel")
	text.Name = "Text"
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 0.6
	text.BackgroundColor3 = Color3.fromRGB(20, 20, 40)
	text.TextColor3 = mutation.Color
	text.TextStrokeTransparency = 0.2
	text.TextScaled = true
	text.Font = Enum.Font.SourceSansBold
	text.Text = def.Name
	text.Parent = gui
	gui.Parent = body

	local click = Instance.new("ClickDetector")
	click.Name = "BuyClick"
	click.MaxActivationDistance = 32
	click.Parent = body

	model.PrimaryPart = body
	-- v3.2: JANGAN PivotTo di sini. Semua part sudah diposisikan absolut
	-- di atas; PivotTo memakai pusat bounding-box (~+0.55*s di atas
	-- badan) sebagai pivot dan akan menggeser model ke bawah ~0.55*s,
	-- mengubur kaki + cincin. Lihat BrainrotFactory.moveTo().
	return model
end

-- Isi ulang teks label (setelah dibeli / di-fusion / dicuri):
-- "Nama\nMutation Rarity | $X/s" + "BELI: $Y" kalau masih di conveyor.
function BrainrotFactory.setLabel(model, def, mutation, priceOrNil, fused)
	local body = model:FindFirstChild("Body")
	if not body then
		return
	end
	local gui = body:FindFirstChild("Label")
	if not gui then
		return
	end
	local text = gui:FindFirstChild("Text")
	if not text then
		return
	end
	local income = def.Income * mutation.Mult
	local name = def.Name
	if fused then
		name = "FUSED " .. name
	end
	local line = string.format(
		"%s\n%s %s | %s/s",
		name,
		mutation.Name,
		def.Rarity,
		Config.formatMoney(income)
	)
	if priceOrNil then
		line ..= string.format("\nBELI: %s", Config.formatMoney(priceOrNil))
	end
	text.Text = line
	text.TextColor3 = mutation.Color
end

return BrainrotFactory
