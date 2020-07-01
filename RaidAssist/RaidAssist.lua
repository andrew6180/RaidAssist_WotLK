-- compatability 
if not Details and not C_Timer or C_Timer._version ~= 2 then
	local setmetatable = setmetatable
	local type = type
	local tinsert = table.insert
	local tremove = table.remove

	C_Timer = C_Timer or {}
	C_Timer._version = 2

	local TickerPrototype = {}
	local TickerMetatable = {
		__index = TickerPrototype,
		__metatable = true
	}

	local waitTable = {}
	local waitFrame = TimerFrame or CreateFrame("Frame", "TimerFrame", UIParent)
	waitFrame:SetScript("OnUpdate", function(self, elapsed)
		local total = #waitTable
		local i = 1

		while i <= total do
			local ticker = waitTable[i]

			if ticker._cancelled then
				tremove(waitTable, i)
				total = total - 1
			elseif ticker._delay > elapsed then
				ticker._delay = ticker._delay - elapsed
				i = i + 1
			else
				ticker._callback(ticker)

				if ticker._remainingIterations == -1 then
					ticker._delay = ticker._duration
					i = i + 1
				elseif ticker._remainingIterations > 1 then
					ticker._remainingIterations = ticker._remainingIterations - 1
					ticker._delay = ticker._duration
					i = i + 1
				elseif ticker._remainingIterations == 1 then
					tremove(waitTable, i)
					total = total - 1
				end
			end
		end

		if #waitTable == 0 then
			self:Hide()
		end
	end)

	local function AddDelayedCall(ticker, oldTicker)
		if oldTicker and type(oldTicker) == "table" then
			ticker = oldTicker
		end

		tinsert(waitTable, ticker)
		waitFrame:Show()
	end

	_G.AddDelayedCall = AddDelayedCall

	local function CreateTicker(duration, callback, iterations)
		local ticker = setmetatable({}, TickerMetatable)
		ticker._remainingIterations = iterations or -1
		ticker._duration = duration
		ticker._delay = duration
		ticker._callback = callback

		AddDelayedCall(ticker)

		return ticker
	end

	function C_Timer.After(duration, callback)
		AddDelayedCall({
			_remainingIterations = 1,
			_delay = duration,
			_callback = callback
		})
	end

	function C_Timer.NewTimer(duration, callback)
		return CreateTicker(duration, callback, 1)
	end

	function C_Timer.NewTicker(duration, callback, iterations)
		return CreateTicker(duration, callback, iterations)
	end

	function TickerPrototype:Cancel()
		self._cancelled = true
	end
end

if not Details then -- defer to details imp because they're probably more up to date tbh

	RAID_CLASS_COLORS.HUNTER.colorStr = "ffabd473"
	RAID_CLASS_COLORS.WARLOCK.colorStr = "ff8788ee"
	RAID_CLASS_COLORS.PRIEST.colorStr = "ffffffff"
	RAID_CLASS_COLORS.PALADIN.colorStr = "fff58cba"
	RAID_CLASS_COLORS.MAGE.colorStr = "ff3fc7eb"
	RAID_CLASS_COLORS.ROGUE.colorStr = "fffff569"
	RAID_CLASS_COLORS.DRUID.colorStr = "ffff7d0a"
	RAID_CLASS_COLORS.SHAMAN.colorStr = "ff0070de"
	RAID_CLASS_COLORS.WARRIOR.colorStr = "ffc79c6e"
	RAID_CLASS_COLORS.DEATHKNIGHT.colorStr = "ffc41f3b"

	local oldGetInstanceDifficulty = GetInstanceDifficulty
	function GetInstanceDifficulty()
		local diff = oldGetInstanceDifficulty()
		if diff == 1 then
			local _, _, difficulty, _, maxPlayers = GetInstanceInfo()
			if difficulty == 1 and maxPlayers == 25 then
				diff = 2
			end
		end
		return diff
	end

	function IsInGroup()
		return (GetNumRaidMembers() == 0 and GetNumPartyMembers() > 0)
	end

	function IsInRaid()
		return GetNumRaidMembers() > 0
	end

	function GetNumSubgroupMembers()
		return GetNumPartyMembers()
	end

	function GetNumGroupMembers()
		if IsInGroup() then
			return GetNumPartyMembers()
		else
			return GetNumRaidMembers()
		end
	end
