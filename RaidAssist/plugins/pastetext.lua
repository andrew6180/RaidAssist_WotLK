local RA = RaidAssist
local L = LibStub ("AceLocale-3.0"):GetLocale ("RaidAssistAddon")
local _
local default_priority = 20

if (_G ["RaidAssistPasteText"]) then
	return
end

if true then -- paste text is kinda useless imo
	return 
end

local PasteText = {version = "v0.1", pluginname = "PasteText"}
_G ["RaidAssistPasteText"] = PasteText

PasteText.LastSelected_Options = 1
PasteText.LastSelected_Screen = 1

local default_config = {
	enabled = true,
	texts = {},
}

local icon_texcoord = {l=64/512, r=96/512, t=0, b=1}
local text_color_enabled = {r=1, g=1, b=1, a=1}
local text_color_disabled = {r=0.5, g=0.5, b=0.5, a=1}
local icon_texture = "Interface\\AddOns\\" .. RA.InstallDir .. "\\media\\plugin_icons"

local can_install = false
local COMM_RECEIVED_TEXT = "PTRE"

PasteText.menu_text = function (plugin)
	if (PasteText.db.enabled) then
		return icon_texture, icon_texcoord, "Paste Text", text_color_enabled
	else
		return icon_texture, icon_texcoord, "Paste Text", text_color_disabled
	end
end

PasteText.menu_popup_show = function (plugin, ct_frame, param1, param2)
	RA:AnchorMyPopupFrame (PasteText)
end

PasteText.menu_popup_hide = function (plugin, ct_frame, param1, param2)
	PasteText.popup_frame:Hide()
end

PasteText.menu_on_click = function (plugin)
	--if (not PasteText.options_built) then
	--	PasteText.BuildOptions()
	--	PasteText.options_built = true
	--end
	--PasteText.main_frame:Show()
	
	RA.OpenMainOptions (PasteText)
end

function PasteText.PluginCommReceived (prefix, sourcePluginVersion, sourceUnit, data)
	if (not PasteText.db.enabled) then
		return
	end
	
	if (UnitInRaid (sourceUnit) or UnitInParty (sourceUnit)) then
		--check if is valid text and title
		if (not data.title or not data.text) then
			return
		end
		data.source = sourceUnit
		
		--check if already exists and update the text if so
		--alse add it
		
		PasteText.AddText (data.title, data.text, data.source, true)
		
		--check se n�o � 'eu mesmo'
		--mostrar na tela se n�o � a mesma pessoa que enviou
		
	end
end

PasteText.OnInstall = function (plugin)
	PasteText.db.menu_priority = default_priority
	PasteText.CreateScreenFrame()
	PasteText:RegisterPluginComm (COMM_RECEIVED_TEXT, PasteText.PluginCommReceived)
end

PasteText.OnEnable = function (plugin)
	-- enabled from the options panel.
	
end

PasteText.OnDisable = function (plugin)
	-- disabled from the options panel.
	
end

PasteText.OnProfileChanged = function (plugin)
	if (plugin.db.enabled) then
		PasteText.OnEnable (plugin)
	else
		PasteText.OnDisable (plugin)
	end
	
	if (plugin.options_built) then
		--plugin.main_frame:RefreshOptions()
	end
end

function PasteText.HideScreenPanel()
	PasteText.ScreenPanel:Hide()
end

function PasteText.SelectAllScreenPanelText()
	PasteText.ScreenPanel.TextBox.editbox:SetFocus (true)
	PasteText.ScreenPanel.TextBox.editbox:HighlightText()
end

function PasteText.ShowOnScreen (data)
	if (not data) then
		PasteText.ScreenPanel:Hide()
	end
	PasteText.ScreenPanel.Title.text = "[|cFFFFFF22Raid Assist|r] Text From: |cFFFF9922" .. (data.source or "") .. "|r | Title: |cFFFF9922" .. data.title
	PasteText.ScreenPanel.TextBox:SetText (data.text)
	PasteText.ScreenPanel:Show()
