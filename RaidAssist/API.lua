local DF = DetailsFramework
local LBB = LibStub("LibBabble-Boss-3.0"):GetLookupTable()
local LibGroupTalents = LibStub("LibGroupTalents-1.0")
local RA = RaidAssist
local _

if (_G.RaidAssistLoadDeny) then
	return
end

--[=[
	RA:GetPopupAttachAnchors()
	get the anchors for the 'menu_popup_show' function. making your popup frame attach on the menu.
	the 'menu_popup_show' return on its seconds parameter the menu frame.
	use: ANCHOR1, <menu_frame>, ANCHOR2, X, Y
--]=]
function RA:GetPopupAttachAnchors()
	local anchorSide = RA.db.profile.addon.anchor_side
	local anchor1, anchor2, x, y
	
	if (anchorSide == "left") then
		anchor1, anchor2, x, y = "left", "right", 4, 0
	elseif (anchorSide == "right") then
		anchor1, anchor2, x, y = "right", "left", -4, 0
	elseif (anchorSide == "top") then
		anchor1, anchor2, x, y = "topleft", "topright", 4, 0
	elseif (anchorSide == "bottom") then
		anchor1, anchor2, x, y = "bottomleft", "right", 4, 0
	end
	
	return anchor1, anchor2, x, y
end

--[=[
	RA:AnchorMyPopupFrame (plugin)
--]=]
function RA:AnchorMyPopupFrame (plugin)
	assert (type (plugin) == "table" and plugin.popup_frame, "AnchorMyPopupFrame expects a plugin object on parameter 1.")
	local ct_frame = GameCooltipFrame1
	local anchor1, anchor2, x, y = RA:GetPopupAttachAnchors()
	plugin.popup_frame:SetPoint (anchor1, ct_frame, anchor2, x, y)
	plugin.popup_frame:Show()
end

