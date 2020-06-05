
local RA = RaidAssist
local _
local DF = DetailsFramework

if (_G.RaidAssistLoadDeny) then
	return
end

--/run RaidAssist.OpenMainOptions()

local CONST_OPTIONS_FRAME_WIDTH = 1280
local CONST_OPTIONS_FRAME_HEIGHT = 720

local CONST_MENU_SCROLL_WIDTH = 170
local CONST_MENU_SCROLL_HEIGHT = 616
local CONST_MENU_BUTTON_WIDTH = 166
local CONST_MENU_BUTTON_HEIGHT = 24

local CONST_MENU_MAX_BUTTONS = 25
local CONST_MENU_STARTPOS_X = 5
local CONST_MENU_STARTPOS_Y = -30

local CONST_OPTIONSPANEL_STARTPOS_X = 208
local CONST_OPTIONSPANEL_STARTPOS_Y = -36

local CONST_MENU_FONT_SIZE = 12

local CACHE_ALL_PLUGINS_INSTALLED = {}

function RA.OpenMainOptions (plugin)

	--if a plugin object has been passed, open the options panel for it
	if (RaidAssistOptionsPanel) then
		if (plugin) then
			RA.OpenMainOptionsForPlugin (plugin)
		end
		RaidAssistOptionsPanel:Show()
		return
	end

	RA.db.options_panel = RA.db.options_panel or {}

	local f = RA:CreateStandardFrame (UIParent, CONST_OPTIONS_FRAME_WIDTH, CONST_OPTIONS_FRAME_HEIGHT, "Raid Assist (|cFFFFAA00/raa|r)", "RaidAssistOptionsPanel", RA.db.options_panel)
	f:SetBackdropBorderColor (1, .7, 0, .8)
	f:SetBackdropColor (0, 0, 0, 1)
	DetailsFramework:ApplyStandardBackdrop (f, 0.9)

	f.AllOptionsButtons = {}
	f.AllOptionsPanels = {}
	
	--create the footer and attach it into the bottom of the main frame
		local statusBar = CreateFrame ("frame", nil, f)
		statusBar:SetPoint ("bottomleft", f, "bottomleft")
		statusBar:SetPoint ("bottomright", f, "bottomright")
		statusBar:SetHeight (20)
		DetailsFramework:ApplyStandardBackdrop (statusBar)
		statusBar:SetAlpha (0.8)
		DetailsFramework:BuildStatusbarAuthorInfo (statusBar)
	

	--keybind to open the panel
		RA.CreateHotkeyFrame(f)
	

	--create the left menu
		--when the player select a plugin in the plugin scroll
		local onSelectPlugin =  function (button, mouse, plugin)
			--reset
			f:ResetButtonsAndPanels()
			
			--make the button change its text color
			plugin.textcolor = "orange"
			
			--show the panel for the plugin
			if (plugin.OnShowOnOptionsPanel) then
				plugin.OnShowOnOptionsPanel()
				plugin.OptionsPanel:Show()
			end
		end
	
		--change the selected plugin from inside plugins
		RA.OpenMainOptionsForPlugin = function (plugin)
			return onSelectPlugin (nil, nil, plugin)
		end


	--hide all panels for all addons
		function f:ResetButtonsAndPanels()
			for _, panel in pairs (f.AllOptionsPanels) do
				panel:Hide()
			end		
			for _, button in pairs (f.AllOptionsButtons) do
				button.textcolor = "white"
			end
		end
	

	--load the plugins
		local plugins_list = RA:GetSortedPluginsInPriorityOrder()
		local plugins_sorted_list = {}
		local bossmods_sorted_list = {}
	
		--build a table to hold plugins
		for _, plugin in pairs (plugins_list) do
			if (not plugin.IsBossMod) then
				plugin.db.menu_priority = plugin.db.menu_priority or 1
				tinsert (plugins_sorted_list, plugin)

			elseif (plugin.IsBossMod) then
				plugin.db.menu_priority = plugin.db.menu_priority or 1
				tinsert (bossmods_sorted_list, plugin)
			end
		end
	
		table.sort (plugins_sorted_list, function (plugin1, plugin2) return ( (plugin1 and plugin1.db.menu_priority) or 1) > ( (plugin2 and plugin2.db.menu_priority) or 1) end)
		table.sort (bossmods_sorted_list, function (plugin1, plugin2) return ( (plugin1 and plugin1.db.menu_priority) or 1) > ( (plugin2 and plugin2.db.menu_priority) or 1) end)
	

	--create the menu scroll box
		--this function refreshes the scroll options
		local refreshLeftMenuScrollBox = function(self, data, offset, totalLines)

			--update the scroll
			for i = 1, totalLines do
				local index = i + offset
				local pluginObject = data [index]
				if (pluginObject) then
					--get the data
					local iconTexture, iconTexcoord, text, textColor = pluginObject.menu_text (pluginObject)

					--update the line
					local button = self:GetLine(i)
					button:SetText (text)

					button:SetClickFunction(onSelectPlugin, pluginObject)

					if (iconTexcoord) then
						button:SetIcon(iconTexture, 18, 18, "overlay", {iconTexcoord.l, iconTexcoord.r, iconTexcoord.t, iconTexcoord.b}, nil, 2, 2)
					else
						button:SetIcon(iconTexture, 18, 18, "overlay", {0, 1, 0, 1}, nil, 2, 2)
					end

					if (pluginObject.IsDisabled) then
						button:Disable()
					else
						button:Enable()
					end

					button:Show()
				end
			end
		end

		--create the left menu scroll
		local createMenuScrollBoxLine = function (parent, index)
			local newButton = RA:CreateButton (parent, onSelectPlugin, CONST_MENU_BUTTON_WIDTH, CONST_MENU_BUTTON_HEIGHT, "", 0, nil, nil, nil, nil, 1, button_template, button_text_template)
			--newButton:SetTextSize(CONST_MENU_FONT_SIZE)
			newButton.textsize = CONST_MENU_FONT_SIZE
			newButton:SetPoint("topleft", parent, "topleft", 2, -1 + ((index - 1) * -CONST_MENU_BUTTON_HEIGHT))
			return newButton
		end

		--add all plugins registered into the all plugins list
		--this list will be used to update the left menu
		local allPlugin = {}
		for _, plugin in pairs (plugins_sorted_list) do
			allPlugin [ #allPlugin + 1 ] = plugin
		end
		
		for _, plugin in pairs (bossmods_sorted_list) do
			allPlugin [ #allPlugin + 1 ] = plugin
		end

	--create the options frame for each plugin
		for i = 1, #allPlugin do
			local plugin = allPlugin[i]

			local optionsFrame = CreateFrame ("frame", "RaidAssistOptionsPanel" .. (plugin.pluginname or math.random (1, 1000000)), f)
			optionsFrame:Hide()
			optionsFrame:SetSize (1, 1)
			optionsFrame:SetPoint ("topleft", f, "topleft", CONST_OPTIONSPANEL_STARTPOS_X, CONST_OPTIONSPANEL_STARTPOS_Y)
			
			plugin.OptionsPanel = optionsFrame
			f.AllOptionsPanels [ #f.AllOptionsPanels + 1 ] = optionsFrame

			CACHE_ALL_PLUGINS_INSTALLED [plugin] = optionsFrame
		end

		local menuScrollBox = DF:CreateScrollBox (f, "$parentScrollBox", refreshLeftMenuScrollBox, allPlugin, CONST_MENU_SCROLL_WIDTH, CONST_MENU_SCROLL_HEIGHT, CONST_MENU_MAX_BUTTONS, CONST_MENU_BUTTON_HEIGHT)
		DF:ReskinSlider (menuScrollBox)
		menuScrollBox:SetPoint("topleft", f, "topleft", CONST_MENU_STARTPOS_X, CONST_MENU_STARTPOS_Y)

		--create the scrollbox lines
		for i = 1, CONST_MENU_MAX_BUTTONS do
			menuScrollBox:CreateLine (createMenuScrollBoxLine)
		end

		menuScrollBox:Refresh()

	--reset everything to start
		f:ResetButtonsAndPanels()
	
		--if a plugin requested to open its options
		if (plugin) then
			onSelectPlugin (nil, nil, plugin)
		end
end


function RA.CreateHotkeyFrame(f)

	local currentKeyBind = RA.DATABASE.OptionsKeybind

	local keyBindListener = CreateFrame ("frame", "RaidAssistBindListenerFrame", f)
	keyBindListener.IsListening = false
	
	local enter_the_key = CreateFrame ("frame", nil, keyBindListener)
	enter_the_key:SetFrameStrata ("tooltip")
	enter_the_key:SetSize (200, 60)
	enter_the_key:SetBackdrop ({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 16, edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize = 1})
	enter_the_key:SetBackdropColor (0, 0, 0, 1)
	enter_the_key:SetBackdropBorderColor (1, 1, 1, 1)
	enter_the_key.text = RA:CreateLabel (enter_the_key, "- Press a keyboard key to bind.\n- Press escape to clear.\n- Click again to cancel.", 11, "orange")
	enter_the_key.text:SetPoint ("center", enter_the_key, "center")
	enter_the_key:Hide()

	local ignoredKeys = {
		["LSHIFT"] = true,
		["RSHIFT"] = true,
		["LCTRL"] = true,
		["RCTRL"] = true,
		["LALT"] = true,
		["RALT"] = true,
		["UNKNOWN"] = true,
	}

	local mouseKeys = {
		["LeftButton"] = "type1",
		["RightButton"] = "type2",
		["MiddleButton"] = "type3",
		["Button4"] = "type4",
		["Button5"] = "type5",
	}

	local keysToMouse = {
		["type1"] = "LeftButton",
		["type2"] = "RightButton",
		["type3"] = "MiddleButton",
		["type4"] = "Button4",
		["type5"] = "Button5",
	}


	local registerKeybind = function (self, key) 
		if (ignoredKeys [key]) then
			return

		elseif (key == "ESCAPE" ) then
			enter_the_key:Hide()
			keyBindListener.IsListening = false
			keyBindListener:SetScript ("OnKeyDown", nil)

			if (RA.DATABASE.OptionsKeybind and RA.DATABASE.OptionsKeybind ~= "") then
				SetBinding (RA.DATABASE.OptionsKeybind)
				RA:Msg ("do a /reload if this bind was a override.")
			end

			RA.DATABASE.OptionsKeybind = ""
			f.SetKeybindButton.text = ""
			f.SetKeybindButton.text = "- click to set -"
			RA:RefreshMacros()
			return

		elseif (mouseKeys [key] or keysToMouse [key]) then
			enter_the_key:Hide()
			keyBindListener.IsListening = false
			keyBindListener:SetScript ("OnKeyDown", nil)
			return
		end
		
		local bind = (IsShiftKeyDown() and "SHIFT-" or "") .. (IsControlKeyDown() and "CTRL-" or "") .. (IsAltKeyDown() and "ALT-" or "")
		bind = bind .. key
	
		RA.DATABASE.OptionsKeybind = bind
		f.SetKeybindButton.text = bind
		
		RA:RefreshMacros()
	
		keyBindListener.IsListening = false
		keyBindListener:SetScript ("OnKeyDown", nil)
		enter_the_key:Hide()
	end
	

	local set_key_bind = function (self, button, keybindIndex)
		if (keyBindListener.IsListening) then
			local key = mouseKeys [button] or button
			return registerKeybind (keyBindListener, key)
		end

		keyBindListener.IsListening = true
		keyBindListener.keybindIndex = keybindIndex
		keyBindListener:SetScript ("OnKeyDown", registerKeybind)
		GameCooltip:Hide()
		
		enter_the_key:Show()
		enter_the_key:SetPoint ("bottom", self, "top")
	end
	
	local setKeybindButton = RA:CreateButton (f, set_key_bind, CONST_MENU_BUTTON_WIDTH, CONST_MENU_BUTTON_HEIGHT, "", _, _, _, "SetKeybindButton", _, 0, RA:GetTemplate ("button", "OPTIONS_BUTTON_TEMPLATE"), RA:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
	setKeybindButton:SetPoint ("bottomleft", f, "bottomleft", 10, 30)
	setKeybindButton:SetClickFunction (set_key_bind, nil, nil, "left")
	setKeybindButton:SetClickFunction (set_key_bind, nil, nil, "right")
	setKeybindButton.text = currentKeyBind and currentKeyBind ~= "" and currentKeyBind or "- click to set -"
	setKeybindButton.tooltip = "Set up a keybind to open this option panel."
	
	local keybind_text = RA:CreateLabel (f, "Options Panel Keybind:")
	keybind_text:SetPoint ("bottom", setKeybindButton, "top", 0, 2)
end
