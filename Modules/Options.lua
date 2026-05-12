-- ============================================================
-- Arui QOL - Options Module
-- ============================================================

local AruiQOLFrame = _G.AruiQOLFrame

local Options = {}
local settingsCreated = false
local categoryFrames = {}
local currentCategory = "qol"

-- ==================== UI HELPER FUNCTIONS ====================

local function CreateModernButton(parent, text, width, height)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetWidth(width)
    btn:SetHeight(height)

    btn.bg = btn:CreateTexture(nil, "BACKGROUND")
    btn.bg:SetAllPoints()
    btn.bg:SetColorTexture(0.2, 0.2, 0.2, 0.9)

    btn.border = btn:CreateTexture(nil, "BORDER")
    btn.border:SetAllPoints()
    btn.border:SetColorTexture(0.4, 0.4, 0.4, 0.8)

    btn.hoverTex = btn:CreateTexture(nil, "HIGHLIGHT")
    btn.hoverTex:SetAllPoints()
    btn.hoverTex:SetColorTexture(0.3, 0.5, 0.7, 0.4)
    btn.hoverTex:Hide()

    btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    btn.text:SetPoint("CENTER")
    btn.text:SetText(text)
    btn.text:SetTextColor(1, 1, 1)

    btn:SetScript("OnEnter", function(self)
        self.hoverTex:Show()
        self.text:SetTextColor(0.6, 0.8, 1)
        self.border:SetColorTexture(0.6, 0.8, 1, 0.8)
    end)
    btn:SetScript("OnLeave", function(self)
        self.hoverTex:Hide()
        self.text:SetTextColor(1, 1, 1)
        self.border:SetColorTexture(0.4, 0.4, 0.4, 0.8)
    end)

    return btn
end

local function CreateCleanEditBox(parent, width, height, isMultiLine)
    local editBox = CreateFrame("EditBox", nil, parent)
    editBox:SetWidth(width)
    editBox:SetHeight(height)
    editBox:SetAutoFocus(false)
    editBox:SetTextInsets(5, 5, 2, 2)
    editBox:SetFontObject("GameFontNormal")
    if isMultiLine then editBox:SetMultiLine(true) end

    local bg = editBox:CreateTexture(nil, "BACKGROUND")
    bg:SetColorTexture(0.05, 0.05, 0.05, 0.8)
    bg:SetAllPoints()

    local border = editBox:CreateTexture(nil, "BORDER")
    border:SetColorTexture(0.3, 0.3, 0.3, 0.8)
    border:SetPoint("TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", 1, -1)

    return editBox
end

-- Custom checkbox button
local function CreateSettingCheckbox(parent)
    local checkbox = CreateFrame("Button", nil, parent)
    checkbox:SetSize(24, 24)

    checkbox.bg = checkbox:CreateTexture(nil, "BACKGROUND")
    checkbox.bg:SetAllPoints()
    checkbox.bg:SetColorTexture(0.1, 0.1, 0.1, 1)

    checkbox.border = checkbox:CreateTexture(nil, "BORDER")
    checkbox.border:SetAllPoints()
    checkbox.border:SetColorTexture(0.4, 0.4, 0.4, 1)

    checkbox.check = checkbox:CreateTexture(nil, "OVERLAY")
    checkbox.check:SetSize(16, 16)
    checkbox.check:SetPoint("CENTER")
    checkbox.check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
    checkbox.check:SetVertexColor(0.2, 0.8, 1, 1)
    checkbox.check:Hide()

    checkbox.highlight = checkbox:CreateTexture(nil, "HIGHLIGHT")
    checkbox.highlight:SetAllPoints()
    checkbox.highlight:SetColorTexture(0.3, 0.5, 0.7, 0.3)
    checkbox.highlight:Hide()

    checkbox.checked = false

    checkbox:SetScript("OnEnter", function(self)
        self.highlight:Show()
        self.border:SetColorTexture(0.6, 0.8, 1, 1)
    end)
    checkbox:SetScript("OnLeave", function(self)
        self.highlight:Hide()
        self.border:SetColorTexture(0.4, 0.4, 0.4, 1)
    end)

    return checkbox
end


local function CreateCustomSlider(parent, minVal, maxVal, step)
    local trackWidth = 120
    local trackHeight = 14
    local btnSize = 18

    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(trackWidth + btnSize * 2 + 4, btnSize)
    container:SetPoint("RIGHT", parent, "RIGHT", -50, 0)

    --Nesi
    local function CreateArrowButton(textStr, anchorParent, anchorPoint)
        local btn = CreateFrame("Button", nil, container)
        btn:SetSize(btnSize, btnSize)
        if anchorParent then
            btn:SetPoint(anchorPoint, anchorParent, anchorPoint == "LEFT" and "RIGHT" or "LEFT", 140, 0)
        else
            btn:SetPoint("LEFT", 0, 0)
        end

        btn.bg = btn:CreateTexture(nil, "BACKGROUND")
        btn.bg:SetAllPoints()
        btn.bg:SetColorTexture(0.2, 0.2, 0.2, 0.9)

        btn.border = btn:CreateTexture(nil, "BORDER")
        btn.border:SetPoint("TOPLEFT", -1, 1)
        btn.border:SetPoint("BOTTOMRIGHT", 1, -1)
        btn.border:SetColorTexture(0.4, 0.4, 0.4, 0.8)

        btn.hover = btn:CreateTexture(nil, "HIGHLIGHT")
        btn.hover:SetAllPoints()
        btn.hover:SetColorTexture(0.3, 0.5, 0.7, 0.4)

        -- a. yr._ o
        btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        btn.text:SetPoint("CENTER", 0, -1)
        btn.text:SetText(textStr)
        btn.text:SetTextColor(1, 1, 1)

        return btn
    end

    local minusBtn = CreateArrowButton("-", nil, "LEFT")

    -- Track background
    local track = CreateFrame("Button", nil, container)
    track:SetSize(trackWidth, trackHeight)
    track:SetPoint("LEFT", minusBtn, "RIGHT", 2, 0)
    track:RegisterForClicks("LeftButtonUp")

    local trackBg = track:CreateTexture(nil, "BACKGROUND")
    trackBg:SetPoint("TOPLEFT", -1, 1)
    trackBg:SetPoint("BOTTOMRIGHT", 1, -1)
    trackBg:SetColorTexture(0.15, 0.15, 0.15, 0.9)

    local trackBorder = track:CreateTexture(nil, "BORDER")
    trackBorder:SetPoint("TOPLEFT", -1, 1)
    trackBorder:SetPoint("BOTTOMRIGHT", 1, -1)
    trackBorder:SetColorTexture(0.4, 0.4, 0.4, 0.8)

    -- Fill bar
    local fill = track:CreateTexture(nil, "OVERLAY")
    fill:SetHeight(trackHeight - 4)
    fill:SetPoint("LEFT", 1, 0)
    fill:SetPoint("TOP", 0, -2)
    fill:SetColorTexture(0.2, 0.5, 0.8, 0.6)

    local plusBtn = CreateArrowButton("+", track, "RIGHT")

    return container, track, fill, minusBtn, plusBtn, trackWidth
