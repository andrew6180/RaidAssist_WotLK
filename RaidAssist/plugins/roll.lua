local RA = RaidAssist
local L = LibStub ("AceLocale-3.0"):GetLocale ("RaidAssistAddon")

local ROLL_PATTERN = RANDOM_ROLL_RESULT

local IsRaidOfficer = IsRaidOfficer
local IsInRaid = IsInRaid
local IsInGroup = IsInGroup
local tsort = table.sort


ROLL_PATTERN = string.gsub(ROLL_PATTERN, "[%(%)%-%+%[%]]", "%%%1")
ROLL_PATTERN = string.gsub(ROLL_PATTERN, "%%s", "(.-)")
ROLL_PATTERN = string.gsub(ROLL_PATTERN, "%%d", "%(%%d-%)")
ROLL_PATTERN = string.gsub(ROLL_PATTERN, "%%%d%$s", "(.-)")
ROLL_PATTERN = string.gsub(ROLL_PATTERN, "%%%d$d", "%(%%d-%)")

local default_priority = 1
local default_config = {
	enabled = true,
	menu_priority = 1,
	
	show_window_after = 0.9,
	text_size = 10,
	text_face = "Friz Quadrata TT",
	text_shadow = false,
}

local Roll = {version = "v0.1", pluginname = "Roll Handler"}
_G ["RaidAssistRoll"] = Roll

local icon_texcoord = {l=0, r=1, t=0, b=1}
local text_color_enabled = {r=1, g=1, b=1, a=1}
local text_color_disabled = {r=0.5, g=0.5, b=0.5, a=1}
local icon_texture = [[Interface\Buttons\UI-GroupLoot-Dice-Up]]
local allow_raid_roll = false

Roll.debug = false

Roll.menu_text = function (plugin)
	if (Roll.db.enabled) then
		return icon_texture, icon_texcoord, "Roll Handler", text_color_enabled
	else
		return icon_texture, icon_texcoord, "Roll Handler", text_color_disabled
	end
end

Roll.menu_popup_show = function (plugin, ct_frame, param1, param2)
	RA:AnchorMyPopupFrame (Roll)
end

Roll.menu_popup_hide = function (plugin, ct_frame, param1, param2)
	Roll.popup_frame:Hide()
end

Roll.menu_on_click = function (plugin)

end

Roll.OnInstall = function (plugin)
	Roll.db.menu_priority = default_priority

	if Roll.db.enabled then 
		Roll.OnEnable(plugin)
	end
end


Roll.OnEnable = function (plugin)
	Roll.activeRoll = {
		rolls = {},
		item = nil,
		rolling = false,
		timers = {}
    }
    if not Roll.Panel then 
        Roll.BuildFrame()
    end

	Roll:RegisterEvent("CHAT_MSG_RAID", Roll.CHAT_MSG)
	Roll:RegisterEvent("CHAT_MSG_PARTY", Roll.CHAT_MSG)
	Roll:RegisterEvent("CHAT_MSG_RAID_WARNING", Roll.CHAT_MSG)
	Roll:RegisterEvent("CHAT_MSG_RAID_LEADER", Roll.CHAT_MSG)
	Roll:RegisterEvent("CHAT_MSG_PARTY_LEADER", Roll.CHAT_MSG)
    Roll:RegisterEvent("CHAT_MSG_SYSTEM", Roll.CHAT_MSG_ROLL)
    
    SLASH_RaidRoll1 = "/raidroll"
    SLASH_RaidRoll2 = "/rr"
    function SlashCmdList.RaidRoll (msg, editbox)
	    Roll.StartRaidRoll()
    end
end

Roll.OnDisable = function (plugin)
    Roll.activeRoll = nil
    if Roll.Panel then 
        Roll.Panel:Hide()
    end
	Roll:UnregisterEvent("CHAT_MSG_RAID", Roll.CHAT_MSG)
	Roll:UnregisterEvent("CHAT_MSG_PARTY", Roll.CHAT_MSG)
	Roll:UnregisterEvent("CHAT_MSG_RAID_WARNING", Roll.CHAT_MSG)
	Roll:UnregisterEvent("CHAT_MSG_RAID_LEADER", Roll.CHAT_MSG)
	Roll:UnregisterEvent("CHAT_MSG_PARTY_LEADER", Roll.CHAT_MSG)
	Roll:UnregisterEvent("CHAT_MSG_SYSTEM", Roll.CHAT_MSG_ROLL)
end

Roll.OnProfileChanged = function (plugin)
	if (plugin.db.enabled) then
		Roll.OnEnable (plugin)
	else
		Roll.OnDisable (plugin)
	end
	
	if (plugin.options_built) then
		
	end
end