end

function UnitIsGroupLeader(unitid) 
	if IsInRaid() then 
		return UnitIsRaidOfficer(unitid)
	elseif IsInGroup() then 
		return UnitIsPartyLeader(unitid)
	end
	return
end
-- raid control

local DF = _G ["DetailsFramework"]
if (not DF) then
	print ("|cFFFFAA00Please restart your client to finish update some AddOns.|r")
	return
end

local DATABASE = "RADataBase"
local FOLDERPATH = "RaidAssist"
local _

--the addon already loaded?
if (_G.RaidAssist) then
	print ("|cFFFFAA00RaidAssist|r: Another addon is using RaidAssist namespace.")
	_G.RaidAssistLoadDeny = true
	return
else
	_G.RaidAssistLoadDeny = nil
end

local SharedMedia = LibStub:GetLibrary ("LibSharedMedia-3.0")
SharedMedia:Register ("font", "Accidental Presidency", [[Interface\Addons\RaidAssist\fonts\Accidental Presidency.ttf]])
SharedMedia:Register ("statusbar", "Iskar Serenity", [[Interface\Addons\RaidAssist\media\bar_serenity]])

--default configs
local defaultConfig = {
	profile = {
		addon = {
			enabled = true,
			show_only_in_raid = false,
			anchor_side = "left",
			anchor_size = 50,
			anchor_color = {r = 0.5, g = 0.5, b = 0.5, a = 1},
			show_shortcuts = true,
			
			--when on vertical (left or right)
			anchor_y = -100,
			--when in horizontal (top or bottom)
			anchor_x = 0,
		},
		plugins = {},
	}
}

--raid assist options
local options_table = {
	name = "Raid Assist",
	type = "group",
	args = {
		IsEnabled = {
			type = "toggle",
			name = "Is Enabled",
			desc = "Is Enabled",
			order = 1,
			get = function() return RaidAssist.db.profile.addon.enabled end,
			set = function (self, val) 
				RaidAssist.db.profile.addon.enabled = not RaidAssist.db.profile.addon.enabled; 
			end,
		},
	}
}


--create the raid assist addon
local RA = DF:CreateAddOn ("RaidAssist", DATABASE, defaultConfig, options_table)
RA.InstallDir = FOLDERPATH

do
	local serialize = LibStub ("AceSerializer-3.0")
	serialize:Embed (RA)
end

RA.__index = RA
RA.version = "v1.0"

--store all plugins isntalled
RA.plugins = {}
--plugins that have been schedule to install
RA.schedule_install = {}
--this is the small frame menu to select an option without using /raa
RA.default_small_popup_width = 150
RA.default_small_popup_height = 40


--plugin database are stored within the raid assist database
function RA:LoadPluginDB (name, isInstall)
	local plugin = RA.plugins [name]
	if (not plugin) then
		return
	end

	local hasConfig = RA.db.profile.plugins [name]
	
	if (hasConfig) then
		RA.table.deploy (hasConfig, plugin.db_default)
	else
		RA.db.profile.plugins [name] = RA.table.copy ({}, plugin.db_default)
	end

	if (plugin.db.enabled == nil) then
		plugin.db.enabled = true
	end
	if (plugin.db.menu_priority == nil) then
		plugin.db.menu_priority = 1
	end

	plugin.db = RA.db.profile.plugins [name]

	if (not isInstall) then
		if (plugin.OnProfileChanged) then
			xpcall (plugin.OnProfileChanged, geterrorhandler(), plugin)
		end
	end

end


--make the reload process all over again in case of a profile change
function RA:ReloadPluginDB()
	for name, plugin in pairs (RA.plugins) do
		RA:LoadPluginDB (name)
	end
end


--do the profile thing
function RA:ProfileChanged()
	RA:RefreshMainAnchor()
	if (RaidAssistAnchorOptionsPanel) then
		RaidAssistAnchorOptionsPanel:RefreshOptions()
	end
	RA:ReloadPluginDB()