end

-- ==================== SETTINGS DEFINITIONS ====================
local SETTINGS = {
    { id = "qol", name = "QoL", settings = {
        { type = "header", desc = "Quality of Life features" },
        { type = "header", desc = "Auto-Sell" },
        { type = "checkbox", name = "Auto-Sell Grey Items", desc = "Automatically sell grey items when visiting a vendor",
            get = function() return AruiQOLDB.QOL.autoSellGreys end,
            set = function(v) AruiQOLDB.QOL.autoSellGreys = v end },
        { type = "checkbox", name = "Also Sell White Items", desc = "Sell common (white) quality items too",
            get = function() return AruiQOLDB.QOL.sellWhites end,
            set = function(v) AruiQOLDB.QOL.sellWhites = v end },
        { type = "checkbox", name = "Detailed Sell Log", desc = "Show each sold item with name and price",
            get = function() return AruiQOLDB.QOL.sellVerbose end,
            set = function(v) AruiQOLDB.QOL.sellVerbose = v end },
        { type = "header", desc = "Auto-Repair" },
        { type = "checkbox", name = "Auto-Repair Equipment", desc = "Automatically repair equipment when visiting a vendor",
            get = function() return AruiQOLDB.QOL.autoRepair end,
            set = function(v) AruiQOLDB.QOL.autoRepair = v end },
        { type = "checkbox", name = "Use Guild Bank for Repair", desc = "Use guild bank funds for repairs when available",
            get = function() return AruiQOLDB.QOL.useGuildRepair end,
            set = function(v) AruiQOLDB.QOL.useGuildRepair = v end },
    }},

    { id = "rezquotes", name = "RezQuotes", settings = {
        { type = "header", desc = "Resurrection quotes - say funny messages when you rez someone" },
        { type = "checkbox", name = "Enable RezQuotes", desc = "Show resurrection quotes when casting rez spells",
            get = function() return AruiQOLDB.RezQuotes.enabled end,
            set = function(v) AruiQOLDB.RezQuotes.enabled = v end },
        { type = "header", desc = "Choose which channels to send quotes to" },
        { type = "checkbox", name = "Send to /say", desc = "Post quotes in Say chat",
            get = function() return AruiQOLDB.RezQuotes.displaySay end,
            set = function(v) AruiQOLDB.RezQuotes.displaySay = v end },
        { type = "checkbox", name = "Send to /party", desc = "Post quotes in Party chat",
            get = function() return AruiQOLDB.RezQuotes.displayParty end,
            set = function(v) AruiQOLDB.RezQuotes.displayParty = v end },
        { type = "checkbox", name = "Send to /raid", desc = "Post quotes in Raid chat",
            get = function() return AruiQOLDB.RezQuotes.displayRaid end,
            set = function(v) AruiQOLDB.RezQuotes.displayRaid = v end },
        { type = "checkbox", name = "Whisper target", desc = "Also whisper the quote to the resurrected player",
            get = function() return AruiQOLDB.RezQuotes.displayWhisper end,
            set = function(v) AruiQOLDB.RezQuotes.displayWhisper = v end },
    }},

    { id = "smarttrack", name = "SmartTrack", settings = {
        { type = "header", desc = "Automatic tracking - switches tracking based on target creature type" },
        { type = "checkbox", name = "Enable Auto-Tracking", desc = "Automatically change tracking when you target something",
            get = function() return AruiQOLDB.SmartTrack.enabled end,
            set = function(v) AruiQOLDB.SmartTrack.enabled = v end },
        { type = "header", desc = "Condition filters - only track when these conditions are met" },
        { type = "checkbox", name = "Lazy Tracking", desc = "Only change tracking if not already tracking something with Imp. Tracking bonus",
            get = function() return AruiQOLDB.SmartTrack.lazy end,
            set = function(v) AruiQOLDB.SmartTrack.lazy = v end },
        { type = "checkbox", name = "Only in Instances", desc = "Only switch tracking while inside a dungeon/raid",
            get = function() return AruiQOLDB.SmartTrack.raidOnly end,
            set = function(v) AruiQOLDB.SmartTrack.raidOnly = v end },
        { type = "checkbox", name = "Only with Imp. Tracking", desc = "Only when talented for Improved Tracking",
            get = function() return AruiQOLDB.SmartTrack.impTrackingOnly end,
            set = function(v) AruiQOLDB.SmartTrack.impTrackingOnly = v end },
        { type = "checkbox", name = "Only in Combat", desc = "Only switch tracking while in combat",
            get = function() return AruiQOLDB.SmartTrack.combatOnly end,
            set = function(v) AruiQOLDB.SmartTrack.combatOnly = v end },
        { type = "checkbox", name = "Restore After Combat", desc = "Restore previous tracking type after leaving combat",
            get = function() return AruiQOLDB.SmartTrack.restore end,
            set = function(v) AruiQOLDB.SmartTrack.restore = v end },
        { type = "checkbox", name = "Ignore Druids", desc = "Don't waste time tracking Druid shapeshifting",
            get = function() return AruiQOLDB.SmartTrack.ignoreDruid end,
            set = function(v) AruiQOLDB.SmartTrack.ignoreDruid = v end },
        { type = "header", desc = "Misc" },
        { type = "checkbox", name = "Quiet Login", desc = "Suppress the login status message",
            get = function() return AruiQOLDB.SmartTrack.quiet end,
            set = function(v) AruiQOLDB.SmartTrack.quiet = v end },
        { type = "checkbox", name = "Debug Mode", desc = "Show detailed tracking debug info in chat",
            get = function() return AruiQOLDB.SmartTrack.debug end,
            set = function(v) AruiQOLDB.SmartTrack.debug = v end },
        { type = "button", name = "Test Auto-Track", desc = "Manually trigger tracking update for current target",
            onClick = function()
                if UnitExists("target") and UnitCanAttack("player", "target") then
                    local targetType = UnitCreatureType("target")
                    if targetType then
                        print("|cff88ccff[SmartTrack]|r Current target type: " .. targetType)
                    end
                else
                    print("|cff88ccff[SmartTrack]|r Target a hostile unit first")
                end
            end },
    }},

    { id = "bossannounce", name = "Boss Announce", settings = {
        { type = "header", desc = "Configure automatic boss fight announcements" },
        { type = "checkbox", name = "Enable Boss Announcements", desc = "Automatically announce boss fights in chat",
            get = function() return AruiQOLDB.BossAnnounce.enabled end,
            set = function(v) AruiQOLDB.BossAnnounce.enabled = v end },
        { type = "header", desc = "Select announcement channels" },
        { type = "checkbox", name = "Party Chat", desc = "Announce in party chat",
            get = function() return AruiQOLDB.BossAnnounce.announceParty end,
            set = function(v) AruiQOLDB.BossAnnounce.announceParty = v end },
        { type = "checkbox", name = "Raid Chat", desc = "Announce in raid chat",
            get = function() return AruiQOLDB.BossAnnounce.announceRaid end,
            set = function(v) AruiQOLDB.BossAnnounce.announceRaid = v end },
        { type = "checkbox", name = "Guild Chat", desc = "Also announce in guild chat",
            get = function() return AruiQOLDB.BossAnnounce.announceGuild end,
            set = function(v) AruiQOLDB.BossAnnounce.announceGuild = v end },
        { type = "header", desc = "Advanced options" },
        { type = "checkbox", name = "Show Fight Duration", desc = "Display how long the boss fight lasted",
            get = function() return AruiQOLDB.BossAnnounce.showTimer end,
            set = function(v) AruiQOLDB.BossAnnounce.showTimer = v end },
        { type = "checkbox", name = "Play Sound on Boss Pull", desc = "Play a sound when a boss fight starts",
            get = function() return AruiQOLDB.BossAnnounce.playSound end,
            set = function(v) AruiQOLDB.BossAnnounce.playSound = v end },
        { type = "checkbox", name = "Instance Only", desc = "Only announce in dungeons/raids",
            get = function() return AruiQOLDB.BossAnnounce.announceOnlyInInstance end,
            set = function(v) AruiQOLDB.BossAnnounce.announceOnlyInInstance = v end },
        { type = "checkbox", name = "Announce Trash Mobs", desc = "Also announce trash mob fights",
            get = function() return AruiQOLDB.BossAnnounce.announceTrash end,
            set = function(v) AruiQOLDB.BossAnnounce.announceTrash = v end },
        { type = "slider", name = "Health Alert %", desc = "Alert when boss drops below this % HP (0 = off)",
            min = 0, max = 90, step = 5,
            get = function() return AruiQOLDB.BossAnnounce.minBossHealth or 50 end,
            set = function(v) AruiQOLDB.BossAnnounce.minBossHealth = v end },
    }},

    { id = "chatfilter", name = "Chat Filter", settings = {
        { type = "header", desc = "Filter unwanted messages from chat channels" },
        { type = "checkbox", name = "Enable Chat Filter", desc = "Filter unwanted messages from chat",
            get = function() return AruiQOLDB.ChatFilter.enabled end,
            set = function(v) AruiQOLDB.ChatFilter.enabled = v end },
        { type = "checkbox", name = "Replace Mode", desc = "Instead of hiding, replace filtered messages with a placeholder",
            get = function() return AruiQOLDB.ChatFilter.replaceMode end,
            set = function(v) AruiQOLDB.ChatFilter.replaceMode = v end },
        { type = "header", desc = "Spam & Repeat filters" },
        { type = "checkbox", name = "Spam Burst Filter", desc = "Hide messages from players who send too many messages quickly",
            get = function() return AruiQOLDB.ChatFilter.filterSpamBurst end,
            set = function(v) AruiQOLDB.ChatFilter.filterSpamBurst = v end },
        { type = "checkbox", name = "Repeat Message Filter", desc = "Hide messages repeated 3+ times in 10 seconds",
            get = function() return AruiQOLDB.ChatFilter.filterRepeat end,
            set = function(v) AruiQOLDB.ChatFilter.filterRepeat = v end },
        { type = "header", desc = "Content filters" },
        { type = "checkbox", name = "Filter World LFG", desc = "Hide LFG/LFM messages from World channel",
            get = function() return AruiQOLDB.ChatFilter.filterWorldLFG end,
            set = function(v) AruiQOLDB.ChatFilter.filterWorldLFG = v end },
        { type = "checkbox", name = "Filter Boost/WTS/WTB", desc = "Hide boost selling, WTS, WTB messages",
            get = function() return AruiQOLDB.ChatFilter.filterBoost end,
            set = function(v) AruiQOLDB.ChatFilter.filterBoost = v end },
        { type = "checkbox", name = "Filter Guild Recruitment", desc = "Hide guild recruitment messages",
            get = function() return AruiQOLDB.ChatFilter.filterGuild end,
            set = function(v) AruiQOLDB.ChatFilter.filterGuild = v end },
        { type = "checkbox", name = "Filter Trade Channel", desc = "Hide all messages in Trade channel",
            get = function() return AruiQOLDB.ChatFilter.filterTrade end,
            set = function(v) AruiQOLDB.ChatFilter.filterTrade = v end },
        { type = "checkbox", name = "Filter General Channel", desc = "Hide all messages in General channel",
            get = function() return AruiQOLDB.ChatFilter.filterGeneral end,
            set = function(v) AruiQOLDB.ChatFilter.filterGeneral = v end },
        { type = "checkbox", name = "Filter Links", desc = "Hide messages containing URLs",
            get = function() return AruiQOLDB.ChatFilter.filterLinks end,
            set = function(v) AruiQOLDB.ChatFilter.filterLinks = v end },
        { type = "checkbox", name = "Filter Whisper Spam", desc = "Hide spammy whispers (boost, gold, etc)",
            get = function() return AruiQOLDB.ChatFilter.filterWhisperSpam end,
            set = function(v) AruiQOLDB.ChatFilter.filterWhisperSpam = v end },
        { type = "checkbox", name = "Filter Non-English", desc = "Hide messages that are mostly non-Latin characters",
            get = function() return AruiQOLDB.ChatFilter.filterNonEnglish end,
            set = function(v) AruiQOLDB.ChatFilter.filterNonEnglish = v end },
        { type = "header", desc = "Custom filter keywords" },
        { type = "editbox", name = "Keywords:", desc = "Comma-separated keywords to filter",
            get = function()
                local kw = AruiQOLDB.ChatFilter.customKeywords or {}
                return table.concat(kw, ", ")
            end,
            set = function(v)
                AruiQOLDB.ChatFilter.customKeywords = {}
                for w in string.gmatch(v or "", "[^,]+") do
                    w = string.match(w, "^%s*(.-)%s*$")
                    if w ~= "" then table.insert(AruiQOLDB.ChatFilter.customKeywords, w) end
                end
            end },
        { type = "button", name = "Clear Keywords", desc = "Remove all custom keywords",
            onClick = function() AruiQOLDB.ChatFilter.customKeywords = {} end },
        { type = "button", name = "Clear Filter Log", desc = "Clear the filter history log",
            onClick = function()
                if _G.AruiQOLChatFilter then _G.AruiQOLChatFilter.ClearLog() end
            end },
    }},

    { id = "interruptannounce", name = "Interrupt", settings = {
        { type = "header", desc = "Show spell interrupts on screen" },
        { type = "checkbox", name = "Enable Interrupt", desc = "Track and display spell interrupts",
            get = function() return AruiQOLDB.InterruptAnnounce.enabled end,
            set = function(v) AruiQOLDB.InterruptAnnounce.enabled = v end },
        { type = "checkbox", name = "Visual Display", desc = "Show interrupts on screen",
            get = function() return AruiQOLDB.InterruptAnnounce.visualEnabled end,
            set = function(v) AruiQOLDB.InterruptAnnounce.visualEnabled = v end },
        { type = "button", name = "Toggle Anchor", desc = "Show/hide the draggable anchor to reposition the display",
            onClick = function()
                if AruiQOL_InterruptToggleAnchor then
                    AruiQOL_InterruptToggleAnchor()
                end
            end },
        { type = "button", name = "Test Display", desc = "Show a test interrupt message on screen",
            onClick = function()
                if AruiQOL_InterruptTest then AruiQOL_InterruptTest() end
            end },
        { type = "checkbox", name = "Show Party Interrupts", desc = "Show interrupts from party/raid members (not just yours)",
            get = function() return AruiQOLDB.InterruptAnnounce.showParty end,
            set = function(v) AruiQOLDB.InterruptAnnounce.showParty = v end },
        { type = "slider", name = "Font Size", desc = "Visual display text size",
            min = 10, max = 24, step = 1,
            get = function() return AruiQOLDB.InterruptAnnounce.fontSize or 15 end,
            set = function(v) AruiQOLDB.InterruptAnnounce.fontSize = v end },
        { type = "header", desc = "Chat announce options" },
        { type = "checkbox", name = "Chat Announce", desc = "Also announce interrupts in chat",
            get = function() return AruiQOLDB.InterruptAnnounce.chatEnabled end,
            set = function(v) AruiQOLDB.InterruptAnnounce.chatEnabled = v end },
        { type = "radio", name = "Chat Channel", options = {
            { id = "Auto", label = "Auto" },
            { id = "Say", label = "Say" },
            { id = "Party", label = "Party" },
            { id = "Raid", label = "Raid" },
            { id = "Self", label = "Self Only" },
        },
            get = function(id) return AruiQOLDB.InterruptAnnounce.output == id end,
            set = function(id, val) if val then AruiQOLDB.InterruptAnnounce.output = id end end },
        { type = "checkbox", name = "Verbose Prefix", desc = "Add '=>' prefix in chat messages",
            get = function() return AruiQOLDB.InterruptAnnounce.verbose end,
            set = function(v) AruiQOLDB.InterruptAnnounce.verbose = v end },
    }},

    { id = "spellannounce", name = "Spells", settings = {
        { type = "header", desc = "Announce totems, defensive cooldowns and important spells" },
        { type = "checkbox", name = "Enable Spell Announce", desc = "Track and announce spells from group members",
            get = function() return AruiQOLDB.SpellAnnounce.enabled end,
            set = function(v) AruiQOLDB.SpellAnnounce.enabled = v end },
        { type = "header", desc = "What to track" },
        { type = "checkbox", name = "Track Totems", desc = "Announce shaman totems (Tremor, Grounding, etc)",
            get = function() return AruiQOLDB.SpellAnnounce.trackTotems end,
            set = function(v) AruiQOLDB.SpellAnnounce.trackTotems = v end },
        { type = "checkbox", name = "Track Defensive CDs", desc = "Announce defensive cooldowns (Shield Wall, Ice Block, etc)",
            get = function() return AruiQOLDB.SpellAnnounce.trackDefensives end,
            set = function(v) AruiQOLDB.SpellAnnounce.trackDefensives = v end },
        { type = "checkbox", name = "Track Important Spells", desc = "Announce Solar Beam and other important spells",
            get = function() return AruiQOLDB.SpellAnnounce.trackImportant end,
            set = function(v) AruiQOLDB.SpellAnnounce.trackImportant = v end },
        { type = "header", desc = "Source filter" },
        { type = "checkbox", name = "Only My CDs", desc = "Only announce spells cast by you (not other players)",
            get = function() return AruiQOLDB.SpellAnnounce.onlyOwnCDs end,
            set = function(v) AruiQOLDB.SpellAnnounce.onlyOwnCDs = v end },
        { type = "header", desc = "Visual display" },
        { type = "checkbox", name = "Visual Display", desc = "Show spell announcements on screen",
            get = function() return AruiQOLDB.SpellAnnounce.visualEnabled end,
            set = function(v) AruiQOLDB.SpellAnnounce.visualEnabled = v end },
        { type = "button", name = "Toggle Anchor", desc = "Show/hide the draggable anchor to reposition the display",
            onClick = function()
                if AruiQOL_SpellToggleAnchor then
                    AruiQOL_SpellToggleAnchor()
                end
            end },
        { type = "button", name = "Test Display", desc = "Show test spell announcements",
            onClick = function()
                if AruiQOL_SpellTest then AruiQOL_SpellTest() end
            end },
        { type = "slider", name = "Font Size", desc = "Visual display text size",
            min = 10, max = 24, step = 1,
            get = function() return AruiQOLDB.SpellAnnounce.fontSize or 15 end,
            set = function(v) AruiQOLDB.SpellAnnounce.fontSize = v end },
        { type = "header", desc = "Chat announce options" },
        { type = "checkbox", name = "Chat Announce", desc = "Also announce spells in chat",
            get = function() return AruiQOLDB.SpellAnnounce.chatEnabled end,
            set = function(v) AruiQOLDB.SpellAnnounce.chatEnabled = v end },
        { type = "radio", name = "Chat Channel", options = {
            { id = "Auto", label = "Auto" },
            { id = "Say", label = "Say" },
            { id = "Party", label = "Party" },
            { id = "Raid", label = "Raid" },
            { id = "Self", label = "Self Only" },
        },
            get = function(id) return AruiQOLDB.SpellAnnounce.output == id end,
            set = function(id, val) if val then AruiQOLDB.SpellAnnounce.output = id end end },
    }},

    { id = "about", name = "About", settings = {
        { type = "spacer", height = 20 },
        { type = "title", text = "|cff88ccffArui|r |cffffffffQOL|r", size = "Large" },
        { type = "spacer", height = 4 },
        { type = "subtitle", text = "Quality of Life for  WoW" },
        { type = "subtitle", text = "Version 1.3.0  |cffb188ffby AYRO|r" },
        { type = "spacer", height = 30 },
        { type = "links" },
    }},

    { id = "advanced", name = "Advanced", settings = {
        { type = "header", desc = "Advanced addon configuration" },
        { type = "checkbox", name = "Debug Mode", desc = "Enable debug messages in chat",
            get = function() return AruiQOLDB.Settings.debugMode end,
            set = function(v) AruiQOLDB.Settings.debugMode = v end },
        { type = "checkbox", name = "Show Minimap Button", desc = "Show the Arui QOL minimap button",
            get = function() return AruiQOLDB.Settings.minimapButton end,
            set = function(v)
                AruiQOLDB.Settings.minimapButton = v
                local mb = _G["AruiQOLMiniMapButton"]
                if mb then
                    if v then mb:Show() else mb:Hide() end
                end
            end },
        { type = "checkbox", name = "Save Window Position", desc = "Remember window position between sessions",
            get = function() return AruiQOLDB.Settings.savePosition end,
            set = function(v) AruiQOLDB.Settings.savePosition = v end },
        { type = "slider", name = "UI Scale", desc = "Adjust the scale of the addon window",
            min = 0.5, max = 1.5, step = 0.05,
            get = function()
                local val = AruiQOLDB.Settings.uiScale
                if type(val) ~= "number" then val = 1.0 end
                return val
            end,
            set = function(v)
                AruiQOLDB.Settings.uiScale = v
                if AruiQOLFrame then AruiQOLFrame:SetScale(v) end
            end },
        { type = "button", name = "Reset Window Position", desc = "Reset window to center of screen",
            onClick = function()
                AruiQOLDB.Settings.windowPosition = nil
                if AruiQOLFrame then
                    AruiQOLFrame:ClearAllPoints()
                    AruiQOLFrame:SetPoint("CENTER")
                end
                print("|cff88ccffArui QOL:|r Position reset")
            end },
        { type = "button", name = "Reset All Settings", desc = "Reset all settings to defaults (reloads UI)",
            onClick = function()
                StaticPopup_Show("ARUIQOL_RESET_ALL")
            end },
    }},
}

