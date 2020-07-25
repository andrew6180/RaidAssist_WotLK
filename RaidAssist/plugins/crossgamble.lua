local RA = RaidAssist
local L = LibStub ("AceLocale-3.0"):GetLocale ("RaidAssistAddon")

local ROLL_PATTERN = RANDOM_ROLL_RESULT

local IsRaidOfficer = IsRaidOfficer
local IsInRaid = IsInRaid
local IsInParty = IsInParty
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
    winnings = {}
}

local CrossGamble = {version = "v0.1", pluginname = "Cross Gamble"}
_G ["RaidAssistCrossGamble"] = CrossGamble

local icon_texcoord = {l=0, r=1, t=0, b=1}
local text_color_enabled = {r=1, g=1, b=1, a=1}
local text_color_disabled = {r=0.5, g=0.5, b=0.5, a=1}
local icon_texture = [[Interface\Buttons\UI-GroupLoot-Dice-Up]]
local allow_raid_roll = false

CrossGamble.debug = false

CrossGamble.menu_text = function (plugin)
	if (CrossGamble.db.enabled) then
		return icon_texture, icon_texcoord, "Cross Gamble", text_color_enabled
	else
		return icon_texture, icon_texcoord, "Cross Gamble", text_color_disabled
	end
end

CrossGamble.menu_popup_show = function (plugin, ct_frame, param1, param2)
	RA:AnchorMyPopupFrame (CrossGamble)
end

CrossGamble.menu_popup_hide = function (plugin, ct_frame, param1, param2)
	CrossGamble.popup_frame:Hide()
end

CrossGamble.menu_on_click = function (plugin)

end

CrossGamble.OnInstall = function (plugin)
	CrossGamble.db.menu_priority = default_priority
    CrossGamble.db.winnings = CrossGamble.db.winnings or {}
	if CrossGamble.db.enabled then 
		CrossGamble.OnEnable(plugin)
	end
end

local function comma_value(amount)
    local formatted = amount
    while true do  
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if (k==0) then
            break
        end
    end
    return formatted
end



CrossGamble.OnEnable = function (plugin)
	CrossGamble.activeRoll = {
		rolls = {},
		item = nil,
        rolling = false,
        acceptingPlayers = false,
		timers = {}
    }
    if not CrossGamble.Panel then 
        CrossGamble.BuildFrame()
    end
    CrossGamble:RegisterEvent("CHAT_MSG_SYSTEM", CrossGamble.CHAT_MSG_ROLL)
    CrossGamble:RegisterEvent("CHAT_MSG_RAID", CrossGamble.CHAT_MSG)
    CrossGamble:RegisterEvent("CHAT_MSG_PARTY", CrossGamble.CHAT_MSG)
    CrossGamble:RegisterEvent("CHAT_MSG_RAID_LEADER", CrossGamble.CHAT_MSG)
    CrossGamble:RegisterEvent("CHAT_MSG_PARTY_LEADER", CrossGamble.CHAT_MSG)

    SLASH_CrossGamble1 = "/cg"

    function SlashCmdList.CrossGamble (msg, editbox)
        cap = tonumber(msg)
        if not cap and string.lower( msg ) ~= "report" and string.lower( msg ) ~= "reset" then
            DEFAULT_CHAT_FRAME:AddMessage("Usage: /cg <number 1-10000>")
            DEFAULT_CHAT_FRAME:AddMessage("/cg report")
            return 
        end
        if cap and cap > 10000 then 
            DEFAULT_CHAT_FRAME:AddMessage("Rolls are capped at 10,000 in 3.3.5, sorry.")
            return 
        end

        if cap then
            CrossGamble:StartNewRoll(cap)
        end

        if string.lower( msg ) == "report" then 
           CrossGamble:Say("Reporting top 3 winners & top 3 losers")
           tsort(CrossGamble.db.winnings, function(a, b) return a[2] > b[2] end)

           local last = 1
            for i, player in ipairs(CrossGamble.db.winnings) do 
                local winner, earnings = unpack(player)

                if i <= 3 or i >= #CrossGamble.db.winnings - 2 then
                    local winmsg = "won" 
                    if earnings < 0 then 
                        winmsg = "lost"
                    end
                    if last == 3 then 
                        CrossGamble:Say("...")
                    end
                    CrossGamble:Say(i..". ["..winner.."] has "..winmsg.." "..comma_value(earnings).."g!")
                    last = i
                end

            end
        end

        if string.lower ( msg ) == "reset" then 
            CrossGamble.db.winnings = {}
            DEFAULT_CHAT_FRAME:AddMessage("Reset CrossGambling DB.")
        end
    end