function Roll.OnShowOnOptionsPanel()
	local OptionsPanel = Roll.OptionsPanel
	Roll.BuildOptions (OptionsPanel)
end


function Roll.BuildFrame() 
    local frame = Roll:CreateCleanFrame(Roll, "RAARollFrame") 
    frame:SetSize(350, 120)

    local ProgressBar = Roll:CreateBar(frame, nil, 350, 16, 100) 
    ProgressBar:SetFrameLevel(frame:GetFrameLevel()+1)
    ProgressBar.RightTextIsTimer = true 
    ProgressBar.BarIsInverse = true 
    ProgressBar:SetPoint ("topleft", frame, "topleft", 10, -50)
    ProgressBar:SetPoint ("topright", frame, "topright", -10, 50)
    ProgressBar.texture = "Iskar Serenity"

    local itemString = Roll:CreateLabel(frame, "ITEM_NAME")
    itemString:SetPoint("topleft", frame, "topleft", 8, -10)
    Roll:SetFontSize(itemString, 14)
    Roll:SetFontOutline (itemString, true)

    Roll.PlayerList = {}
    local x = 10
    local y = -75
    for i = 1, 40 do 
        local Cross = Roll:CreateImage (frame, "Interface\\Glues\\LOGIN\\Glues-CheckBox-Check", 16, 16, "overlay")
        local Label = Roll:CreateLabel (frame, "Player Name")
        local RollLabel = Roll:CreateLabel(frame, "999")
        Label:SetPoint ("left", Cross, "right", 2, 0)
        RollLabel:SetPoint("left", Label, "right", 2, 0)
        Cross.Label = Label
        Cross.RollLabel = RollLabel
		Cross:SetPoint ("topleft", frame, "topleft", x, y)
		if (i%2 == 0) then
			x = 10
			y = y - 16
		else
			x = 140
		end
		Cross:Hide()
        tinsert (Roll.PlayerList, Cross)
    end
    local ebutton = Roll:CreateButton(frame, Roll.EndRollEarly, 100, 20, "End Roll", _, _, _, "ebutton")
    local cbutton = Roll:CreateButton(frame, Roll.CancelRoll, 100, 20, "Cancel Roll", _, _, _, "cbutton")

    ebutton:SetPoint("bottomleft", frame, "bottomleft", 0, 0)
    cbutton:SetPoint("bottomleft", frame, "bottomleft", 102, 0)

    ebutton:SetFrameLevel(frame:GetFrameLevel() + 1)
    cbutton:SetFrameLevel(ebutton:GetFrameLevel())

    Roll.Panel = frame 
    Roll.ProgressBar = ProgressBar 
    Roll.ItemString = itemString
end


function Roll.BuildOptions (frame)

	if (frame.FirstRun) then
		return
	end
	frame.FirstRun = true
	
	-- options panel
	local options_list = {
		{type = "label", get = function() return "General Options:" end, text_template = Roll:GetTemplate ("font", "ORANGE_FONT_TEMPLATE")},
		{
			type = "toggle",
			get = function() return Roll.db.enabled end,
			set = function (self, fixedparam, value) 
				Roll.db.enabled = value
			end,
			name = "Enabled",
		},
		
		{type = "blank"},
		--{type = "label", get = function() return "Text Settings:" end, text_template = Roll:GetTemplate ("font", "ORANGE_FONT_TEMPLATE")},
		
		{
			type = "range",
			get = function() return Roll.db.roll_time or 25 end,
			set = function (self, fixedparam, value)
				Roll.db.roll_time = value
			end,
			min = 15,
			max = 30,
			step = 1,
			name = "Roll Time",
			
		},

		{
			type = "range", 
			get = function() return Roll.db.reroll_time or 10 end,
			set = function(self, fixedparam, value)
				Roll.db.reroll_time = value
			end,
			min = 10, 
			max = 30,
			step = 1, 
			name = "Reroll Time"
		},
	}
	
	local options_text_template = Roll:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE")
	local options_dropdown_template = Roll:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE")
	local options_switch_template = Roll:GetTemplate ("switch", "OPTIONS_CHECKBOX_TEMPLATE")
	local options_slider_template = Roll:GetTemplate ("slider", "OPTIONS_SLIDER_TEMPLATE")
	local options_button_template = Roll:GetTemplate ("button", "OPTIONS_BUTTON_TEMPLATE")
	
	Roll:SetAsOptionsPanel (frame)
	Roll:BuildMenu (frame, options_list, 0, 0, 300, true, options_text_template, options_dropdown_template, options_switch_template, true, options_slider_template, options_button_template)

	
end

function Roll:StartRaidRoll()
    allow_raid_roll = true
    RandomRoll(1, GetNumGroupMembers())
end

