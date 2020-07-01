
local RA = RaidAssist
local L = LibStub ("AceLocale-3.0"):GetLocale ("RaidAssistAddon")

local _ 

local default_priority = 1
local default_config = {
	enabled = true,
	menu_priority = 1,
	
	show_window_after = 0.9,
	text_size = 10,
	text_face = "Friz Quadrata TT",
	text_shadow = false,
}

local icon_texcoord = {l=0, r=1, t=0, b=1}
local text_color_enabled = {r=1, g=1, b=1, a=1}
local text_color_disabled = {r=0.5, g=0.5, b=0.5, a=1}
local icon_texture = "Interface\\AddOns\\" .. RA.InstallDir .. "\\media\\Check"

if (_G ["RaidAssistReadyCheck"]) then
	return
end
local ReadyCheck = {version = "v0.1", pluginname = "Ready Check"}
_G ["RaidAssistReadyCheck"] = ReadyCheck

ReadyCheck.debug = false

local COMM_READY_CHECK_CONFIRM = "RCC" 
local COMM_READY_CHECK_FINISHED = "RCF"
ReadyCheck.menu_text = function (plugin)
	if (ReadyCheck.db.enabled) then
		return icon_texture, icon_texcoord, "Ready Check", text_color_enabled
	else
		return icon_texture, icon_texcoord, "Ready Check", text_color_disabled
	end
end

ReadyCheck.menu_popup_show = function (plugin, ct_frame, param1, param2)
	RA:AnchorMyPopupFrame (ReadyCheck)
end

ReadyCheck.menu_popup_hide = function (plugin, ct_frame, param1, param2)
	ReadyCheck.popup_frame:Hide()
end

ReadyCheck.menu_on_click = function (plugin)

end

ReadyCheck.OnInstall = function (plugin)
	ReadyCheck.db.menu_priority = default_priority
	
	if (ReadyCheck.db.enabled) then
		ReadyCheck.BuildScreenFrames()
	end
end


ReadyCheck.OnEnable = function (plugin)
	-- enabled from the options panel.
	if (not ReadyCheck.ScreenPanel) then
		ReadyCheck.BuildScreenFrames()
	end
	
	ReadyCheck:RegisterEvent ("READY_CHECK")
	ReadyCheck:RegisterEvent ("READY_CHECK_CONFIRM")
	ReadyCheck:RegisterEvent ("READY_CHECK_FINISHED")
	ReadyCheck:RegisterEvent ("ENCOUNTER_START")
	ReadyCheck:RegisterEvent ("PLAYER_REGEN_DISABLED")
end

ReadyCheck.OnDisable = function (plugin)
	-- disabled from the options panel.
	if (ReadyCheck.ScreenPanel) then
		ReadyCheck.ScreenPanel:Hide()
		ReadyCheck:UnregisterEvent ("READY_CHECK")
		ReadyCheck:UnregisterEvent ("READY_CHECK_CONFIRM")
		ReadyCheck:UnregisterEvent ("READY_CHECK_FINISHED")
		ReadyCheck:UnregisterEvent ("ENCOUNTER_START")
		ReadyCheck:UnregisterEvent ("PLAYER_REGEN_DISABLED")
	end
end

ReadyCheck.OnProfileChanged = function (plugin)
	if (plugin.db.enabled) then
		ReadyCheck.OnEnable (plugin)
	else
		ReadyCheck.OnDisable (plugin)
	end
	
	if (plugin.options_built) then
		
	end
end

