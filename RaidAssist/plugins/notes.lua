
-- envia para as demais pessoas da raide.

local DF = DetailsFramework
local RA = RaidAssist
local L = LibStub ("AceLocale-3.0"):GetLocale ("RaidAssistAddon")
local _
local default_priority = 20

if (_G ["RaidAssistNotepad"]) then
	return
end
local Notepad = {version = 1, pluginname = "Notes"}
_G ["RaidAssistNotepad"] = Notepad

local default_config = {
	notes = {},
	currently_shown = false,
	text_size = 12,
	text_face = "Friz Quadrata TT",
	text_justify = "left",
	text_shadow = false,
	framestrata = "LOW",
	locked = false,
	background = {r=0, g=0, b=0, a=0.3, show = true},
	hide_on_combat = false,
	auto_format = true,
	auto_complete = false,
}


local icon_texture
local icon_texcoord = {l=4/32, r=28/32, t=4/32, b=28/32}
local text_color_enabled = {r=1, g=1, b=1, a=1}
local text_color_disabled = {r=0.5, g=0.5, b=0.5, a=1}

local COMM_QUERY_SEED = "NOQI"
local COMM_QUERY_NOTE = "NOQN"
local COMM_RECEIVED_SEED = "NORI"
local COMM_RECEIVED_FULLNOTE = "NOFN"

local is_raid_leader = function (sourceUnit)
	if (type (sourceUnit) == "string") then
		return UnitIsGroupLeader (sourceUnit) or UnitIsGroupLeader (sourceUnit:gsub ("%-.*", "")) or Notepad:UnitHasAssist (sourceUnit) or Notepad:UnitHasAssist (sourceUnit:gsub ("%-.*", ""))
	end
end
local is_connected = function (sourceUnit)
	if (type (sourceUnit) == "string") then
		return UnitIsConnected (sourceUnit) or UnitIsConnected (sourceUnit:gsub ("%-.*", ""))
	end
end

if (UnitFactionGroup("player") == "Horde") then
	icon_texture = [[Interface\WorldStateFrame\HordeFlag]]
else
	icon_texture = [[Interface\WorldStateFrame\AllianceFlag]]
end

Notepad.menu_text = function (plugin)
	if (Notepad.db.enabled) then
		return icon_texture, icon_texcoord, "Raid Assignments", text_color_enabled
	else
		return icon_texture, icon_texcoord, "Raid Assignments", text_color_disabled
	end
end

Notepad.menu_popup_show = function (plugin, ct_frame, param1, param2)
	RA:AnchorMyPopupFrame (Notepad)
end

Notepad.menu_popup_hide = function (plugin, ct_frame, param1, param2)
	Notepad.popup_frame:Hide()
end

Notepad.menu_on_click = function (plugin)
	--if (not Notepad.options_built) then
	--	Notepad.BuildOptions()
	--	Notepad.options_built = true
	--end
	--Notepad.main_frame:Show()
	
	RA.OpenMainOptions (Notepad)
end

Notepad.OnInstall = function (plugin)
	
	Notepad.db.menu_priority = default_priority
	
	local popup_frame = Notepad.popup_frame
	
	-- title frame
	local screen_frame = RA:CreateCleanFrame (Notepad, "NotepadScreenFrame")
	Notepad.screen_frame = screen_frame
	screen_frame:SetSize (250, 20)
	screen_frame:SetClampedToScreen (true)
	screen_frame:Hide()
	screen_frame:EnableMouse(true)
	
	-------
	
	local title_text = screen_frame:CreateFontString (nil, "overlay", "GameFontNormal")
	title_text:SetText ("Raid Assignments (/raa)")
	title_text:SetTextColor (.8, .8, .8, 1)
	title_text:SetPoint ("center", screen_frame, "center")
	screen_frame.title_text = title_text
	-------
	
	-- edit box
	local editbox_notes = Notepad:NewSpecialLuaEditorEntry (screen_frame, 250, 200, "editbox_notes", "RaidAssignmentsNoteEditboxScreen", true)
	editbox_notes:SetPoint ("topleft", screen_frame, "bottomleft", 0, 0)
	editbox_notes:SetPoint ("topright", screen_frame, "bottomright", 0, 0)
	editbox_notes:SetBackdrop (nil)
	editbox_notes:SetFrameLevel (screen_frame:GetFrameLevel()+1)
	editbox_notes:SetResizable (true)
	editbox_notes:SetMaxResize (600, 1024)
	editbox_notes:SetMinResize (150, 50)
	editbox_notes:EnableMouse(true)
	
	screen_frame.text = editbox_notes
	
	editbox_notes.editbox:SetTextInsets (2, 2, 3, 3)
	editbox_notes.scroll:ClearAllPoints()
	editbox_notes.scroll:SetPoint ("topleft", editbox_notes, "topleft", 0, 0)
	editbox_notes.scroll:SetPoint ("bottomright", editbox_notes, "bottomright", -26, 0)
	local f, h, fl = editbox_notes.editbox:GetFont()
	editbox_notes.editbox:SetFont (f, 12, fl)
	
	-- background
	local background = editbox_notes:CreateTexture (nil, "background")
	background:SetPoint ("topleft", editbox_notes, "topleft", 0, -5)
	background:SetPoint ("bottomright", editbox_notes, "bottomright", 0, -5)
	screen_frame.background = background
	
	-- resize button
	local resize_button = CreateFrame ("button", nil, screen_frame)
	resize_button:SetPoint ("topleft", editbox_notes, "bottomleft")
	resize_button:SetPoint ("topright", editbox_notes, "bottomright")
	resize_button:SetHeight (16)
	resize_button:SetFrameLevel (screen_frame:GetFrameLevel()+5)
	resize_button:SetBackdrop ({edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize = 1, bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tileSize = 64, tile = true})
	resize_button:SetBackdropColor (0, 0, 0, 0.6)
	resize_button:SetBackdropBorderColor (0, 0, 0, 0)
	screen_frame.resize_button = resize_button
	
	local resize_texture = resize_button:CreateTexture (nil, "overlay")
	resize_texture:SetTexture ([[Interface\CHATFRAME\UI-ChatIM-SizeGrabber-Down]])
	resize_texture:SetPoint ("bottomright", resize_button, "bottomright", 0, 0)
	resize_texture:SetSize (16, 16)
	resize_texture:SetTexCoord (0, 1, 0, 1)
	screen_frame.resize_texture = resize_texture
	
	resize_button:SetScript ("OnMouseDown", function()
		editbox_notes:StartSizing ("bottomright")
	end)
	resize_button:SetScript ("OnMouseUp", function()
		editbox_notes:StopMovingOrSizing()
		screen_frame:SetWidth (editbox_notes:GetWidth())
		editbox_notes:SetPoint ("topleft", screen_frame, "bottomleft", 0, 0)
		editbox_notes:SetPoint ("topright", screen_frame, "bottomright", 0, 0)
	end)
	
	resize_button:SetScript ("OnSizeChanged", function()
		screen_frame:SetWidth (editbox_notes:GetWidth())
		editbox_notes:SetPoint ("topleft", screen_frame, "bottomleft", 0, 0)
		editbox_notes:SetPoint ("topright", screen_frame, "bottomright", 0, 0)
		Notepad.update_scroll_bar()
	end)
	
	RaidAssignmentsNoteEditboxScreenScrollBarThumbTexture:SetTexture (0, 0, 0, 0.4)
	RaidAssignmentsNoteEditboxScreenScrollBarThumbTexture:SetSize (14, 17)
	
	RaidAssignmentsNoteEditboxScreenScrollBarScrollUpButton:SetNormalTexture ([[Interface\Buttons\Arrow-Up-Up]])
	RaidAssignmentsNoteEditboxScreenScrollBarScrollUpButton.Normal = RaidAssignmentsNoteEditboxScreenScrollBarScrollUpButton:GetNormalTexture()
	
	RaidAssignmentsNoteEditboxScreenScrollBarScrollUpButton:SetHighlightTexture ([[Interface\Buttons\Arrow-Up-Up]])
	RaidAssignmentsNoteEditboxScreenScrollBarScrollUpButton.Highlight = RaidAssignmentsNoteEditboxScreenScrollBarScrollUpButton:GetHighlightTexture()

	RaidAssignmentsNoteEditboxScreenScrollBarScrollUpButton:SetPushedTexture ([[Interface\Buttons\Arrow-Up-Down]])
	RaidAssignmentsNoteEditboxScreenScrollBarScrollUpButton.Pushed = RaidAssignmentsNoteEditboxScreenScrollBarScrollUpButton:GetPushedTexture()

	RaidAssignmentsNoteEditboxScreenScrollBarScrollUpButton:SetDisabledTexture ([[Interface\Buttons\Arrow-Up-Disabled]])
	RaidAssignmentsNoteEditboxScreenScrollBarScrollUpButton.Disabled = RaidAssignmentsNoteEditboxScreenScrollBarScrollUpButton:GetDisabledTexture()
	
	RaidAssignmentsNoteEditboxScreenScrollBarScrollDownButton:SetNormalTexture ([[Interface\Buttons\Arrow-Down-Up]])
	RaidAssignmentsNoteEditboxScreenScrollBarScrollDownButton.Normal = RaidAssignmentsNoteEditboxScreenScrollBarScrollDownButton:GetNormalTexture()

	RaidAssignmentsNoteEditboxScreenScrollBarScrollDownButton:SetHighlightTexture ([[Interface\Buttons\Arrow-Down-Up]])
	RaidAssignmentsNoteEditboxScreenScrollBarScrollDownButton.Highlight = RaidAssignmentsNoteEditboxScreenScrollBarScrollDownButton:GetHighlightTexture()

	RaidAssignmentsNoteEditboxScreenScrollBarScrollDownButton:SetPushedTexture ([[Interface\Buttons\Arrow-Down-Down]])
	RaidAssignmentsNoteEditboxScreenScrollBarScrollDownButton.Pushed = RaidAssignmentsNoteEditboxScreenScrollBarScrollDownButton:GetPushedTexture()

	RaidAssignmentsNoteEditboxScreenScrollBarScrollDownButton:SetDisabledTexture ([[Interface\Buttons\Arrow-Down-Disabled]])
	RaidAssignmentsNoteEditboxScreenScrollBarScrollDownButton.Disabled = RaidAssignmentsNoteEditboxScreenScrollBarScrollDownButton:GetDisabledTexture()

	RaidAssignmentsNoteEditboxScreenScrollBarScrollUpButton.Normal:SetTexCoord (0, 1, 0, 1)
	RaidAssignmentsNoteEditboxScreenScrollBarScrollUpButton.Disabled:SetTexCoord (0, 1, 0, 1)
	RaidAssignmentsNoteEditboxScreenScrollBarScrollUpButton.Highlight:SetTexCoord (0, 1, 0, 1)
	RaidAssignmentsNoteEditboxScreenScrollBarScrollUpButton.Pushed:SetTexCoord (0, 1, 0, 1)
	RaidAssignmentsNoteEditboxScreenScrollBarScrollDownButton.Normal:SetTexCoord (0, 1, 0, 1)
	RaidAssignmentsNoteEditboxScreenScrollBarScrollDownButton.Disabled:SetTexCoord (0, 1, 0, 1)
	RaidAssignmentsNoteEditboxScreenScrollBarScrollDownButton.Highlight:SetTexCoord (0, 1, 0, 1)
	RaidAssignmentsNoteEditboxScreenScrollBarScrollDownButton.Pushed:SetTexCoord (0, 1, 0, 1)
	
	-------

	local lock = CreateFrame ("button", "NotepadScreenFrameLockButton", screen_frame)
	lock:SetSize (16, 16)
	lock:SetNormalTexture (Notepad:GetFrameworkFolder() .. "icons")
	lock:SetHighlightTexture (Notepad:GetFrameworkFolder() .. "icons")
	lock:SetPushedTexture (Notepad:GetFrameworkFolder() .. "icons")
	lock:SetAlpha (0.7)
	lock:SetScript ("OnClick", function()
		if (screen_frame:IsMouseEnabled()) then
			Notepad.db.locked = true
			Notepad:UpdateScreenFrameSettings()
		else
			Notepad.db.locked = false
			Notepad:UpdateScreenFrameSettings()
		end
	end)
	screen_frame.lock = lock
	
	local close = CreateFrame ("button", "NotepadScreenFrameCloseButton", screen_frame)
	close:SetSize (16, 16)
	close:SetNormalTexture (Notepad:GetFrameworkFolder() .. "icons")
	close:SetHighlightTexture (Notepad:GetFrameworkFolder() .. "icons")
	close:SetPushedTexture (Notepad:GetFrameworkFolder() .. "icons")
	close:SetAlpha (0.7)
	close:GetPushedTexture():SetTexCoord (0/128, 16/128, 0, 1)
	close:GetNormalTexture():SetTexCoord (0/128, 16/128, 0, 1)
	close:GetHighlightTexture():SetTexCoord (0/128, 16/128, 0, 1)
	close:SetScript ("OnClick", function()
		Notepad.UnshowNoteOnScreen (true)
	end)
	screen_frame.close = close
	
	---------------
	
	local f_anim = CreateFrame ("frame", nil, screen_frame)
	local t = f_anim:CreateTexture (nil, "overlay")
	t:SetTexture (1, 1, 1, 0.25)
	t:SetAllPoints()
	t:SetBlendMode ("ADD")
	local animation = t:CreateAnimationGroup()
	local anim1 = animation:CreateAnimation ("Alpha")
	local anim2 = animation:CreateAnimation ("Alpha")
	local anim3 = animation:CreateAnimation ("Alpha")
	local anim4 = animation:CreateAnimation ("Alpha")
	local anim5 = animation:CreateAnimation ("Alpha")
	
	anim1:SetOrder (1)
	anim1:SetChange(-1)
	anim1:SetDuration (0.0)
	
	anim4:SetOrder (2)
	anim4:SetChange(1)
	anim4:SetDuration (0.2)
	
	anim5:SetOrder (3)
	anim5:SetChange(-1)
	anim5:SetDuration (3)

	animation:SetScript ("OnFinished", function (self)
		f_anim:Hide()
	end)
	
	Notepad.DoFlashAnim = function()
		f_anim:Show()
		f_anim:SetParent (block)
		f_anim:SetPoint ("topleft", editbox_notes, "topleft")
		f_anim:SetPoint ("bottomright", editbox_notes, "bottomright")
		animation:Play()

		if (Notepad.PlayerAFKTicker and Notepad.MouseCursorX and Notepad.MouseCursorY) then
			local x, y = GetCursorPosition()
			if (Notepad.MouseCursorX ~= x or Notepad.MouseCursorY ~= y) then
				if (Notepad.PlayerAFKTicker) then
					Notepad.PlayerAFKTicker:Cancel()
					Notepad.PlayerAFKTicker = nil
				end
			end
		end
	end

	------------------	
	
	Notepad:UpdateScreenFrameSettings()
	
	--C_Timer.After (2, function() Notepad.BuildOptions(); Notepad.options_built = true; Notepad.main_frame:Show() end)
	
	Notepad.playerIsInGroup = IsInGroup()
	
	local _, instanceType = GetInstanceInfo()
	Notepad.current_instanceType = instanceType
	
	Notepad:RegisterEvent ("PARTY_MEMBERS_CHANGED")
	Notepad:RegisterEvent ("ZONE_CHANGED_NEW_AREA")
	Notepad:RegisterEvent ("PLAYER_REGEN_DISABLED")
	Notepad:RegisterEvent ("PLAYER_REGEN_ENABLED")
	
	if (Notepad.db.currently_shown) then
		--print (Notepad.db.currently_shown)
		Notepad:ValidateNoteCurrentlyShown() --only removes, zone_changed has been removed
	end
	
	C_Timer.After (10, function()
		local _, instanceType, DifficultyID = GetInstanceInfo()
		if (instanceType == "raid" and Notepad.playerIsInGroup and DifficultyID ~= 17) then
			Notepad:AskForEnabledNote()
		end
	end)
	
