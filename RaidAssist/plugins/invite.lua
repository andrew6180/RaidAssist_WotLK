-- InviteUnit/AcceptGroup


local RA = RaidAssist
local L = LibStub ("AceLocale-3.0"):GetLocale ("RaidAssistAddon")
local _
local default_priority = 16

if (_G ["RaidAssistInvite"]) then
	return
end
local Invite = {version = "v0.1", pluginname = "Invites"}
_G ["RaidAssistInvite"] = Invite

local default_config = {
	presets = {},
	invite_msg = "[RA]: invites in 5 seconds.",
	invite_msg_repeats = true,
	auto_invite = false,
	auto_invite_limited = true,
	auto_invite_keywords = {},
	auto_accept_invites = false,
	auto_accept_invites_limited = true,
	invite_interval = 60,
}

local icon_texcoord = {l=1, r=0, t=0, b=1}
local text_color_enabled = {r=1, g=1, b=1, a=1}
local text_color_disabled = {r=0.5, g=0.5, b=0.5, a=1}
local icon_texture = [[Interface\CURSOR\Cast]]

Invite.menu_text = function (plugin)
	if (Invite.db.enabled) then
		return icon_texture, icon_texcoord, "Invites", text_color_enabled
	else
		return icon_texture, icon_texcoord, "Invites", text_color_disabled
	end
end

Invite.menu_popup_show = function (plugin, ct_frame, param1, param2)
	RA:AnchorMyPopupFrame (Invite)
end

Invite.menu_popup_hide = function (plugin, ct_frame, param1, param2)
	Invite.popup_frame:Hide()
end


Invite.menu_on_click = function (plugin)
	--if (not Invite.options_built) then
	--	Invite.BuildOptions()
	--	Invite.options_built = true
	--end
	--Invite.main_frame:Show()
	
	RA.OpenMainOptions (Invite)
	Invite.main_frame:RefreshPresetButtons()
	
	--C_Timer.After (0.1, Invite.create_new_preset)
end

Invite.OnInstall = function (plugin)

	Invite.db.menu_priority = default_priority

	if (not Invite.db.first_run) then
		tinsert (Invite.db.auto_invite_keywords, "inv")
		tinsert (Invite.db.auto_invite_keywords, "invite")
		Invite.db.first_run = true
	end

	local popup_frame = Invite.popup_frame
	
	Invite:RegisterEvent ("PARTY_INVITE_REQUEST")
	Invite:RegisterEvent ("CHAT_MSG_WHISPER")
	Invite:RegisterEvent ("CHAT_MSG_BN_WHISPER")

	--C_Timer.After (20, Invite.CheckForAutoInvites)
	C_Timer.After (20, Invite.CheckForAutoInvites)

	--Invite.db.auto_invite = false
	--Invite.db.auto_accept_invites = false

	--debug
	--C_Timer.After (1, Invite.menu_on_click)
end

Invite.OnEnable = function (plugin)
	-- enabled from the options panel.
	
end

Invite.OnDisable = function (plugin)
	-- disabled from the options panel.
	
end

Invite.OnProfileChanged = function (plugin)
	if (plugin.db.enabled) then
		Invite.OnEnable (plugin)
	else
		Invite.OnDisable (plugin)
	end
	
	if (plugin.options_built) then
		--plugin.main_frame:RefreshOptions()
	end
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--> track whispers

local handle_inv_text = function (message, from)
	for i = 1, #Invite.db.auto_invite_keywords do
	
		local LowMessage, LowKeyword = string.lower (message), string.lower (Invite.db.auto_invite_keywords [i])
		
		if (LowMessage == LowKeyword) then
			if (GetNumGroupMembers() == 5) then
				if (not IsInRaid()) then
					local in_instance, instance_type = IsInInstance()
					if (not in_instance or instance_type ~= "party") then
						ConvertToRaid()
					else
						return
					end
				end
			end
			InviteUnit (from)
		end
	end
end

local handle_inv_whisper = function (message, from)
	if (not from) then
		return
	end
	if (Invite.db.auto_invite) then
		if (Invite:IsInQueue()) then
			return
		elseif (Invite.db.auto_invite_limited) then
			if (Invite:IsBnetFriend (from) or Invite:IsFriend (from) or Invite:IsGuildFriend (from)) then
				handle_inv_text (message, from)
			end
		else
			handle_inv_text (message, from)
		end
	end
end

function Invite:CHAT_MSG_WHISPER (event, message, sender, language, channelString, target, flags, unknown, channelNumber, channelName, unknown, counter, guid)
	return handle_inv_whisper (message, sender)
end

function Invite:CHAT_MSG_BN_WHISPER (event, message, sender, unknown, unknown, unknown, unknown, unknown, unknown, unknown, unknown, counter, unknown, presenceID, unknown)
	local bnet_friends_amt = BNGetNumFriends()
	for i = 1, bnet_friends_amt do 
		local presenceID, presenceName, battleTag, isBattleTagPresence, toonName, toonID, client, isOnline, lastOnline, isAFK, isDND, messageText, noteText, isRIDFriend, broadcastTime, canSoR = BNGetFriendInfo (i)
		if (presenceName == sender) then
			return handle_inv_whisper (message, toonName)
		end
	end
	return handle_inv_whisper (message, sender)
end


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--> auto accept invites

local accept_group = function (from, source)
	AcceptGroup()
	StaticPopup_Hide ("PARTY_INVITE")
	StaticPopup_Hide ("PARTY_INVITE_XREALM")
--	Invite:Msg ("invite from " .. from .. " accepted (" .. (source == 1 and "|cFFFF5555accepting all invites|r") or (source == 2 and "|cff82c5ffbnet friend|r") or (source == 3 and "|cfffee05bfriend|r") or (source == 4 and "|cff40fb40guild member|r") .. ")")
end

function Invite:PARTY_INVITE_REQUEST (from)
	if (not Invite.db.auto_accept_invites) then
		return
	end
	
	if (Invite:IsInQueue()) then
		return
	elseif (not Invite.db.auto_accept_invites_limited) then
		return accept_group (from, 1)
	elseif (Invite:IsBnetFriend (from)) then
		return accept_group (from, 2)
	elseif (Invite:IsFriend (from)) then
		return accept_group (from, 3)
	elseif (Invite:IsGuildFriend (from)) then
		return accept_group (from, 4)
	end
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function Invite:GetAllPresets()
	return Invite.db.presets
