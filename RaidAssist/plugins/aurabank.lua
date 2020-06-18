
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

local toolbar_icon = [[Interface\Buttons\UI-GroupLoot-Coin-Up]]
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
local DEFAULT_SELECTED_BOSS = 15956 --Anub Rekhan

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

		local count = auras and #auras or 0
		FauxScrollFrame_Update (self, count, 10, 40)
		local offset = FauxScrollFrame_GetOffset (self)

		for i = 1, 10 do
			local index = i + offset
			local f = self.Frames [i]
			local data = auras and auras [index]
			
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