end

function PasteText.CreateScreenFrame()
	PasteText.ScreenPanel = RA:CreateCleanFrame (PasteText, "PasteTextScreenFrame")
	PasteText.ScreenPanel:SetSize (600, 200)

	local animation = RA:CreateAnimationHub (PasteText.ScreenPanel)
	RA:CreateAnimation (animation, "scale", 1, .11, .2, .2, 1.1, 1.1, "center")
	RA:CreateAnimation (animation, "scale", 2, .08, 1.1, 1.1, 1, 1)
	
	PasteText.ScreenPanel:SetScript ("OnShow", function()
		--animation:Play()
	end)
	
	--text title
	PasteText.ScreenPanel.Title =  PasteText:CreateLabel (PasteText.ScreenPanel, "")
	PasteText.ScreenPanel.Title:SetPoint ("topleft", PasteText.ScreenPanel, "topleft", 2, -2)

	--close button
	PasteText.ScreenPanel.Close =  PasteText:CreateButton (PasteText.ScreenPanel, PasteText.HideScreenPanel, 50, 20, "close")
	PasteText.ScreenPanel.Close:SetPoint ("topright", PasteText.ScreenPanel, "topright", -2, -2)
	
	--select all
	PasteText.ScreenPanel.SelectAll =  PasteText:CreateButton (PasteText.ScreenPanel, PasteText.SelectAllScreenPanelText, 50, 20, "select all")
	PasteText.ScreenPanel.SelectAll:SetPoint ("right", PasteText.ScreenPanel.Close, "left", -2, 0)

	--editbox
	PasteText.ScreenPanel.TextBox = PasteText:NewSpecialLuaEditorEntry (PasteText.ScreenPanel, 600, 180, "pasteEditbox", "PasteTextScreenFrameEditBox", true)
	PasteText.ScreenPanel.TextBox:SetPoint ("topleft", PasteText.ScreenPanel, "topleft", 0, -20)
	PasteText.ScreenPanel.TextBox:SetBackdrop (nil)
end


--left menu scrollframe
-- pequeno 200 pixels +-
-- tem uma scrollframe pra mostrar quais os textos salvos
-- o menu tem um text e uma X para apagar
-- todo texto recebido � salvo automaticamente

-- text
-- grande 800 pixels +-
-- tem aquenas uma box para mostrar o texto
-- ter um +- para mudar o tamanho da fonte do texto

function PasteText.OnShowOnOptionsPanel()
	local OptionsPanel = PasteText.OptionsPanel
	PasteText.BuildOptions (OptionsPanel)