function ReadyCheck.BuildScreenFrames()
	local ScreenPanel = ReadyCheck:CreateCleanFrame (ReadyCheck, "ReadyCheckScreenFrame")
	ScreenPanel:SetSize (300, 200)
	
	local ProgressBar = ReadyCheck:CreateBar (ScreenPanel, nil, 300, 16, 100)
	ProgressBar:SetFrameLevel (ScreenPanel:GetFrameLevel()+1)
	ProgressBar.RightTextIsTimer = true
	ProgressBar.BarIsInverse = true
	ProgressBar:SetPoint ("topleft", ScreenPanel, "topleft", 10, -50)
	ProgressBar:SetPoint ("topright", ScreenPanel, "topright", -10, -50)
	ProgressBar.texture = "Iskar Serenity"
	
	local TitleString = ReadyCheck:CreateLabel (ScreenPanel, "Ready Check")
	TitleString:SetPoint ("topleft", ScreenPanel, "topleft", 8, -10)
	ReadyCheck:SetFontSize (TitleString, 14)
	ReadyCheck:SetFontColor (TitleString, "orange")
	ReadyCheck:SetFontOutline (TitleString, true)
	
	local From = ReadyCheck:CreateLabel (ScreenPanel, "")
	From:SetPoint ("topleft", ScreenPanel, "topleft", 10, -28)

	ReadyCheck.PlayerList = {}
	local x = 10
	local y = -75
	for i = 1, 40 do
		local Cross = ReadyCheck:CreateImage (ScreenPanel, "Interface\\Glues\\LOGIN\\Glues-CheckBox-Check", 16, 16, "overlay")
		local Label = ReadyCheck:CreateLabel (ScreenPanel, "Player Name")
		Label:SetPoint ("left", Cross, "right", 2, 0)
		Cross.Label = Label
		Cross:SetPoint ("topleft", ScreenPanel, "topleft", x, y)
		if (i%2 == 0) then
			x = 10
			y = y - 16
		else
			x = 140
		end
		Cross:Hide()
		tinsert (ReadyCheck.PlayerList, Cross)
	end
	
	ReadyCheck.UpdateTextSettings()
	
	ReadyCheck.ScreenPanel = ScreenPanel
	ReadyCheck.ProgressBar = ProgressBar
	ReadyCheck.TitleString = TitleString
	ReadyCheck.From = From
	
	ScreenPanel:Hide()
	
	--> ready check events
	ReadyCheck:RegisterEvent ("READY_CHECK")
	ReadyCheck:RegisterEvent ("READY_CHECK_CONFIRM")
	ReadyCheck:RegisterEvent ("READY_CHECK_FINISHED")
	ReadyCheck:RegisterEvent ("ENCOUNTER_START")
	ReadyCheck:RegisterEvent ("PLAYER_REGEN_DISABLED")
	
end

function ReadyCheck.OnShowOnOptionsPanel()
	local OptionsPanel = ReadyCheck.OptionsPanel
	ReadyCheck.BuildOptions (OptionsPanel)
end

function ReadyCheck.UpdateTextSettings()
	local SharedMedia = LibStub:GetLibrary ("LibSharedMedia-3.0")
	local db = ReadyCheck.db
	
	local font = SharedMedia:Fetch ("font", db.text_font)
	local size = db.text_size
	local shadow = db.text_shadow
	
	for Index, Player in ipairs (ReadyCheck.PlayerList or {}) do
		ReadyCheck:SetFontFace (Player.Label, font)
		ReadyCheck:SetFontSize (Player.Label, size)
		ReadyCheck:SetFontOutline (Player.Label, shadow)
	end
end

function ReadyCheck.BuildOptions (frame)

	if (frame.FirstRun) then
		return
	end
	frame.FirstRun = true

	local on_select_text_font = function (self, fixed_value, value)
		ReadyCheck.db.text_font = value
		ReadyCheck.UpdateTextSettings()
	end
	
	-- options panel
	local options_list = {
		{type = "label", get = function() return "General Options:" end, text_template = ReadyCheck:GetTemplate ("font", "ORANGE_FONT_TEMPLATE")},
		{
			type = "toggle",
			get = function() return ReadyCheck.db.enabled end,
			set = function (self, fixedparam, value) 
				ReadyCheck.db.enabled = value
				if (not value) then
					if (ReadyCheck.ScreenPanel) then
						ReadyCheck.ScreenPanel:SetScript ("OnUpdate", nil)
						if (ReadyCheck.ScreenPanel:IsShown()) then
							ReadyCheck.ScreenPanel:Hide()
						end
					end
				end
			end,
			name = "Enabled",
		},
		
		{type = "blank"},
		--{type = "label", get = function() return "Text Settings:" end, text_template = ReadyCheck:GetTemplate ("font", "ORANGE_FONT_TEMPLATE")},
		
		{
			type = "range",
			get = function() return ReadyCheck.db.text_size end,
			set = function (self, fixedparam, value) 
				ReadyCheck.db.text_size = value
				ReadyCheck.UpdateTextSettings()
			end,
			min = 4,
			max = 32,
			step = 1,
			name = L["S_PLUGIN_TEXT_SIZE"],
			
		},
		{
			type = "select",
			get = function() return ReadyCheck.db.text_font end,
			values = function() 
				return ReadyCheck:BuildDropDownFontList (on_select_text_font) 
			end,
			name = L["S_PLUGIN_TEXT_FONT"],
			
		},
		{
			type = "toggle",
			get = function() return ReadyCheck.db.text_shadow end,
			set = function (self, fixedparam, value) 
				ReadyCheck.db.text_shadow = value
				ReadyCheck.UpdateTextSettings()
			end,
			name = L["S_PLUGIN_TEXT_SHADOW"],
		},
	}
	
	local options_text_template = ReadyCheck:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE")
	local options_dropdown_template = ReadyCheck:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE")
	local options_switch_template = ReadyCheck:GetTemplate ("switch", "OPTIONS_CHECKBOX_TEMPLATE")
	local options_slider_template = ReadyCheck:GetTemplate ("slider", "OPTIONS_SLIDER_TEMPLATE")
	local options_button_template = ReadyCheck:GetTemplate ("button", "OPTIONS_BUTTON_TEMPLATE")
	
	ReadyCheck:SetAsOptionsPanel (frame)
	ReadyCheck:BuildMenu (frame, options_list, 0, 0, 300, true, options_text_template, options_dropdown_template, options_switch_template, true, options_slider_template, options_button_template)

	
