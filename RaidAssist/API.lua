local DF = DetailsFramework
local LBB = LibStub("LibBabble-Boss-3.0"):GetLookupTable()
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
			RA:SendCommMessage (RA.commPrefix, RA:Serialize (prefix, self.version or "", ...), "INSTANCE_CHAT", nil, nil, callback, callbackParam)
		else
			RA:SendCommMessage (RA.commPrefix, RA:Serialize (prefix, self.version or "", ...), "RAID", nil, nil, callback, callbackParam)
		end
	elseif (channel == "PARTY-NOINSTANCE") then
		if (IsInGroup ()) then
			RA:SendCommMessage (RA.commPrefix, RA:Serialize (prefix, self.version or "", ...), "PARTY", nil, nil, callback, callbackParam)
		end
	elseif (channel == "PARTY") then
		if (IsInGroup ()) then
			RA:SendCommMessage (RA.commPrefix, RA:Serialize (prefix, self.version or "", ...), "INSTANCE_CHAT", nil, nil, callback, callbackParam)
		else
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
	return a table where the first index is the specialization ID and the other 7 indexes are the IDs for the chosen talents.
--]=]
function RA:GetTalents()
	return {}
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

local ENCOUNTER_ID_MAP = {
	[16028] = LBB["Patchwerk"]
}
--[=[
	GetEncounterName (encounter_id)
	return the encounter name from a encounter id.
--]=]
function RA:GetEncounterName (encounterId)
	return ENCOUNTER_ID_MAP[encounterId] or ""
end

--[=[
	GetCurrentRaidEncounterList()
	return a table with encounter names from the current raid.
--]=]

local raid_list = {
	-- [mapid from GetInstanceInfo()] = {ejid, {cleu ids}}
	[1861] = {1031, {2144, 2141, 2128, 2136, 2134, 2145, 2135, 2122}}, --uldir
	[2070] = {1176, {2265, 2263, 2266, 2271, 2268, 2272, 2276, 2280, 2281}}, --battle for dazar'alor
	
	--the eternal palace
	
	--{MapID} = { instanceIJID , {Cleu IDs}},
	--2298 Abyssal Commander Sivara
	--2305 radiance of azshara
	--2289 blackwater behemoth
	--2304 lady sahvane
	--2303 orgozoa
	--2311 the queen's court
	--2293 za'qul
	--2299 queen azshara
	--
	
	--instance info maop id | ejid | cleu boss combat log ids
	[2164] = {1179, {2298, 2305, 2289, 2304, 2303, 2311, 2293, 2299}},
	
}


local empty_table = {}
function RA:GetCurrentRaidEncounterList (mapid)
	local zoneName, zoneType, _, _, _, _, _, zoneMapID = GetInstanceInfo()
	if (mapid) then
		zoneMapID = mapid
	end
	local EJ_id, true_encounter_ids = unpack (raid_list [zoneMapID] or empty_table)
	if (EJ_id) then
		DF.EncounterJournal.EJ_SelectInstance (EJ_id)
		local bosses = {}
		for i = 1, 99 do
			local boss_name = DF.EncounterJournal.EJ_GetEncounterInfoByIndex (i, EJ_id)
			if (boss_name) then
				tinsert (bosses, {boss_name, true_encounter_ids [i]})
			else
				break
			end
		end
		return bosses
	else
		return {}
	end
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

	[2031] = { --argus
		248165,
		248396,
		257299,
		248317,
		251570,
		255826,
		258399,
		250669,
		248499,
		257296,
	},

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
	
	--Uldir
	[1031] = {
		2168, 2167, 2146, 2169, 2166, 2195, 2194, 2147,
		[2168] = 2144, --Taloc
		[2167] = 2141, --MOTHER
		[2146] = 2128, --Fetid Devourer
		[2169] = 2136, --Zek'voz, Herald of N'zoth
		[2166] = 2134, --Vectis
		[2195] = 2145, --Zul, Reborn
		[2194] = 2135, --Mythrax the Unraveler
		[2147] = 2122, --G'huun
	},
	
	--Battle of Daraz'alor
	[1176] = {
		2333, 2325, 2341, 2342, 2330, 2335, 2334, 2337, 2343,
		[2333] = 2265, --Champion of the Light
		[2325] = 2263, --Grong, the Jungle Lord
		[2341] = 2266, --Jadefire Masters
		[2342] = 2271, --Opulence
		[2330] = 2268, --Conclave of the Chosen
		[2335] = 2272, --King Rastakhan
		[2334] = 2276, --High Tinker Mekkatorque
		[2337] = 2280, --Stormwall Blockade
		[2343] = 2281, --Lady Jaina Proudmoore
	},
	
	[1179] = {
		2298, 2305, 2289, 2304, 2303, 2311, 2293, 2299,
		[2352] = 2298, --Abyssal Commander Sivara
		[2347] = 2289, --Blackwater Behemoth
		[2353] = 2305, --Radiance of Azshara
		[2354] = 2304, --Lady Ashvane
		[2351] = 2303, --Orgozoa
		[2359] = 2311, --The Queen's Court
		[2349] = 2293, --Za'qul, Harbinger of Ny'alotha
		[2361] = 2299, --Queen Azshara

	},
}

local combat_log_ids = {
	--[instance EJID] = { --[boss Combatlog ID] = boss EJID}
	
	--Uldir
	[1031] = {
		2144, 2141, 2128, 2136, 2134, 2145, 2135, 2122,
		[2144] = 2168, --Taloc
		[2141] = 2167, --MOTHER
		[2128] = 2146, --Fetid Devourer
		[2136] = 2169, --Zek'voz
		[2134] = 2166, --Vectis
		[2145] = 2195, --Zul
		[2135] = 2194, --Mythrax the Unraveler
		[2122] = 2147, --G'huun
	},
	
	--Battle of Daraz'alor
	[1176] = {
		2265, 2263, 2266, 2271, 2268, 2272, 2276, 2280, 2281,
		[2265] = 2333, --Champion of the Light
		[2263] = 2325, --Grong, the Jungle Lord
		[2266] = 2341, --Jadefire Masters
		[2271] = 2342, --Opulence
		[2268] = 2330, --Conclave of the Chosen
		[2272] = 2335, --King Rastakhan
		[2276] = 2334, --High Tinker Mekkatorque
		[2280] = 2337, --Stormwall Blockade
		[2281] = 2343, --Lady Jaina Proudmoore
	},
	
	[1179] = {
		2352, 2347, 2353, 2354, 2351, 2359, 2349, 2361,
		[2352] = 2352, --Abyssal Commander Sivara
		[2347] = 2347, --Blackwater Behemoth
		[2353] = 2353, --Radiance of Azshara
		[2354] = 2354, --Lady Ashvane
		[2351] = 2351, --Orgozoa
		[2359] = 2359, --The Queen's Court
		[2349] = 2349, --Za'qul, Harbinger of Ny'alotha
		[2361] = 2361, --Queen Azshara

	},

}

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