end
function PasteText.BuildOptions (frame)
	
	if (not frame.FirstRun) then
		frame.FirstRun = true
		
		local options_text_template = PasteText:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE")
		
		local options_list = {
			{type = "label", get = function() return "General Options:" end, text_template = PasteText:GetTemplate ("font", "ORANGE_FONT_TEMPLATE")},
			{
				type = "toggle",
				get = function() return PasteText.db.enabled end,
				set = function (self, fixedparam, value) 
					PasteText.db.enabled = value
				end,
				desc = L["S_PLUGIN_ENABLED_DESC"],
				name = L["S_PLUGIN_ENABLED"],
				text_template = options_text_template,
			},
		}
		
		local options_text_template = PasteText:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE")
		local options_dropdown_template = PasteText:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE")
		local options_switch_template = PasteText:GetTemplate ("switch", "OPTIONS_CHECKBOX_TEMPLATE")
		local options_slider_template = PasteText:GetTemplate ("slider", "OPTIONS_SLIDER_TEMPLATE")
		local options_button_template = PasteText:GetTemplate ("button", "OPTIONS_BUTTON_TEMPLATE")
		
		RA:BuildMenu (frame, options_list, 0, 0, 500, true, options_text_template, options_dropdown_template, options_switch_template, true, options_slider_template, options_button_template)
		
		--monta o menu de scroll
		local scroll_width = 200
		local scroll_line_amount = 24
		local scroll_line_height = 20
		
		local scroll_refresh = function (self, data, offset, total_lines)
			for i = 1, total_lines do
				local index = i + offset
				local text = data [index]
				if (text) then
					local line = self:GetLine (i)
					line:SetAlpha (1)
					line.name:SetText (text.title)
					line.icon:SetTexture (nil)
					line.Index = index
					line.DeleteButton.Index = index
					
					if (index == PasteText.LastSelected_Options) then
						RA:SetFontColor (line.name, "orange")
					else
						RA:SetFontColor (line.name, "white")
					end
				end
			end
		end
		
		local line_delete_OnClick = function (self)
			PasteText.RemoveText (self.Index)
		end
		
		local editNote = function (noteID, setFocus)
			PasteText.LastSelected_Options = noteID
			PasteText.OptionsPasteMenuScroll:Refresh()
			PasteText:RefreshText()
			
			if (setFocus) then
				frame.PasteMenuEditBox:SetFocus (true)
			else
				frame.PasteMenuEditBox:ClearFocus()
				local selectedText = PasteText.db.texts [noteID]
				if (selectedText) then
					local text = selectedText.text
					if (string.len (text) == 0) then
						PasteText.EmptyText2:Show()
					else
						PasteText.EmptyText2:Hide()
					end
				end
			end
		end
		
		local line_onclick = function (self)
			PasteText:SaveText()
			editNote (self.Index)
		end
		
		local scroll_createline = function (self, index)
			local line = CreateFrame ("button", "$parentLine" .. index, self)
			line:SetPoint ("topleft", self, "topleft", 0, -((index-1)*(scroll_line_height+1)))
			line:SetSize (scroll_width, scroll_line_height)
			line:SetScript ("OnEnter", line_onenter)
			line:SetScript ("OnLeave", line_onleave)
			line:SetScript ("OnClick", line_onclick)
			
			line:SetBackdrop ({bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tileSize = 64, tile = true})
			line:SetBackdropColor (0, 0, 0, 0.2)
			
			local icon = line:CreateTexture ("$parentIcon", "overlay")
			icon:SetSize (scroll_line_height, scroll_line_height)
			local name = line:CreateFontString ("$parentName", "overlay", "GameFontNormal")
			RA:SetFontSize (name, 9)
			icon:SetPoint ("left", line, "left", 2, 0)
			name:SetPoint ("left", icon, "right", 2, 0)
			line.icon = icon
			line.name = name
			name:SetHeight (10)
			name:SetJustifyH ("left")
			
			local deleteButton = CreateFrame ("button", nil, line)
			deleteButton:SetPoint ("right", line, "right", -2, 0)
			deleteButton:SetSize (18, 18)
			deleteButton:SetScript ("OnClick", line_delete_OnClick)
			deleteButton:SetNormalTexture ([[Interface\GLUES\LOGIN\Glues-CheckBox-Check]])
			
			line.DeleteButton = deleteButton
			return line
		end
		
		local pasteMenu = RA:CreateScrollBox (frame, "$parentMenuScroll", scroll_refresh, PasteText.db.texts, scroll_width, 470, scroll_line_amount, scroll_line_height)
		pasteMenu:SetPoint ("topleft", frame, "topleft", 10, -60)
		for i = 1, scroll_line_amount do 
			pasteMenu:CreateLine (scroll_createline)
		end
		frame.PasteMenuScroll = pasteMenu
		PasteText.OptionsPasteMenuScroll = pasteMenu
		--pasteMenu:SetBackdrop ({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 16})
		--pasteMenu:SetBackdropColor (0, 0, 0, 0)
		
		DetailsFramework:ReskinSlider (pasteMenu)
		
		--monta a editbox
		local pasteEditbox = PasteText:NewSpecialLuaEditorEntry (frame, 778, 494, "pasteEditbox", "PasteTextEditBox", true)
		pasteEditbox:SetPoint ("topleft", pasteMenu, "topright", 17, 10)
		pasteEditbox:SetBackdrop (nil)
		frame.PasteMenuEditBox = pasteEditbox
		PasteText.OptionsPasteEditbox = pasteEditbox
		
		DetailsFramework:ReskinSlider (pasteEditbox.scroll)
		
		pasteEditbox:SetScript ("OnMouseDown", function()
			pasteEditbox:SetFocus (true)
		end)
		
		function PasteText:RefreshText()
			local selectedText = PasteText.db.texts [PasteText.LastSelected_Options]
			if (selectedText) then
				local text = selectedText.text
				pasteEditbox:SetText (text)
				
				if (string.len(text) < 1) then
					PasteText.EmptyText:Show()
				else
					PasteText.EmptyText:Hide()
				end
			else
				pasteEditbox:SetText ("")
				PasteText.EmptyText:Show()
			end
		end
		
		function PasteText:SaveText()
			if (PasteText.db.texts [PasteText.LastSelected_Options]) then
				PasteText.db.texts [PasteText.LastSelected_Options].text = pasteEditbox:GetText()
			end
		end
		
		pasteEditbox.editbox:SetScript ("OnEditFocusGained", function()
			PasteText.EmptyText2:Hide()
		
			if (#PasteText.db.texts == 0) then
				pasteEditbox:ClearFocus()
				return
			end
			PasteText.EmptyText:Hide()
		end)
		
		pasteEditbox.editbox:SetScript ("OnEditFocusLost", function()
			PasteText:SaveText()
			PasteText:RefreshText()
			
			local selectedText = PasteText.db.texts [PasteText.LastSelected_Options]
			if (selectedText) then
				local text = selectedText.text
				if (string.len (text) == 0) then
					PasteText.EmptyText2:Show()
				else
					PasteText.EmptyText2:Hide()
				end
			end
			
		end)
		
		--create new button
		local create_new = function (name)
			if (name ~= "") then
				PasteText.AddText (name, "")
				PasteText.LastSelected_Options = 1
				frame.PasteMenuScroll:Refresh()
				PasteText:RefreshText()
				editNote (1, true) --it insert in the first index
			end
		end
		
		local AskForAName = function()
			PasteText:ShowTextPromptPanel ("Enter the name for the new Paste", create_new)
		end
		
		local CreateButton = PasteText:CreateButton (frame, AskForAName, 120, 20, "Create New Text", _, _, _, "button_createnew", _, _, PasteText:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"), PasteText:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
		CreateButton:SetPoint (250, -20)
		
		local SendSelectedText = function()
			PasteText:SaveText()
			pasteEditbox:ClearFocus()
			local selectedText = PasteText.LastSelected_Options
			local data = PasteText.db.texts [selectedText]
			
			--chamar a fun��o para enviar o texto
			PasteText.ShareText (data)
		end
		
		local SendButton = PasteText:CreateButton (frame, SendSelectedText, 100, 20, "Sent Text", _, _, _, "button_sendtext", _, _, PasteText:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"), PasteText:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
		SendButton:SetPoint (370, -20)
		
		local flashTexture = frame:CreateTexture (nil, "background")
		flashTexture:SetTexture (1, 1, 1)
		flashTexture:SetAllPoints (pasteEditbox.editbox)
		flashTexture:Hide()
		
		local flashAnimation = RA:CreateAnimationHub (flashTexture, function() flashTexture:Show() end, function() flashTexture:Hide() end)
		RA:CreateAnimation (flashAnimation, "alpha", 1, .05, 0, .1)
		RA:CreateAnimation (flashAnimation, "alpha", 2, .05, .1, 0)
		
		local emptyText2 = RA:CreateLabel (frame, "This notepad is empty\nClick anywhere here to start editing it.", 14, {.98, .8, .8, .75})
		emptyText2:SetJustifyH ("center")
		emptyText2:SetPoint ("center", pasteEditbox, "center", 0, 100)
		emptyText2:Hide()
		PasteText.EmptyText2 = emptyText2
		
		local emptyText = RA:CreateLabel (frame, "Click on 'Create New Text'\nThen click here to Add the Text\nSend it to Your Raid, They Can Copy/Paste it\n\nyou can send any text you want: a team speak server, youtube video\na strategy, link to a topic on mmo-champion forum.", 14, {.8, .8, .8, .75})
		emptyText:SetJustifyH ("center")
		emptyText:SetPoint ("center", pasteEditbox, "center")
		emptyText:Hide()
		PasteText.EmptyText = emptyText
		
		function PasteText.FocusText()
			pasteEditbox:SetFocus (true)
			flashAnimation:Play()
		end
		
		pasteMenu:Refresh()
		if (PasteText.db.texts [PasteText.LastSelected_Options]) then
			PasteText:RefreshText()
			--C_Timer.After (1, PasteText.FocusText)
		end
		
		frame:SetScript ("OnShow", function()
			PasteText.OptionsPasteMenuScroll:Refresh()
			PasteText:RefreshText()
		end)
	end
end

function PasteText.RemoveText (index)
	tremove (PasteText.db.texts, index)
	
	if (index >= PasteText.LastSelected_Options) then
		PasteText.LastSelected_Options = math.max (1, PasteText.LastSelected_Options - 1)
	end
	if (index >= PasteText.LastSelected_Screen) then
		PasteText.LastSelected_Screen = math.max (1, PasteText.LastSelected_Screen - 1)
	end

	--se o painel de op��o estiver aberto, dar refresh nele
	if (PasteText.OptionsPasteMenuScroll and PasteText.OptionsPasteMenuScroll:IsShown()) then
		PasteText.OptionsPasteMenuScroll:Refresh()
		PasteText:RefreshText()
	end
	
	--se o screen panel estiver aberto, dar refresh nele
	
end

function PasteText.AddText (title, text, source, showOnScreen)
	local newText
	for i = 1, #PasteText.db.texts do
		if (PasteText.db.texts [i].title == title) then
			newText = PasteText.db.texts [i]
			break
		end
	end
	
	if (not newText) then
		newText = {title = title, text = text}
		tinsert (PasteText.db.texts, 1, newText)
		tremove (PasteText.db.texts, 100)
	else
		newText.text = text
	end
	
	newText.source = source
	
	--verifica se o painel de op��es esta aberto e da refresh
	if (PasteText.OptionsPasteMenuScroll and PasteText.OptionsPasteMenuScroll:IsShown()) then
		PasteText.OptionsPasteMenuScroll:Refresh()
		PasteText:RefreshText()
	end
	
	if (showOnScreen) then
		PasteText.ShowOnScreen (newText)
	end
end

function PasteText.ShareText (data)

	--PasteText.ShowOnScreen ({title = "texto paste", text = "meu texto digitado", source = "Trcioo"})

	--verifica se � officer ou raid leader
	if (IsInRaid()) then
		if (not PasteText:UnitHasAssist ("player")) then
			return PasteText:Msg ("you aren't leader or assistant.")
		end
	elseif (IsInGroup()) then
		if (not UnitIsGroupLeader ("player")) then
			return PasteText:Msg ("you aren't leader or assistant.")
		end
	end

	--envia o texto para a raide
	if (IsInRaid()) then
		PasteText:SendPluginCommMessage (COMM_RECEIVED_TEXT, "RAID", nil, nil, PasteText:GetPlayerNameWithRealm(), data)
	elseif (IsInGroup()) then
		PasteText:SendPluginCommMessage (COMM_RECEIVED_TEXT, "PARTY", nil, nil, PasteText:GetPlayerNameWithRealm(), data)
	end
end

local install_status = RA:InstallPlugin ("Paste Text", "RAPasteText", PasteText, default_config)