-- ==================== CREATE SETTING CONTROLS ====================

local function CreateCheckboxRow(parent, setting, yOff)
    local row = CreateFrame("Frame", nil, parent)
    row:SetWidth(parent:GetWidth() - 20)
    row:SetHeight(30)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, yOff)

    local label = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("LEFT", row, "LEFT", 0, 0)
    label:SetText(setting.name)
    label:SetTextColor(1, 1, 1)

    local cb = CreateSettingCheckbox(row)
    cb:SetPoint("RIGHT", row, "RIGHT", 0, 0)
    cb.checked = setting.get()
    cb.check:SetShown(cb.checked)
    cb:SetScript("OnClick", function(self)
        self.checked = not self.checked
        self.check:SetShown(self.checked)
        setting.set(self.checked)
    end)

    row:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(setting.name, 1, 1, 1)
        if setting.desc then GameTooltip:AddLine(setting.desc, 0.8, 0.8, 0.8, true) end
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    return row
end

local function CreateSliderRow(parent, setting, yOff)
    local row = CreateFrame("Frame", nil, parent)
    row:SetWidth(parent:GetWidth() - 20)
    row:SetHeight(50)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, yOff)

    local label = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("LEFT", row, "LEFT", 0, 0)
    label:SetText(setting.name)
    label:SetTextColor(1, 1, 1)

    -- Value text
    local valueText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    valueText:SetPoint("RIGHT", row, "RIGHT", -10, 0)
    valueText:SetTextColor(0.6, 0.8, 1)

    local step = setting.step or 1
    local isInteger = step >= 1

    -- Read current value
    local currentVal = setting.get()
    if type(currentVal) ~= "number" or currentVal < setting.min then currentVal = setting.min end
    if currentVal > setting.max then currentVal = setting.max end

    valueText:SetText(isInteger and tostring(math.floor(currentVal)) or string.format("%.2f", currentVal))

    -- Create button-based slider
    local container, track, fill, minusBtn, plusBtn, trackWidth = CreateCustomSlider(row, setting.min, setting.max, step)

    -- Update visual fill bar based on value
    local function UpdateVisual(val)
        local ratio = (val - setting.min) / (setting.max - setting.min)
        ratio = math.max(0, math.min(1, ratio))
        fill:SetWidth((trackWidth - 2) * ratio)
    end

    -- Update value and visuals
    local function SetValue(newVal)
        -- Snap to step
        local rv = math.floor(newVal / step + 0.5) * step
        -- Clamp
        if rv < setting.min then rv = setting.min end
        if rv > setting.max then rv = setting.max end
        -- Only update if changed
        if setting.get() ~= rv then
            setting.set(rv)
        end
        valueText:SetText(isInteger and tostring(math.floor(rv)) or string.format("%.2f", rv))
        UpdateVisual(rv)
    end

    -- ERNESTO IS ALREADY IN GROUP
    UpdateVisual(currentVal)

    -- Minus button
    minusBtn:SetScript("OnClick", function(self, button)
        SetValue(setting.get() - step)
    end)

    -- Plus button
    plusBtn:SetScript("OnClick", function(self, button)
        SetValue(setting.get() + step)
    end)

    -- Click on track: jump to that position
    track:SetScript("OnClick", function(self, button)
        local relX = GetCursorPosition()
        local scale = self:GetEffectiveScale()
        local left = self:GetLeft() * scale
        local width = self:GetWidth() * scale
        local ratio = (relX - left) / width
        ratio = math.max(0, math.min(1, ratio))
        local targetVal = setting.min + ratio * (setting.max - setting.min)
        SetValue(targetVal)
    end)

    -- Mouse wheel on the whole row
    row:EnableMouseWheel(true)
    row:SetScript("OnMouseWheel", function(self, delta)
        SetValue(setting.get() + delta * step)
    end)

    -- Tooltip on the row
    row:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(setting.name, 1, 1, 1)
        if setting.desc then GameTooltip:AddLine(setting.desc, 0.8, 0.8, 0.8, true) end
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    return row
end

