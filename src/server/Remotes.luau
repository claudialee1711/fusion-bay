-- Fusion Bay v3.0 — semua Remote dibuat di sini (server saja).
-- Modul lain me-require modul ini; tidak ada circular require karena
-- modul ini tidak me-require sistem lain.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = {}

local folder = ReplicatedStorage:FindFirstChild("Remotes")
if not folder then
	folder = Instance.new("Folder")
	folder.Name = "Remotes"
	folder.Parent = ReplicatedStorage
end

local events = folder:FindFirstChild("RemoteEvents")
if not events then
	events = Instance.new("Folder")
	events.Name = "RemoteEvents"
	events.Parent = folder
end

local functions = folder:FindFirstChild("RemoteFunctions")
if not functions then
	functions = Instance.new("Folder")
	functions.Name = "RemoteFunctions"
	functions.Parent = folder
end

local function getEvent(name)
	local e = events:FindFirstChild(name)
	if not e then
		e = Instance.new("RemoteEvent")
		e.Name = name
		e.Parent = events
	end
	return e
end

local function getFunction(name)
	local f = functions:FindFirstChild(name)
	if not f then
		f = Instance.new("RemoteFunction")
		f.Name = name
		f.Parent = functions
	end
	return f
end

Remotes.SlapEvent = getEvent("SlapEvent")
Remotes.BuyItemEvent = getEvent("BuyItemEvent")
Remotes.RebirthEvent = getEvent("RebirthEvent")
Remotes.FuseEvent = getEvent("FuseEvent")
Remotes.UpdateUIEvent = getEvent("UpdateUIEvent")
Remotes.NotifyEvent = getEvent("NotifyEvent")
Remotes.WaveEvent = getEvent("WaveEvent")
Remotes.GetPlayerData = getFunction("GetPlayerData")
Remotes.GetLeaderboard = getFunction("GetLeaderboard")
Remotes.MissionEvent = getEvent("MissionEvent")

function Remotes.notify(player, message)
	Remotes.NotifyEvent:FireClient(player, message)
end

function Remotes.notifyAll(message)
	Remotes.NotifyEvent:FireAllClients(message)
end

return Remotes
