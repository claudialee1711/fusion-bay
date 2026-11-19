-- Fusion Bay v3.0 — conveyor spawn. Brainrot berjalan dari x=-90 ke
-- x=+90 di z=30, bisa dibeli dengan klik (ClickDetector; validasi beli
-- ada di server, di EconomySystem).

local RunService = game:GetService("RunService")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local BrainrotDefs = require(game:GetService("ReplicatedStorage").Shared.BrainrotDefs)
local BrainrotFactory = require(script.Parent.BrainrotFactory)
local State = require(script.Parent.State)

local Spawner = {}

local START_X = -90
local END_X = 90
local LANE_Z = 30
local LANE_GROUND_Y = 1.6 -- atas conveyor (v3.3: conveyor naik +1.0); titik badan = 1.6 + 1.6*skala

function Spawner.clearConveyor()
	for i = #State.Active, 1, -1 do
		local rec = State.Active[i]
		if rec.State == "walking" then
			if rec.Model then
				rec.Model:Destroy()
			end
			table.remove(State.Active, i)
		end
	end
end

function Spawner.spawnOne(lucky, startX)
	local def = BrainrotDefs.rollDef()
	local mutation = Config.rollMutation(lucky or false)
	local x0 = startX or START_X
	-- Titik badan = tanah conveyor + 1.6*skala (v3.0, koreksi dari 1.3:
	-- dasar kaki = body - 1.6*s harus tepat = tanah), supaya kaki
	-- menapak di atas conveyor (bukan terbenam / melayang).
	-- v3.2: Heartbeat menggerakkan model lewat TranslateBy, bukan PivotTo.
	local bodyY = LANE_GROUND_Y + 1.6 * BrainrotFactory.scaleFor(def)
	local model = BrainrotFactory.build(def, mutation, Vector3.new(x0, bodyY, LANE_Z))
	model.Parent = game:GetService("Workspace")
	BrainrotFactory.setLabel(model, def, mutation, def.Price)

	local rec = {
		Id = State.NextBrainrotId,
		Model = model,
		Def = def,
		Mutation = mutation,
		State = "walking",
		Owner = nil,
		BaseIndex = nil,
		SlotIndex = nil,
		Price = def.Price,
		X = x0,
		BodyY = bodyY,
	}
	State.NextBrainrotId += 1
	table.insert(State.Active, rec)

	-- Klik untuk beli: server yang memvalidasi (lihat EconomySystem).
	local body = model:FindFirstChild("Body")
	local click = body and body:FindFirstChild("BuyClick")
	if click then
		click.MouseClick:Connect(function(player)
			local Economy = require(script.Parent.EconomySystem)
			Economy.buyBrainrot(player, rec)
		end)
	end
	return rec
end

-- Gerakkan brainrot yang sedang berjalan di conveyor.
function Spawner.start()
	-- Screenshot pertama langsung ramai: 8 brainrot tersebar di conveyor
	-- baru (z=30) saat server mulai, bukan menunggu spawn satu per satu.
	for _, x in ipairs({ -70, -50, -30, -10, 10, 30, 50, 70 }) do
		Spawner.spawnOne(false, x)
	end
	print("[FusionBay] CONVEYOR v2: 8 brainrot di z=30, x=-70..70")

	task.spawn(function()
		while true do
			task.wait(Config.SpawnIntervalSeconds)
			local walking = 0
			for _, rec in ipairs(State.Active) do
				if rec.State == "walking" then
					walking += 1
				end
			end
			if walking < Config.MaxOnConveyor then
				Spawner.spawnOne(false)
			end
		end
	end)

	RunService.Heartbeat:Connect(function(dt)
		local t = os.clock()
		for i = #State.Active, 1, -1 do
			local rec = State.Active[i]
			if rec.State == "walking" and rec.Model and rec.Model.Parent then
				rec.X += Config.ConveyorSpeed * dt
				-- Bobbing: karakter bergerak hidup (naik-turun kecil) supaya
				-- conveyor terlihat ramai, bukan patung yang meluncur.
				-- v3.2: TranslateBy dengan delta per frame (bukan PivotTo,
				-- yang menggeser model ke bawah ~0.55*s tiap frame).
				-- Delta dihitung dari posisi Body saat ini, jadi model
				-- tidak akan drift walau bobY berubah tiap frame.
				local bobY = (rec.BodyY or LANE_GROUND_Y + 2.6) + math.sin(t * 3 + rec.Id * 1.7) * 0.25
				local target = Vector3.new(rec.X, bobY, LANE_Z)
				local pp = rec.Model.PrimaryPart
				if pp then
					rec.Model:TranslateBy(target - pp.Position)
				end
				if rec.X >= END_X then
					rec.Model:Destroy()
					table.remove(State.Active, i)
				end
			end
		end
	end)
end

return Spawner
