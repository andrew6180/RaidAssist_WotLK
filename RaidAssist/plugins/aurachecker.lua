
local RA = RaidAssist
local L = LibStub ("AceLocale-3.0"):GetLocale ("RaidAssistAddon")
local _ 
local default_priority = 26

local default_config = {
	enabled = true,
	menu_priority = 1,
	only_from_guild = false,
	auto_install_from_trusted = false,
	installed_history = {},
}

local text_color_enabled = {r=1, g=1, b=1, a=1}
local text_color_disabled = {r=0.5, g=0.5, b=0.5, a=1}

local toolbar_icon = [[Interface\CHATFRAME\UI-ChatIcon-Share]]
local icon_texcoord = {l=0, r=1, t=0, b=1}

if (_G ["RaidAssistAuraCheck"]) then
	return
end
local AuraCheck = {version = "v0.1", pluginname = "Aura Check"}
_G ["RaidAssistAuraCheck"] = AuraCheck

local COMM_AURA_CHECKREQUEST = "WAC" --check aura - the raid leader requested an aura check
local COMM_AURA_CHECKRECEIVED = "WAR" --a user sent an aura check response
local COMM_AURA_INSTALLREQUEST = "WAI" --install - the raid leader requested the user to install an aura

local RESPONSE_TYPE_NOSAMEGUILD = 4
local RESPONSE_TYPE_DECLINED_ALREADYHAVE = 3
local RESPONSE_TYPE_DECLINED = 2
local RESPONSE_TYPE_HAVE = 1
local RESPONSE_TYPE_NOT_HAVE = 0
local RESPONSE_TYPE_NOWA = -1
local RESPONSE_TYPE_WAITING = -2
local RESPONSE_TYPE_OFFLINE = -3

local CONST_RESULTAURALIST_ROWS = 20
local CONST_AURALIST_ROWS = 24

local valid_results = {
	[RESPONSE_TYPE_NOSAMEGUILD] = true,
	[RESPONSE_TYPE_DECLINED_ALREADYHAVE] = true,
	[RESPONSE_TYPE_DECLINED] = true,
	[RESPONSE_TYPE_HAVE] = true,
	[RESPONSE_TYPE_NOT_HAVE] = true,
	[RESPONSE_TYPE_NOWA] = true,
}

AuraCheck.AuraState = {} --hold aura state received from other users
--structure:
-- AuraState [ PLAYER NAME ] = { [AURANAME] = AURASTATE}

AuraCheck.menu_text = function (plugin)
	if (AuraCheck.db.enabled) then
		return toolbar_icon, icon_texcoord, "Aura Check & Share", text_color_enabled
	else
		return toolbar_icon, icon_texcoord, "Aura Check & Share", text_color_disabled
	end
end

AuraCheck.menu_popup_show = function (plugin, ct_frame, param1, param2)

end

AuraCheck.menu_popup_hide = function (plugin, ct_frame, param1, param2)

end

AuraCheck.menu_on_click = function (plugin)

end

AuraCheck.OnInstall = function (plugin)
	AuraCheck.db.menu_priority = default_priority
	
	AuraCheck:RegisterPluginComm (COMM_AURA_CHECKREQUEST, AuraCheck.PluginCommReceived)
	AuraCheck:RegisterPluginComm (COMM_AURA_CHECKRECEIVED, AuraCheck.PluginCommReceived)	
	AuraCheck:RegisterPluginComm (COMM_AURA_INSTALLREQUEST, AuraCheck.PluginCommReceived)	
	
	if (AuraCheck.db.enabled) then
		AuraCheck.OnEnable (AuraCheck)
	end
end

AuraCheck.OnEnable = function (plugin)
	
end

AuraCheck.OnDisable = function (plugin)
	
end

AuraCheck.OnProfileChanged = function (plugin)

end

local lower = string.lower
local sortFunction = function (t1, t2) return t2[1] < t1[1] end
local sortFunction2 = function (t1, t2) return lower(t2) > lower(t1) end

--reuse some tables to update the fill panel
local alphabeticalPlayers = {}
local auraNames = {}
local panelHeader = {}

