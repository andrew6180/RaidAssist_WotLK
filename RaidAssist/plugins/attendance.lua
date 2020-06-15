


local RA = RaidAssist
local L = LibStub ("AceLocale-3.0"):GetLocale ("RaidAssistAddon")
local _
local default_priority = 17

local GetUnitName = GetUnitName
local GetGuildInfo = GetGuildInfo

local week1, week2, week3, week4, week5, week6, week7 = "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"

local empty_func = function()end

local default_config = {
	raidschedules = {},
	playerids = {},
	menu_priority = 2,
	sorting_by = 1,
}

if (_G ["RaidAssistAttendance"]) then
	return
end
local Attendance = {version = "v0.1", pluginname = "Attendance"}
_G ["RaidAssistAttendance"] = Attendance

Attendance.debug = false
--Attendance.debug = true

local RaidSchedule

local icon_texcoord = {l=0, r=1, t=0, b=1}
local icon_texture = "Interface\\AddOns\\" .. RA.InstallDir .. "\\media\\attendance_flag"
local text_color_enabled = {r=1, g=1, b=1, a=1}
local text_color_disabled = {r=0.5, g=0.5, b=0.5, a=1}

Attendance.menu_text = function (plugin)
	if (Attendance.db.enabled) then
		return icon_texture, icon_texcoord, L["S_PLUGIN_ATTENDANCE_NAME"], text_color_enabled
	else
		return icon_texture, icon_texcoord, L["S_PLUGIN_ATTENDANCE_NAME"], text_color_disabled
	end
end

Attendance.menu_popup_hide = function (plugin, ct_frame, param1, param2)
	local popup_frame = Attendance.popup_frame
	popup_frame:Hide()
end

Attendance.menu_on_click = function (plugin)
	--if (not Attendance.options_built) then
	--	Attendance.BuildOptions()
	--	Attendance.options_built = true
	--end
	--Attendance.main_frame:Show()
	
	RA.OpenMainOptions (Attendance)
end

Attendance.StartUp = function()
	Attendance.player_name = GetUnitName ("player")
	
	if (not Attendance.player_name) then
		C_Timer.After (0.5, function() Attendance.StartUp() end)
		return
	end
	RaidSchedule = _G ["RaidAssistRaidSchedule"]
	if (not RaidSchedule) then
		C_Timer.After (0.5, function() Attendance.StartUp() end)
		return
	end
	
	Attendance:CheckForNextEvent()
	--Attendance:CheckOldTables()
	Attendance.need_popup_update = true
end

Attendance.OnInstall = function (plugin)
	local popup_frame = Attendance.popup_frame
	popup_frame.label_no_data = RA:CreateLabel (popup_frame, L["S_PLUGIN_ATTENDANCE_NO_DATA"], Attendance:GetTemplate ("font", "ORANGE_FONT_TEMPLATE"))
	popup_frame.label_no_data:SetPoint ("center", popup_frame, "center")
	popup_frame.label_no_data.width = 130
	popup_frame.label_no_data.height = 40
	
	Attendance.db.menu_priority = default_priority
	
	C_Timer.After (2, Attendance.StartUp)
end

function Attendance:CheckOldTables()
	local removed = 0
	for id, att_table in pairs (Attendance.db.raidschedules) do
		for day, day_table in pairs (att_table) do 
			if (day_table.t + 2592000 < time()) then
				att_table [day] = nil
				removed = removed + 1
			end
		end
	end

	--Attendance:Msg ("Removed", removed, "attendance tables outdated.")
end

Attendance.OnEnable = function (plugin)

end

Attendance.OnDisable = function (plugin)

end

Attendance.OnProfileChanged = function (plugin)

end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function Attendance:GetAttendanceTable (index)
	return Attendance.db.raidschedules [index]
end

function Attendance:OnFinishCapture()
	Attendance:Msg ("raid time ended.")
	Attendance.need_popup_update = true
end

function Attendance:Msg (...)
	if (Attendance.debug) then
		print ("|cFFFFDD00Attendance|r:", ...)
	end
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--doo

function Attendance.OnShowOnOptionsPanel()
	local OptionsPanel = Attendance.OptionsPanel
	Attendance.BuildOptions (OptionsPanel)
end

