CRIMXP = CRIMXP or {}

CRIMXP.Config = {
	BaseKillXP = 100,
	HeadshotBonus = 50,
	MeleeBonus = 50,
	LongshotBonus = 25,
	LongshotDist = 1550,
	AssistXP = 30,
	AssistFraction = 0.25,
	BotKillXP = 0.5,
	MultikillWindow = 6,
	MultikillBonus = {25, 50, 75, 100},
	StreakEvery = 5,
	StreakBonus = 50,
	FractureBaseKill = 150,
	FractureHeadshot = 75,
	FractureMelee = 75,
	FractureLongshot = 40,
	FractureAssist = 50,
	FractureMultikillBonus = {50, 100, 150, 200},
	FractureStreakBonus = 100,
	LevelReward = 1000,
	FractureBotKill = 0.5,
	VictimLevelScale = 0.02,
	VictimLevelScaleCap = 0.5,
	XPBase = 500,
	XPGrowth = 1.1,
	MaxLevel = 100,
}

CRIMXP.Ranks = {
	{level = 1, name = "Civilian", color = Color(200, 200, 200)},
	{level = 5, name = "Crook", color = Color(120, 255, 120)},
	{level = 10, name = "Thug", color = Color(255, 220, 80)},
	{level = 15, name = "Gangster", color = Color(255, 180, 40)},
	{level = 20, name = "Hustler", color = Color(255, 150, 40)},
	{level = 27, name = "Hitman", color = Color(255, 110, 40)},
	{level = 35, name = "Enforcer", color = Color(255, 70, 40)},
	{level = 45, name = "Assassin", color = Color(255, 40, 70)},
	{level = 55, name = "Underboss", color = Color(220, 40, 255)},
	{level = 70, name = "Crime Lord", color = Color(160, 60, 255)},
	{level = 85, name = "Kingpin", color = Color(100, 100, 255)},
	{level = 100, name = "Godfather", color = Color(255, 255, 120)},
}

local function Unlock(points, free)
	return {points = points, price = free and 0 or points * 1000, free = free or nil}
end

CRIMXP.Loadouts = {
	traitor = {
		maxPoints = 30,
		defaultWeapons = {"weapon_mp-80", "weapon_buck200knife"},
		skillsets = {
			["none"] = Unlock(0, true),
			["infiltrator"] = Unlock(15),
			["assassin"] = Unlock(15),
			["damned"] = Unlock(30),
			["chemist"] = Unlock(10),
		},
		items = {
			["weapon_mp-80"] = Unlock(2, true),
			["weapon_tranquilizer"] = Unlock(5),
			["weapon_p22"] = Unlock(6),
			["weapon_taser"] = Unlock(6),
			["weapon_buck200knife"] = Unlock(2, true),
			["weapon_sogknife"] = Unlock(2),
			["weapon_hg_rgd_tpik"] = Unlock(4),
			["weapon_adrenaline"] = Unlock(3),
			["weapon_hg_shuriken"] = Unlock(1),
			["weapon_hg_smokenade_tpik"] = Unlock(2),
			["weapon_traitor_ied"] = Unlock(5),
			["weapon_traitor_ied_shitty"] = Unlock(2),
			["weapon_traitor_poison1"] = Unlock(2),
			["weapon_traitor_poison2"] = Unlock(2),
			["weapon_traitor_poison3"] = Unlock(4),
			["weapon_traitor_poison4"] = Unlock(2),
			["weapon_traitor_poison_consumable"] = Unlock(3),
			["weapon_traitor_suit"] = Unlock(1),
			["weapon_hg_jam"] = Unlock(1),
			["weapon_walkie_talkie"] = Unlock(1),
		},
		addons = {
			["weapon_p22_silencer"] = Unlock(2),
			["weapon_p22_ammo"] = Unlock(2),
		},
		exclusions = {
			["weapon_buck200knife"] = {["weapon_sogknife"] = true},
			["weapon_sogknife"] = {["weapon_buck200knife"] = true},
		},
	},
	hero = {
		maxPoints = 16,
		defaultWeapons = {"weapon_px4beretta"},
		items = {
			["weapon_px4beretta"] = Unlock(4, true),
			["weapon_glock17"] = Unlock(5),
			["weapon_hk_usp"] = Unlock(5),
			["weapon_remington870"] = Unlock(8),
			["weapon_kar98"] = Unlock(8),
			["ent_armor_vest3"] = Unlock(4),
			["ent_armor_helmet1"] = Unlock(2),
			["ent_armor_helmet7"] = Unlock(2),
			["ent_armor_mask1"] = Unlock(2),
			["ent_armor_mask2"] = Unlock(2),
			["ent_armor_mask3"] = Unlock(2),
			["weapon_vpo209"] = Unlock(12),
			["weapon_vpo136"] = Unlock(12),
			["weapon_mosin"] = Unlock(8),
			["weapon_walkie_talkie"] = Unlock(1),
		},
		addons = {
			["hero_px4_silencer"] = Unlock(2),
			["hero_px4_ammo"] = Unlock(2),
			["hero_glock_silencer"] = Unlock(2),
			["hero_glock_rmr"] = Unlock(2),
			["hero_glock_laser"] = Unlock(1),
			["hero_glock_ammo"] = Unlock(2),
			["hero_usp_silencer"] = Unlock(2),
			["hero_usp_ammo"] = Unlock(2),
			["hero_remington_ammo"] = Unlock(2),
			["hero_kar98_scope"] = Unlock(2),
			["hero_kar98_ammo"] = Unlock(2),
			["hero_remington_sight"] = Unlock(2),
			["hero_vpo209_silencer"] = Unlock(2),
			["hero_vpo209_optic"] = Unlock(2),
			["hero_vpo209_ammo"] = Unlock(2),
			["hero_vpo136_silencer"] = Unlock(2),
			["hero_vpo136_optic"] = Unlock(2),
			["hero_vpo136_ammo"] = Unlock(2),
			["hero_mosin_silencer"] = Unlock(2),
			["hero_mosin_scope"] = Unlock(2),
			["hero_mosin_ammo"] = Unlock(2),
		},
		exclusions = {},
	},
}