end

function Notepad:UpdateScreenFrameBackground()
	local bg = Notepad.db.background
	if (bg.show) then
		Notepad.screen_frame.background:SetTexture (bg.r, bg.g, bg.b, bg.a)
		Notepad.screen_frame.background:SetHeight (Notepad.screen_frame.text:GetHeight())
	else
		Notepad.screen_frame.background:SetTexture (0, 0, 0, 0)
	end
end

function Notepad:UpdateScreenFrameSettings()
	--font face
	local SharedMedia = LibStub:GetLibrary ("LibSharedMedia-3.0")
	local font = SharedMedia:Fetch ("font", Notepad.db.text_font)
	Notepad:SetFontFace (Notepad.screen_frame.text.editbox, font)
	
	--font size
	Notepad:SetFontSize (Notepad.screen_frame.text.editbox, Notepad.db.text_size)
	
	-- font shadow
	Notepad:SetFontOutline (Notepad.screen_frame.text.editbox, Notepad.db.text_shadow)
	
	--frame strata
	Notepad.screen_frame:SetFrameStrata (Notepad.db.framestrata)
	
	--background show
	Notepad:UpdateScreenFrameBackground()
	
	--frame locked
	if (Notepad.db.locked) then
		Notepad.screen_frame:EnableMouse (false)
		Notepad.screen_frame.lock:GetNormalTexture():SetTexCoord (16/128, 32/128, 0, 1)
		Notepad.screen_frame.lock:GetHighlightTexture():SetTexCoord (16/128, 32/128, 0, 1)
		Notepad.screen_frame.lock:GetPushedTexture():SetTexCoord (16/128, 32/128, 0, 1)
		Notepad.screen_frame.lock:SetAlpha (0.15)
		Notepad.screen_frame.close:SetAlpha (0.15)
		
		Notepad.screen_frame:SetBackdrop (nil)
		
		Notepad.screen_frame.resize_button:Hide()
		Notepad.screen_frame.resize_texture:Hide()
		
		Notepad.screen_frame.title_text:SetTextColor (.8, .8, .8, 0.15)
	else
		Notepad.screen_frame:EnableMouse (true)
		Notepad.screen_frame.lock:GetNormalTexture():SetTexCoord (32/128, 48/128, 0, 1)
		Notepad.screen_frame.lock:GetHighlightTexture():SetTexCoord (32/128, 48/128, 0, 1)
		Notepad.screen_frame.lock:GetPushedTexture():SetTexCoord (32/128, 48/128, 0, 1)
		Notepad.screen_frame.lock:SetAlpha (1)
		Notepad.screen_frame.close:SetAlpha (1)
		Notepad.screen_frame:SetBackdrop ({edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize = 1, bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tileSize = 64, tile = true})
		Notepad.screen_frame:SetBackdropColor (0, 0, 0, 0.8)
		Notepad.screen_frame:SetBackdropBorderColor (0, 0, 0, 1)
		Notepad.screen_frame.resize_button:Show()
		Notepad.screen_frame.resize_texture:Show()
		
		Notepad.screen_frame.title_text:SetTextColor (.8, .8, .8, 1)
	end

	--text justify and lock butotn
	Notepad.screen_frame.text.editbox:SetJustifyH (Notepad.db.text_justify)	
	Notepad.screen_frame.text:ClearAllPoints()
	Notepad.screen_frame.lock:ClearAllPoints()
	Notepad.screen_frame.close:ClearAllPoints()
	
	if (Notepad.db.text_justify == "left") then
		Notepad.screen_frame.lock:SetPoint ("left", Notepad.screen_frame, "left", 0, 0)
		Notepad.screen_frame.close:SetPoint ("left", Notepad.screen_frame.lock, "right", 2, 0)
		Notepad.screen_frame.text:SetPoint ("topleft", Notepad.screen_frame, "bottomleft", 0, 0)
	elseif (Notepad.db.text_justify == "right") then
		Notepad.screen_frame.lock:SetPoint ("right", Notepad.screen_frame, "right", 0, 0)
		Notepad.screen_frame.close:SetPoint ("right", Notepad.screen_frame.lock, "left", 2, 0)
		Notepad.screen_frame.text:SetPoint ("topright", Notepad.screen_frame, "bottomright", -0, 0)
	end
	
	Notepad.screen_frame.text:EnableMouse (false)
	Notepad.screen_frame.text.editbox:EnableMouse (false)
	
end

Notepad.OnEnable = function (plugin)
	-- enabled from the options panel.
	Notepad.db.auto_complete = false
end

Notepad.OnDisable = function (plugin)
	-- disabled from the options panel.
	
end

Notepad.OnProfileChanged = function (plugin)
	if (plugin.db.enabled) then
		Notepad.OnEnable (plugin)
	else
		Notepad.OnDisable (plugin)
	end
	
	if (plugin.options_built) then
		--plugin.main_frame:RefreshOptions()
	end
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function Notepad:GetNoteList()
	return Notepad.db.notes
end

function Notepad:GetNote (note_id)
	return Notepad.db.notes [note_id]
end

local name_feedback_func = function (name)
	Notepad.CreateNewNotepad (_, _, name)
end