local function CreateEditBoxRow(parent, setting, yOff)
    local row = CreateFrame("Frame", nil, parent)
    row:SetWidth(parent:GetWidth() - 20)
    row:SetHeight(55)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, yOff)

    local label = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
    label:SetText(setting.name)
    label:SetTextColor(1, 1, 1)

    local editBox = CreateCleanEditBox(row, row:GetWidth() - 10, 22, false)
    editBox:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -22)
    editBox:SetText(setting.get())
    editBox:SetScript("OnTextChanged", function(self)
        setting.set(self:GetText())
    end)

    row:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(setting.name, 1, 1, 1)
        if setting.desc then GameTooltip:AddLine(setting.desc, 0.8, 0.8, 0.8, true) end
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    return row
end

local function CreateButtonRow(parent, setting, yOff)
    local btn = CreateModernButton(parent, setting.name, 180, 28)
    btn:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, yOff)
    btn:SetScript("OnClick", function()
        if setting.onClick then setting.onClick() end
    end)

    local row = CreateFrame("Frame", nil, parent)
    row:SetWidth(parent:GetWidth() - 20)
    row:SetHeight(30)
    row:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)

    row:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
        GameTooltip:SetText(setting.name, 1, 1, 1)
        if setting.desc then GameTooltip:AddLine(setting.desc, 0.8, 0.8, 0.8, true) end
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    return row
end