end

CrossGamble.OnDisable = function (plugin)
    CrossGamble.activeRoll = nil
    if CrossGamble.Panel then 
        CrossGamble.Panel:Hide()
    end
    CrossGamble:UnregisterEvent("CHAT_MSG_SYSTEM", CrossGamble.CHAT_MSG_ROLL)
    CrossGamble:UnregisterEvent("CHAT_MSG_RAID", CrossGamble.CHAT_MSG)
    CrossGamble:UnregisterEvent("CHAT_MSG_PARTY", CrossGamble.CHAT_MSG)
    CrossGamble:UnregisterEvent("CHAT_MSG_RAID_LEADER", CrossGamble.CHAT_MSG)
    CrossGamble:UnregisterEvent("CHAT_MSG_PARTY_LEADER", CrossGamble.CHAT_MSG)
    SLASH_CrossGamble1 = nil
end

CrossGamble.OnProfileChanged = function (plugin)
	if (plugin.db.enabled) then
		CrossGamble.OnEnable (plugin)
	else
		CrossGamble.OnDisable (plugin)
	end
	
	if (plugin.options_built) then
		
	end
end

function CrossGamble.OnShowOnOptionsPanel()
	local OptionsPanel = CrossGamble.OptionsPanel
	CrossGamble.BuildOptions (OptionsPanel)
end


function CrossGamble.BuildFrame() 
    local frame = CrossGamble:CreateCleanFrame(CrossGamble, "RAACrossGambleFrame") 
    frame:SetSize(350, 120)


    local itemString = CrossGamble:CreateLabel(frame, "ITEM_NAME")
    itemString:SetPoint("topleft", frame, "topleft", 8, -10)
    CrossGamble:SetFontSize(itemString, 14)
    CrossGamble:SetFontOutline (itemString, true)

    CrossGamble.PlayerList = {}
    local x = 10
    local y = -75
    for i = 1, 40 do 
        local Cross = CrossGamble:CreateImage (frame, "Interface\\Glues\\LOGIN\\Glues-CheckBox-Check", 16, 16, "overlay")
        local Label = CrossGamble:CreateLabel (frame, "Player Name")
        local RollLabel = CrossGamble:CreateLabel(frame, "")
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
        tinsert (CrossGamble.PlayerList, Cross)
    end
    local end_button_func = function()
        if CrossGamble.activeRoll.rolling then 
            CrossGamble:EndRollEarly()
        elseif CrossGamble.activeRoll.acceptingPlayers then 
            CrossGamble:StartRoll()
        end
    end
    local ebutton = CrossGamble:CreateButton(frame, end_button_func, 100, 20, "End CrossGamble", _, _, _, "ebutton", _, _, CrossGamble:GetTemplate("button", "OPTIONS_BUTTON_TEMPLATE"), CrossGamble:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
    local cbutton = CrossGamble:CreateButton(frame, CrossGamble.CancelRoll, 100, 20, "Cancel CrossGamble", _, _, _, "cbutton", _, _, CrossGamble:GetTemplate("button", "OPTIONS_BUTTON_TEMPLATE"), CrossGamble:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))

    ebutton:SetPoint("bottomleft", frame, "bottomleft", 0, 0)
    cbutton:SetPoint("bottomleft", frame, "bottomleft", 102, 0)

    ebutton:SetFrameLevel(frame:GetFrameLevel() + 1)
    cbutton:SetFrameLevel(ebutton:GetFrameLevel())

    CrossGamble.Panel = frame 
    CrossGamble.ItemString = itemString
    CrossGamble.endButton = ebutton
end


function CrossGamble.BuildOptions (frame)

	if (frame.FirstRun) then
		return
	end
	frame.FirstRun = true
	
	-- options panel
	local options_list = {
		{type = "label", get = function() return "General Options:" end, text_template = CrossGamble:GetTemplate ("font", "ORANGE_FONT_TEMPLATE")},
		{
			type = "toggle",
			get = function() return CrossGamble.db.enabled end,
			set = function (self, fixedparam, value) 
				CrossGamble.db.enabled = value
			end,
			name = "Enabled",
		},
		
		{type = "blank"},
		--{type = "label", get = function() return "Text Settings:" end, text_template = CrossGamble:GetTemplate ("font", "ORANGE_FONT_TEMPLATE")},
	}
	
	local options_text_template = CrossGamble:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE")
	local options_dropdown_template = CrossGamble:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE")
	local options_switch_template = CrossGamble:GetTemplate ("switch", "OPTIONS_CHECKBOX_TEMPLATE")
	local options_slider_template = CrossGamble:GetTemplate ("slider", "OPTIONS_SLIDER_TEMPLATE")
	local options_button_template = CrossGamble:GetTemplate ("button", "OPTIONS_BUTTON_TEMPLATE")
	
	CrossGamble:SetAsOptionsPanel (frame)
	CrossGamble:BuildMenu (frame, options_list, 0, 0, 300, true, options_text_template, options_dropdown_template, options_switch_template, true, options_slider_template, options_button_template)

	
