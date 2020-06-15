


local RA = RaidAssist
local L = LibStub ("AceLocale-3.0"):GetLocale ("RaidAssistAddon")
local _
local default_priority = 4

local GetUnitName = GetUnitName
local GetGuildInfo = GetGuildInfo

local week1, week2, week3, week4, week5, week6, week7 = "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"

local empty_func = function()end

local default_config = {
	cores = {},
	characters = {},
	next_db_number = 1,
}

if (_G ["RaidAssistRaidSchedule"]) then
	return
end
local RaidSchedule = {version = "v0.1", pluginname = "RaidSchedule"}
RaidSchedule.debug = false
_G ["RaidAssistRaidSchedule"] = RaidSchedule

local icon_texture = [[Interface\Calendar\UI-Calendar-Button]]
local icon_texcoord = {l=0, r=47/128, t=0, b=48/64}
local text_color_enabled = {r=1, g=1, b=1, a=1}
local text_color_disabled = {r=0.5, g=0.5, b=0.5, a=1}

RaidSchedule.menu_text = function (plugin)
	if (RaidSchedule.db.enabled) then
		return icon_texture, icon_texcoord, "Raid Schedule", text_color_enabled
	else
		return icon_texture, icon_texcoord, "Raid Schedule", text_color_disabled
	end
end

RaidSchedule.menu_popup_show = function (plugin, ct_frame, param1, param2)
	-- don't have a popup frame
end

RaidSchedule.menu_popup_hide = function (plugin, ct_frame, param1, param2)
	local popup_frame = RaidSchedule.popup_frame
	popup_frame:Hide()
end

RaidSchedule.menu_on_click = function (plugin)
	RA.OpenMainOptions (RaidSchedule)
end

RaidSchedule.StartUp = function()
	RaidSchedule.player_name = GetUnitName ("player")
	RaidSchedule.need_popup_update = true
end

RaidSchedule.OnInstall = function (plugin)

	RaidSchedule.db.menu_priority = default_priority

	local popup_frame = RaidSchedule.popup_frame
end

RaidSchedule.OnEnable = function (plugin)

end

RaidSchedule.OnDisable = function (plugin)

end

RaidSchedule.OnProfileChanged = function (plugin)

end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function RaidSchedule:GetAllRegisteredCores()
	return RaidSchedule.db.cores
end

function RaidSchedule:GetRaidScheduleTableByName (core_name)
	for index, core in pairs (RaidSchedule.db.cores) do
		if (core.core_name == core_name) then
			return core, index
		end
	end
end

function RaidSchedule:SetCharacterRaidScheduleTable (db_number)
	RaidSchedule.db.characters [RaidSchedule.player_name or GetUnitName ("player")] = db_number
end

function RaidSchedule:GetCharacterRaidScheduleTableIndex()
	return RaidSchedule.db.characters [RaidSchedule.player_name or GetUnitName ("player")]
end

function RaidSchedule:GetRaidScheduleTable (index)
	return RaidSchedule.db.cores [index]
end

function RaidSchedule:GetCharacterRaidScheduleTable()
	local current_db = RaidSchedule.db.characters [RaidSchedule.player_name or GetUnitName ("player")]
	
	if (not current_db or not RaidSchedule.db.cores [current_db]) then
		local first_db = next (RaidSchedule.db.cores)
		if (first_db) then
			RaidSchedule.db.characters [RaidSchedule.player_name or GetUnitName ("player")] = first_db
			current_db = first_db
		end
	end
	
	current_db = RaidSchedule.db.cores [current_db]
	return current_db
end

function RaidSchedule:OnEditRaidScheduleTable (attendance_table)
	-- when the schedule table got a edit
	
end

function RaidSchedule:OnCreateRaidScheduleTable (attendance_table, index)
	--> when a schedule table is created
	
	--> if the player has no core, set this new one
	if (not RaidSchedule:GetCharacterRaidScheduleTableIndex()) then
		RaidSchedule:SetCharacterRaidScheduleTable (index)
	end
	
	--> actually, always set the new core to be the current for the player
	RaidSchedule:SetCharacterRaidScheduleTable (index)
	
	--> refresh the dropdown
	RaidSchedule.main_frame:RefreshYourCoreDropdown()
