
local RA = RaidAssist
local L = LibStub ("AceLocale-3.0"):GetLocale ("RaidAssistAddon")
local _ 
local default_priority = 14

--battle res default config
local default_config = {
	enabled = false,
	menu_priority = 1,
	saved_lists = {},
	latest_raid_map = 536, -- nax for now
}

-- raid leader query for a single user
local COMM_QUERY_USERLIST = "BISU"
-- raid leader query the entire raid
local COMM_QUERY_RAIDLIST = "BISR"
-- a user sent the list
local COMM_RECEIVED_LIST = "BISL"

local icon_texture = [[Interface\PaperDollInfoFrame\UI-EquipmentManager-Toggle]]
local icon_texcoord = {l=0.078125, r=0.921875, t=0.078125, b=0.921875}
local text_color_enabled = {r=1, g=1, b=1, a=1}
local text_color_disabled = {r=0.5, g=0.5, b=0.5, a=1}

if (_G ["RaidAssistBisListRaid"]) then
	return
end
local BisListRaid = {version = "v0.1", pluginname = "BisListRaid"}
_G ["RaidAssistBisListRaid"] = BisListRaid

BisListRaid.IsDisabled = false
--BisListRaid.IsDisabled = false

local BisList = _G ["RaidAssistBisList"]

local can_install = false

BisListRaid.last_data_request = 0
BisListRaid.last_data_sent = 0

BisListRaid.menu_text = function (plugin)
	if (BisListRaid.db.enabled) then
		return icon_texture, icon_texcoord, "Loot (Raid List)", text_color_enabled
	else
		return icon_texture, icon_texcoord, "Loot (Raid List)", text_color_disabled
	end
end

BisListRaid.menu_popup_show = function (plugin, ct_frame, param1, param2)
	RA:AnchorMyPopupFrame (BisListRaid)
end

BisListRaid.menu_popup_hide = function (plugin, ct_frame, param1, param2)
	BisListRaid.popup_frame:Hide()
end

BisListRaid.menu_on_click = function (plugin)
	--RA.OpenMainOptions (BisListRaid)
end

BisListRaid.OnInstall = function (plugin)

	BisListRaid.db.menu_priority = default_priority

	BisListRaid:RegisterForEnterRaidGroup (BisListRaid.OnEnterRaidGroup)
	BisListRaid:RegisterForLeaveRaidGroup (BisListRaid.OnLeaveRaidGroup)
	
	--C_Timer.After (5, BisListRaid.menu_on_click)
	
	BisListRaid.main_frame:SetScript ("OnShow", function()
		BisListRaid.QueryData()
	end)
end

BisListRaid.OnEnable = function (plugin)
	-- enabled from the options panel.
	BisListRaid:RefreshResFrame()
end

BisListRaid.OnDisable = function (plugin)
	-- disabled from the options panel.

end

BisListRaid.OnProfileChanged = function (plugin)
	if (plugin.db.enabled) then
		BisListRaid.OnEnable (plugin)
		BisListRaid:RefreshResFrame()
	else
		BisListRaid.OnDisable (plugin)
	end
	
	if (plugin.options_built) then
		plugin.main_frame:RefreshOptions()
	end
end

function BisListRaid.QueryData()
	if (BisListRaid.last_data_request+30 > time() or not BisListRaid.playerIsInGroup or not IsInRaid () or not BisListRaid:UnitHasAssist ("player")) then
		return
	end
	BisListRaid:SendPluginCommMessage ("BLR", "RAID-NOINSTANCE", _, _, BisListRaid:GetPlayerNameWithRealm())
	BisListRaid.last_data_request = time()
end

function BisListRaid.OnEnterRaidGroup()
	BisListRaid.QueryData()
end

function BisListRaid.OnLeaveRaidGroup()
	return
end

function BisListRaid.OnShowOnOptionsPanel()
	local OptionsPanel = BisListRaid.OptionsPanel
	BisListRaid.BuildOptions (OptionsPanel)
end

