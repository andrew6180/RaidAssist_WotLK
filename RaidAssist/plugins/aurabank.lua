
local RA = RaidAssist
local L = LibStub ("AceLocale-3.0"):GetLocale ("RaidAssistAddon")
local LBB = LibStub("LibBabble-Boss-3.0"):GetLookupTable()
local _ 
local default_priority = 25

local default_config = {
	enabled = true,
	menu_priority = 1,
	installed_history = {},
}

local text_color_enabled = {r=1, g=1, b=1, a=1}
local text_color_disabled = {r=0.5, g=0.5, b=0.5, a=1}

local toolbar_icon = [[Interface\CHATFRAME\UI-ChatIcon-Share]]
local icon_texcoord = {l=0, r=1, t=0, b=1}

local RAID_TIERS = {
	[536] = { -- naxxramas
		name = "Naxxramas",
		boss_names = {
			LBB["Anub'Rekhan"],
			LBB["Grand Widow Faerlina"],
			LBB["Maexxna"],
			LBB["Noth the Plaguebringer"],
			LBB["Heigan the Unclean"],
			LBB["Loatheb"],
			LBB["Instructor Razuvious"],
			LBB["Gothik the Harvester"],
			LBB["The Four Horsemen"],
			LBB["Patchwerk"],
			LBB["Grobbulus"],
			LBB["Gluth"],
			LBB["Thaddius"],
			LBB["Sapphiron"],
			LBB["Kel'Thuzad"],
		},
		boss_ids = {
			[15956] = 1, --Anub'Rekhan
			[15953] = 2, --Grand Widow Faerlina
			[15952] = 3, --Maexxna
			[15954] = 4, --Noth the Plaguebringer
			[15936] = 5, --Heigan the Unclean
			[16011] = 6, --Loatheb
			[16061] = 7, --Instructor Razuvious
			[16060] = 8, --Gothik the Harvester
			[30549] = 9, --The Four Horsemen
			[16028] = 10, --Patchwerk
			[15931] = 11, --Grobbulus
			[15932] = 12, --Gluth
			[15928] = 13, --Thaddius
			[15989] = 14, --Sapphiron
			[15990] = 15, --Kel'Thuzad
		},
	},
}
local DEFAULT_SELECTED_BOSS = 1426 --hellfire assault

if (_G ["RaidAssistAuraBank"]) then
	return
end
local AuraBank = {version = "v0.1", pluginname = "Aura Bank"}
_G ["RaidAssistAuraBank"] = AuraBank

AuraBank.menu_text = function (plugin)
	if (AuraBank.db.enabled) then
		return toolbar_icon, icon_texcoord, "Aura Bank", text_color_enabled
	else
		return toolbar_icon, icon_texcoord, "Aura Bank", text_color_disabled
	end
end

AuraBank.IsDisabled = true

AuraBank.menu_popup_show = function (plugin, ct_frame, param1, param2)

end

AuraBank.menu_popup_hide = function (plugin, ct_frame, param1, param2)

end

AuraBank.menu_on_click = function (plugin)

end

AuraBank.OnInstall = function (plugin)
	AuraBank.db.menu_priority = default_priority
	
	if (AuraBank.db.enabled) then
		AuraBank.OnEnable (AuraBank)
	end
	
	for _, raidData in ipairs (RAID_TIERS) do
		local raidName = raidData.name
		for encounterID, bossID  in pairs(raidData.boss_ids) do 
			local bossName = raidData.boss_names[bossID]
			if (bossName) then
				if (not AuraBank.Bank [encounterID]) then
					AuraBank.Bank [encounterID] = {}
				end
			end
		end
	end
end

AuraBank.OnEnable = function (plugin)
	
end

AuraBank.OnDisable = function (plugin)
	
end

AuraBank.OnProfileChanged = function (plugin)

end

function AuraBank.OnShowOnOptionsPanel()
	local OptionsPanel = AuraBank.OptionsPanel
	AuraBank.BuildOptions (OptionsPanel)
end

local installRAGroup = function()
	if (WeakAurasSaved and WeakAurasSaved.displays) then
		local group = WeakAurasSaved.displays ["Raid Assist Imported"]
		if (not group) then
			local groupPrototype = RA.table.copy ({}, AuraBank.GroupPrototype)
			WeakAuras.Add (groupPrototype)
			AuraBank.InstallWaGroup:Cancel()
		end
	end
end
AuraBank.InstallWaGroup = C_Timer.NewTicker (.5, installRAGroup, 60)


local wait_for_options_panel = function()
	AuraBank.PutOnGroup (AuraBank.WaitingForAura)
end
function AuraBank.PutOnGroup (waName)
	local aura = WeakAuras.GetData (waName)
	if (not aura) then
		return AuraBank:Msg ("Aura not found.")
	end
	
	local group = WeakAuras.GetData ("Raid Assist Imported")
	if (not group) then
		installRAGroup()
	end
	
	for i = 1, #group.controlledChildren do
		if (group.controlledChildren [i] == waName) then
			return AuraBank:Msg ("Aura already on the group.")
		end
	end
	if (aura.parent) then
		return AuraBank:Msg ("Aura is already on another group.")
	end
	
	local groupButton = WeakAuras.GetDisplayButton ("Raid Assist Imported")
	local auraButton = WeakAuras.GetDisplayButton (waName)
	
	if (not groupButton or not auraButton) then
		AuraBank.WaitingForAura = waName
		C_Timer.After (.2, wait_for_options_panel)
	else
		auraButton.group:Click()
		groupButton.frame:Click()
	end
end

