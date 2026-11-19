-- Fusion Bay v3.0 — daftar 10 karakter brainrot original.
-- Shape: "box" (kotak), "ball" (bola), "cylinder" (silinder tegak).
-- Accessory adalah kata kunci yang dibaca BrainrotFactory untuk
-- membangun aksesori 3D dari Part (tanpa aset eksternal).

local BrainrotDefs = {}

BrainrotDefs.List = {
	{
		Id = "pisang-kucing",
		Shape = "ball",
		Name = "Pisang Kucing Melayang",
		Rarity = "Common",
		Income = 5,
		Price = 100,
		Body = Color3.fromRGB(255, 220, 80),
		Head = Color3.fromRGB(255, 235, 150),
		Accessory = "banana",
	},
	{
		Id = "kayu-sahur",
		Shape = "box",
		Name = "Kayu Ketuk Sahur",
		Rarity = "Common",
		Income = 8,
		Price = 250,
		Body = Color3.fromRGB(150, 100, 55),
		Head = Color3.fromRGB(120, 80, 40),
		Accessory = "log",
	},
	{
		Id = "monyet-disco",
		Shape = "ball",
		Name = "Monyet Pisang Disco",
		Rarity = "Rare",
		Income = 15,
		Price = 600,
		Body = Color3.fromRGB(110, 75, 45),
		Head = Color3.fromRGB(180, 140, 100),
		Accessory = "banana",
	},
	{
		Id = "kaktus-menari",
		Shape = "cylinder",
		Name = "Kaktus Gurun Menari",
		Rarity = "Rare",
		Income = 25,
		Price = 1200,
		Body = Color3.fromRGB(240, 200, 170),
		Head = Color3.fromRGB(255, 220, 190),
		Accessory = "cactus",
	},
	{
		Id = "hiu-bernyanyi",
		Shape = "ball",
		Name = "Hiu Biru Bernyanyi",
		Rarity = "Epic",
		Income = 45,
		Price = 2500,
		-- v3.4: badan dulu (90,140,255) nyaris sama dengan base biru
		-- (90,160,255) — digelapkan jadi biru navy supaya terbaca.
		Body = Color3.fromRGB(30, 70, 190),
		Head = Color3.fromRGB(140, 180, 255),
		Accessory = "sharkfin",
	},
	{
		Id = "kopi-pedang",
		Shape = "cylinder",
		Name = "Kopi Hitam Berpedang",
		Rarity = "Epic",
		Income = 70,
		Price = 4500,
		Body = Color3.fromRGB(120, 70, 30),
		Head = Color3.fromRGB(240, 220, 200),
		Accessory = "cup",
	},
	{
		Id = "balerina-kopi",
		Shape = "cylinder",
		Name = "Balerina Kopi Berputar",
		Rarity = "Legendary",
		Income = 110,
		Price = 8000,
		Body = Color3.fromRGB(255, 180, 210),
		Head = Color3.fromRGB(255, 220, 230),
		Accessory = "tutu",
	},
	{
		Id = "buaya-pesawat",
		Shape = "box",
		Name = "Buaya Pesawat Terbang",
		Rarity = "Legendary",
		Income = 160,
		Price = 12000,
		-- v3.4: badan dulu hijau (60,140,70) — hilang di rumput hijau
		-- (80,220,90). Diganti teal gelap supaya kontras dengan rumput.
		Body = Color3.fromRGB(30, 140, 150),
		Head = Color3.fromRGB(60, 180, 180),
		Accessory = "plane",
	},
	{
		Id = "hidung-bersin",
		Shape = "ball",
		Name = "Hidung Panjang Bersin",
		Rarity = "Mythic",
		Income = 250,
		Price = 20000,
		Body = Color3.fromRGB(140, 190, 220),
		Head = Color3.fromRGB(200, 230, 255),
		Accessory = "nose",
	},
	{
		Id = "raja-kombinasi",
		Shape = "box",
		Name = "Raja Kombinasi Emas",
		Rarity = "Mythic",
		Income = 400,
		Price = 35000,
		Body = Color3.fromRGB(255, 200, 60),
		Head = Color3.fromRGB(255, 230, 120),
		Accessory = "crown",
	},
}

BrainrotDefs.ById = {}
for _, def in ipairs(BrainrotDefs.List) do
	BrainrotDefs.ById[def.Id] = def
end

-- Roll karakter untuk spawn di conveyor. Bobot total 100:
-- Common 55, Rare 25, Epic 12, Legendary 6, Mythic 2.
function BrainrotDefs.rollDef()
	local weights = { 27, 28, 12, 13, 6, 6, 3, 3, 1, 1 }
	local total = 0
	for _, w in ipairs(weights) do
		total += w
	end
	local r = math.random(total)
	local acc = 0
	for i, w in ipairs(weights) do
		acc += w
		if r <= acc then
			return BrainrotDefs.List[i]
		end
	end
	return BrainrotDefs.List[1]
end

-- Semua def yang rarity-nya sama dengan `rarity` (untuk hasil fusion).
function BrainrotDefs.ofRarity(rarity)
	local out = {}
	for _, def in ipairs(BrainrotDefs.List) do
		if def.Rarity == rarity then
			table.insert(out, def)
		end
	end
	return out
end

return BrainrotDefs