end

function CrossGamble:StartRoll()
    CrossGamble.activeRoll.rolling = true 
    CrossGamble.activeRoll.acceptingPlayers = false
    local players = ""

    for player in pairs(CrossGamble.activeRoll.players) do 
        if players == "" then
             players = player
        else
            players = players..", "..player
        end
    end

    CrossGamble:Say("[/roll 1-"..CrossGamble.activeRoll.cap.."g]: "..players)

    CrossGamble.endButton:SetText("End Roll")

    for _, slot in ipairs(CrossGamble.PlayerList) do 
        slot:Hide()
    end
end

function CrossGamble:CHAT_MSG(msg, author)
    if CrossGamble.activeRoll.acceptingPlayers then 
        if msg == "1" and not CrossGamble.activeRoll.players[author] then 
            CrossGamble.activeRoll.players[author] = true
            CrossGamble:UpdatePanel()
        elseif msg == "-1" and CrossGamble.activeRoll.players[author] then 
            CrossGamble.activeRoll.players[author] = nil
            CrossGamble:UpdatePanel()
        end
    end
end


function CrossGamble:ConvertRoll(msg)

    if not msg or msg == "" then return end

    for name, roll, low, high in string.gmatch(msg, ROLL_PATTERN) do
        return name, tonumber(roll), tonumber(low), tonumber(high)
    end
end


function CrossGamble:CHAT_MSG_ROLL(text, ...)
    if not text or text == "" then return end
    local name, roll, low, high = CrossGamble:ConvertRoll(text)

    if name == nil then
        return 
    end
    
    for _, v in pairs(CrossGamble.activeRoll.rolls) do 
        n = unpack(v)
        if n == name then
            CrossGamble:Say("Ignored Multiroll from " .. n)
            return
        end
    end

    if  CrossGamble.activeRoll.rolling and (low == 1 and high == CrossGamble.activeRoll.cap) then
        if CrossGamble.activeRoll.players[name] then
            CrossGamble.activeRoll.players[name] = false
            tinsert(CrossGamble.activeRoll.rolls, {name, roll})
            CrossGamble.UpdatePanel()

            local continue_roll = false 
            for _, active in pairs(CrossGamble.activeRoll.players) do 
                if active then 
                    continue_roll = true 
                    break
                end
            end

            if not continue_roll then 
                CrossGamble:EndRoll()
            end
        end
    end
end


function CrossGamble:Say(msg, loud)
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
            SendChatMessage("[RAA] Cross Gambling: "..msg, channel)
            --print("[RAA] Cross Gambling: "..msg)
        end
end

function CrossGamble.UpdatePanel() 
    tsort(CrossGamble.activeRoll.rolls, function(a, b) return a[2] > b[2] end)
    local i = 1

    if CrossGamble.activeRoll.acceptingPlayers then 
        for name, active in pairs(CrossGamble.activeRoll.players) do 
            local _, class = UnitClass(name)
            local slot = CrossGamble.PlayerList[i]

            if active then
                 slot.name = name
                slot:Show()
                slot.Label:Show()
                slot.RollLabel:Hide()
                slot:SetTexture("Interface\\AddOns\\" .. RA.InstallDir .. "\\media\\Check")

                slot:SetTexCoord(0, 1, 0, 1)
                local color = class and RAID_CLASS_COLORS [class] and RAID_CLASS_COLORS [class].colorStr or "ffffffff"
                slot.Label:SetText("|c" .. color .. name .. "|r")
            else
                slot:Hide()
                slot.name = nil
            end

            i = i + 1
        end

    elseif CrossGamble.activeRoll.rolling then

        for _, data in ipairs(CrossGamble.activeRoll.rolls) do 
            local name, roll = unpack(data)
            local _, class = UnitClass(name)
            local slot
            for _, s in ipairs(CrossGamble.PlayerList) do 
                if s.name == name then 
                    slot = s
                    break
                end
            end
            if not slot then 
                slot = CrossGamble.PlayerList[i] 
            end
            slot.name = name
            slot:Show()
            slot.Label:Show()
            slot.RollLabel:Show()

            if i == 1 then
                slot:SetTexture([[Interface\Buttons\UI-GroupLoot-Coin-Up]])
            elseif i == #CrossGamble.activeRoll.rolls then 
                slot:SetTexture("Interface\\Glues\\LOGIN\\Glues-CheckBox-Check")
            else
                slot:SetTexture("Interface\\AddOns\\" .. RA.InstallDir .. "\\media\\Check")
            end

            slot:SetTexCoord(0, 1, 0, 1)
            local color = class and RAID_CLASS_COLORS [class] and RAID_CLASS_COLORS [class].colorStr or "ffffffff"
            slot.Label:SetText("|c" .. color .. name .. "|r")
            slot.RollLabel:SetText("|cFFebe534"..roll.."|r")
            i = i + 1
        end
    end

    CrossGamble.Panel:SetHeight (120 + (math.ceil ((i-1) / 2) * 17))