end

local hide_screen_panel = function()
	if (ReadyCheck.ScreenPanel and ReadyCheck.ScreenPanel:IsShown()) then
		ReadyCheck.ScreenPanel:Hide()
	end
end

local check_onupdate = function (self, elapsed)

		for _, Player in ipairs (ReadyCheck.PlayerList) do
			Player:Hide()
			Player.Label:Hide()
		end
		
		if (not ReadyCheck.db.enabled) then
			return
		end
		
		-- true = answered
		-- false = did answered 'not ready'
		-- "afk" = no answer from the start of the check
		-- "offline" = offline at the start of the check
		
		local index = 1
		for player, answer in pairs (ReadyCheck.AnswerTable) do
		
			local _, class = UnitClass (player)
			
			if (answer == "offline") then
				ReadyCheck.PlayerList [index]:Show()
				ReadyCheck.PlayerList [index].Label:Show()
				
				ReadyCheck.PlayerList [index]:SetTexture ([[Interface\CHARACTERFRAME\Disconnect-Icon]])
				ReadyCheck.PlayerList [index]:SetTexCoord (18/64, (64-18)/64, 14/64, (64-14)/64)
				
				local color = class and RAID_CLASS_COLORS [class] and RAID_CLASS_COLORS [class].colorStr or "ffffffff"
				ReadyCheck.PlayerList [index].Label:SetText ("|c" .. color .. ReadyCheck:RemoveRealName (player) .. "|r" .. " (|cFFFF3300offline|r)")
				index = index + 1
				
			elseif (answer == "afk") then
				if (GetTime() > ReadyCheck.ScreenPanel.EndAt - ReadyCheck.ScreenPanel.ShowAFKPlayersAt) then
					ReadyCheck.PlayerList [index]:Show()
					ReadyCheck.PlayerList [index].Label:Show()
					
					ReadyCheck.PlayerList [index]:SetTexture ([[Interface\FriendsFrame\StatusIcon-Away]])
					ReadyCheck.PlayerList [index]:SetTexCoord (0, 1, 0, 1)

					local color = class and RAID_CLASS_COLORS [class] and RAID_CLASS_COLORS [class].colorStr or "ffffffff"
					ReadyCheck.PlayerList [index].Label:SetText ("|c" .. color .. ReadyCheck:RemoveRealName (player) .. "|r" .. " (|cFFFF3300afk|r)")
					
					index = index + 1
				end
				
			elseif (answer == false) then
				ReadyCheck.PlayerList [index]:Show()
				ReadyCheck.PlayerList [index].Label:Show()
				
				ReadyCheck.PlayerList [index]:SetTexture ("Interface\\Glues\\LOGIN\\Glues-CheckBox-Check")
				ReadyCheck.PlayerList [index]:SetTexCoord (0, 1, 0, 1)
				
				local color = class and RAID_CLASS_COLORS [class] and RAID_CLASS_COLORS [class].colorStr or "ffffffff"
				ReadyCheck.PlayerList [index].Label:SetText ("|c" .. color .. ReadyCheck:RemoveRealName (player) .. "|r" .. " (|cFFFFAA00not ready|r)")
				index = index + 1
			end
		end

		index = index - 1
		
		ReadyCheck.ScreenPanel:SetHeight (80 + (math.ceil (index / 2) * 17))

end