end

function Invite:GetPreset (preset_number)
	return Invite.db.presets [preset_number]
end

function Invite:DeletePreset (preset_number)
	tremove (Invite.db.presets, preset_number)
	
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function Invite:GetScheduleCores()
	local RaidSchedule = _G ["RaidAssistRaidSchedule"]
	if (RaidSchedule) then
		return RaidSchedule.db.cores
	else
		return {}
	end
end

local empty_func = function()end

function Invite.OnShowOnOptionsPanel()
	local OptionsPanel = Invite.OptionsPanel
	Invite.BuildOptions (OptionsPanel)
end

function Invite.BuildOptions (frame)

	if (frame.FirstRun) then
		return
	end
	frame.FirstRun = true

	local main_frame = frame
	Invite.main_frame = frame
	main_frame:SetSize (400, 500)

	--- create panel precisa ser passado para dentro da janela, ficaria no lado esquerdo
	function Invite:CleanNewInviteFrames()
	
	end

	----------create new invite frames
	
		local panel = main_frame
		
		--preset name
		local label_preset_name = RA:CreateLabel (panel, "Preset Name" .. ": ", Invite:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
		local editbox_preset_name = RA:CreateTextEntry (panel, empty_func, 160, 20, "editbox_preset_name", _, _, Invite:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"))
		label_preset_name:SetPoint ("topleft", panel, "topleft", 10, -0)
		editbox_preset_name:SetPoint ("left", label_preset_name, "right", 2, 0)

		--guild rank to invite
		local welcome_text_create1 = RA:CreateLabel (panel, "When editing a profile, select here, which ranks will be invited,\nthe raid difficulty and additional assistants (if any):", Invite:GetTemplate ("font", "ORANGE_FONT_TEMPLATE"))
		welcome_text_create1:SetPoint ("topleft", panel, "topleft", 10, -35)
		
		local switchers = {}
		function Invite:UpdateRanksOnProfileCreation()
			local ranks = Invite:GetGuildRanks()
			--dos
			
			for i = 1, #switchers do
				local s = switchers[i]
				s:Hide()
				s.rank_label:Hide()
			end
			
			local x, y, b, i = 10, -60, 4, 1
			for rank_index, rank_name in pairs (ranks) do
			
				local switch = switchers [i]
			
				if (not switch) then
					local s, l = RA:CreateSwitch (panel, empty_func, false, 20, 26, _, _, "switch_rank" .. i, _, _, _, _, ranks [i], Invite:GetTemplate ("switch", "OPTIONS_CHECKBOX_TEMPLATE"), Invite:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
					l:ClearAllPoints()
					s:ClearAllPoints()
					s.rank_label = l
					l:SetPoint ("left", s, "right", 2, 0)
					switch = s
					switch:SetAsCheckBox()
					switch:SetPoint ("topleft", panel, "topleft", x, y)
					if (i > b) then
						y = y - 20
						x = 10
						b = b+5
					else
						x = x + 80
					end
					switchers [i] = switch
				end
				
				switch:Show()
				switch.rank_label:Show()
				switch.rank = rank_index
				switch.rank_label.text = rank_name
				
				i = i + 1
			end
		end
		
		--raid difficult
		local difficulty_table = {
			{value = 3, label = "Normal 10", onclick = empty_func},
			{value = 4, label = "Normal 25", onclick = empty_func},
			{value = 5, label = "Heroic 10", onclick = empty_func},
			{value = 6, label = "Heroic 25", onclick = empty_func},
		}
		local dropdown_diff_fill = function()
			return difficulty_table
		end
		local label_diff = RA:CreateLabel (panel, "Raid Difficulty" .. ": ", Invite:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
		local dropdown_diff = RA:CreateDropDown (panel, dropdown_diff_fill, 1, 160, 20, "dropdown_diff_preset", _, Invite:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"))
		dropdown_diff:SetPoint ("left", label_diff, "right", 2, 0)
		label_diff:SetPoint (10, -130)
		
		--master loot
		local label_masterloot_name = RA:CreateLabel (panel, "Assistants" .. ": ", Invite:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
		local editbox_masterloot_name = RA:CreateTextEntry (panel, empty_func, 200, 20, "editbox_masterloot_name", _, _, Invite:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"))
		editbox_masterloot_name:SetJustifyH ("left")
		editbox_masterloot_name.tooltip = "Separate player names with a space.\n\nIf the player is from a different realm, add the realm name too, example: Tercioo-Azralon."
		label_masterloot_name:SetPoint ("topleft", panel, "topleft", 10, -155)
		editbox_masterloot_name:SetPoint ("left", label_masterloot_name, "right", 2, 0)

		--raid leader
		local label_raidleader_name = RA:CreateLabel (panel, "Raid Leader" .. ": ", Invite:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
		local editbox_raidleader_name = RA:CreateTextEntry (panel, empty_func, 160, 20, "editbox_raidleader_name", _, _, Invite:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"))
		editbox_raidleader_name:SetJustifyH ("left")
		label_raidleader_name:SetPoint ("topleft", panel, "topleft", 10, -180)
		editbox_raidleader_name:SetPoint ("left", label_raidleader_name, "right", 2, 0)		

		--invite msg
		local label_invite_msg = RA:CreateLabel (panel, "Invite Message" .. ": ", Invite:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
		local editbox_invite_msg = RA:CreateTextEntry (panel, empty_func, 260, 20, "editbox_invite_msg", _, _, Invite:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"))
		editbox_invite_msg:SetJustifyH ("left")
		label_invite_msg:SetPoint ("topleft", panel, "topleft", 10, -205)
		editbox_invite_msg:SetPoint ("left", label_invite_msg, "right", 2, 0)		
		
		--keep auto inviting for X minutes
		local welcome_text_create2 = RA:CreateLabel (panel, "Auto Invite Settings:", Invite:GetTemplate ("font", "ORANGE_FONT_TEMPLATE"))
		welcome_text_create2:SetPoint ("topleft", panel, "topleft", 10, -230)
		
		local keep_auto_invite_table = {{value = 0, label = "disabled", onclick = empty_func}}
		for i = 2, 30 do
			keep_auto_invite_table [#keep_auto_invite_table+1] = {value = i, label = i .. " minutes", onclick = empty_func}
		end
		local keep_auto_invite_fill = function()
			return keep_auto_invite_table
		end
		local label_keep_auto_invite = RA:CreateLabel (panel, "Keep Inviting For" .. ": ", Invite:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
		local dropdown_keep_auto_invite = RA:CreateDropDown (panel, keep_auto_invite_fill, 1, 160, 20, "dropdown_keep_invites", _, Invite:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"))
		dropdown_keep_auto_invite:SetPoint ("left", label_keep_auto_invite, "right", 2, 0)
		label_keep_auto_invite:SetPoint (10, -275)
		
		--auto start inviting
		local auto_invite_switch, auto_invite_label = RA:CreateSwitch (panel, empty_func, false, _, _, _, _, "switch_auto_invite", _, _, _, _, "Auto Start Invites", Invite:GetTemplate ("switch", "OPTIONS_CHECKBOX_TEMPLATE"), Invite:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
		auto_invite_switch:SetAsCheckBox()
		auto_invite_label:SetPoint ("topleft", panel, "topleft", 10, -300)	
		
		local schedule_fill = function()
			local t = {}
			if (_G ["RaidAssistRaidSchedule"]) then
				local all_cores = Invite:GetScheduleCores()
				for i, core in pairs (all_cores) do
					t [#t+1] = {value = i, label = core.core_name, onclick = empty_func}
				end
			end
			return t
		end
		local label_schedule_select = RA:CreateLabel (panel, "Using this Raid Schedule" .. ": ", Invite:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
		local dropdown_schedule_select = RA:CreateDropDown (panel, schedule_fill, 1, 160, 20, "dropdown_schedule", _, Invite:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"))
		dropdown_schedule_select:SetPoint ("left", label_schedule_select, "right", 2, 0)
		label_schedule_select:SetPoint (10, -330)
		
		function Invite:ResetNewPresetPanel()
			editbox_preset_name.text = ""
			for i = 1, #switchers do
				local switch = switchers [i]
				switch:SetValue (false)
			end
			dropdown_diff:Select (1, true)
			editbox_masterloot_name.text = ""
			
			dropdown_keep_auto_invite:Select (0)
			auto_invite_switch:SetValue (false)
			dropdown_schedule_select:Select (1, true)
			
			panel.button_create_preset:SetText ("Create")
		end
		
		function Invite:ShowPreset (preset)
			editbox_preset_name.text = preset.name
			
			for i = 1, #switchers do
				local switch = switchers [i]
				switch:SetValue (false)
			end
			for this_rank, _ in pairs (preset.ranks) do
				for i = 1, #switchers do
					local switch = switchers [i]
					if (switch.rank == this_rank) then
						switch:SetValue (true)
						break
					end
				end
			end
			
			dropdown_diff:Select (preset.difficulty)
			editbox_masterloot_name.text = preset.masterloot or ""
			editbox_raidleader_name.text = preset.raidleader or ""
			editbox_invite_msg.text = preset.invite_msg or ""
			
			dropdown_keep_auto_invite:Select (preset.keepinvites)
			auto_invite_switch:SetValue (preset.autostart)
			dropdown_schedule_select:Select (preset.autostartcore)
		end
		
		function Invite:EditPreset (preset)
			editbox_preset_name.text = preset.name
			
			for i = 1, #switchers do
				local switch = switchers [i]
				switch:SetValue (false)
			end
			for this_rank, _ in pairs (preset.ranks) do
				for i = 1, #switchers do
					local switch = switchers [i]
					if (switch.rank == this_rank) then
						switch:SetValue (true)
						break
					end
				end
			end
			
			dropdown_diff:Select (preset.difficulty)
			editbox_masterloot_name.text = preset.masterloot or ""
			editbox_raidleader_name.text = preset.raidleader or ""
			editbox_invite_msg.text = preset.invite_msg or ""
			
			dropdown_keep_auto_invite:Select (preset.keepinvites)
			auto_invite_switch:SetValue (preset.autostart)
			dropdown_schedule_select:Select (preset.autostartcore)
			
			panel.button_create_preset:SetText ("Save")
			panel:Show()
		end
		
		function Invite.create_or_edit_preset()
			
			local preset_name = editbox_preset_name.text ~= "" and editbox_preset_name.text or " --no name--"
			local ranks = {}
			local raid_difficulty = dropdown_diff:GetValue()
			local master_loot = editbox_masterloot_name.text
			local raid_leader = editbox_raidleader_name.text
			local invite_msg = editbox_invite_msg.text
			local keep_inviting = dropdown_keep_auto_invite:GetValue()
			local auto_start_invites = auto_invite_switch:GetValue()
			local auto_start_core
			
			if (_G ["RaidAssistRaidSchedule"]) then
				local cores = Invite:GetScheduleCores()
				local dropdown_value = dropdown_schedule_select:GetValue()
				local coreTable = cores [dropdown_value]
				local coreName = coreTable and coreTable.core_name
				auto_start_core = coreName
			end
			
			local got_rank_selected
			for i = 1, #switchers do
				local switch = switchers [i]
				if (switch:GetValue()) then
					ranks [switch.rank] = GuildControlGetRankName (switch.rank)
					got_rank_selected = true
				end
			end
			
			if (not got_rank_selected) then
				return print ("No rank selected.")
			end
			
			if (Invite.is_editing) then
				local preset = Invite.is_editing_table
				preset.name = preset_name
				preset.ranks = ranks
				preset.difficulty = raid_difficulty
				preset.masterloot = master_loot
				preset.raidleader = raid_leader
				preset.invite_msg = invite_msg
				preset.keepinvites = keep_inviting
				preset.autostart = auto_start_invites
				preset.autostartcore = auto_start_core
			else
				local preset = {}
				preset.name = preset_name
				preset.ranks = ranks
				preset.difficulty = raid_difficulty
				preset.masterloot = master_loot
				preset.raidleader = raid_leader
				preset.invite_msg = invite_msg
				preset.keepinvites = keep_inviting
				preset.autostart = auto_start_invites
				preset.autostartcore = auto_start_core
				
				tinsert (Invite.db.presets, preset)
			end
			
			Invite.is_editing = nil
			Invite.is_editing_table = nil

			Invite:DisableCreatePanel()
			Invite:EnableInviteButtons()
			
			main_frame:RefreshPresetButtons()
		end
		
		--create button (confirm) // edit button is 'save'
		local create_button = RA:CreateButton (panel, Invite.create_or_edit_preset, 160, 20, "Create Preset", _, _, _, "button_create_preset", _, _, Invite:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"), Invite:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
		create_button.widget.texture_disabled:SetTexture ([[Interface\Tooltips\UI-Tooltip-Background]])
		create_button.widget.texture_disabled:SetVertexColor (0, 0, 0)
		create_button.widget.texture_disabled:SetAlpha (.5)
		
		create_button:SetPoint ("topleft", panel, "topleft", 10 , -375)
	
	------------------------ fim	


	Invite.create_new_preset = function()
		if (not Invite.create_preset_panel_built) then
			Invite:CleanNewInviteFrames()
			Invite.create_preset_panel_built = true
		end
		
		Invite.is_editing = nil
		Invite.is_editing_table = nil
		
		Invite:ResetNewPresetPanel()
		Invite:UpdateRanksOnProfileCreation()
		
		Invite:EnableCreatePanel()
		Invite:DisableInviteButtons()
	end
	
	local edit_preset = function()
		local dropdown_value = main_frame.dropdown_edit_preset:GetValue()
		if (type (dropdown_value) == "number" and Invite:GetPreset (dropdown_value)) then
			Invite.is_editing = true
			Invite.is_editing_table = Invite:GetPreset (dropdown_value)
			
			if (not Invite.EditPreset) then
				Invite:CleanNewInviteFrames()
			end
			Invite:UpdateRanksOnProfileCreation()
			
			Invite:EnableCreatePanel()
			Invite:EditPreset (Invite.is_editing_table)
			Invite:DisableInviteButtons()
		end
	end
	
	
	-------- Main widgets frames
		local x_start = 400
		
		--> welcome text
		local welcome_text1 = RA:CreateLabel (main_frame, "Create or select a invite preset. If the preset isn't set to auto start invites,\nclicking on it starts the inviting process.", Invite:GetTemplate ("font", "ORANGE_FONT_TEMPLATE"))
		welcome_text1:SetPoint ("topleft", main_frame, "topleft", x_start, 0)
		
		--> hold all preset buttons created
		local preset_buttons = {}
		
		--> no preset created yet
		local no_preset_text1 = RA:CreateLabel (main_frame, "There is no preset created yet.", Invite:GetTemplate ("font", "ORANGE_FONT_TEMPLATE"))
		no_preset_text1.color = "red"
		no_preset_text1:SetPoint ("topleft", main_frame, "topleft", x_start, -70)
		
		local select_preset_start_inviting = function (_, _, preset_number)
			Invite:StartInvites (preset_number)
		end
		
		--> update preset buttons when on frame show()
		function main_frame:RefreshPresetButtons()
			for i = 1, #preset_buttons do
				preset_buttons[i]:Hide()
			end
			
			local got_one
			local x, y = x_start, -70
			
			for i = 1, #Invite.db.presets do
				local preset = Invite.db.presets[i]
				local button = preset_buttons[i]
				if (not button) then
					button = RA:CreateButton (main_frame, select_preset_start_inviting, 110, 20, "", _, _, _, _, _, _, Invite:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"), Invite:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
					preset_buttons[i] = button
				end
				button:Show()
				button:SetText (preset.name)
				button:SetClickFunction (select_preset_start_inviting, i)
				
				button:ClearAllPoints()
				button:SetPoint ("topleft", main_frame, "topleft", x, y)
				x = x + 120
				if (i == 3 or i == 6) then
					y = y - 25
					x = x_start
				end
				
				got_one = true
			end
			
			if (got_one) then
				no_preset_text1:Hide()
			else
				no_preset_text1:Show()
			end
			
			main_frame.dropdown_edit_preset:Refresh()
			main_frame.dropdown_edit_preset:Select (1, true)
			main_frame.dropdown_remove_preset:Refresh()
			main_frame.dropdown_remove_preset:Select (1, true)
		end
		
		--> welcome text 2
		local welcome_text2 = RA:CreateLabel (main_frame, "Create, edit or remove a preset.", Invite:GetTemplate ("font", "ORANGE_FONT_TEMPLATE"))
		welcome_text2:SetPoint ("topleft", main_frame, "topleft", x_start, -145)
		
		local create_button = RA:CreateButton (main_frame, Invite.create_new_preset, 160, 20, "Create Preset", _, _, _, _, _, _, Invite:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"), Invite:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
		create_button:SetIcon ("Interface\\AddOns\\" .. RA.InstallDir .. "\\media\\plus", 10, 10, "overlay", {0, 1, 0, 1}, {1, 1, 1}, 3, 1, 0)
		create_button:SetPoint ("topleft", main_frame, "topleft", x_start , -165)
		
		--> edit dropdown
		local on_edit_select = function (_, _, preset)
			Invite:ShowPreset (Invite:GetPreset (preset))
			Invite:DisableCreatePanel()
			--InviteNewProfileFrame:Hide()
		end
		local dropdown_edit_fill = function()
			local t = {}
			for i, preset in ipairs (Invite.db.presets) do
				t [#t+1] = {value = i, label = preset.name, onclick = on_edit_select}
			end
			return t
		end
		local label_edit = RA:CreateLabel (main_frame, "Edit" .. ": ", Invite:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
		local dropdown_edit = RA:CreateDropDown (main_frame, dropdown_edit_fill, _, 160, 20, "dropdown_edit_preset", _, Invite:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"))
		dropdown_edit:SetPoint ("left", label_edit, "right", 2, 0)
		
		local button_edit = RA:CreateButton (main_frame, edit_preset, 80, 18, "Edit", _, _, _, _, _, _, Invite:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"), Invite:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
		button_edit:SetPoint ("left", dropdown_edit, "right", 2, 0)
		button_edit:SetIcon ([[Interface\BUTTONS\UI-OptionsButton]], 12, 12, "overlay", {0, 1, 0, 1}, {1, 1, 1}, 2, 1, 0)
		
		--> remove dropdown
		local dropdown_remove_fill = function()
			local t = {}
			for i, preset in ipairs (Invite.db.presets) do
				t [#t+1] = {value = i, label = preset.name, onclick = empty_func}
			end
			return t
		end
		local label_remove = RA:CreateLabel (main_frame, "Remove" .. ": ", Invite:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
		local dropdown_remove = RA:CreateDropDown (main_frame, dropdown_remove_fill, _, 160, 20, "dropdown_remove_preset", _, Invite:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"))
		dropdown_remove:SetPoint ("left", label_remove, "right", 2, 0)

		local remove_preset_table = function()
			local preset_number = dropdown_remove.value
			if (preset_number) then
				local preset = Invite:GetPreset (preset_number)
				if (preset) then
					if (Invite.is_editing and Invite.is_editing_table == preset) then
						--InviteNewProfileFrame:Hide()
						Invite.is_editing = nil
						Invite.is_editing_table = nil
					end
					Invite:DeletePreset (preset_number)
					main_frame:RefreshPresetButtons()
					dropdown_remove:Refresh()
					dropdown_remove:Select (1, true)
					dropdown_edit:Refresh()
					dropdown_edit:Select (1, true)
				end
			end
			
		end
		
		local button_remove = RA:CreateButton (main_frame, remove_preset_table, 80, 18, "Remove", _, _, _, _, _, _, Invite:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"), Invite:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
		button_remove:SetPoint ("left", dropdown_remove, "right", 2, 0)
		button_remove:SetIcon ([[Interface\BUTTONS\UI-StopButton]], 14, 14, "overlay", {0, 1, 0, 1}, {1, 1, 1}, 2, 1, 0)
		
		label_edit:SetPoint ("topleft", main_frame, "topleft", x_start, -190)
		label_remove:SetPoint ("topleft", main_frame, "topleft", x_start, -210)
		
		
		--> auto invite on whisper
		--> welcome msg
		local welcome_text3 = RA:CreateLabel (main_frame, "On receiving a whisper with a specific keyword, should auto invite the person?.", Invite:GetTemplate ("font", "ORANGE_FONT_TEMPLATE"))
		welcome_text3:SetPoint ("topleft", main_frame, "topleft", x_start, -240)
		
		--> enabled
		local on_auto_invite_switch = function (_, _, value)
			Invite.db.auto_invite = value
		end
		local auto_invite_switch, auto_invite_label = RA:CreateSwitch (main_frame, on_auto_invite_switch, Invite.db.auto_invite, _, _, _, _, "switch_auto_invite2", _, _, _, _, "Enabled", Invite:GetTemplate ("switch", "OPTIONS_CHECKBOX_TEMPLATE"), Invite:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
		auto_invite_switch:SetAsCheckBox()
		auto_invite_label:SetPoint ("topleft", main_frame, "topleft", x_start, -260)
		
		--> only from guild
		local on_auto_invite_guild_switch = function (_, _, value)
			Invite.db.auto_invite_limited = value
		end
		local auto_invite_guild_switch, auto_invite_guild_label = RA:CreateSwitch (main_frame, on_auto_invite_guild_switch, Invite.db.auto_invite_limited, _, _, _, _, "switch_auto_invite_guild", _, _, _, _, "Only Guild and Friends", Invite:GetTemplate ("switch", "OPTIONS_CHECKBOX_TEMPLATE"), Invite:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
		auto_invite_guild_switch:SetAsCheckBox()
		auto_invite_guild_label:SetPoint ("topleft", main_frame, "topleft", x_start, -280)	
		
		--> key words
		--add
		local editbox_add_keyword, label_add_keyword = RA:CreateTextEntry (main_frame, empty_func, 120, 20, "entry_add_keyword", _, "Add Keyword", Invite:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"), Invite:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
		label_add_keyword:SetPoint ("topleft", main_frame, "topleft", x_start, -300)	
		
		local add_key_word_func = function()
			local keyword = editbox_add_keyword.text
			if (keyword ~= "") then
				tinsert (Invite.db.auto_invite_keywords, keyword)
			end
			editbox_add_keyword.text = ""
			editbox_add_keyword:ClearFocus()
			main_frame.dropdown_keyword_remove:Refresh()
			main_frame.dropdown_keyword_remove:Select (1, true)
		end
		local button_add_keyword = RA:CreateButton (main_frame, add_key_word_func, 60, 18, "Add", _, _, _, _, _, _, Invite:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"), Invite:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
		button_add_keyword:SetPoint ("left", editbox_add_keyword, "right", 2, 0)
		button_add_keyword:SetIcon ("Interface\\AddOns\\" .. RA.InstallDir .. "\\media\\plus", 10, 10, "overlay", {0, 1, 0, 1}, {1, 1, 1}, 3, 1, 0)
		
		--remove
		local dropdown_keyword_erase_fill = function()
			local t = {}
			for i, keyword in ipairs (Invite.db.auto_invite_keywords) do
				t [#t+1] = {value = i, label = keyword, onclick = empty_func}
			end
			return t
		end
		local label_keyword_remove = RA:CreateLabel (main_frame, "Erase Keyword" .. ": ", Invite:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
		local dropdown_keyword_remove = RA:CreateDropDown (main_frame, dropdown_keyword_erase_fill, _, 160, 20, "dropdown_keyword_remove", _, Invite:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"))
		dropdown_keyword_remove:SetPoint ("left", label_keyword_remove, "right", 2, 0)

		local keyword_remove = function()
			local value = dropdown_keyword_remove.value
			tremove (Invite.db.auto_invite_keywords, value)
			dropdown_keyword_remove:Refresh()
			dropdown_keyword_remove:Select (1, true)
		end
		local button_keyword_remove = RA:CreateButton (main_frame, keyword_remove, 60, 18, "Remove", _, _, _, _, _, _, Invite:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"), Invite:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
		button_keyword_remove:SetPoint ("left", dropdown_keyword_remove, "right", 2, 0)
		button_keyword_remove:SetIcon ([[Interface\BUTTONS\UI-StopButton]], 14, 14, "overlay", {0, 1, 0, 1}, {1, 1, 1}, 2, 1, 0)
		label_keyword_remove:SetPoint ("topleft", main_frame, "topleft", x_start, -320)
		
		--> auto accept invites
		
		--> welcome msg
		local welcome_text4 = RA:CreateLabel (main_frame, "When a friend or guild member send a group invite, auto accept it?", Invite:GetTemplate ("font", "ORANGE_FONT_TEMPLATE"))
		welcome_text4:SetPoint ("topleft", main_frame, "topleft", x_start, -350)
		
		--> enabled
		local on_auto_ainvite_switch = function (_, _, value)
			Invite.db.auto_accept_invites = value
		end
		local auto_ainvite_switch, auto_ainvite_label = RA:CreateSwitch (main_frame, on_auto_ainvite_switch, Invite.db.auto_accept_invites, _, _, _, _, "switch_auto_ainvite", _, _, _, _, "Enabled", Invite:GetTemplate ("switch", "OPTIONS_CHECKBOX_TEMPLATE"), Invite:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
		auto_ainvite_switch:SetAsCheckBox()
		auto_ainvite_label:SetPoint ("topleft", main_frame, "topleft", x_start, -370)
		
		--> only from guild
		local on_auto_ainvite_guild_switch = function (_, _, value)
			Invite.db.auto_accept_invites_limited = value
		end
		local auto_ainvite_guild_switch, auto_ainvite_guild_label = RA:CreateSwitch (main_frame, on_auto_ainvite_guild_switch, Invite.db.auto_accept_invites_limited, _, _, _, _, "switch_auto_ainvite_guild", _, _, _, _, "Only From Guild and Friends", Invite:GetTemplate ("switch", "OPTIONS_CHECKBOX_TEMPLATE"), Invite:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
		auto_ainvite_guild_switch:SetAsCheckBox()
		auto_ainvite_guild_label:SetPoint ("topleft", main_frame, "topleft", x_start, -390)

        --> invite message repeats
		--> welcome msg
		local welcome_text5 = RA:CreateLabel (main_frame, "Repeat the invite announcement with each wave?", Invite:GetTemplate ("font", "ORANGE_FONT_TEMPLATE"))
		welcome_text5:SetPoint ("topleft", main_frame, "topleft", x_start, -420)
		
		--> enabled
		local on_invite_msg_repeats_switch = function (_, _, value)
		    Invite.db.invite_msg_repeats = value
		end
		local invite_msg_repeats_switch, invite_msg_repeats_label = RA:CreateSwitch (main_frame, on_invite_msg_repeats_switch, Invite.db.invite_msg_repeats, _, _, _, _, "switch_invite_msg_repeats", _, _, _, _, "Enabled", Invite:GetTemplate ("switch", "OPTIONS_CHECKBOX_TEMPLATE"), Invite:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
		invite_msg_repeats_switch:SetAsCheckBox()
		invite_msg_repeats_label:SetPoint ("topleft", main_frame, "topleft", x_start, -440)	
	
	--> interval between each wave
		--> welcome msg
		local welcome_text6 = RA:CreateLabel (main_frame, "Interval in seconds between each invite wave.", Invite:GetTemplate ("font", "ORANGE_FONT_TEMPLATE"))
		welcome_text6:SetPoint ("topleft", main_frame, "topleft", x_start, -460)
		
		local invite_interval_slider, invite_interval_label = RA:CreateSlider (main_frame, 180, 20, 60, 180, 1, Invite.db.invite_interval, _, "InviteInterval", _, "Inverval", Invite:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"), Invite:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
		invite_interval_label:SetPoint ("topleft", main_frame, "topleft", x_start, -480)	
		invite_interval_slider.OnValueChanged = function (_, _, value) 
			Invite.db.invite_interval = value 
		end
	
	
	-------------- fim
	
	------- functions
	
	--> create panel
	function Invite:DisableCreatePanel()
		panel.button_create_preset:Disable()
		editbox_preset_name:Disable()
		dropdown_diff:Disable()
		editbox_masterloot_name:Disable()
		editbox_raidleader_name:Disable()
		editbox_invite_msg:Disable()
		
		dropdown_keep_auto_invite:Disable()
		panel.switch_auto_invite:Disable()
		dropdown_schedule_select:Disable()
		
		for _, switch in ipairs (switchers) do
			switch:Disable()
		end
	end
	
	function Invite:EnableCreatePanel()
		panel.button_create_preset:Enable()
		editbox_preset_name:Enable()
		dropdown_diff:Enable()
		editbox_masterloot_name:Enable()
		editbox_raidleader_name:Enable()
		editbox_invite_msg:Enable()

		dropdown_keep_auto_invite:Enable()
		panel.switch_auto_invite:Enable()
		dropdown_schedule_select:Enable()
		
		for _, switch in ipairs (switchers) do
			switch:Enable()
		end
		
		panel.dropdown_schedule:Refresh()
	end	
	
	function Invite:DisableInviteButtons()
		for i = 1, #preset_buttons do
			preset_buttons[i]:Disable()
		end
		create_button:Disable()
		button_edit:Disable()
		button_remove:Disable()
		dropdown_edit:Disable()
		dropdown_remove:Disable()
	end
	
	function Invite:EnableInviteButtons()
		for i = 1, #preset_buttons do
			preset_buttons[i]:Enable()
		end
		create_button:Enable()
		button_edit:Enable()
		button_remove:Enable()
		dropdown_edit:Enable()
		dropdown_remove:Enable()
	end	
	
	--disable the create panel at menu creation
	Invite:DisableCreatePanel()
	main_frame:RefreshPresetButtons()
	
end


local install_status = RA:InstallPlugin ("Invites", "RAInvite", Invite, default_config)

local check_lootandleader = function()
	if (Invite.auto_invite_preset or Invite.invite_preset) then
		Invite:CheckMasterLootForPreset (Invite.auto_invite_preset or Invite.invite_preset)
		Invite:CheckRaidLeaderForPreset (Invite.auto_invite_preset or Invite.invite_preset)
	end
end

function Invite:SetRaidDifficultyForPreset (preset)
	local diff = preset.difficulty
	if (diff == "Normal 10" or diff == 3) then
		SetRaidDifficulty(1)
	elseif (diff == "Normal 25" or diff == 4) then
		SetRaidDifficulty (2)
	elseif (diff == "Heroic 10" or diff == 5) then
		SetRaidDifficulty (3)
	elseif (diff == "Heroic 25" or diff == 6) then
		SetRaidDifficulty (4)
	end
end

function Invite:CheckRaidLeaderForPreset (preset)
	if (preset.raidleader and preset.raidleader ~= "") then
		local ImLeader = UnitIsGroupLeader ("player")
		if (ImLeader and UnitInRaid (preset.raidleader) and UnitName("player") ~= preset.raidleader) then
			PromoteToLeader (preset.raidleader)
			print ("Promoting ", preset.raidleader, "to leader.")
			-- promote leader to master loot
			local lootmethod, masterlooterPartyID, masterlooterRaidID = GetLootMethod()
			if (lootmethod ~= master) then
				SetLootMethod ("master", preset.raidleader)
			else
				local masterloot = UnitName ("raid" .. masterlooterRaidID)
				if (not masterloot or masterloot ~= preset.raidleader) then
					SetLootMethod ("master", preset.raidleader)
				end
			end
		end
	end
end

function Invite:CheckMasterLootForPreset (preset)
	if (preset.masterloot and preset.masterloot ~= "" and UnitIsGroupLeader ("player")) then
		--split the names of people in the raid
		local allAssistants = {}
		local splitBySpace = {strsplit (" ", preset.masterloot)}

		for _, playerName in ipairs (splitBySpace) do
			local masterloot_name = playerName
			if (UnitInRaid (masterloot_name)) then

				if (not RA:UnitHasAssist (masterloot_name)) then
					PromoteToAssistant (masterloot_name)
					print ("|cFFFFDD00RaidAssist (/raa):|cFFFFFF00 " .. masterloot_name .. " now has assist.|r")
				end
				
				--[=[ let's preserve the master loot code just in case...
				local lootmethod, masterlooterPartyID, masterlooterRaidID = GetLootMethod()
				if (lootmethod ~= master) then
					SetLootMethod ("master", masterloot_name)
				else
					local masterloot = UnitName ("raid" .. masterlooterRaidID)
					if (not masterloot or masterloot ~= preset.masterloot then
						SetLootMethod ("master", masterloot_name)
					end
				end
				--]=]
			end
		end
	end
end

local redo_invites = function()
	Invite.DoInvitesForPreset (Invite.invite_preset)
end

function Invite:PARTY_MEMBERS_CHANGED()
	if (not IsInRaid () and IsInGroup ()) then
		if (GetNumGroupMembers()) then
			Invite:UnregisterEvent ("PARTY_MEMBERS_CHANGED")
			ConvertToRaid()
			Invite:SetRaidDifficultyForPreset (Invite.invite_preset)
			
			if (Invite.CanRedoInvites) then
				Invite.CanReroInvites = nil
				C_Timer.After (10, check_lootandleader)
				C_Timer.After (2, redo_invites)
			end
		end
	elseif (IsInRaid ()) then
		Invite:UnregisterEvent ("PARTY_MEMBERS_CHANGED")
	end
end

function Invite.DoInvitesForPreset (preset)

	if (not preset) then
		Invite:Msg ("Invite thread is invalid, please cancel and re-start.")
		return
	end

	local my_name = UnitName ("player")
	local is_showing_all = GetGuildRosterShowOffline()
	if is_showing_all then 
		SetGuildRosterShowOffline(false)
	end

	local in_raid= IsInRaid ()
	if (not in_raid) then
		Invite:RegisterEvent ("PARTY_MEMBERS_CHANGED")
		-- check if we're already in a party first
		Invite:PARTY_MEMBERS_CHANGED()
	end

	if (not in_raid) then
		--> we should invite few guys, converto on raid and invite everyone else after that.
--		print ("Sending only 4 invites...")
		local invites_sent = 0
		for i = 1, GetNumGuildMembers() do
			local name, rank, rankIndex, level, classDisplayName, zone, note, officernote, isOnline = GetGuildRosterInfo (i) --, status, class, achievementPoints, achievementRank, isMobile, canSoR, repStanding
			if (preset.ranks [rankIndex+1] and isOnline and not isMobile) then
				if (my_name ~= name and ((in_raid and not UnitInRaid(name)) or (not in_raid and not UnitInParty(name))) ) then
					InviteUnit (name)
					--print ("Inviting", name)
					invites_sent = invites_sent + 1
					if (invites_sent >= 4) then
						break
					end
				end
			end
		end
		Invite.CanRedoInvites = true
	else
		for i = 1, GetNumGuildMembers() do
			local name, rank, rankIndex, level, classDisplayName, zone, note, officernote, isOnline = GetGuildRosterInfo (i) --, status, class, achievementPoints, achievementRank, isMobile, canSoR, repStanding
			if (preset.ranks [rankIndex+1] and isOnline and not isMobile) then
				if (my_name ~= name and ((in_raid and not UnitInRaid(name)) or (not in_raid and not UnitInParty(name))) ) then
					InviteUnit (name)
				end
			end
		end	
	end

end

function Invite.AutoInviteTick()
	Invite.auto_invite_wave_time = Invite.auto_invite_wave_time - 1
	Invite.auto_invite_ticks = Invite.auto_invite_ticks - 1
	
	if (Invite.auto_invite_wave_time == 15) then
		GuildRoster()
		
	--elseif (Invite.auto_invite_wave_time == 5) then
	elseif (Invite.db.invite_msg_repeats and Invite.auto_invite_wave_time == 5) then
		Invite:SendInviteAnnouncementMsg()
		
	elseif (Invite.auto_invite_wave_time == 0) then
		Invite.auto_invite_frame.statusbar:SetTimer (Invite.db.invite_interval + 1)
		Invite.auto_invite_wave_number = Invite.auto_invite_wave_number + 1
		
		Invite.auto_invite_frame.statusbar.lefttext = "next wave (" .. Invite.auto_invite_wave_number .. ") in:"
		Invite.auto_invite_wave_time = Invite.db.invite_interval - 1
		
		Invite.DoInvitesForPreset (Invite.auto_invite_preset)
		
		Invite:CheckMasterLootForPreset (Invite.auto_invite_preset)
		Invite:CheckRaidLeaderForPreset (Invite.auto_invite_preset)
		C_Timer.After (10, check_lootandleader)
		
		if (Invite.auto_invite_ticks < 0) then
			Invite:StopAutoInvites()
		end
	end
end

function Invite:StopAutoInvites()
	Invite.auto_invite_ticket:Cancel()
	Invite.auto_invite_ticket = nil
	Invite.invites_in_progress = nil
	Invite.auto_invite_preset = nil
	Invite.invite_preset = nil
	Invite.auto_invite_frame:Hide()
	Invite:UnregisterEvent ("PARTY_MEMBERS_CHANGED")
	
	--> check first in case the options panel isn't loaded yet
	if (Invite.EnableInviteButtons) then
		Invite:EnableInviteButtons()
	end
end

local do_first_wave = function()
	Invite.DoInvitesForPreset (Invite.invite_preset)
end

function Invite:StartInvitesAuto (preset, remaining)
	if (Invite.invites_in_progress) then
		return
	end
	
	GuildRoster()
	
	if (not Invite.auto_invite_frame) then
		Invite.auto_invite_frame = RA:CreateCleanFrame (Invite, "AutoInviteFrame")
		Invite.auto_invite_frame:SetSize (205, 58)
		
		Invite.auto_invite_frame.preset_name = Invite:CreateLabel (Invite.auto_invite_frame, "", Invite:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
		Invite.auto_invite_frame.preset_name:SetPoint (10, -10)
		
		Invite.auto_invite_frame.statusbar = Invite:CreateBar (Invite.auto_invite_frame, LibStub:GetLibrary ("LibSharedMedia-3.0"):Fetch ("statusbar", "Iskar Serenity"), 167, 16, 50)
		Invite.auto_invite_frame.statusbar:SetPoint (10, -25)
		Invite.auto_invite_frame.statusbar.fontsize = 11
		Invite.auto_invite_frame.statusbar.fontface = "Accidental Presidency"
		Invite.auto_invite_frame.statusbar.fontcolor = "darkorange"
		Invite.auto_invite_frame.statusbar.color = "gray"
		Invite.auto_invite_frame.statusbar.texture = "Iskar Serenity"
		
		Invite.auto_invite_frame.cancel = Invite:CreateButton (Invite.auto_invite_frame, Invite.StopAutoInvites, 16, 16, "", _, _, [[Interface\Buttons\UI-GroupLoot-Pass-Down]])
		Invite.auto_invite_frame.cancel:SetPoint ("left", Invite.auto_invite_frame.statusbar, "right", 2, 0)
	end
	
	Invite.invites_in_progress = true
	Invite.auto_invite_frame.preset_name.text = "Invites in Progress: " .. preset.name
	
	Invite.invite_preset = preset
	Invite.auto_invite_preset = preset
	Invite.auto_invite_wave_number = 2
	Invite.auto_invite_wave_time = Invite.db.invite_interval - 1
	Invite.auto_invite_ticks = remaining
	
	Invite.auto_invite_frame.statusbar:SetTimer (Invite.db.invite_interval + 1)
	Invite.auto_invite_frame.statusbar.lefttext = "next wave (" .. Invite.auto_invite_wave_number .. ") in:"
	
	Invite:SetRaidDifficultyForPreset (preset)
	
	Invite.auto_invite_frame:Show()
	Invite.auto_invite_ticket = C_Timer.NewTicker (1, Invite.AutoInviteTick)

	--wait to guild roster
	Invite:SendInviteAnnouncementMsg()
	C_Timer.After (5, do_first_wave)
end

local finish_invite_wave = function()
	Invite.invite_preset = nil
	Invite.invites_in_progress = nil
	
	--> check first in case the options panel isn't loaded yet
	if (Invite.EnableInviteButtons) then
		Invite:EnableInviteButtons()
	end	
end

function Invite:StartInvites (preset_number)
	if (Invite.invites_in_progress) then
		return
	end
	
	local preset = Invite:GetPreset (preset_number)
	if (preset) then
		Invite:DisableInviteButtons()
	
		if (preset.keepinvites and preset.keepinvites > 0) then
			--Invite.invites_in_progress = true
			local invite_time = preset.keepinvites * 60
			return Invite:StartInvitesAuto (preset, invite_time)
		else
			GuildRoster()
			Invite.invites_in_progress = true
			Invite.invite_preset = preset
			Invite:SendInviteAnnouncementMsg()
			C_Timer.After (5, do_first_wave)
			C_Timer.After (60, finish_invite_wave)
		end
	end
end

function Invite.CheckForAutoInvites()
	if (not IsInGuild()) then
		return
	end
	
	--get the raid schedule plugin
	local RaidSchedule = _G ["RaidAssistRaidSchedule"]
	if (RaidSchedule) then
		local now = time()
		for index, preset in ipairs (Invite:GetAllPresets()) do 
			--this invite preset has a schedule?
			if (preset.autostart) then
				
				local core, index = RaidSchedule:GetRaidScheduleTableByName (preset.autostartcore)
				
				if (core) then
					local next_event_in, start_time, end_time, day, month_number, month_day = RaidSchedule:GetNextEventTime (index)
					print("Next event in " .. next_event_in)
					local keep_invites = preset.keepinvites or 15

					if (next_event_in <= (keep_invites*60) and next_event_in > 1) then --problem here, next_event_in is nil
						local invite_time = (keep_invites and keep_invites > 0 and keep_invites * 60 or false) or (next_event_in > 121 and next_event_in or 121)
						print ("|cFFFFDD00RaidAssist (/raa):|cFFFFFF00 starting auto invites.|r")
						return Invite:StartInvitesAuto (preset, invite_time)
						
					elseif (next_event_in > (keep_invites*60)) then
						Invite.NextCheckTimer = C_Timer.NewTimer (next_event_in - ((keep_invites*60)-1), Invite.CheckForAutoInvites)
					end

					--return Invite:StartInvitesAuto (preset, 180) --debug
				end
			end
		end
	end
end

function Invite:SendInviteAnnouncementMsg()
	local msg = "[RA] "
	if Invite.invite_preset.invite_msg and Invite.invite_preset.invite_msg ~= "" then
		msg = msg .. Invite.invite_preset.invite_msg
	else 
		msg = Invite.db.invite_msg
	end
	
	print("[GUILD] " .. msg)
	--SendChatMessage (msg, "GUILD")
end



--endd