local function CreateRadioGroup(parent, setting, yOff)
    local group = CreateFrame("Frame", nil, parent)
    group:SetWidth(parent:GetWidth() - 20)
    group:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, yOff)

    local label = group:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("TOPLEFT", 0, 0)
    label:SetText(setting.name)
    label:SetTextColor(1, 1, 1)

    local radios = {}
    local y = -25

    for _, opt in ipairs(setting.options) do
        local rb = CreateSettingCheckbox(group)
        rb:SetPoint("TOPLEFT", 15, y)
        rb.checked = setting.get(opt.id)
        rb.check:SetShown(rb.checked)

        local lbl = group:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl:SetPoint("LEFT", rb, "RIGHT", 8, 0)
        lbl:SetText(opt.label)
        lbl:SetTextColor(1, 1, 1)

        rb:SetScript("OnClick", function(self)
            if self.checked then return end
            for _, r in ipairs(radios) do
                r.checked = false
                r.check:Hide()
            end
            self.checked = true
            self.check:Show()
            setting.set(opt.id, true)
        end)

        table.insert(radios, rb)
        y = y - 28
    end

    group:SetHeight(math.abs(y) + 10)
    return group
end

-- ==================== LINK BUTTON CREATION ====================

local LINK_BUTTONS = {
    { name = "Discord",    url = "https://discord.gg/T5rtyW9yX4",        icon = "Interface\\AddOns\\AruiQOL\\Media\\discord.tga",   color = {0.57, 0.63, 0.82} },
    { name = "CurseForge", url = "https://www.curseforge.com/wow/addons/aruiqol", icon = "Interface\\AddOns\\AruiQOL\\Media\\forge.tga", color = {1.0, 0.55, 0.12} },
    { name = "GitHub",     url = "https://github.com/ayro-CMD/AruiQOL",        icon = "Interface\\AddOns\\AruiQOL\\Media\\gi.tga",     color = {0.85, 0.85, 0.85} },
    { name = "Bug Report", url = "https://discord.gg/uvtvKXzbXW", icon = "Interface\\AddOns\\AruiQOL\\Media\\bug.tga",  color = {0.9, 0.35, 0.35} },
}