function Notepad.CreateNewNotepad (self, button, name)
	if (not name) then
		Notepad:ShowTextPromptPanel ("Enter a Name (to show in the dropdown)", name_feedback_func)
	else
		if (name ~= "") then
			local seed = math.random (10000000, 99999999)
			local newnote = {
				text = "",
				last_edit_date = time(),
				last_edit_by = UnitName ("player"),
				seed = seed,
				boss = Notepad.boss_editing_id,
				name = name,
			}
			Notepad.db.notes [seed] = newnote

			Notepad.main_frame.dropdown_notes:Refresh()
			Notepad.main_frame.dropdown_notes:Select (seed)
			
			Notepad:SetCurrentEditingNote (seed)
		end
	end
	
end

-- ~boss
local list_colors = {{.96, .96, .96}, {1, .8, .2}, {1, 1, .4}, {.8, 1, .2}, {.6, .6, 1}, {1, .4, .4}, {.4, 1, .4}}
function Notepad:BuildBossList()
	local t = {}
	
	--get the list of raids
	local raids = RA:GetRegisteredRaids()
	local raidPool = {}
	
	--put them inside a numeric table
	for mapID, bossList in pairs (raids) do
		tinsert (raidPool, {mapID, bossList})
	end
	
	--sort from the first to last release raid
	table.sort (raidPool, function(t1, t2)
			if t1[1] == 530 then -- ulduar has a lower id than naxx 
				return 537 < t2[1] -- give a fake id of naxx+1
			end
			return t1[1] < t2[1] 
		end)
	
	--fill the dropdown
	for index, table in ipairs (raidPool) do
		local mapID = table[1]
		local bossList = table[2]
		local color = list_colors [index]
		for id, _ in pairs(bossList) do
			t [#t+1] = {label = RA:GetRaidEncounterName(mapID, id), value = mapID .. "_" .. id, onclick = Notepad.OnBossSelection, color = color}
		end
	end
	return t
end

function Notepad:GetBossName (boss_id)
	local instance_id, boss_index = boss_id:match ("(.-)_(.)")
	return RA:GetEncounterName(boss_id)
end

function Notepad:SetCurrentBoss (boss_id)
	self.boss_editing_id = boss_id
	
	Notepad.main_frame.dropdown_notes:Refresh()
	Notepad.main_frame.dropdown_notes:Select (false)
end

function Notepad:SaveCurrentEditingNote()
	local note = Notepad:GetNote (self.notepad_editing_id)
	note.text = Notepad.main_frame.editbox_notes:GetText()
	note.last_edit_by = UnitName ("player")
	note.last_edit_date = time()
end

function Notepad.DeleteCurrentNote()
	--> check if the note isn't the one currently showing on screen.
	if (Notepad.db.currently_shown == Notepad.notepad_editing_id) then
		Notepad.UnshowNoteOnScreen()
	end
	
	local id = Notepad.notepad_editing_id
	
	--> check if the note is enabled.
	Notepad:CancelNoteEditing()
	
	--> erase it
	if id and Notepad.db.notes[id] then
		Notepad.db.notes [id] = nil
	end
end

function Notepad:SetCurrentEditingNote (note_id)
	self.notepad_editing_id = note_id
	
	local main_frame = Notepad.main_frame
	main_frame.button_erase:Enable()
	main_frame.button_cancel:Enable()
	main_frame.button_clear:Enable()
	main_frame.button_save:Enable()
	main_frame.button_save2:Enable()
	main_frame.editbox_notes:Enable()
	main_frame.editbox_notes:SetFocus()
	
	main_frame.button_create:Disable()
	main_frame.dropdown_notes:Disable()
	main_frame.dropdown_boss:Disable()
	
	local note = Notepad:GetNote (note_id)
	
	main_frame.editbox_notes:SetText (note.text)
	Notepad:FormatText()

	Notepad.main_frame.editbox_notes:Show()
	Notepad.main_frame.toptions_panel:Hide()

	if (string.len (note.text) == 0) then
		main_frame.editbox_notes.editbox:SetText ("\n\n\n")
	end
	
	main_frame.editbox_notes.editbox:SetFocus (true)
	main_frame.editbox_notes.editbox:SetCursorPosition (0)
end

function Notepad:GetCurrentEditingNote()
	return self.notepad_editing_id
end

function Notepad:CancelNoteEditing()
	self.notepad_editing_id = nil
	
	local main_frame = Notepad.main_frame
	main_frame.button_erase:Disable()
	main_frame.button_cancel:Disable()
	main_frame.button_clear:Disable()
	main_frame.button_save:Disable()
	main_frame.button_save2:Disable()
	
	main_frame.editbox_notes:SetText ("")
	main_frame.editbox_notes:Disable()	
	
	main_frame.button_create:Enable()
	main_frame.dropdown_notes:Enable()
	main_frame.dropdown_boss:Enable()
	
	Notepad.main_frame.dropdown_notes:Refresh()
	Notepad.main_frame.dropdown_notes:Select (false)
	
	Notepad.main_frame.editbox_notes:Hide()
	Notepad.main_frame.toptions_panel:Show()
end

-- UnitIsGroupAssistant

local update_scroll_bar = function()
	if (RaidAssignmentsNoteEditboxScreenScrollBarScrollDownButton:IsEnabled()) then
		RaidAssignmentsNoteEditboxScreenScrollBar:Show()
	else
		RaidAssignmentsNoteEditboxScreenScrollBar:Hide()
	end
	RaidAssignmentsNoteEditboxScreenScrollBarScrollDownButton:SetScript ("OnUpdate", nil)
end
Notepad.update_scroll_bar = update_scroll_bar

local track_mouse_position = function()
	local x, y = GetCursorPosition()
	if (Notepad.MouseCursorX == x and Notepad.MouseCursorY == y) then
		--> player afk?
		if (not Notepad.PlayerAFKTicker) then
			Notepad.PlayerAFKTicker = C_Timer.NewTicker (5, Notepad.DoFlashAnim, 10)
		end
	end
end

function Notepad:ShowNoteOnScreen (note_id)
	local note = Notepad:GetNote (note_id)
	if (note) then
		Notepad.db.currently_shown = note_id
		
		if (Notepad.UpdateFrameShownOnOptions) then
			Notepad:UpdateFrameShownOnOptions()
		end
		
		Notepad.screen_frame:Show()
		
		local formated_text = Notepad:FormatText (note.text)
		local player_name = UnitName ("player")
		
		local locclass, class = UnitClass ("player")
		
		Notepad.screen_frame.text:SetText (formated_text)
		
		RaidAssignmentsNoteEditboxScreenScrollBarScrollDownButton:SetScript ("OnUpdate", update_scroll_bar)
		C_Timer.After (0.5, update_scroll_bar)
		
		RaidAssignmentsNoteEditboxScreenScrollBar:SetValue (0)
		
		Notepad.DoFlashAnim()
		
		Notepad.MouseCursorX, Notepad.MouseCursorY = GetCursorPosition()
		
		C_Timer.After (3, track_mouse_position)
		
		Notepad:UpdateScreenFrameBackground()
	end
end

function Notepad.UnshowNoteOnScreen (from_close_button)
	if (Notepad.db.currently_shown) then
		Notepad.db.currently_shown = false
		
		if (Notepad.options_built) then
			Notepad.main_frame.frame_note_shown:Hide()
		end

		Notepad.screen_frame:Hide()
		
		if (Notepad.main_frame.frame_note_shown) then
			Notepad.main_frame.frame_note_shown:Hide()
		end

		if (from_close_button and type (from_close_button) == "boolean") then
			if (is_raid_leader ("player")) then
				RA:ShowPromptPanel ("Close it on All Raid Members as Well?", function() Notepad:SendUnShowNote() end, function() end)
			end
		end
	end
end

function Notepad:ValidateNoteCurrentlyShown()
	if (IsInRaid()) then
		return Notepad:ZONE_CHANGED_NEW_AREA() --has been removed
	elseif (not IsInRaid()) then
		return Notepad.UnshowNoteOnScreen()
	end
end

function Notepad:PARTY_MEMBERS_CHANGED()
	if (Notepad.playerIsInGroup and not IsInGroup()) then
		--> left the group
		Notepad.UnshowNoteOnScreen()
	elseif (not Notepad.playerIsInGroup and IsInGroup()) then
		--> joined a group
		local _, instanceType = GetInstanceInfo()
		if (instanceType and instanceType == "raid") then
			Notepad:AskForEnabledNote()
		end
	end
	Notepad.playerIsInGroup = IsInGroup()
end

function Notepad:ZONE_CHANGED_NEW_AREA()
--	local _, instanceType = GetInstanceInfo()
	
--	if (Notepad.playerIsInGroup and Notepad.current_instanceType ~= "raid") then -- instanceType == "raid" and 
--		Notepad:AskForEnabledNote()
--	else
--		Notepad.UnshowNoteOnScreen()
--	end
	
--	local _, instanceType = GetInstanceInfo()
--	Notepad.current_instanceType = instanceType
end

function Notepad:PLAYER_REGEN_DISABLED()
	if (Notepad.db.hide_on_combat and (InCombatLockdown() or UnitAffectingCombat ("player")) and Notepad.db.currently_shown and not Notepad.main_frame:IsShown()) then
		Notepad.screen_frame.on_combat = true
		Notepad.screen_frame:Hide()
	end
end

function Notepad:PLAYER_REGEN_ENABLED()
	if (Notepad.db.currently_shown and Notepad.screen_frame.on_combat) then
		Notepad.screen_frame:Show()
		Notepad.screen_frame.on_combat = nil
	end
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function Notepad.OnShowOnOptionsPanel()
	local OptionsPanel = Notepad.OptionsPanel
	Notepad.BuildOptions (OptionsPanel)
end

function Notepad.BuildOptions (frame)
	
	if (frame.FirstRun) then
		return
	end
	frame.FirstRun = true
	
	local main_frame = frame
	main_frame:SetSize (640, 480)
	main_frame:EnableMouse(true)
	Notepad.main_frame = main_frame

	main_frame:SetScript ("OnShow", function()
		if (Notepad.db.currently_shown) then
			Notepad:UpdateFrameShownOnOptions()
			if (Notepad.screen_frame.on_combat) then
				Notepad.screen_frame:Show()
			end
		else
			main_frame.frame_note_shown:Hide()
		end
	end)
	
	main_frame:SetScript ("OnHide", function()
		Notepad:PLAYER_REGEN_DISABLED()
	end)
	
	local toptions_panel = CreateFrame ("frame", "NotepadTextOptionsPanel", main_frame)
	main_frame.toptions_panel = toptions_panel
	toptions_panel:SetSize (446, 375)
	--toptions_panel:SetBackdrop ({edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize = 1, bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tileSize = 64, tile = true})
	--toptions_panel:SetBackdropColor (0, 0, 0, 0.4)
	--toptions_panel:SetBackdropBorderColor (0, 0, 0, 1)

	local on_select_text_font = function (self, fixed_value, value)
		Notepad.db.text_font = value
		Notepad:UpdateScreenFrameSettings()
	end
	local on_select_text_anchor = function (self, fixed_value, value)
		Notepad.db.text_justify = value
		Notepad:UpdateScreenFrameSettings()
	end
	local text_anchor_options = {
		{value = "left", label = L["S_ANCHOR_LEFT"], onclick = on_select_text_anchor},
		{value = "right", label = L["S_ANCHOR_RIGHT"], onclick = on_select_text_anchor},
	}
	local set_frame_strata = function (_, _, strata)
		Notepad.db.framestrata = strata
		Notepad:UpdateScreenFrameSettings()
	end
	local strataTable = {}
	strataTable [1] = {value = "BACKGROUND", label = "BACKGROUND", onclick = set_frame_strata}
	strataTable [2] = {value = "LOW", label = "LOW", onclick = set_frame_strata}
	strataTable [3] = {value = "MEDIUM", label = "MEDIUM", onclick = set_frame_strata}
	strataTable [4] = {value = "HIGH", label = "HIGH", onclick = set_frame_strata}
	strataTable [5] = {value = "DIALOG", label = "DIALOG", onclick = set_frame_strata}
	
	local options_list = {
	
		{type = "label", get = function() return "Text:" end, text_template = Notepad:GetTemplate ("font", "ORANGE_FONT_TEMPLATE")},
		
		{
			type = "range",
			get = function() return Notepad.db.text_size end,
			set = function (self, fixedparam, value) 
				Notepad.db.text_size = value
				Notepad:UpdateScreenFrameSettings()
			end,
			min = 4,
			max = 32,
			step = 1,
			name = L["S_PLUGIN_TEXT_SIZE"],
			
		},
		{
			type = "select",
			get = function() return Notepad.db.text_font end,
			values = function() return Notepad:BuildDropDownFontList (on_select_text_font) end,
			name = L["S_PLUGIN_TEXT_FONT"],
			
		},
		{
			type = "select",
			get = function() return Notepad.db.text_justify end,
			values = function() return text_anchor_options end,
			name = L["S_PLUGIN_TEXT_ANCHOR"],
		},
		{
			type = "toggle",
			get = function() return Notepad.db.text_shadow end,
			set = function (self, fixedparam, value) 
				Notepad.db.text_shadow = value
				Notepad:UpdateScreenFrameSettings()
			end,
			name = L["S_PLUGIN_TEXT_SHADOW"],
		},
		
		--
		{
			type = "blank",
		},
		--
		{type = "label", get = function() return "Frame:" end, text_template = Notepad:GetTemplate ("font", "ORANGE_FONT_TEMPLATE")},
		--
		{
			type = "select",
			get = function() return Notepad.db.framestrata end,
			values = function() return strataTable end,
			name = "Frame Strata"
		},
		{
			type = "toggle",
			get = function() return Notepad.db.locked end,
			set = function (self, fixedparam, value) 
				Notepad.db.locked = value
				Notepad:UpdateScreenFrameSettings()
			end,
			desc = L["S_PLUGIN_FRAME_LOCKED_DESC"],
			name = L["S_PLUGIN_FRAME_LOCKED"],
			
		},
		{
			type = "toggle",
			get = function() return Notepad.db.background.show end,
			set = function (self, fixedparam, value) 
				Notepad.db.background.show = value
				Notepad:UpdateScreenFrameSettings()
			end,
			desc = "",
			name = "Frame Background",
			
		},
		{
			type = "color",
			get = function() 
				return {Notepad.db.background.r, Notepad.db.background.g, Notepad.db.background.b, Notepad.db.background.a} 
			end,
			set = function (self, r, g, b, a) 
				local color = Notepad.db.background
				color.r, color.g, color.b, color.a = r, g, b, a
				Notepad:UpdateScreenFrameSettings()
			end,
			name = "Background Color",
			
		},
	}
	
	local options_text_template = Notepad:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE")
	local options_dropdown_template = Notepad:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE")
	local options_switch_template = Notepad:GetTemplate ("switch", "OPTIONS_CHECKBOX_TEMPLATE")
	local options_slider_template = Notepad:GetTemplate ("slider", "OPTIONS_SLIDER_TEMPLATE")
	local options_button_template = Notepad:GetTemplate ("button", "OPTIONS_BUTTON_TEMPLATE")
	
	Notepad:SetAsOptionsPanel (toptions_panel)
	Notepad:BuildMenu (toptions_panel, options_list, 10, -12, 300, true, options_text_template, options_dropdown_template, options_switch_template, true, options_slider_template, options_button_template)

	----------
	
	local frame_note_shown = CreateFrame ("frame", nil, main_frame)
	frame_note_shown:SetPoint ("topleft", main_frame, "topleft", 10, -138)
	frame_note_shown:SetSize (160, 43)
	frame_note_shown:SetBackdrop ({edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize = 1, bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tileSize = 64, tile = true})
	frame_note_shown:SetBackdropColor (1, 1, 1, .5)
	frame_note_shown:SetBackdropBorderColor (0, 0, 0, 1)
	frame_note_shown:Hide()
	
	main_frame.frame_note_shown = frame_note_shown
	
	--> currently showing note
	local label_note_shown1 = Notepad:CreateLabel (frame_note_shown, "Showing on screen" .. ":", Notepad:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"), _, _, "label_note_show1")
	local label_note_shown2 = Notepad:CreateLabel (frame_note_shown, "", Notepad:GetTemplate ("font", "ORANGE_FONT_TEMPLATE"), _, _, "label_note_show2")
	label_note_shown1:SetPoint (5, -5)
	label_note_shown2:SetPoint (5, -25)
	
	local unsend_button =  Notepad:CreateButton (frame_note_shown, Notepad.UnshowNoteOnScreen, 20, 10, "x", _, _, _, "button_unsend", _, _, Notepad:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"), Notepad:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
	unsend_button:SetSize (10, 10)
	unsend_button:SetPoint (145, -18)
	
	function Notepad:UpdateFrameShownOnOptions()
		local note = Notepad:GetNote (Notepad.db.currently_shown)
		if (note) then
			main_frame.frame_note_shown:Show()
			local boss_name = Notepad:GetBossName (note.boss)
			main_frame.frame_note_shown.label_note_show2.text = boss_name .. " - " .. note.name
		else
			main_frame.frame_note_shown:Hide()
		end
	end
	
	--> dropdown for boss selection
	local label_boss = Notepad:CreateLabel (main_frame, "Boss" .. ":", Notepad:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
	function Notepad.OnBossSelection (self, fixed_value, selected_value)
		Notepad:SetCurrentBoss (selected_value)
	end
	
	local boss_list = Notepad:BuildBossList()
	local build_boss_list = function()
		return boss_list
	end
	local dropdown_boss = Notepad:CreateDropDown (main_frame, build_boss_list, 1, 160, 20, "dropdown_boss", _, Notepad:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"))
	label_boss:SetPoint (10, 0)
	dropdown_boss:SetPoint ("topleft", label_boss, "bottomleft", 0, -5)
	toptions_panel:SetPoint ("topleft", dropdown_boss.widget, "topright", 10, 11)
	
	--> dropdown for note selection
	local label_notes = Notepad:CreateLabel (main_frame, "Assignments Texts" .. ":", Notepad:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
	local on_notepad_selection = function (self, fixed_value, selected_value)
		Notepad:SetCurrentEditingNote (selected_value)
	end
	local build_notes_list = function()
		local t = {}
		for note_id, note_table in pairs (Notepad:GetNoteList()) do
			--print (note_table.boss, Notepad.boss_editing_id)
			if (note_table.boss == Notepad.boss_editing_id) then
				t [#t+1] = {label = note_table.name, value = note_id, onclick = on_notepad_selection, desc = note_table.text}
			end
		end
		return t
	end
	local dropdown_notes = Notepad:CreateDropDown (main_frame, build_notes_list, 1, 160, 20, "dropdown_notes", _, Notepad:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"))
	label_notes:SetPoint (10, -45)
	dropdown_notes:SetPoint ("topleft", label_notes, "bottomleft", 0, -5)

	--> multi line editbox for edit the note
	local editbox_notes = Notepad:NewSpecialLuaEditorEntry (main_frame, 446, 485, "editbox_notes", "RaidAssignmentsNoteEditbox", true)
	editbox_notes:SetPoint ("topleft", dropdown_boss.widget, "topright", 10, 0)
	editbox_notes:SetTemplate (Notepad:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"))
	editbox_notes:SetBackdrop ({edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize = 1, tileSize = 64, tile = true, bgFile = [[Interface\Tooltips\UI-Tooltip-Background]]})
	editbox_notes:SetBackdropBorderColor (0, 0, 0, 0)
	editbox_notes:SetBackdropColor (0.4, 0.4, 0.4, 0.4)
	editbox_notes:EnableMouse(true)
	DetailsFramework:ReskinSlider (editbox_notes.scroll)
	
	-- .scroll .editbox
	
	editbox_notes.editbox:SetTextInsets (2, 2, 3, 3)
	editbox_notes.scroll:ClearAllPoints()
	editbox_notes.scroll:SetPoint ("topleft", editbox_notes, "topleft", 0, 0)
	editbox_notes.scroll:SetPoint ("bottomright", editbox_notes, "bottomright", -24, 0)
	local f, h, fl = editbox_notes.editbox:GetFont()
	editbox_notes.editbox:SetFont (f, 12, fl)
	
	editbox_notes:Hide()
	
	local cancel_edition = function()
		Notepad:CancelNoteEditing()
	end
	
	local clear_editbox = function()
		editbox_notes:SetText ("")
	end
	
	local save_changes = function()
		Notepad:SaveCurrentEditingNote()
		local note_id = Notepad:GetCurrentEditingNote()
		if (note_id == Notepad.db.currently_shown) then
			Notepad:ShowNoteOnScreen (note_id)
			Notepad:SendNote (note_id)
			return true
		end
	end
	
	local save_changes_and_send = function()
		local has_sent = save_changes()
		if (not has_sent) then
			--> call the comm function to send this notepad
			local note_id = Notepad:GetCurrentEditingNote()
			Notepad:ShowNoteOnScreen (note_id)
			Notepad:SendNote (note_id)
		end
	end
	
	local save_changes_and_close = function()
		save_changes()
		Notepad:CancelNoteEditing()
	end
	
	--create new note "New"
	local buttons_y, buttons_width = -520, 70
	
	local create_button = Notepad:CreateButton (main_frame, Notepad.CreateNewNotepad, buttons_width, 20, "New", _, _, _, "button_create", _, _, Notepad:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"), Notepad:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
	create_button:SetPoint ("topleft", main_frame, "topleft", 10 , -90)
	create_button:SetIcon ("Interface\\AddOns\\" .. RA.InstallDir .. "\\media\\plus", 10, 10, "overlay", {0, 1, 0, 1}, {1, 1, 1}, 3, 1, 0)
	create_button.widget.texture_disabled:SetTexture ([[Interface\Tooltips\UI-Tooltip-Background]])
	create_button.widget.texture_disabled:SetVertexColor (0, 0, 0)
	create_button.widget.texture_disabled:SetAlpha (.5)
	
	--delete note "Erase"
	local erase_button =  Notepad:CreateButton (main_frame, Notepad.DeleteCurrentNote, buttons_width, 20, "Erase Note", _, _, _, "button_erase", _, _, Notepad:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"), Notepad:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
	erase_button:SetPoint ("topleft", main_frame, "topleft", 90 , -90)
	erase_button:SetIcon ([[Interface\BUTTONS\UI-StopButton]], 14, 14, "overlay", {0, 1, 0, 1}, {1, 1, 1}, 2, 1, 0)
	erase_button.widget.texture_disabled:SetTexture ([[Interface\Tooltips\UI-Tooltip-Background]])
	erase_button.widget.texture_disabled:SetVertexColor (0, 0, 0)
	erase_button.widget.texture_disabled:SetAlpha (.5)
	
	local ww = 100
	
	--clear "Clear"
	local clear_button =  Notepad:CreateButton (main_frame, clear_editbox, ww, 20, "Clear Text", _, _, _, "button_clear", _, _, Notepad:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"), Notepad:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
	--clear_button:SetPoint ("topleft", main_frame, "topleft", 310 , buttons_y)
	clear_button:SetIcon ([[Interface\Glues\LOGIN\Glues-CheckBox-Check]])
	clear_button.widget.texture_disabled:SetTexture ([[Interface\Tooltips\UI-Tooltip-Background]])
	clear_button.widget.texture_disabled:SetVertexColor (0, 0, 0)
	clear_button.widget.texture_disabled:SetAlpha (.5)
	
	--save "Save"
	local save_button =  Notepad:CreateButton (main_frame, save_changes, ww, 20, "Save", _, _, _, "button_save", _, _, Notepad:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"), Notepad:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
	--save_button:SetPoint ("topleft", main_frame, "topleft", 390, buttons_y)
	--save_button:SetIcon ([[Interface\AddOns\IskarAssist\media\save]], 10, 10, "overlay", {0, 1, 0, 1}, {1, 1, 1}, 4, 1, 0)
	save_button:SetIcon ([[Interface\BUTTONS\UI-CheckBox-Check]], 16, 16, "overlay", {0, 1, 0, 28/32}, {1, 1, 1}, 2, 1, 0)
	save_button.widget.texture_disabled:SetTexture ([[Interface\Tooltips\UI-Tooltip-Background]])
	save_button.widget.texture_disabled:SetVertexColor (0, 0, 0)
	save_button.widget.texture_disabled:SetAlpha (.5)
	
	--save and send "Send"
	local save2_button =  Notepad:CreateButton (main_frame, save_changes_and_send, ww, 20, "Send", _, _, _, "button_save2", _, _, Notepad:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"), Notepad:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
	--save2_button:SetPoint ("topleft", main_frame, "topleft", 470 , buttons_y)
	save2_button:SetIcon ([[Interface\BUTTONS\JumpUpArrow]], 14, 12, "overlay", {0, 1, 0, 32/32}, {1, 1, 1}, 2, 1, 0)
	save2_button.widget.texture_disabled:SetTexture ([[Interface\Tooltips\UI-Tooltip-Background]])
	save2_button.widget.texture_disabled:SetVertexColor (0, 0, 0)
	save2_button.widget.texture_disabled:SetAlpha (.5)
	
	--cancel edition "Done"
	local cancel_button =  Notepad:CreateButton (main_frame, save_changes_and_close, ww, 20, "Done", _, _, _, "button_cancel", _, _, Notepad:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"), Notepad:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
	cancel_button:SetIcon ([[Interface\BUTTONS\UI-CheckBox-Check]], 16, 16, "overlay", {0, 1, 0, 28/32}, {1, 0.8, 0}, 2, 1, 0)
	cancel_button.widget.texture_disabled:SetTexture ([[Interface\Tooltips\UI-Tooltip-Background]])
	cancel_button.widget.texture_disabled:SetVertexColor (0, 0, 0)
	cancel_button.widget.texture_disabled:SetAlpha (.5)
	
	--set points
	cancel_button:SetPoint ("topleft", main_frame, "topleft", 528 , buttons_y)
	save2_button:SetPoint ("right", cancel_button, "left", -16 , 0)
	save_button:SetPoint ("right", save2_button, "left", -16 , 0)
	clear_button:SetPoint ("right", save_button, "left", -16 , 0)
	
	
	main_frame.button_erase:Disable()
	main_frame.button_cancel:Disable()
	main_frame.button_clear:Disable()
	main_frame.button_save:Disable()
	main_frame.button_save2:Disable()
	main_frame.editbox_notes:Disable()
	
	
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--> text format

	--color
	local colors_panel = CreateFrame ("frame", nil, editbox_notes)
	
	
	local get_color_hash = function (t)
		local r = RA:Hex (floor (t[1]*255))
		local g = RA:Hex (floor (t[2]*255))
		local b = RA:Hex (floor (t[3]*255))
		return r .. g .. b
	end
	
	local color_pool

	-- code author Saiket from  http://www.wowinterface.com/forums/showpost.php?p=245759&postcount=6
	--- @return StartPos, EndPos of highlight in this editbox.
	local function GetTextHighlight ( self )
		local Text, Cursor = self:GetText(), self:GetCursorPosition();
		self:Insert( "" ); -- Delete selected text
		local TextNew, CursorNew = self:GetText(), self:GetCursorPosition();
		-- Restore previous text
		self:SetText( Text );
		self:SetCursorPosition( Cursor );
		local Start, End = CursorNew, #Text - ( #TextNew - CursorNew );
		self:HighlightText( Start, End );
		return Start, End;
	end
	local StripColors;
	do
		local CursorPosition, CursorDelta;
		--- Callback for gsub to remove unescaped codes.
		local function StripCodeGsub ( Escapes, Code, End )
			if ( #Escapes % 2 == 0 ) then -- Doesn't escape Code
				if ( CursorPosition and CursorPosition >= End - 1 ) then
					CursorDelta = CursorDelta - #Code;
				end
				return Escapes;
			end
		end
		--- Removes a single escape sequence.
		local function StripCode ( Pattern, Text, OldCursor )
			CursorPosition, CursorDelta = OldCursor, 0;
			return Text:gsub( Pattern, StripCodeGsub ), OldCursor and CursorPosition + CursorDelta;
		end
		--- Strips Text of all color escape sequences.
		-- @param Cursor  Optional cursor position to keep track of.
		-- @return Stripped text, and the updated cursor position if Cursor was given.
		function StripColors ( Text, Cursor )
			Text, Cursor = StripCode( "(|*)(|c%x%x%x%x%x%x%x%x)()", Text, Cursor );
			return StripCode( "(|*)(|r)()", Text, Cursor );
		end
	end
	
	local COLOR_END = "|r";
	--- Wraps this editbox's selected text with the given color.
	local function ColorSelection ( self, ColorCode )
		local Start, End = GetTextHighlight( self );
		local Text, Cursor = self:GetText(), self:GetCursorPosition();
		if ( Start == End ) then -- Nothing selected
			--Start, End = Cursor, Cursor; -- Wrap around cursor
			return; -- Wrapping the cursor in a color code and hitting backspace crashes the client!
		end
		-- Find active color code at the end of the selection
		local ActiveColor;
		if ( End < #Text ) then -- There is text to color after the selection
			local ActiveEnd;
			local CodeEnd, _, Escapes, Color = 0;
			while ( true ) do
				_, CodeEnd, Escapes, Color = Text:find( "(|*)(|c%x%x%x%x%x%x%x%x)", CodeEnd + 1 );
				if ( not CodeEnd or CodeEnd > End ) then
					break;
				end
				if ( #Escapes % 2 == 0 ) then -- Doesn't escape Code
					ActiveColor, ActiveEnd = Color, CodeEnd;
				end
			end
       
			if ( ActiveColor ) then
				-- Check if color gets terminated before selection ends
				CodeEnd = 0;
				while ( true ) do
					_, CodeEnd, Escapes = Text:find( "(|*)|r", CodeEnd + 1 );
					if ( not CodeEnd or CodeEnd > End ) then
						break;
					end
					if ( CodeEnd > ActiveEnd and #Escapes % 2 == 0 ) then -- Terminates ActiveColor
						ActiveColor = nil;
						break;
					end
				end
			end
		end
     
		local Selection = Text:sub( Start + 1, End );
		-- Remove color codes from the selection
		local Replacement, CursorReplacement = StripColors( Selection, Cursor - Start );
     
		self:SetText( ( "" ):join(
			Text:sub( 1, Start ),
			ColorCode, Replacement, COLOR_END,
			ActiveColor or "", Text:sub( End + 1 )
		) );
     
		-- Restore cursor and highlight, adjusting for wrapper text
		Cursor = Start + CursorReplacement;
		if ( CursorReplacement > 0 ) then -- Cursor beyond start of color code
			Cursor = Cursor + #ColorCode;
		end
		if ( CursorReplacement >= #Replacement ) then -- Cursor beyond end of color
			Cursor = Cursor + #COLOR_END;
		end
		
		self:SetCursorPosition( Cursor );
		-- Highlight selection and wrapper
		self:HighlightText( Start, #ColorCode + ( #Replacement - #Selection ) + #COLOR_END + End );
	end	
------------------------------------------------------------------------------------------
	
	local label_colors = Notepad:CreateLabel (colors_panel, "Color" .. ":", Notepad:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
	local on_color_selection = function (self, fixed_value, color_name)
		local DF = _G ["DetailsFramework"]
		local color_table = DF.alias_text_colors [color_name]
		if (color_table) then

			local startpos, endpos = GetTextHighlight ( main_frame.editbox_notes.editbox )
		
			local color = "|cFF" .. get_color_hash (color_table)
			local endcolor = "|r"
			
			if (startpos == endpos) then
				--> no selection
				--ColorSelection ( main_frame.editbox_notes.editbox, color )
				main_frame.editbox_notes.editbox:Insert (color .. endcolor)
				main_frame.editbox_notes.editbox:SetCursorPosition (startpos + 10)
			else
				--> has selection
				ColorSelection ( main_frame.editbox_notes.editbox, color )
				
			end
		end
	end
	
	local build_color_list = function()
		if (not color_pool) then
			color_pool = {}
			local DF = _G ["DetailsFramework"]
			for color_name, color_table in pairs (DF.alias_text_colors) do
				color_pool [#color_pool+1] = {color_name, color_table}
			end
			table.sort (color_pool, function (t1, t2)
				return t1[1] < t2[1]
			end)
			tinsert (color_pool, 1, {"Default Color", {1, 1, 1}})
		end
	
		local t = {}
		for index, color_table in ipairs (color_pool) do
			local color_name, color = unpack (color_table)
			t [#t+1] = {label = "|cFF" .. get_color_hash (color) .. color_name .. "|r", value = color_name, onclick = on_color_selection}
		end
		return t
	end
	local dropdown_colors = Notepad:CreateDropDown (colors_panel, build_color_list, 1, 160, 20, "dropdown_colors", _, Notepad:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"))
	label_colors:SetPoint ("topleft", editbox_notes, "topright", 10, 0)
	dropdown_colors:SetPoint ("topleft", label_colors, "bottomleft", 0, -5)
	
	local index = 1
	local colors = {"white", "silver", "gray", "HUNTER", "WARLOCK", "PRIEST", "PALADIN", "MAGE", "ROGUE", "DRUID", "SHAMAN", "WARRIOR", "DEATHKNIGHT", "MONK", --14
	"darkseagreen", "green", "lime", "yellow", "gold", "orange", "orangered", "red", "magenta", "pink", "deeppink", "violet", "mistyrose", "blue", "darkcyan", "cyan", "lightskyblue", "maroon",
	"peru", "plum", "tan", "wheat"} --4
	for o = 1, 4 do
		for i = 1, 9 do
			local color_button =  Notepad:CreateButton (colors_panel, on_color_selection, 24, 24, "", colors [index], _, _, "button_color" .. index, _, _, Notepad:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"), Notepad:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
			color_button:SetPoint ("topleft", editbox_notes, "topright", 10 + ((i-1)*24), -20 + (o*24*-1))
			local color_texture = color_button:CreateTexture (nil, "background")
			color_texture:SetTexture (Notepad:ParseColors (colors [index]))
			color_texture:SetAlpha (0.7)
			color_texture:SetAllPoints()
			index = index + 1
		end
	end
	
	--~colors
	local current_color = Notepad:CreateLabel (colors_panel, "A", 14, "white", nil, "current_font")
	current_color:SetPoint ("bottomright", dropdown_colors, "topright")
	local do_text_format = function (self, elapsed)
	
		--> color
		local pos = main_frame.editbox_notes.editbox:GetCursorPosition()
		local text = main_frame.editbox_notes.editbox:GetText()

		local cutoff = text:sub (-text:len(), -(text:len() - pos))
		if (cutoff) then
			local i = 0
			local find_color
			local find_end
			while (find_color == nil and find_end == nil and i > -cutoff:len()) do
				i = i - 1
				find_color = cutoff:find ("|cFF", i)
				find_end = cutoff:find ("|r", i)
			end
			
			if (find_end or not find_color) then
				current_color:SetText ("|cFFFFFFFFA|r")
			else
				local color = cutoff:match (".*cFF(.*)")
				if (color) then
					color = color:match ("%x%x%x%x%x%x")
					current_color:SetText ("|cFF" .. color .. "A|r")
				else
					current_color:SetText ("|cFFFFFFFFA|r")
				end
			end
		else
			current_color:SetText ("|cFFFFFFFFA|r")
		end
		
		--> icons
		
	end
	
	
	--raid targets
	local label_raidtargets = Notepad:CreateLabel (colors_panel, "Targets" .. ":", Notepad:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
	label_raidtargets:SetPoint ("topleft", editbox_notes, "topright", 10, -150)
	
	--http://wowwiki.wikia.com/wiki/UI_escape_sequences
	
	--local icon_path = [[|TInterface\TargetingFrame\UI-RaidTargetingIcon_ICONINDEX:12:12|t]]
	--local icon_path = [[|TInterface\TargetingFrame\UI-RaidTargetingIcon_ICONINDEX:12:12:0:-7:64:64:0:64:0:64|t]]
	local icon_path = [[|TInterface\TargetingFrame\UI-RaidTargetingIcon_ICONINDEX:0|t]]
	
	local on_raidtarget_selection = function (self, button, icon_index)
		local startpos, endpos = GetTextHighlight ( main_frame.editbox_notes.editbox )
		local icon = icon_path:gsub ([[ICONINDEX]], icon_index)
		main_frame.editbox_notes.editbox:Insert (icon .. " ")
	end
	
	local index = 1
	for o = 1, 1 do
		for i = 1, 8 do
			local raidtarget =  Notepad:CreateButton (colors_panel, on_raidtarget_selection, 32, 32, "", index, _, _, "button_raidtarget" .. index, _, _, Notepad:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"), Notepad:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
			raidtarget:SetPoint ("topleft", editbox_notes, "topright", 10 + ((i-1)*32), -140 + (o*32*-1))
			local color_texture = raidtarget:CreateTexture (nil, "overlay")
			color_texture:SetTexture ("Interface\\TARGETINGFRAME\\UI-RaidTargetingIcon_" .. index)
			color_texture:SetAlpha (0.7)
			color_texture:SetAllPoints()
			index = index + 1
		end
	end

	--cooldowns
	local label_iconcooldowns = Notepad:CreateLabel (colors_panel, "Cooldowns" .. ":", Notepad:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
	label_iconcooldowns:SetPoint ("topleft", editbox_notes, "topright", 10, -220)
	
	local cooldown_icon_path = [[|TICONPATH:]]..(Notepad.db.text_size * 2)..[[:]]..(Notepad.db.text_size * 2)..[[:0:0:64:64:5:59:5:59|t]]
	--local cooldown_icon_path = [[|TICONPATH:0|t]]
	local on_spellcooldown_selection = function (self, button, spellid)
		local spellname, rank, iconpath = GetSpellInfo (spellid)
		main_frame.editbox_notes.editbox:Insert (cooldown_icon_path:gsub ([[ICONPATH]], iconpath) .. "|Hspell:" .. spellid .."|h|r|cff71d5ff[" .. spellname .. "]|r|h")
	end
	
	local i, o, index = 1, 1, 1
	local spell_added = {} --can be repeated
	
	local button_cooldown_backdrop = {edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize = 1, tileSize = 64, tile = true}
	
	local on_enter_cooldown = function (self)
		local button = self.MyObject
		GameTooltip:SetOwner (self, "ANCHOR_RIGHT")
		GameTooltip:SetHyperlink("spell:"..button.spellid)
		GameTooltip:Show()
	end
	
	local on_leave_cooldown = function (self)
		GameTooltip:Hide()
	end
	
	local class_cooldowns = _G ["RaidAssistCooldowns"].spell_list
	for class, class_table in pairs (class_cooldowns) do
		for spec, spells in pairs (class_table) do 
			for spellid, spellinfo in pairs (spells) do
				
				if (not spell_added [spellid]) then
					local spellname, rank, spellicon = GetSpellInfo (spellid)
				
					local spell =  Notepad:CreateButton (colors_panel, on_spellcooldown_selection, 32, 32, "", spellid, _, _, "button_cooldown" .. index)
					spell:SetBackdrop (button_cooldown_backdrop)
					spell:SetPoint ("topleft", editbox_notes, "topright", 10 + ((i-1)*32), -210 + (o*32*-1))
					spell:SetHook ("OnEnter", on_enter_cooldown)
					spell:SetHook ("OnLeave", on_leave_cooldown)
					spell:EnableMouse(true)
					spell.spellid = spellid
					local spell_texture = spell:CreateTexture (nil, "background")
					spell_texture:SetTexture (spellicon)
					spell_texture:SetTexCoord (5/65, 59/64, 5/65, 59/64)
					spell_texture:SetAlpha (0.7)
					spell_texture:SetAllPoints()
					
					local class_color = RAID_CLASS_COLORS [class]
					spell:SetBackdropBorderColor (class_color.r, class_color.g, class_color.b)
					
					index = index + 1
					i = i +1
					if (i == 10) then
						i = 1
						o = o + 1
					end
					spell_added [spellid] = true
				end
			end
		end
	end
	
	--boss spells
	local label_iconbossspells = Notepad:CreateLabel (colors_panel, "Boss Abilities" .. ":", Notepad:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
	label_iconbossspells:SetPoint ("topleft", editbox_notes, "topright", 10, -243)
	
	--local bossspell_icon_path = [[|TICONPATH:12:12:0:0:64:64:5:59:5:59|t]]
	local bossspell_icon_path = [[|TICONPATH:0|t]]
	local bossspell_icon_path_noformat = [[||TICONPATH:0||t]]
	local on_bossspell_selection = function (self, button)
		local spellname, rank, iconpath = GetSpellInfo (self.MyObject.spellid)
		if (Notepad.db.auto_format) then
			main_frame.editbox_notes.editbox:Insert (bossspell_icon_path:gsub ([[ICONPATH]], iconpath) .. " " .. spellname)
		else
			main_frame.editbox_notes.editbox:Insert (bossspell_icon_path_noformat:gsub ([[ICONPATH]], iconpath) .. " " .. spellname)
		end
	end	
	
	local button_bossspell_backdrop = {edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize = 1, tileSize = 64, tile = true}
	
	local on_enter_bossspell = function (self)
		local button = self.MyObject
		GameTooltip:SetOwner (self, "ANCHOR_RIGHT")
		GameTooltip:SetHyperlink("spell:"..button.spellid)
		GameTooltip:Show()
	end
	
	local on_leave_bossspell = function (self)
		GameTooltip:Hide()
	end
	
	local boss_abilities_buttons = {}
	function Notepad:UpdateBossAbilities()
		for buttonid, button in ipairs (boss_abilities_buttons) do
			button:Hide()
		end
		local bossid = Notepad.boss_editing_id and Notepad.boss_editing_id:gsub (".*_", "")
		local raidID = Notepad.boss_editing_id and Notepad.boss_editing_id:gsub ("_.*", "")
		
		bossid = tonumber (bossid)
		raidID = tonumber (raidID)
		
		if (bossid) then
			
			local bossEJID = RA:GetBossIds (raidID, bossid)
			local spells = nil
			
		--	local ejid, combatlogid = Notepad:GetBossIds (raidID, bossid)
		--	local spells = Notepad:GetBossSpellList (ejid)
			
			if (spells) then
				local button_index = 1
				local i, o = 1, 1
				local alreadyAdded = {}
				
				for index, spellid in ipairs (spells) do

					local spellname, _, spellicon = GetSpellInfo (spellid)
				
					if (spellname and not alreadyAdded [spellname]) then
						alreadyAdded [spellname] = true
				
						local button = boss_abilities_buttons [button_index]
						if (not button) then
							button =  Notepad:CreateButton (colors_panel, on_bossspell_selection, 18, 18, "", spellid, _, _, "button_bossspell" .. button_index)
							button.spell_texture = button:CreateTexture (nil, "background")
							boss_abilities_buttons [button_index] = button
							button:SetHook ("OnEnter", on_enter_bossspell)
							button:SetHook ("OnLeave", on_leave_bossspell)
							button:EnableMouse(true)
							button:SetBackdrop (button_bossspell_backdrop)
							button:SetPoint ("topleft", editbox_notes, "topright", 10 + ((i-1)*19), -238 + (o*19*-1))
						end
						
						button.spellid = spellid
						
						button.spell_texture:SetTexture (spellicon)
						button.spell_texture:SetTexCoord (5/65, 59/64, 5/65, 59/64)
						button.spell_texture:SetAlpha (0.7)
						button.spell_texture:SetAllPoints()
						
						button:Show()
						
						button_index = button_index + 1
						i = i +1
						if (i == 10) then
							i = 1
							o = o + 1
						end
					end
				end
			end
		end
	end

	
	--keywords
	local label_keywords = Notepad:CreateLabel (colors_panel, "Keywords" .. ":", Notepad:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
	label_keywords:SetPoint ("topleft", editbox_notes, "topright", 10, -450)
	
	local localized_keywords = {"Cooldowns", "Phase", "Dispell", "Interrupt", "Adds", "Personals", "Second Pot At", "Tanks", "Dps", "Healers"}
	
	if (UnitFactionGroup("player") == "Horde") then
		tinsert (localized_keywords, "Bloodlust At")
	else
		tinsert (localized_keywords, "Heroism At")
	end
	
	local on_keyword_selection = function (self, button, keyword)
		main_frame.editbox_notes.editbox:Insert (keyword .. ":")
	end
	
	local i, o, index = 1, 1, 1
	local button_keyword_backdrop = {edgeSize = 1, tileSize = 64, tile = true, bgFile = [[Interface\Tooltips\UI-Tooltip-Background]]}
	
	local on_enter_keyword = function (self)
		local button = self.MyObject
		button.textcolor = "orange"
	end
	
	local on_leave_keyword = function (self)
		local button = self.MyObject
		button.textcolor = "white"
	end
	
	for index, keyword in pairs (localized_keywords) do
		local keyword_button =  Notepad:CreateButton (colors_panel, on_keyword_selection, 80, 24, keyword, keyword, _, _, "button_keyword" .. index, nil, 1) --short method 1
		keyword_button:SetBackdrop (button_keyword_backdrop)
		keyword_button:SetBackdropColor (0, 0, 0, 0.4)
		keyword_button:SetPoint ("topleft", editbox_notes, "topright", 8 + ((i-1)*85), -450 + (o*24*-1))
		keyword_button:SetHook ("OnEnter", on_enter_keyword)
		keyword_button:SetHook ("OnLeave", on_leave_keyword)
		keyword_button:EnableMouse(true)
		keyword_button.textsize = 14
		keyword_button.textface = "Friz Quadrata TT"
		keyword_button.textcolor = "white"
		keyword_button.textalign = "<"
		keyword_button.keyword = keyword

		index = index + 1
		i = i +1
		if (i == 3) then
			i = 1
			o = o + 1
		end
	end
	
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------



	local func = function (self, fixedparam, value) 
		Notepad.db.auto_format = value
		Notepad:FormatText()
	end
	local checkbox = Notepad:CreateSwitch (colors_panel, func, Notepad.db.auto_format, _, _, _, _, _, "NotepadFormatCheckBox", _, _, _, _, Notepad:GetTemplate ("switch", "OPTIONS_CHECKBOX_TEMPLATE"), Notepad:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
	checkbox:SetAsCheckBox()
	checkbox.tooltip = "auto format text"
	checkbox:SetPoint ("bottomleft", editbox_notes, "topleft")
	checkbox:SetValue (Notepad.db.auto_format)
	local label_autoformat = Notepad:CreateLabel (colors_panel, "Auto Format Text (|cFFC0C0C0can't copy/paste icons|r)", Notepad:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
	label_autoformat:SetPoint ("left", checkbox, "right", 2, 0)
	
	local func = function (self, fixedparam, value) 
		Notepad.db.auto_complete = value
	end
	local checkbox2 = Notepad:CreateSwitch (colors_panel, func, Notepad.db.auto_complete, _, _, _, _, _, "NotepadAutoCompleteCheckBox", _, _, _, _, Notepad:GetTemplate ("switch", "OPTIONS_CHECKBOX_TEMPLATE"), Notepad:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
	checkbox2:SetAsCheckBox()
	checkbox2.tooltip = "auto format text"
	checkbox2:SetPoint ("bottomleft", editbox_notes, "topleft", 250, 0)
	checkbox2:SetValue (Notepad.db.auto_complete)
	local label_autocomplete = Notepad:CreateLabel (colors_panel, "Auto Complete Player Names", Notepad:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
	label_autocomplete:SetPoint ("left", checkbox2, "right", 2, 0)
	
	
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	
	editbox_notes:SetScript ("OnShow", function()
		colors_panel:SetScript ("OnUpdate", do_text_format)
		Notepad:UpdateBossAbilities()
	end)
	editbox_notes:SetScript ("OnHide", function()
		colors_panel:SetScript ("OnUpdate", nil)
	end)
	
	dropdown_boss:Refresh()
	dropdown_boss:Select (1, true)
	Notepad.boss_editing_id = dropdown_boss.value
	dropdown_notes:Refresh()
	dropdown_notes:Select (false)
	
	local lastword, characters_count = "", 0

	local get_last_word = function()
		lastword = ""
		local cursor_pos = main_frame.editbox_notes.editbox:GetCursorPosition()
		local text = main_frame.editbox_notes.editbox:GetText()
		for i = cursor_pos, 1, -1 do
			local character = text:sub (i, i)
			if (character:match ("%a")) then
				lastword = character .. lastword
			else
				break
			end
		end
	end
	
	editbox_notes.editbox:SetScript ("OnTextChanged", function (self)
		local chars_now = main_frame.editbox_notes.editbox:GetText():len()
		--> backspace
		if (chars_now == characters_count -1) then
			lastword = lastword:sub (1, lastword:len()-1)
		--> delete lots of text
		elseif (chars_now < characters_count) then
			main_frame.editbox_notes.editbox.end_selection = nil
			get_last_word()
		end
		characters_count = chars_now
	end)
	
	editbox_notes.editbox:SetScript ("OnSpacePressed", function (self)
		main_frame.editbox_notes.editbox.end_selection = nil
	end)
	editbox_notes.editbox:HookScript ("OnEscapePressed", function (self) 
		main_frame.editbox_notes.editbox.end_selection = nil
	end)
	
	editbox_notes.editbox:SetScript ("OnEnterPressed", function (self) 
		if (main_frame.editbox_notes.editbox.end_selection) then
			main_frame.editbox_notes.editbox:SetCursorPosition (main_frame.editbox_notes.editbox.end_selection)
			main_frame.editbox_notes.editbox:HighlightText (0, 0)
			main_frame.editbox_notes.editbox.end_selection = nil
			main_frame.editbox_notes.editbox:Insert (" ")
		else
			main_frame.editbox_notes.editbox:Insert ("\n")
		end
		
		lastword = ""
	end)
	
	editbox_notes.editbox:SetScript ("OnEditFocusGained", function (self) 
		get_last_word()
		main_frame.editbox_notes.editbox.end_selection = nil
		characters_count = main_frame.editbox_notes.editbox:GetText():len()
	end)

	editbox_notes.editbox:SetScript ("OnChar", function (self, char) 
		main_frame.editbox_notes.editbox.end_selection = nil
	
		if (main_frame.editbox_notes.editbox.ignore_input) then
			return
		end
		if (char:match ("%a")) then
			lastword = lastword .. char
		else
			lastword = ""
		end
		
		main_frame.editbox_notes.editbox.ignore_input = true
		if (lastword:len() >= 2 and false) then
			for i = 1, GetNumGroupMembers() do
				local name = UnitName ("raid" .. i) or UnitName ("party" .. i)
				--print (name, string.find ("keyspell", "^key"))
				if (name and (name:find ("^" .. lastword) or name:lower():find ("^" .. lastword))) then
					local rest = name:gsub (lastword, "")
					rest = rest:lower():gsub (lastword, "")
					local cursor_pos = self:GetCursorPosition()
					main_frame.editbox_notes.editbox:Insert (rest)
					main_frame.editbox_notes.editbox:HighlightText (cursor_pos, cursor_pos + rest:len())
					main_frame.editbox_notes.editbox:SetCursorPosition (cursor_pos)
					main_frame.editbox_notes.editbox.end_selection = cursor_pos + rest:len()
					break
				end
			end
		end
		main_frame.editbox_notes.editbox.ignore_input = false
	end)
	
end

function Notepad:FormatText (mytext)
	local text = mytext
	if (not text) then
		text = Notepad.main_frame.editbox_notes.editbox:GetText()
	end
	
	if (Notepad.db.auto_format or mytext) then
		-- format the text, show icons
		text = text:gsub ("{Star}", [[|TInterface\TargetingFrame\UI-RaidTargetingIcon_1:0|t]])
		text = text:gsub ("{Circle}", [[|TInterface\TargetingFrame\UI-RaidTargetingIcon_2:0|t]])
		text = text:gsub ("{Diamond}", [[|TInterface\TargetingFrame\UI-RaidTargetingIcon_3:0|t]])
		text = text:gsub ("{Triangle}", [[|TInterface\TargetingFrame\UI-RaidTargetingIcon_4:0|t]])
		text = text:gsub ("{Moon}", [[|TInterface\TargetingFrame\UI-RaidTargetingIcon_5:0|t]])
		text = text:gsub ("{Square}", [[|TInterface\TargetingFrame\UI-RaidTargetingIcon_6:0|t]])
		text = text:gsub ("{Cross}", [[|TInterface\TargetingFrame\UI-RaidTargetingIcon_7:0|t]])
		text = text:gsub ("{Skull}", [[|TInterface\TargetingFrame\UI-RaidTargetingIcon_8:0|t]])
		text = text:gsub ("{rt1}", [[|TInterface\TargetingFrame\UI-RaidTargetingIcon_1:0|t]])
		text = text:gsub ("{rt2}", [[|TInterface\TargetingFrame\UI-RaidTargetingIcon_2:0|t]])
		text = text:gsub ("{rt3}", [[|TInterface\TargetingFrame\UI-RaidTargetingIcon_3:0|t]])
		text = text:gsub ("{rt4}", [[|TInterface\TargetingFrame\UI-RaidTargetingIcon_4:0|t]])
		text = text:gsub ("{rt5}", [[|TInterface\TargetingFrame\UI-RaidTargetingIcon_5:0|t]])
		text = text:gsub ("{rt6}", [[|TInterface\TargetingFrame\UI-RaidTargetingIcon_6:0|t]])
		text = text:gsub ("{rt7}", [[|TInterface\TargetingFrame\UI-RaidTargetingIcon_7:0|t]])
		text = text:gsub ("{rt8}", [[|TInterface\TargetingFrame\UI-RaidTargetingIcon_8:0|t]])
		
		text = text:gsub ("||c", "|c")
		text = text:gsub ("||r", "|r")
		text = text:gsub ("||t", "|t")
		text = text:gsub ("||T", "|T")
		
	else
		--> show plain text
		--> replace the raid target icons:
		text = text:gsub ([[|TInterface\TargetingFrame\UI%-RaidTargetingIcon_1:0|t]], "{Star}")
		text = text:gsub ([[|TInterface\TargetingFrame\UI%-RaidTargetingIcon_2:0|t]], "{Circle}")
		text = text:gsub ([[|TInterface\TargetingFrame\UI%-RaidTargetingIcon_3:0|t]], "{Diamond}")
		text = text:gsub ([[|TInterface\TargetingFrame\UI%-RaidTargetingIcon_4:0|t]], "{Triangle}")
		text = text:gsub ([[|TInterface\TargetingFrame\UI%-RaidTargetingIcon_5:0|t]], "{Moon}")
		text = text:gsub ([[|TInterface\TargetingFrame\UI%-RaidTargetingIcon_6:0|t]], "{Square}")
		text = text:gsub ([[|TInterface\TargetingFrame\UI%-RaidTargetingIcon_7:0|t]], "{Cross}")
		text = text:gsub ([[|TInterface\TargetingFrame\UI%-RaidTargetingIcon_8:0|t]], "{Skull}")

		--> escape sequences
		text = text:gsub ("|c", "||c")
		text = text:gsub ("|r", "||r")
		text = text:gsub ("|t", "||t")
		text = text:gsub ("|T", "||T")
	end

	--> passed a text, so just return a formated text
	if (mytext) then
		return text
	else
		Notepad.main_frame.editbox_notes.editbox:SetText (text)
	end
end

local install_status = RA:InstallPlugin ("Raid Assignments", "RANotepad", Notepad, default_config)

-- new feature: quick note

--> mandar primeiro o a nota/texto
--> depois mandar o id para mostrar


function NotepadRefreshScreenFrame (boss_id, note_id)
	-- refresh the screen frame options
end

--> when the user enters in the raid instance or after /reload or logon
local do_ask_for_enabled_note = function()
	local raidLeader = Notepad:GetRaidLeader()
	if (raidLeader) then
		Notepad:SendPluginCommWhisperMessage (COMM_QUERY_SEED, raidLeader, nil, nil, Notepad:GetPlayerNameWithRealm())
	end
end
function Notepad:AskForEnabledNote()
	local zoneName, zoneType, _, _, _, _, _, zoneMapID = GetInstanceInfo()
	if (IsInRaid()) then -- zoneType == "raid" and 
		--> make it safe calling with a delay in case many users enter/connect at the same time
		C_Timer.After (math.random (3), do_ask_for_enabled_note) -- 15
	end
end

function Notepad.OnReceiveComm (prefix, sourcePluginVersion, sourceUnit, fullNote, noteSeed, noteDate)
	local ZoneName, InstanceType, DifficultyID = GetInstanceInfo()
	if (DifficultyID and DifficultyID == 17) then
		return
	end
	
	--> Full Note - the user received a note from the Raid Leader
	if (prefix == COMM_RECEIVED_FULLNOTE) then
		--> check if the sender is the raid leader
		if ((not IsInRaid() and not IsInGroup()) or not is_raid_leader (sourceUnit)) then
			return
		end
		
		--> validade the note
		if (not fullNote) then
			--> hide any note shown
			local current_note = Notepad.db.currently_shown
			if (current_note) then
				Notepad.UnshowNoteOnScreen()
			end
			return
		end
		
		if (not fullNote.seed or not fullNote.last_edit_date) then
			return
		end	
		
		local noteSeed, noteDate = fullNote.seed, fullNote.last_edit_date

		--> update the note and show it on the screen
		Notepad.db.notes [noteSeed] = fullNote
		
		if (Notepad.main_frame and Notepad.main_frame:IsShown()) then
			Notepad.main_frame.dropdown_notes:Refresh()
			Notepad.main_frame.dropdown_notes:Select (noteSeed)
		end
		
		Notepad:ShowNoteOnScreen (noteSeed)
		
	--> Query note current status - the user sent to the raid leader a query about the current note
	elseif (prefix == COMM_QUERY_SEED) then --"NOQI"
		--> check if I'm the raid leader
		if ((not IsInRaid() and not IsInGroup()) or not is_raid_leader ("player")) then
			return
		end
		
		--> sent the current state for the player
		if (is_connected (sourceUnit)) then
			local current_note = Notepad.db.currently_shown
			if (current_note) then
				local note = Notepad:GetNote (current_note)
				Notepad:SendPluginCommWhisperMessage (COMM_RECEIVED_SEED, sourceUnit, nil, nil, Notepad:GetPlayerNameWithRealm(), nil, note.seed, note.last_edit_date)
			else
				Notepad:SendPluginCommWhisperMessage (COMM_RECEIVED_FULLNOTE, sourceUnit, nil, nil, Notepad:GetPlayerNameWithRealm())
			end
		end

	--> Query hasn been answered by the raid leader - the user now has the current note state
	elseif (prefix == COMM_RECEIVED_SEED) then --"NORI"
		--> check if the answer came from the raid leader
		if ((not IsInRaid() and not IsInGroup()) or not is_raid_leader (sourceUnit)) then
			return
		end

		--> no note is currently shown
		if (not noteSeed or type (noteSeed) ~= "number" or not noteDate or type (noteDate) ~= "number") then
			return
		end

		--> check if we have the current note
		local note = Notepad:GetNote (noteSeed)
		if (not note) then
			--> if not, we have to request the note from the raid leader
			local raidLeader = Notepad:GetRaidLeader()
			if (raidLeader and is_connected (raidLeader)) then
				Notepad:SendPluginCommWhisperMessage (COMM_QUERY_NOTE, raidLeader, nil, nil, Notepad:GetPlayerNameWithRealm())
			end
			return
		end
	
		--> check if the note we have is up to date
		if (note.last_edit_date < noteDate) then
			--> if not, we have to request the note from the raid leader
			local raidLeader = Notepad:GetRaidLeader()
			if (raidLeader and is_connected (raidLeader)) then
				Notepad:SendPluginCommWhisperMessage (COMM_QUERY_NOTE, raidLeader, nil, nil, Notepad:GetPlayerNameWithRealm())
			end
			return
		end
		
		--> we have the note and it is up to date, show it on the screen
		Notepad:ShowNoteOnScreen (noteSeed)
		
	--> Request Note - the user received the current state and doesn't have the current note, request it from the raid leader
	elseif (prefix == COMM_QUERY_NOTE) then --"NOQN"
		--> check if I'm the raid leader
		if ((not IsInRaid() and not IsInGroup()) or not is_raid_leader ("player")) then
			return
		end
		
		if (is_connected (sourceUnit)) then
			local current_note = Notepad.db.currently_shown
			if (current_note) then
				local note = Notepad:GetNote (current_note)
				Notepad:SendPluginCommWhisperMessage (COMM_RECEIVED_FULLNOTE, sourceUnit, nil, nil, Notepad:GetPlayerNameWithRealm(), note)
			else
				--> if no note is shown, just send an empty FULLNOTE
				Notepad:SendPluginCommWhisperMessage (COMM_RECEIVED_FULLNOTE, sourceUnit, nil, nil, Notepad:GetPlayerNameWithRealm())
			end
		end
		
	end

end

--> send and receive notes:
	-- Full Note - the raid leader sent a note to be shown on the screen
	
	RA:RegisterPluginComm (COMM_RECEIVED_FULLNOTE, Notepad.OnReceiveComm)
--> query a Note or ID and Time:
	-- Request Current ID - received by the raid leader, asking about the current note state (id and time)
	RA:RegisterPluginComm (COMM_QUERY_SEED, Notepad.OnReceiveComm)
	-- Received Current ID - raid leader response with the current note id and time
	RA:RegisterPluginComm (COMM_RECEIVED_SEED, Notepad.OnReceiveComm)
	-- Request Note - request a full note with a ID
	RA:RegisterPluginComm (COMM_QUERY_NOTE, Notepad.OnReceiveComm)

function Notepad:SendUnShowNote()
	-- send a signal to hide the current note shown
	
	-- is raid leader?
	if (is_raid_leader ("player") and (IsInRaid() or IsInGroup())) then
		if (IsInRaid()) then
			Notepad:SendPluginCommMessage (COMM_RECEIVED_FULLNOTE, "RAID", nil, nil, Notepad:GetPlayerNameWithRealm(), nil)
		else
			Notepad:SendPluginCommMessage (COMM_RECEIVED_FULLNOTE, "PARTY", nil, nil, Notepad:GetPlayerNameWithRealm(), nil)
		end
	end
end

function Notepad:SendNote (note_id)
	-- send the note for other people in the raid
	
	-- is raid leader?
	if (is_raid_leader ("player") and (IsInRaid() or IsInGroup())) then
	
		local ZoneName, InstanceType, DifficultyID, _, _, _, _, ZoneMapID = GetInstanceInfo()
		if (DifficultyID and DifficultyID == 17) then
			--> it's raid finder
			return
		end
	
		-- send the note?
		local note = Notepad:GetNote (note_id)
		if (note) then
			if (IsInRaid()) then
				Notepad:SendPluginCommMessage (COMM_RECEIVED_FULLNOTE, "RAID", nil, nil, Notepad:GetPlayerNameWithRealm(), note)
			else
				Notepad:SendPluginCommMessage (COMM_RECEIVED_FULLNOTE, "PARTY", nil, nil, Notepad:GetPlayerNameWithRealm(), note)
			end
		end
	end
	
end