end

function CrossGamble:ShowRollPanel(cap)
    wipe(CrossGamble.activeRoll.rolls) -- clean just incase 
    CrossGamble.Panel:Show()
    CrossGamble.ItemString.text = "CrossGamble for: "..comma_value(CrossGamble.activeRoll.cap)

    for Index, Player in ipairs (CrossGamble.PlayerList) do
        Player:Hide()
        Player.Label:Hide()
        Player.RollLabel:Hide()
    end
end

function CrossGamble:StartNewRoll(cap)
    CrossGamble.activeRoll.acceptingPlayers = true
    CrossGamble.activeRoll.cap = cap
    CrossGamble.activeRoll.players = {}
    CrossGamble:ShowRollPanel(CrossGamble.activeRoll.cap)
    CrossGamble.endButton:SetText("Start Roll")
    CrossGamble:Say("["..comma_value(cap).."] Type 1 to enter, -1 to leave.")
end


function CrossGamble:EndRoll()
    CrossGamble.activeRoll.acceptingRolls = false
    tsort(CrossGamble.activeRoll.rolls, function(a, b) return a[2] > b[2] end)

    winner = CrossGamble.activeRoll.rolls[1]
    loser = CrossGamble.activeRoll.rolls[#CrossGamble.activeRoll.rolls]
    local db = CrossGamble.db

    if winner and loser and winner ~= loser then

        local diff = winner[2] - loser[2]
        
        local did_winner, did_loser = false, false
        for i, player in ipairs(CrossGamble.db.winnings) do 
            local name, earned = unpack(player)
            if name == winner[1] then 
                earned = earned + diff
                CrossGamble.db.winnings[i] = {name, earned}
                did_winner = true 
            elseif name == loser[1] then
                earned = earned - diff
                CrossGamble.db.winnings[i] = {name, earned}
                did_loser = true
            end
        end

        if not did_winner then 
            tinsert(CrossGamble.db.winnings, {winner[1], diff})
        end
        if not did_loser then 
            tinsert(CrossGamble.db.winnings, {loser[1], -diff})
        end

        CrossGamble:Say(loser[1].." owes "..winner[1].." "..comma_value(diff).. "g!")
    else 
        CrossGamble:Say("Less than two people entered. Ended roll.")
    end

    CrossGamble:FinalizeRoll()
end


function CrossGamble:FinalizeRoll()
    C_Timer.After(2, function() CrossGamble.Panel:Hide() end)
    CrossGamble.activeRoll.timers = {}
    CrossGamble.activeRoll.rolls = {}
    CrossGamble.activeRoll.players = {}
    CrossGamble.activeRoll.rolling = false
    CrossGamble.activeRoll.acceptingPlayers = false
end


function CrossGamble:EndRollEarly()
    if CrossGamble.activeRoll.rolling then
        for _, timer in ipairs(CrossGamble.activeRoll.timers) do
			timer:Cancel()
        end
        
        CrossGamble:Say("Ending roll early.")
        CrossGamble:EndRoll()
    end
end


function CrossGamble:CancelRoll()
    if CrossGamble.activeRoll.rolling or CrossGamble.activeRoll.acceptingPlayers then 
        for _, timer in ipairs(CrossGamble.activeRoll.timers) do 
            timer:Cancel()
        end
        CrossGamble:Say("Cancelled Roll.")
        CrossGamble:FinalizeRoll()
    end
end


local install_status = RA:InstallPlugin ("CrossGamble Handler", "RACrossGamble", CrossGamble, default_config)