function AuraCheck.UpdateAurasFillPanel (fillPanel)
	fillPanel = fillPanel or (AuraCheckerAurasFrame and AuraCheckerAurasFrame.fillPanel)
	if (not fillPanel) then
		return
	end

	wipe (alphabeticalPlayers)
	wipe (auraNames)
	wipe (panelHeader)

	--alphabetical order
	for playerName, auraStateTable in pairs (AuraCheck.AuraState) do
		tinsert (alphabeticalPlayers, {playerName, auraStateTable})
		for auraName, _ in pairs (auraStateTable) do
			auraNames [auraName] = true
		end
	end
	table.sort (alphabeticalPlayers, sortFunction)	
	
	if (#alphabeticalPlayers > 0) then
		fillPanel.NoAuraLabel:Hide()
		fillPanel.ResultInfoLabel:Hide()
	else
		fillPanel.NoAuraLabel:Show()
		fillPanel.ResultInfoLabel:Show()
	end
	
	tinsert (panelHeader, {name = "Player Name", type = "text", width = 120})
	for auraName, _ in pairs (auraNames) do
		tinsert (panelHeader, {name = auraName, type = "text", width = 120})
	end
	
	fillPanel:SetFillFunction (function (index) 
		local playerName = alphabeticalPlayers [index][1]
		local stateTable = alphabeticalPlayers [index][2]
	
		local temp = {}
		for auraName, _ in pairs (auraNames) do
			tinsert (temp, 
					(stateTable [auraName] == RESPONSE_TYPE_NOSAMEGUILD and "|cFFFF0000guild|r") or --is not from the same guild
					(stateTable [auraName] == RESPONSE_TYPE_DECLINED_ALREADYHAVE and "|cFFFFFF00ok|r") or --refused but already has one installed
					(stateTable [auraName] == RESPONSE_TYPE_DECLINED and "|cFFFF0000declined|r") or --refused to install
					(stateTable [auraName] == RESPONSE_TYPE_HAVE and "|cFF55FF55ok|r") or  --have
					(stateTable [auraName] == RESPONSE_TYPE_NOT_HAVE and "|cFFFF5555-|r") or --not have
					(stateTable [auraName] == RESPONSE_TYPE_NOWA and "|cFFFF5555NO WA|r") or --no wa installed
					(stateTable [auraName] == RESPONSE_TYPE_WAITING and "|cFF888888?|r") or --still waiting the user answer
					(stateTable [auraName] == RESPONSE_TYPE_OFFLINE and "|cFFFF0000offline|r") --the user is offline
				)
		end
		return {playerName, unpack (temp)}
	end)
	
	fillPanel:SetTotalFunction (function() return #alphabeticalPlayers end)
	fillPanel:SetSize (790, 503)
	fillPanel:UpdateRows (panelHeader)
	fillPanel:Refresh()
	
	--update received auras scroll
	AuraCheckerHistoryFrameHistoryScroll.Update()
end

function AuraCheck.OnShowOnOptionsPanel()
	local OptionsPanel = AuraCheck.OptionsPanel
	AuraCheck.BuildOptions (OptionsPanel)
end

function AuraCheck.BuildOptions (frame)
	
	if (frame.FirstRun) then
		return
	end
	frame.FirstRun = true
	
	local framesSize = {800, 600}
	local framesPoint = {"topleft", frame, "topleft", 0, -30}
	local backdrop = {bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tileSize = 64, tile = true}
	local backdropColor = {0, 0, 0, 0.5}
	
	function AuraCheck.ShowAurasPanel()
		AuraCheckerAurasFrame:Show()
		AuraCheckerHistoryFrame:Hide()
		frame.showMainFrameButton:SetBackdropBorderColor (1, 1, 0)
		frame.showHistoryFrameButton:SetBackdropBorderColor (0, 0, 0)
		frame.ShowingPanel = 1
	end
	function AuraCheck.ShowHistoryPanel()
		AuraCheckerAurasFrame:Hide()
		AuraCheckerHistoryFrame:Show()
		frame.showMainFrameButton:SetBackdropBorderColor (0, 0, 0)
		frame.showHistoryFrameButton:SetBackdropBorderColor (1, 1, 0)
		frame.ShowingPanel = 2
	end
	
	--on main frame
		local mainButtonTemplate = {
			backdrop = {edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize = 1, bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tileSize = 64, tile = true},
			backdropcolor = {1, 1, 1, .5},
			onentercolor = {1, 1, 1, .5},
		}
	
		--button - show auras
		local showMainFrameButton = AuraCheck:CreateButton (frame, AuraCheck.ShowAurasPanel, 100, 18, "Results", _, _, _, "showMainFrameButton", _, _, mainButtonTemplate, AuraCheck:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
		showMainFrameButton:SetPoint ("topleft", frame, "topleft", 0, 5)
		showMainFrameButton:SetIcon ([[Interface\BUTTONS\UI-GuildButton-PublicNote-Up]], 14, 14, "overlay", {0, 1, 0, 1}, {1, 1, 1}, 2, 1, 0)
	
		--button - show history
		local showHistoryFrameButton = AuraCheck:CreateButton (frame, AuraCheck.ShowHistoryPanel, 100, 18, "Received Auras", _, _, _, "showHistoryFrameButton", _, _, mainButtonTemplate, AuraCheck:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
		showHistoryFrameButton:SetPoint ("left", showMainFrameButton, "right", 2, 0)
		showHistoryFrameButton:SetIcon ([[Interface\BUTTONS\JumpUpArrow]], 14, 12, "overlay", {0, 1, 1, 0}, {1, .5, 1}, 2, 1, 0)
	
		showMainFrameButton:SetBackdropBorderColor (1, 1, 0)
		frame.ShowingPanel = 1
	
	--auras frame
	
		local aurasFrame = CreateFrame ("frame", "AuraCheckerAurasFrame", frame)
		aurasFrame:SetPoint (unpack (framesPoint))
		aurasFrame:SetSize (unpack (framesSize))
		
		local NoAuraLabel = AuraCheck:CreateLabel (aurasFrame, "Select a weakaura on the right scroll box.\nClick on 'Check Aura', to see users who has it in the raid.\nClick on 'Share Aura' to send the aura to all raid members.\nRaid members also must have 'Raid Assist' addon.")
		NoAuraLabel:SetPoint ("left", RaidAssistOptionsPanel, "left", 195, 160)
		NoAuraLabel.align = "left"
		AuraCheck:SetFontSize (NoAuraLabel, 14)
		AuraCheck:SetFontColor (NoAuraLabel, "silver")
		
		local ResultInfoLabel = AuraCheck:CreateLabel (aurasFrame, "When checking or sharing an aura, results can be:\n\n|cFFFF0000guild|r: is not from the same guild\n|cFFFFFF00ok|r: refused but already has the aura installed\n|cFFFF0000declined|r: the user declined the aura\n|cFF55FF55ok|r: the user accepted or already have the aura\n|cFFFF5555-|r: the user DO NOT have the aura\n|cFFFF5555NO WA|r: the user DO NOT have weakauras installed\n|cFF888888?|r: waiting the answer from the raid member\n|cFFFF0000offline|r: the raid member is offline")
		ResultInfoLabel:SetPoint ("left", RaidAssistOptionsPanel, "left", 195, 30)
		ResultInfoLabel.align = "left"
		AuraCheck:SetFontSize (ResultInfoLabel, 14)
		AuraCheck:SetFontColor (ResultInfoLabel, "silver")
		
		--fillpanel - auras panel
		local fillPanel = AuraCheck:CreateFillPanel (aurasFrame, {}, 790, 450, false, false, false, {rowheight = 13}, _, "AuraCheckerAurasFrameFillPanel")
		fillPanel:SetPoint ("topleft", aurasFrame, "topleft", 0, 0)
		aurasFrame.fillPanel = fillPanel
		
		fillPanel.NoAuraLabel = NoAuraLabel
		fillPanel.ResultInfoLabel = ResultInfoLabel
		
		--fauxscroll - auras scrollbar
		
		local updateAddonsList = function (self)
			local auras = AuraCheck:GetAllWeakAurasNames()
			
			if (not auras) then
				return
			end
			
			if (self.SearchingFor ~= "") then
				local search = lower (self.SearchingFor)
				for i = #auras, 1, -1 do
					if (not lower (auras [i]):find (search)) then
						tremove (auras, i)
					end
				end
			end
			
			table.sort (auras, sortFunction2)
			
			FauxScrollFrame_Update (self, #auras, CONST_AURALIST_ROWS, 21) --self, amt, amt frames, height of each frame
			
			local offset = FauxScrollFrame_GetOffset (self)
			
			for i = 1, CONST_AURALIST_ROWS do
				local index = i + offset
				local button = self.Frames [i]
				local data = auras [index]
				
				if (data) then
					button.Label:SetText (data)
					if (data == self.CurrentAuraSelected) then
						button:SetBackdropColor (1, 1, 0)
					else
						button:SetBackdropColor (unpack (backdropColor))
					end
					button:Show()
				else
					button.Label:SetText ("")
					button:Hide()
				end
			end
			
			self:Show()
		end
		
		local auraScroll = CreateFrame ("scrollframe", "AuraCheckerAurasFrameAuraScroll", frame, "FauxScrollFrameTemplate")
		auraScroll:SetPoint ("topleft", aurasFrame, "topleft", 795, -5)
		auraScroll:SetSize (180, CONST_AURALIST_ROWS*21 - 5)
		auraScroll.CurrentAuraSelected = "-none-"
		auraScroll.SearchingFor = ""
		auraScroll:EnableMouseWheel(true)
		auraScroll:EnableMouse(true)
		
		DetailsFramework:ReskinSlider (auraScroll)

		auraScroll:SetScript ("OnVerticalScroll", function (self, offset) 
			FauxScrollFrame_OnVerticalScroll (self, offset, 20, updateAddonsList) 
		end)
		
		auraScroll.Frames = {}
		
		local on_mousedown = function (self)
			if (self.Label:GetText() ~= "") then
				auraScroll.CurrentAuraSelected = self.Label:GetText()
				updateAddonsList (auraScroll)
				
				local now = GetTime()
				if (self.LastClick + 0.22 > now) then
					if (WeakAuras and WeakAuras.IsOptionsOpen) then
						if (WeakAuras.IsOptionsOpen()) then
							WeakAurasFilterInput:SetText (self.Label:GetText())
						else
							WeakAuras.OpenOptions (self.Label:GetText())
							WeakAurasFilterInput:SetText (self.Label:GetText())
						end						
					end
				end
				self.LastClick = now
			end
		end
		
		local aura_on_enter = function (self)
			if (auraScroll.CurrentAuraSelected ~= self.Label:GetText()) then
				self:SetBackdropColor (.3, .3, .3, .75)
			end
		end
		local aura_on_leave = function (self)
			if (auraScroll.CurrentAuraSelected ~= self.Label:GetText()) then
				self:SetBackdropColor (unpack (backdropColor))
			end
		end
		
		--> aura selection
		for i = 1, CONST_AURALIST_ROWS do
			local f = CreateFrame ("frame", "AuraCheckerAurasFrameAuraScroll_Button" .. i, auraScroll)
			f:SetPoint ("topleft", auraScroll, "topleft", 2, -(i-1)*21)
			f:SetScript ("OnMouseUp", on_mousedown)
			f:SetScript ("OnEnter", aura_on_enter)
			f:SetScript ("OnLeave", aura_on_leave)
			f:SetSize (180, 20)
			f:SetBackdrop (backdrop)
			f:SetBackdropColor (unpack (backdropColor))
			f.LastClick = 0
			f:EnableMouse(true)
			local label = f:CreateFontString (nil, "overlay", "GameFontNormal")
			label:SetPoint ("left", f, "left", 2, 0)
			AuraCheck:SetFontSize (label, 10)
			AuraCheck:SetFontColor (label, "white")
			f.Label = label
			tinsert (auraScroll.Frames, f)
		end
	
		--textbox - search aura
		local onTextChanged = function()
			local text = frame.searchBox:GetText()
			auraScroll.SearchingFor = text
			updateAddonsList (auraScroll)
		end
		local searchBox = AuraCheck:CreateTextEntry (frame, function()end, 160, 20, "searchBox", _, _, AuraCheck:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"))
		searchBox:SetPoint ("bottomleft", auraScroll, "topleft", 0, 2)
		searchBox:SetSize (160, 18)
		searchBox:SetHook ("OnTextChanged", onTextChanged)
		
		local mglass = AuraCheck:CreateImage (searchBox, [[Interface\MINIMAP\TRACKING\None]], 18, 18)
		mglass:SetPoint ("left", searchBox, "left", 2, 0)

		local clearSearchBoxFunc = function()
			frame.searchBox:SetText ("")
			
		end
		local clearSearchBox = AuraCheck:CreateButton (frame, clearSearchBoxFunc, 12, 18, "", _, _, _, "clearSearchBox")
		clearSearchBox:SetPoint ("left", searchBox, "right", 2, 0)
		clearSearchBox:SetIcon ([[Interface\Glues\LOGIN\Glues-CheckBox-Check]])
		
		--button - share and check aura
		
		AuraCheck.last_data_request = 0
		
		local checkAuraFunc = function()
		
			NoAuraLabel:Hide()
			ResultInfoLabel:Hide()
		
			--get the selected aura
			local auraSelected = auraScroll.CurrentAuraSelected
			if (auraSelected == "" or auraSelected == "-none-") then
				return AuraCheck:Msg ("you need to select an aura before.")
			end
			
			local auraName = auraSelected
			
			--get the aura object
			local auraTable = AuraCheck:GetWeakAuraTable (auraName)
			if (not auraTable) then
				return AuraCheck:Msg ("aura not found.")
			end
			
			--am i the raid leader and can i send the request?
			if (not IsInRaid () and not IsInGroup ()) then
				return AuraCheck:Msg ("you aren't in a local raid group.")
				
			elseif (not AuraCheck:UnitIsRaidLeader (UnitName ("player")) and not RA:UnitHasAssist ("player")) then
				return AuraCheck:Msg ("you aren't the raid leader or assistant.")
				
			elseif (AuraCheck.last_data_request + 5 > time()) then
				return AuraCheck:Msg ("another task still ongoing, please wait.")
				
			end
			
			--send the request
			AuraCheck:SendPluginCommMessage (COMM_AURA_CHECKREQUEST, AuraCheck.GetChannel(), _, _, AuraCheck:GetPlayerNameWithRealm(), auraName)
			
			--fill the result table
			local myName = UnitName ("player") .. "-" .. GetRealmName()
			
			if (IsInRaid()) then
				for i = 1, GetNumGroupMembers() do
					local playerName, realmName = UnitName ("raid" .. i)
					if (realmName == "" or realmName == nil) then
						realmName = GetRealmName()
					end
					playerName = playerName .. "-" .. realmName
					
					AuraCheck.AuraState [playerName] = AuraCheck.AuraState [playerName] or {}
					if (myName == playerName) then
						AuraCheck.AuraState [playerName] [auraName] = RESPONSE_TYPE_HAVE
					else
						if (UnitIsConnected ("raid" .. i)) then
							AuraCheck.AuraState [playerName] [auraName] = RESPONSE_TYPE_WAITING
						else
							AuraCheck.AuraState [playerName] [auraName] = RESPONSE_TYPE_OFFLINE
						end
					end
				end
			elseif (IsInGroup()) then
				for i = 1, GetNumGroupMembers() do
					local playerName, realmName = UnitName ("party" .. i)
					if (realmName == "" or realmName == nil) then
						realmName = GetRealmName()
					end
					playerName = playerName .. "-" .. realmName
					
					AuraCheck.AuraState [playerName] = AuraCheck.AuraState [playerName] or {}
					if (myName == playerName) then
						AuraCheck.AuraState [playerName] [auraName] = RESPONSE_TYPE_HAVE
					else
						if (UnitIsConnected ("party" .. i)) then
							AuraCheck.AuraState [playerName] [auraName] = RESPONSE_TYPE_WAITING
						else
							AuraCheck.AuraState [playerName] [auraName] = RESPONSE_TYPE_OFFLINE
						end
					end
				end
			end
			
			--wait the results
			AuraCheck.last_data_request = time()
			--statusBar
			frame.statusBarWorking.lefttext = "Working..."
			frame.statusBarWorking:SetTimer (5)
			
			AuraCheck.UpdateAurasFillPanel()
		end
		
		local shareAuraFunc = function()
		
			NoAuraLabel:Hide()
			ResultInfoLabel:Hide()
		
			local auraSelected = auraScroll.CurrentAuraSelected
			if (auraSelected == "" or auraSelected == "-none-") then
				return AuraCheck:Msg ("you need to select an aura before.")
			end
			
			--am i the raid leader and can i send the request?
			if (not IsInRaid () and not IsInGroup ()) then
				return AuraCheck:Msg ("you aren't in a local raid group.")
				
			elseif (not AuraCheck:UnitIsRaidLeader (UnitName ("player")) and not RA:UnitHasAssist ("player")) then
				return AuraCheck:Msg ("you aren't the raid leader or assistant.")
				
			elseif (AuraCheck.last_data_request + 5 > time()) then
				return AuraCheck:Msg ("another task still ongoing, please wait.")
			end

			local auraName = auraSelected
			
			local compressedAura = WeakAuras.DisplayToString (auraName, true)
			--Details:DumpString (compressedAura)
			--if true then return end
			
			if (not compressedAura or type (compressedAura) ~= "string") then
				return AuraCheck:Msg ("failed to export the aura from WeakAuras.")
			end
			
			--get the aura object
			--local auraTable = AuraCheck:GetWeakAuraTable (auraName)
			--if (not auraTable) then
			--	return AuraCheck:Msg ("aura not found.")
			--end

			--send the aura
			AuraCheck:SendPluginCommMessage (COMM_AURA_INSTALLREQUEST, AuraCheck.GetChannel(), _, _, AuraCheck:GetPlayerNameWithRealm(), auraName, false, compressedAura)
			
			--fill the result table
			local myName = UnitName ("player") .. "-" .. GetRealmName()
			
			if (IsInRaid()) then
				for i = 1, GetNumGroupMembers() do
					local playerName, realmName = UnitName ("raid" .. i)
					if (realmName == "" or realmName == nil) then
						realmName = GetRealmName()
					end
					playerName = playerName .. "-" .. realmName
					
					AuraCheck.AuraState [playerName] = AuraCheck.AuraState [playerName] or {}
					if (myName == playerName) then
						AuraCheck.AuraState [playerName] [auraName] = RESPONSE_TYPE_HAVE
					else
						if (UnitIsConnected ("raid" .. i)) then
							AuraCheck.AuraState [playerName] [auraName] = RESPONSE_TYPE_WAITING
						else
							AuraCheck.AuraState [playerName] [auraName] = RESPONSE_TYPE_OFFLINE
						end
					end
				end
				
			elseif (IsInGroup()) then
				for i = 1, GetNumGroupMembers() do
					local playerName, realmName = UnitName ("party" .. i)
					if (realmName == "" or realmName == nil) then
						realmName = GetRealmName()
					end
					playerName = playerName .. "-" .. realmName
					
					AuraCheck.AuraState [playerName] = AuraCheck.AuraState [playerName] or {}
					if (myName == playerName) then
						AuraCheck.AuraState [playerName] [auraName] = RESPONSE_TYPE_HAVE
					else
						if (UnitIsConnected ("party" .. i)) then
							AuraCheck.AuraState [playerName] [auraName] = RESPONSE_TYPE_WAITING
						else
							AuraCheck.AuraState [playerName] [auraName] = RESPONSE_TYPE_OFFLINE
						end
					end
				end
			end
			
			--wait the results
			AuraCheck.last_data_request = time()
			--statusBar
			frame.statusBarWorking.lefttext = "Sending..."
			frame.statusBarWorking:SetTimer (5)
			
			AuraCheck.UpdateAurasFillPanel()
		end

		local checkAuraButton = AuraCheck:CreateButton (frame, checkAuraFunc, 98, 18, "Check Aura", _, _, _, "checkAuraButton", _, _, AuraCheck:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"), AuraCheck:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
		local shareAuraButton = AuraCheck:CreateButton (frame, shareAuraFunc, 98, 18, "Share Aura", _, _, _, "shareAuraButton", _, _, AuraCheck:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"), AuraCheck:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
		
		checkAuraButton:SetPoint ("bottomleft", searchBox, "topleft", 0, 2)
		shareAuraButton:SetPoint ("left", checkAuraButton, "right", 2, 0)
		
		checkAuraButton:SetIcon ([[Interface\BUTTONS\UI-CheckBox-Check]], 16, 16, "overlay", {0, 1, 0, 28/32}, {1, 1, 1}, 2, 1, 0)
		shareAuraButton:SetIcon ([[Interface\BUTTONS\JumpUpArrow]], 14, 12, "overlay", {0, 1, 0, 32/32}, {1, 1, 1}, 2, 1, 0)
		
		checkAuraButton.tooltip = "Verifies if raid memebers has the selected aura installed."
		shareAuraButton.tooltip = "Send the selected aura to raid members.\nThey can accept the aura or decline.\nThe result is shown on the panel."
		
		--local statusBar = AuraCheck:CreateBar (frame, LibStub:GetLibrary ("LibSharedMedia-3.0"):Fetch ("statusbar", "Iskar Serenity"), 590, 18, 100, "statusBarWorking", "AuraCheckerStatusBar")
		local statusBar = AuraCheck:CreateBar (frame, LibStub:GetLibrary ("LibSharedMedia-3.0"):Fetch ("statusbar", "Iskar Serenity"), 583, 16, 100, "statusBarWorking", "AuraCheckerStatusBar")
		--statusBar:SetPoint ("topleft", frame, "topleft", 2, -431)
		statusBar:SetPoint ("left", showHistoryFrameButton, "right", 2, 0)
		statusBar.RightTextIsTimer = true
		statusBar.BarIsInverse = false
		statusBar.fontsize = 11
		statusBar.fontface = "Accidental Presidency"
		statusBar.fontcolor = "darkorange"
		statusBar.color = "gray"
		statusBar.texture = "Iskar Serenity"
		statusBar.lefttext = "Ready!"
		statusBar:SetHook ("OnTimerEnd", function()
			statusBar.lefttext = "Ready!"
			statusBar.value = 100
			statusBar.shown = true
			statusBar.div_timer:Hide()
			return true
		end)

	--history frame
		local historyFrame = CreateFrame ("frame", "AuraCheckerHistoryFrame", frame)
		historyFrame:SetPoint (unpack (framesPoint))
		historyFrame:SetSize (unpack (framesSize))
	
		--received auras scrollbar
		local uninstall_func = function (self, button, auraName)
--			print (self, button, auraName)
			
			if (not _G.WeakAuras) then
				return AuraCheck:Msg ("WeakAuras not found. AddOn is disabled?")
			end
			if (not WeakAuras.IsOptionsOpen) then
				return AuraCheck:Msg ("WeakAuras options not found. WeakAuras options is disabled?")
			end
			
			if (WeakAuras.IsOptionsOpen()) then
				WeakAurasFilterInput:SetText (auraName)
			else
				WeakAuras.OpenOptions (auraName)
			end
		end		
		
		local updateHistoryList = function (self)
			self = self or AuraCheckerHistoryFrameHistoryScroll
			local auras = AuraCheck.db.installed_history
			if (not auras) then
				return
			end
			
			--> clean up auras
			for i = #auras, 1, -1 do
				local auraName = auras [i][1]
				if (not AuraCheck:GetWeakAuraTable (auraName)) then
					tremove (auras, i)
				end
			end
			
			--> update the scroll
			FauxScrollFrame_Update (self, #auras, 20, 19) --self, amt, amt frames, height of each frame
			local offset = FauxScrollFrame_GetOffset (self)
			
			for i = 1, 20 do
				local index = i + offset
				local button = self.Frames [i]
				local data = auras [index]
				
				if (data) then
					button.auraName:SetText (data [1])
					button.auraFrom:SetText (data [2])
					button.auraDate:SetText (date ("%m/%d/%y %H:%M:%S", data [3]))
					button.uninstallButton:SetClickFunction (uninstall_func, data [1])
					button:Show()
				else
					button:Hide()
				end
			end
		end
		
		local historyScroll = CreateFrame ("scrollframe", "AuraCheckerHistoryFrameHistoryScroll", historyFrame, "FauxScrollFrameTemplate")
		historyScroll:SetPoint ("topleft", historyFrame, "topleft", 0, 0)
		historyScroll:SetSize (767, 503)
		DetailsFramework:ReskinSlider (historyScroll)
		
		historyScroll:SetScript ("OnVerticalScroll", function (self, offset) 
			FauxScrollFrame_OnVerticalScroll (self, offset, 20, updateHistoryList)
		end)
		
		function historyScroll.Update()
			updateHistoryList (historyScroll)
		end
		historyFrame:SetScript ("OnShow", function()
			updateHistoryList (historyScroll)
			historyScroll:Show()
		end)
		
		historyScroll.Frames = {}

		for i = 1, CONST_RESULTAURALIST_ROWS do
			local f = CreateFrame ("frame", "AuraCheckerHistoryFrameHistoryScroll_Button" .. i, historyScroll)
			f:SetPoint ("topleft", historyScroll, "topleft", 2, -(i-1)*19)
			f:SetSize (571, 18)
			f:SetBackdrop (backdrop)
			f:SetBackdropColor (unpack (backdropColor))
			
			local uninstallButton = AuraCheck:CreateButton (f, uninstall_func, 12, 18)
			uninstallButton:SetIcon ([[Interface\Glues\LOGIN\Glues-CheckBox-Check]])
			
			local auraName = f:CreateFontString (nil, "overlay", "GameFontNormal")
			local auraFrom = f:CreateFontString (nil, "overlay", "GameFontNormal")
			local auraDate = f:CreateFontString (nil, "overlay", "GameFontNormal")
			AuraCheck:SetFontSize (auraName, 10)
			AuraCheck:SetFontColor (auraName, "white")
			AuraCheck:SetFontSize (auraFrom, 10)
			AuraCheck:SetFontColor (auraFrom, "white")
			AuraCheck:SetFontSize (auraDate, 10)
			AuraCheck:SetFontColor (auraDate, "white")

			uninstallButton:SetPoint ("left", f, "left", 2, 0)
			auraName:SetPoint ("left", f, "left", 26, 0)
			auraFrom:SetPoint ("left", f, "left", 190, 0)
			auraDate:SetPoint ("left", f, "left", 360, 0)
			
			f.auraName = auraName
			f.auraFrom = auraFrom
			f.auraDate = auraDate
			f.uninstallButton = uninstallButton
			tinsert (historyScroll.Frames, f)
		end
	
	
	--all frames built
	AuraCheck.ShowAurasPanel()
	
	AuraCheck.UpdateAurasFillPanel (fillPanel)
	updateAddonsList (auraScroll)
	updateHistoryList (historyScroll)
	
	frame:SetScript ("OnShow", function()
		AuraCheck.UpdateAurasFillPanel (fillPanel)
	end)
	
end

local install_status = RA:InstallPlugin ("Aura Check", "RAAuraCheck", AuraCheck, default_config)

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function AuraCheck.SendAuraStatus (auraName)
	--> get weakauras global 
	local WeakAuras_Object, WeakAuras_SavedVar = AuraCheck:GetWeakAuras2Object()
	if (WeakAuras_Object) then --> the user has weakauras installed
		local isInstalled = AuraCheck:GetWeakAuraTable (auraName)
		if (isInstalled) then
			AuraCheck:SendPluginCommMessage (COMM_AURA_CHECKRECEIVED, AuraCheck.GetChannel(), _, _, AuraCheck:GetPlayerNameWithRealm(), auraName, 1)
		else
			AuraCheck:SendPluginCommMessage (COMM_AURA_CHECKRECEIVED, AuraCheck.GetChannel(), _, _, AuraCheck:GetPlayerNameWithRealm(), auraName, 0)
		end
	else --> the user don't have weakauras installed 
		AuraCheck:SendPluginCommMessage (COMM_AURA_CHECKRECEIVED, AuraCheck.GetChannel(), _, _, AuraCheck:GetPlayerNameWithRealm(), auraName, -1)
	end
end

function AuraCheck.IsValidResultIndex (index)
	if (valid_results [index]) then
		return true
	end
end

function AuraCheck.GetChannel()
	if (IsInRaid()) then
		return "RAID-NOINSTANCE"
	elseif (IsInGroup()) then
		return "PARTY-NOINSTANCE"
	else
		return "RAID-NOINSTANCE"
	end
end

function AuraCheck.PluginCommReceived (prefix, sourcePluginVersion, playerName, auraName, auraState, auraString)

	--print ("COMM", prefix, playerName, auraName, auraState, auraString)

	if (type (playerName) ~= "string" or type (auraName) ~= "string") then
		return
	end
	
	if (prefix == COMM_AURA_CHECKREQUEST) then --leader is requesting an aura check
		--check if who sent is indeed the leader or assistant
		if (AuraCheck:UnitIsRaidLeader (playerName) or RA:UnitHasAssist (playerName)) then	
			--send the aura state
			AuraCheck.SendAuraStatus (auraName)
		end

	elseif (prefix == COMM_AURA_CHECKRECEIVED) then --some raid member sent the aura status
		--is a valid result?
		if (type (auraState) == "number") then
			if (AuraCheck.IsValidResultIndex (auraState)) then
				--add the user to the result list
				AuraCheck.AuraState [playerName] = AuraCheck.AuraState [playerName] or {}
				AuraCheck.AuraState [playerName] [auraName] = auraState
				--update the panel if it is already created and is shown
				AuraCheck.UpdateAurasFillPanel()
			end
		end
	
	elseif (prefix == COMM_AURA_INSTALLREQUEST) then --leader is requesting an aura install
		--check if who sent is indeed the leader
		if (not AuraCheck:UnitIsRaidLeader (playerName) and not RA:UnitHasAssist (playerName)) then
			return
		end
		--check if the sender isnt 'me'
		if (playerName == UnitName ("player")) then
			return
		end
		
		if (false and AuraCheck.db.only_from_guild) then --disabling this
			if (not IsInGuild()) then
				--send a packet notifying about the no guild
				AuraCheck:SendPluginCommMessage (COMM_AURA_CHECKRECEIVED, AuraCheck.GetChannel(), _, _, AuraCheck:GetPlayerNameWithRealm(), auraName, RESPONSE_TYPE_NOSAMEGUILD)
				return
			end
			if (not AuraCheck:IsGuildFriend (playerName)) then
				--send a packet notify isnt from the same guild
 				AuraCheck:SendPluginCommMessage (COMM_AURA_CHECKRECEIVED, AuraCheck.GetChannel(), _, _, AuraCheck:GetPlayerNameWithRealm(), auraName, RESPONSE_TYPE_NOSAMEGUILD)
				return
			end
		end
		
		if (type (auraString) == "string") then
			--> check for trusted - auto install if trusted
			if (AuraCheck.db.auto_install_from_trusted) then
				if (AuraCheck.IsTrusted (playerName)) then
					AuraCheck.InstallAura (auraName, playerName, auraString, time())
					return
				end
			end
			
			--> ask to install
			AuraCheck.WaitingAnswer = AuraCheck.WaitingAnswer or {}
			tinsert (AuraCheck.WaitingAnswer, {auraName, playerName, auraString, time()})
			
			AuraCheck.AskToInstall()
		end
	end
end

function AuraCheck.InstallAura (auraName, playerName, auraString, time)
	WeakAuras.ImportString (auraString)
	WeakAurasTooltipImportButton:Click()
	
	tinsert (AuraCheck.db.installed_history, {auraName, playerName, time})
	AuraCheck:SendPluginCommMessage (COMM_AURA_CHECKRECEIVED, AuraCheck.GetChannel(), _, _, AuraCheck:GetPlayerNameWithRealm(), auraName, 1)
end

function AuraCheck.DeclineAura (auraName, playerName, auraString, time)
	--> check if already is installed
	if (AuraCheck:GetWeakAuraTable (auraName)) then
		AuraCheck:SendPluginCommMessage (COMM_AURA_CHECKRECEIVED, AuraCheck.GetChannel(), _, _, AuraCheck:GetPlayerNameWithRealm(), auraName, 3)
	else
		AuraCheck:SendPluginCommMessage (COMM_AURA_CHECKRECEIVED, AuraCheck.GetChannel(), _, _, AuraCheck:GetPlayerNameWithRealm(), auraName, 2)
	end
end

function AuraCheck.CreateFlash (frame, duration, amount, r, g, b)
	--defaults
	duration = duration or 0.25
	amount = amount or 1
	
	if (not r) then
		r, g, b = 1, 1, 1
	else
		r, g, b = RA:ParseColors (r, g, b)
	end

	--create the flash frame
	local f = CreateFrame ("frame", "RaidAssistAuraCheckFlashAnimationFrame".. math.random (1, 100000000), frame)
	f:SetFrameLevel (frame:GetFrameLevel()+1)
	f:SetAllPoints()
	f:Hide()
	
	--create the flash texture
	local t = f:CreateTexture ("RaidAssistAuraCheckFlashAnimationTexture".. math.random (1, 100000000), "artwork")
	t:SetTexture (r, g, b)
	t:SetAllPoints()
	t:SetBlendMode ("ADD")
	t:Hide()
		
	local OnPlayCustomFlashAnimation = function (animationHub)
		animationHub:GetParent():Show()
		animationHub.Texture:Show()
	end
	local OnStopCustomFlashAnimation = function (animationHub)
		animationHub:GetParent():Hide()
		animationHub.Texture:Hide()
	end
	
	--create the flash animation
	local animationHub = RA:CreateAnimationHub (f, OnPlayCustomFlashAnimation, OnStopCustomFlashAnimation)
	animationHub.AllAnimations = {}
	animationHub.Parent = f
	animationHub.Texture = t
	animationHub.Amount = amount
	
	for i = 1, amount * 2, 2 do
		local fadeIn = RA:CreateAnimation (animationHub, "ALPHA", i, duration, 0, 1)
		local fadeOut = RA:CreateAnimation (animationHub, "ALPHA", i + 1, duration, 1, 0)
		tinsert (animationHub.AllAnimations, fadeIn)
		tinsert (animationHub.AllAnimations, fadeOut)
	end
	
	return animationHub
end

function AuraCheck.AskToInstall()
	if (not AuraCheck.AskFrame) then
		AuraCheck.AskFrame = RA:CreateSimplePanel (UIParent, 380, 130, "Raid Assist: WA Sharer", "RaidAssistWAConfirmation")
		AuraCheck.AskFrame:SetSize (380, 100)
		AuraCheck.AskFrame:Hide()

		AuraCheck.AskFrame.accept_text = AuraCheck:CreateLabel (AuraCheck.AskFrame, "", AuraCheck:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
		AuraCheck.AskFrame.accept_text:SetPoint (16, -28)
		
		AuraCheck.AskFrame.aura_name = AuraCheck:CreateLabel (AuraCheck.AskFrame, "", AuraCheck:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
		AuraCheck.AskFrame.aura_name:SetPoint (16, -46)
		
		local accept_aura = function (self, button, t)
			AuraCheck.InstallAura (unpack (t))
			AuraCheck.AskFrame:Hide()
			AuraCheck.AskToInstall()
		end
		local decline_aura = function (self, button, t)
			AuraCheck.DeclineAura (unpack (t))
			AuraCheck.AskFrame:Hide()
			AuraCheck.AskToInstall()
		end
		
		AuraCheck.AskFrame.accept_button = AuraCheck:CreateButton (AuraCheck.AskFrame, accept_aura, 100, 20, "Accept", -1, nil, nil, nil, nil, nil, RA:GetTemplate ("button", "OPTIONS_BUTTON_TEMPLATE"))
		AuraCheck.AskFrame.decline_button = AuraCheck:CreateButton (AuraCheck.AskFrame, decline_aura, 100, 20, "Decline", -1, nil, nil, nil, nil, nil, RA:GetTemplate ("button", "OPTIONS_BUTTON_TEMPLATE"))
		
		AuraCheck.AskFrame.accept_button:SetPoint ("bottomright", AuraCheck.AskFrame, "bottomright", -14, 11)
		AuraCheck.AskFrame.decline_button:SetPoint ("bottomleft", AuraCheck.AskFrame, "bottomleft", 14, 11)
		
		AuraCheck.AskFrame.Flash = AuraCheck.CreateFlash (AuraCheck.AskFrame)
	end
	
	if (AuraCheck.AskFrame:IsShown()) then
		return
	end

	local nextAura = tremove (AuraCheck.WaitingAnswer)
	
	if (nextAura) then
		rawset (AuraCheck.AskFrame.accept_button, "param1", nextAura)
		rawset (AuraCheck.AskFrame.decline_button, "param1", nextAura)
		AuraCheck.AskFrame.aura_name.text = nextAura [1]
		AuraCheck.AskFrame.accept_text.text = "|cFFFFAA00" .. nextAura [2] .. " sent an aura:|r"
		AuraCheck.AskFrame:SetPoint ("center", UIParent, "center", 0, 150)
		AuraCheck.AskFrame:Show()
		AuraCheck.AskFrame.Flash:Play()
	end
end

function AuraCheck.IsTrusted (playerName)
	--is on a guild?
	if (not IsInGuild()) then
		return
	end
	
	--> is inside a raid?
	local _, instanceType = IsInInstance()
	if (instanceType ~= "raid") then
		return
	end
	
	--> who sent is the raid leader or assistant?
	if (not AuraCheck:UnitIsRaidLeader (playerName) and not RA:UnitHasAssist (playerName)) then
		return
	end
	
	if (not RA:IsGuildFriend (playerName)) then
		return
	end
	
	return true
end


-- - dop endp endd - stop auto complete
