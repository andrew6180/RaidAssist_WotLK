
local RA = RaidAssist
local L = LibStub ("AceLocale-3.0"):GetLocale ("RaidAssistAddon")
local _ 
local default_priority = 15

local default_config = {
	enabled = false,
	menu_priority = 1,
	frame_scale = 1,
	frame_orientation = "H",
	reverse_order = true,
	pull_timer = 15,
	readycheck_timer = 35,
	hide_in_combat = true,
	hide_not_in_group = false,
}

local text_color_enabled = {r=1, g=1, b=1, a=1}
local text_color_disabled = {r=0.5, g=0.5, b=0.5, a=1}

local toolbar_icon = [[Interface\CastingBar\UI-CastingBar-Border]]
local icon_texcoord = {l=25/256, r=80/256, t=14/64, b=49/64}

if (_G ["RaidAssistLeaderToolbar"]) then
	return
end
local LeaderToolbar = {version = "v0.1", pluginname = "Leader Toolbar"}
_G ["RaidAssistLeaderToolbar"] = LeaderToolbar

LeaderToolbar.menu_text = function (plugin)
	if (LeaderToolbar.db.enabled) then
		return toolbar_icon, icon_texcoord, "Leader Toolbar", text_color_enabled
	else
		return toolbar_icon, icon_texcoord, "Leader Toolbar", text_color_disabled
	end
end

LeaderToolbar.menu_popup_show = function (plugin, ct_frame, param1, param2)

end

LeaderToolbar.menu_popup_hide = function (plugin, ct_frame, param1, param2)

end

LeaderToolbar.menu_on_click = function (plugin)

end

LeaderToolbar.OnInstall = function (plugin)
	LeaderToolbar.db.menu_priority = default_priority
	
	if (LeaderToolbar.db.enabled) then
		LeaderToolbar.OnEnable (LeaderToolbar)
	end
end

function LeaderToolbar.CanShow()
	local can_show = true

	if (not LeaderToolbar.db.enabled) then
		can_show = false
	end
	if (LeaderToolbar.db.hide_in_combat) then
		if (UnitAffectingCombat ("player")) then
			can_show = false
		end
	end
	if (LeaderToolbar.db.hide_not_in_group) then
		if (not IsInGroup()) then
			can_show = false
		end
	end
	
	--> we can't hide or show this frame while the interface is Lockdown
	if (not InCombatLockdown()) then
		if (not can_show) then
			if (LeaderToolbar.ScreenPanel) then
				if (LeaderToolbar.ScreenPanel:IsShown()) then
					LeaderToolbar.ScreenPanel:Hide()
				end
			end
		else
			if (LeaderToolbar.ScreenPanel) then
				if (not LeaderToolbar.ScreenPanel:IsShown()) then
					LeaderToolbar.ScreenPanel:Show()
				end
			end
		end
	end

	return can_show
end

function LeaderToolbar:PLAYER_REGEN_DISABLED()
	if (LeaderToolbar.db.hide_in_combat) then
		LeaderToolbar.CanShow()
	end
end

function LeaderToolbar:PLAYER_REGEN_ENABLED()
	if (LeaderToolbar.db.hide_in_combat) then
		LeaderToolbar.CanShow()
	end
end

function LeaderToolbar:PARTY_MEMBERS_CHANGED()
	if (LeaderToolbar.db.hide_not_in_group) then
		LeaderToolbar.CanShow()
	end
end

function LeaderToolbar:RAID_ROSTER_UPDATE()
	LeaderToolbar:PARTY_MEMBERS_CHANGED()
end

LeaderToolbar.OnEnable = function (plugin)
	LeaderToolbar:RegisterEvent ("PLAYER_REGEN_DISABLED")
	LeaderToolbar:RegisterEvent ("PLAYER_REGEN_ENABLED")
	LeaderToolbar:RegisterEvent ("PARTY_MEMBERS_CHANGED")
	LeaderToolbar:RegisterEvent ("RAID_ROSTER_UPDATE")
	if (not LeaderToolbar.ScreenPanel) then
		LeaderToolbar.CreateScreenPanel()
	end
	
	LeaderToolbar.CanShow()
