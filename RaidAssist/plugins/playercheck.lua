
local DF = DetailsFramework
local RA = RaidAssist
local L = LibStub ("AceLocale-3.0"):GetLocale ("RaidAssistAddon")
local _ 
local default_priority = 19

local LibGroupInSpecT = LibStub:GetLibrary ("LibGroupInSpecT-1.1")

if (_G ["RaidAssistPlayerCheck"]) then
	return
end
local PlayerCheck = {
	last_data_sent = 0,
	player_data = {},
	version = "v0.1",
	pluginname = "PlayerCheck"
}
_G ["RaidAssistPlayerCheck"] = PlayerCheck

--PlayerCheck.IsDisabled = true
local can_install = false
local can_install = true

local default_config = {
	leader_request_interval = 600,
}

local COMM_REQUEST_DATA = "PCR"
local COMM_RECEIVED_DATA = "PCD"
local COMM_RECEIVED_LATENCY = "PCL"

local icon_texcoord = {l=0, r=1, t=0, b=1}
local icon_texture = [[Interface\CURSOR\thumbsup]]
local text_color_enabled = {r=1, g=1, b=1, a=1}
local text_color_disabled = {r=0.5, g=0.5, b=0.5, a=1}

PlayerCheck.menu_text = function (plugin)
	if (PlayerCheck.db.enabled) then
		return icon_texture, icon_texcoord, "Player Check", text_color_enabled
	else
		return icon_texture, icon_texcoord, "Player Check", text_color_disabled
	end
end

PlayerCheck.menu_popup_show = function (plugin, ct_frame, param1, param2)
	RA:AnchorMyPopupFrame (PlayerCheck)
end

PlayerCheck.menu_popup_hide = function (plugin, ct_frame, param1, param2)
	PlayerCheck.popup_frame:Hide()
end

PlayerCheck.menu_on_click = function (plugin)
	--if (not PlayerCheck.options_built) then
	--	PlayerCheck.BuildOptions()
	--	PlayerCheck.options_built = true
	--end
	--PlayerCheck.main_frame:Show()
	
	RA.OpenMainOptions (PlayerCheck)
end

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--> every 30 seconds if out of combat, send a latency update.
local func_latency_ticker = function()
	local w, h = PlayerCheck:GetLatency()
	PlayerCheck:SendPluginCommMessage (COMM_RECEIVED_LATENCY, "RAID-NOINSTANCE", _, _, PlayerCheck:GetPlayerNameWithRealm(), w, h)
end

function PlayerCheck:StartLatencyTicker()
	if (not PlayerCheck.LatencyTicker or PlayerCheck.LatencyTicker._cancelled) then
		PlayerCheck.LatencyTicker = C_Timer.NewTicker (30, func_latency_ticker)
	end
end

function PlayerCheck:StopLatencyTicker()
	if (PlayerCheck.LatencyTicker and not PlayerCheck.LatencyTicker._cancelled) then
		PlayerCheck.LatencyTicker:Cancel()
	end
end

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--> if we are the leader, we can ask for information when out of combat
local func_requestdata_ticker = function()
	if (not InCombatLockdown()) then
		PlayerCheck:SendPluginCommMessage (COMM_REQUEST_DATA, "RAID-NOINSTANCE", _, _, PlayerCheck:GetPlayerNameWithRealm())
	end
end

function PlayerCheck:StartDataRequestTicker()
	if (not PlayerCheck.LeaderRequestTicker or PlayerCheck.LeaderRequestTicker._cancelled) then
		PlayerCheck.LeaderRequestTicker = C_Timer.NewTicker (PlayerCheck.db.leader_request_interval, func_requestdata_ticker)
	end
end

function PlayerCheck:StopDataRequestTicker()
	if (PlayerCheck.LeaderRequestTicker and not PlayerCheck.LeaderRequestTicker._cancelled) then
		PlayerCheck.LeaderRequestTicker:Cancel()
	end
end

function PlayerCheck:CheckLeadership()
	if (UnitIsGroupLeader ("player")) then
		PlayerCheck:StartDataRequestTicker()
	else
		PlayerCheck:StopDataRequestTicker()
	end	
end

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