local function CreateLinkButton(parent, data, xOff)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(64, 64)
    btn:SetPoint("TOPLEFT", parent, "TOPLEFT", xOff, 0)

    -- Background
    btn.bg = btn:CreateTexture(nil, "BACKGROUND")
    btn.bg:SetAllPoints()
    btn.bg:SetColorTexture(0.15, 0.15, 0.15, 0.9)

    -- Border
    btn.border = btn:CreateTexture(nil, "BORDER")
    btn.border:SetPoint("TOPLEFT", -1, 1)
    btn.border:SetPoint("BOTTOMRIGHT", 1, -1)
    btn.border:SetColorTexture(0.4, 0.4, 0.4, 0.8)

    -- Icon texture
    btn.icon = btn:CreateTexture(nil, "OVERLAY")
    btn.icon:SetSize(40, 40)
    btn.icon:SetPoint("CENTER", 0, 6)
    btn.icon:SetTexture(data.icon)
    btn.icon:SetVertexColor(data.color[1], data.color[2], data.color[3])

    -- Label
    btn.label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    btn.label:SetPoint("BOTTOM", 0, 2)
    btn.label:SetText(data.name)
    btn.label:SetTextColor(1, 1, 1)

    -- Highlight
    btn.hoverTex = btn:CreateTexture(nil, "HIGHLIGHT")
    btn.hoverTex:SetAllPoints()
    btn.hoverTex:SetColorTexture(data.color[1], data.color[2], data.color[3], 0.25)

    btn:SetScript("OnEnter", function(self)
        self.border:SetColorTexture(data.color[1], data.color[2], data.color[3], 1)
        self.label:SetTextColor(data.color[1], data.color[2], data.color[3])
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(data.name, 1, 1, 1)
        GameTooltip:AddLine("Click to copy link", 0.8, 0.8, 0.8)
        GameTooltip:AddLine(data.url, data.color[1], data.color[2], data.color[3], true)
        GameTooltip:Show()
    end)

    btn:SetScript("OnLeave", function(self)
        self.border:SetColorTexture(0.4, 0.4, 0.4, 0.8)
        self.label:SetTextColor(1, 1, 1)
        GameTooltip:Hide()
    end)

    btn:SetScript("OnClick", function(self)
        -- Insert link into chat edit box for easy copying
        if ChatEdit_GetActiveWindow then
            local editBox = ChatEdit_GetActiveWindow()
            if editBox then
                editBox:Insert(data.url)
            else
                ChatFrame_OpenChat(data.url)
            end
        else
            -- Fallback: print to chat
            print("|cff88ccff[" .. data.name .. "]|r " .. data.url)
        end
    end)

    return btn