function BisListRaid.BuildOptions (frame)
	
	if (frame.FirstRun) then
		return
	end
	frame.FirstRun = true	
	
	--window object
	local main_frame = frame
	BisListRaid.main_frame = frame
	main_frame:SetSize (722, 385)

	local fill_panel = BisListRaid:CreateFillPanel (frame, {}, 890, 460, false, false, false, {rowheight = 16}, "fill_panel", "RaidBisListFillPanel")
	fill_panel:SetPoint ("topleft", frame, "topleft", -10, -30)
	
	
	function main_frame:Refresh()
		--> refresh the panel
		
		local header = {{name = "Player Name", type = "text", width = 120}, {name = "Item", type = "text", width = 650}}
		local players = {}
		-- all players saved
		for playerName, itemString in pairs (BisListRaid.db.saved_lists) do --> for each player in the saved list
			
			-- remove the realm name
			local name = playerName:gsub ("-.*", "")
			
			-- is the player in the raid right now?
			if name then--if (UnitInRaid (playerName) or UnitInRaid (name)) then -- and (UnitIsConnected (playerName) or UnitIsConnected (name))
			
				local str = ""
				for slot, item in pairs ({strsplit (",", itemString)}) do -- for each item in the player bis list
					local itemId, haveIt, itemDiff = strsplit (":", item)
					itemId = tonumber (itemId)
					if (haveIt == "0") then
						local itemName, itemLink, _, itemLevel, _, itemType, itemSubType, _, _, itemTexture = GetItemInfo (itemId)
						if (itemLink) then
							str = str .. "|TInterface\\Glues\\LOGIN\\Glues-CheckBox-Check:32:32|t" .. itemLink .. " "
						end
						
					elseif (haveIt == "1") then
					
						local itemName, itemLink, _, itemLevel, _, itemType, itemSubType, _, _, itemTexture = GetItemInfo (itemId)
						if (itemLink) then
							str = str .. "|TInterface\\AddOns\\" .. RA.InstallDir .. "\\media\\Check:32:32|t" .. itemLink .. " "
						end
					end
				end

				tinsert (players, {name, str})
				
			end
		end
		
		local sort_alphabetical = function(a, b) return a[1] < b[1] end
		sort (players, sort_alphabetical)
		
		frame.fill_panel:SetFillFunction (function (index) return players [index] end)
		frame.fill_panel:SetTotalFunction (function() return #players end)
		
		frame.fill_panel:UpdateRows (header)
		frame.fill_panel:Refresh()
		
	end
	
	--select encounter dropdown
	local on_select_boss = function (_, _, encounter_id)
		main_frame:Refresh()
	end
	
	local dropdown_build_encounter_list = function()
		local isIn, type = IsInInstance()
		local mapid = GetCurrentMapAreaID()
		if (not isIn or type ~= "raid") then
			mapid = 536 -- naxx for now
		end
		local encounters = BisListRaid:GetCurrentRaidEncounterList (mapid)
		local t = {}
		for index, encounter in ipairs (encounters) do
			local bossname, encounterid = unpack (encounter)
			tinsert (t, {value = encounterid, label = bossname, onclick = on_select_boss})
		end
		
		return t
	end
	
	local label_boss = BisListRaid:CreateLabel (main_frame, "Boss" .. ": ", BisListRaid:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
	local dropdown_boss = BisListRaid:CreateDropDown (main_frame, dropdown_build_encounter_list, 1, 160, 20, "dropdown_boss_list", _, BisListRaid:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"))
	dropdown_boss:SetPoint ("left", label_boss, "right", 2, 0)
	label_boss:SetPoint (10, -10)

	local sync_func = function()
		BisListRaid:SendPluginCommMessage (COMM_QUERY_RAIDLIST, "RAID", nil, nil, BisListRaid:GetPlayerNameWithRealm())
	end
	local sync_button =  BisListRaid:CreateButton (main_frame, sync_func, 100, 20, "Sync", _, _, _, "button_sync", _, _, BisListRaid:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"), BisListRaid:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
	sync_button:SetPoint ("left", dropdown_boss, "right", 2, 0)
	sync_button:SetIcon ([[Interface\BUTTONS\UI-RefreshButton]], 14, 14, "overlay", {0, 1, 0, 1}, {1, 1, 1}, 2, 1, 0)
	
	
	dropdown_boss:Select (1, true)
	main_frame:Refresh()
end

if (can_install) then
	local install_status = RA:InstallPlugin ("BisListRaid", "RABisListRaid", BisListRaid, default_config)
end

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


function BisListRaid.SendMyBisList()
	--> only send at minimum of 30 seconds
	if (BisListRaid.last_data_sent+30 > time()) then
		if (BisListRaid.sending_timer and not BisListRaid.sending_timer._cancelled) then
			BisListRaid.sending_timer:Cancel()
		end
		BisListRaid.sending_timer = C_Timer.NewTimer (BisListRaid.last_data_sent+30-time(), BisListRaid.SendMyBisList)
		return
	end
	
	--> build the list
	local bislist = BisList:GetCharacterItemList()
	local current_items = BisList:GetMyItems()
	
	local s = ""
	for index, item_id in ipairs (bislist or {}) do
		s = s .. item_id .. ":" .. current_items [index] .. ","
		
	end
	--> send the list
	BisListRaid:SendPluginCommMessage (COMM_RECEIVED_LIST, "RAID", nil, nil, BisListRaid:GetPlayerNameWithRealm(), s)
	BisListRaid.last_data_sent = time()
end

function BisListRaid.StoreReceivedBisList (playerName, itemString)
	BisListRaid.db.saved_lists [playerName] = itemString
	if (BisListRaid.main_frame:IsShown()) then
		BisListRaid.main_frame:Refresh()
	end
end

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function BisListRaid.OnReceiveComm (prefix, sourcePluginVersion, sourceUnit, bisListReceived)

	--> received a list from a user
	if (prefix == COMM_RECEIVED_LIST) then
	
		BisListRaid.StoreReceivedBisList (sourceUnit, bisListReceived)
	
	--> raid leader requested the list for the entire raid
	--> raid leader requested the list only for a single user
	elseif (prefix == COMM_QUERY_RAIDLIST or prefix == COMM_QUERY_USERLIST) then
		--> are we on a local raid group?
		if (not IsInRaid ()) then
			return
		end
		--> who requested is the raid leader
		if (not RA:UnitIsRaidLeader (sourceUnit)) then
			return
		end
		--> send the list
		BisListRaid.SendMyBisList()
	end


end

RA:RegisterPluginComm (COMM_QUERY_USERLIST, BisListRaid.OnReceiveComm)
RA:RegisterPluginComm (COMM_QUERY_RAIDLIST, BisListRaid.OnReceiveComm)
RA:RegisterPluginComm (COMM_RECEIVED_LIST, BisListRaid.OnReceiveComm)

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