function Roll:DoRaidRoll(roll, high)
	local players = {}
	local msg = ""
	for i = 1, GetNumGroupMembers() do 
		local player = GetRaidRosterInfo(i)
		tinsert(players, i, player)
		msg = msg .. " (#"..i..". "..player..")"
		if strlen(msg) >= 200 then
			Roll:Say(msg)
			msg = ""
		end
	end
	Roll:Say(msg)

	Roll:Say("Rolling a random player 1-"..high)
	local winner = players[roll]
	if not winner then 
		winner = "No one"
	end
    Roll:Say(winner .. " Won! (#" .. roll .. ")", true)
end

function Roll:ConvertRoll(msg)

    if not msg or msg == "" then return end

    for name, roll, low, high in string.gmatch(msg, ROLL_PATTERN) do
        return name, tonumber(roll), tonumber(low), tonumber(high)
    end
end


function Roll:CHAT_MSG_ROLL(text, ...)
    if not text or text == "" then return end
    local name, roll, low, high = Roll:ConvertRoll(text)

    if name == nil then
        return 
    end

    if not Roll.activeRoll.acceptingRolls then
        if name == UnitName("player") and allow_raid_roll then
            allow_raid_roll = false
            Roll:DoRaidRoll(roll, high)
            return
        end
    end
    
    for _, v in pairs(Roll.activeRoll.rolls) do 
        n = unpack(v)
        if n == name then
            Roll:Say("Ignored Multiroll from " .. n)
            return
        end
    end

    if  Roll.activeRoll.rolling and (low == 1 and high == 100) then

        if Roll.activeRoll.rerolls then
            for i, v in ipairs(Roll.activeRoll.rerolls) do 
                if name == v[1] then 
                    tinsert(Roll.activeRoll.rolls, i, {name, roll})
                    break
                end
			end
			local finished = true
			for i, v in ipairs(Roll.activeRoll.rerolls) do 
				if not Roll.activeRoll.rolls[i] then 
					finished = false
					break 
				end 
			end

			if finished then 
				Roll:EndRollEarly()
			end

        else
            tinsert(Roll.activeRoll.rolls, {name, roll})
        end
        Roll.UpdatePanel()
    end
end


function Roll:CHAT_MSG(text, ...)

    if Roll.activeRoll.rolling then return end -- do nothing if we're mid roll
    local sender = select(1, ...)

    if (sender ~= UnitName("Player")) then
        return
    end

    local itemLinkStart = strfind(text, "item:")
    local _, itemLinkEnd = strfind(text, "|h|r")

    if not itemLinkStart or not itemLinkEnd then 
        return
    end

    local text_without_item = strsub(text, 0, itemLinkStart - 12) .. strsub(text, itemLinkEnd, strlen(text))
    text_without_item = strlower(text_without_item) 
    if not strfind(text_without_item, "roll") then
        return
    end
    
    local count = strmatch(text_without_item, "x%d")
    if count then 
        count = count:gsub("x", "")
        count = tonumber(count)
        Roll.activeRoll.count = count
    else 
        Roll.activeRoll.count = 1 
    end

    local itemLink = strsub(text, itemLinkStart - 12, itemLinkEnd)
    Roll:StartNewRoll(itemLink)
end


function Roll:Say(msg, loud)
    local channel = nil
        
        if IsInRaid() then
            if IsRaidOfficer() and loud then
                channel = "RAID_WARNING"
            else
                channel = "RAID"
            end

        elseif IsInGroup() then 
            channel = "PARTY"
        end

        if channel then
            SendChatMessage("[RAA] "..msg, channel)
        end
end

function Roll.UpdatePanel() 
    tsort(Roll.activeRoll.rolls, function(a, b) if a and b then return a[2] > b[2] else return true end end)
    local i = 1

    for _, data in ipairs(Roll.activeRoll.rolls) do 
        local name, roll = unpack(data)
        local _, class = UnitClass(name)
        local slot = Roll.PlayerList[i] 
        slot:Show()
        slot.Label:Show()
        slot.RollLabel:Show()

        if i <= Roll.activeRoll.count then
            slot:SetTexture("Interface\\AddOns\\" .. RA.InstallDir .. "\\media\\Check")
        else 
            slot:SetTexture("Interface\\Glues\\LOGIN\\Glues-CheckBox-Check")
        end

        slot:SetTexCoord(0, 1, 0, 1)
        local color = class and RAID_CLASS_COLORS [class] and RAID_CLASS_COLORS [class].colorStr or "ffffffff"
        slot.Label:SetText("|c" .. color .. name .. "|r")
        slot.RollLabel:SetText("|cFFebe534"..roll.."|r")
        i = i + 1
    end

    Roll.Panel:SetHeight (120 + (math.ceil ((i-1) / 2) * 17))