end


--plugin is loaded, do the initialization
function RA.OnInit (self)

	--do more of the profile thing
	RA.db.RegisterCallback (RA, "OnProfileChanged", "ProfileChanged")
	RA.db.RegisterCallback (RA, "OnProfileCopied", "ProfileChanged")
	RA.db.RegisterCallback (RA, "OnProfileReset", "ProfileChanged")
	
	RA.DATABASE = _G [DATABASE]
	
	for _, pluginTable in ipairs (RA.schedule_install) do
		local name, frameName, pluginObject, defaultConfig = unpack (pluginTable)
		RA:InstallPlugin (name, frameName, pluginObject, defaultConfig)
	end

	RA.mainAnchor = CreateFrame ("frame", "RaidAssistUIAnchor", UIParent)

	RA.mainAnchor:SetScript ("OnMouseDown", function (self, button)
		if (button == "LeftButton") then
			RA:OpenAnchorOptionsPanel()
		end
	end)
	
	local priorityOrder = {}
	
	--which menus go first
	local priorityFunc = function (plugin1, plugin2)
		--print (plugin1.name, plugin1.db.menu_priority, plugin2.name, plugin2.db.menu_priority)
		--if (plugin1.db.menu_priority == nil) then
		--	plugin1.db.menu_priority = 1
		--end
		--if (plugin2.db.menu_priority == nil) then
		--	plugin2.db.menu_priority = 1
		--end

		if (plugin1.db.enabled and plugin2.db.enabled) then
			--print (plugin1.pluginname, plugin1.db.menu_priority, plugin2.pluginname, plugin2.db.menu_priority)
			return plugin1.db.menu_priority > plugin2.db.menu_priority
		elseif (plugin1.db.enabled) then
			return true
		elseif (plugin2.db.enabled) then
			return false
		end
	end

	
	--cooltip 
	local ct = GameCooltip2
	local icon_size = 14
	local empty_table = {}
	local first_frame = 1
	local ct_backdrop = {
		bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
		edgeFile = [[Interface\Buttons\WHITE8X8]],
		tile = true,
		edgeSize = 1, 
		tileSize = 64, 
	}

	local ct_backdrop_color = {0, 0, 0, 0.8}
	local ct_backdrop_border_color = {0, 0, 0, 1}
	
	function RA:GetSortedPluginsInPriorityOrder()
		local t = {}
		for name, plugin in pairs (RA:GetPluginList()) do
			t [#t+1] = plugin
		end
		table.sort (t, priorityFunc)
		return t
	end
	

	--when the anchor is hovered over, create a menu using cooltip
	RA.mainAnchor:SetScript ("OnEnter", function (self)
	
		wipe (priorityOrder)
		
		for name, plugin in pairs (RA:GetPluginList()) do
			priorityOrder [#priorityOrder+1] = plugin
		end
		
		table.sort (priorityOrder, priorityFunc)
		
		local anchorSide = RA.db.profile.addon.anchor_side
		local anchor1, anchor2, x, y
		
		if (anchorSide == "left") then
			anchor1, anchor2, x, y = "bottomleft", "bottomright", 0, 0
		elseif (anchorSide == "right") then
			anchor1, anchor2, x, y = "bottomright", "bottomleft", 0, 0
		elseif (anchorSide == "top") then
			anchor1, anchor2, x, y = "topleft", "bottomleft", 0, 0
		elseif (anchorSide == "bottom") then
			anchor1, anchor2, x, y = "bottomleft", "topleft", 0, 0
		end
	
		ct:Reset()
		ct:SetBackdrop (first_frame, ct_backdrop, ct_backdrop_color, ct_backdrop_border_color)
	
		for index, plugin in ipairs (priorityOrder) do
			local icon_texture, icon_texcoord, text, text_color = plugin.menu_text (plugin)
			local popup_frame_show = plugin.menu_popup_show
			local popup_frame_hide = plugin.menu_popup_hide
			local on_click = plugin.menu_on_click
			
			text_color = text_color or empty_table
			icon_texcoord = icon_texcoord or empty_table

			ct:AddLine (text, _, _, text_color.r, text_color.g, text_color.b, text_color.a, _, _, _, _, 10, "Accidental Presidency")
			ct:AddIcon (icon_texture, first_frame, _, icon_size, icon_size, icon_texcoord.l, icon_texcoord.r, icon_texcoord.t, icon_texcoord.b)
			ct:AddMenu ("main", on_click, plugin)
			ct:AddPopUpFrame (popup_frame_show, popup_frame_hide, plugin)
		end
	
		ct:SetType ("menu")
		ct:SetOwner (self, anchor1, anchor2, x, y)
		ct:Show()
	
		-- need to create the support on cooltip for the extra panel being attached on the menu
		-- the plugin fills the panel if it has.
		-- fill the click function.
	end)
	

	local hideCooltip = function()
		if (not GameCooltip2.had_interaction) then
			GameCooltip2:Hide()
		end
	end
	
	RA.mainAnchor:SetScript ("OnLeave", function (self)
		-- hide cooltip
		C_Timer.After (1, hideCooltip)
	end)
	
	RA:RefreshMainAnchor()
	RA:RefreshMacros()
	

	--I don't remember what patch_71 was
	C_Timer.After (10, function()
		if (RA.db and not RA.db.profile.patch_71) then
			RA.db.profile.patch_71 = true
			
			if (_G ["RaidAssistReadyCheck"] and _G ["RaidAssistReadyCheck"].db) then
				_G ["RaidAssistReadyCheck"].db.enabled = true
			end
			
		end
	end)
	

	--create the floating frame in UIParent, with some delay
	C_Timer.After (10, function()
		--RA.db.profile.welcome_screen1 = false
		if (not RA.db.profile.welcome_screen1) then
			
			local button_template = {
				backdrop = {edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize = 1, bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tileSize = 64, tile = true},
				backdropcolor = {1, 1, 1, .5},
				backdropbordercolor = {1, .9, 0, 1},
				onentercolor = {1, 1, 1, .5},
				onenterbordercolor = {1, .9, 1, 1},
			}
			
			local f = CreateFrame ("frame", nil, UIParent)
			f:SetSize (600, 430)
			f:SetBackdrop ({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 16, edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize = 1})
			f:SetBackdropColor (0, 0, 0)
			f:SetBackdropBorderColor (1, .7, 0, .8)
			
			f:SetScript ("OnUpdate", function()
				if (RaidAssistOptionsPanel and RaidAssistOptionsPanel:IsShown()) then
					f:SetAlpha (0)
				else
					f:SetAlpha (1)
				end
			end)
			
			local logo = DF:CreateImage (f, [[Interface\TUTORIALFRAME\UI-TUTORIALFRAME-SPIRITREZ]], 221*.4, 128*.4, "overlay", {82/512, 303/512, 0, 1})
			logo:SetPoint ("topleft", f, "topleft", 0, -2)
			
			local title = DF:CreateLabel (f, "Welcome to Raid Assist", 16, "yellow")
			local subtitle = DF:CreateLabel (f, "", 10, "white")
			subtitle:SetAlpha (0.8)
			title:SetPoint (221*.4 + 10, -12)
			subtitle:SetPoint ("topleft", title, "bottomleft", 0, -2)
			
			local label_command = DF:CreateLabel (f, "[/raa to open raid assist at any time]", 14, "orange")
			label_command:SetPoint ("topright", f, "topright", -10, -12)
			
			local label_SetupSchedule = DF:CreateLabel (f, "Setup Raid Time Schedule", 12, "yellow")
			local label_SetupSchedule_Desc = DF:CreateLabel (f, "If Raid Assist does know which time you raid,\nit'll record the attendance of players for you.", 10, "white")
			local button_SetupSchedule = DF:CreateButton (f, function() RA.OpenMainOptions (_G ["RaidAssistRaidSchedule"]) end, 80, 40, "Setup\nSchedule")
			button_SetupSchedule:SetPoint ("topleft", subtitle, "bottomleft", (-221*.4) - 5, -30)
			button_SetupSchedule:SetTemplate (button_template)
			label_SetupSchedule:SetPoint ("topleft", button_SetupSchedule, "topright", 10, -2)
			label_SetupSchedule_Desc:SetPoint ("topleft", label_SetupSchedule, "bottomleft", 0, -2)
			
			local label_SetupInvites = DF:CreateLabel (f, "Are you an Officer? - Setup Auto Start Invites", 12, "yellow")
			local label_SetupInvites_Desc = DF:CreateLabel (f, "When Raid Assist knows your raid schedule,\nit can automatically start invites 15 minutes before the raid start.", 10, "white")
			local button_SetupInvites = DF:CreateButton (f, function() RA.OpenMainOptions (_G ["RaidAssistInvite"]) end, 80, 40, "Setup\nInvites")
			button_SetupInvites:SetPoint ("topleft", button_SetupSchedule, "bottomleft", 0, -8)
			button_SetupInvites:SetTemplate (button_template)
			label_SetupInvites:SetPoint ("topleft", button_SetupInvites, "topright", 10, -2)
			label_SetupInvites_Desc:SetPoint ("topleft", label_SetupInvites, "bottomleft", 0, -2)
			
			local label_SetupCooldowns = DF:CreateLabel (f, "Raid Cooldown Monitor", 12, "yellow")
			local label_SetupCooldowns_Desc = DF:CreateLabel (f, "Setup a cooldown monitor to track raid defensive cooldowns.", 10, "white")
			local button_SetupCooldowns = DF:CreateButton (f, function() RA.OpenMainOptions (_G ["RaidAssistCooldowns"]) end, 80, 40, "Cooldown\nMonitor")
			button_SetupCooldowns:SetPoint ("topleft", button_SetupInvites, "bottomleft", 0, -8)
			button_SetupCooldowns:SetTemplate (button_template)
			label_SetupCooldowns:SetPoint ("topleft", button_SetupCooldowns, "topright", 10, -2)
			label_SetupCooldowns_Desc:SetPoint ("topleft", label_SetupCooldowns, "bottomleft", 0, -2)
			
			local label_SetupBattleRes = DF:CreateLabel (f, "BattleRes Monitor", 12, "yellow")
			local label_SetupBattleRes_Desc = DF:CreateLabel (f, "Setup a battle res monitor.", 10, "white")
			local button_SetupBattleRes = DF:CreateButton (f, function() RA.OpenMainOptions (_G ["RaidAssistBattleRes"]) end, 80, 40, "BattleRes\nMonitor")
			button_SetupBattleRes:SetPoint ("topleft", button_SetupCooldowns, "bottomleft", 0, -8)
			button_SetupBattleRes:SetTemplate (button_template)
			label_SetupBattleRes:SetPoint ("topleft", button_SetupBattleRes, "topright", 10, -2)
			label_SetupBattleRes_Desc:SetPoint ("topleft", label_SetupBattleRes, "bottomleft", 0, -2)
			
			--plus
			local label_Plus = DF:CreateLabel (f, "More Tools (require all raid members using Raid Assist):", 12, "yellow")
			label_Plus:SetPoint ("topleft", button_SetupBattleRes, "bottomleft", 0, -20)
			
			local label_WeakAuras = DF:CreateLabel (f, "|cFFFFAA00Weakauras Check|r|cFFFFFFFF: see if all raid members are using an specific aura you want they use.", 12, "yellow")
			local button_WeakAuras = DF:CreateButton (f, function() RA.OpenMainOptions (_G ["RaidAssistAuraCheck"]) end, 16, 16, ">")
			button_WeakAuras:SetTemplate (button_template)
			button_WeakAuras:SetPoint ("topleft", label_Plus, "bottomleft", 0, -8)
			label_WeakAuras:SetPoint ("left", button_WeakAuras, "right", 2, 0)
			
			local label_AddonsCheck = DF:CreateLabel (f, "|cFFFFAA00AddOns Check|r|cFFFFFFFF: check if raid members are using required addons by your guild.", 12, "yellow")
			local button_AddonsCheck = DF:CreateButton (f, function() RA.OpenMainOptions (_G ["RaidAssistAddonsCheck"]) end, 16, 16, ">")
			button_AddonsCheck:SetTemplate (button_template)
			button_AddonsCheck:SetPoint ("topleft", button_WeakAuras, "bottomleft", 0, -8)
			label_AddonsCheck:SetPoint ("left", button_AddonsCheck, "right", 2, 0)
			
			local label_RaidAssignments = DF:CreateLabel (f, "|cFFFFAA00Raid Assignments|r|cFFFFFFFF: help on building assignments for each boss, e.g. cooldown order.", 12, "yellow")
			local button_RaidAssignments = DF:CreateButton (f, function() RA.OpenMainOptions (_G ["RaidAssistNotepad"]) end, 16, 16, ">")
			button_RaidAssignments:SetTemplate (button_template)
			button_RaidAssignments:SetPoint ("topleft", button_AddonsCheck, "bottomleft", 0, -8)
			label_RaidAssignments:SetPoint ("left", button_RaidAssignments, "right", 2, 0)
			
			local label_SendText = DF:CreateLabel (f, "|cFFFFAA00Paste Text|r|cFFFFFFFF: send Urls to your raid (e.g. discord/teamspeak), paste a strategy guide.", 12, "yellow")
			local button_SendText = DF:CreateButton (f, function() RA.OpenMainOptions (_G ["RaidAssistPasteText"]) end, 16, 16, ">")
			button_SendText:SetTemplate (button_template)
			button_SendText:SetPoint ("topleft", button_RaidAssignments, "bottomleft", 0, -8)
			label_SendText:SetPoint ("left", button_SendText, "right", 2, 0)
			
			--close
			local close = DF:CreateButton (f, function() f:Hide(); RA.db.profile.welcome_screen1 = true; end, 80, 20, "close")
			close:SetPoint ("bottomright", f, "bottomright", -12, 12)
			close:InstallCustomTexture()
			f:SetPoint ("center")
			f:Show()
			--f:Hide()
		end
	end)
	
end


--macro to open the /raa panel
local redoRefreshMacros = function()
	RA:RefreshMacros()
end
function RA:RefreshMacros()
	--can't run while in combat
	if (InCombatLockdown()) then
		return C_Timer.After (1, redoRefreshMacros)
	end

	if (RA.DATABASE.OptionsKeybind and RA.DATABASE.OptionsKeybind ~= "") then
		local macro = GetMacroInfo ("RAOpenOptions")
		if (not macro) then
			local n = CreateMacro ("RAOpenOptions", "WoW_Store", "/raa") --what? dunno what i did 7 years ago
		end
		SetBinding (RA.DATABASE.OptionsKeybind, "MACRO RAOpenOptions")
	end
end


--config the anchor for the floating frame in the UIParent
function RA:RefreshMainAnchor()
	RA.mainAnchor:ClearAllPoints()

	local anchorSide = RA.db.profile.addon.anchor_side
	
	if (anchorSide == "left" or anchorSide == "right") then
		RA.mainAnchor:SetPoint (anchorSide, UIParent, anchorSide, 0, RA.db.profile.addon.anchor_y)
		RA.mainAnchor:SetSize (2, RA.db.profile.addon.anchor_size)

	elseif (anchorSide == "top" or anchorSide == "bottom") then
		RA.mainAnchor:SetPoint (anchorSide, UIParent, anchorSide, RA.db.profile.addon.anchor_x, 0)
		RA.mainAnchor:SetSize (RA.db.profile.addon.anchor_size, 2)
	end
	
	RA.mainAnchor:SetBackdrop ({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 64})
	local color = RA.db.profile.addon.anchor_color
	RA.mainAnchor:SetBackdropColor (color.r, color.g, color.b, color.a)
	
	if (RA.db.profile.addon.show_only_in_raid) then
		if (IsInRaid()) then
			RA.mainAnchor:Show()
		else
			RA.mainAnchor:Hide()
		end
	else
		RA.mainAnchor:Show()
	end
	
	--won't show in alpha versions
	RA.mainAnchor:Hide()
end


--group managind
RA.playerIsInRaid = false
RA.playerIsInParty = false

RA.playerEnteredInRaidGroup = {}
RA.playerLeftRaidGroup = {}
RA.playerEnteredInPartyGroup = {}
RA.playerLeftPartyGroup = {}

--group roster changed
local groupHandleFrame = CreateFrame("frame")
groupHandleFrame:RegisterEvent ("PARTY_MEMBERS_CHANGED")
groupHandleFrame:RegisterEvent ("RAID_ROSTER_UPDATE")

groupHandleFrame:SetScript("OnEvent", function()
	--check if player entered or left the raid
	if (RA.playerIsInRaid and not IsInRaid()) then
		RA.playerIsInRaid = false
		RA.RaidStateChanged()

	elseif (not RA.playerIsInRaid and IsInRaid()) then
		RA.playerIsInRaid = true
		RA.RaidStateChanged()
	end
	
	--check if player entered or left a party
	if (RA.playerIsInParty and not IsInGroup()) then
		RA.playerIsInParty = false
		RA.PartyStateChanged()
		
	elseif (not RA.playerIsInParty and IsInGroup()) then
		RA.playerIsInParty = true
		RA.PartyStateChanged()
	end
end)


--handle when the player enters or leave a raid group
--some plugins registered a callback to know when the player enter or leave a group
function RA.RaidStateChanged()
	if (RA.db.profile.addon.show_only_in_raid) then
		RA:RefreshMainAnchor()
	end
	
	if (RA.playerIsInRaid) then
		for _, func in ipairs (RA.playerEnteredInRaidGroup) do
			local okey, errortext = pcall (func, true)
			if (not okey) then
				print ("error on EnterRaidGroup func:", errortext)
			end
		end
	else
		for _, func in ipairs (RA.playerLeftRaidGroup) do
			local okey, errortext = pcall (func, false)
			if (not okey) then
				print ("error on LeaveRaidGroup func:", errortext)
			end
		end
	end
end


--handle when the player enters or leave a party group
function RA.PartyStateChanged()
	if (RA.playerIsInParty) then
		for _, func in ipairs (RA.playerEnteredInPartyGroup) do
			local okey, errortext = pcall (func, true)
			if (not okey) then
				print ("error on EnterPartyGroup func:", errortext)
			end
		end
	else
		for _, func in ipairs (RA.playerEnteredInPartyGroup) do
			local okey, errortext = pcall (func, false)
			if (not okey) then
				print ("error on LeavePartyGroup func:", errortext)
			end
		end
	end
end


--comunication
RA.comm = {}
RA.commPrefix = "RAST"

function RA:CommReceived (_, data)
	local prefix =  select (2, RA:Deserialize (data))
	local func = RA.comm [prefix]
	if (func) then
		local values = {RA:Deserialize (data)}
		if (values [1]) then
			tremove (values, 1) --remove the Deserialize state
			local state, errortext = pcall (func, unpack (values))
			if (not state) then
				RA:Msg ("error on CommPCall: ".. errortext)
			end
		end
	end
end

RA:RegisterComm (RA.commPrefix, "CommReceived")


--combat log event events
local CLEU_Frame = CreateFrame ("frame")
CLEU_Frame:RegisterEvent ("COMBAT_LOG_EVENT_UNFILTERED")

RA.CLEU_readEvents = {}
RA.CLEU_registeredEvents = {}

--cahe for fast reading
local isEventRegistered = RA.CLEU_readEvents

CLEU_Frame:SetScript ("OnEvent", function(self, event, ...)
	local time, token, hidding, sourceGUID, sourceName, sourceFlag, sourceFlag2, targetGUID, targetName, targetFlag, targetFlag2, spellID, spellName, spellType, amount, overKill, school, resisted, blocked, absorbed, isCritical = ...

	if (isEventRegistered [token]) then
		for _, func in ipairs (RA.CLEU_registeredEvents [token]) do
			pcall (func, time, token, hidding, sourceGUID, sourceName, sourceFlag, sourceFlag2, targetGUID, targetName, targetFlag, targetFlag2, spellID, spellName, spellType, amount, overKill, school, resisted, blocked, absorbed, isCritical)
		end
	end
end)


--register chat command
SLASH_RaidAssist1 = "/raa"
function SlashCmdList.RaidAssist (msg, editbox)
	RA.OpenMainOptions()
end
