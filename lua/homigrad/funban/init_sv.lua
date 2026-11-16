-- Ban/kick show: beep from the head -> head gib -> actual ULX ban/kick.
-- hg_funbantest 1 replaces the head explosion with the Waco Siege sniper shot.
-- The ConVar is server-only, so only admins (server console/rcon) or the
-- admin-gated toggle command below can change it.
if not SERVER then return end

local funbantest = CreateConVar("hg_funbantest", "0", {FCVAR_ARCHIVE, FCVAR_NOTIFY}, "Decapitate banned/kicked players with the Waco Siege sniper shot instead of the normal head explosion.", 0, 1)

local BEEP_SOUND = "beepbeep.mp3"
local SNIPER_SOUND = "mosin/mosin_dist.wav"
local BEEP_LENGTH = 5.05 -- beepbeep.mp3 is ~5 seconds long
local COMPLETE_DELAY = 0.3 -- gib -> ban/kick
local SAFETY_DELAY = 6 -- force the ban/kick if ULX still has not done it

util.PrecacheSound(BEEP_SOUND)
util.PrecacheSound(SNIPER_SOUND)

-- the sound lives in the mounted content addon, only add it to the download list if we actually have it
if file.Exists("sound/" .. BEEP_SOUND, "GAME") then
	resource.AddFile("sound/" .. BEEP_SOUND)
end

local activeBySteamID = {}
local activeByPlayer = {}

local function IsValidPlayer(ply)
	return IsValid(ply) and ply:IsPlayer()
end

local function IsSameTarget(data)
	return IsValidPlayer(data.target) and data.target:SteamID() == data.steamid
end

local function Debug(str)
	print("[hg_funban] " .. tostring(str))
end

local function NotifyCaller(calling, str)
	if IsValidPlayer(calling) and ULib and ULib.tsayError then
		pcall(ULib.tsayError, calling, str, true)
	end
end

local function GetBody(ply)
	if not IsValidPlayer(ply) then return end

	if IsValid(ply.FakeRagdoll) then return ply.FakeRagdoll end
	if IsValid(ply.OldRagdoll) and ply.OldRagdoll:IsRagdoll() then return ply.OldRagdoll end
	if ply:Alive() then return ply end

	local ragdoll = ply:GetNWEntity("RagdollDeath")
	if IsValid(ragdoll) then return ragdoll end

	if IsValid(ply.RagdollDeath) then return ply.RagdollDeath end

	return ply
end

local function GetHeadBone(body)
	if not IsValid(body) then return end
	return body:LookupBone("ValveBiped.Bip01_Head1")
end

local function GetHeadPos(body)
	if not IsValid(body) then return end

	local bone = GetHeadBone(body)
	if bone then
		local matrix = body:GetBoneMatrix(bone)
		if matrix then return matrix:GetTranslation() end

		local pos = body:GetBonePosition(bone)
		if pos then return pos end
	end

	return body:WorldSpaceCenter()
end

local function IsHeadRemoved(body)
	if not IsValid(body) then return true end
	if body.noHead or body.headexploded then return true end

	local gibRemove = body.gibRemove
	local bone = GetHeadBone(body)
	if bone and gibRemove then
		local phys = body:TranslateBoneToPhysBone(bone)
		if phys and gibRemove[phys] then return true end
	end

	return false
end

local function StartHeadBeep(ply)
	local body = GetBody(ply)
	if not IsValid(body) then return end

	local ent = ents.Create("info_target")
	if not IsValid(ent) then return end

	local headPos = GetHeadPos(body)
	ent:SetPos(headPos)
	ent:Spawn()
	ent:SetNoDraw(true)
	ent:SetSolid(SOLID_NONE)
	ent:SetMoveType(MOVETYPE_NONE)

	local attachment = body:LookupAttachment("head")
	if attachment and attachment > 0 then
		ent:SetParent(body, attachment)
	else
		-- ragdolls have no "head" attachment, keep it on the head bone manually
		ent:SetParent(body)
		ent:SetLocalPos(WorldToLocal(headPos, angle_zero, body:GetPos(), body:GetAngles()))
	end

	ent:EmitSound(BEEP_SOUND, 100, 100, 1)

	return ent
end

local function StopHeadBeep(data)
	if IsValid(data.beep) then
		data.beep:StopSound(BEEP_SOUND)
		data.beep:Remove()
	end

	data.beep = nil