end

local function CreateLinksPanel(parent)
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetWidth(parent:GetWidth() - 20)
    panel:SetHeight(90)
    panel:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, 0)

    local spacing = 20
    local totalWidth = #LINK_BUTTONS * 64 + (#LINK_BUTTONS - 1) * spacing
    local startX = (panel:GetWidth() - totalWidth) / 2

    for i, data in ipairs(LINK_BUTTONS) do
        local xOff = startX + (i - 1) * (64 + spacing)
        CreateLinkButton(panel, data, xOff)
    end

    return panel
end

-- ==================== BUILD A CATEGORY PAGE ====================
local function BuildCategoryPage(contentArea, catData)
    
    local scrollFrame = CreateFrame("ScrollFrame", "AruiQOLScroll_" .. catData.id, contentArea, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 0, 0)
    scrollFrame:SetPoint("BOTTOMRIGHT", -25, 0)

    local scrollContent = CreateFrame("Frame", nil, scrollFrame)
    scrollContent:SetSize(contentArea:GetWidth() - 20, 800)
    scrollFrame:SetScrollChild(scrollContent)

    local yOff = -10

    for _, setting in ipairs(catData.settings) do
        if setting.type == "spacer" then
            yOff = yOff - (setting.height or 20)

        elseif setting.type == "title" then
            local fs = scrollContent:CreateFontString(nil, "OVERLAY",
                setting.size == "Large" and "GameFontNormalLarge" or "GameFontNormal")
            fs:SetPoint("TOPLEFT", scrollContent, "TOPLEFT", (scrollContent:GetWidth() - 200) / 2, yOff)
            fs:SetText(setting.text)
            fs:SetTextColor(1, 1, 1)
            yOff = yOff - 40

        elseif setting.type == "subtitle" then
            local fs = scrollContent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            fs:SetPoint("TOPLEFT", scrollContent, "TOPLEFT", (scrollContent:GetWidth() - 200) / 2, yOff)
            fs:SetText(setting.text)
            fs:SetTextColor(0.6, 0.6, 0.6)
            yOff = yOff - 22

        elseif setting.type == "links" then
            local panel = CreateLinksPanel(scrollContent)
            panel:SetPoint("TOPLEFT", scrollContent, "TOPLEFT", 10, yOff)
            yOff = yOff - 100

        elseif setting.type == "header" then
            -- Separator + header text
            local sep = scrollContent:CreateTexture(nil, "BACKGROUND")
            sep:SetPoint("TOPLEFT", 10, yOff)
            sep:SetPoint("TOPRIGHT", -10, yOff)
            sep:SetHeight(1)
            sep:SetColorTexture(0.4, 0.4, 0.4, 0.5)

            local hText = scrollContent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            hText:SetPoint("TOPLEFT", 10, yOff - 18)
            hText:SetText(setting.desc or "")
            hText:SetTextColor(0.6, 0.8, 1)

            yOff = yOff - 40

        elseif setting.type == "checkbox" then
            CreateCheckboxRow(scrollContent, setting, yOff)
            yOff = yOff - 32

        elseif setting.type == "slider" then
            CreateSliderRow(scrollContent, setting, yOff)
            yOff = yOff - 50

        elseif setting.type == "editbox" then
            CreateEditBoxRow(scrollContent, setting, yOff)
            yOff = yOff - 58

        elseif setting.type == "button" then
            CreateButtonRow(scrollContent, setting, yOff)
            yOff = yOff - 35

        elseif setting.type == "radio" then
            local group = CreateRadioGroup(scrollContent, setting, yOff)
            yOff = yOff - group:GetHeight() - 5
        end
    end

    scrollContent:SetHeight(math.max(math.abs(yOff) + 50, 400))

    -- Hide initially
    scrollFrame:Hide()

    return scrollFrame