do
	local heroWeaponIds = {
		"weapon_px4beretta",
		"weapon_glock17",
		"weapon_hk_usp",
		"weapon_remington870",
		"weapon_kar98",
		"weapon_vpo209",
		"weapon_vpo136",
		"weapon_mosin",
	}

	for _, weaponId in ipairs(heroWeaponIds) do
		CRIMXP.Loadouts.hero.exclusions[weaponId] = CRIMXP.Loadouts.hero.exclusions[weaponId] or {}

		for _, otherId in ipairs(heroWeaponIds) do
			if otherId ~= weaponId then
				CRIMXP.Loadouts.hero.exclusions[weaponId][otherId] = true
			end
		end
	end

	local armorSlots = {
		{"ent_armor_helmet1", "ent_armor_helmet7"},
		{"ent_armor_mask1", "ent_armor_mask2", "ent_armor_mask3"},
	}

	for _, slot in ipairs(armorSlots) do
		for _, armorId in ipairs(slot) do
			CRIMXP.Loadouts.hero.exclusions[armorId] = CRIMXP.Loadouts.hero.exclusions[armorId] or {}

			for _, otherId in ipairs(slot) do
				if otherId ~= armorId then
					CRIMXP.Loadouts.hero.exclusions[armorId][otherId] = true
				end
			end
		end
	end
end

do
	local addonParents = {
		traitor = {
			["weapon_p22_silencer"] = "weapon_p22",
			["weapon_p22_ammo"] = "weapon_p22",
		},
		hero = {
			["hero_px4_silencer"] = "weapon_px4beretta",
			["hero_px4_ammo"] = "weapon_px4beretta",
			["hero_glock_silencer"] = "weapon_glock17",
			["hero_glock_rmr"] = "weapon_glock17",
			["hero_glock_laser"] = "weapon_glock17",
			["hero_glock_ammo"] = "weapon_glock17",
			["hero_usp_silencer"] = "weapon_hk_usp",
			["hero_usp_ammo"] = "weapon_hk_usp",
			["hero_remington_ammo"] = "weapon_remington870",
			["hero_remington_sight"] = "weapon_remington870",
			["hero_kar98_scope"] = "weapon_kar98",
			["hero_kar98_ammo"] = "weapon_kar98",
			["hero_vpo209_silencer"] = "weapon_vpo209",
			["hero_vpo209_optic"] = "weapon_vpo209",
			["hero_vpo209_ammo"] = "weapon_vpo209",
			["hero_vpo136_silencer"] = "weapon_vpo136",
			["hero_vpo136_optic"] = "weapon_vpo136",
			["hero_vpo136_ammo"] = "weapon_vpo136",
			["hero_mosin_silencer"] = "weapon_mosin",
			["hero_mosin_scope"] = "weapon_mosin",
			["hero_mosin_ammo"] = "weapon_mosin",
		},
	}

	for roleId, parents in pairs(addonParents) do
		local config = CRIMXP.Loadouts[roleId]
		for id, parent in pairs(parents) do
			if config and config.addons[id] then config.addons[id].parent = parent end
		end
	end