end

function Roll:ShowRollPanel(itemLink, timelimit)
    wipe(Roll.activeRoll.rolls) -- clean just incase 
    Roll.Panel:Show()
    Roll.ProgressBar:SetTimer(timelimit + 1)
    Roll.ItemString.text = "Roll for: " .. tostring(itemLink) 
    if (Roll.activeRoll.count > 1) then 
        Roll.ItemString.text = Roll.ItemString.text .. " x"..Roll.activeRoll.count 
    end

    for Index, Player in ipairs (Roll.PlayerList) do
        Player:Hide()
        Player.Label:Hide()
        Player.RollLabel:Hide()
    end
end

function Roll:StartNewRoll(itemLink)

    Roll.activeRoll.rolling = true
    Roll.activeRoll.item = itemLink
    Roll.activeRoll.rerolls = nil
    Roll.activeRoll.acceptingRolls = true

    local timelimit = Roll.db.roll_time or 30

    Roll:ShowRollPanel(itemLink, timelimit)

    Roll:Say("Roll ending in " .. timelimit .. " seconds!")
    Roll:ScheduleEndRoll(timelimit)
end


function Roll:StartReroll(rerolls)
    local players = ""
    local length = getn(rerolls)

    Roll.activeRoll.rerolls = rerolls
    for i, v in ipairs(rerolls) do 
        players = players .. v[1]
        if i ~= length then 
            players = players .. ", "
        end
    end

    local count = #Roll.activeRoll.rolls
    for i = 0, count do Roll.activeRoll.rolls[i] = nil end

    Roll.activeRoll.rolling = true
    Roll.activeRoll.acceptingRolls = true

    Roll:Say(players .. " Reroll for " .. Roll.activeRoll.item, true)
    local timelimit = Roll.db.reroll_time or 20

    Roll:ShowRollPanel(Roll.activeRoll.item, timelimit)

    Roll:Say("Roll ending in " .. timelimit .. " seconds!") 

    Roll:ScheduleEndRoll(timelimit)
end


function Roll:ScheduleEndRoll(timelimit)
	local timers = {}
	tinsert(timers, C_Timer.NewTimer(timelimit-6, function() 
		tinsert(timers, C_Timer.NewTicker(1, function(ticker) Roll:Say("Roll Ending in "..ticker._remainingIterations) end, 5))
	end))
	tinsert(timers, C_Timer.NewTimer(timelimit, Roll.EndRoll))
    Roll.activeRoll.timers = timers
end


function Roll:EndRoll()
    Roll.activeRoll.acceptingRolls = false
    tsort(Roll.activeRoll.rolls, function(a, b) return a[2] > b[2] end)
    winners = {}

    for i = 1, min(Roll.activeRoll.count, #Roll.activeRoll.rolls) do 
        tinsert(winners, Roll.activeRoll.rolls[i]) 
    end
    local rerolls = {}

    for _, v in ipairs(Roll.activeRoll.rolls) do
        if v[2] == winners[1][2] then 
            tinsert(rerolls, v)
        end
    end

    if getn(rerolls) > Roll.activeRoll.count then 
        Roll:StartReroll(rerolls)
        return
    end

    if getn(winners) > 0 then
        local winner_names = {}
        local winner_rolls = {}

        for i = 1, #winners do 
            tinsert(winner_names, winners[i][1])
            tinsert(winner_rolls, winners[i][2])
        end

        local name, roll = table.concat(winner_names, ", "), table.concat(winner_rolls, ", ")
        
        Roll:Say(name .. " won " .. Roll.activeRoll.item .. " with " .. roll, true)
    else 
        Roll:Say("No one wanted " .. Roll.activeRoll.item)
    end

    Roll:FinalizeRoll()
end


function Roll:FinalizeRoll()
    Roll.Panel:Hide()
    Roll.activeRoll.timers = {}
    Roll.activeRoll.rolls = {}
    Roll.activeRoll.item = nil
    Roll.activeRoll.rolling = false
    Roll.activeRoll.acceptingRolls = false
    Roll.activeRoll.count = 0
end


function Roll:EndRollEarly()
    if Roll.activeRoll.rolling then
        for _, timer in ipairs(Roll.activeRoll.timers) do
			timer:Cancel()
        end
        
        Roll:Say("Ending roll early.")
        Roll:EndRoll()
    end
end


function Roll:CancelRoll()
    if Roll.activeRoll.rolling then 
        for _, timer in ipairs(Roll.activeRoll.timers) do 
            timer:Cancel()
        end
        Roll:Say("Cancelled " ..Roll.activeRoll.item)
        Roll:FinalizeRoll()
    end
end

local install_status = RA:InstallPlugin ("Roll Handler", "RARoll", Roll, default_config)