end

function RaidSchedule:CheckCurrentCore()
	local player = RaidSchedule.player_name or GetUnitName ("player")
	local my_core_id = RaidSchedule.db.characters [player]
	
	--> check if exists
	if (my_core_id) then
		if (not RaidSchedule.db.cores [current_db]) then
			RaidSchedule.db.characters [player] = nil
		end
	end
	
	--> try to assign a new core
	if (not RaidSchedule.db.characters [player]) then
		local first_db = next (RaidSchedule.db.cores)
		if (first_db) then
			RaidSchedule.db.characters [player] = first_db
		end
	end
end

function RaidSchedule:RemoveRaidScheduleTable (index)
	RaidSchedule.db.cores [index] = nil
	
	if (RaidSchedule.main_frame) then
		RaidSchedule.main_frame:Refresh()
	end
	
	--> check if the core still exists
	RaidSchedule:CheckCurrentCore()
	
	if (RaidSchedule:GetCharacterRaidScheduleTableIndex() == index) then
		RaidSchedule:GetCharacterRaidScheduleTable()
		RaidSchedule.main_frame:RefreshYourCoreDropdown()
		if (not RaidSchedule:GetCharacterRaidScheduleTable()) then
			RaidSchedule.main_frame.dropdown_select_database:Select (1, true)
		end
	end
		
	RaidSchedule.main_frame.dropdown_edit_attendance:Select (1, true)
	RaidSchedule.just_select_schedule_table()
	RaidSchedule.main_frame:DisableAll()
	RaidSchedule.main_frame:RefreshYourCoreDropdown()
end

function RaidSchedule:Msg (...)
	if (RaidSchedule.debug) then
		print ("|cFFFFDD00RaidSchedule|r:", ...)
	end
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local week_days = {
	{value = 1, label = "Mon", onclick = empty_func},
	{value = 2, label = "Tue", onclick = empty_func},
	{value = 3, label = "Wed", onclick = empty_func},
	{value = 4, label = "Thu", onclick = empty_func},
	{value = 5, label = "Fri", onclick = empty_func},
	{value = 6, label = "Sat", onclick = empty_func},
	{value = 7, label = "Sun", onclick = empty_func},
}

local minutes = {}
for i = 0, 59 do
	local n = i
	if (n < 10) then
		n = "0" .. i
	end
	tinsert (minutes, {value = i, label = n, onclick = empty_func})
end
local min_func = function()
	return minutes
end

local hours = {}
for i = 0, 23 do
	local n = i
	if (n < 10) then
		n = "0" .. i
	end
	tinsert (hours, {value = i, label = n, onclick = empty_func})
end
local hour_func = function()
	return hours
end

local days_func = function()
	return week_days
end

local dropdown_set_backdrop = function (dropdown)
	dropdown:SetBackdrop ({edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize = 1, bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tileSize = 64, tile = true})
	dropdown:SetBackdropColor (1, 1, 1, .5)
	dropdown:SetBackdropBorderColor (0, 0, 0, 1)
end

