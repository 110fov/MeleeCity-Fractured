if SERVER then return end

CRIMXP = CRIMXP or {}
CRIMXP.Unlocks = CRIMXP.Unlocks or {}
CRIMXP.UnlocksReady = false

local NET_UNLOCK_SYNC = "HG_CrimXPUnlockSync"
local NET_PURCHASE = "HG_CrimXPPurchase"
local NET_PURCHASE_RESULT = "HG_CrimXPPurchaseResult"

function CRIMXP.IsUnlocked(id)
	local entry = CRIMXP.GetUnlockEntry(id)
	if entry and entry.free then return true end
	return CRIMXP.Unlocks[id] == true
end

function CRIMXP.GetUnlockPrice(id)
	local entry = CRIMXP.GetUnlockEntry(id)
	return entry and math.floor(tonumber(entry.price) or 0) or 0
end

function CRIMXP.RequestPurchase(id, early)
	if not isstring(id) or id == "" then return end

	net.Start(NET_PURCHASE)
		net.WriteString(id)
		net.WriteBool(early == true)
	net.SendToServer()
end

net.Receive(NET_UNLOCK_SYNC, function()
	local owned = net.ReadTable()
	CRIMXP.Unlocks = {}

	if istable(owned) then
		for id, value in pairs(owned) do
			if value then CRIMXP.Unlocks[id] = true end
		end
	end

	CRIMXP.UnlocksReady = true
	hook.Run("HG_CrimXPUnlocksUpdated")
end)

net.Receive(NET_PURCHASE_RESULT, function()
	local ok = net.ReadBool()
	local id = net.ReadString()
	local message = net.ReadString()
	net.ReadUInt(32)

	if ok then
		CRIMXP.Unlocks[id] = true
		CRIMXP.UnlocksReady = true
	end

	if message ~= "" then
		chat.AddText(ok and Color(100, 255, 100) or Color(255, 120, 120), "[XP] ", color_white, message)
	end

	hook.Run("HG_CrimXPUnlocksUpdated", id, ok)
end)
