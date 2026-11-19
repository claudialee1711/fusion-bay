-- Fusion Bay v3.0 — steal + slap.
-- Ambil brainrot dari base pemain lain dengan mendekatinya, bawa pulang
-- (diperlambat, terlihat), dan jatuhkan dengan slap. Semua dicek server
-- tiap Heartbeat: jarak, base terkunci, proteksi spawn, cooldown.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local Utils = require(game:GetService("ReplicatedStorage").Shared.Utils)
local DataSystem = require(script.Parent.DataSystem)
local State = require(script.Parent.State)
local Remotes = require(script.Parent.Remotes)
local BrainrotFactory = require(script.Parent.BrainrotFactory)

local StealSystem = {}

local lastSlap = {}
local lastSteal = {} -- [player] = os.clock() steal terakhir yang berhasil
local lastStealVictim = {} -- [player] = {Victim=player, At=os.clock()}
local joinTime = {} -- [player] = os.clock() saat masuk (proteksi spawn)

local function restoreSpeed(player)
	local data = DataSystem.get(player)
	local hum = Utils.getHumanoid(player)
	if hum then
		if data and data.Items.boots then
			hum.WalkSpeed = Config.BootsWalkSpeed
		else
			hum.WalkSpeed = Config.NormalWalkSpeed
		end
	end
end

function StealSystem.noteJoin(player)
	joinTime[player] = os.clock()
end

-- Penanda visual di atas kepala pembawa curian: pemain lain bisa
-- melihat dan mengejar. Dibuat saat pickup, dihapus saat drop/deliver.
local function setCarryMarker(player, on)
	local char = player.Character
	if not char then
		return
	end
	local head = char:FindFirstChild("Head")
	if not head then
		return
	end
	local old = head:FindFirstChild("CarryMarker")
	if old then
		old:Destroy()
	end
	if not on then
		return
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = "CarryMarker"
	gui.Size = UDim2.fromOffset(220, 36)
	gui.StudsOffset = Vector3.new(0, 3.5, 0)
	gui.AlwaysOnTop = true
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 0.3
	label.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
	label.Text = "MEMBAWA CURIAN!"
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextScaled = true
	label.Font = Enum.Font.SourceSansBold
	label.Parent = gui
	gui.Parent = head
end

-- Jatuhkan brainrot yang sedang dibawa; kembali ke slot base pemilik asal.
function StealSystem.dropCarried(player, returnToOwner)
	local rec = State.Carrying[player]
	if not rec then
		return
	end
	State.Carrying[player] = nil
	setCarryMarker(player, false)
	restoreSpeed(player)
	local base = nil
	for _, b in ipairs(State.Bases) do
		if b.Index == rec.BaseIndex then
			base = b
			break
		end
	end
	rec.State = "owned"
	if base and rec.SlotIndex then
		rec.Model:PivotTo(CFrame.new(BrainrotFactory.bodyCenter(base.Slots[rec.SlotIndex], rec.Def)))
	end
	if returnToOwner and rec.Owner then
		Remotes.notify(rec.Owner, "Brainrotmu kembali ke base!")
	end
end

-- Coba ambil brainrot milik orang lain yang sedang didekati.
local function tryPickup(player)
	if State.Carrying[player] then
		return
	end
	local now = os.clock()
	-- Fair steal: cooldown 20 detik antar steal.
	if lastSteal[player] and now - lastSteal[player] < Config.StealCooldownSeconds then
		return
	end
	local root = Utils.getRoot(player)
	if not root then
		return
	end
	for _, rec in ipairs(State.Active) do
		if rec.State == "owned" and rec.Owner ~= player and rec.Model and rec.Model.Parent then
			local body = rec.Model:FindFirstChild("Body")
			if body then
				local base = nil
				for _, b in ipairs(State.Bases) do
					if b.Index == rec.BaseIndex then
						base = b
						break
					end
				end
				if base and not State.isLocked(base) then
					-- Proteksi spawn: base pemain yang baru masuk 60 detik
					-- tidak bisa dicuri.
					local victimJoin = joinTime[rec.Owner] or 0
					if now - victimJoin < Config.SpawnProtectionSeconds then
						Remotes.notify(player, "Base itu masih dilindungi (pemain baru)!")
						return
					end
					-- Tidak boleh curi 2x berturut-turut dari korban yang sama.
					local last = lastStealVictim[player]
					if last and last.Victim == rec.Owner and now - last.At < Config.StealSameVictimSeconds then
						Remotes.notify(player, "Tunggu dulu sebelum mencuri dari pemain yang sama!")
						return
					end
					if (root.Position - body.Position).Magnitude < Config.PickupDistance then
						rec.State = "carried"
						State.Carrying[player] = rec
						lastSteal[player] = now
						lastStealVictim[player] = { Victim = rec.Owner, At = now }
						setCarryMarker(player, true)
						local hum = Utils.getHumanoid(player)
						if hum then
							hum.WalkSpeed = Config.CarryWalkSpeed
						end
						Remotes.notify(player, "Kamu mencuri " .. rec.Def.Name .. "! Lari pulang!")
						if rec.Owner then
							Remotes.notify(rec.Owner, player.Name .. " mencuri " .. rec.Def.Name .. " dari basemu! Slap dia!")
						end
						return
					end
				end
			end
		end
	end