PlayerCheck.OnInstall = function (plugin)
	PlayerCheck.db.menu_priority = default_priority

	local popup_frame = PlayerCheck.popup_frame
	local main_frame = PlayerCheck.main_frame
	
	PlayerCheck:RegisterPluginComm (COMM_REQUEST_DATA, PlayerCheck.PluginCommReceived)
	PlayerCheck:RegisterPluginComm (COMM_RECEIVED_DATA, PlayerCheck.PluginCommReceived)
	PlayerCheck:RegisterPluginComm (COMM_RECEIVED_LATENCY, PlayerCheck.PluginCommReceived)
	LibGroupInSpecT.RegisterCallback (PlayerCheck, "GroupInSpecT_Update", "LibGroupInSpecT_UpdateReceived")
	
	main_frame:RegisterEvent ("PARTY_MEMBERS_CHANGED")
	main_frame:RegisterEvent ("RAID_ROSTER_UPDATE")
	main_frame:SetScript ("OnEvent", function (self, event, ...)
		if (event == "PARTY_MEMBERS_CHANGED" or event == "RAID_ROSTER_UPDATE") then
			PlayerCheck:GroupUpdate()
		end
	end)
	PlayerCheck:GroupUpdate()
end

--> after joining a raid group, send a welcome with our base data
local delayed_send_data = function()
	if (IsInRaid ()) then
		PlayerCheck:SendData()
	end
end

--> on group roster update
function PlayerCheck:GroupUpdate()
	if (IsInRaid ()) then
		if (not PlayerCheck.InGroup) then
			--> we are in group now
			PlayerCheck.InGroup = true
			--> random delay to send the initial welcome data
			--C_Timer.After (10 + math.random (10), delayed_send_data)
			C_Timer.After (3, delayed_send_data)
			--> send the latency periodically
			PlayerCheck:StartLatencyTicker()
		end
	else
		if (PlayerCheck.InGroup) then
			PlayerCheck.InGroup = false
			PlayerCheck:StopLatencyTicker()
		end
	end
	
	PlayerCheck:CheckLeadership()
end

PlayerCheck.OnEnable = function (plugin)
	-- enabled from the options panel.
	PlayerCheck.OnInstall (plugin)
end

PlayerCheck.OnDisable = function (plugin)
	-- disabled from the options panel.
	PlayerCheck:UnregisterPluginComm (COMM_REQUEST_DATA, PlayerCheck.PluginCommReceived)
	PlayerCheck:UnregisterPluginComm (COMM_RECEIVED_DATA, PlayerCheck.PluginCommReceived)
	PlayerCheck:UnregisterPluginComm (COMM_RECEIVED_LATENCY, PlayerCheck.PluginCommReceived)
	LibGroupInSpecT.UnregisterCallback (PlayerCheck, "GroupInSpecT_Update")
	PlayerCheck.main_frame:UnregisterEvent ("PARTY_MEMBERS_CHANGED")
	PlayerCheck.main_frame:UnregisterEvent ("RAID_ROSTER_UPDATE")
	PlayerCheck:StopLatencyTicker()
	PlayerCheck:StopDataRequestTicker()
end

PlayerCheck.OnProfileChanged = function (plugin)
	if (plugin.db.enabled) then
		PlayerCheck.OnEnable (plugin)
	else
		PlayerCheck.OnDisable (plugin)
	end
	
	if (plugin.options_built) then
		plugin.main_frame:RefreshOptions()
	end
end

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--get the player item level
function PlayerCheck:GetItemLevel()
	local overall, equipped = 0, 0
	if GearScore_GetScore then
		equipped, overall = GearScore_GetScore(UnitName("player"), "player")
	end
	return equipped, overall
end

--get the player ping
function PlayerCheck:GetLatency()
	local latencyWorld = select(3, GetNetStats())
	return latencyWorld
end

--get the% of repair and missing gems and enchants
function PlayerCheck:GetRepairAndMissingAdds()
	local repair_percent = PlayerCheck:GetRepairStatus()
	local missing_enchants, missing_gems = PlayerCheck:GetSloppyEquipment()
	return repair_percent, missing_enchants, missing_gems
end

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--local spec_id, spec_name, spec_description, spec_icon, spec_background, spec_role, spec_class = GetSpecializationInfoByID (spec or 0)
--local talentID, name, texture, selected, available = GetTalentInfoByID (talents [i])