function ReadyCheck:READY_CHECK (event, player, timeout)
	
	--print (timeout)
	
	--ready check started
	if (ReadyCheck.db.enabled) then
		ReadyCheck.AnswerTable = ReadyCheck.AnswerTable or {}
		wipe (ReadyCheck.AnswerTable)

		local amt = 0
		for i = 1, GetNumGroupMembers() do
			local name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML = GetRaidRosterInfo (i)
			if (player ~= name) then
				ReadyCheck.AnswerTable [name] = "afk"
				amt = amt + 1
			end
		end
		
		ReadyCheck.ScreenPanel:Show()
		ReadyCheck.ProgressBar:SetTimer (timeout)
		ReadyCheck.Waiting = amt
		ReadyCheck.From.text = "From: " .. player
		ReadyCheck.From.player = player
		
		local _, class = UnitClass (player)
		if (class) then
			local color = RAID_CLASS_COLORS [class]
			if (color) then
				print ("|cFFFFDD00RaidAssist (/raa):|cFFFFFF00 ready check from |c" .. color.colorStr .. player .. "|r|cFFFFFF00 at " .. date ("%H:%M") .. "|r")
			else
				print ("|cFFFFDD00RaidAssist (/raa):|cFFFFFF00 ready check from " .. player .. " at " .. date ("%H:%M") .. "|r")
			end
		else
			print ("|cFFFFDD00RaidAssist (/raa):|cFFFFFF00 ready check from " .. player .. " at " .. date ("%H:%M") .. "|r")
		end
		
		for Index, Player in ipairs (ReadyCheck.PlayerList) do
			Player:Hide()
			Player.Label:Hide()
		end
		
		ReadyCheck.ScreenPanel:SetHeight (80)
		
		ReadyCheck.ScreenPanel.ShowAFKPlayersAt = timeout * ReadyCheck.db.show_window_after
		ReadyCheck.ScreenPanel.StartAt = GetTime()
		ReadyCheck.ScreenPanel.EndAt = GetTime() + timeout
		ReadyCheck.ScreenPanel:SetScript ("OnUpdate", check_onupdate)
	end
end

function ReadyCheck:READY_CHECK_CONFIRM (event, player, status, arg4, arg5)
	
	player = UnitName(player)
	print(event, player, status)
	-- retornou false pra n�o pronto
	-- retornou true para pronto
	if (ReadyCheck.db.enabled and ReadyCheck.AnswerTable and ReadyCheck.ScreenPanel) then
		local PlayerName = player
		if (PlayerName and ReadyCheck.AnswerTable [PlayerName] ~= nil) then
			if (not status and ReadyCheck.ScreenPanel.StartAt and ReadyCheck.ScreenPanel.StartAt + 0.3 and not UnitIsConnected (player)) then
				ReadyCheck.AnswerTable [PlayerName] = "offline"
			elseif (ReadyCheck.AnswerTable [PlayerName] ~= "offline") then
				if (ReadyCheck.AnswerTable [PlayerName] == false and status == false) then
					--if (ReadyCheck.ScreenPanel.EndAt -1 > GetTime()) then --isn't sending answers at the end
						ReadyCheck.AnswerTable [PlayerName] = status
					--end
				else
					ReadyCheck.AnswerTable [PlayerName] = status
				end
			end
			if ReadyCheck.From.player == UnitName("player") then 
				ReadyCheck:SendPluginCommMessage(COMM_READY_CHECK_CONFIRM, "RAID", nil, nil, player, status)
			end
		end
	end
end

local finished_func = function()
	if (ReadyCheck.ScreenPanel) then
		ReadyCheck.ScreenPanel:SetScript ("OnUpdate", nil)
		if (ReadyCheck.ScreenPanel:IsShown()) then
			ReadyCheck.ProgressBar:SetTimer (0)
			C_Timer.After (4, hide_screen_panel)
		end
	end
end

function ReadyCheck:READY_CHECK_FINISHED (event, arg2, arg3)

	if ReadyCheck.From.player == UnitName("player") then 
		ReadyCheck:SendPluginCommMessage(COMM_READY_CHECK_FINISHED, "RAID")
	end
	C_Timer.After (1, finished_func)

	if (ReadyCheck.db.enabled) then
		print (event, arg2, arg3)
	end
	
end

local combat_start = function()
	C_Timer.After (1, finished_func)
end

function ReadyCheck:PLAYER_REGEN_DISABLED()
	combat_start()
end
function ReadyCheck:ENCOUNTER_START()
	combat_start()
end

local install_status = RA:InstallPlugin ("Ready Check", "RAReadyCheck", ReadyCheck, default_config)


function ReadyCheck.OnReceiveComm (prefix, sourcePluginVersion, player, status)
	if UnitIsGroupLeader("player") then 
		return 
	end

	if (prefix == COMM_READY_CHECK_CONFIRM) then 
		ReadyCheck:READY_CHECK_CONFIRM("READY_CHECK_CONFIRM", player, status)
	elseif (prefix == COMM_READY_CHECK_FINISHED) then
		ReadyCheck:READY_CHECK_FINISHED("READY_CHECK_FINISHED")
	end
end	

RA:RegisterPluginComm (COMM_READY_CHECK_CONFIRM, ReadyCheck.OnReceiveComm)
RA:RegisterPluginComm (COMM_READY_CHECK_FINISHED, ReadyCheck.OnReceiveComm)