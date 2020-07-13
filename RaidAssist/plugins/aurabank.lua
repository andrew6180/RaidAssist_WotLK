
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
	-- newest tier at the top 
	[530] = { -- ulduar
		name = "Ulduar",
		boss_ids = {
			[33113] = 1, --Flame Leviathan
			[33118] = 2, --Ignis the Furnace Master
			[33186] = 3, --Razorscale
			[33293] = 4, --XT-002 Deconstructor
			[32867] = 5, --Assembly of Iron
			[32930] = 6, --Kologarn
			[33515] = 7, --Auriaya
			[32845] = 8, --Hodir
			[32865] = 9, --Thorim
			[32906] = 10, --Freya
			[33350] = 11, --Mimiron
			[33271] = 12, --General Vezax
			[33136] = 13, --Yogg-Saron
			[32871] = 14, --Algalon the Observer
		},
		--> install the raid
		boss_names = {
		[1] = LBB["Flame Leviathan"],
		[2] = LBB["Ignis the Furnace Master"],
		[3] = LBB["Razorscale"],
		[4] = LBB["XT-002 Deconstructor"],
		[5] = LBB["Assembly of Iron"],
		[6] = LBB["Kologarn"],
		[7] = LBB["Auriaya"],
		[8] = LBB["Hodir"],
		[9] = LBB["Thorim"],
		[10] = LBB["Freya"],
		[11] = LBB["Mimiron"],
		[12] = LBB["General Vezax"],
		[13] = LBB["Yogg-Saron"],
		[14] = LBB["Algalon the Observer"],
		}
	},
	[536] = { -- naxxramas
		name = "Naxxramas",
		boss_names = {
		[1] = LBB["Anub'Rekhan"],
		[2] = LBB["Grand Widow Faerlina"],
		[3] = LBB["Maexxna"],
		[4] = LBB["Noth the Plaguebringer"],
		[5] = LBB["Heigan the Unclean"],
		[6] = LBB["Loatheb"],
		[7] = LBB["Instructor Razuvious"],
		[8] = LBB["Gothik the Harvester"],
		[9] = LBB["The Four Horsemen"],
		[10] = LBB["Patchwerk"],
		[11] = LBB["Grobbulus"],
		[12] = LBB["Gluth"],
		[13] = LBB["Thaddius"],
		[14] = LBB["Sapphiron"],
		[15] = LBB["Kel'Thuzad"],
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
local DEFAULT_SELECTED_BOSS = 33113 --Flame Levi

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
		for _, raidTier in pairs (RAID_TIERS) do
			local raidName = raidTier.name
			for encounterID, index in pairs(raidTier.boss_ids) do
				local bossName = raidTier.boss_names[index]
				if (bossName and encounterID) then
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
	[33113] = { --Flame Levi
		{
			name = "Pursuit Warning",
			wa_name = "FL Pursued",
			icon = "Ability_Rogue_FindWeakness",
			desc = "Shows a warning when targeted by pursuit.",
			code = [[!TwvyVjooq0Fn3h3vqswG(rAfShs0acNE9UtRm1K4K4Ub7ihhOSFO)23NTtGULDLUtARqPjJhp(9M5nJPdPjuIGswinCDolL)LfPkzZxMUtujmN2Urv0Y3oxiZEKZ(QK30qj4xWhho(JFIs2tjz2FiiPkvvM6OmH)IzMKTRINrVLsoTkpVHBOZ)WOj3momAu44GWOWGrtO5FiAeLWKPLk9ALqAOK7MfNmBZLGnlRGt3bNsncal750yyAdEbElKIU3YXRnLU3XxgTOOGRTUh7iyNb7RSwntY2Z7wKSUv30cOITTNzsl5nKs1XvsCqU)pfN8bo(QDh)axAwR55IxOeY6zlxsjTn8TgawJO2IZm(U288Kt1yh)50n3p)bVpX4eTzdR7EFURIHC5UlbMaJ2aV9UPKKTKKPBaADRGqXzvMsWdxGTuiWfRpRvT1BtvTWjBOQ5vvlYA85e7P8Z5YVG)PQ97es(9(0GFtlvh5nyTwBQMuxXoH0ijTTXO2VTuKHOze797hO4CE2vhYenp3k7ou)E8LYd8eVN3RqeamCftOaLSQ)cfouRPXb3qjFLZRNcALA2WGcWrsEv(7ulz8gMbjfJtRuRvfAiurLkv4d1axAEdVOte1PkGsDBtjdcT)UtLA90z2(Gs(J6FWR7uvkTF7WX4a3Zq3ZOow49(ceN(qYQoRSwWFWI0hfz2I5u8D3sOWZZ8MJhf13t8pVhupJuOi)0fIRvgq6ehwJxfpRxHaY6jGBBPVb2dDWEOd2dFhSZvweVo51NaaAE9PyMwRo(dzGRG0rLo7rnd5Php)MBHdi1JzawrVN9)S28Zhlr8nOdcot9RQhwN8TvREiz5cqvNcRKlkkn(KwLI5gez7XASXdAHVPKylTvzTmTR)i16X(w0V2lstDnIV3QHvHoVGRSNjqxAkSC6QLSNR78UTF7Hx5tUFq2V44UYSwHm47nkKf22(RS748BmIeN0HLJi0NYTnH3680gyxRGpHkWaFGEbgKpP8F3ZFq85btlTJzmOsSQUFYRXwCewfSNa9dI70CsxQoZ2gch22je5i4yGeHZA4ymmxwy14HEdjx2OB8Rq(BmCNVs43ua9ZZStax4sy)FUX8)qhORkCRvXIHKZJgnjCCuyu0Gr4VGqCx5NICLe3mqJk9q)yYWbHdqxIT8nF5Rp1ppNWQQlzUr85AmVhKJz8F7BXMBT6zi5UnZMftjhVmbcOjxu0FnR9WC9tVC(28Or3mCs0KjdhnEsW4XdS3Mh5AcsUCDOn5kEJ(P)ADNqKCaOjkWYE63p(Sk13vIAKuc6GkPA0QOXle1jfQULsIRPe5EcrEmfgNsPBlvRqve0fKeKurGjIWa1YDfi8sqIo45pgWVHTJaSo)Duf)en0Xcee59MMJZA1v2DC3UWicgXsHRDyPRGxYCLRlbX2BAooRvperexbxB3UJBpEDi84Lmx5Ajbv)MIiLy4UaQbIi4nykImQiy4VYQiiHWmOgjPncguJKeeNWE18n8ORNs7jtul1FBxVv)jkwpr)OaQrst0n5FyBq33cguJKWyC(eINfG9h2RIfly43W2XoeHFkP7ewWERvG4wILj4Bmsle8eA)zkIOIGH)kRIa8Qpol4UIwwSG(tjQiaV6JZcWB5XflwaxP33EvfbjFrZ00U8pJG(Ftnem4EohpjiCB4A72ki1QptrebxciF3hvuGqbIfK8fntZsmCxGfUUfHDvRzDbCmCxGBVtybnIBVtybmT7jbdUNZb(UlaRZFhvXprdDe427ewGDO(INTQvSo6wqBCmdUNZXtAJaY3DbyD(7Ok(jAOJaY3DmiCV(mQkisrsqBCmdUNZb(URfcmAdJ6yoPjxat7EsGzlNhJNOfIfSmnXNkqyWTciTEPsVV96OaHcg(nSDSyeLWc2SVu2JvWPtVpzfim4wbj6GN)yXnqebXjSxnFdpACdezIc4EoJbo)eAzmyD(7Ok(jAOJGm6tQiG)Styve0BzMQIyXcCIbQryVstccpCyRG24yCIbQryVstAJGe10KA0YCmve0BzMQIyXcQOSRIGElZuvelwG5BWuerfb9wMPQiwSG24ymq9fpRncQVHRIGElZuvelwSaAsawN)oQIFIg6yvRy3pSybJGG2eAZrBcEqG9kq4vWqXs]],
			author = "Built-in Aura",
			spellid = 62374,
			group = true,
		},
	},
	[33293] = { -- XT-002
		{
			name = "Searing Light Warning",
			wa_name = "Searing Light",
			icon = "Ability_Paladin_InfusionofLight",
			desc = "Shows a warning when you have searing light.",
			code = [[!TAvyVjVnq4FntAF5TkekWlFKYOBirbeoDDt6vMAsCs8wWoY2bk9d93(U7mb6Bt10M0Rek15Y5Zp3Dp3JlVhpHZuC2CTxAZfPYVnp1ODFBYovLYFA7ArLitP3oxN34ugTjFHQO0Zzool(MEJUzaNTNZYWFqKsnvglSyzp6xm9Sp98w8jSXtRYZDspF5xg)1BII5mHoT0yxBuA4RtNTmz2gmqMQmZr9SScjFh4uQhoDhEgoVW6HfG35kTYvgwdldwH1ERQOqADbKKCXaT9Azv1CaWdh0lUhN14K)Q10uVn10aiaoR9cFAP0XknhxPHnq)DcaGds4TMDYdsTFTvMREHZyRNTybfLTEaZEvngIm5UM88Kt1Wo(TjBE4(hd(SuSxYVl4EWNPvcNd3sBGzGrmWBNoHLSLLmzdwxBCEZ(TLQmiGE1EjGFYBi8srLVKZWG95q2tWq0yfXHtUTeaarJaIXKcRsx82ZTn3GdUqLf95CP8JE6Xo1(DkT8HqrlC2lmhLoF4m)33Dd21y1vItq3HE)ARICqqjrsW4dgi)d0ifsy1IQFhAZaZa4AJ5S)wkRNaGp1Vra8fQSkRY)a3kt6eEazEIzvBnfwPZbn0uviuru3yJS4mL7mhs(IFRRua0Y)OLdhD2m(GZ(P6VZRPVByiIggIOHHORddbVVcXjpMS6Svrd0XHSi9jvg2FNaVF(ta)qMfmVC4TTtq)5hb1FbKgv(PRjU14HKoHW6YvlN1snGKnKa02(pmdhqHbr86K3EgaG7TNxkSwZXVRc0bshn2SNScOo90Lv0hoaL(Dv0Sri7)mrHlhlt9kWdIVK6D6hOtHPVvpMSyoKQezQus8oQOvzeKKfnqGXd4cVA0WwAQYAewGztJMGl7BG56lAlIkyUlUJDK21XyMcgMtblN68j8CPZ7U2y2VJp5bzVo2TgOu95aRJzyEdL36IxmNFNrOWPjSCeIYPCu54oYt88OrHqbvb3pGt96CvrqFaYKKRsFcTcPTbu3QvZYW5nW42ZmojeaqF5mbut1DPWjbLAPUaj29dgsU6GhLMv6FGH7Y9h)GcijhQZuT3v5VErgo1ntlaooP7ct3aVDv9788vJzp)(rXrdgn4RJhDB84HrdJ55FzWaYFsoZBsp0Q41pQFeq4vzDfWdJf3BbT3aazt3mB2siJrtqsi8csr(4vvKxUCXC8WH3mc6RyKFP0TB8VC6Nff9qUeE4HlKRQldHit5q975eV4)9)hrB9blke1cjDSdqKVng1A4)d]],
			author = "Built-in Aura",
			spellid = 65121,
			group = true,
		},
		{
			name = "Gravity Bomb Warning",
			wa_name = "Gravity Bomb",
			icon = "inv_ingot_titansteel_dark",
			desc = "Shows a warning when you have Gravity Bomb.",
			code = [[!TAvxVPooq0Fn7J3ki8rBFKIs7IefQWPB3v6kN6M4K49gSJSDGsFO)23zgtGEBQwTR0vcfmtgp(mZCMJHpKNWzkoBH2lTfIm53xKz0UVR07sv6sJp1R8cTZlL1P5c7p4mhNfDXWlVycNTLZYXpqmYm1glSy1q6te9Ce9Cm(0Zzhwxu4KE(QVD9vxmiIZe6SkJ9bJsdVDE8QK4nyGm15M9648sj)fWPmVcqeEgoVW6HfG3fkTYvfwdldwH1ERQSuADbKKCYaT9gzD9caWtNmmAiN16K3znTnPzMwabWzTv4ZQKowLz)AnSb67zaa2jHF1(ICNu7FWkluVYzShIxUKIsQhWSx1GHix(sBrrYHgyh)(Sn3F7JbFwj2k53eCp4Z8AHZHBPlWmWig405ZyjPSKzBW6ARZB2MwPYHa6vBLa(jVHWlf1(kodd2xdzpbdrRvefo5UsaaencigtkSqF(9NxQkR8NQrUqLf95yPKDNvSt5p8(Z3y2(c(Ym4BLwEFOMfo6LM9sNpCK)RBUf7zSMAXbO3q)(CJIAKckfscgV3azFGePqIQwu)hqtg4fat7Ao7hszZma6z(ncGTqfvzDXNyw5sNWdaZt8QgRP0kDoODMPcHAa1l2ilps4oYGKV6tDvcGu(NDm4bhnJp4SFR5N8A(hgfgqJcdOrHbNhfcEFgIZEmz9rRIwOFdzr2tQCS7od(9XxbSdzEW8QPJ7MF(RpdQ)gOmQIdNtCRXdjDcH1vRxf3rmGKnKa02(pmbhqHbr8djV)maa37pVsyTM9)ufOhK2BS5pzfqD6PtROxSdk9VuttgHS)RKeoDSm1Bapi6uQ3RFGofM9w)yYYfqQsKPkjXUPIwTrqcw04agpGl8MrdBPToVvybInnycUSTfMQpPSiQHPUOE2rAxpJ5kyuodSCO3RWZLoVB6I5OE(uee96z3AGs1xdSEMHPAuCRpEXC(dgHcNMWYEikhkqDJBipXZJgfcfufCVao0RluLb1bitsol8j0kK2gqDNsnlhN3aJPhzCsiaG6YrcOMQ7sHtc60sDjsShfmKC2bpkmR0)cd3PBp(ffqsnuNR6UPYF(AmCQlwlaooP6ct3aVDDZh88nJzl)2XxnD0vxDz0Krxpn6YjJ4fFBYyYFsoZBY21P4nAWObaHxL)zD1Jtf3AbL3a(yZ3ehVcsy0eKdcVG0J3Fwe51t3khnD6fxcTvmWSyz7DVwenDtfsLWZoCBCDtvie5khkFVGOf)p(7dDfgSAqCkKTX2bXCCekYW)Np]],
			author = "Built-in Aura",
			spellid = 63024,
			group = true,
		},
		{
			name = "Gravity Bomb Text Warning",
			wa_name = "Gravity Bomb Text",
			icon = "inv_ingot_titansteel_dark",
			desc = "Shows a text warning when you have Gravity Bomb.",
			code = [[!Ts13ZPnoq4)D6lPJ)zm8iWyAZnGjtKt56nDKrXwgR7mwmsYqOpWF73Us2P5k3Dp1zyWYR)29B1UF7s9P5uIGsEOZWv1Ss(3EOu2P)MO7uHOBV0uyegwN2W5Tfvm1FrjAkj4J(jFmMsoqjv4pigYEtROJtjBEoF1dzPucR30ivBoAeqabigaPqFSLDjN)k8Y6nFj96UzBN91R)ge1gwL88x3uxR5gA2D(qa6kHa8Ou0bOxKMLN(eLu2RnYdyeE(yfZaeYpXraaDYdmJOCROY0qjZG3bRLJ0t0gMY4YdrNy4unCu3ypdVzuI975keEMTYmyapY6vSo2b(WhjFsXojmxUUBU8WlOZa5LnCnPrEEthEHWNZa(pbjPU)fBE(OIxlELsipMUAfL0R5fgPS1iosFbQp8x6RRZVCe84ZZEA9YNDyYaEPZDWDyw0Y0A0LXataJyGlwmJKxqYN9u(BLMpZzTyjXydmErcSX6tkz)XIszpacd1rEB7dvd9kKL)97Y)BvOeEc6G1UIHZ1vYZCn8TESStqfaush6KfnIkiMgXbEf1I5h1CBpHzzn3zCTead8A7HGITJ1(fOFbTyAwWuGnEB9GGz(M88nRHoSeF7X8R7abL(6UmMsjptjnCX(gdD59rEX((tdtIcG)9NqRVlkHsALmRUgl5AX35yb67suG33w1Zu2YvjI4qp0(gZ2sBF5NTAyTqJi4g7vcOPvcwUCZNqET8nF09WBWu7u3)h0DJzLSLFJryihvb3y3ENFNrIH3zZLZqOVuJcH5wKgxjMG4ZcsgNK)9XjzqKO47H00jRn2zFyhtTy)4i4R8k3qBwGNhL8NGWquFHswLUejwwEAShh6fIiev)KY76o3oLxhyD5DXXtMg4njoimkCs80aSTgbKPaXlmwZmmBQD2Y7YKyV4PtNcUeCFCKNveC)4gOLOpUSNS4P00mO7GzWhsZd)WFmVjDXwk5YBmNeccQWjbXXjEtJccheuLYwPYn1G)cOlNeLKecYpVOO7d899bGXjWDKM5rZIgK5UQ5I35Sh6m())eiusReVBx7zPQARIDKs2(2jwNaxr6KmJ7dhwl0zf3vWYbeqHZOMJHfgJ5mnw24D7X2uOZq(pC0U)t09lmCVTz(xuaTk1tqXcMZHJ0)(]],
			author = "Built-in Aura",
			spellid = 63024,
			group = true,
		},
	}
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
