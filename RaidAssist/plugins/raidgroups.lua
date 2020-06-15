

local RA = RaidAssist
local L = LibStub ("AceLocale-3.0"):GetLocale ("RaidAssistAddon")
local _
local default_priority = 23
local DF = DetailsFramework

if (_G ["RaidAssistRaidGroups"]) then
	return
end
local RaidGroups = {version = "v0.1", pluginname = "RaidGroups"}
_G ["RaidAssistRaidGroups"] = RaidGroups

RaidGroups.IsDisabled = false

local ROSTER_PLAYERNAME = 1
local ROSTER_RAIDRANK = 2
local ROSTER_RAIDGROUP = 3

local group_sizeX, group_sizeY, group_spacing_vertical = 234, 99, 15
local slot_iconsize = 14
local slot_backdrop = {edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize = 1, bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tileSize = 64, tile = true}
local slot_backdropcolor = {0, 0, 0, .55}
local slot_backdropcolor_filled = {.13, .13, .13, 1}
local slot_bordercolor = {0, 0, 0, 0}
local slot_bordercolor_filled = {1, 1, 0, 0.1}
local slot_bordercolor_filtered = {1, 1, 0, 0.25}
local slot_bordercolor_onenter = {1, 1, 0, 0.30}
local slot_height = 19

local default_config = {
	enabled = true,
	text_size = 10,
	text_face = "Friz Quadrata TT",
	text_shadow = false,
	filter = false,
	show_class_name = true,
	show_level = true,
	show_class_icon = true,
	show_role_icon = true,
	show_rank_icons = true,
}

local icon_texcoord = {l=32/512, r=64/512, t=0, b=1}
local text_color_enabled = {r=1, g=1, b=1, a=1}
local text_color_disabled = {r=0.5, g=0.5, b=0.5, a=1}
local icon_texture = "Interface\\AddOns\\" .. RA.InstallDir .. "\\media\\plugin_icons"

local can_install = true

RaidGroups.menu_text = function (plugin)
	if (RaidGroups.db.enabled) then
		return icon_texture, icon_texcoord, "Raid Groups", text_color_enabled
	else
		return icon_texture, icon_texcoord, "Raid Groups", text_color_disabled
	end
end

RaidGroups.menu_popup_show = function (plugin, ct_frame, param1, param2)
	RA:AnchorMyPopupFrame (RaidGroups)
end

RaidGroups.menu_popup_hide = function (plugin, ct_frame, param1, param2)
	RaidGroups.popup_frame:Hide()
end

RaidGroups.menu_on_click = function (plugin)
	--if (not RaidGroups.options_built) then
	--	RaidGroups.BuildOptions()
	--	RaidGroups.options_built = true
	--end
	--RaidGroups.main_frame:Show()
	
	RA.OpenMainOptions (RaidGroups)
end

RaidGroups.OnInstall = function (plugin)

	RaidGroups.db.menu_priority = default_priority

	RaidGroups:RegisterEvent ("PARTY_MEMBERS_CHANGED")
	RaidGroups:RegisterEvent ("RAID_ROSTER_UPDATE")
	RaidGroups:PARTY_MEMBERS_CHANGED()
	RaidGroups:RAID_ROSTER_UPDATE()
end

RaidGroups.OnEnable = function (plugin)
	-- enabled from the options panel.
end

RaidGroups.OnDisable = function (plugin)
	-- disabled from the options panel.
end

RaidGroups.OnProfileChanged = function (plugin)
	if (plugin.db.enabled) then
		RaidGroups.OnEnable (plugin)
	else
		RaidGroups.OnDisable (plugin)
	end
	
	if (plugin.options_built) then
		--plugin.main_frame:RefreshOptions()
	end
end

function RaidGroups.UpdateRosterFrames()

	local SharedMedia = LibStub:GetLibrary ("LibSharedMedia-3.0")
	local db = RaidGroups.db
	
	for _, group_frame in ipairs (RaidGroups.RaidGroups) do
		for _, slot in ipairs (group_frame.Slots) do
		
			local font = SharedMedia:Fetch ("font", db.text_font)
			local size = db.text_size
			local shadow = db.text_shadow
			
			RaidGroups:SetFontFace (slot.playername, font)
			RaidGroups:SetFontFace (slot.playerlevel, font)
			RaidGroups:SetFontFace (slot.playerclass, font)
		
			RaidGroups:SetFontSize (slot.playername, size)
			RaidGroups:SetFontSize (slot.playerlevel, size)
			RaidGroups:SetFontSize (slot.playerclass, size)
			
			RaidGroups:SetFontOutline (slot.playername, shadow)
			RaidGroups:SetFontOutline (slot.playerlevel, shadow)
			RaidGroups:SetFontOutline (slot.playerclass, shadow)
			
			if (db.show_class_name) then
				slot.playerclass:Show()
			else
				slot.playerclass:Hide()
			end
			
			if (db.show_level) then
				slot.playerlevel:Show()
			else
				slot.playerlevel:Hide()
			end
			
			if (db.show_class_icon) then
				slot.classicon:Show()
			else
				slot.classicon:Hide()
			end
			
			if (db.show_role_icon) then
				slot.roleicon:Show()
			else
				slot.roleicon:Hide()
			end

			if (db.show_rank_icons) then
				slot.assisticon:Show()
				slot.tankicon:Show()
				slot.masterlooticon:Show()
			else
				slot.assisticon:Hide()
				slot.tankicon:Hide()
				slot.masterlooticon:Hide()
			end
		end
	end
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
local get_player_raidInfo = function (playerName)
	for i = 1, GetNumGroupMembers() do
		local name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML = GetRaidRosterInfo (i)
		if (name == playerName) then
			return i, name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML
		end
	end