local create_day_block = function (i, loc_day_name, self, y)
	local label_day_name = RA:CreateLabel (self, loc_day_name .. ": ", RaidSchedule:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
	label_day_name:SetPoint ("topleft", self, "topleft", 5, y)
	
	local switch_enabled = RA:CreateSwitch (self, empty_func, false, 60, 20, _, _, "switch_enabled" .. i, _, _, _, _, _, RaidSchedule:GetTemplate ("switch", "OPTIONS_CHECKBOX_BRIGHT_TEMPLATE"))
	switch_enabled:SetAsCheckBox()
	
	local editbox_start_time_hour = RA:CreateDropDown (self, hour_func, 0, 60, 20, "dropdown_start_time_hour" .. i, _, RaidSchedule:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"))
	dropdown_set_backdrop (editbox_start_time_hour)
	local two_points1 = RA:CreateLabel (self, ":", RaidSchedule:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
	local editbox_start_time_min = RA:CreateDropDown (self, min_func, 0, 60, 20, "dropdown_start_time_min" .. i, _, RaidSchedule:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"))
	dropdown_set_backdrop (editbox_start_time_min)
	
	local dropdown_end_day = RA:CreateDropDown (self, days_func, i, 75, 20, "dropdown_end_day" .. i, _, RaidSchedule:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"))
	dropdown_set_backdrop (dropdown_end_day)
	
	local editbox_end_time_hour = RA:CreateDropDown (self, hour_func, 0, 60, 20, "dropdown_end_time_hour" .. i, _, RaidSchedule:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"))
	dropdown_set_backdrop (editbox_end_time_hour)
	local two_points2 = RA:CreateLabel (self, ":", RaidSchedule:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
	local editbox_end_time_min = RA:CreateDropDown (self, min_func, 0, 60, 20, "dropdown_end_time_min" .. i, _, RaidSchedule:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"))
	dropdown_set_backdrop (editbox_end_time_min)
	
	switch_enabled:SetPoint ("topleft", self, "topleft", 65, y)
	
	editbox_start_time_hour:SetPoint ("left", switch_enabled, "right", 10, 0)
	two_points1:SetPoint ("left", editbox_start_time_hour, "right", 0, 0)
	editbox_start_time_min:SetPoint ("left", editbox_start_time_hour, "right", 4, 0)
	
	dropdown_end_day:SetPoint ("left", editbox_start_time_min, "right", 15, 0)
	editbox_end_time_hour:SetPoint ("left", dropdown_end_day, "right", 5, 0)
	two_points2:SetPoint ("left", editbox_end_time_hour, "right", 0, 0)
	editbox_end_time_min:SetPoint ("left", editbox_end_time_hour, "right", 4, 0)
	
	return label_day_name
end

--doo
function RaidSchedule.BuildCreatePanel()

	return panel
end

local just_select_schedule_table = function()
	local core = RaidSchedule.main_frame.dropdown_edit_attendance.value
	core = RaidSchedule.db.cores [core]
	if (core) then
		local admin_rank = core.admin_rank
		RaidSchedule.main_frame:Reset()
		
		local f = RaidSchedule.create_schedule_panel
		
		f.editbox_core_name.text = core.core_name
		f.dropdown_admin_rank:Select (admin_rank, true)
		
		local d = core.days_table
		for i = 1, 7 do
			f ["switch_enabled" .. i]:SetValue (d[i].enabled)
			f ["dropdown_start_time_hour" .. i]:Select (d[i].start_hour)
			f ["dropdown_start_time_min" .. i]:Select (d[i].start_min)
			f ["dropdown_end_day" .. i]:Select (d[i].end_day, true)
			f ["dropdown_end_time_hour" .. i]:Select (d[i].end_hour)
			f ["dropdown_end_time_min" .. i]:Select (d[i].end_min)
		end
	end
end
RaidSchedule.just_select_schedule_table = just_select_schedule_table

local edit_attendance_table = function()
	local core = RaidSchedule.main_frame.dropdown_edit_attendance.value
	core = RaidSchedule.db.cores [core]
	if (core) then
	
		RaidSchedule.main_frame:EnableAll()
	
		local admin_rank = core.admin_rank
	
		if (not RaidSchedule.create_panel_built) then
			RaidSchedule.BuildCreatePanel()
			RaidSchedule.create_panel_built = true
		end
		
		RaidSchedule.main_frame:Reset()
		
		local f = RaidSchedule.create_schedule_panel
		
		f.editbox_core_name.text = core.core_name
		f.editbox_core_name:Disable()
		f.dropdown_admin_rank:Select (admin_rank, true)
		
		local d = core.days_table
		for i = 1, 7 do
			f ["switch_enabled" .. i]:SetValue (d[i].enabled)
			f ["dropdown_start_time_hour" .. i]:Select (d[i].start_hour)
			f ["dropdown_start_time_min" .. i]:Select (d[i].start_min)
			f ["dropdown_end_day" .. i]:Select (d[i].end_day, true)
			f ["dropdown_end_time_hour" .. i]:Select (d[i].end_hour)
			f ["dropdown_end_time_min" .. i]:Select (d[i].end_min)
		end
		
		f.button_create.text = "Save Changes"
		f.is_editing = true
		f.is_editing_table = core
		
		RaidSchedule.main_frame:DisableRightPart()
	end
end

local remove_attendance_table = function()
	local core_selected = RaidSchedule.main_frame.dropdown_edit_attendance.value
	if (core_selected) then
		local index = core_selected
		core_selected = RaidSchedule.db.cores [core_selected]
		RA:ShowPromptPanel ("Remove " .. core_selected.core_name .. "?", function() RaidSchedule:RemoveRaidScheduleTable (index) end, empty_func)
	end
end

function RaidSchedule.OnShowOnOptionsPanel()
	local OptionsPanel = RaidSchedule.OptionsPanel
	RaidSchedule.BuildOptions (OptionsPanel)
end

function RaidSchedule.BuildOptions (frame)

	if (frame.FirstRun) then
		return
	end
	frame.FirstRun = true

	local main_frame = frame
	RaidSchedule.main_frame = frame

	local panel = main_frame
	
	local label_core_name = RA:CreateLabel (panel, "Core Name" .. ": ", RaidSchedule:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
	local editbox_core_name = RA:CreateTextEntry (panel, empty_func, 160, 20, "editbox_core_name", _, _, RaidSchedule:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"))
	label_core_name:SetPoint ("topleft", panel, "topleft", 0, 0)
	editbox_core_name:SetPoint ("left", label_core_name, "right", 2, 0)
	
	local label_start_time = RA:CreateLabel (panel, "Start Time", RaidSchedule:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
	local label_end_time = RA:CreateLabel (panel, "End Day and Time", RaidSchedule:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
	label_start_time:SetPoint ("topleft", panel, "topleft", 135, -42)
	label_end_time:SetPoint ("topleft", panel, "topleft", 274, -42)
	
	local down_y = -25
	
	local names = {"Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"}
	for i = 1, 7 do
		create_day_block (i, names [i], panel, down_y + (-(i+1)*20))
	end
	
	local get_guild_ranks = function()
		return RaidSchedule:GetGuildRanks (true)
	end

	local label_admin_rank = RA:CreateLabel (panel, "Core Officer Rank" .. ": ", RaidSchedule:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
	local dropdown_admin_rank = RA:CreateDropDown (panel, get_guild_ranks, 1, 160, 20, "dropdown_admin_rank")
	dropdown_set_backdrop (dropdown_admin_rank)
	dropdown_admin_rank:SetPoint ("left", label_admin_rank, "right", 2, 0)
	label_admin_rank:SetPoint ("topleft", panel, "topleft", 5, down_y + (-10*20))
	
	local add_attendance_table = function()
	
		if (panel.is_editing) then
			local attendance_table = panel.is_editing_table
			
			local core_name = editbox_core_name.text
			if (core_name ~= "") then
				attendance_table.core_name = core_name
			end
			
			attendance_table.admin_rank = dropdown_admin_rank.value
			attendance_table.guild_name = GetGuildInfo ("player")
			
			for i = 1, 7 do
				attendance_table.days_table[i].enabled = panel ["switch_enabled" .. i].value
				attendance_table.days_table[i].start_hour = panel ["dropdown_start_time_hour" .. i].value
				attendance_table.days_table[i].start_min = panel ["dropdown_start_time_min" .. i].value
				attendance_table.days_table[i].end_hour = panel ["dropdown_end_time_hour" .. i].value
				attendance_table.days_table[i].end_min = panel ["dropdown_end_time_min" .. i].value
				attendance_table.days_table[i].end_day = panel ["dropdown_end_day" .. i].value
			end

			RaidSchedule:OnEditRaidScheduleTable (attendance_table)
			
			panel.button_create.text = "Create"
			panel.is_editing = nil
			
			just_select_schedule_table()
			panel:DisableAll()
			
		else
			local new_attendance = {}
			
			local core_name = editbox_core_name.text
			if (core_name == "") then
				core_name = "Core 1"
			end
			
			local days_table = {}
			for i = 1, 7 do
				days_table[i] = {
					enabled = panel ["switch_enabled" .. i].value,
					start_hour = panel ["dropdown_start_time_hour" .. i].value,
					start_min = panel ["dropdown_start_time_min" .. i].value,
					end_hour = panel ["dropdown_end_time_hour" .. i].value,
					end_min = panel ["dropdown_end_time_min" .. i].value,
					end_day = panel ["dropdown_end_day" .. i].value,
				}
			end
			new_attendance.weeks = 4
			new_attendance.serial = math.random (1000000, 9000000)
			new_attendance.only_guild_members = true
			new_attendance.attendance = {}
			new_attendance.name_pool = {}
			new_attendance.days_table = days_table
			new_attendance.core_name = core_name
			new_attendance.admin_rank = dropdown_admin_rank.value
			new_attendance.guild_name = GetGuildInfo ("player")
			
			local next_id = RaidSchedule.db.next_db_number
			
			RaidSchedule.db.cores [next_id] = new_attendance
			RaidSchedule:OnCreateRaidScheduleTable (new_attendance, next_id)
			
			panel.dropdown_edit_attendance:Refresh()
			panel.dropdown_edit_attendance:Select (core_name)

			just_select_schedule_table()
			panel:DisableAll()
			
			RaidSchedule.db.next_db_number = next_id + 1
		end
		
		panel:EnableRightPart()

	end
	
	local button_create = RA:CreateButton (panel, add_attendance_table, 160, 20, "Create", _, _, _, "button_create", _, _, RaidSchedule:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"), RaidSchedule:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
	
	button_create:SetPoint ("topleft", panel, "topleft", 5, down_y + (-12*20))

	function panel:Reset()
		editbox_core_name.text = ""
		editbox_core_name:Enable()
		dropdown_admin_rank:Select (1)
		for i = 1, 7 do
			self ["switch_enabled" .. i]:SetValue (false)
			self ["dropdown_start_time_hour" .. i]:Select (0)
			self ["dropdown_start_time_min" .. i]:Select (0)
			self ["dropdown_end_day" .. i]:Select (i)
			self ["dropdown_end_time_hour" .. i]:Select (0)
			self ["dropdown_end_time_min" .. i]:Select (0)
		end
		panel.button_create.text = "Create"
	end
	
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

	local show_schedule = function (_, _, value)
		panel:EnableAll()
		just_select_schedule_table()
		panel:DisableAll()
	end

	local dropdown_edit_fill = function()
		local t = {}
		for i, core in pairs (RaidSchedule:GetAllRegisteredCores()) do
			t [#t+1] = {value = i, label = core.core_name, onclick = show_schedule}
		end
		return t
	end
	local label_edit = RA:CreateLabel (main_frame, "Edit" .. ": ", RaidSchedule:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
	local dropdown_edit = RA:CreateDropDown (main_frame, dropdown_edit_fill, _, 160, 20, "dropdown_edit_attendance", _, RaidSchedule:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"))
	dropdown_edit:SetPoint ("left", label_edit, "right", 2, 0)

	local button_edit = RA:CreateButton (main_frame, edit_attendance_table, 60, 18, "Edit", _, _, _, _, _, _, RaidSchedule:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"), RaidSchedule:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
	button_edit:SetPoint ("left", dropdown_edit, "right", 2, 0)
	local button_remove = RA:CreateButton (main_frame, remove_attendance_table, 60, 18, "Remove", _, _, _, _, _, _, RaidSchedule:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"), RaidSchedule:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
	button_remove:SetPoint ("left", button_edit, "right", 2, 0)
	button_edit:SetIcon ([[Interface\BUTTONS\UI-OptionsButton]], 12, 12, "overlay", {0, 1, 0, 1}, {1, 1, 1}, 2, 1, 0)
	button_remove:SetIcon ([[Interface\BUTTONS\UI-StopButton]], 14, 14, "overlay", {0, 1, 0, 1}, {1, 1, 1}, 2, 1, 0)
	
	local dropdown_selected_db = function (self, fixed_param, value)
		RaidSchedule:SetCharacterRaidScheduleTable (value)
	end
	local dropdown_select_db = function()
		local t = {}
		for i, core in pairs (RaidSchedule:GetAllRegisteredCores()) do
			t [#t+1] = {value = i, label = core.core_name, onclick = dropdown_selected_db}
		end
		return t
	end
	
	local label_change_database = RA:CreateLabel (main_frame, "Your Core" .. ": ", RaidSchedule:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
	local dropdown_select_database = RA:CreateDropDown (main_frame, dropdown_select_db, RaidSchedule:GetCharacterRaidScheduleTableIndex(), 160, 20, "dropdown_select_database")
	
	function panel:RefreshYourCoreDropdown()
		if (RaidSchedule:GetCharacterRaidScheduleTableIndex()) then
			local id = RaidSchedule:GetCharacterRaidScheduleTableIndex()
			for i, coreTable in ipairs (dropdown_select_db()) do
				if (coreTable) then
					if (coreTable.value == id) then
						dropdown_select_database:Select (i, true)
					end
				end
			end
		else
			dropdown_select_database:Select (false)
		end
	end
	
	panel:RefreshYourCoreDropdown()
	
	dropdown_set_backdrop (dropdown_select_database)
	dropdown_select_database:SetPoint ("left", label_change_database, "right", 2, 0)
	
	local create_new = function()
		RaidSchedule.main_frame:DisableRightPart()
		panel:EnableAll()
		panel:Reset()
	end
	
	local new_schedule_button = RA:CreateButton (panel, create_new, 180, 20, "Create New Core Schedule", _, _, _, "new_schedule_button", _, _, RaidSchedule:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"), RaidSchedule:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
	new_schedule_button:SetIcon ("Interface\\AddOns\\" .. RA.InstallDir .. "\\media\\plus", 10, 10, "overlay", {0, 1, 0, 1}, {1, 1, 1}, 4, 1, 0)
	
	local x = 470
	local y = 0
	
	label_edit:SetPoint ("topleft", main_frame, "topleft", x, 0 + y)
	label_change_database:SetPoint ("topleft", main_frame, "topleft", x, -30 + y)
	new_schedule_button:SetPoint ("topleft", main_frame, "topleft", x, -70 + y)

	dropdown_edit:Refresh()
	
	function panel:Refresh()
		dropdown_edit:Refresh()
	end
	
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

	function panel:DisableAll()
		panel.editbox_core_name:Disable()
		panel.dropdown_admin_rank:Disable()
		panel.button_create:Disable()
		for i = 1, 7 do
			panel ["switch_enabled" .. i]:Disable()
--			print (panel ["switch_enabled" .. i].Disable)
			panel ["dropdown_start_time_hour" .. i]:Disable()
			panel ["dropdown_start_time_min" .. i]:Disable()
			panel ["dropdown_end_time_hour" .. i]:Disable()
			panel ["dropdown_end_time_min" .. i]:Disable()
			panel ["dropdown_end_day" .. i]:Disable()
		end
		
		
		--print (panel ["switch_enabled1"].Disable)
		
	end
	
	function panel:DisableRightPart()
		button_edit:Disable()
		button_remove:Disable()
		new_schedule_button:Disable()
		dropdown_select_database:Disable()
		dropdown_edit:Disable()
	end
	
	function panel:EnableRightPart()
		button_edit:Enable()
		button_remove:Enable()
		new_schedule_button:Enable()
		dropdown_select_database:Enable()
		dropdown_edit:Enable()
	end	
	
	function panel:EnableAll()
		panel.editbox_core_name:Enable()
		panel.dropdown_admin_rank:Enable()
		panel.button_create:Enable()
		for i = 1, 7 do
			panel ["switch_enabled" .. i]:Enable()
			panel ["dropdown_start_time_hour" .. i]:Enable()
			panel ["dropdown_start_time_min" .. i]:Enable()
			panel ["dropdown_end_time_hour" .. i]:Enable()
			panel ["dropdown_end_time_min" .. i]:Enable()
			panel ["dropdown_end_day" .. i]:Enable()
		end
	end

	panel:DisableAll()
	
	
	
	RaidSchedule.create_schedule_panel = panel
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	
	panel:EnableAll()
	just_select_schedule_table()
	panel:DisableAll()
	
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	
	
	
	
end

local day_seconds = 86400

local get_epoch_raid_time = function (attendance, current_time, today)
	current_time = current_time or time()

	-- horario de hoje onde ir� iniciar a captura do attendance
	local raid_start = date ("*t", current_time)
	raid_start.hour = attendance.start_hour
	raid_start.min = attendance.start_min
	raid_start.sec = 0
	local day, month = raid_start.month, raid_start.day
	raid_start = time (raid_start)

	-- horario em que a raide terminar�
	local raid_end
	if (attendance.end_day == today) then
		raid_end = date ("*t", current_time)
	else
		raid_end = date ("*t", current_time+day_seconds)
	end
	raid_end.hour = attendance.end_hour
	raid_end.min = attendance.end_min
	raid_end.sec = 0
	raid_end = time (raid_end)
	
	return raid_start, raid_end, day, month
end

local get_raid_time = function (schedule_table, day, now, diff_days)
	local t = schedule_table [day]
	if (t.enabled) then
		local start_time, end_time, month_number, month_day = get_epoch_raid_time (t, now + (diff_days*day_seconds), day)
		if (now < start_time) then
			return start_time - now, start_time, end_time, month_number, month_day
		elseif (now > start_time and now < end_time) then
			return 0, start_time, end_time, month_number, month_day
		end
	end
end

--if week day is passed, it just convert from 1-7 to 0-6
local getWeekDayIndex = function (weekDay)
	--0-6 = Sunday-Saturday
	local todayWeekDay = weekDay or tonumber (date ("%w")) 
	--0 == sunsay
	if (todayWeekDay == 0) then 
		todayWeekDay = 7
	end
	return todayWeekDay
end

--get the time start and end for the next raid
local getUnixTime = function (weekScheduleTable)

	--get the 1-7 week index
	local todayWeekIndex = getWeekDayIndex()

	--store time() of start and end of the next event
	local startTime, endTime

	--check if today has an event today
	local dayTable = weekScheduleTable [todayWeekIndex]
	--if is enabled, there's an event today

	--[[
	if (dayTable.enabled) then
		
		--get a table with time information now
		--replace the hour and minute with the start event hour and time
		local timeTableStart = date ("*t", time())
		timeTableStart.hour = dayTable.start_hour
		timeTableStart.min = dayTable.start_min
		timeTableStart.sec = 0
		--get the time() at the start of the event
		startTime = time (timeTableStart)

		--check if the end time of the event is in the same day where it started
		if (dayTable.end_day == todayWeekIndex) then
			--the event starts and end on the same day
			local timeTableEnd = date ("*t", time())
			timeTableEnd.hour = dayTable.end_hour
			timeTableEnd.min = dayTable.end_min
			timeTableEnd.sec = 0
			--get the time() at the end of the event
			endTime = time (timeTableEnd)

		else
			--get the dayTable from the day where the event ends
			local endDayTable = weekScheduleTable [dayTable.end_day]

			--the event starts in one day and finishes in another
			local timeTableEnd = date ("*t", time() + 86400)
			timeTableEnd.hour = dayTable.end_hour
			timeTableEnd.min = dayTable.end_min
			timeTableEnd.sec = 0
			--get the time() at the end of the event
			endTime = time (timeTableEnd)
		end
		
	else --there's no event today
		--check if the end time of the previous day isn't today
		--so check if the raid isn't going on

		--get the dayTable from the day where the event ends
		local previousDay = dayTable.end_day - 1
		if (previousDay == 0) then
			previousDay = 7
		end

		local yesterdayTable = weekScheduleTable [previousDay]
		if (yesterdayTable.enabled) then

			--here I know an event started yesterday
			--but I don't know if the event is already done
			--I don't know if the event finished today

			--get the start of the yesterday event
			local timeTableStart = date ("*t", time() - 86400)
			timeTableStart.hour = dayTable.start_hour
			timeTableStart.min = dayTable.start_min
			timeTableStart.sec = 0
			--get the time() at the end of the event
			startTime = time (timeTableStart)

			if (yesterdayTable.end_day == todayWeekIndex) then
				--get the end of the yesterday event
				local timeTableEnd = date ("*t", time() - 86400)
				timeTableEnd.hour = dayTable.end_hour
				timeTableEnd.min = dayTable.end_min
				timeTableEnd.sec = 0
				--get the time() at the end of the event
				endTime = time (timeTableEnd)
			end
		end

		local todayWeekDay = tonumber (date ("%w")) --0-6 = Sunday-Saturday
		local todayWeekIndex = todayWeekDay
		if (todayWeekIndex == 0) then --0 == sunsay
			todayWeekIndex = 7
		end

	end
	--]]


	local timeNow = time()

	local nextRaidStart, nextRaidEnd = -1, -1

	for i = 0, 6 do --sunday to saturday
		local todayWeekIndex = i
		if (todayWeekIndex == 0) then --0 == sunsay
			todayWeekIndex = 7
		end

		local dayTable = weekScheduleTable [todayWeekIndex]

		if (dayTable.enabled) then

			local todayTable = date ("*t", current_time)

			local unixTime = time ({
				year = tonumber (date ("%Y")),
				month = tonumber (date ("%m")), 
				day = tonumber (date ("%d")),
				hour = weekScheduleTable [1].start_hour, 
				min = weekScheduleTable [1].start_min,
			})


		end
	end

end 

function RaidSchedule:GetNextEventTime (index)

	local current_core
	if (index) then
		current_core = RaidSchedule:GetRaidScheduleTable (index)
	else
		current_core = RaidSchedule:GetCharacterRaidScheduleTable()
		index = RaidSchedule:GetCharacterRaidScheduleTableIndex()
	end
	
	if (current_core) then
		local schedule_table = current_core.days_table
		local nextStart, nextEnd = getUnixTime (schedule_table)

		local now = time()
		local today_wday = tonumber (date ("%w"))
		
		if (today_wday == 0) then
			today_wday = 7 --sunday
		end
		
		local diff_days = 0
		
		for day = today_wday, 7 do
			local t, s, e, m, d = get_raid_time (schedule_table, day, now, diff_days)
			if (t) then 
				return t, s, e, day, m, d, index --time / start / end / weekday / month / day
			end
			diff_days = diff_days + 1
		end
		
		--using -1 here since the loop above goes from the current day until sunday
		--this loop goes from monday to yesterday by adding the -1
		--issue is if the event is today but the time already passed, it won't handle and will return nil causing errors
		for day = 1, today_wday do -- -1
			local t, s, e, m, d = get_raid_time (schedule_table, day, now, diff_days)
			if (t) then 
				return t, s, e, day, m, d, index
			end
			diff_days = diff_days + 1
		end
	end
end


local install_status = RA:InstallPlugin ("RaidSchedule", "RARaidSchedule", RaidSchedule, default_config)


--[[
function Attendance:GetPlayerGuildRank()
	local my_name = GetUnitName ("player")
	for i = 1, 999 do 
		local name, _, rankIndex = GetGuildRosterInfo (i)
		if (name == my_name) then	
			return rankIndex
		end
	end
end
--]]