function Attendance.BuildOptions (frame)


	
	local sort_alphabetical = function(a,b) return a[1] < b[1] end
	local sort_bigger = function (a,b) return a[2] > b[2] end
	
	local fill_panel = Attendance:CreateFillPanel (frame, {}, 790, 400, false, false, false, {rowheight = 16}, "fill_panel", "AttendanceFillPanel")
	fill_panel:SetPoint ("topleft", frame, "topleft", 10, -30)
	
	local advise_panel = CreateFrame ("frame", nil, frame)
	advise_panel:SetPoint ("center", frame, "center", 790/2, -400/2)
	advise_panel:SetSize (460, 68)
	advise_panel:SetBackdrop ({edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize = 1, bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tileSize = 64, tile = true})
	advise_panel:SetBackdropColor (1, 1, 1, .5)
	advise_panel:SetBackdropBorderColor (0, 0, 0, 1)
	local advise_panel_text = advise_panel:CreateFontString (nil, "overlay", "GameFontNormal")
	advise_panel_text:SetPoint ("center", advise_panel, "center")
	Attendance:SetFontSize (advise_panel_text, 11)
	
	--box with the attendance tables
	Attendance.update_attendance = function()
	
		local scheduleId = frame.dropdown_schedule_list:GetValue()
		local current_db = Attendance.db.raidschedules [scheduleId] -- Attendance.db.raidschedules = scheduleId - days table
		--local _, current_db = next (Attendance.db.raidschedules) -- Attendance.db.raidschedules = scheduleId - days table

		if (current_db) then
		
			--> short from oldest to newer
			local alphabetical_months = {}
			for key, table in pairs (current_db) do
				local m, d = key:match ("(%d+)-(%d+)")
				if (string.len (d) == 1) then
					d = "0" .. d
				end
				local value = tonumber (m .. d)
				tinsert (alphabetical_months, {key, table, value})
			end
			
			table.sort (alphabetical_months, function (t1, t2) return t2[3] < t1[3] end)			
	
			--add the two initial headers for player name and total attendance
			local header = {{name = "Player Name", type = "text", width = 120}, {name = "ATT", type = "text", width = 60}}
			local players = {}
			local players_index = {}
			local amt_days = 0
			local sort = table.sort
			
			local maxDays = 20
			
			for i, table in ipairs (alphabetical_months) do

				local month = table [1]
				local att_table = table [2]
			
				amt_days = amt_days + 1
				if (amt_days > maxDays) then
					break
				end
				
				--add the header for this vertical row
				local time_at = date ("%a", att_table.t)
				
				tinsert (header, {name = table[1] .. "\n" .. time_at .. "", type = "text", width = 30, textsize = 9, textalign = "center", header_textsize = 9, header_textalign = "center"})
				
				for player_id, player_points in pairs (att_table.players) do
					local index = players_index [player_id]
					local player
					
					if (not index) then
						local player_name = Attendance:GetPlayerNameFromId (player_id)
						
						--first match for this player, fill the previous days with "-"
						player = {player_name, 0}
						for o = 1, i-1 do
							tinsert (player, "-")
						end
						tinsert (player, player_points)
						player[2] = player[2] + player_points
						tinsert (players, player)
						players_index [player_id] = #players
					else
						player = players [index]
						
						--fill the player table if he missed some days
						for o = #player+1, i-1 do
							tinsert (player, "-")
						end
						
						player[2] = player[2] + player_points
						tinsert (player, player_points)
					end					
				end
			end
			
			--fill the player table is he missed all days until the end
			for index, player_table in ipairs (players) do
				for i = #player_table-1, amt_days do
					tinsert (player_table, "-")
				end
			end
			
			if (not Attendance.db.sorting_by or Attendance.db.sorting_by == 1) then
				sort (players, sort_alphabetical)
			elseif (Attendance.db.sorting_by == 2) then
				sort (players, sort_bigger)
			end
			
			frame.fill_panel:SetFillFunction (function (index) return players [index] end)
			frame.fill_panel:SetTotalFunction (function() return #players end)
			
			--frame:SetSize (math.min (GetScreenWidth()-200, #header*100), (#players*16) + 32)
			frame:SetSize (math.min (GetScreenWidth()-200, (#header*60) + 60), 425)
			--frame.fill_panel:SetSize (math.min (GetScreenWidth()-200, #header*100), (#players*16) + 32)
			frame.fill_panel:SetSize (math.min (GetScreenWidth()-200, (#header*60) + 60), 425)
			
			frame.fill_panel:UpdateRows (header)
			frame.fill_panel:Refresh()
			
			advise_panel:Hide()
			frame.fill_panel:Show()
		else
			if (RaidSchedule and next (RaidSchedule.db.cores)) then
				advise_panel_text:SetText ("No attendance has been recorded yet.")
			else
				advise_panel_text:SetText ("No attendance has been recorded yet, make sure to create a Raid Schedule.\nAttendance is automatically captured during your raid once a schedule is set.")
			end
			
			advise_panel:Show()
			frame.fill_panel:Hide()
		end

	end
	
	if (frame.FirstRun) then
		Attendance.update_attendance()
		return
	end
	frame.FirstRun = true	
	
	local on_select_schedule = function (_, _, scheduleId)
		Attendance.update_attendance()
	end
	
	local build_schedule_list = function()
		local t = {}
		for raidschedule_index, schedule_table in pairs (Attendance.db.raidschedules) do
			local schedule = RaidSchedule:GetRaidScheduleTable (raidschedule_index)
			if (schedule) then
				tinsert (t, {value = raidschedule_index, label = schedule.core_name, onclick = on_select_schedule})
			end
		end
		return t
	end
	
	local label_raidschedule = Attendance:CreateLabel (frame, "Schedule" .. ": ", Attendance:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
	local dropdown_raidschedule = Attendance:CreateDropDown (frame, build_schedule_list, 1, 160, 20, "dropdown_schedule_list", _, Attendance:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"))
	dropdown_raidschedule:SetPoint ("left", label_raidschedule, "right", 2, 0)
	label_raidschedule:SetPoint (10, -10)
	dropdown_raidschedule:Refresh()
	dropdown_raidschedule:Select (1, true)
	
	local reset_func_callback = function (text)
		--if (YES:lower() == text:lower()) then
			--> wipe
			local scheduleId = frame.dropdown_schedule_list:GetValue()
			if (not scheduleId) then
				return
			end
			
			local current_db = Attendance.db.raidschedules [scheduleId]
			if (current_db) then
				for key, table in pairs (current_db) do
					current_db [key] = nil
				end
			end
			
			Attendance.update_attendance()
		--end
	end
	local reset_func = function()
		Attendance:ShowPromptPanel ("Are you sure you want to reset?", reset_func_callback, empty_func)
		--Attendance:ShowTextPromptPanel ("Are you sure you want to reset? (type 'yes')", reset_func_callback)
	end
	local reset_button =  Attendance:CreateButton (frame, reset_func, 80, 20, "Reset", _, _, _, "button_reset", _, _, Attendance:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"), Attendance:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
	reset_button:SetPoint ("left", dropdown_raidschedule, "right", 10, 0)
	reset_button:SetIcon ([[Interface\BUTTONS\UI-StopButton]], 14, 14, "overlay", {0, 1, 0, 1}, {1, 1, 1}, 2, 1, 0)

	local sort1_button =  Attendance:CreateButton (frame, function() Attendance.db.sorting_by = 1; Attendance.update_attendance() end, 80, 20, "Sort A-Z", _, _, _, "button_sort1", _, _, Attendance:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"), Attendance:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
	sort1_button:SetPoint ("left", reset_button, "right", 2, 0)
	sort1_button:SetIcon ([[Interface\BUTTONS\UI-StopButton]], 14, 14, "overlay", {0, 1, 0, 1}, {1, 1, 1}, 2, 1, 0)

	local sort2_button =  Attendance:CreateButton (frame, function() Attendance.db.sorting_by = 2; Attendance.update_attendance() end, 80, 20, "Sort ATT", _, _, _, "button_sort2", _, _, Attendance:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"), Attendance:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
	sort2_button:SetPoint ("left", sort1_button, "right", 2, 0)
	sort2_button:SetIcon ([[Interface\BUTTONS\UI-StopButton]], 14, 14, "overlay", {0, 1, 0, 1}, {1, 1, 1}, 2, 1, 0)

	local pos = -frame.fill_panel:GetHeight() - 70
	for i, rank in pairs(RA:GetGuildRanks()) do 
		local rank_label = Attendance:CreateLabel (frame, "Ignore "..rank..":", Attendance:GetTemplate("font", "OPTIONS_FONT_TEMPLATE"))
		Attendance.db.ignore_rank = Attendance.db.ignore_rank or {}
		Attendance.db.ignore_rank[i] = Attendance.db.ignore_rank[i] or false
		local rank_checkbox = Attendance:CreateSwitch (frame, function(_, _, value) Attendance.db.ignore_rank[i] = value end, Attendance.db.ignore_rank[i], 60, 20, _, _, "rank_enabled"..i, _, _, _, _, _, Attendance:GetTemplate("switch", "OPTIONS_CHECKBOX_BRIGHT_TEMPLATE"))
		rank_checkbox:SetAsCheckBox()
		rank_label:SetPoint("topleft", frame, "topleft", 2, pos)
		rank_checkbox:SetPoint("left", rank_label, "right", 2, 0)
		pos = pos - 25
	end
	
	frame:SetScript ("OnShow", function()
		Attendance.update_attendance()
		dropdown_raidschedule:Refresh()
		--dropdown_raidschedule:Select (1, true)
	end)
	
	Attendance.update_attendance()
	
end

local install_status = RA:InstallPlugin (L["S_PLUGIN_ATTENDANCE_NAME"], "RAAttendance", Attendance, default_config)


------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function Attendance:CheckForNextEvent()
	local next_event_in, start_time, end_time, day, month_number, month_day, index = RaidSchedule:GetNextEventTime()
	if (next_event_in) then
		Attendance:Msg ("Attendance Next Event:", next_event_in)
		
		local now = time()
		if (now < next_event_in) then
			C_Timer.After (next_event_in+1, Attendance.CheckForNextEvent)
			Attendance:Msg ("Nop, next event is too far away.")
		elseif (next_event_in == 0) then --return 0 if time() is bigger than the start time
			if (Attendance.is_capturing) then
				Attendance:Msg ("Is already capturing.")
				return
			else
				Attendance:Msg ("Need to start capturing.")
				Attendance:StartNewCapture (start_time, end_time, now, day, month_number, month_day, index)
			end
		end
	else
		C_Timer.After (60, Attendance.CheckForNextEvent)
	end
end

function Attendance:CaptureIsOver()
	--> clean up
	Attendance.capture_ticker = nil
	Attendance.is_capturing = nil
	Attendance.db_table = nil
	Attendance.player_table = nil
	Attendance.guild_name = nil
	
	--> on finish
	Attendance:OnFinishCapture()
	
	--> check next event
	C_Timer.After (5, Attendance.CheckForNextEvent)
end

function Attendance:GetPlayerID (unitid)
	local name = UnitName (unitid)
	if (name) then
		return name
	end
end

function Attendance:GetPlayerNameFromId (id)
	return Attendance.db.playerids [id] or id
end

function Attendance:StartNewCapture (start_time, end_time, now, day, month_number, month_day, raidschedule_index)

	--> get the raidschedule table from the database
	local db = Attendance.db.raidschedules [raidschedule_index]
	if (not db) then
		Attendance.db.raidschedules [raidschedule_index] = {}
		db = Attendance.db.raidschedules [raidschedule_index]
	end

	--> get 'todays' key id
	local key = "" .. month_number .. "-" .. month_day
	
	--> get the GUID table with the 'todays' attendance
	local ctable = db [key]
	if (not ctable) then
		db [key] = {t = time(), players = {}}
		ctable = db [key]
	end
	
	Attendance.is_capturing = true
	Attendance.db_table = db
	Attendance.player_table = ctable
	Attendance.guild_name = GetGuildInfo ("player")
	
	local ticks = floor ((end_time - time()) / 60) -- usava 'start_time' ao inv�s de time(), mas se der /reload ou entrar na j� em andamento vai zuar o tempo total da captura.
	
	Attendance:StartCapture (ticks)
	
	Attendance:Msg ("Raid time started.", ticks)
end

local do_capture_tick = function (tick_object)

	local amt_player = 0
	local player_table = Attendance.player_table.players --holds [player id] = number
	local name_pool = Attendance.db.playerids
	local show_offline = GetGuildRosterShowOffline()
	SetGuildRosterShowOffline(false)
	
	for i = 1, GetNumGuildMembers() do 
		local name, _, rank_id = GetGuildRosterInfo(i)
		if name and rank_id and not Attendance.db.ingore_rank[rank_id] then 
			player_table [name] = (player_table [name] or 0) + 1
			amt_player = amt_player + 1
			if not name_pool [name] then 
				name_pool [name] = name
			end
		end
	end

	SetGuildRosterShowOffline(show_offline)
	Attendance:Msg ("Tick", amt_player, "counted.")
	
	if (tick_object._remainingIterations == 1) then
		--> it's over
		Attendance:CaptureIsOver()
	end
end

function Attendance:StartCapture (ticks)
	-- cancel any tick ongoing
	if (Attendance.capture_ticker and not Attendance.capture_ticker._cancelled) then
		Attendance.capture_ticker:Cancel()
		Attendance:Msg ("Capture ticker is true, cancelling and starting a new one.")
	end
	
	-- start the ticker
	Attendance.capture_ticker = C_Timer.NewTicker (60, do_capture_tick, ticks-1)
	Attendance:Msg ("Capture ticker has been started.")
end


-- ao receber NEW verifica se quem mandou � guild master, somente GM pode criar novas tabelas.
-- NEW todos criam as tabelas.

-- ao receber EDIT verifica se quem mandou � officer do attendance ou guild master.
-- GM pode editar todas as tabelas, officer apenas as deles.

-- ao receber DELETE verifica se quem mandou � officer/gm ou se a guilda que o player esta � difirente da tabela.

-- SHAREAR INDEXES

-- somente officer mandam informa��es
-- officers somente recebem informa��es de outro officer para sincronizar as tabelas

-- officer manda o index do dia e espera alguem pedir
-- e vai mandando e shariando com todos na raide