function AuraBank.BuildOptions (frame)

	if (frame.FirstRun) then
		return
	end
	frame.FirstRun = true
	
	local framesSize = {800, 600}
	local framesPoint = {"topleft", frame, "topleft", 0, -30}
	local backdrop = {bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tileSize = 64, tile = true}
	local backdropColor = {0, 0, 0, 0.5}
	local mainButtonTemplate = {
		backdrop = {edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize = 1, bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tileSize = 64, tile = true},
		backdropcolor = {1, 1, 1, .5},
		onentercolor = {1, 1, 1, .5},
	}
	
	function AuraBank.ShowAurasPanel()
		AuraBankerAurasFrame:Show()
		AuraBankerHistoryFrame:Hide()
		AuraBankAurasFrameInstallScroll:Show()
		frame.showMainFrameButton:SetBackdropBorderColor (1, 1, 0)
		frame.showHistoryFrameButton:SetBackdropBorderColor (0, 0, 0)
		frame.ShowingPanel = 1
	end
	function AuraBank.ShowHistoryPanel()
		AuraBankerAurasFrame:Hide()
		AuraBankerHistoryFrame:Show()
		AuraBankAurasFrameInstallScroll:Hide()
		frame.showMainFrameButton:SetBackdropBorderColor (0, 0, 0)
		frame.showHistoryFrameButton:SetBackdropBorderColor (1, 1, 0)
		frame.ShowingPanel = 2
	end
	
	--auras frame
		local aurasFrame = CreateFrame ("frame", "AuraBankerAurasFrame", frame)
		aurasFrame:SetPoint (unpack (framesPoint))
		aurasFrame:SetSize (unpack (framesSize))
	
	--history frame
		local historyFrame = CreateFrame ("frame", "AuraBankerHistoryFrame", frame)
		historyFrame:SetPoint (unpack (framesPoint))
		historyFrame:SetSize (unpack (framesSize))
	
	--button - show auras
		local showMainFrameButton = AuraBank:CreateButton (frame, AuraBank.ShowAurasPanel, 100, 18, "Install Auras", _, _, _, "showMainFrameButton", _, _, mainButtonTemplate, AuraBank:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
		showMainFrameButton:SetPoint ("topleft", frame, "topleft", 0, 5)
		showMainFrameButton:SetIcon ([[Interface\BUTTONS\UI-GuildButton-PublicNote-Up]], 14, 14, "overlay", {0, 1, 0, 1}, {1, 1, 1}, 2, 1, 0)

	--button - show history
		local showHistoryFrameButton = AuraBank:CreateButton (frame, AuraBank.ShowHistoryPanel, 100, 18, "History", _, _, _, "showHistoryFrameButton", _, _, mainButtonTemplate, AuraBank:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
		showHistoryFrameButton:SetPoint ("left", showMainFrameButton, "right", 2, 0)
		showHistoryFrameButton:SetIcon ([[Interface\BUTTONS\JumpUpArrow]], 14, 12, "overlay", {0, 1, 1, 0}, {1, .5, 1}, 2, 1, 0)
	
		showMainFrameButton:SetBackdropBorderColor (1, 1, 0)
		frame.ShowingPanel = 1	
	
	AuraBank.CurrentBoss = DEFAULT_SELECTED_BOSS
	
	local onClickInstallButton = function (self)
		local auraIndex = self.Aura
		local aura = AuraBank.Bank [AuraBank.CurrentBoss] [auraIndex]
		
		--install the aura
		local exportedString = aura.code
		if (WeakAuras) then
			WeakAuras.ImportString (exportedString)
			local auraName = ItemRefTooltipTextLeft1:GetText()
			tinsert (AuraBank.db.installed_history, {aura.name, UnitName ("player"), time(), auraName})
			
			WeakAurasTooltipImportButton:HookScript ("OnClick", function()
				C_Timer.After (3, AuraBankAurasFrameInstallScroll.UpdateScroll)
			end)
		else
			AuraBank:Msg ("WeakAuras not installed or enabled.")
		end
	end
	
	if (WeakAuras) then
		hooksecurefunc (WeakAuras, "Delete", function()
			C_Timer.After (.1, AuraBankAurasFrameInstallScroll.UpdateScroll)
		end)
	end
	
	local onClickGroupButton = function (self)
		local auraIndex = self.Aura
		local aura = AuraBank.Bank [AuraBank.CurrentBoss] [auraIndex]
		
		local waName = aura.wa_name
		if (waName and WeakAuras) then
			if (not WeakAuras.OptionsFrame) then
				WeakAuras.OpenOptions()
			else
				if (not WeakAuras.OptionsFrame():IsShown()) then
					WeakAuras.OpenOptions()
				end
			end
			AuraBank.PutOnGroup (waName)
		end
	end
	
	--dropdown - boss selection (top right corner)
	local select_boss_func = function (_, _, encounterID)
		AuraBank.CurrentBoss = encounterID
		FauxScrollFrame_SetOffset (AuraBankAurasFrameInstallScroll, 0)
		AuraBankAurasFrameInstallScroll:UpdateScroll()
	end
	local auras_fill_func = function()
		--boss list
		local raidList = {}
		for _, raidTier in ipairs (RAID_TIERS) do
			DF.EncounterJournal.EJ_SelectInstance (raidTier)
			local raidName = DF.EncounterJournal.EJ_GetInstanceInfo (raidTier)
			for i = 1, 20 do
				local bossName, description, encounterID, rootSectionID, link = DF.EncounterJournal.EJ_GetEncounterInfoByIndex (i, raidTier)
				if (bossName) then
					--print (bossName, encounterID)
					tinsert (raidList, {value = encounterID, label = bossName, onclick = select_boss_func})
				end
			end
		end
		return raidList
	end
	local dropdown_bossSelection = RA:CreateDropDown (aurasFrame, auras_fill_func, AuraBank.CurrentBoss, 160, 20, "dropdown_bossSelection", _, AuraBank:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"))
	dropdown_bossSelection:SetPoint ("topleft", aurasFrame, "topleft", 600, 35)
	local label_bossSelection = RA:CreateLabel  (aurasFrame, "Select Encounter:", AuraBank:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
	label_bossSelection:SetPoint ("right", dropdown_bossSelection, "left", -2, 0)
	
	local backdropColor = {.3, .3, .3, .3}
	local backdropColorOnEnter = {.6, .6, .6, .6}	
	local backdropColorHaveAura = {.3, .9, .3, .3}
	local backdropColorOnEnterHaveAura = {.6, .9, .6, .6}
	
	--install auras scroll
	local updateAuraList = function (self)
		self = self or AuraBankAurasFrameInstallScroll
		local auras = AuraBank.Bank [AuraBank.CurrentBoss]
		
		FauxScrollFrame_Update (self, #auras, 10, 40)
		local offset = FauxScrollFrame_GetOffset (self)

		for i = 1, 10 do
			local index = i + offset
			local f = self.Frames [i]
			local data = auras [index]
			
			if (data) then
				f.InstallButton.Aura = index
				f.GroupButton.Aura = index
				f.AuraIcon:SetTexture ("Interface\\ICONS\\" .. data.icon)
				f.AuraName:SetText (data.name)
				f.Desc:SetText (data.desc)
				f.Author:SetText (data.author)
				f.spellid = data.spellid
				if (WeakAuras and WeakAuras.GetData (data.wa_name)) then
					f:SetBackdropColor (unpack (backdropColorHaveAura))
					f.HaveAura = true
				else
					f:SetBackdropColor (unpack (backdropColor))
					f.HaveAura = nil
				end
				f:Show()
				self:Show()
			else
				f.spellid = nil
				f:Hide()
			end
		end
	end
	
	local auraScroll = CreateFrame ("scrollframe", "AuraBankAurasFrameInstallScroll", frame, "FauxScrollFrameTemplate")
	auraScroll:SetPoint ("topleft", aurasFrame, "topleft", 0, -11)
	auraScroll:SetSize (759, 409)
	auraScroll.Frames = {}

	auraScroll:SetScript ("OnVerticalScroll", function (self, offset) 
		FauxScrollFrame_OnVerticalScroll (self, offset, 20, updateAuraList)
	end)
	auraScroll.UpdateScroll = updateAuraList

	local on_enter = function (self)
		if (self.IsInstallButton) then
			if (self:GetParent().HaveAura) then
				self:GetParent():SetBackdropColor (unpack (backdropColorOnEnterHaveAura))
			else
				self:GetParent():SetBackdropColor (unpack (backdropColorOnEnter))
			end
			GameTooltip:SetOwner (self, "ANCHOR_CURSOR")
			GameTooltip:AddLine ("Import Aura")
			GameTooltip:AddLine ("A WeakAuras dialog will open after press this button")
			GameTooltip:Show()
		elseif (self.IsGroupButton) then
			if (self:GetParent().HaveAura) then
				self:GetParent():SetBackdropColor (unpack (backdropColorOnEnterHaveAura))
			else
				self:GetParent():SetBackdropColor (unpack (backdropColorOnEnter))
			end
			self:GetParent():SetBackdropColor (unpack (backdropColorOnEnter))
			GameTooltip:SetOwner (self, "ANCHOR_CURSOR")
			GameTooltip:AddLine ("Group Aura")
			GameTooltip:AddLine ("Place this aura inside a dynamic group on WeakAuras.")
			GameTooltip:AddLine ("This avoid auras being overlapped by each other.")
			GameTooltip:AddLine (" ")
			GameTooltip:AddLine ("Always group the aura if you won't group it manually.")
			GameTooltip:Show()
		else
			if (self.HaveAura) then
				self:SetBackdropColor (unpack (backdropColorOnEnterHaveAura))
			else
				self:SetBackdropColor (unpack (backdropColorOnEnter))
			end
			if (self.spellid) then
				GameTooltip:SetOwner (self, "ANCHOR_TOPRIGHT")
				GameTooltip:SetSpellByID (self.spellid)
				GameTooltip:Show()
			end
		end
	end
	local on_leave = function (self)
		GameTooltip:Hide()
		if (not self.IsInstallButton and not self.IsGroupButton) then
			if (self.HaveAura) then
				self:SetBackdropColor (unpack (backdropColorHaveAura))
			else
				self:SetBackdropColor (unpack (backdropColor))
			end
		end
	end
	
	local font = "GameFontHighlightSmall"
	
	for i = 1, 10 do
		local f = CreateFrame ("frame", "AuraBankAurasFrameInstallScroll_" .. i, auraScroll)
		f:SetSize (759, 39)
		f:SetPoint ("topleft", auraScroll, "topleft", 0, -(i-1)*40)
		f:SetBackdrop ({bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tileSize = 64, tile = true})
		f:SetBackdropColor (unpack (backdropColor))
		f:SetScript ("OnEnter", on_enter)
		f:SetScript ("OnLeave", on_leave)
		tinsert (auraScroll.Frames, f)
		
		local f1 = CreateFrame ("frame", nil, f)
		local f2 = CreateFrame ("frame", nil, f)
		local f3 = CreateFrame ("frame", nil, f)
		local f4 = CreateFrame ("frame", nil, f)
		local f5 = CreateFrame ("frame", nil, f)
		local f6 = CreateFrame ("frame", nil, f)
		
		f1:SetPoint ("left", f, "left", -1, 0)
		f2:SetPoint ("left", f1, "right", 0, 0)
		f3:SetPoint ("left", f2, "right", 0, 0)
		f4:SetPoint ("left", f3, "right", 0, 0)
		f5:SetPoint ("left", f4, "right", 0, 0)
		f6:SetPoint ("left", f5, "right", 0, 0)
		
		f1:SetSize (34, 32)
		f2:SetSize (34, 32)
		f3:SetSize (34, 32)
		f4:SetSize (113, 32)
		f5:SetSize (470, 32)
		f6:SetSize (89, 32)
		
		f.InstallButton = CreateFrame ("Button", f:GetName() .. "InstallButton", f1)
		f.GroupButton = CreateFrame ("Button", f:GetName() .. "GroupButton", f2)
		f.AuraIcon = f3:CreateTexture (nil, "artwork")
		f.AuraName = f4:CreateFontString (nil, "artwork", font)
		f.Desc = f5:CreateFontString (nil, "artwork", font)
		f.Author = f6:CreateFontString (nil, "artwork", font)
		
		f.InstallButton:SetPoint ("center", f1, "center")
		f.GroupButton:SetPoint ("center", f2, "center")
		f.AuraIcon:SetPoint ("center", f3, "center")
		f.AuraName:SetPoint ("left", f4, "left")
		f.Desc:SetPoint ("left", f5, "left")
		f.Author:SetPoint ("left", f6, "left")
		
		f.InstallButton:SetScript ("OnClick", onClickInstallButton)
		f.InstallButton:SetNormalTexture ([[Interface\BUTTONS\UI-MicroStream-Green]])
		f.InstallButton:SetHighlightTexture ([[Interface\BUTTONS\UI-MicroStream-Green]])
		f.InstallButton:SetSize (32, 32)
		f.InstallButton:SetScript ("OnEnter", on_enter)
		f.InstallButton:SetScript ("OnLeave", on_leave)
		f.InstallButton.IsInstallButton = true
		
		f.GroupButton:SetScript ("OnClick", onClickGroupButton)
		f.GroupButton:SetNormalTexture ("Interface\\GLUES\\CharacterCreate\\UI-RotationRight-Big-Up.blp")
		f.GroupButton:SetHighlightTexture ("Interface\\GLUES\\CharacterCreate\\UI-RotationRight-Big-Up.blp")
		f.GroupButton:SetSize (32, 32)
		f.GroupButton:SetScript ("OnEnter", on_enter)
		f.GroupButton:SetScript ("OnLeave", on_leave)
		f.GroupButton.IsGroupButton = true
		
		f.AuraIcon:SetSize (32, 32)
		f.AuraName:SetSize (100, 32)
		f.Desc:SetSize (470, 32)
		f.Desc:SetJustifyH ("left")
	end
	
	local header = CreateFrame ("frame", "AuraBankAurasHeader", frame)
	header:SetPoint ("bottomleft", auraScroll, "topleft")
	header:SetPoint ("bottomright", auraScroll, "topright")
	header:SetHeight (16)

	header.InstallButton = RA:CreateLabel  (header, "Install", AuraBank:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
	header.GroupButton = RA:CreateLabel  (header, "Group", AuraBank:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
	header.AuraIcon = RA:CreateLabel  (header, "Icon", AuraBank:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
	header.AuraName = RA:CreateLabel  (header, "Name", AuraBank:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
	header.Desc = RA:CreateLabel  (header, "Description", AuraBank:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
	header.Author = RA:CreateLabel  (header, "Author", AuraBank:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
	
	header.InstallButton:SetPoint ("left", header, "left", -1, 0)
	header.GroupButton:SetPoint ("left", header, "left", 33, 0)
	header.AuraIcon:SetPoint ("left", header, "left", 66, 0)
	header.AuraName:SetPoint ("left", header, "left", 105, 0)
	header.Desc:SetPoint ("left", header, "left", 220, 0)
	header.Author:SetPoint ("left", header, "left", 680, 0)
	
--------------------------------------------------------------------------------------------------------------------------------------------------------
--> history panel

	local latest_search = ""
	local fill_search_box = function()
		WeakAurasFilterInput:SetText (latest_search)
	end

	--> installed auras scrollbar
	local uninstall_func = function (self, button, auraName)
		if (not _G.WeakAuras) then
			return AuraBank:Msg ("WeakAuras not found. AddOn is disabled?")
		end
		if (not WeakAuras.IsOptionsOpen) then
			return AuraBank:Msg ("WeakAuras options not found. WeakAuras options is disabled?")
		end
		
		if (WeakAuras.IsOptionsOpen()) then
			latest_search = auraName
			WeakAurasFilterInput:SetText (auraName)
			C_Timer.After (.2, fill_search_box)
		else
			latest_search = auraName
			WeakAuras.OpenOptions (auraName)
			C_Timer.After (.2, fill_search_box)
		end
	end		
	
	local updateHistoryList = function (self)
		self = self or AuraBankerHistoryFrameHistoryScroll
		local auras = AuraBank.db.installed_history
		if (not auras) then
			return
		end
		
		--> clean up auras
		for i = #auras, 1, -1 do
			local auraName = auras [i][4]
			if (not AuraBank:GetWeakAuraTable (auraName)) then
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
				button.waName:SetText (data [4])
				button.uninstallButton:SetClickFunction (uninstall_func, data [4])
				button:Show()
			else
				button:Hide()
			end
		end
	end
	
	local historyScroll = CreateFrame ("scrollframe", "AuraBankHistoryFrameHistoryScroll", AuraBankerHistoryFrame, "FauxScrollFrameTemplate")
	historyScroll:SetPoint ("topleft", historyFrame, "topleft", 0, 0)
	historyScroll:SetSize (759, 420)
	
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
	
	for i = 1, 20 do
		local f = CreateFrame ("frame", "AuraBankerHistoryFrameHistoryScroll_Button" .. i, historyScroll)
		f:SetPoint ("topleft", historyScroll, "topleft", 2, -(i-1)*19)
		f:SetSize (759, 18)
		f:SetBackdrop (backdrop)
		f:SetBackdropColor (unpack (backdropColor))
		
		local uninstallButton = AuraBank:CreateButton (f, uninstall_func, 12, 18)
		uninstallButton:SetIcon ([[Interface\Glues\LOGIN\Glues-CheckBox-Check]])
		
		local auraName = f:CreateFontString (nil, "overlay", "GameFontNormal")
		local auraFrom = f:CreateFontString (nil, "overlay", "GameFontNormal")
		local auraDate = f:CreateFontString (nil, "overlay", "GameFontNormal")
		local waName = f:CreateFontString (nil, "overlay", "GameFontNormal")
		
		AuraBank:SetFontSize (auraName, 10)
		AuraBank:SetFontColor (auraName, "white")
		AuraBank:SetFontSize (auraFrom, 10)
		AuraBank:SetFontColor (auraFrom, "white")
		AuraBank:SetFontSize (auraDate, 10)
		AuraBank:SetFontColor (auraDate, "white")
		AuraBank:SetFontSize (waName, 10)
		AuraBank:SetFontColor (waName, "white")

		uninstallButton:SetPoint ("left", f, "left", 2, 0)
		auraName:SetPoint ("left", f, "left", 26, 0)
		auraFrom:SetPoint ("left", f, "left", 190, 0)
		auraDate:SetPoint ("left", f, "left", 360, 0)
		waName:SetPoint ("left", f, "left", 490, 0)
		
		f.auraName = auraName
		f.auraFrom = auraFrom
		f.auraDate = auraDate
		f.waName = waName
		f.uninstallButton = uninstallButton
		tinsert (historyScroll.Frames, f)
	end	

--------------------------------------------------------------------------------------------------------------------------------------------------------
--> on start
	
	--update the aura scroll at start
	AuraBankAurasFrameInstallScroll:UpdateScroll()
	--show the auras panel at start
	AuraBank.ShowAurasPanel()
end
 
local install_status = RA:InstallPlugin ("Aura Bank", "RAAuraBank", AuraBank, default_config)

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function AuraBank.InstallAura (auraName, playerName, auraTable, time)

	local installState = AuraBank:InstallWeakAura (auraTable)
	if (installState == 1) then
		--> check if there is a group for our auras
		if (not WeakAurasSaved.displays ["Raid Assist Imported"]) then
			local group = RA.table.copy ({}, group_prototype)
			WeakAuras.Add (group)
		end
		
		--WeakAuras.FixGroupChildrenOrder()
	
		tinsert (AuraBank.db.installed_history, {auraName, playerName, time})
	end
end

AuraBank.Bank = {
	--hellfire citadel - encounterID from encounter journal
	[1426] = { --hellfire assault
		--numeric table
		{
			name = "Metamorphosis Announcer",
			wa_name = "Metamorphosis Cast",
			icon = "Spell_Shadow_Metamorphosis",
			desc = "Shows a warning when a Felcaster starts to cast Metamorphosis.",
			code = [[dWJ3daGEkr1UOuSnLkZKsQMRqA2I61ukDtO0Hv13ubptiStbSxYUrSFkj9tLQgMk0VHCEHYqPeQbtjXWHQdrjWPr6yc6CkPSqLILsjKfRewUKEiLkpfSmb65kMiLiMQetwKPJ6IuIYvPKYLP66szJkj9xOyZu02Pu10ujFLsK(Sk13vIAKuc6GkPA0QOXle1jfQULsIRPe5EcrEmfgNsPBlvRqve0fKeKurGjIWa1YDfi8sqIo45pgWVHTJaSo)Duf)en0Xcee59MMJZA1v2DC3UWicgXsHRDyPRGxYCLRlbX2BAooRvperexbxB3UJBpEDi84Lmx5Ajbv)MIiLy4UaQbIi4nykImQiy4VYQiiHWmOgjPncguJKeeNWE18n8ORNs7jtul1FBxVv)jkwpr)OaQrst0n5FyBq33cguJKWyC(eINfG9h2RIfly43W2XoeHFkP7ewWERvG4wILj4Bmsle8eA)zkIOIGH)kRIa8Qpol4UIwwSG(tjQiaV6JZcWB5XflwaxP33EvfbjFrZ00U8pJG(Ftnem4EohpjiCB4A72ki1QptrebxciF3hvuGqbIfK8fntZsmCxGfUUfHDvRzDbCmCxGBVtybnIBVtybmT7jbdUNZb(UlaRZFhvXprdDe427ewGDO(INTQvSo6wqBCmdUNZXtAJaY3DbyD(7Ok(jAOJaY3DmiCV(mQkisrsqBCmdUNZb(URfcmAdJ6yoPjxat7EsGzlNhJNOfIfSmnXNkqyWTciTEPsVV96OaHcg(nSDSyeLWc2SVu2JvWPtVpzfim4wbj6GN)yXnqebXjSxnFdpACdezIc4EoJbo)eAzmyD(7Ok(jAOJGm6tQiG)Styve0BzMQIyXcCIbQryVstccpCyRG24yCIbQryVstAJGe10KA0YCmve0BzMQIyXcQOSRIGElZuvelwG5BWuerfb9wMPQiwSG24ymq9fpRncQVHRIGElZuvelwSaAsawN)oQIFIg6yvRy3pSybJGG2eAZrBcEqG9kq4vWqXs]],
			author = "Built-in Aura",
			spellid = 181968,
			group = true,
		},
		{
			name = "Howling Axe",
			wa_name = "HellfireAssault - Howling Axe",
			icon = "ability_arakkoa_spinning_blade",
			desc = "Tell when the player is target of the Howling Axe.",
			code = [[dOZWeaGEjs7sKyBKGzkskZLKA2O6MkOUnP6Wa7KKSxQDR0(ff)KeAyiu)g0FrXqfjvdwuz4s4GiKVPsCmf6CsuTqvslvuLwmPy5s5HIQQNcTmrQNJ0efjXuv0KL00jUOOQCvjkxw46s1gvPSvrsAZO02fvXNfXPv10eL(ocmse04uPA0kW4LiojIClfKRrICEe1Zir9yv8AsP9ONgFJKwjASGtOM0bUu1anp)fYmGgqRwiGHw87(BcJgoOggPgtNYykeNs6lg1nwnw90iyFDG8W1tJub0epnkKlcJfTGgIXIwqdXysdsGfJ6GF90yrlOHySOZPHfJS)(0bEASOf0qms5Fn4bRyXIrP9jjrZtJubC0Y8ll04b2xX4c0dMFzHgb9gW4c0dQNw1OrcHeW)njtoIkjSySgA6SStYfHrcjkVdFRSuZyNgm0IGZjv9vJ0IGZjvPEAvJw149SkRq5wm2PbtFFXxnE6ubQZm4RHr51JQfJSWvmMpEEkJuMC3GRyCq8jdeRAm9DJCiO6PrbWJv80OENlVNwSym2dSVs0(QXXlxUBSboHNg17C590IfJDAWe7b2xjAF1xnwFw2)05czpnQ35Y7PflgBqE4Pr9oxEpTyXil4ipC90OENlVNwSyStdMsHByng70G5a11aeF1yPWnmsyW5SFlYKl)VaQb3Irw4k4xAyvPZAS(0coGmkGJwQX823m5iIaazJTi5H7KCry8pW1yjkYYsdX3gkB5Pv6(y20kxE5PjEu5lMDOSzn(7lmhOEbpKOAvJgpqiVcjy9vJubC0sZpCfWV6XkgvSSjskvYNXsHqDRI4uu2iOlqRX4xnsyW5SFliIsbDUKj3qzYriKa(VjzYrujHrqT(YdxaNrAFss0OEAXibFvgyvJPVBC76Z2NKenQvnAKSISS0q8TlkOSsxusbIv4Is3vG4S3n7qzvYi4ipCPEAKkGM4PXkKHc7B1xnsH9TAmtUtNkqDJuyFRmfazGre23Q6ZaqdCKOPgpWEljuJhyVLePk8a43cDapux2wdq9wOd4XnEeepMcmjXif23kZzay3GBCyavIMflgRpTGdit6axJKwjASGtOM0bUu1anp)fYmGgqRwiGHw87(BcJgoOggPc4OLM6WFfJxvCovCylgbEAKqib8FtYKJOscJKwjASGtOM0bUu1anp)fYmGgqRwiGHw87(BcJgoOgwmMhRAmB6rl2a]],
			author = "Built-in Aura",
			spellid = 184369,
			group = true,
		},
	},
	[1425] = {--Iron Reaver
		{
			name = "Artillery",
			wa_name = "Iron Reaver - Artillery",
			icon = "spell_fire_ragnaros_lavaboltgreen",
			desc = "When the player is a target of Artillery.",
			code = [[dSZ9eaGEjQ2fPKTjLyMKIYCfvMnHBsk1Hb9nrOLbWofP2l1Uv1(Lk9tsH)sQgNezyIGHskQgSuvdxchuPY5bYXeLZPuyHkvTusrwSuLLJ4Hsu6PqpwrpNKjQu0uvYKvy6OUOOQ6QsP6YcxxsBuKSvrvXMjQTlv0Pr6ZsX0uk9DPcJukPNbugTiA8IQsNeq3skLRjQY9KO42e51av)wLDMxgPgb(CqKHZihW59QC76rfugKER1NdIU2qc4Xi1r2mGCsJkJa0ktRe0cqIgLmomo8Yi8PsqMEVxgvmKWEzKbvegliHkyJfKqfSXgY1HzJsq67LXcsOc2yrvOcZgLPpvL0lJfKqfSrLGocriZMnBKj0MMG4LrfdNGRtF5Z48QpBuvecbWHXSszjMhyghrVQS8curyS1DAs7uTRzgBixTqFE1N1Oiiq(igltzm(qPq5LtNzChHPcrqaz2OQiecGdLxoDMtNvcaGsjy2yvf6QIqiao8EJpukmMkeD7V)K6z8HsHo9LpJWkbASHC1c95vF2yMXzvXNKEs6imYuPyy2O89SX8l6SDGD7N6E2yYG2KKD6maLmko4WlJLFFyS1qiKPKOB)Ysz4iegJFE1NdcDymlXs5zKaNHxgLQcM6LzZgRQqp(5vFoi0H3BCqLLPZQGb5LrPQGPEz2SXQk0l)(W9mkdNm9EVmkvfm1lZMnsor4LrPQGPEz2SXQk0NNupi79gzOiE2lJsvbt9YSzZgLVNrA5HtdyRXbvviGGqgobxzut1VB)DDabzKen07xGkcJ059gZxnKLvb7uTLxPnadSsjKy2waT0slGLz522U1i9PS(8KkebhdNoZOIHtWvA(rF24Enwln02OIHtWvL9EgsFP4zJA0(cbUz(nw(DsoDcAbMryLp3ZiDyei5(U91ua7miD73w3(7imvicciJWXGY07HcDMqBAcIYlZg7Go4KoDgGsg)Q0IqBAcIYPZmcsdzzvWovlLYaaydajcipW2ciBJnSCBBZZiCY07vEzuXqc7LXXPRU6p8EJQR(dJD7pRk(KmQU6p0lGCsJ4v)rUzsibo5GKdNxL0e5W5vjnr(CtOivibfrU2)rahPcjOisjIiHmTUMgJQR(d9zs4)HWO2qfheZMnoOQcbeeW59gb(CqKHZihW59QCQIqi0LPKqNaBEi5u6cyNWENGBir8gN3jgxhV3B2i0lJ7imvicciJaFoiYWzKd48EvUD9OckdsV16ZbrxBib8yK6iBgqoPzJD60zBbKz2g]],
			author = "Built-in Aura",
			spellid = 182280,
			group = true,
		},
		{
			name = "Immolation",
			wa_name = "Iron Reaver - Immolation",
			icon = "Spell_Fire_FelImmolation",
			desc = "Shows when the player has Immolation debuff, tells the amount of stacks.",
			code = [[dKdZdaGEQQYUuPABOqmtuOmxkvZMIBQc6BQe7eK2lz3kTFkf)uqnmvOFR42IAOOq1GPKA4I0bPK0JvLJHsNtkSqbzPusSyvGLlvpKsONcTmq8CQmrQQmvHMSQA6ixefsxLsKll56GAJOOdJQnlW2Pe8muWPb(Su67srnskrnnQkJwLY4PQQojv5wukDnvKZRs6VIyCQOETuKfRIcbc9wQ6b8xz37nRZoMwgtctqVsywgVCEmCcmRqNqi3zVF8oKlcZc)c)kk0)HdcCfjM2E64zFSm0GryBWWjiNoFsb26ZNq(JaZ6uuOJ4DsrH)jXnW7xHe6g49l0gRFWoAYcDd8(ts50nH4aVF7(foSFw1p7wMVTGTn0SLlj0SLfn8TPJmCFABf6g49N8UX3TmcpK7OQlsKqQdABRUIc)1bWbbXRPLqlBvRCitlXycDPLX49DkkOSck7zihV4tKWLNlNIckRqVCEmCcmRircVvG2BKGYc5SqZW)kkK4MAjffMHneqrrIew7BGxQ6GVq2lNpje2vj1(g4LQo4Rqc)GGaWd2qxvuyg2qaffjsyN)kffMHneqrrIegWFeywffMHneqrrIec7QK3KpGtkKW(ykffMHneqrrIejmywcb(Reui(e2RwWSXRPLqWBwH8fK5eywff6iENuuiDnTeM2lxrct7LRiHT9PzrcZCWQOW0E5ksykSXvIejeSak5n5utr1xqzf6i(RjhJpGLegkCmg(qH8)hqGz5MeQdABRUtrrcDe)1KZIZsCWMRLeg2sr0ZpgvO)MjlOhVZGqomn6aHGVqV(S2yTvkUfQUnwBRnw7LZJHtGzf2m4t3euwiNfUW5yh02wDNGYk8A4GaxrI5fww2lm0OrdixocPrdFkWwFNe(bUud)Q3BwHElv9a(RS79M1zhtlJjHjOxjmlJxopgobMv4BgZFAEvirc5kk0lNhdNaZk0BPQhWFLDV3So7yAzmjmb9kHzz8Y5XWjWSIeAbbL1hewrsa]],
			author = "Built-in Aura",
			spellid = 182074,
			group = true,
		},
	}, 
	[1392] = {}, --Kormrok
	[1432] = { --Hellfire High Council
		{
			name = "Mark of the Necromancer",
			wa_name = "High Council - Mark of the Necromancer",
			icon = "ability_bossfelorcs_necromancer_red",
			desc = "Shows an icon when the player is affected by the Mark of the Necromancer debuff.",
			code = [[dKZzeaGEksTlkITPqMjfjMRez2k6Mku3gs7uvSxXUvz)sYpvqdJs8BL(Me0qPiPblPgUuCqvf8yuDmvPZjHAHkWsrIYIrklh0drI8uILHKEoIjkHmvPAYqmDsxejQUQeOlt11bSrvfDyO2mqBxc4ZsPtJY0OK(UQsnsvL8mvvnAk04vvOtsrDlKW1uv58ivVwIACuWFPuN30JWIy(uhcI5EjZ89iLW0ytMs3M2siG(CHCI95C4IIpUdTBaGntpcjcvtEnXIjulKIIPOD0iqR)P6rqJGebj9i0hccsCnFAyK1r)lSyl)Os1Ivl)PgqkS(lc(yOyLTx6rikgQPhrP34rAGoX1inqN4AKw4(D0iOy2LEKgOtCnsdWK4rJgrHS2whMEesJpNMriPNN388AW6OchfnYHrDs655nYymSCv9cwvRg9Q6hNdxu8XDy0iionaqWo9gpYxFGYg)zbnLOrm6SwJAEEPAiYCXiPhbG42NxahgAru80pn9iOatLLE0Or8JVaN6qgsK3cl2qeaIB7hFbo1HmKmiccdeKXbMk90JGcmvw6rJgbUtp9iOatLLE0OrGyUNEeuGPYspA0iGyUY2l9iOatLLE0OraiUnFrPH1miAeW9uHzAppuTgbHrAMy6II5LjrgJHLRQxWQA1Oxv)4C4IIpUdJa9w2ED6nEegFViSJP28fTz6QJKN3i8DNi73xgebZv2EK0JqumutpczboeBUr8D(mYymrDyeYcCi2ny1yezboKsfnCyrFOOsFHVw21oypNypypNst8v2YFt222iKf4qIuvZbi6IgbzTjlWHKbrJgHOyEzcL2tXSd1pnYWc2fZfr5rm9UO5XIj)JGb0n0IWqI8fR1yvnLwGJZMv1uuvpgdlxvVGv1QrVQ(X5WffFChgbJGWu2E4PTczTToKKE0iFZquJ55LQHiFCiiiX18jf)m8ZWBX)my53FlJmyWsaPWQ1ihaAhYABDijpVrqyKMjMUz(ErmFQdbXCVKz(EKsyASjtPBtBjeqFUqoX(CoCrXh3H2qhjcrX8YetDzNgzWWEF44OrWPhzmgwUQEbRQvJEv9JZHlk(4omI5tDiiM7LmZ3JuctJnzkDBAlHa6ZfYj2NZHlk(4o0Uba2m9OrkqEETs9nAc]],
			author = "Built-in Aura",
			spellid = 184676,
			group = true,
		},
	},
	[1396] = { --Kilrogg Deadeye
		{
			name = "Heart Seeker",
			wa_name = "Kilrogg Deadeye - Heart Seeker",
			icon = "inv_ragnaros_heart",
			desc = "Shows an icon when the player has the Heart Seeker debuff.",
			code = [[dStfeaGEHKEjij7cuzBGeZePknxKy2Q4MkqFtH62c1ors7LA3QA)IWpbfdtb9Bexg1qLuPblkgUI6GivLhlLJjQohO0crQSuKQQflKA5apuirpfAzKupNutusftvIjlvtN4IcjCvjv9mrPRRsBurSvqsTzrA7GuJdeNwWNjX3vaJeu10qkJMKmEKQ4KcXTuKUMc58IOxlP8xj5WkTZDXyWyKxyq62ykrAKxtj8qxbwLFbeDLkEbIrTr1WLd3q4upEkStvGcusPLvnBm2y3y3fJBtcKx7IrTSaXfJDsLMC)UPZOMC)UXezAxTqInQj3VxnVIkJi5(DknvlyBcdOGnYfOWuWg5cuyOM02ZeoEpmL6)oV9jC8E4jhMhMdhrrXOMC)Evt1(pFmo4QfgyXIrbeuuyGlg7C0300sYz2i80h9p4K6PxJ6z(CI01UyQ5MAoKHzHaRfJ)gZAxm1CJWZlqsKbzUgdSyXOkoOOsm1C1qmEiB3fJxnx9m0mWrBu2d)IlgJVhj4Iflg5VrUVWGq3y(yiqX4vZv83i3xyqOB6m2dPPH29ijDXy89ibxSyXiyBSlgJVhj4IflgbKd7IX47rcUyXIX0TjbY7IX47rcUyXIXRMRAK4OxX0zXyk5fmev2uvtZypONpBsu2wnTr45fijYGmxJbgbSsG8LKZSXqJ8gPhyst1S4jthrdcKXJGfcSqYoMwonAoDknAgdFqQAK45dlC3uZnQLTvtxxs4fJ0btPaZGg3EpibYVNkbeuuyG2flg1Y2QPJsYlB4J5xmct9fmsDIcJrLqIn1HWL14EfIJ2yOBeQcharrjrM6WBNtYjYmnrg45fijYGmxJbgtctAQMfpz8iyHKnBoKXdhosD2rQD6uAJmoqOlQm1C1qm(34ciOOWaTPMBC)q8kbY7IrTSaXfJsYz24mG1SyCgWAwmQaidyXy8gExmodynlgNVhnBXIXEqpF2KrAK3yKxyq62ykrAKxtj8qxbwLFbeDLkEbIXgHC6KbEtNfJRlgHNxGKidYCngymYlmiDBmLinYRPeEORaRYVaIUsfVaXIrOn1CAQZTyd]],
			author = "Built-in Aura",
			spellid = 180389,
			group = true,
		},
	}, 
	[1372] = {--Gorefiend
		{
			name = "Hunger for Life",
			wa_name = "Gorefiend - Hunger for Life (fixate)",
			icon = "ability_fixated_state_purple",
			desc = "Alerts when an add is fixated on the player.",
			code = [[d0toeaGErjTlrvBduP(MsuZuuXCjQMTehg4Mkr(lPCBcDEqStLQ9sTBi7hK(jbmmLs)wLNjkyOIsmyqz4e5GIs5uGk5yk4CKQOfsGwQOuTysLLtYdvc8uKLrqphQjsQkMQunzPmDuxujORkkYLfUUiBKuL8zfAZsA7KQuFKuf(kPQAAkH(UOsJujzCkfJwj14bvDsIYTef1Pv19ef6XkAuKQsVguXEWDtVjziouvWmKlBEiSCGUV8meT6dpGJMgMbCOjLusLWe2KW8d53Mx4YMen1m1C3e8cuR4G9EMfQNWD(ncnbrGAfhS3fUvy(TlBcm5)qy3nHzGID3u70Wxc1SGMWxc1mbf2mH5t0e(sOMMeGxBIUeQjFQcaNuH8v310)vQYxDxt)xP2vaeUEkXSuaqc12H834Oj8LqnT5AacfftlbWCOmB2eR(XXq5UPwOlvRlOaWytIGXFAQf6s1AhIuyAv2Y(s6vMYXecigy39(GPvj0yOGcREkOWY5RHztjCOHLIsrwZ6mHLIsrwd7U3h8(WMTdlUXSPAQuWtaY6mHaIH2jfkaFktzmJMMjmFIAR)wyIFXOz2064hxZEFq4gtLd0C3edkbID3KyQWV7MnBkqZlH4q9ntdlVjdMs4qlqZlH4q9nlOP2xR)mvyiUBsmv43DZMnPUs4UjXuHF3nB2ufm5)qUBsmv43DZMnLWH28e1bylOjfygUBsmv43DZMnBQEiM(SgEx4IMApwQaGqmychSPSNqqHLTCbqmPIX)qDisHPFEitp6zT5jkvcoAEFWeMbt4GZY9i2KGc07cSKjmdMWbVGdXGhjgi2KazQtY0NfAkR3j69T5ZGjqIpRZ03mPhNkQFGAqHLzOWwLqJHckS6PGclNVgqHPV1hEahWLja6fb8Fi3nHzGID3KKkWbBAuD5AIHifMKuboyZMebpYDtsQahSjPubhMnBk3VXR9(GWnMqjXU6hhdf27dMApwQaGiBEitYqCOQGzix28qy5aDF5ziA1hEahnnmd4qtkPKkHP5DL2LlYcA2eWDtRsOXqbfw9uqHLZxdtYqCOQGzix28qy5aDF5ziA1hEahnnmd4qtkPKkHzt6T3hwu4GzB]],
			author = "Built-in Aura",
			spellid = 180148,
			group = true,
		},
		{
			name = "Touch of Doom",
			wa_name = "Gorefiend - Touch of Doom (debuff)",
			icon = "ability_bossgorefiend_touchofdoom",
			desc = "Shows a warning when the player has the Touch of Doom debuff.",
			code = [[d4tHeaGEfGdJYUaITPa6Vk0mfsXCrvMTs(MQk3uvjNhv1TvPtdANa1EP2nu7hq)einmf0Vj9muPgQqLAWamCv4GcP0PeQshtuDovfwiQKLkuvwSQ0Yv0dvG6PiltO8CituizQsAYImDIlkurxvvPUSuxxInIkSvHu1MvQTlufFuOQ6ZIY0uv13vv0ifQWJfmAv04fQKtke3svuxdv09uGmovHxRkYOesLDURMGMIGLEUzHMxKGIr8yVWfu4p(QiuMo7nSXPrrlHtDNu9Aczkgi5GmeKy)mDnLmLC1eddVmbQyxnHe2uC10XSrTykBQFAs4F0MoMnQflMUmi2vthZg1IPJYc1wSysMWSSE6QPu)w27k)J2uCeTX3xC8D0yAxwluGH9RPcQhrh9Afj5xtOJETIKqUAW5gC(Jy5)gAXuQFl79GxmeY0LLbdMWSBJC1GZnv1s4eiaDdequQETycZU9OE0tMOttdAqMcfKO3XtyQnjWBNSy6SHzNIbNh7HPLYsUAsyRglUA6wwc0vlwm14GwWspHjt5)EWTPcQhBCqlyPNWK5YucU3Wqzj8D10TSeORwSyAQR2vt3YsGUAXIPnliqf7QPBzjqxTyXub1Jb9(YeZLPjl0UA6wwc0vlwSyARyHGdOn4y)nLGOJfJpjSWtitvTeobcq3abeLQxtZodQ4k)J2emOytXfO7nQfZXZCYj3p4(x(WbY5aZhg7)hE)8))MGyOmg07XQLozW5Mqcl8ekUviwmXfO1kOFzILsqbQy2AuMWSSEIC1IjKWcpHgSIfgeFBSyc0VRuKOIttdq1RbpeeUnXkI6xt8bDVrTyWXg(biCM)B4JpE8N7FCAcMmf)6S3WgNac4zGaQAjCceGUbcikvVabeDP(TS3XRPpHj50GZJ9WeUCRtywwprgCUjwqGkg5QjKWMIRMs6isl4K5Yesl4KjGacfKOxtiTGtJhm50ePfCIx4KnzbPN8OGwMznpkOLzwh9AGT4OVSvZ7BCQzjo6lB1CS6EyoiAwMjKwWPXWjdJ7LPVyiPNwSykbrhlg)ibfBkcw65MfAErckgXJ9cxqH)4RIqz6S3WgNgfTeo1Ds1RPGQRK(j2CzXeZvtvTeobcq3abeLQxtrWsp3SqZlsqXiESx4ck8hFvektN9g240OOLWPUtQETykEm48)XYTyd]],
			author = "Built-in Aura",
			spellid = 182170,
			group = true,
		},
		{
			name = "Digest Timer",
			wa_name = "Gorefiend - Digest Timer (debuff)",
			icon = "Spell_Shadow_DeathCoil",
			desc = "Tells how much time the player may stay inside the stomach.",
			code = [[d0JceaGEQq2fizBur8neXmPc1CvunBbpwQUPKkhgPBdQZlj2ji2lz3uSFfPrrfWFPk)gQtdmuLQYGvQmCk1bPcQtPuvDmQQZrL0cPsSukrAXuPwUcper6PQwgL0ZHmrjPPk0KLy6OUiLO6Qur5YIUUs2ivu9mkHnJW2PcYhPc0NLIPjL8DfXiPeLXjPmALY4PeXjru3ssvxtk19OI0pbPgMIYRvQYYxrDGozdNdcApNtUJnO53odbVVrl4jEvtkVrkge0r6wHYhQzqzLeDy9IErrDANbydsrDethSI6i8Yu86BuJjd61rrCo0r4LP4zt5nDDeEzk6t31xigdRxWEi8YuKBXI1PgamLbyJI6iMoyf1Thjkz9MbEIoxXo1ThjkzX6WuGrrD7rIsw3EfqPyX68a00Kdf1nu40dBNdkJh6o1P69fIXWEBGsQZa4SOVqPhYodbYf5whzNHa5csrbXxq8R5B112I1nu4ePOG4Rxf0KiwSEjDViiinqriDyAdORtScbuNAKB9s6ErqeRyN6wMdBP15CN5yX6BjOzJfeFR10dyArrDMgsdROo8kWafflwFHsV00XldNdqrUOxaeeG(kWvuuhEfyGIIfRpO9urD4vGbkkwSEA64LHZbOO7tsnl0jODgGnkQdVcmqrXI1xO0RJHDtz5I(ahsf1HxbgOOyXI1jWg(ahLcI1w6faYoqRCM23dPhbW50Doojy9r2aWMyf7uh0XgDGbWEDmSDi5Sii(6DmouWtmYfDet77HifBykWaNgwhANfp5QwUUJWyybzguwOtxmwU1PLcGbydn4Xdqttoqkkwhu0Dq8ijaPPmDx9t3vf0KiE6Uiaoht35aL09IGy)6wc0eeOKLZRVDBlQzbj(ZCsBN4pZAlxfr9TAPpbu4nbX3AnDZcooann5aji(6vGMGaLSGyDMRq12NKz1CTwlliPTEbGSd0kK7yJozdNdcApNtUJnO53odbVVrl4jEvtkVrkge0rmTVhAFyGH1Db6ye66eRtvuVkOjrSozdNdcApNtUJnO53odbVVrl4jEvtkVrkgeeR7qcIFlR(ILa]],
			author = "Built-in Aura",
			spellid = 181295,
			group = true,
		},		
	}, 
	[1433] = {}, --Shadow-Lord Iskar
	[1427] = {--Socrethar the Eternal
		{
			name = "Volatile Fel Orb",
			wa_name = "Socrethar - Volatile Fel Orb (debuff)",
			icon = "achievement_zone_cataclysmgreen",
			desc = "Tells the player about the Fel Orb coming.",
			code = [[d0treaGEKs7srSncP8yHMjHKMlHA2coSQUjsHHPu6BksDELQDcI9sTBG9dQgfsr9xjACIQ6YKgQOugmOmCP0bfLQtjkOJjfNtuOfsiwQOKwms1Yf5HIk8uOLbsphXerkYuL0KLQPJ6IIcCvrrEgHexxHnkQ0wvkSzKSDjKpRO(QOettrY3fvzKkf9AjuJMGgpHuDscClrrDAIUNOI(PeCBL8Bv2nUAuAuaG1e1hvXcIhGi(JcLAr6sbCjThqlJp)XWoznNufyKye6KMjBNaDAJlJDJDxn(a56z5bC1iH)e7QX2Ksu24C6YZiV3QgBtkrzZgxVe4QX2Ksu2y7iquZMnYj58SMC1yxPpOOQ7TQXnZEwPrUzsunc(LsC1qAmUXfEwgu4WYvdWHvir3SXbrljTAiiOB6gjTAiiOtC1qAmKM83cfAJzJuJqGeFGPBe8lT8A10ZxYyoZPXUsFqrLJWtigx)SmAmoi8Tkfk7QrwU0UzJcv5Sq2qAGMVXW9DxnYFqbSRgxJalD1SzJkiEdaRjz3yZ0zCkJdIwQG4naSMKDlIXUKIsghbE3vJRrGLUA2SX0hvxnUgbw6QzZgP(ilpGRgxJalD1SzJdIwgVf9NTigtxqD14AeyPRMnB2i1byusRAiqNYyxsAd)oYFSyIXSoaWHL98(DJjDwEG6ERAugpGrjqYLXB1guw7gsJXpYYdqC1iH)e7QX(vsUbOBrmsUbOBeoS4GW3Yi5gGEz7ZcnI3a0fht6ZJKkEZ76z5cuI38UEwUavn9ac1Lwzl87AABZKBE2i5gGEzu4daAWinEcRjZMns4pwmjBNeWgfPqTwGggj8hlMKJdWVeSuaBSqMQOaAkdms7Dldz7erX4p4Z0nk7gXlMuw4NGdlZWHTXfEwgu4WYvdWHvirhomAUR0huuzOX8KDwOH0anFJIEbkkIYgsMHMrrBs(qncgRAsopRjIH0yCVaffrzdb6wOt2oTXUK0g(DbXdyuaG1e1hvXcIhGi(JcLAr6sbCjThqlJp)XWoznNufymExOF5bSiMn(UACJl8SmOWHLRgGdRqIUrbawtuFufliEaI4pkuQfPlfWL0EaTm(8hd7K1CsvGzJfzintbTXSn]],
			author = "Built-in Aura",
			spellid = 180221,
			group = true,
		},
		{
			name = "Gift of the Man'ari",
			wa_name = "Socrethar - Gift of the Man'ari (debuff)",
			icon = "Spell_Shadow_AntiMagicShell",
			desc = "A warning when the player get this powerful debuff.",
			code = [[d0JoeaGEQQYUKcBJQs6XsAMuvWCfkZMkhwv3Ks5Vc62uY9ea7ufTxYUHSFfzuuvKHHe9BOUSOHIufdwknCQYbrcNcPQCmf15OQQwOu0sPQOwSq1YvYdvH6PGLHKEoftuGAQkmzPA6OUivL4QuvXZOQuxxP2isv61cOnRsBhPQ6JQG(MkKplHVlrgjvvAAivgTqgpvf6KiLBjaDAeNNs1pLOgNa5tQaRzneqeqdX56(1mgTkgzIbEPZfcrFhxkKcetS9fKkeLoNaJaQnMBqzdQhjWsqxqxdbFLjyKrdbg(xSgcm4nQhwJEekDcS9goxcm4nQh69CKaaVr9ybxUCWueCm)(OccQOjgLMWMyuES7rbsPVBGlkeyWBuxWuBDBySLGoo0G3OUAkwSaErkkYLgc6z899ES7ngbwFbPkOUnm2kmI0tbmXk7c2Mm04LohTUIlW4LohTUrdDoRZ5GOBMkDIfGERme7LRNXlbbiacUBNZuFKIla9wPrdDol4qYLNAX3PwokNAT9Od(frSGEgFFVd7EPa)sHpBJE9JpiwquskIyDotnibo831qa)UeXAiWA7yIgIflyBYWevXBeNlsxnf0j3lPUDSDneyTDmrdXIfSWUudbwBht0qSybjQI3ioxKUG5J8pDcUFLjyKgcS2oMOHyXcwFn1qG12XenelwW2KHvSv8NvtXcUyede)L6KkDc6eJN7Td8xd0ia43(ulfLE7cwzbbJg29sbKkgjGGiCyfB55so76CwWJiwptWiney4FXAiGT7Lc8wPjzbER0KSGIfUKybwpbPHaVvAswG32zsXIfuXyxhxcPMcm8xd0CmgXpbzLiwqz)maAb7lc8hgBPtkB4Bb)MXkUasxaGRRKJ(1uBaNApKC5Pw8DQLJYPwBp6GFrMA9PEgFFV0NGsKohPZzQbjWhlFVMK1zaP6FFTrqufG2wJfPOixgDolWE571KSoPsj1guEKGoX45E70QyKaAiox3VMXOvXitmWlDUqi674sHuGyITVGuHO05ey4VgOHEWeelOz5XOSnXcEneCi5YtT47ulhLtT2E0b)IiGgIZ19RzmAvmYed8sNleI(oUuifiMy7livikDoXcOFDoth1zXs]],
			author = "Built-in Aura",
			spellid = 184124,
			group = true,
		},
		{
			name = "Shadow Word: Agony",
			wa_name = "Socrethar - Shadow Word: Agony (debuff)",
			icon = "Spell_Shadow_DeathsEmbrace",
			desc = "Shows the amount of stacks the player has.",
			code = [[d0JfeaGEkLSljQTrjLEScZKskMRqz2s1HH6Mkknme4BQeopfANQI9s2nK9tbJsOQ(Rq(Tsxw0qPKWGrOHtvDqe0POKKJPsDovswOezPus0IrulxspurXtbltvADkQmrfXuLYKPY0rDrkvDvkf9mvsDDvSrkj1ZrAZu02PKQ(Se(QIQMgLkFNsmskLACcvgnvz8usLtIi3sOkNwW9Ou4NksVwLOBRQw3QjiiGeIZQjEKXinweng4N9Ee4HDRLOjjM9O2)jxXJuavWB57Yeu(9cbFbobo1eyCQPjnz98sWBzcUqagf(yoSi1eqzCLvtGFnPjlOOUweWg9tb(1KMSybFCaPMa)AstwG)PttXIfW1qrrwvtGljFmnNPJPubFCryiWLKpMMnJ(PaBtOvoRvBtRrac)tQA65wa4HDRfdeNFRU5mqKWIfzuSGdnJO(zVtYjYcO(zVtYrvtp365oo7EV(kXcmp9oDGrISae(NrRFwX8wfydBiyCO8(J8cUuah(PtSaVmu4X65(nob9f7utaJ7jIvtW)05GAIflirJ9G4SgCcUV4k7eCOzuIg7bXzn4ujbUGPzyC6Sr1e8pDoOMyXcQBpvtW)05GAIflWep4WIutW)05GAIfl4qZOX(jJzvsqfps1e8pDoOMyXIfyUigc2k1ZRDcQzryrnJ(PGWyrccOahn2VFp50PNBbugpUKAfBaXcknT1MoRakJhxsNzrmoG(jIfm1MnG0e7fyRD)6HGYxlaF4vKfGhCyru1eqzCLvtGBJO7b5ujb09GCcmqCCO8(fq3dYf5JzpbWEqUytMoDcHtIzBmQiGkkTOKgvAr5mDm6scUU8wuiGUhKlA4HrOSlywmLZQyXccobWoQj7HRgigpdebpSBTyG48B1nNbIewSiJgigFxs(yAAvcSeCSNEUFJtG1n10KMSEI37vwB54EfGo)wnuuKvQEUf4cu)o2iPXIeqcXz1epYyKglIgd8ZEpc8WU1s0KeZEu7)KR4rkySB3TwqQKyby1eaEy3AXaX53QBodejSyrgfqcXz1epYyKglIgd8ZEpc8WU1s0KeZEu7)KR4rkwG1RNB7EVflb]],
			author = "Built-in Aura",
			spellid = 184239,
			group = true,
		},
		{
			name = "Ghastly Fixation",
			wa_name = "Socrethar - Ghastly Fixation (debuff)",
			icon = "ability_fixated_state_purple",
			desc = "Nofity the player about an add fixated.",
			code = [[d0toeaGEbODPi2gjfFtantIsAUevZMupwHBQcCyLUnHoVuStv0EP2nk7xqgfjbddvYVbETkKHkagSGA4e5GKKCkIs5ykQZPizHeflLKulMalxOhssvpfzzOINdAIeLyQs1KL00HUijHUkjrpJOuDDj2OuIpJQAZQ02LsQpQc1xLsY0ub9DbQrQi14eiJgvz8sPojbDlsQCAvDpskDzr)evQ)sI9S7MEtczygV7iLlCayq5RGx)yJY9BVywvG4IPIujkPttqtCMmpHRjCc0KOPQPQ7M2b(ag0DtqCJO7MGGcRQm4TmwQnDWcXmAcckSQI0I8mrGcRkFeZflXu(0aqTva9v(0aqTva9Thxg8cIIbqVnzKR5ja(8nbbfw1uOWJcebIMQafiOWQwgJgnHXNp)m6UPAkOCVQxVqOjXL)pmnkqeiQW7RPj8fZQPcmvGsPwlSAbMGsPwlScD3NZ(CoiobQMPmAITIPcqkJlcIMuRAnDlAnCSmlWeBftO7(C20X8wiQBcfULV9IpGz0unfuU3EJuAAAvP6dArLYQrt8YNpp0NZCcYKgSv3nHRozO7MelA8D3OrtfyQKSbOWWm(vlJP6FV)OOXg3njw047UrJMIaD6UjXIgF3nA0uYgGcdZ4xnnh4uhA6Ud8bm3njw047UrJMI7iD3KyrJV7gnAQatLbquWIwgJMUagsFatFY5qt1hkP3gc3XrqtQUWcfwvbVnMIj)hW6nsPPFayME2JkdGOKoXS6Zztl7fx8bm3nbXnIUBcBKstsXeMOjPyct0e)iiyJMe3N5UjPyct0KurdtJgnnaaDfemZYycI74iO6bmCFMyYqtCRYojuwurtbeae9jxtKDtBbbwGPVAIaJyI82yOWQlu4J5Tqu3ekClF7fFaluyvOMck3RSzk4VI885mNGm1M77fMOpvhNPuZKG4yIve7XNp)mc95SPgUVxyI(KdxCMWvGMQpusVnchaMjHmmJ3DKYfoamO8vWRFSr5(TxmRkqCXurQeL0PjiUJJGba8m0KmC37CFGrtR7MoM3crDtOWT8Tx8bmtczygV7iLlCayq5RGx)yJY9BVywvG4IPIujkPtJMATpNpKZSrBa]],
			author = "Built-in Aura",
			spellid = 182769,
			group = true,
		},
		{
			name = "Felblaze Charge",
			wa_name = "Socrethar - Felblaze Charge (debuff)",
			icon = "spell_fire_moltenbloodgreen",
			desc = "If the player is the target of the boss charge, shows a warning.",
			code = [[dWZpeaGEcYUueBtKKzsKWCjIzd62Q0nvbESeFtf0Hv1ovr7LA3a7xumkIu8xr1Vv6EIenuPKAWIsdxehuKuNIijhtkoNIKfsqTuPKSyf1Yf8qc0tHwgH8CKMicktvQMSKMoPlIGQRQc5zeP01vyJsP2krQSzeTDIK61iiFMOMMIuFxkXijsvJtfQrJqJNirNKqDlrcNwOZlsDzuddb(jbSBC3y0OyGYbYVWsexwavcnHHWCYyGZVluzWmC3QCGzGrQrrtAMqWerhA8ASAS6UXVOXfqD3iv)G6Ur6oa18cXhayOXdEQYbJ0DaQ5jVs0iUdqvsH4h(IYbjyzhbzwcw2rqMLUT8W289HSKJav(RT57d52qMjOzYklBKUdq1yMSLbv3RX6Mt3bOAHTA1OgIYYCWDJvEEqski8PuJ3xowmwguDV5eJv2OgVC14GY50egcfx9SrAcdHIRu39zJpBMIGMu1y1i4VC(MWHx3GXuMsJKdiKwEGNnc(ltD3NngBZWz4leNjRGe)GmB1yLNhKK90jSrPp1T6G2hjfwnsKJYevF2i6yJW9RUBuFidu3nEhqn6UvRghuoNbLDauoeRwyJ1ijzSmGAA3nEhqn6UvRgdlKD34Da1O7wTAKbLDauoeRgBoCQPns(fnUa3nEhqn6UvRgdFHD34Da1O7wTACq58YENF1cB1i5cumke7trtBSgPjWpnQFHquJTAaYKn1T8Pngy54c6PtyJXYcmgbrnVS3eiRC1NngFq8(ACbUBKQFqD3OMoHnMeykRgtcmLvJYHTfRgVFe4UXKatz1yYaszRwnw2fw3wawyJu9leIk4c0pcUmqnkWrDumHr4gfA3RpjyI0A8h66zJXQrClbwj(HmztrMSTz4m8fIZKvqIFqMZKvAQ88GKuQm2sSQe9zJOJnkLcqssz1NPq0uPAYXImcg3EiklZbQpBmMwasskR(uebIMqWHgRrAc8tlUSaJIbkhi)clrCzbuj0egcZjJbo)UqLbZWDRYbMbgP6xieT1BeOgfwGExGdSA8D3yBgodFH4mzfK4hKzJIbkhi)clrCzbuj0egcZjJbo)UqLbZWDRYbMbwnk1(SzArnwTb]],
			author = "Built-in Aura",
			spellid = 190161,
			group = true,
		},		
	},
	[1391] = {
		{ --Fel Lord Zakuun
			name = "Seed of Destruction",
			wa_name = "Fel Lord Zakuun - Seed of Destruction (debuff)",
			icon = "Spell_Shadow_SeedOfDestruction",
			desc = "Shows a warning when the player is target of one of the Seeds of Corruption.",
			code = [[d4ZxeaGEjIESi7sQQTjbY4KOAMsinxKQzlQ)kLUPuLoVu42q60KStGAVu7g0(byuaQAyir)wPltmujOAWkQHtQoOeHtjbXXKkNtcklej1sLizXkslxspuIupv1YqkphQjQiMQctwW0rDrjGUkGYZau56cTrKKTkbyZqSDji9tPOpdKPjHQVdiJucuVwQIrtkgVeIojP0TKq5Asu6EsuCyeRvcHVHe2DE4R81czPIqscDTPfIPFDjNBVgsybQ9IeAImrWCnMy1c9X(0631NY(0OWh1p4h8WVrteeSWgmnkP1Nsk8jjwTqSh(yMuzp8XBegAtAiqOK97LGzP6J3im0Qtyn(FJWa9KgsLKyPs)Pnwbj0FAJvqsbSjsMkbLKf6adgesGkbLKfQYIqzx)feiF8gHbFaZPiMxu)W2I3imyQnB2NavOewTqp8XmPYE4Zn0fF9QGf2xVkyH9bvxGm7Jsuqp81RcwyF9yglMn7Zvfiqs1d)GmnIGu6mbJ9rjGuj)ueZlARgvq8zfQe8JyPfRl5S2GN6J1LCwBa7Hb3zWDL3v2UYA2hsqL2vxQeER(LPm(iXCgNiqp1hsqfShgCN)fjayEramprWCnMy1cn7hKPreKrdDXVGlrP6LkGvuZ(AefinSb3rRC)8scE4ZKSazp8rJzw5HzZ(rS0kW0gHSuvbtTFqHGOsXm3WdF0yMvEy2SFDZIh(OXmR8WSzFbM2iKLQk43rbfu4JqsSAHE4JgZSYdZM9RKK4HpAmZkpmB2pIL20IoLWMAZ(ilKVQKIbtR4(bfwptACMK6b7xQieWCjaI0WVkGulC0qx8vPf6RGkUnTO6zHLGb35N2nhwGGMAFmts9Gl9czIcIkq2VjWgx7Kc0VK7IAWu2h48jrE9uFvWNkjdyUOBnayUii9eJqaZfdW8fjayEramprWCnMy1cbmd8bzAebPq8bsfyngChTY9lYMiiyHn4IrRWkO(LtZhgrhvfiqsfBWD(bfwptAOnTqFTqwQiKKqxBAHy6xxY52RHewGAViHMitemxJjwTqFmts9Gl8vbzFQBogn71SpXd)lsaW8IayEIG5AmXQf6RfYsfHKe6Atlet)6so3EnKWcu7fj0ezIG5AmXQfA2Vqn4UItRZSn]],
			author = "Built-in Aura",
			spellid = 181515,
			group = true,
		},
	},
	[1447] = {--Xhul'horac
		{
			name = "Fel Surge",
			wa_name = "Xhul'horac - Fel Surge (debuff)",
			icon = "spell_fel_incinerate",
			desc = "Shows a warning telling the player about the debuff.",
			code = [[d4d8daGEQQ03uuAxsfBJQIESOMjcvnxH0Sr6WGUPKsNxGUTs9Aff7uj2lz3a7xaJIQc(RImoLKltzOuLIbledxOoivvCkeQCmPQZHqXcrilLQQSyjvlxIhsvv9uvldbphYerO0uLYKvy6OUivPQRQOQNrvcxxKnkvARuLsBgrBNQcnmb1NLKPPOY3LumsQsYyPkPgnvX4PkrNuqUfvLCAQCpQk1pvs9jQsLFd1QxnDOA6DnAGipvQm9qa2kKWSfnugdqrrXgLorA0jhi7awbYMyDKoHo9Dc3HWS6B9H(qnDVCnjjYyT4lceJp7SIGomZomaPMoIHfwn9bEcHtGHishHtGHEGi5eIXBDeobgtXq2J(XjWiA2dSaZSvI(movQSOpJtLkZBXziTRTHul68GHbhDTnKADPMfUVdUQshHtGXu2deamQETqeBfXI1Ha3gYomqnDedlSA6XfdzSEvbxJohm20JlgYyX6BOdOMECXqgRhNOitSyDU4QQSIA6dREIK0)uicPVHvUS(WQNijBbJnDVYp(R2UZt86a42qQPLE9UgnqKNkvMy9eYMqXgLgAO66OyJsdnqQPLET0VYNZfEwX6KjkfLHavxha32eo2kqgx09TV1ZjeJ3tECdtNDBBiw3J5Q8WAPNWkDkgoutNHudWQPVtu2PMyX6giJta2kUHE)QWH1tiBYazCcWwXner6dhjPlNOCq103jk7utSy9cMAQPVtu2PMyX6KWm7Wa103jk7utSy9eYMY4DDilI0lWSPM(orzNAIflwNed478RPfcZPpCOykm4zyEgKU)sGar8tnWG6fRYHbTGXMUlJb6oGJNY4Dm1yBOLEDedZZG8gSdW6eTU1wxRoIH5zq(hdyOdSnaRVE(2drSEVUFX4Twc3Xl0HjgR66UHUx7jr9op4cmhiIVcePRrde5PsLfiIpmS6jssItVg3G9OLEcR0dUMKezSwieMqNWZQds7wXvvzfKw61houmfgmugd0dbyRqcZw0qzmafffBu6ePrNCGSdyfiB6zmMoW1aerI19rT0phHEXsa]],
			author = "Built-in Aura",
			spellid = 186407,
			group = true,
		},
		{
			name = "Void Surge",
			wa_name = "Xhul'horac - Void Surge (debuff)",
			icon = "Spell_Shadow_DevouringPlague",
			desc = "Shows a warning telling the player about the debuff.",
			code = [[d4ZaeaGEjQ8yPSlfY2OkPddAMufL5kIMnvgMc6MkuDEr42qmkQc1ovs7LSBO2Ve5NkL(RImoiXLfgQsWGfjdxchKQuDkjQ6ykQZrvuTqiPLsvrlwbwUKEivL6PQwgK65iMOsutvQMSOMoLlsvqxvj0ZOQQRJQnsvLTkrzZi12vI8nQs8zKmnQs57kfJKQaJLQqgTs14PkItksDlQkCAuUhvL8Afk)g4tufP1S66q11ldWYLsDELk0tJTOsdBrY0naMK8fHZn9DygSzA5yjaVYWul4Gu8qMorh9O5rdhH2l6i6z9S66j2sttctROhIE0qVOdXmeOXay11jgSAQRBjkc9IAqctVOgKW0PQGnY0rGmS66f1GeMEb3rczY0TkJIkQQRNJbCAAF7GeIocKI10BCIbqM2z5q3yirwNtIjsr4CPZAGoPiCU0zI6ADwRZO4v)93Fz6yismbkIk0avDF5lDAUZrAqSgOJHibrDToRxgGLlL68kvitphd4009efHUh4DFoUFl6zY03dg1UP1z0OO7aWS66g0fytDDeUZyQltMoNetbUb4ylQSSqvpZOPznUZsOUoc3zm1LjtVcCH66iCNXuxMm9a3aCSfvwwFgLHd1PHnJbWQRJWDgtDzY0RWwOUoc3zm1LjtNtIPgaza0eQY0Pby7SYfAfT30ZmsHdM4gSngr3NCCPuEFdmHEnOyaCprrOZAaSodZSPgaPWfwK16SoSzmaMOUoXGvtDDcGJZtTDigho9XHelQ6eahNNkG2U(bCCozBhwHnlQjFdWRurY3a8kvugObD(fiqxKCrCoGz)ceOl8ZfXW5rakkDcGJZ6Ls14edGONbteahNfQYKP3aaxgSblu1jgSngX3aSbzyKaB6BxS)0l7H6Ldaq06Wr(Rd5gqd0zzDpAN780Dqf2kLYhLsvgGLlL68kvukLhNJbCA6YRVHLTDToJgfDpzlnnjmT6d0EUxhHcADmhPxzuurLO1z9mJu4Gjs3ay90ylQ0WwKmDdGjjFr4CtFhMbBMwowcWRmm1coifp0jgSngzbadB6OUT33oUm9L06S3qpltca]],
			author = "Built-in Aura",
			spellid = 186333,
			group = true,
		},
	}, 
	[1394] = {--Tyrant Velhari
		{
			name = "Font of Corruption",
			wa_name = "Tyrant - Font of Corruption (debuff)",
			icon = "Spell_Shadow_TwistedFaith",
			desc = "Show a warning when the player has the Font of Corruption debuff.\nUsed on the 2nd phase of the encounter.",
			code = [[d0dmeaGEQuAxkrBJkHVPKyMusL5svmBjESsDtruhMIBtPopvPDcr7LSBv2VQQrrfr)LQACusonudfskdwvA4i1bPsXPOKIJbHZrfHfkswkLu1IfPwUKEOsQNcwgK65iMivQMQGjl00rDrkP0vPsQNrfLRlQnkcNfsQ2ms2ovuDzP(SQY0us67uHrcjzyqIrRkgpvKCskXTOsY1OIu3Jkr)uj8ArKFRyHqbbybwoURuMD7XYEoIhGUlfF4Xehh(bhyc3Xegm)iGia9selrzj6veylikiQGaZHTnmEofeqytLvqaDTjnl4RooeWEPBb01M0Syb2g8PGa6AtAwaDUqAXIfWv83xxvqqStNPOcEPBbOYnwFYjCT1j4m2nrbHeHGeZX)Vd1)76PwZ0mEoXcYK2Nq3LILOslGq3LILirbHeHqIWkuCA0UqSaQCPq2MtPfCg72FO7QHNQax6sbXoDMIADXqicSnF4TGDMWJT)do2cySDhfl4PXFpSqIaTvckJjQGa2u6JvqGDUWyfelwqF7jFCxXrbiwXQvfKjTFF7jFCxXrLsqetrH35c7vbb25cJvqSybvZUvqGDUWyfelwaLzZ45uqGDUWyfelwqM0(7XoTHvkb1P0kiWoxyScIflwa1CmGDBlKOxvqetOlgVaB2jreG6t()fvgN3)VjMJfu7p8CbV0Ta8Eob4dZ(7XMU0ChfsecmBgphrbbe2uzfeehFYKVOsjGm5lk4)DNj8ylGm5l6tB4hbWKVOh3xSWD34UhuzUp89LAUM4NAUEDXCjHIZwoFFcit(I(7hZDDrqYgc3vXIfqyZojcQn4JfKAriSizbe2StISEo2Gp7(yblCDaS4U1kWTZylKOS0zcmzEuAb4OGG3Q54)xx9)Myo()DO(Fxp1AMMXZ9)6KXoDMIYAe4ah5hHebARe4ulOOinlKUcTt4ILwHwWLTdv83xxjcjcbExqrrAwirJc6LOSIGiMqxmETSNtGLJ7kLz3ESSNJ4bO7sXhEmXXHFWbMWDmHbZpc2ZuIJJtPelWOGGeZX)Vd1)76PwZ0mEobwoURuMD7XYEoIhGUlfF4Xehh(bhyc3Xegm)iwGZfseRIgHyja]],
			author = "Built-in Aura",
			spellid = 180526,
			group = true,
		},
		{
			name = "Edict of Condemnation",
			wa_name = "Tyrant - Edict of Condemnation (debuff)",
			icon = "inv_hammer_1h_draeneipaladin_c_01",
			desc = "Show a warning telling the player to run to melee.",
			code = [[dWdAeaGErfTlPQ2MOcZKukMlPy2s62s5MIQ6XI8nvPCyv2ji2l1UvSFvLFII8xq9BGZlvmusPQbdsdxuoOuP6uOGCmOCosvQfskzPsLYILQSCjEikQNISmuQNtYejvjtvjtgvtN4IIkDvvP6zKQW1vQnkvYwjLsBgQ2UOkVgf4ZQQMMQK(UQeJKuQCzHrRkgpkOojk5wKQQtd5EKQY4qHgfPkAyKkBmVmHmXAKOGFPqdReyuAqtEWpxRffyShyE5Ijqzx94ObobRdZKYe7(y911N9BMAM4M4Ez6sccmkVmPKRiEzsb2dho9CZevt5FkjkMuG9WHZo5Xeb2dxt65kxsIIgkb2L)qdLa7YFOTG0v7kAxn08(WJJ3v0UA0vncDy9b))MuG9Wn9bnTvcOzIdGvG9WTwwSy6gu7eey8YKsUI4LjPtwykReQqmLvcviM(lGxSyQDOXltzLqfIPSDvfwSyskO))O4LP0wjGg8dIhMeul4M4rVnooZ1tPm1UFuY0wfWQSOwzXDptQSOwzXvEziygcgJ6WYbMftZ1cyqwuobumPp9zcFxRQ0nUNP5AHYldbZuUCus(GcW)GYmy4rBobbglM4rVno(Qtwys76E3YVR31glMEc0)JyiySz0ufCCVmjxngXltTDvqEzXIPTkGJjb2Jefe3AzIJWXrPDv64LP2UkiVSyXu5sHxMA7QG8YIftXKa7rIcIBc7ngF1e(Leey8YuBxfKxwSyQaQHxMA7QG8YIftBvaNaTENyTSychmcHYzyiSF1ehPYQxhsUeduM62E(GkGpO5h1imvIFeywDYctOeymHgKaNaTSAib3qWmLaGkh8YyTmPKlXafZGro00IrmX07lILELRPCcandrxF9W0TfG7zcXnT6uUr(GQ)pO5Yrj5dka)dkZGHhT5eey(GQN8O3ghNHmXWmHJRcXq0pB9oh9zKTPxqC5XqWyZOPz3wf0)FuugcMPomHJRcXqyRJDFDVzIJuz1RdReymXAKOGFPqdReyuAqtEWpxRffyShyE5Ijqzx94ObobRdZKsUeduApanIjTyATykFlMoVmLlhLKpOa8pOmdgE0MtqGXeRrIc(LcnSsGrPbn5b)CTwuGXEG5LlMaLD1JJg4eSomlMYZqWELnMfBa]],
			author = "Built-in Aura",
			spellid = 180161,
			group = true,
		},
	}, 
	[1395] = {}, --Mannoroth
	[1438] = {--Archimonde
		{
			name = "Doomfire",
			wa_name = "Archimonde - Doomfire (debuff)",
			icon = "Spell_Fire_FelFlameRing",
			desc = "Tells when the player is fixated or when have the doom fire debuff.",
			code = [[dSJ6daGEbODjs2Msv1mjKYCfuZMu3uj42s5BcKhRWovk7fTBv2VGyuek6Vc1Vv1HjzOekmybPHlKdQuLtriXXusNdQyHIQwQa1IfPwUKEOsONcwgu1ZjAIIstvIjROPt5Ies1vfqDzQUUuTrcCELkBgkBxPQ8mbWNfX0iu13vIAKeQmocXOffJNqsNKGUfHsNgY9eqETsKHbv6NIkZvwiGii8mVIPgEyHJ)KHHixRJfGQESaxlqRAEWOlHGKa(uRPWnf(Gi0imjmzHGOMddt6g3elEC2FkrWtqnm0Fswiinv1yHW8JLF)Mmpb53VjHqcD0L23ii)(nJJuwgcW3Vz4S5YLDVSHfN6sqxs()CzC()8f1QBjCdqQpjHG873mEKrDNRjSGsAELgncQd1ug6pwiinv1yHqu1LUriP(ltW2f5eIQU0nAeAk0XcHOQlDJquxlDA0iyvusIxzHW0t3XWwuRKscnvcAqy6P7yyLDrobXTxWliiWIgHt1CjlCBLq2)ByOQtJqx6XYixRfozAcYixRfoLSWTvUTkcoIGtq0iG11A5qDmnHt184pYRk7RecuGim6s7BXzqtNGHA(KgHmokjJXTv8Iqq)QjlemL2pJfcTU2qSqJgb)gF)mVIMewdchCi0LESFJVFMxrtMNWeHHHgDTTJfcTU2qSqJgH6RDwi06AdXcnAeWudd9hleADTHyHgncDPhp(wALX8eQQHZcHwxBiwOrJgbS)mafqNB4fpHQNG(RSlYjGg)raDilE8TiTB(KBReKMASKumE0zeYNRuYTabPPgljx8ptHUMFgHCbUacZk6ec4)nUHBQaqq1TNPjGMe2RoYGA)n9qcvSHeA2)ByOQhsOI50t3XWefclJMwgUTIxec7YHHjDJB4XfFkCdIW1BLkkjXRsUTsyIKrA1oHJ)ii8mVIPgEyHJ)KHHixRJfGQESaxlqRAEWOlHW4F98x(yEAeuSqi7)nmu1ji8mVIPgEyHJ)KHHixRJfGQESaxlqRAEWOlHgH9XTvXJFLgj]],
			author = "Built-in Aura",
			spellid = 189897,
			group = true,
		},
		{
			name = "Shadow Blast",
			wa_name = "Archimonde - Shadow Blast (debuff)",
			icon = "ability_warlock_coil2",
			desc = "Tell how many stacks of Shadow Blast the player has.",
			code = [[dSZ8daGEQcTlj41QuMPkvzUuLMnvUPeQBJIVjH8yb7uf2lz3QA)cLFkK(lv1Vv6WadfvvAWcvdxIoOkvofQk6yQKZjPQfIilfvLSyuYYv4Hsk9uOLjjphPjkeMQitwutNYfrvfxLQOEMKIRROnIQsDEuQnJkBxLQABOQQpRIMMKkFhvzKufmoey0iQXle1jrOBje50GUhvrggc6YsnkuvyDPKqOqIV1doqO9smSp1lGf0bn2(8ad3gU5hwORsivyvHRcewOQiHmcZcZkjKDuooAB6OIWQcewKqqWG7tvsi1adtjH0D(z)azW)TtyXaQ1dH0D(z)sGrwiUZp7nIOrJ4Ui86bWFc)ts73uFs7316a)ncRPWEEkKUZplmw8WKAlJW86t35NfjzYecEidWG7RKqQbgMscn2LTWYrtBty5OPTj8CS8KjKbaFLewoAABclNoAltMqBapp7HscZnRjhxToaLkKbCcdcdtQTm(KH5wObz6SWjT9PLTZrmlwcPLTZrmtvshx64IGAiG)1jt4dyA)TShaBhc9KNeYnDoAa8ILWhW0uL0XLqKmiV8IfNKdqnzcZnRjhxIDzl0d3XxfZ3E(EYesUHNKnDCvrGq3cYkj0aU(nLeYmDgujzYeoPTF)HD(wpGzrsygYXbdtNXwjHmtNbvsMmHJ11kjKz6mOsYKjS)WoFRhWSWRIQVEHCGGb3xjHmtNbvsMmHdqOvsiZ0zqLKjt4K2(HLHfWejzc523qOhBDuvNWrFc3pXUSfcd7le(qZpSmLU26SoUeg21LxEVijKAGWnAT7Ba4Z0VjmQNtiXi4hHECxgDqyHAecM2kwcHzH3ncKHm7N7yXJuS4izqE5flojhGAXIZh5M1KJJpfYdMnY64QIaHrokhhTnDePQ65FbcQe(tM0aEE2dQoUeMH0shGnXW(cj(wp4aH2lXW(uVawqh0y7ZdmCB4MFyHUkHudeUr53f(MqsrtPOfltiqjHizqE5flojhGAcj(wp4aH2lXW(uVawqh0y7ZdmCB4MFyHUkzcVVoUQR6sMe]],
			author = "Built-in Aura",
			spellid = 183864,
			group = true,
		},
	}, 
}

AuraBank.GroupPrototype = {
	["xOffset"] = -378.999450683594,
	["yOffset"] = 212.765991210938,
	["id"] = "Raid Assist Imported",
	["grow"] = "RIGHT",
	["controlledChildren"] = {},
	["animate"] = true,
	["border"] = "None",
	["anchorPoint"] = "CENTER",
	["regionType"] = "dynamicgroup",
	["sort"] = "none",
	["actions"] = {},
	["space"] = 0,
	["background"] = "None",
	["expanded"] = true,
	["constantFactor"] = "RADIUS",
	["trigger"] = {
		["type"] = "aura",
		["spellIds"] = {},
		["unit"] = "player",
		["debuffType"] = "HELPFUL",
		["names"] = {},
	},
	["borderOffset"] = 16,
	
	["animation"] = {
		["start"] = {
			["type"] = "none",
			["duration_type"] = "seconds",
		},
		["main"] = {
			["type"] = "none",
			["duration_type"] = "seconds",
		},
		["finish"] = {
			["type"] = "none",
			["duration_type"] = "seconds",
		},
	},
	["align"] = "CENTER",
	["rotation"] = 0,
	["frameStrata"] = 1,
	["width"] = 199.999969482422,
	["height"] = 20,
	["stagger"] = 0,
	["radius"] = 200,
	["numTriggers"] = 1,
	["backgroundInset"] = 0,
	["selfPoint"] = "LEFT",
	["load"] = {
		["use_combat"] = true,
		["race"] = {
			["multi"] = {},
		},
		["talent"] = {
			["multi"] = {},
		},
		["role"] = {
			["multi"] = {},
		},
		["spec"] = {
			["multi"] = {},
		},
		["class"] = {
			["multi"] = {},
		},
		["size"] = {
			["multi"] = {},
		},
	},
	["untrigger"] = {},
}


-- - dop dor endp endd - stop auto complete