--> raid leader requested data
function PlayerCheck:SendData()
	if (PlayerCheck.last_data_sent + 20 < time()) then
		local worldLatency = PlayerCheck:GetLatency()
		local equippedILevel, totalIlevel = PlayerCheck:GetItemLevel()
		local repairPercent, noEnchants, noGems = PlayerCheck:GetRepairAndMissingAdds()
		for id, slot in ipairs (noGems) do
			tinsert (noEnchants, slot)
		end
		local specTalents = PlayerCheck:GetTalents()
	
		PlayerCheck:SendPluginCommMessage (COMM_RECEIVED_DATA, "RAID-NOINSTANCE", _, _, PlayerCheck:GetPlayerNameWithRealm(), worldLatency, equippedILevel, totalIlevel, repairPercent, noEnchants, specTalents)
		PlayerCheck.last_data_sent = time()
	end
end

local postpone_send_data = function()
	if (not PlayerCheck.PostponeTicker or PlayerCheck.PostponeTicker._cancelled) then
		PlayerCheck.PostponeTicker = C_Timer.NewTicker (10, PlayerCheck.PostponeSendData)
	end
end
function PlayerCheck:PostponeSendData()
	if (not InCombatLockdown() and IsInRaid ()) then
		PlayerCheck:SendData()
		if (PlayerCheck.PostponeTicker and not PlayerCheck.PostponeTicker._cancelled) then
			PlayerCheck.PostponeTicker:Cancel()
		end
	elseif (not IsInRaid ()) then
		if (PlayerCheck.PostponeTicker and not PlayerCheck.PostponeTicker._cancelled) then
			PlayerCheck.PostponeTicker:Cancel()
		end
	end
end

--> on receive a comm
function PlayerCheck.PluginCommReceived (prefix, sourcePluginVersion, player_name, lag_w, ilvl_e, ilvl_t, repair, missing_adds, spec_stalents)

--	print (player_name, lag_w, ilvl_e, ilvl_t, repair, missing_adds, spec_stalents)
	
	if (prefix == COMM_REQUEST_DATA) then
		--> leader requested data
		if (PlayerCheck:UnitIsRaidLeader (player_name)) then
			if (InCombatLockdown()) then
				postpone_send_data()
			else
				PlayerCheck:SendData()
			end
		end
		
	elseif (prefix == COMM_RECEIVED_LATENCY) then
		--only latency
		local t = PlayerCheck.player_data [player_name] or {}
		
		t [1] = t [1] or 0
		t [2] = t [2] or 0
		t [3] = lag_w
		t [4] = lag_l
		t [5] = t [5] or 0
		t [6] = t [6] or {}
		t [7] = t [7] or ""
		
		PlayerCheck.player_data [player_name] = t
		
		if (PlayerCheckFillPanel and PlayerCheckFillPanel:IsShown()) then
			if (PlayerCheck.update_PlayerCheck and PlayerCheck.fill_panel) then
				PlayerCheck.update_PlayerCheck (PlayerCheck.fill_panel)
			end
		end
		
	elseif (prefix == COMM_RECEIVED_DATA) then
		--entire data
		local t = PlayerCheck.player_data [player_name] or {}
		
		t [1] = ilvl_e or t [1] or 0
		t [2] = ilvl_t or t [2] or 0
		t [3] = lag_w or t [3] or 0
		t [4] = lag_l or t [4] or 0
		t [5] = repair or t [5] or 0
		t [6] = missing_adds or t [6] or {}
		t [7] = spec_stalents or t [7] or ""
		
		PlayerCheck.player_data [player_name] = t
		
		if (PlayerCheckFillPanel and PlayerCheckFillPanel:IsShown()) then
			if (PlayerCheck.update_PlayerCheck and PlayerCheck.fill_panel) then
				PlayerCheck.update_PlayerCheck (PlayerCheck.fill_panel)
			end
		end
	end
end