end

LeaderToolbar.OnDisable = function (plugin)

	LeaderToolbar:UnregisterEvent ("PLAYER_REGEN_DISABLED")
	LeaderToolbar:UnregisterEvent ("PLAYER_REGEN_ENABLED")
	LeaderToolbar:UnregisterEvent ("PARTY_MEMBERS_CHANGED")
	LeaderToolbar:UnregisterEvent ("RAID_ROSTER_UPDATE")
	if (LeaderToolbar.ScreenPanel) then
		if (LeaderToolbar.ScreenPanel:IsShown()) then
			LeaderToolbar.ScreenPanel:Hide()
		end
	end	
end

LeaderToolbar.OnProfileChanged = function (plugin)

end

function LeaderToolbar.OnShowOnOptionsPanel()
	local OptionsPanel = LeaderToolbar.OptionsPanel
	LeaderToolbar.BuildOptions (OptionsPanel)
end

local align_raidmarkers = function()
	local ScreenPanel = LeaderToolbarScreenFrame
	if (ScreenPanel and LeaderToolbar.MarkersButtons) then
		if (LeaderToolbar.db.reverse_order) then
			local o = 1
			for i = 8, 1, -1 do
				local button = LeaderToolbar.MarkersButtons [i]
				button:ClearAllPoints()
				button:SetPoint ("topleft", ScreenPanel, "topleft", 3 + ((o-1)*21), -3)
				o = o + 1
			end
		else
			for i = 1, 8 do
				local button = LeaderToolbar.MarkersButtons [i]
				button:ClearAllPoints()
				button:SetPoint ("topleft", ScreenPanel, "topleft", 3 + ((i-1)*21), -3)
			end
		end
	end
end

local adjust_scale = function()
	local ScreenPanel = LeaderToolbarScreenFrame
	if (ScreenPanel and LeaderToolbar.MarkersButtons) then
		ScreenPanel:SetScale (LeaderToolbar.db.frame_scale)
	end
end