--[=[
	RA:InstallPlugin (name, frameName, pluginObject, defaultConfig)
	name: string, name of the plugin.
	frameName: string, name for the plugin frames.
	pluginObject: table, with all the plugin functions.
	defaultConfig: table, with key and values to store on db.
--]=]
function RA:InstallPlugin (name, frameName, pluginObject, defaultConfig)
	assert (type (name) == "string", "InstallPlugin expects a string on parameter 1.")
	assert (type (frameName) == "string", "InstallPlugin expects a string on parameter 2.")
	assert (not RA.plugins [name], "Plugin name " ..name.." already in use.")
	assert (type (pluginObject) == "table", "InstallPlugin expects a table on parameter 3.")
	
	if (not RA.db) then
		RA.schedule_install [#RA.schedule_install+1] = {name, frameName, pluginObject, defaultConfig}
		return "scheduled"
	end
	
	RA.plugins [name] = pluginObject
	pluginObject.db_default = defaultConfig or {}
	setmetatable (pluginObject, RA)

	RA:LoadPluginDB (name, true)

	if (pluginObject.db.menu_priority == nil) then
		pluginObject.db.menu_priority = 1
	end
	
	pluginObject.popup_frame = RA:CreatePopUpFrame (pluginObject, frameName .. "PopupFrame")
	pluginObject.main_frame = RA:CreatePluginFrame (pluginObject, frameName .. "MainFrame", name)

	if (pluginObject.OnInstall) then
		local err = geterrorhandler()
		xpcall (pluginObject.OnInstall, err, pluginObject)
	end
	
	return "successful"
end

--[=[
	RA:EnablePlugin (name)
	Turn on a plugin and calls OnEnable member if exists.
--]=]
function RA:EnablePlugin (name)
	assert (type (name) == "string", "DisablePlugin expects a string on parameter 1.")
	local plugin = RA.plugins [name]
	if (plugin) then
		plugin.db.enabled = true
		if (plugin.OnEnable) then
			pcall (plugin.OnEnable, plugin)
		end
	end
end

--[=[
	RA:DisablePlugin (name)
	Turn off a plugin and calls OnDisable member if exists.
--]=]
function RA:DisablePlugin (name)
	assert (type (name) == "string", "DisablePlugin expects a string on parameter 1.")
	local plugin = RA.plugins [name]
	if (plugin) then
		plugin.db.enabled = false
		if (plugin.OnDisable) then
			pcall (plugin.OnDisable, plugin)
		end
	end
end

--[=[
	RA:GetPluginList()
	return the plugin list.
--]=]
function RA:GetPluginList()
	return RA.plugins
end

--[=[
	RA:RegisterPluginComm (prefix, func)
	prefix (string) combination of two-four letters for identify the function which will receive the data.
	func (function) a function to be called when receive data with the prefix.
--]=]
function RA:RegisterPluginComm (prefix, func)
	assert (type (prefix) == "string", "RegisterPluginComm expects a string on parameter 1.")
	assert (type (func) == "function", "RegisterPluginComm expects a function on parameter 2.")
	RA.comm [prefix] = func
end

--[=[
	RA:UnregisterPluginComm (prefix)
	prefix (string) a previous registered prefix.
--]=]
function RA:UnregisterPluginComm (prefix, func)
	assert (type (prefix) == "string", "RegisterPluginComm expects a string on parameter 1.")
	RA.comm [prefix] = nil
end

--[=[
	RA:SendPluginCommMessage (prefix, channel, ...)
	
	Is a customized function to use when sending comm messages.
	SendCommMessage / CommReceived / RegisterComm can all be used directly from the plugin.
	
	prefix (string) receiving func identification.
	channel (string) which channel the comm is sent.
	callback (function) called after the message as fully sent.
	callbackParam (any value), param to be added within callback.
	... all parameter to be send within the comm.
--]=]

function RA:SendPluginCommWhisperMessage (prefix, target, callback, callbackParam, ...)
	RA:SendCommMessage (RA.commPrefix, RA:Serialize (prefix, self.version or "", ...), "WHISPER", target, nil, callback, callbackParam)
end

function RA:SendPluginCommMessage (prefix, channel, callback, callbackParam, ...)
	assert (type (prefix) == "string", "SendPluginCommMessage expects a string on parameter 1.")
	if (callback) then
		assert (type (callback) == "function", "SendPluginCommMessage expects a function as callback (optional).")
	end
	if (channel == "RAID-NOINSTANCE") then
		if (IsInRaid ()) then
			RA:SendCommMessage (RA.commPrefix, RA:Serialize (prefix, self.version or "", ...), "RAID", nil, nil, callback, callbackParam)
		end
	elseif (channel == "RAID") then
		if (IsInRaid ()) then
			RA:SendCommMessage (RA.commPrefix, RA:Serialize (prefix, self.version or "", ...), "RAID", nil, nil, callback, callbackParam)
		end
	elseif (channel == "PARTY-NOINSTANCE") then
		if (IsInGroup ()) then
			RA:SendCommMessage (RA.commPrefix, RA:Serialize (prefix, self.version or "", ...), "PARTY", nil, nil, callback, callbackParam)
		end
	elseif (channel == "PARTY") then
		if (IsInGroup ()) then
			RA:SendCommMessage (RA.commPrefix, RA:Serialize (prefix, self.version or "", ...), "PARTY", nil, nil, callback, callbackParam)
		end
	else
		RA:SendCommMessage (RA.commPrefix, RA:Serialize (prefix, self.version or "", ...), channel, nil, nil, callback, callbackParam)
	end
end

--[=[
	RA:IsAddOnInstalled (addonName)
	return if the user has a addon installed and if is enabled or not.
	addonName (string) name of an addon.
--]=]
function RA:IsAddOnInstalled (addonName)
	assert (type (addonName) == "string", "IsAddOnInstalled expects a string on parameter 1.")
	local name, title, notes, loadable, reason, security, newVersion = GetAddOnInfo (addonName)
	
	-- need to check ingame what the values is returning.
	print (name, loadable, reason)
end

--[=[
	RA:RegisterForCLEUEvent (event, func)
	register a sub event of combat log and calls a function when this event happens.
	event (string) name of the CLEU token, e.g. SPELL_DAMAGE, SPELL_INTERRUPT.
	func (function) it's called when the event is triggered.
--]=]
function RA:RegisterForCLEUEvent (event, func)
	RA.CLEU_readEvents [event] = true
	if (not RA.CLEU_registeredEvents [event]) then
		RA.CLEU_registeredEvents [event] = {}
	end
	tinsert (RA.CLEU_registeredEvents [event], func)
end

--[=[
	RA:UnregisterForCLEUEvent (event, func)
	unregister a previous registered event of combat log.
	event (string) the event previous registered.
	func (function) the function previous registered.
--]=]
function RA:UnregisterForCLEUEvent (event, func)
	if (RA.CLEU_registeredEvents [event]) then
		for index, f in ipairs (RA.CLEU_registeredEvents [event]) do 
			if (f == func) then
				tremove (RA.CLEU_registeredEvents [event], index)
				break
			end
		end
		if (#RA.CLEU_registeredEvents [event] < 1) then
			RA.CLEU_readEvents [event] = nil
		end
	end
end

--[=[
	RA:GetRepairStatus()
	return the durability amount from the player's equipment.
--]=]
function RA:GetRepairStatus()
	local percent, items = 0, 0
	for i = INVSLOT_FIRST_EQUIPPED, INVSLOT_LAST_EQUIPPED do
		local durability, maxdurability = GetInventoryItemDurability (i)
		if (durability and maxdurability) then
			local p = durability / maxdurability * 100
			percent = percent + p
			items = items + 1
		end
	end

	if (items == 0) then
		return 100
	end

	return percent / items
end

--[=[
	RA:GetSloppyEquipment()
	return two tables containing the slot id of items without enchats and gems.
--]=]
local canEnchantSlot = {
	--[INVSLOT_NECK] = true,
	[INVSLOT_HAND] = true,
	[INVSLOT_WRIST] = true,
	[INVSLOT_CHEST] = true,
	[INVSLOT_SHOULDER] = true,
	[INVSLOT_HEAD] = true,
	[INVSLOT_LEGS] = true,
	[INVSLOT_FEET] = true,
	[INVSLOT_BACK] = true,
	[INVSLOT_MAINHAND] = true,
	[INVSLOT_OFFHAND] = true,
}
local statsTable = {}
function RA:GetSloppyEquipment()

	local no_enchant = {}
	local no_gem = {}

	for equip_id = 1, 17 do
		if (equip_id ~= 4 and equip_id ~= 13 and equip_id ~= 14) then --shirt / trinket1 / trinket2
			local item = GetInventoryItemLink ("player", equip_id)
			if (item) then
				local _, _, enchant, gemID1, gemID2, gemID3, gemID4 = strsplit (":", item)
				
				if (canEnchantSlot [equip_id] and (enchant == "0" or enchant == "")) then
					no_enchant [#no_enchant+1] = equip_id
				end

				if (equip_id == INVSLOT_RANGED and select(2, UnitClass("player")) == "HUNTER" and canEnchantSlot [equip_id] and (enchant == "0" or enchant == "")) then
					no_enchant [#no_enchant+1] = equip_id
				end
				
				local filledSockets = 4

				if (gemID1 == "0" or gemID1 == "") then
					filledSockets = filledSockets - 1
				end

				if (gemID2 == "0" and gemID2 == "") then
					filledSockets = filledSockets - 1
				end

				if (gemID3 == "0" and gemID3 == "") then
					filledSockets = filledSockets - 1
				end

				if (gemID4 == "0" and gemID4 == "") then
					filledSockets = filledSockets - 1
				end

				GetItemStats (item, statsTable)

				local socket_count = 0
				
				if statsTable.EMPTY_SOCKET_PRISMATIC then 
					socket_count = socket_count + statsTable.EMPTY_SOCKET_PRISMATIC
				end

				if statsTable.EMPTY_SOCKET_YELLOW then 
					socket_count = socket_count + statsTable.EMPTY_SOCKET_YELLOW
				end

				if statsTable.EMPTY_SOCKET_RED then 
					socket_count = socket_count + statsTable.EMPTY_SOCKET_RED
				end

				if statsTable.EMPTY_SOCKET_BLUE then 
					socket_count = socket_count + statsTable.EMPTY_SOCKET_BLUE
				end

				if filledSockets < socket_count then
					no_gem [#no_gem+1] = equip_id
				end
			end
		end
	end

	return no_enchant, no_gem
end

--[=[
	RA:GetTalents()
	Returns a talent string of ##/##/##
--]=]
function RA:GetTalents()
	local _, t1, t2, t3 = LibGroupTalents:GetUnitTalentSpec("player")
	return t1 .. "/" .. t2 .. "/" .. t3
end

--[=[
	RA:GetGuildRanks (forDropdown)
	return a table with ranks for the player guild or a formated table for use on dropdowns.
--]=]
function RA:GetGuildRanks (forDropdown)
	if (forDropdown) then
		local t = {}
		for i = 1, GuildControlGetNumRanks() do 
			tinsert (t, {value = i, label = GuildControlGetRankName (i), onclick = empty_func})
		end
		return t
	else
		local t = {}
		for i = 1, GuildControlGetNumRanks() do 
			t [i] = GuildControlGetRankName (i)
		end
		return t
	end
end

--[=[
	RA:IsInQueue()
	return is the player is in queue for bg, arena, dungeon, rf, premade.
--]=]
function RA:IsInQueue()
	for LFG_CATEGORY = 1, 5 do 
		if (GetLFGMode (LFG_CATEGORY)) then
			return true
		end
	end
end

--[=[
	Friendship functions:
	RA:IsBnetFriend (character_name): return if the character is your bnet friend.
	RA:IsFriend (character_name): return if the character is in your friend list.
	RA:IsGuildFriend (character_name): return if the character is in the same guild as the player.
--]=]

function RA:IsBnetFriend (who)
	who = RA:RemoveRealName (who)
	local bnet_friends_amt = BNGetNumFriends()
	for i = 1, bnet_friends_amt do 
		local presenceID, presenceName, battleTag, isBattleTagPresence, toonName, toonID, client, isOnline, lastOnline, isAFK, isDND, messageText, noteText, isRIDFriend, broadcastTime, canSoR = BNGetFriendInfo (i)
		if (isOnline and client == BNET_CLIENT_WOW and who == toonName) then
			return true
		end
	end
end

function RA:IsFriend (who)
	local friends_amt = GetNumFriends()
	for i = 1, friends_amt do
		local toonName = GetFriendInfo (i)
		if (who == toonName) then
			return true
		end
	end
end


function RA:IsGuildFriend (who)
	if (IsInGuild()) then
		return UnitIsInMyGuild (who) or UnitIsInMyGuild (who:gsub ("%-.*", ""))
	end
end

--[=[
	RA:RegisterForEnterRaidGroup (func)
	RA:RegisterForLeaveRaidGroup (func)
	Calls 'func' when the player enters or left a raid group.
	
	RA:UnregisterForEnterRaidGroup (func)
	RA:UnregisterForLeaveRaidGroup (func)
	Remove a previous regitered function.
--]=]

function RA:RegisterForEnterRaidGroup (func)
	tinsert (RA.playerEnteredInRaidGroup, func)
end

function RA:RegisterForLeaveRaidGroup (func)
	tinsert (RA.playerLeftRaidGroup, func)
end

function RA:RegisterForEnterPartyGroup (func)
	tinsert (RA.playerEnteredInPartyGroup, func)
end

function RA:RegisterForLeavePartyGroup (func)
	tinsert (RA.playerLeftPartyGroup, func)
end

function RA:UnregisterForEnterRaidGroup (func)
	for i = #RA.playerEnteredInRaidGroup, 1, -1 do
		if (RA.playerEnteredInRaidGroup [i] == func) then
			tremove (RA.playerEnteredInRaidGroup, i)
		end
	end
end

function RA:UnregisterForLeavePartyGroup (func)
	for i = #RA.playerLeftPartyGroup, 1, -1 do
		if (RA.playerLeftPartyGroup [i] == func) then
			tremove (RA.playerLeftPartyGroup, i)
		end
	end
end

function RA:UnregisterForEnterPartyGroup (func)
	for i = #RA.playerEnteredInPartyGroup, 1, -1 do
		if (RA.playerEnteredInPartyGroup [i] == func) then
			tremove (RA.playerEnteredInPartyGroup, i)
		end
	end
end

function RA:UnregisterForLeaveRaidGroup (func)
	for i = #RA.playerLeftRaidGroup, 1, -1 do
		if (RA.playerLeftRaidGroup [i] == func) then
			tremove (RA.playerLeftRaidGroup, i)
		end
	end
end

--[=[
	GetPlayerWithRealmName()
	return the player name with its realm name.
--]=]

function RA:GetPlayerNameWithRealm()
	local name, realmName = UnitName ("player")
	if (realmName == "" or realmName == nil) then
		realmName = GetRealmName()
	end
	name = name.."-"..realmName
	return name
end

local faction_champ_id, gunship_id = 34467, 37540
if UnitFactionGroup("player") == "Alliance" then 
	faction_champ_id, gunship_id = 34451, 37215 
end

local ENCOUNTER_ID_MAP = {
	[536] = { -- Naxxramas
		[15956] = LBB["Anub'Rekhan"],
		[15953] = LBB["Grand Widow Faerlina"],
		[15952] = LBB["Maexxna"],
		[15954] = LBB["Noth the Plaguebringer"],
		[15936] = LBB["Heigan the Unclean"],
		[16011] = LBB["Loatheb"],
		[16061] = LBB["Instructor Razuvious"],
		[16060] = LBB["Gothik the Harvester"],
		[30549] = LBB["The Four Horsemen"],
		[16028] = LBB["Patchwerk"],
		[15931] = LBB["Grobbulus"],
		[15932] = LBB["Gluth"],
		[15928] = LBB["Thaddius"],
		[15989] = LBB["Sapphiron"],
		[15990] = LBB["Kel'Thuzad"],
	},
	[532] = { -- Obsidian Sanctum
		[28860] = LBB["Sartharion"],
	},
	[528] = { 
        [28859] = LBB["Malygos"],
    },
	[530] = { -- Ulduar
		[33113] = LBB["Flame Leviathan"],
		[33118] = LBB["Ignis the Furnace Master"],
		[33186] = LBB["Razorscale"],
		[33293] = LBB["XT-002 Deconstructor"],
		[32867] = LBB["Assembly of Iron"],
		[32930] = LBB["Kologarn"],
		[33515] = LBB["Auriaya"],
		[32845] = LBB["Hodir"],
		[32865] = LBB["Thorim"],
		[32906] = LBB["Freya"],
		[33350] = LBB["Mimiron"],
		[33271] = LBB["General Vezax"],
		[33136] = LBB["Yogg-Saron"],
		[32871] = LBB["Algalon the Observer"],
	},
	[544] = { -- ToC
		[34797] = LBB["The Beasts of Northrend"],
		[34780] = LBB["Lord Jaraxxus"],
		[faction_champ_id] = LBB["Faction Champions"],
		[34497] = LBB["The Twin Val'kyr"],
		[34564] = LBB["Anub'arak"],
	},
	[605] = { -- Icecrown Citadel 
		[36612] = LBB["Lord Marrowgar"],
		[36855] = LBB["Lady Deathwhisper"],
		[gunship_id] = LBB["Icecrown Gunship Battle"],
		[37813] = LBB["Deathbringer Saurfang"],
		[36626] = LBB["Festergut"],
		[36627] = LBB["Rotface"],
		[36678] = LBB["Professor Putricide"],
		[37970] = LBB["Blood Prince Council"],
		[37955] = LBB["Blood-Queen Lana'thel"],
		[36789] = LBB["Valithria Dreamwalker"],
		[36853] = LBB["Sindragosa"],
		[36597] = LBB["The Lich King"],
	},
	[610] = { -- Ruby Sanctum
		[39863] = LBB["Halion"],
	},
}
--[=[
	GetEncounterName (encounter_id)
	return the encounter name from a encounter id.
--]=]
function RA:GetEncounterName (encounterId)
	for _, encounters in pairs(ENCOUNTER_ID_MAP) do 
		if encounters[encounterId] then 
			return encounters[encounterId]
		end
	end
	return ""
end

function RA:GetRaidEncounterName (mapID, encounterID)
	return ENCOUNTER_ID_MAP[mapID] and ENCOUNTER_ID_MAP[mapID] [encounterID] 
end
--[=[
	GetCurrentRaidEncounterList()
	return a table with encounter names from the current raid.
--]=]


local empty_table = {}
function RA:GetCurrentRaidEncounterList (mapid)
	if not mapid then 
		mapid = GetCurrentMapAreaID()
	end
	local bosses = {}
	local encounters = ENCOUNTER_ID_MAP[mapid] or empty_table
	for id, name in pairs(encounters) do
		tinsert(bosses, {name, id})
	end
	return bosses
end

--[=[
	UnitHasAssist (unit)
	return is a unit has assist on the raid
--]=]
function RA:UnitHasAssist (unit)
	return IsInRaid() and (UnitIsRaidOfficer (unit) or UnitIsGroupLeader (unit))
end

--[=[
	UnitIsRaidLeader (unit)
	return is a unit is the leader of the raid
--]=]
function RA:UnitIsRaidLeader (unit)
	if (type (unit) == "string") then
		return UnitIsGroupLeader (unit) or UnitIsGroupLeader (unit:gsub ("%-.*", ""))
	end
end

--[=[
	GetRaidLeader()
	return the raid leader name and raidunitid
--]=]
function RA:GetRaidLeader()
	if (IsInRaid()) then
		for i = 1, GetNumGroupMembers() do
			local name, rank = GetRaidRosterInfo (i)
			if (rank == 2) then
				return name, "raid" .. i
			end
		end
	end
	return false
end

--[=[
	PercentColor()
	return green <-> red color based on the value passed
--]=]
function RA:PercentColor (value, inverted)
	local r, g
	if (value < 50) then
		r = 255
	else
		r = floor ( 255 - (value * 2 - 100) * 255 / 100)
	end
	
	if (value > 50) then
		g = 255
	else
		g = floor ( (value * 2) * 255 / 100)
	end
	
	if (inverted) then
		return g/255, r/255, 0
	else
		return r/255, g/255, 0
	end
end
--[=[
	Hex()
	return a hex string for the number passed
--]=]
function RA:Hex (num)
	local hexstr = '0123456789abcdef'
	local s = ''
	while num > 0 do
		local mod = math.fmod (num, 16)
		s = string.sub (hexstr, mod+1, mod+1) .. s
		num = math.floor (num / 16)
	end
	if s == '' then s = '00' end
	if (string.len (s) == 1) then
		s = "0"..s
	end
	return s
end

--[=[
	GetBossSpellList (encounterid)
	return a table with spells id.
--]=]

local boss_spells = { --[boss EJID] = {spellIDs}
}

function RA:GetBossSpellList (ej_id)

	return boss_spells [ej_id]
end

--[=[
	GetBossIds (any id)
	return the encounter id from the journal and for the combatlog
--]=]
local encounter_journal = {
	--[instance EJID] { [boss EJID] = Combatlog ID}
	[536] = { -- Naxxramas
		[15956] = 15956,
		[15953] = 15953,
		[15952] = 15952,
		[15954] = 15954,
		[15936] = 15936,
		[16011] = 16011,
		[16061] = 16061,
		[16060] = 16060,
		[30549] = 30549,
		[16028] = 16028,
		[15931] = 15931,
		[15932] = 15932,
		[15928] = 15928,
		[15989] = 15989,
		[15990] = 15990,
	},
	[532] = { -- Obsidian Sanctum
		[28860] = 28860,
	},
	[528] = { 
        [28859] = 28859,
    },
	[530] = { -- Ulduar
		[33113] = 33113,
		[33118] = 33118,
		[33186] = 33186,
		[33293] = 33293,
		[32867] = 32867,
		[32930] = 32930,
		[33515] = 33515,
		[32845] = 32845,
		[32865] = 32865,
		[32906] = 32906,
		[33350] = 33350,
		[33271] = 33271,
		[33136] = 33136,
		[32871] = 32871,
	},
	[544] = { -- ToC
		[34797] = 34797,
		[34780] = 34780,
		[faction_champ_id] = faction_champ_id,
		[34497] = 34497,
		[34564] = 34564,
	},
	[605] = { -- Icecrown Citadel 
		[36612] = 36612,
		[36855] = 36855,
		[gunship_id] = gunship_id,
		[37813] = 37813,
		[36626] = 36626,
		[36627] = 36627,
		[36678] = 36678,
		[37970] = 37970,
		[37955] = 37955,
		[36789] = 36789,
		[36853] = 36853,
		[36597] = 36597,
	},
	[610] = { -- Ruby Sanctum
		[39863] = 39863,
	},
}

local combat_log_ids = encounter_journal -- ids are the same anyway

function RA:GetRegisteredRaids()
	return encounter_journal
end

function RA:GetBossIds (raidID, bossid)
	local ejid = encounter_journal [raidID] and encounter_journal [raidID] [bossid] or bossid
	local combatlog = combat_log_ids [raidID] and combat_log_ids [raidID] [bossid] or bossid
	return ejid, combatlog
end

--[=[
	GetWeakAuras2Object()
	return the weakaura addon object if installed and enabled
--]=]

function RA:GetWeakAuras2Object()
	local WeakAuras_Object = _G.WeakAuras
	local WeakAuras_SavedVar = _G.WeakAurasSaved
	return WeakAuras_Object, WeakAuras_SavedVar
end

--/run _G.WeakAuras.Delete (_G.WeakAurasSaved.displays ["Rip Target"])

--[=[
	GetWeakAuraTable (auraName)
	return the aura table of a specific aura
--]=]

function RA:GetWeakAuraTable (auraName)
	local WeakAuras_Object, WeakAuras_SavedVar = RA:GetWeakAuras2Object()
	if (WeakAuras_SavedVar) then
		return WeakAuras_SavedVar.displays [auraName]
	end
end

--[=[
	GetAllWeakAurasIds()
	return a table with all weak auras ids (names)
--]=]

function RA:GetAllWeakAurasNames()
	local AllAuras = RA:GetAllWeakAuras()
	if (AllAuras) then
		local t = {}
		for auraName, auraTable in pairs (AllAuras) do
			t [#t+1] = auraName
		end
		return t
	end
end

--[=[
	GetAllWeakAuras()
	return a table with all weak auras
--]=]

function RA:GetAllWeakAuras()
	local WeakAuras_Object, WeakAuras_SavedVar = RA:GetWeakAuras2Object()
	return WeakAuras_SavedVar and WeakAuras_SavedVar.displays
end

--[=[
	InstallWeakAura (auraTable)
	install a weakaura into WeakAuras2 addon
--]=]

function RA:InstallWeakAura (auraTable)
	if (not auraTable.id) then
		return
	end
	local WeakAuras_Object, WeakAuras_SavedVar = RA:GetWeakAuras2Object()
	if (WeakAuras_Object) then
		if (not RA:GetWeakAuraTable (auraTable.id)) then
			WeakAuras.Add (auraTable)
			return 1
		else
			return 1
		end
	else
		return -1
	end
end