end

local get_amtPlayers_onRaidGroup = function (groupIndex)
	local amtFound = 0
	for i = 1, GetNumGroupMembers() do
		local name, rank, subgroup = GetRaidRosterInfo (i)
		if (subgroup == groupIndex) then
			amtFound = amtFound + 1
		end
	end
	return amtFound
end

local group_cache = {}
local get_groupIntruderIndex = function (groupIndex) -- is 1
	for i = 1, GetNumGroupMembers() do
		local name, rank, subgroup = GetRaidRosterInfo (i)
		if (subgroup == groupIndex) then
			if (group_cache [name] ~= subgroup) then
				return i
			end
		end
	end
	return 0
end

local unlock_frame_after_sync = function()
	RaidGroups.lock_frame:Hide()
end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local DragOnUpdate = function (self, elapsed)
	RaidGroups.TargetSlot = nil
	RaidGroups.TargetGroup = nil
	
	for group, group_frame in ipairs (RaidGroups.RaidGroups) do
		for index, slot in ipairs (group_frame.Slots) do
			if (slot:IsMouseOver() and slot ~= self.DraggingFrame) then
				-- show effects
				RaidGroups.TargetSlot = slot
				RaidGroups.TargetGroup = group_frame
				--print ("Hovering Frame:", RaidGroups.TargetSlot.RosterIndex)
			end
		end
	end
	
	if (not RaidGroups.TargetSlot) then
		for group, group_frame in ipairs (RaidGroups.RaidGroups) do
			if (group_frame:IsMouseOver() and group_frame ~= self.DraggingFrame:GetParent()) then
				RaidGroups.TargetGroup = group_frame
			end
		end
	end
end


function RaidGroups.OnShowOnOptionsPanel()
	local OptionsPanel = RaidGroups.OptionsPanel
	RaidGroups.BuildOptions (OptionsPanel)
	RaidGroups.UpdateFilterLabel()
end

local OnShowPanel = function()

end