end

do
	local levelByPoints = {
		[1] = 1,
		[2] = 2,
		[3] = 3,
		[4] = 3,
		[5] = 4,
		[6] = 4,
		[8] = 5,
		[12] = 7,
	}
	local skillsetLevels = {
		none = 1,
		chemist = 4,
		infiltrator = 6,
		assassin = 7,
		damned = 20,
	}

	for _, config in pairs(CRIMXP.Loadouts) do
		for _, group in ipairs({"skillsets", "items", "addons"}) do
			for id, entry in pairs(config[group] or {}) do
				if group == "skillsets" then
					entry.requiredLevel = skillsetLevels[id] or 1
				elseif entry.free then
					entry.requiredLevel = 1
				else
					entry.requiredLevel = levelByPoints[tonumber(entry.points)] or 1
				end
			end
		end
	end
end

CRIMXP.Net = {
	Kill = "hg_crimxp_kill",
	Assist = "hg_crimxp_assist",
	Death = "hg_crimxp_death",
	LevelUp = "hg_crimxp_levelup",
	UnlockSync = "HG_CrimXPUnlockSync",
	Purchase = "HG_CrimXPPurchase",
	PurchaseResult = "HG_CrimXPPurchaseResult",
}

function CRIMXP.GetRank(level)
	local rank = CRIMXP.Ranks[1]
	for i = 1, #CRIMXP.Ranks do
		if level >= CRIMXP.Ranks[i].level then rank = CRIMXP.Ranks[i] end
	end
	return rank.name, rank.color
end

function CRIMXP.XPForLevel(level)
	return math.floor(CRIMXP.Config.XPBase * CRIMXP.Config.XPGrowth ^ (level - 1))
end

function CRIMXP.LevelForXP(xp)
	xp = math.max(math.floor(xp or 0), 0)
	local level, remaining = 1, xp
	while level < CRIMXP.Config.MaxLevel do
		local need = CRIMXP.XPForLevel(level)
		if remaining < need then break end
		remaining = remaining - need
		level = level + 1
	end
	if level >= CRIMXP.Config.MaxLevel then return CRIMXP.Config.MaxLevel, 0, 0 end
	return level, remaining, CRIMXP.XPForLevel(level)
end

function CRIMXP.TotalXPForLevel(level)
	level = math.Clamp(math.floor(tonumber(level) or 1), 1, CRIMXP.Config.MaxLevel)

	local total = 0
	for i = 1, level - 1 do
		total = total + CRIMXP.XPForLevel(i)
	end

	return total
end

function CRIMXP.GetLevelReward(level)
	level = math.Clamp(math.floor(tonumber(level) or 1), 1, CRIMXP.Config.MaxLevel)
	return math.floor((CRIMXP.Config.LevelReward or 0) * level)
end

function CRIMXP.GetUnlockEntry(id, roleId)
	if not isstring(id) then return end

	local roleIds = roleId and {roleId} or {"traitor", "hero"}
	for _, rid in ipairs(roleIds) do
		local config = CRIMXP.Loadouts[rid]
		if config then
			for _, group in ipairs({"items", "addons", "skillsets"}) do
				local entry = config[group] and config[group][id]
				if entry then return entry, rid, group end
			end
		end
	end
end

function CRIMXP.GetRequiredLevel(id, roleId)
	local entry = CRIMXP.GetUnlockEntry(id, roleId)
	return tonumber(entry and entry.requiredLevel) or 1
end

function CRIMXP.GetEarlyUnlockPrice(id, roleId)
	local entry = CRIMXP.GetUnlockEntry(id, roleId)
	return math.floor((tonumber(entry and entry.price) or 0) * 4)