end

-- ==================== CREATE SIDEBAR ====================
local function CreateSidebar(parent)
    local sidebar = CreateFrame("Frame", nil, parent)
    sidebar:SetWidth(145)
    sidebar:SetPoint("TOPLEFT", parent, "TOPLEFT", 5, 0)
    sidebar:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 5, 0)

    local sidebarBg = sidebar:CreateTexture(nil, "BACKGROUND")
    sidebarBg:SetAllPoints()
    sidebarBg:SetColorTexture(0.05, 0.05, 0.08, 0.5)

    local yOff = -10
    local buttons = {}

    for _, catData in ipairs(SETTINGS) do
        local btn = CreateFrame("Button", nil, sidebar)
        btn:SetWidth(125)
        btn:SetHeight(28)
        btn:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 10, yOff)

        btn.bg = btn:CreateTexture(nil, "BACKGROUND")
        btn.bg:SetAllPoints()
        btn.bg:SetColorTexture(0.15, 0.15, 0.15, 0.8)

        btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        btn.text:SetPoint("CENTER")
        btn.text:SetText(catData.name)
        btn.text:SetTextColor(0.8, 0.8, 0.8)

        btn:SetScript("OnClick", function()
            -- Hide all
            for catId, frame in pairs(categoryFrames) do
                frame:Hide()
            end
            -- Show selected
            if categoryFrames[catData.id] then
                categoryFrames[catData.id]:Show()
            end
            -- Update highlights
            for _, b in ipairs(buttons) do
                b.bg:SetColorTexture(0.15, 0.15, 0.15, 0.8)
                b.text:SetTextColor(0.8, 0.8, 0.8)
            end
            btn.bg:SetColorTexture(0.2, 0.4, 0.6, 0.8)
            btn.text:SetTextColor(1, 1, 1)
            currentCategory = catData.id
        end)

        btn:SetScript("OnEnter", function(self)
            if currentCategory ~= catData.id then
                btn.bg:SetColorTexture(0.2, 0.3, 0.4, 0.6)
                btn.text:SetTextColor(1, 1, 1)
            end
        end)

        btn:SetScript("OnLeave", function(self)
            if currentCategory ~= catData.id then
                btn.bg:SetColorTexture(0.15, 0.15, 0.15, 0.8)
                btn.text:SetTextColor(0.8, 0.8, 0.8)
            end
        end)

        table.insert(buttons, btn)

        -- Build category content
        local contentArea = CreateFrame("Frame", nil, parent)
        contentArea:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", 8, 0)
        contentArea:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -5, 0)
        contentArea:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -5, 0)

        categoryFrames[catData.id] = BuildCategoryPage(contentArea, catData)

        -- Store contentArea reference on the frame
        categoryFrames[catData.id].contentParent = contentArea

        yOff = yOff - 32
    end

    -- Highlight first button
    if buttons[1] then
        buttons[1].bg:SetColorTexture(0.2, 0.4, 0.6, 0.8)
        buttons[1].text:SetTextColor(1, 1, 1)
    end

    return sidebar
end

-- ==================== STATIC POPUPS ====================
StaticPopupDialogs["ARUIQOL_RESET_ALL"] = {
    text = "Reset all Arui QOL settings to defaults? This will reload the UI.",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function()
        AruiQOLDB = {
            QOL = { autoSellGreys = false, autoRepair = false, useGuildRepair = false },
            BossAnnounce = { enabled = false, announceParty = true, announceRaid = false, announceGuild = false, showTimer = true, minBossHealth = 50, playSound = true, announceTrash = false, announceOnlyInInstance = true },
            ChatFilter = { enabled = true, filterWorldLFG = true, filterBoost = true, filterGuild = false, customKeywords = {}, filterLFGChannels = {} },
            InterruptAnnounce = { enabled = false, output = "Auto", verbose = true, announceSelf = true },
            RezQuotes = { enabled = false, displaySay = true, displayParty = false, displayRaid = false, displayWhisper = false },
            SmartTrack = { enabled = true, lazy = true, raidOnly = false, impTrackingOnly = true, combatOnly = false, restore = false, ignoreDruid = false, quiet = false, debug = false },
            Settings = { uiScale = 1.0, minimapButton = true, debugMode = false, savePosition = true, windowPosition = nil },
        }
        ReloadUI()
    end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1
}

-- ==================== INITIALIZATION ====================
local function CreateAllSettings()
    if settingsCreated then return end
    settingsCreated = true

    local parent = AruiQOLFrame.ContentArea
    if not parent then return end

    CreateSidebar(parent)

    -- Show first category
    if categoryFrames[currentCategory] then
        categoryFrames[currentCategory]:Show()
    end
end

-- Wait for frame to be ready
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        self:UnregisterEvent("PLAYER_LOGIN")
        C_Timer.After(0.5, CreateAllSettings)
    end
end)