function RaidGroups.BuildOptions (frame)

	if (frame.FirstRun) then
		return
	end
	frame.FirstRun = true
	
	RaidGroups.GroupsFrame = frame
	frame:SetSize (640, 480)
	
	RaidGroups.VirtualGroups = {}
	
	frame:SetScript ("OnShow", OnShowPanel)
	
	local help_frame = CreateFrame ("frame", nil, frame)
	help_frame:SetSize (320, 100)
	help_frame:SetBackdrop ({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 16, edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize = 1})
	help_frame:SetBackdropColor (0, 0, 0, .3)
	help_frame:SetBackdropBorderColor (.3, .3, .3, .3)
	local label =  RA:CreateLabel (help_frame, "Tips:\n\n- You can modify raid groups while your raid clear trash mobs and apply the changes when all players are out of combat, saving a lot of time on organizing the raid.\n\n- Use as a backup if need to make many changes to the roster layout.", 10, "orange")
	label:SetPoint ("topleft", help_frame, "topleft", 10, -10)
	label:SetSize (300, 90)
	label:SetAlpha (.8)
	label:SetJustifyV ("top")
	help_frame:SetPoint ("bottomright", RaidAssistOptionsPanel, "bottomright", -10, 119)
	
	local OnDragStart = function (self)
		local cursorX, cursorY = GetCursorPosition()
		local uiScale = UIParent:GetScale()
		self:StartMoving()
		self:ClearAllPoints()
		--centraliza
		self:SetPoint("CENTER", UIPARENT, "BOTTOMLEFT", cursorX / uiScale, cursorY / uiScale)
		frame.DraggingFrame = self
		frame:SetScript ("OnUpdate", DragOnUpdate)
	end
	local OnDragStop = function (self)
		
		self:StopMovingOrSizing()
		frame:SetScript ("OnUpdate", nil)
		
		if (RaidGroups.TargetSlot) then
			-- SetRaidSubgroup	raid index do GetNumGroupMembers()
			-- SwapRaidSubgroup	mesma coisa, usa o index do GetNumGroupMembers()
			
			if (RaidGroups.TargetSlot.RosterIndex) then -- o slot esta ocupado? � um switch
				
				--> get raid indexes, goes from 1 .. 40
				local self_rosterIndex = self.RosterIndex
				local target_rosterIndex = RaidGroups.TargetSlot.RosterIndex
				
				--> roster tables (with the GetRaidRosterInfo)
				local self_virtualRosterInfo = RaidGroups.VirtualGroups [self_rosterIndex] --table
				if (self_virtualRosterInfo) then
				
					local target_virtualRosterInfo = RaidGroups.VirtualGroups [target_rosterIndex] --table
					
					--> isn't both players from the same group?
					if (target_virtualRosterInfo and self_virtualRosterInfo [ROSTER_RAIDGROUP] ~= target_virtualRosterInfo [ROSTER_RAIDGROUP]) then
						--> which group (1 .. 8) the player belongs to
						local self_raidGroup = self_virtualRosterInfo [ROSTER_RAIDGROUP]
						local target_raidGroup = target_virtualRosterInfo [ROSTER_RAIDGROUP]
						
						--> swap which groups those players belongs to
						target_virtualRosterInfo [ROSTER_RAIDGROUP] = self_raidGroup
						self_virtualRosterInfo [ROSTER_RAIDGROUP] = target_raidGroup
						
						--> swap indexes on the virtual roster
						RaidGroups.VirtualGroups [target_rosterIndex] = self_virtualRosterInfo
						RaidGroups.VirtualGroups [self_rosterIndex] = target_virtualRosterInfo
						
						--> update the virtual roster frame
						RaidGroups.UpdateVirtualGroups()
					end
				end
				
			else -- o slot n�o esta ocupado, adicionar o jogador ao grupo
				
				--> get raid indexes, goes from 1 .. 40
				local self_rosterIndex = self.RosterIndex
				local target_rosterIndex = RaidGroups.TargetSlot.RosterIndex

				--> roster tables (with the GetRaidRosterInfo)
				local self_virtualRosterInfo = RaidGroups.VirtualGroups [self_rosterIndex] --table
				if (self_virtualRosterInfo) then
				
					local target_virtualRosterInfo = RaidGroups.VirtualGroups [target_rosterIndex] --table
					local target_raidGroup = RaidGroups.TargetGroup.Group
					
					--> which group (1 .. 8) the player belongs to
					local self_raidGroup = self_virtualRosterInfo [ROSTER_RAIDGROUP]
					
					-- if the target group is BIGGER than the current one
					if (target_raidGroup > self_raidGroup) then
					
						local stop_raidGroup = target_raidGroup + 1
						
						--> find the target roster raid index (1 .. 40)
						local targetIndex
						for i = self_rosterIndex+1, 40 do
							local this_rosterInfo = RaidGroups.VirtualGroups [i] --table
							if (this_rosterInfo) then
								if (this_rosterInfo [ROSTER_RAIDGROUP] == stop_raidGroup) then
									targetIndex = i
									break
								end
							else
								targetIndex = i
								break
							end
						end
						
						if (targetIndex) then
							self_virtualRosterInfo [ROSTER_RAIDGROUP] = target_raidGroup
							tinsert (RaidGroups.VirtualGroups, targetIndex, self_virtualRosterInfo)
							tremove (RaidGroups.VirtualGroups, self_rosterIndex)
							--> update the virtual roster frame
							RaidGroups.UpdateVirtualGroups()
						end
						
					elseif (target_raidGroup < self_raidGroup) then
						
						local stop_raidGroup = target_raidGroup - 1
						
						--> find the target raid index
						local targetIndex
						--for i = self_rosterIndex-1, 1, -1 do
						for i = 1, 40 do
							local this_rosterInfo = RaidGroups.VirtualGroups [i] --table
							if (this_rosterInfo) then
								if (this_rosterInfo [ROSTER_RAIDGROUP] >= target_raidGroup) then
									-- targetIndex = i
									-- get the latest spot on the group
									for o = i, i+5 do
										this_rosterInfo = RaidGroups.VirtualGroups [o] --table
										if (not this_rosterInfo or this_rosterInfo [ROSTER_RAIDGROUP] > target_raidGroup) then
											targetIndex = o
											break
										end
									end
									break
								end
							else
								targetIndex = i
								break
							end
						end
			
						if (targetIndex) then
							self_virtualRosterInfo [ROSTER_RAIDGROUP] = target_raidGroup
							tremove (RaidGroups.VirtualGroups, self_rosterIndex) --remove em cima
							tinsert (RaidGroups.VirtualGroups, targetIndex, self_virtualRosterInfo) --adiciona em baixo depois
							--> update the virtual roster frame
							RaidGroups.UpdateVirtualGroups()
						end
					
					end
				end
			end
			
			---
			--slot.Id = o -- 1 a 5
			--slot.Id_Raid = index -- 1 a 40
			--slot.RosterIndex -- index no GetNumGroupMembers()
		
		
		elseif (RaidGroups.TargetGroup) then
			--> the mouse is between slots, so try to move the player to the hovering over group
			
			-- pegar qual � o grupo
			local group = RaidGroups.TargetGroup.Group
			
			-- o grupo esta cheio?
			local freeSlot
			for index, slot in ipairs (RaidGroups.TargetGroup.Slots) do
				if (not slot.RosterIndex) then
					freeSlot = slot
					break
				end
			end
			
			-- se nao estiver, mover o jogador
			if (freeSlot) then
				RaidGroups.TargetSlot = freeSlot
				--> inception
				RaidGroups.OnDragStop (self)
				return
			end
			
		end
		
		RaidGroups.TargetSlot = nil
		RaidGroups.TargetGroup = nil
		self:ClearAllPoints()
		self:SetPoint ("topleft", self:GetParent(), "topleft", 0, self.Height)
		
	end
	
	RaidGroups.OnDragStop = OnDragStop
	
	--create group panels
	RaidGroups.RaidGroups = {}
	local x, y, index = 0, 0, 1
	local OnEnter = function (self)
		self:SetBackdropBorderColor (unpack (slot_bordercolor_onenter))
	end
	local OnLeave = function (self)
		if (self.GotFilteredOut) then
			self:SetBackdropBorderColor (unpack (slot_bordercolor_filtered))
		elseif (self.RosterIndex) then
			self:SetBackdropBorderColor (unpack (slot_bordercolor_filled))
		else
			self:SetBackdropBorderColor (unpack (slot_bordercolor))
		end
	end

	for i = 1, 8 do
	
		local panel = CreateFrame ("frame", "RaidAssistRaidGroups_Group" .. i, frame)
		panel:SetPoint ("topleft", frame, "topleft", x, y)
		panel:SetSize (group_sizeX, group_sizeY)
		panel:SetBackdrop ({edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize = 1, bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tileSize = 64, tile = true})
		panel:SetBackdropColor (0, 0, 0, .1)
		panel:SetBackdropBorderColor (0.1, 0.1, 0.1, 1)
		local label = panel:CreateFontString (nil, "overlay", "GameFontNormal")
		--label:SetPoint ("center", panel, "center")
		label:SetPoint ("bottomleft", panel, "topleft", 2, 1)
		--label:SetPoint ("bottom", panel, "top", 0, 2)
		label:SetText ("Group " .. i)
		RaidGroups:SetFontSize (label, 10)
		
		panel.Group = i
		panel.Slots = {}
		tinsert (RaidGroups.RaidGroups, panel)
		
		for o = 1, 5 do
			local slot = CreateFrame ("frame", "RaidAssistRaidGroups_Group" .. i .. "Slot" .. o, panel)
			slot:SetMovable (true)
			slot:SetSize (group_sizeX-2, slot_height)
			slot:RegisterForDrag ("LeftButton")
			slot:EnableMouse (true)
			slot:SetBackdrop (slot_backdrop)
			slot:SetBackdropColor (unpack (slot_backdropcolor))
			slot:SetBackdropBorderColor (unpack (slot_bordercolor))
			
			--background texture
			local bg = slot:CreateTexture (nil, "border")
			bg:SetAllPoints()
			bg:SetTexture ([[Interface\RaidFrame\UI-RaidFrame-GroupButton]])
			bg:SetTexCoord (5/256, 160/256, 2/32, 12/32)
			bg:SetAlpha (0.2)
			
			slot.Height = -(o-1) * (slot_height+1)
			slot:SetPoint ("topleft", panel, "topleft", 1, slot.Height)
			
			local classicon = slot:CreateTexture (nil, "overlay")
			local roleicon = slot:CreateTexture (nil, "overlay")
			local assisticon = slot:CreateTexture (nil, "overlay")
			local tankicon = slot:CreateTexture (nil, "overlay")
			local masterlooticon = slot:CreateTexture (nil, "overlay")
			
			classicon:SetSize (slot_iconsize, slot_iconsize)
			roleicon:SetSize (slot_iconsize, slot_iconsize)
			assisticon:SetSize (slot_iconsize, slot_iconsize)
			tankicon:SetSize (slot_iconsize, slot_iconsize)
			masterlooticon:SetSize (slot_iconsize, slot_iconsize)
			
			local playername = slot:CreateFontString (nil, "artwork", "GameFontNormal")
			local playerlevel = slot:CreateFontString (nil, "artwork", "GameFontNormal")
			local playerclass = slot:CreateFontString (nil, "artwork", "GameFontNormal")
			local empty = slot:CreateFontString (nil, "artwork", "GameFontNormal")
			
			classicon:SetPoint ("left", slot, "left", 1, 0)
			assisticon:SetPoint ("left", classicon, "right", 2, 0)
			tankicon:SetPoint ("left", assisticon, "right", 0, 0)
			masterlooticon:SetPoint ("left", tankicon, "right", 0, 0)
			playername:SetPoint ("left", masterlooticon, "right", 2, 0)
			empty:SetPoint ("center", slot, "center", 0, 0)
			
			roleicon:SetPoint ("left", slot, "left", group_sizeX*0.55, 0)
			playerlevel:SetPoint ("left", roleicon, "right", 2, 0)
			playerclass:SetPoint ("right", slot, "right", -2, 0)
			
			slot.classicon = classicon
			slot.roleicon = roleicon
			slot.assisticon = assisticon
			slot.tankicon = tankicon
			slot.masterlooticon = masterlooticon
			slot.playername = playername
			slot.playerlevel = playerlevel
			slot.playerclass = playerclass
			slot.empty = empty
			
			RaidGroups:SetFontColor (empty, .2, .2, .2, .8)
			RaidGroups:SetFontSize (empty, 10)
			empty:SetText ("Empty")
			empty:Hide()
			
			slot:SetScript ("OnDragStart", OnDragStart)
			slot:SetScript ("OnDragStop", OnDragStop)
			
			slot:SetScript ("OnEnter", OnEnter)
			slot:SetScript ("OnLeave", OnLeave)
			
			tinsert (panel.Slots, slot)
			slot.Id = o
			slot.Id_Raid = index
			
			index = index + 1
		end
		
		x = x + group_sizeX + 4
		if (i%2 == 0) then
			x = 0
			y = y - group_sizeY - group_spacing_vertical
		end
		
	end
	
	--> lock frame while syncing
	local lock_frame = CreateFrame ("frame", nil, frame)
	lock_frame:SetFrameStrata ("TOOLTIP")
	lock_frame:SetPoint ("topleft", RaidGroups.RaidGroups[1], "topleft", 0, 0)
	lock_frame:SetPoint ("bottomright", RaidGroups.RaidGroups[8], "bottomright", 0, 0)
	lock_frame:SetBackdrop ({edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize = 1, bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tileSize = 64, tile = true})
	lock_frame:SetBackdropColor (0, 0, 0, 0.8)
	lock_frame:SetBackdropBorderColor (0, 0, 0, 1)
	lock_frame:EnableMouse (true)
	lock_frame:Hide()
	RaidGroups.lock_frame = lock_frame
	--
	
	local apply_frame = CreateFrame ("frame", nil, UIParent)
	
	RaidGroups.CanGoNext = true

	local sync_after_apply = function() 
		RaidGroups.Sync()
	end
	local current_applying_index
	local timeelapsed = 0
	local apply_on_update = function (self, elapsed)
		
		if (InCombatLockdown() or UnitAffectingCombat ("player")) then
			RaidGroups:Msg ("You are in combat and cannot move players through raid groups.")
			apply_frame:SetScript ("OnUpdate", nil)
			unlock_frame_after_sync()
			return
		end
		
		local playerVirtual = RaidGroups.VirtualGroups [current_applying_index]
		timeelapsed = timeelapsed + elapsed
		
		if (playerVirtual) then
			if (RaidGroups.CanGoNext or timeelapsed > 1) then
			
				if (timeelapsed > 1) then
					RaidGroups:Msg ("Server answer timeout, check your latency.")
				end
			
				--> get the current player information from the raid roster
				local raidIndex, name, rank, subgroup = get_player_raidInfo (playerVirtual [ROSTER_PLAYERNAME]) --get from the original roster
				
				--print (index, playerVirtual [ROSTER_PLAYERNAME], playerVirtual [ROSTER_RAIDGROUP], subgroup, name)
				
				if (raidIndex) then
					--> algo saiu errado, o grupo n�o foi atualizado?
					--RaidGroups.Sync()
					--apply_frame:SetScript ("OnUpdate", nil)
					--print ("Algo saiu errado, o grupo n�o era o mesmo...")
					--return

					--> if the player is on a different group on the virtual roster, we need to move he on the original roster
					if (subgroup ~= playerVirtual [ROSTER_RAIDGROUP]) then
						local amt = get_amtPlayers_onRaidGroup (playerVirtual [ROSTER_RAIDGROUP])
						
						--print (name, amt, "do grupo", subgroup, "para", playerVirtual [ROSTER_RAIDGROUP])
						
						if (amt == 5) then
							--need to swap somebody, find who don't belong to the group and remove him
							local intruder = get_groupIntruderIndex (playerVirtual [ROSTER_RAIDGROUP]) -- is 1
							if (not UnitAffectingCombat ("raid" .. raidIndex)) then
								SwapRaidSubgroup (raidIndex, intruder)
							else
								RaidGroups:Msg ("Could not move " .. (UnitName ("raid" .. raidIndex) or "") .. " (unit in combat).")
							end
							RaidGroups.CanGoNext = false
						else
							-- keyspell esta sendo movido do grupo 1 para o 8.
							--print ("setting raid group for ", name, raidIndex, playerVirtual [ROSTER_RAIDGROUP], "PPL on group:", amt)
							if (not UnitAffectingCombat ("raid" .. raidIndex)) then
								SetRaidSubgroup (raidIndex, playerVirtual [ROSTER_RAIDGROUP])
							else
								RaidGroups:Msg ("Could not move " .. (UnitName ("raid" .. raidIndex) or "") .. " (unit in combat).")
							end
							RaidGroups.CanGoNext = false
						end
					end
				end
				
				current_applying_index = current_applying_index + 1
				timeelapsed = 0
			end
		else
			apply_frame:SetScript ("OnUpdate", nil)
			C_Timer.After (1, sync_after_apply)
		end
		
	end
	
	local apply_func = function()
		--> build the cache
		wipe (group_cache)
		for index, player in ipairs (RaidGroups.VirtualGroups) do
			group_cache [player [ROSTER_PLAYERNAME]] = player [ROSTER_RAIDGROUP]
		end
		
		current_applying_index, RaidGroups.CanGoNext, timeelapsed = 1, true, 0
		apply_frame:SetScript ("OnUpdate", apply_on_update)
		RaidGroups.lock_frame:Show()
	end
	
	local check_combat_tick = 0
	local apply_onupdate = function (self, elapsed)
		check_combat_tick = check_combat_tick + elapsed
		if (check_combat_tick > 0.2) then
			check_combat_tick = 0
			
			if (InCombatLockdown()) then
				--print ("i'm in combat")
				self.MyObject:Disable()
				RaidGroups.alert_incombat_label:Show()
				return
			end
			
			for i = 1, GetNumGroupMembers() do
				if (UnitAffectingCombat ("raid" .. i)) then
					--print ("raid member in combat")
					self.MyObject:Disable()
					RaidGroups.alert_incombat_label:Show()
					return
				end
			end
			
			--print ("no body is in combat")
			self.MyObject:Enable()
			RaidGroups.alert_incombat_label:Hide()
		end
	end
	
	local right_panel_x = 490
	
	local apply_button =  RaidGroups:CreateButton (frame, apply_func, 100, 20, "Apply", _, _, _, "button_apply", _, _, RaidGroups:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"), RaidGroups:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
	apply_button:SetPoint ("topleft", frame, "topleft", right_panel_x, 0)
	apply_button:SetScript ("OnUpdate", apply_onupdate)
	apply_button:SetIcon ([[Interface\BUTTONS\UI-CheckBox-Check]], 16, 16, "overlay", {0, 1, 0, 28/32}, {1, 1, 1}, 2, 1, 0)

	local sync_func = function()
		RaidGroups.lock_frame:Show()
		RaidGroups.Sync()
		RaidGroups.lock_frame:Hide()
	end
	local sync_button =  RaidGroups:CreateButton (frame, sync_func, 100, 20, "Refresh", _, _, _, "button_sync", _, _, RaidGroups:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"), RaidGroups:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
	sync_button:SetPoint ("left", apply_button, "right", 6, 0)
	sync_button:SetIcon ([[Interface\BUTTONS\UI-RefreshButton]], 14, 14, "overlay", {0, 1, 0, 1}, {1, 1, 1}, 2, 1, 0)

	local alert_incombat_label = RaidGroups:CreateLabel (frame, "Raid Member In Combat", RaidGroups:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"), _, _, "label_filter1")
	alert_incombat_label:SetPoint ("left", sync_button, "right", 20, 0)
	alert_incombat_label.textcolor = "red"
	alert_incombat_label:Hide()
	RaidGroups.alert_incombat_label = alert_incombat_label
	
	--> build options
	
	local on_select_text_font = function (self, fixed_value, value)
		RaidGroups.db.text_font = value
		RaidGroups.UpdateRosterFrames()
	end
	
	local options_list = {
		{
			type = "range",
			get = function() return RaidGroups.db.text_size end,
			set = function (self, fixedparam, value) 
				RaidGroups.db.text_size = value
				RaidGroups.UpdateRosterFrames()
			end,
			min = 4,
			max = 32,
			step = 1,
			name = L["S_PLUGIN_TEXT_SIZE"],
			
		},
		{
			type = "select",
			get = function() return RaidGroups.db.text_font end,
			values = function() 
				return RaidGroups:BuildDropDownFontList (on_select_text_font) 
			end,
			name = L["S_PLUGIN_TEXT_FONT"],
			
		},
		{
			type = "toggle",
			get = function() return RaidGroups.db.text_shadow end,
			set = function (self, fixedparam, value) 
				RaidGroups.db.text_shadow = value
				RaidGroups.UpdateRosterFrames()
			end,
			name = L["S_PLUGIN_TEXT_SHADOW"],
		},
	
		
		{
			type = "toggle",
			get = function() return RaidGroups.db.show_class_name end,
			set = function (self, fixedparam, value) 
				RaidGroups.db.show_class_name = value
				RaidGroups.UpdateRosterFrames()
			end,
			name = "Show Class Name",
		},		
		{
			type = "toggle",
			get = function() return RaidGroups.db.show_level end,
			set = function (self, fixedparam, value) 
				RaidGroups.db.show_level = value
				RaidGroups.UpdateRosterFrames()
			end,
			name = "Show Level",
		},
		{
			type = "toggle",
			get = function() return RaidGroups.db.show_class_icon end,
			set = function (self, fixedparam, value) 
				RaidGroups.db.show_class_icon = value
				RaidGroups.UpdateRosterFrames()
			end,
			name = "Show Class Icon",
		},
		{
			type = "toggle",
			get = function() return RaidGroups.db.show_role_icon end,
			set = function (self, fixedparam, value) 
				RaidGroups.db.show_role_icon = value
				RaidGroups.UpdateRosterFrames()
			end,
			name = "Show Role Icon",
		},
		{
			type = "toggle",
			get = function() return RaidGroups.db.show_rank_icons end,
			set = function (self, fixedparam, value) 
				RaidGroups.db.show_rank_icons = value
				RaidGroups.UpdateRosterFrames()
			end,
			name = "Show Raid Icons",
		},
	}

	local options_text_template = RaidGroups:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE")
	local options_dropdown_template = RaidGroups:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE")
	local options_switch_template = RaidGroups:GetTemplate ("switch", "OPTIONS_CHECKBOX_TEMPLATE")
	local options_slider_template = RaidGroups:GetTemplate ("slider", "OPTIONS_SLIDER_TEMPLATE")
	local options_button_template = RaidGroups:GetTemplate ("button", "OPTIONS_BUTTON_TEMPLATE")
	
	RaidGroups:SetAsOptionsPanel (frame)
	RaidGroups:BuildMenu (frame, options_list, right_panel_x, -40, 300, true, options_text_template, options_dropdown_template, options_switch_template, true, options_slider_template, options_button_template)

	--> filters
	
	local filter_label = RaidGroups:CreateLabel (frame, "Filter" .. ":", RaidGroups:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"), _, _, "label_filter1")
	local filter_current_label = RaidGroups:CreateLabel (frame, "", RaidGroups:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"), _, _, "label_filter2")
	filter_current_label.textcolor = "orange"
	
	filter_label:SetPoint ("topleft", frame, "topleft", right_panel_x, -285)
	filter_current_label:SetPoint ("left", filter_label, "right", 2, 0)
	RaidGroups.CurrentFilter = filter_current_label
	
	local filters = {
		["HEALER"] = "Healer",
		["TANK"] = "Tank",
		["DPS"] = "Dps",
	}
	
	function RaidGroups.UpdateFilterLabel()
		filter_current_label.text = filters [RaidGroups.db.filter] or ""
	end
	
	local apply_filter_func = function (button, mousebutton, filter, filterName)	
		if (filter == RaidGroups.db.filter) then
			filter = false
		end
		RaidGroups.db.filter = filter
		RaidGroups.UpdateFilterLabel()
		RaidGroups.UpdateVirtualGroups()
	end
	local clear_filter_button =  RaidGroups:CreateButton (frame, apply_filter_func, 6, 20, "X", false, _, _, "button_clear_sync", _, _, RaidGroups:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"), RaidGroups:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
	clear_filter_button:SetPoint ("topleft", frame, "topleft", right_panel_x, -300)
	
	local healer_filter_button =  RaidGroups:CreateButton (frame, apply_filter_func, 60, 20, "Healers", "HEALER", _, _, "button1_sync", _, _, RaidGroups:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"), RaidGroups:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
	healer_filter_button:SetPoint ("left", clear_filter_button, "right", 2, 0)
	local tank_filter_button =  RaidGroups:CreateButton (frame, apply_filter_func, 60, 20, "Tanks", "TANK", _, _, "button2_sync", _, _, RaidGroups:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"), RaidGroups:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
	tank_filter_button:SetPoint ("left", healer_filter_button, "right", 2, 0)
	local dps_filter_button =  RaidGroups:CreateButton (frame, apply_filter_func, 60, 20, "Dps", "DPS", _, _, "button3_sync", _, _, RaidGroups:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"), RaidGroups:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
	dps_filter_button:SetPoint ("left", tank_filter_button, "right", 2, 0)
	
	RaidGroups.UpdateRosterFrames()
	RaidGroups.Sync()
end

-- slot idraid = 1 to 40
-- slot id = 1 to 5 (group only)
-- panel.group = raid group number

function RaidGroups.Clear()
	for _, group_frame in ipairs (RaidGroups.RaidGroups) do
		group_frame.nextSlot = 1
		for _, slot in ipairs (group_frame.Slots) do
			slot.classicon:SetTexture (nil)
			slot.roleicon:SetTexture (nil)
			slot.assisticon:SetTexture (nil)
			slot.playername:SetText ("")
			slot.RosterIndex = nil
			slot.GotFilteredOut = nil
			slot:SetAlpha (1)
			slot:SetBackdrop (slot_backdrop)
			slot:SetBackdropColor (unpack (slot_backdropcolor))
			slot:SetBackdropBorderColor (unpack (slot_bordercolor))
		end
	end
	
	wipe (RaidGroups.VirtualGroups)
end

function RaidGroups.UpdatePlayer (raidIndex, name, rank, subgroup, level, class, className, zone, online, isDead, role, isML)
	local group_frame = RaidGroups.RaidGroups [subgroup]
	local slot_number = group_frame.nextSlot
	
	if (slot_number <= 5) then
		
		local slot = group_frame.Slots [slot_number]
		
		local coords = CLASS_ICON_TCOORDS [className]
		local color = RAID_CLASS_COLORS [className]
		
		slot.classicon:SetTexture ([[Interface\ARENAENEMYFRAME\UI-CLASSES-CIRCLES]])
		slot.classicon:SetTexture ([[Interface\WorldStateFrame\ICONS-CLASSES]])
		slot.classicon:SetTexCoord (unpack (coords))
		
		if (rank == 2) then
			slot.assisticon:SetTexture ([[Interface\GROUPFRAME\UI-Group-LeaderIcon]])
		elseif (rank == 1) then
			slot.assisticon:SetTexture ([[Interface\GROUPFRAME\UI-GROUP-ASSISTANTICON]])
		else
			slot.assisticon:SetTexture (nil)
		end
		
		if (role == "MAINASSIST") then
			slot.tankicon:SetTexture ([[Interface\GROUPFRAME\UI-GROUP-MAINASSISTICON]])
		elseif (role == "MAINTANK") then
			slot.tankicon:SetTexture ([[Interface\GROUPFRAME\UI-GROUP-MAINTANKICON]])
		else
			slot.tankicon:SetTexture (nil)
		end
		
		if (isML) then
			slot.masterlooticon:SetTexture ([[Interface\GROUPFRAME\UI-Group-MasterLooter]])
		else
			slot.masterlooticon:SetTexture (nil)
		end
		
		local role = DF.UnitGroupRolesAssigned (name)
		if (role == "DAMAGER") then
			slot.roleicon:SetTexture ([[Interface\LFGFrame\UI-LFG-ICON-PORTRAITROLES]])
			slot.roleicon:SetTexCoord (20/64, 39/64, 22/64, 41/64)
		elseif (role == "HEALER") then
			slot.roleicon:SetTexture ([[Interface\LFGFrame\UI-LFG-ICON-PORTRAITROLES]])
			slot.roleicon:SetTexCoord (20/64, 39/64, 1/64, 20/64)
		elseif (role == "TANK") then
			slot.roleicon:SetTexture ([[Interface\LFGFrame\UI-LFG-ICON-PORTRAITROLES]])
			slot.roleicon:SetTexCoord (0/64, 19/64, 22/64, 41/64)
		else	
			slot.roleicon:SetTexture (nil)
		end
		
		--
		slot.playername:SetText (RaidGroups:RemoveRealName (name))
		slot.playerlevel:SetText (level ~= 0 and level or "")		
		local unitClass = UnitClass (name)
		slot.playerclass:SetText (unitClass)
		
		while (slot.playerclass:GetStringWidth() > 45) do
			unitClass = unitClass:sub (1, #unitClass-1)
			slot.playerclass:SetText (unitClass)
		end

		if (online) then
			RaidGroups:SetFontColor (slot.playername, color.r, color.g, color.b, 1)
			RaidGroups:SetFontColor (slot.playerlevel, color.r, color.g, color.b, 1)
			RaidGroups:SetFontColor (slot.playerclass, color.r, color.g, color.b, 1)
		else
			RaidGroups:SetFontColor (slot.playername, .4, .4, .4)
			RaidGroups:SetFontColor (slot.playerlevel, .4, .4, .4)
			RaidGroups:SetFontColor (slot.playerclass, .4, .4, .4)
		end
		
		
		--> filters
		
		slot:SetBackdrop (slot_backdrop)
		slot:SetBackdropColor (unpack (slot_backdropcolor_filled))
		slot:SetBackdropBorderColor (unpack (slot_bordercolor_filled))
		slot:SetAlpha (1)
		slot.GotFilteredOut = nil
		
		local filter = RaidGroups.db.filter

		if (filter) then
			local got_filtered = false
			
			if (filter == "HEALER") then
				if (role == "HEALER") then
					slot:SetBackdropBorderColor (unpack (slot_bordercolor_filtered))
					got_filtered = true
				end
			elseif (filter == "TANK") then
				if (role == "TANK") then
					slot:SetBackdropBorderColor (unpack (slot_bordercolor_filtered))
					got_filtered = true
				end
			elseif (filter == "DPS" or filter == "DAMAGER") then
				if (role == "DAMAGER") then
					slot:SetBackdropBorderColor (unpack (slot_bordercolor_filtered))
					got_filtered = true
				end
			end
			
			if (not got_filtered) then
				slot:SetAlpha (0.3)
			else
				slot.GotFilteredOut = true
			end
		end
		slot.RosterIndex = raidIndex
	end
	
	group_frame.nextSlot = group_frame.nextSlot + 1
end

--dom

function RaidGroups.UpdateVirtualGroups()
	for _, group_frame in ipairs (RaidGroups.RaidGroups) do
		group_frame.nextSlot = 1
		for _, slot in ipairs (group_frame.Slots) do
			--icons
			slot.classicon:SetTexture (nil)
			slot.roleicon:SetTexture (nil)
			slot.tankicon:SetTexture (nil)
			slot.assisticon:SetTexture (nil)
			slot.masterlooticon:SetTexture (nil)
			--texts
			slot.playername:SetText ("")
			slot.playerclass:SetText ("")
			slot.playerlevel:SetText ("")
			--clear index
			slot.RosterIndex = nil
			slot.GotFilteredOut = nil
			slot:SetAlpha (1)
			slot:SetBackdrop (slot_backdrop)
			slot:SetBackdropColor (unpack (slot_backdropcolor))
			slot:SetBackdropBorderColor (unpack (slot_bordercolor))
			
			slot.empty:Hide()
		end
	end
	
	--> bring raid leader to first index of the group
	for index, slot in ipairs (RaidGroups.VirtualGroups) do
		--> is the leader ?
		if (slot [ROSTER_RAIDRANK] == 2) then
			local leader_group = slot [ROSTER_RAIDGROUP]
			local leader_new_index = index
			for i = index-1, 1, -1 do
				local player = RaidGroups.VirtualGroups [i]
				if (player and player [ROSTER_RAIDGROUP] == leader_group) then
					leader_new_index = i
				else
					break
				end
			end
			if (leader_new_index ~= index) then
				--> move the leader
				tremove (RaidGroups.VirtualGroups, index)
				tinsert (RaidGroups.VirtualGroups, leader_new_index, slot)
			end
			break
		end
	end
	
	for index, slot in ipairs (RaidGroups.VirtualGroups) do
		RaidGroups.UpdatePlayer (index, unpack (slot))
	end
	
	for _, group_frame in ipairs (RaidGroups.RaidGroups) do
		for _, slot in ipairs (group_frame.Slots) do
			if (not slot.RosterIndex) then
				slot.empty:Show()
				slot:SetBackdropColor (unpack (slot_backdropcolor))
			else
				slot:SetBackdropColor (unpack (slot_backdropcolor_filled))
			end
		end
	end
end

function RaidGroups.Sync (no_wait)
	RaidGroups.Clear()
	C_Timer.After (0.3, unlock_frame_after_sync)
	RaidGroups.lock_frame:Show()
	
	local raid_leader_group, leader_roster_info, leader_correct_index
	for i = 1, GetNumGroupMembers() do
		local name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML = GetRaidRosterInfo (i)
		--> solve the leader group cheating
		if (raid_leader_group and raid_leader_group <= subgroup) then
			leader_correct_index = i
			raid_leader_group = nil
		end
		
		--> is the raid leader?
		if (i == 1 and rank == 2  and subgroup ~= 1) then 
			--> raid leader cheats the raidIndex
			raid_leader_group = subgroup
			leader_roster_info = {GetRaidRosterInfo (i)}
		else
			tinsert (RaidGroups.VirtualGroups, {GetRaidRosterInfo (i)})
			--> RaidGroups.VirtualGroups [i] = {GetRaidRosterInfo (i)} --has to be tinsert or first index is NIL due to raid leader
		end
	end
	
	--> if the leader was the latest player in the raid group
	if (raid_leader_group) then
		leader_correct_index = #RaidGroups.VirtualGroups+1
		raid_leader_group = nil
	end

	if (leader_correct_index) then
		tinsert (RaidGroups.VirtualGroups, leader_correct_index, leader_roster_info)
	end
	
	RaidGroups.UpdateVirtualGroups()
end

function RaidGroups:PARTY_MEMBERS_CHANGED()
	RaidGroups.CanGoNext = true

	--print ("roster update 1", RaidGroups.GroupsFrame, RaidGroups.GroupsFrame and RaidGroups.GroupsFrame:IsShown())
	if (RaidGroups.GroupsFrame and RaidGroups.GroupsFrame:IsShown()) then
		--print ("roster update 2")
		--for i = 1, GetNumGroupMembers() do
		--	RaidGroups.VirtualGroups [i] = {GetRaidRosterInfo (i)}
		--end
		--RaidGroups.Sync()
	end
	
	--> verifica pessoas que sairam do grupo e atualiza automaticamente
--[[
	for i = #RaidGroups.VirtualGroups, 1, -1 do
		local name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML = unpack (RaidGroups.VirtualGroups [i])
		
		if (not UnitInRaid (name)) then
			tremove ()
		end
	end
	RaidGroups.VirtualGroups, {GetRaidRosterInfo (i)}
--]]	
end

function RaidGroups:RAID_ROSTER_UPDATE()
	RaidGroups:PARTY_MEMBERS_CHANGED()
end


if (can_install) then
	local install_status = RA:InstallPlugin ("Raid Groups", "RARaidGroups", RaidGroups, default_config)
end

SLASH_RaidGroups1, SLASH_RaidGroups2 = "/raidgroups", "/groups"
function SlashCmdList.RaidGroups (msg, editbox)
	if (not IsInRaid ()) then
		return RaidGroups:Msg ("You aren't in a raid group.")
	elseif (not UnitIsGroupLeader ("player")) then
		return RaidGroups:Msg ("You aren't the group leader.")
	end

	--open

end

--raidUI on AddOns