function LeaderToolbar.CreateScreenPanel()

	local ScreenPanel = LeaderToolbar:CreateCleanFrame (LeaderToolbar, "LeaderToolbarScreenFrame")
	ScreenPanel:SetSize (292, 46)
	LeaderToolbar.ScreenPanel = ScreenPanel
	
	DetailsFramework:ApplyStandardBackdrop (ScreenPanel)
	
	local hook_on_mousedown = function (self, mousebutton, capsule)

	end
	
	local hook_on_mouseup = function (self, mousebutton, capsule)
		if (mousebutton == "LeftButton") then
			SetRaidTargetIcon ("target", capsule.IconIndex)
		elseif (mousebutton == "RightButton") then
			SetRaidTargetIcon ("target", 0)
		end
	end
	
	LeaderToolbar.MarkersButtons = {}
	LeaderToolbar.WorldMarkersButtons = {}
	
	local markers_3d = {
		[[spells\raid_ui_fx_yellow]],
		[[spells\raid_ui_fx_orange]],
		[[spells\raid_ui_fx_purple]],
		[[spells\raid_ui_fx_green]],
		[[spells\raid_ui_fx_silver]],
		[[spells\raid_ui_fx_cyan]],
		[[spells\raid_ui_fx_red]],
		[[spells\raid_ui_fx_white]]
	}
	
	local button_template = {
		backdrop = {edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize = 1, bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tileSize = 64, tile = true},
		backdropcolor = {0, 0, 0, .5},
		backdropbordercolor = {0, 0, 0, 1},
		onentercolor = {1, 1, 1, .5},
		onenterbordercolor = {1, 1, 1, 1},
	}
	
	local icon_idle_color = {.7, .7, .7}
	local icon_active_color = {1, 1, 1}
	
	local button_on_enter = function (self)
		self:SetBackdropBorderColor (unpack (button_template.onenterbordercolor))
		self.MyIcon:SetVertexColor (unpack (icon_active_color))
	end
	
	local button_on_leave = function (self)
		self:SetBackdropBorderColor (unpack (button_template.backdropbordercolor))
		self.MyIcon:SetVertexColor (unpack (icon_idle_color))
	end
	
	local hook_on_enter = function (self, capsule)
		capsule.MyIcon:SetVertexColor (unpack (icon_active_color))
	end
	
	local hook_on_leave = function (self, capsule)
		capsule.MyIcon:SetVertexColor (unpack (icon_idle_color))
	end
	
	local world_markers_colors = {
		[1] = 5,
		[2] = 6,
		[3] = 3,
		[4] = 2,
		[5] = 7,
		[6] = 1,
		[7] = 4,
		[8] = 8,
	}
	
	--> buttons for the 8 markers (icons and world markers)
	for i = 1, 8 do
		local button =  LeaderToolbar:CreateButton (ScreenPanel, function()end, 20, 20, "", i, _, _, "button" .. i, _, _, button_template)
		button:SetHook ("OnMouseDown", hook_on_mousedown)
		button:SetHook ("OnMouseUp", hook_on_mouseup)
		button:SetHook ("OnEnter", hook_on_enter)
		button:SetHook ("OnLeave", hook_on_leave)
		button.IconIndex = i
		button:EnableMouse(true)
		button:SetScript("OnClick", function(self) SetRaidTargetIcon("target", i) end)
		
		local icon = LeaderToolbar:CreateImage (button, "Interface\\TARGETINGFRAME\\UI-RaidTargetingIcon_" .. i , 19, 19, "overlay")
		icon:SetPoint ("center", button, "center")
		icon:SetVertexColor (unpack (icon_idle_color))
		button.MyIcon = icon
		LeaderToolbar.MarkersButtons [i] = button
		
		local raid_marker_button = CreateFrame ("button", "LeaderToolbarRaidGroundIcon" .. i, ScreenPanel, "SecureActionButtonTemplate")
		raid_marker_button:SetAttribute ("type1", "macro")
		raid_marker_button:SetAttribute ("type2", "macro")
		raid_marker_button:SetSize (20, 20)
		raid_marker_button:RegisterForClicks ("AnyDown")
		raid_marker_button:SetAttribute ("macrotext1", "/wm " .. world_markers_colors [i] .. "")
		raid_marker_button:SetAttribute ("macrotext2", "/cwm " .. world_markers_colors [i] .. "")
		raid_marker_button:SetPoint ("top", button.widget, "bottom", 0, -0)

		raid_marker_button:SetScript ("OnEnter", button_on_enter)
		raid_marker_button:SetScript ("OnLeave", button_on_leave)
		
		raid_marker_button:SetBackdrop (button_template.backdrop)
		raid_marker_button:SetBackdropColor (unpack (button_template.backdropcolor))
		raid_marker_button:SetBackdropBorderColor (unpack (button_template.backdropbordercolor))
		
		local icon = LeaderToolbar:CreateImage (button, [[Interface\AddOns\RaidAssist\media\world_markers_icons]] , 18, 18, "overlay") 
		icon:SetTexCoord (((i-1) * 20) / 256, ((i) * 20) / 256, 0, 20/32)
		icon:SetPoint ("center", raid_marker_button, "center", 0, 0)
		icon:SetVertexColor (unpack (icon_idle_color))
		raid_marker_button.MyIcon = icon
		LeaderToolbar.WorldMarkersButtons [i] = raid_marker_button
	end
	
	--> reset buttons
	LeaderToolbar.remove_self_mark = function (self, deltaTime)
		SetRaidTargetIcon ("player", 0)
		local icon = GetRaidTargetIndex ("player")
		if (icon) then
			C_Timer.After (0.1, LeaderToolbar.remove_self_mark)
		end
	end
	local reset_marks = function (self)
		for i = 8, 1, -1 do
			SetRaidTargetIcon ("player", i)
		end
		C_Timer.After (0.5, LeaderToolbar.remove_self_mark)
	end
	local reset_button = LeaderToolbar:CreateButton (ScreenPanel, reset_marks, 14, 20, "X", _, _, _, "reset_markers_button", _, "none", button_template)
	--reset_button:SetPoint ("left", LeaderToolbar.MarkersButtons [#LeaderToolbar.MarkersButtons], "right", 2, 0)
	reset_button:SetPoint ("topleft", ScreenPanel, "topleft", 3 + (8*21), -3)
	
	local reset_button2 = LeaderToolbar:CreateButton (ScreenPanel, ClearRaidMarker, 14, 20, "X", _, _, _, "reset_markers_button2", _, "none", button_template)
	--reset_button2:SetPoint ("left", LeaderToolbar.WorldMarkersButtons [#LeaderToolbar.WorldMarkersButtons], "right", 2, 0)
	reset_button2:SetPoint ("topleft", ScreenPanel, "topleft", 3 + (8*21), -23)
	
	local open_raidstatus = function()
		RA.OpenMainOptions (_G ["RaidAssistPlayerCheck"])
	end

	local status_button = LeaderToolbar:CreateButton (ScreenPanel, open_raidstatus, 50, 20, "Status", _, _, _, "status_button", _, "none", button_template)
	status_button:SetPoint ("left", reset_button, "right", 2, 0)
	local status_frame = CreateFrame ("frame", nil, UIParent)
	status_frame:SetSize (790, 460)
	status_frame:SetFrameStrata ("TOOLTIP")
	status_frame:SetClampedToScreen (true)
	status_frame:SetBackdrop (button_template.backdrop)
	status_frame:SetBackdropColor (unpack (button_template.backdropcolor))
	status_frame:SetBackdropColor (0, 0, 0, 1)
	status_frame:SetBackdropBorderColor (unpack (button_template.backdropbordercolor))
	local fill_panel = LeaderToolbar:CreateFillPanel (status_frame, {}, 790, 460, false, false, false, {rowheight = 16}, "fill_panel", "PlayerCheckScreenFillPanel")
	fill_panel:SetPoint ("topleft", status_frame, "topleft", 0, 0)

	status_button:SetHook ("OnEnter", function()
		local PlayerCheck = _G ["RaidAssistPlayerCheck"]
		if (PlayerCheck) then
			PlayerCheck.update_PlayerCheck (fill_panel)
			status_frame:Show()
			status_frame:SetPoint ("bottom", status_button.widget, "top", 0, 2)
		end
	end)
	status_button:SetHook ("OnLeave", function()
		status_frame:Hide()
	end)	
	
	--> manage groups
	local open_raidgroups = function()
		RA.OpenMainOptions (_G ["RaidAssistRaidGroups"])
	end
	local raidgroups_button = LeaderToolbar:CreateButton (ScreenPanel, open_raidgroups, 50, 20, "Groups", _, _, _, "raidgroups_button", _, "none", button_template)
	raidgroups_button:SetPoint ("left", reset_button2, "right", 2, 0)
	
--	pull_timer = 15,
--	readycheck_timer = 35,	
	
	--> readycheck and pull
	local do_readycheck = function()
		DoReadyCheck()
	end
	local readycheck_button = LeaderToolbar:CreateButton (ScreenPanel, do_readycheck, 50, 20, "Check", _, _, _, "readycheck_button", _, "none", button_template)
	readycheck_button:SetPoint ("left", status_button, "right", 2, 0)
	
	local function dopull()
		if (_G.DBM and SlashCmdList ["DEADLYBOSSMODS"]) then
			SlashCmdList ["DEADLYBOSSMODS"] ("pull " .. tostring (LeaderToolbar.db.pull_timer))
			
		elseif (BigWigs and SlashCmdList.BIGWIGSPULL) then
			SlashCmdList ["BIGWIGSPULL"] (tostring (LeaderToolbar.db.pull_timer))
		end
	end
	
	local pull_button = LeaderToolbar:CreateButton (ScreenPanel, dopull, 50, 20, "Pull", _, _, _, "pull_button", _, "none", button_template)
	pull_button:SetPoint ("left", raidgroups_button, "right", 2, 0)
	
	--> post process
	align_raidmarkers()
	adjust_scale()
	ScreenPanel:Show()

end
	
function LeaderToolbar.BuildOptions (frame)
	
	if (frame.FirstRun) then
		return
	end
	frame.FirstRun = true
	
	if (LeaderToolbar.db.enabled) then
		if (not LeaderToolbar.ScreenPanel) then
			LeaderToolbar.CreateScreenPanel()
		end
	end
	
	local on_select_orientation = function (self, fixed_value, value)
		LeaderToolbar.db.frame_orientation = value
		
	end
	local orientation_options = {
		{value = "H", label = "Horizontal", onclick = on_select_orientation},
		{value = "V", label = "Vertical", onclick = on_select_orientation},
	}	
	
	local options_list = {
		{type = "label", get = function() return "General Options:" end, text_template = LeaderToolbar:GetTemplate ("font", "ORANGE_FONT_TEMPLATE")},
		{
			type = "toggle",
			get = function() return LeaderToolbar.db.enabled end,
			set = function (self, fixedparam, value) 
				LeaderToolbar.db.enabled = value
				if (value) then
					LeaderToolbar.OnEnable()
				else
					LeaderToolbar.OnDisable()
				end
			end,
			name = "Enabled",
		},
		
		{type = "blank"},
		
		
		
--		{
--			type = "select",
--			get = function() return LeaderToolbar.db.frame_orientation end,
--			values = function() return orientation_options end,
--			name = "Frame Orientation",
--		},
		{
			type = "toggle",
			get = function() return LeaderToolbar.db.reverse_order end,
			set = function (self, fixedparam, value) 
				LeaderToolbar.db.reverse_order = value
				align_raidmarkers()
			end,
			name = "Reverse Icons",
		},
		
		{
			type = "toggle",
			get = function() return LeaderToolbar.db.hide_in_combat end,
			set = function (self, fixedparam, value) 
				LeaderToolbar.db.hide_in_combat = value
				LeaderToolbar.CanShow()
			end,
			name = "Hide in Combat",
		},
		{
			type = "toggle",
			get = function() return LeaderToolbar.db.hide_not_in_group end,
			set = function (self, fixedparam, value) 
				LeaderToolbar.db.hide_not_in_group = value
				LeaderToolbar.CanShow()
			end,
			name = "Hide When not in Group",
		},
		
		{
			type = "range",
			get = function() return LeaderToolbar.db.frame_scale end,
			set = function (self, fixedparam, value) 
				LeaderToolbar.db.frame_scale = value
				adjust_scale()
			end,
			min = 0.65,
			max = 1.5,
			step = 0.02,
			name = "Scale",
			usedecimals = true
		},
		{
			type = "range",
			get = function() return LeaderToolbar.db.pull_timer end,
			set = function (self, fixedparam, value) 
				LeaderToolbar.db.pull_timer = value
			end,
			min = 3,
			max = 20,
			step = 1,
			name = "Pull Timer",
			desc = "How much time the pull time should be.",
		},
	}
	
	local options_text_template = LeaderToolbar:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE")
	local options_dropdown_template = LeaderToolbar:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE")
	local options_switch_template = LeaderToolbar:GetTemplate ("switch", "OPTIONS_CHECKBOX_TEMPLATE")
	local options_slider_template = LeaderToolbar:GetTemplate ("slider", "OPTIONS_SLIDER_TEMPLATE")
	local options_button_template = LeaderToolbar:GetTemplate ("button", "OPTIONS_BUTTON_TEMPLATE")
	
	LeaderToolbar:SetAsOptionsPanel (frame)
	LeaderToolbar:BuildMenu (frame, options_list, 0, 0, 300, true, options_text_template, options_dropdown_template, options_switch_template, true, options_slider_template, options_button_template)

end




local install_status = RA:InstallPlugin ("Leader Toolbar", "RALeaderToolbar", LeaderToolbar, default_config)