end

-- Same shot the Siege mode sniper takes, used when zb.SniperShot is unavailable.
local function FallbackSniperShot(ply)
	local body = GetBody(ply)
	if not IsValid(body) then return false end

	local target = GetHeadPos(body)
	if not target then return false end

	local filter = {body}
	if IsValidPlayer(ply) and ply ~= body then filter[#filter + 1] = ply end

	local src
	for i = 1, 12 do
		local ang = math.Rand(0, math.pi * 2)
		local dist = math.Rand(1200, 2500)
		local test = target + Vector(math.cos(ang) * dist, math.sin(ang) * dist, math.Rand(300, 900))

		local tr = util.TraceLine({start = test, endpos = target, mask = MASK_SHOT, filter = filter})
		if tr.Fraction >= 0.98 then
			src = test
			break
		end
	end

	src = src or target + Angle(0, math.Rand(0, 360), 0):Forward() * 64 + Vector(0, 0, 40)

	local world = game.GetWorld()
	world:FireLuaBullets({
		Attacker = world,
		Inflictor = world,
		Src = src,
		Dir = (target - src):GetNormal(),
		Damage = 180,
		Force = 60,
		Num = 1,
		Spread = vector_origin,
		Tracer = 1,
		AmmoType = ".338 Lapua Magnum",
		Penetration = 32.2,
		Diameter = 8.6,
		penetrated = 0,
		limit_ricochet = 0,
		dmgtype = DMG_BULLET,
		DisableLagComp = true,
		Distance = 8000
	})

	sound.Play(SNIPER_SOUND, src, 120, math.random(95, 105))

	return true
end

local function SniperShot(ply)
	-- reuse the exact Waco Siege shot (sv_criresp.lua), forced to the head
	if zb and isfunction(zb.SniperShot) then
		if pcall(zb.SniperShot, ply, true) then return true end
	end

	local ok, fired = pcall(FallbackSniperShot, ply)
	return ok and fired
end

local function MarkHeadExploded(rag)
	if not IsValid(rag) then return end

	rag.headexploded = true

	local org = rag.organism
	if org then
		org.headamputated = true

		if IsValid(org.owner) then
			org.owner.fullsend = true
		end

		if hg and hg.send_bareinfo then
			pcall(hg.send_bareinfo, org)
		end
	end
end

-- quiet = remove the head without the explosion sound/model
local function GibHeadBody(ply, quiet, attempt, steamid)
	if not IsValidPlayer(ply) then return end
	if steamid and ply:SteamID() ~= steamid then return end

	local rag = GetBody(ply)
	if IsValid(rag) and rag ~= ply and not IsHeadRemoved(rag) then
		local bone = GetHeadBone(rag)
		if bone and isfunction(Gib_Input) then
			pcall(Gib_Input, rag, bone, nil, quiet)
		end

		MarkHeadExploded(rag)
		return
	end

	-- the death ragdoll is not ready yet
	if attempt < 3 then
		timer.Simple(0.1, function()
			GibHeadBody(ply, quiet, attempt + 1, steamid)
		end)
	end
end

local function GibHeadNow(ply, quiet)
	if not IsValidPlayer(ply) then return end

	local steamid = ply:SteamID()
	local body = GetBody(ply)
	if IsValid(body) and IsHeadRemoved(body) then return end

	if not quiet and hg and hg.ExplodeHead then
		pcall(hg.ExplodeHead, ply)
		return
	end

	if ply:Alive() then
		pcall(ply.Kill, ply)
	end

	timer.Simple(0, function()
		GibHeadBody(ply, quiet, 0, steamid)
	end)
end

local function GibHeadSniper(ply)
	if not IsValidPlayer(ply) then return end

	local steamid = ply:SteamID()
	local body = GetBody(ply)
	if IsValid(body) and IsHeadRemoved(body) then return end

	if not SniperShot(ply) then
		-- sniper could not fire, fall back to the regular gib so the head still comes off
		GibHeadNow(ply, false)
		return
	end

	-- the bullet may already have decapitated them, only finish the job if the head is still on
	timer.Simple(0.1, function()
		if IsValidPlayer(ply) and ply:SteamID() == steamid then
			GibHeadNow(ply, true)
		end
	end)
end

local function IsBanned(steamid)
	if not (ULib and ULib.bans) then return false end

	local ban = ULib.bans[steamid]
	if not ban then return false end

	local unban = tonumber(ban.unban)

	return not unban or unban == 0 or unban > os.time()
end

local function ClearActive(data)
	if data.steamid and activeBySteamID[data.steamid] == data then
		activeBySteamID[data.steamid] = nil
	end

	if activeByPlayer[data.target] == data then
		activeByPlayer[data.target] = nil
	end

	StopHeadBeep(data)

	if IsSameTarget(data) then
		pcall(data.target.Freeze, data.target, false)
	end
end

local function ForceBan(data)
	if data.forced then return end
	if not (ULib and ULib.addBan) then return end
	if IsBanned(data.steamid) then return end

	data.forced = true

	local ok, err = pcall(ULib.addBan, data.steamid, data.minutes or 0, data.reason, data.name, data.calling)
	if not ok then Debug("force ban failed: " .. tostring(err)) end
end

local function ForceKick(data)
	if data.forced then return end
	if not (ULib and ULib.kick) then return end
	if not IsSameTarget(data) then return end

	local target = data.target
	if not target:IsConnected() then return end

	data.forced = true

	local ok, err = pcall(ULib.kick, target, data.reason, data.calling)
	if not ok then Debug("force kick failed: " .. tostring(err)) end
end

local function Complete(data)
	if data.completed then return end
	data.completed = true

	StopHeadBeep(data)

	if data.kind == "ban" then
		if data.banid or IsSameTarget(data) then
			local ok, err = pcall(data.doComplete)
			if not ok then
				Debug("original command failed: " .. tostring(err))
				ForceBan(data)
			end
		else
			-- ULX needs the target entity, but they are gone, ban the steamid instead
			ForceBan(data)
		end
	elseif IsSameTarget(data) then
		local ok, err = pcall(data.doComplete)
		if not ok then Debug("original command failed: " .. tostring(err)) end
	end

	ClearActive(data)
end

local function Safety(data)
	if not data.gibbed and IsSameTarget(data) then
		data.gibbed = true

		if funbantest:GetBool() then
			GibHeadSniper(data.target)
		else
			GibHeadNow(data.target, false)
		end
	end

	if data.kind == "ban" then
		ForceBan(data)
	else
		ForceKick(data)
	end

	data.completed = true
	ClearActive(data)
end

local function StartSequence(data)
	activeBySteamID[data.steamid] = data
	if IsValidPlayer(data.target) then activeByPlayer[data.target] = data end

	if IsValidPlayer(data.target) and data.target:Alive() then
		pcall(data.target.Freeze, data.target, true)
	end

	local ok, beep = pcall(StartHeadBeep, data.target)
	data.beep = ok and beep or nil

	timer.Simple(BEEP_LENGTH, function()
		if data.completed then return end

		if not data.gibbed then
			data.gibbed = true

			if IsSameTarget(data) then
				pcall(data.target.Freeze, data.target, false)

				if funbantest:GetBool() then
					GibHeadSniper(data.target)
				else
					GibHeadNow(data.target, false)
				end
			end
		end

		timer.Simple(COMPLETE_DELAY, function()
			if not data.completed then Complete(data) end
		end)
	end)

	timer.Simple(SAFETY_DELAY, function()
		Safety(data)
	end)
end

local function BeginBan(calling, target, minutes, reason, original, banid, steamid)
	if not IsValidPlayer(target) then
		return original(calling, target, minutes, reason)
	end

	if target:IsListenServerHost() or target:IsBot() then
		return original(calling, target, minutes, reason)
	end

	steamid = steamid or target:SteamID()
	if activeBySteamID[steamid] then
		NotifyCaller(calling, "A funban is already in progress for " .. target:Nick() .. ".")
		return
	end

	StartSequence({
		kind = "ban",
		target = target,
		steamid = steamid,
		name = target:Name(),
		calling = calling,
		minutes = minutes,
		reason = reason,
		doComplete = function()
			return original(calling, banid and steamid or target, minutes, reason)
		end
	})
end

local function BeginKick(calling, target, reason, original)
	if not IsValidPlayer(target) then
		return original(calling, target, reason)
	end

	if target:IsListenServerHost() or target:IsBot() then
		return original(calling, target, reason)
	end

	local steamid = target:SteamID()
	if activeBySteamID[steamid] then
		NotifyCaller(calling, "A funban is already in progress for " .. target:Nick() .. ".")
		return
	end

	StartSequence({
		kind = "kick",
		target = target,
		steamid = steamid,
		name = target:Name(),
		calling = calling,
		reason = reason,
		doComplete = function()
			return original(calling, target, reason)
		end
	})
end

local installed = false

local function TryInstall()
	if installed then return true end
	if not (istable(ulx) and ULib and ULib.cmds and ULib.cmds.translatedCmds) then return false end

	local banCmd = ULib.cmds.translatedCmds["ulx ban"]
	local kickCmd = ULib.cmds.translatedCmds["ulx kick"]
	local banidCmd = ULib.cmds.translatedCmds["ulx banid"]

	if not (banCmd and kickCmd) then return false end
	if banCmd.__hg_funban and kickCmd.__hg_funban then
		installed = true
		return true
	end

	if not banCmd.__hg_funban and isfunction(banCmd.fn) then
		local originalBan = banCmd.fn

		banCmd.__hg_funban = true
		banCmd.fn = function(calling, target, minutes, reason)
			return BeginBan(calling, target, minutes, reason, originalBan)
		end
	end

	if not kickCmd.__hg_funban and isfunction(kickCmd.fn) then
		local originalKick = kickCmd.fn

		kickCmd.__hg_funban = true
		kickCmd.fn = function(calling, target, reason)
			return BeginKick(calling, target, reason, originalKick)
		end
	end

	if banidCmd and not banidCmd.__hg_funban and isfunction(banidCmd.fn) then
		local originalBanid = banidCmd.fn

		banidCmd.__hg_funban = true
		banidCmd.fn = function(calling, steamid, minutes, reason)
			local target = isstring(steamid) and player.GetBySteamID(steamid) or nil

			if not IsValidPlayer(target) then
				return originalBanid(calling, steamid, minutes, reason)
			end

			return BeginBan(calling, target, minutes, reason, originalBanid, true, steamid)
		end
	end

	installed = true

	return true
end

if not TryInstall() then
	local attempts = 0

	timer.Create("hg_funban_install", 0.5, 0, function()
		attempts = attempts + 1

		if TryInstall() then
			timer.Remove("hg_funban_install")
			Debug("hooked ulx ban/kick.")
		elseif attempts >= 120 then
			timer.Remove("hg_funban_install")
			Debug("ULX not found, funban is disabled.")
		end
	end)
end

-- hg_funbantest is a server ConVar (server console / rcon only). This gives
-- admins an in-game way to toggle it, and blocks everyone else.
local function IsAdminPly(ply)
	if not IsValidPlayer(ply) then return true end -- server console / rcon

	if ply:IsAdmin() or ply:IsSuperAdmin() then return true end

	if ULib and ULib.ucl and ULib.ucl.query then
		local ok, access = pcall(ULib.ucl.query, ply, "ulx ban")
		if ok and access then return true end
	end

	return false
end

local function PrintFunbantest(ply, str)
	if IsValidPlayer(ply) then
		ply:ChatPrint(str)
	else
		print(str)
	end
end

local function SetFunbantest(ply, value)
	if value ~= nil then
		funbantest:SetBool(value)
	end

	PrintFunbantest(ply, "[hg_funban] sniper decapitation is now " .. (funbantest:GetBool() and "ON" or "OFF"))
end

local function FunbantestCommand(ply, arg)
	if not IsAdminPly(ply) then
		PrintFunbantest(ply, "[hg_funban] hg_funbantest is admin only.")
		return
	end

	if arg == "0" or arg == "1" then
		SetFunbantest(ply, arg == "1")
	elseif arg == nil or arg == "" then
		SetFunbantest(ply, not funbantest:GetBool())
	else
		PrintFunbantest(ply, "Usage: hg_funbantest_toggle [0|1]")
	end
end

concommand.Add("hg_funbantest_toggle", function(ply, cmd, args)
	FunbantestCommand(ply, args and args[1])
end, nil, "Admin only: toggle hg_funbantest (sniper head gib on ban/kick)")

hook.Add("PlayerSay", "hg_funbantest", function(ply, text)
	local cmd, arg = string.match(text, "^[!/]([%w_]+)%s*(.*)$")
	if not cmd or string.lower(cmd) ~= "funbantest" then return end

	FunbantestCommand(ply, arg)

	return ""
end)