end

local function LoadoutConflict(config, selected, id)
	local exclusions = config.exclusions and config.exclusions[id]
	if exclusions then
		for _, selectedId in ipairs(selected) do
			if selectedId ~= id and exclusions[selectedId] then return true end
		end
	end

	for _, selectedId in ipairs(selected) do
		if selectedId ~= id then
			local selectedExclusions = config.exclusions and config.exclusions[selectedId]
			if selectedExclusions and selectedExclusions[id] then return true end
		end
	end

	return false
end

function CRIMXP.GetLoadoutPoints(roleId, loadout)
	local config = CRIMXP.Loadouts[roleId]
	if not config or type(loadout) ~= "table" then return 0 end

	local points = 0
	for _, id in ipairs(loadout.weapons or {}) do
		local entry = (config.items and config.items[id]) or (config.addons and config.addons[id])
		if entry then points = points + (tonumber(entry.points) or 0) end
	end

	local skillset = config.skillsets and config.skillsets[loadout.skillset or "none"]
	if skillset then points = points + (tonumber(skillset.points) or 0) end

	return points
end

function CRIMXP.SanitizeLoadout(roleId, rawLoadout, isUnlocked)
	local config = CRIMXP.Loadouts[roleId]
	if not config then return {weapons = {}} end

	if type(rawLoadout) ~= "table" then rawLoadout = {} end

	local normalized = {weapons = {}}
	if config.skillsets then normalized.skillset = "none" end

	local function allowed(id, entry)
		if not entry then return false end
		if entry.free then return true end
		return isUnlocked ~= nil and isUnlocked(id) == true
	end

	if config.skillsets and type(rawLoadout.skillset) == "string" then
		local entry = config.skillsets[rawLoadout.skillset]
		if allowed(rawLoadout.skillset, entry) then normalized.skillset = rawLoadout.skillset end
	end

	local totalPoints = 0
	if config.skillsets and config.skillsets[normalized.skillset] then
		totalPoints = tonumber(config.skillsets[normalized.skillset].points) or 0
	end

	local rawIds = {}
	local seen = {}

	if type(rawLoadout.weapons) == "table" then
		for key, value in pairs(rawLoadout.weapons) do
			local id
			if type(value) == "string" then
				id = value
			elseif type(key) == "string" and value == true then
				id = key
			end

			if id and not seen[id] and ((config.items and config.items[id]) or (config.addons and config.addons[id])) then
				seen[id] = true
				rawIds[#rawIds + 1] = id
			end
		end
	end

	local used = {}

	local function AddEntry(id, info, parent)
		if not info or used[id] or not allowed(id, info) then return end
		if parent and not used[parent] then return end
		if LoadoutConflict(config, normalized.weapons, id) then return end

		local cost = tonumber(info.points) or 0
		if totalPoints + cost > config.maxPoints then return end

		used[id] = true
		normalized.weapons[#normalized.weapons + 1] = id
		totalPoints = totalPoints + cost
	end

	for _, id in ipairs(rawIds) do
		AddEntry(id, config.items and config.items[id])
	end

	for _, id in ipairs(rawIds) do
		local addon = config.addons and config.addons[id]
		if addon then AddEntry(id, addon, addon.parent) end
	end

	if #normalized.weapons == 0 and normalized.skillset == "none" and config.defaultWeapons then
		for _, id in ipairs(config.defaultWeapons) do
			AddEntry(id, config.items and config.items[id])
		end
	end

	return normalized
end

local PLAYER = FindMetaTable("Player")

function PLAYER:GetCrimeLevel() return self:GetNWInt("hg_crime_level", 1) end
function PLAYER:GetCrimeXP() return self:GetNWInt("hg_crime_xp", 0) end
function PLAYER:GetCrimeKills() return self:GetNWInt("hg_crime_kills", 0) end
function PLAYER:GetCrimeDeaths() return self:GetNWInt("hg_crime_deaths", 0) end
function PLAYER:GetCrimeStreak() return self:GetNWInt("hg_crime_streak", 0) end
function PLAYER:GetCrimeBestStreak() return self:GetNWInt("hg_crime_beststreak", 0) end
function PLAYER:GetFracture() return self:GetNWInt("hg_crime_fracture", 0) end