function PlayerCheck:LibGroupInSpecT_UpdateReceived (event, guid, unitid, info)

	if (info and info.name) then
		local name = info.name:find ("%-") and info.name:gsub ("%-.*", "") or info.name
		name = info.name .. "-" .. (info.realm or GetRealmName())
		
		local t = PlayerCheck.player_data [name] or {}
		t [1] = t [1] or 0
		t [2] = t [2] or 0
		t [3] = t [3] or 0
		t [4] = t [4] or 0
		t [5] = t [5] or 0
		t [6] = t [6] or {}
		t [7] = t [7] or ""
		
		if (PlayerCheckFillPanel and PlayerCheckFillPanel:IsShown()) then
			if (PlayerCheck.update_PlayerCheck and PlayerCheck.fill_panel) then
				PlayerCheck.update_PlayerCheck (PlayerCheck.fill_panel)
			end
		end
	end
end

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function PlayerCheck.OnShowOnOptionsPanel()
	local OptionsPanel = PlayerCheck.OptionsPanel
	PlayerCheck.BuildOptions (OptionsPanel)
end

PlayerCheck.update_PlayerCheck = function (fill_panel, export)

	local current_db = PlayerCheck.player_data
	if (current_db) then
	
		--> alphabetical order
		local alphabetical_players = {}
		for playername, table in pairs (current_db) do
			tinsert (alphabetical_players, {playername, table})
		end
		
		table.sort (alphabetical_players, function (t1, t2) return t2[1] < t1[1] end)			

		--add the two initial headers for player name and total PlayerCheck
		local header = {
			{name = "Player Name", type = "text", width = 120},
			{name = "Latency", type = "text", width = 60},
			{name = "Item Level", type = "text", width = 60},
			{name = "Repair %", type = "text", width = 60},
			{name = "No Enchant/Gem", type = "text", width = 120},
			{name = "Talents", type = "text", width = 120},
		}

		local get_latency_color = function (latency)
			if (latency < 300) then
				return "|cFF33FF33" .. latency .. "|r"
			elseif (latency < 600) then
				return "|cFFFFFF33" .. latency .. "|r"
			else
				return "|cFFFF3333" .. latency .. "|r"
			end
		end
		
		local get_repair_color = function (repair_percent)
			local r, g, b = PlayerCheck:PercentColor (repair_percent)
			r = RA:Hex (floor (r*255))
			g = RA:Hex (floor (g*255))
			b = RA:Hex (floor (b*255))
			return "|cFF" .. r .. g .. b .. repair_percent .. "|r"
		end
		
		local get_missing_color = function (amt)
			if (amt == 0) then
				return ""
			elseif (amt < 3) then
				return "|cFFFFFF33" .. amt .. "|r"
			else
				return "|cFFFF3333" .. amt .. "|r"
			end
		end
		
		fill_panel:SetFillFunction (function (index) 
			
			local name = alphabetical_players [index][1]
			local t = alphabetical_players [index][2]
			
			local latency = get_latency_color (t[3] or 0)
			
			local item_level = floor (t[1] or 0) .. " | " .. floor (t[2] or 0)
			local repair = get_repair_color (floor (t[5] or 0))
			
			local missing_enchants = ""
			local missing_enchants_amt = 0
			for index, slot in ipairs (t [6] or {}) do
				missing_enchants = missing_enchants .. slot .. " "
				missing_enchants_amt = missing_enchants_amt + 1
			end
			
			missing_enchants_amt = get_missing_color (missing_enchants_amt)
			
			local talents = t [7]

			return {name, latency, item_level, repair, missing_enchants_amt, talents}
		end)

		fill_panel:SetTotalFunction (function() return #alphabetical_players end)
		fill_panel:SetSize (math.min (GetScreenWidth()-200, (#header*60) + 60), 450)
		fill_panel:UpdateRows (header)
		fill_panel:Refresh()
	end
end

function PlayerCheck.BuildOptions (frame)
	
	if (frame.FirstRun) then
		return
	end
	frame.FirstRun = true
	
	local fill_panel = PlayerCheck:CreateFillPanel (frame, {}, 790, 460, false, false, false, {rowheight = 16}, "fill_panel", "PlayerCheckFillPanel")
	PlayerCheck.fill_panel = fill_panel
	fill_panel:SetPoint ("topleft", frame, "topleft", 10, 0)

	frame:SetScript ("OnShow", function()
		PlayerCheck.update_PlayerCheck (PlayerCheck.fill_panel)
	end)
	
	PlayerCheck.update_PlayerCheck (PlayerCheck.fill_panel)
end

if (can_install) then
	local install_status = RA:InstallPlugin ("Player Check", "RAPlayerCheck", PlayerCheck, default_config)
end
