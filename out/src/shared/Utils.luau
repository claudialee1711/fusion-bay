-- Fusion Bay v3.0 — util kecil yang dipakai server (dan client bila perlu).

local Utils = {}

function Utils.clamp(v, lo, hi)
	if v < lo then
		return lo
	elseif v > hi then
		return hi
	end
	return v
end

-- HumanoidRootPart pemain, nil kalau karakter belum siap.
function Utils.getRoot(player)
	local char = player.Character
	if not char then
		return nil
	end
	return char:FindFirstChild("HumanoidRootPart")
end

function Utils.getHumanoid(player)
	local char = player.Character
	if not char then
		return nil
	end
	return char:FindFirstChildOfClass("Humanoid")
end

-- Apakah posisi `pos` berada di dalam kotak base (tengah `center`,
-- setengah lebar hx, setengah dalam hz)?
function Utils.insideBase(pos, center, hx, hz)
	return math.abs(pos.X - center.X) < hx and math.abs(pos.Z - center.Z) < hz
end

return Utils
