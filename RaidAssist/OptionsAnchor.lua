
local RA = RaidAssist
local _

if (_G.RaidAssistLoadDeny) then
	return
end

function RA:OpenAnchorOptionsPanel()
	if (not RaidAssistAnchorOptionsPanel) then
		local f = RA:CreateOptionsFrame ("RaidAssistAnchorOptionsPanel", "Raid Assist Anchor Options", 1)
		local L = LibStub ("AceLocale-3.0"):GetLocale ("RaidAssistAddon")
		f:SetHeight (200)
		
		local texture_icon = [[Interface\TARGETINGFRAME\UI-PhasingIcon]]
		local texture_icon_size = {14, 14}
		local texture_texcoord = {0, 1, 0, 1}
		
		local anchor_size_func = function (_, _, value)
			RA.db.profile.addon.anchor_side = value
			RA:RefreshMainAnchor()
		end
		local anchor_side = {
			{value = "left", label = L["S_ANCHOR_LEFT"], icon = texture_icon, iconsize = texture_icon_size, texcoord = texture_texcoord, onclick = anchor_size_func},
			{value = "right", label = L["S_ANCHOR_RIGHT"], icon = texture_icon, iconsize = texture_icon_size, texcoord = texture_texcoord, onclick = anchor_size_func},
			{value = "top", label = L["S_ANCHOR_TOP"], icon = texture_icon, iconsize = texture_icon_size, texcoord = texture_texcoord, onclick = anchor_size_func},
			{value = "bottom", label = L["S_ANCHOR_BOTTOM"], icon = texture_icon, iconsize = texture_icon_size, texcoord = texture_texcoord, onclick = anchor_size_func},
		}
		
		local options_list = {
			{
				type = "select",
				get = function() return RA.db.profile.addon.anchor_side end,
				values = function() return anchor_side end,
				desc = L["S_ANCHOR_SIDE_DESC"],
				name = L["S_ANCHOR_SIDE"]
			},
			{
				type = "range",
				get = function() return RA.db.profile.addon.anchor_size end,
				set = function (_, _, value) RA.db.profile.addon.anchor_size = value; RA:RefreshMainAnchor() end,
				min = 20,
				max = 1024,
				step = 1,
				desc = L["S_ANCHOR_SIZE_DESC"],
				name = L["S_ANCHOR_SIZE"],
			},
			{
				type = "color",
				get = function() return {RA.db.profile.addon.anchor_color.r, RA.db.profile.addon.anchor_color.g, RA.db.profile.addon.anchor_color.b, RA.db.profile.addon.anchor_color.a} end,
				set = function (self, r, g, b, a) 
					local color = RA.db.profile.addon.anchor_color
					color.r, color.g, color.b, color.a = r, g, b, a
					RA:RefreshMainAnchor()
				end,
				desc = L["S_ANCHOR_COLOR_DESC"],
				name = L["S_ANCHOR_COLOR"],
			},
			{
				type = "range",
				get = function() return RA.db.profile.addon.anchor_y end,
				set = function (_, _, value) RA.db.profile.addon.anchor_y = value; RA:RefreshMainAnchor() end,
				min = -1024,
				max = 1024,
				step = 1,
				desc = L["S_ANCHOR_Y_DESC"],
				name = L["S_ANCHOR_Y"],
			},
			{
				type = "range",
				get = function() return RA.db.profile.addon.anchor_x end,
				set = function (_, _, value) RA.db.profile.addon.anchor_x = value; RA:RefreshMainAnchor() end,
				min = -1024,
				max = 1024,
				step = 1,
				desc = L["S_ANCHOR_X_DESC"],
				name = L["S_ANCHOR_X"],
			},
			{
				type = "toggle",
				get = function() return RA.db.profile.addon.show_only_in_raid end,
				set = function (self, fixedparam, value) 
					RA.db.profile.addon.show_only_in_raid = value
					RA:RefreshMainAnchor()
				end,
				desc = L["S_ANCHOR_ONLY_IN_RAID_DESC"],
				name = L["S_ANCHOR_ONLY_IN_RAID"],
			},
		}
		
		local options_text_template = RA:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE")
		local options_dropdown_template = RA:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE")
		local options_switch_template = RA:GetTemplate ("switch", "OPTIONS_CHECKBOX_TEMPLATE")
		local options_slider_template = RA:GetTemplate ("slider", "OPTIONS_SLIDER_TEMPLATE")
		local options_button_template = RA:GetTemplate ("button", "OPTIONS_BUTTON_TEMPLATE")
		
		RA:BuildMenu (f, options_list, 15, -60, 200, true, options_text_template, options_dropdown_template, options_switch_template, true, options_slider_template, options_button_template)
		f:SetBackdropColor (0, 0, 0, .9)
	end
	RaidAssistAnchorOptionsPanel:Show()
end