end

-- Coba serahkan curian di base sendiri: kepemilikan pindah ke pencuri.
local function tryDeliver(player)
	local rec = State.Carrying[player]
	if not rec then
		return
	end
	local root = Utils.getRoot(player)
	if not root then
		return
	end
	local myBase = State.baseForPlayer(player)
	if not myBase then
		return
	end
	if not Utils.insideBase(root.Position, myBase.Center, 15, 12) then
		return
	end
	local slot = State.freeSlot(myBase)
	if not slot then
		Remotes.notify(player, "Base penuh! Brainrot curian jatuh.")
		StealSystem.dropCarried(player, true)
		return
	end
	local oldOwner = rec.Owner
	if oldOwner then
		DataSystem.removeOwned(oldOwner, rec.Def.Id, rec.Mutation.Name)
	end
	DataSystem.addOwned(player, rec.Def.Id, rec.Mutation.Name, rec.Fused or false)
	local data = DataSystem.get(player)
	if data then
		data.Steals += 1
	end
	rec.State = "owned"
	rec.Owner = player
	rec.BaseIndex = myBase.Index
	rec.SlotIndex = slot
	State.Carrying[player] = nil
	setCarryMarker(player, false)
	restoreSpeed(player)
	rec.Model:PivotTo(CFrame.new(BrainrotFactory.bodyCenter(myBase.Slots[slot], rec.Def)))
	BrainrotFactory.setLabel(rec.Model, rec.Def, rec.Mutation, nil, rec.Fused or false)
	Remotes.notify(player, "Berhasil mencuri " .. rec.Def.Name .. "!")
	if oldOwner then
		Remotes.notify(oldOwner, player.Name .. " berhasil mencuri " .. rec.Def.Name .. "!")
		-- Fair steal: base korban terkunci otomatis 30 detik.
		for _, b in ipairs(State.Bases) do
			if b.Owner == oldOwner then
				b.LockUntil = os.clock() + Config.AutoLockAfterStealSeconds
				break
			end
		end
	end
end

-- Slap: cooldown 2 detik, jarak < 10 stud, knockback + jatuhkan bawaan.
local function doSlap(player)
	local now = os.clock()
	if lastSlap[player] and now - lastSlap[player] < Config.SlapCooldownSeconds then
		return
	end
	lastSlap[player] = now
	local root = Utils.getRoot(player)
	if not root then
		return
	end
	for _, other in ipairs(Players:GetPlayers()) do
		if other ~= player then
			local otherRoot = Utils.getRoot(other)
			if otherRoot and (root.Position - otherRoot.Position).Magnitude < Config.SlapRange then
				local dir = (otherRoot.Position - root.Position).Unit
				otherRoot.AssemblyLinearVelocity = dir * Config.SlapKnockback + Vector3.new(0, 25, 0)
				if State.Carrying[other] then
					StealSystem.dropCarried(other, true)
					Remotes.notify(player, "Kamu menjatuhkan curian " .. other.Name .. "!")
					Remotes.notify(other, "Kamu di-slap! Curianmu jatuh!")
				end
			end
		end
	end
end

function StealSystem.start()
	Remotes.SlapEvent.OnServerEvent:Connect(function(player)
		doSlap(player)
	end)

	-- Tiap frame: brainrot curian melayang di atas kepala pembawa,
	-- lalu coba pickup dan deliver.
	RunService.Heartbeat:Connect(function()
		for _, player in ipairs(Players:GetPlayers()) do
			local rec = State.Carrying[player]
			if rec and rec.Model and rec.Model.Parent then
				local root = Utils.getRoot(player)
				if root then
					rec.Model:PivotTo(CFrame.new(root.Position + Vector3.new(0, 5, 0)))
				end
			end
			tryPickup(player)
			tryDeliver(player)
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		if State.Carrying[player] then
			StealSystem.dropCarried(player, true)
		end
		lastSlap[player] = nil
		lastSteal[player] = nil
		lastStealVictim[player] = nil
		joinTime[player] = nil
	end)
end

-- Tool Slap: dibuat saat pemain masuk. Aktivasi tool ditangani client
-- (Game.client.luau): saat tool diaktifkan, client kirim SlapEvent.
function StealSystem.giveSlapTool(player)
	local backpack = player:FindFirstChild("Backpack")
	if not backpack then
		return
	end
	if backpack:FindFirstChild("Slap") then
		return
	end
	local tool = Instance.new("Tool")
	tool.Name = "Slap"
	tool.RequiresHandle = true
	tool.CanBeDropped = false
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(1, 0.5, 3)
	handle.Color = Color3.fromRGB(255, 120, 120)
	handle.Parent = tool
	tool.Parent = backpack
end

return StealSystem
