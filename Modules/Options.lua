-- Arui QOL - Options Module

local AruiQOLFrame = _G.AruiQOLFrame

local Options = {}
local settingsCreated = false
local categoryFrames = {}
local currentCategory = "qol"
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

    local fill = track:CreateTexture(nil, "OVERLAY")
    fill:SetHeight(trackHeight - 4)
    fill:SetPoint("LEFT", 1, 0)
    fill:SetPoint("TOP", 0, -2)
    fill:SetColorTexture(0.2, 0.5, 0.8, 0.6)

    local plusBtn = CreateArrowButton("+", track, "RIGHT")

    return container, track, fill, minusBtn, plusBtn, trackWidth
end

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
        { type = "header", desc = "WhoPulled - Track who pulled the boss/adds" },
        { type = "checkbox", name = "Enable WhoPulled", desc = "Track and announce who pulled bosses (and adds if set to All mode)",
            get = function() return AruiQOLDB.WhoPulled.enabled end,
            set = function(v) AruiQOLDB.WhoPulled.enabled = v end },
        { type = "radio", name = "Track Mode", options = {
            { id = "boss", label = "Raid Boss" },
            { id = "dungeon", label = "Boss + Dungeon" },
            { id = "all", label = "All (Boss + Adds)" },
        },
            get = function(id) return AruiQOLDB.WhoPulled.trackMode == id end,
            set = function(id, val) if val then AruiQOLDB.WhoPulled.trackMode = id end end },
        { type = "header", desc = "Announcement" },
        { type = "checkbox", name = "Show Self Message", desc = "Print who pulled to your chat (self only)",
            get = function() return AruiQOLDB.WhoPulled.announceSelf end,
            set = function(v) AruiQOLDB.WhoPulled.announceSelf = v end },
        { type = "checkbox", name = "Announce to Chat", desc = "Send who pulled to raid/party chat",
            get = function() return AruiQOLDB.WhoPulled.announceChat end,
            set = function(v) AruiQOLDB.WhoPulled.announceChat = v end },
        { type = "radio", name = "Chat Channel", options = {
            { id = "AUTO", label = "Auto" },
            { id = "RAID", label = "Raid" },
            { id = "RAID_WARNING", label = "RW" },
            { id = "PARTY", label = "Party" },
            { id = "SAY", label = "Say" },
            { id = "SELF", label = "Self Only" },
        },
            get = function(id) return AruiQOLDB.WhoPulled.announceChannel == id end,
            set = function(id, val) if val then AruiQOLDB.WhoPulled.announceChannel = id end end },
        { type = "button", name = "Show Last Pull", desc = "Show who pulled the last boss",
            onClick = function()
                if _G.AruiQOLWhoPulled then
                    SlashCmdList["ARUIQOLWP"]("")
                else
                    print("|cff88ccff[WhoPulled]|r Module not loaded")
                end
            end },
        { type = "button", name = "Test WhoPulled", desc = "Show WhoPulled status and current state",
            onClick = function()
                SlashCmdList["ARUIQOLWP"]("test")
            end },
    }},

    { id = "resannounce", name = "ResAnnounce", settings = {
        { type = "header", desc = "Resurrection announcements - say funny messages when you rez someone" },
        { type = "checkbox", name = "Enable ResAnnounce", desc = "Show resurrection announcements when casting rez spells",
            get = function() return AruiQOLDB.ResAnnounce.enabled end,
            set = function(v) AruiQOLDB.ResAnnounce.enabled = v end },
        { type = "header", desc = "Choose which channels to send announcements to" },
        { type = "checkbox", name = "Send to /say", desc = "Post announcements in Say chat",
            get = function() return AruiQOLDB.ResAnnounce.displaySay end,
            set = function(v) AruiQOLDB.ResAnnounce.displaySay = v end },
        { type = "checkbox", name = "Send to /party", desc = "Post announcements in Party chat",
            get = function() return AruiQOLDB.ResAnnounce.displayParty end,
            set = function(v) AruiQOLDB.ResAnnounce.displayParty = v end },
        { type = "checkbox", name = "Send to /raid", desc = "Post announcements in Raid chat",
            get = function() return AruiQOLDB.ResAnnounce.displayRaid end,
            set = function(v) AruiQOLDB.ResAnnounce.displayRaid = v end },
        { type = "checkbox", name = "Whisper target", desc = "Also whisper the announcement to the resurrected player",
            get = function() return AruiQOLDB.ResAnnounce.displayWhisper end,
            set = function(v) AruiQOLDB.ResAnnounce.displayWhisper = v end },
    }},

    { id = "smarttrack", name = "SmartTrack", settings = {
        { type = "toggle", name = "SmartTrack", desc = "Toggle SmartTrack ON/OFF (also click the external toggle on screen)",
            get = function() return AruiQOLDB.SmartTrack.enabled end,
            set = function(v)
                AruiQOLDB.SmartTrack.enabled = v
                if _G.AruiQOLSmartTrackToggleFrame then
                    local f = _G.AruiQOLSmartTrackToggleFrame
                    if f and f.UpdateVisual then f:UpdateVisual() end
                end
            end },
        { type = "toggle", name = "Show Toggle", desc = "Show/hide the external iPhone-style toggle button on screen",
            get = function() return AruiQOLDB.SmartTrack.showToggle ~= false end,
            set = function(v)
                AruiQOLDB.SmartTrack.showToggle = v
                if v then
                    if _G.AruiQOLSmartTrackToggleVisibility then
                        _G.AruiQOLSmartTrackToggleVisibility()
                    end
                else
                    local f = _G.AruiQOLSmartTrackToggleFrame
                    if f then f:Hide() end
                end
            end },
        { type = "button", name = "Reset Toggle Position", desc = "Reset the external toggle button to default position",
            onClick = function()
                local f = _G.AruiQOLSmartTrackToggleFrame
                if f then
                    f:ClearAllPoints()
                    f:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -200, -200)
                    AruiQOLDB.SmartTrack.togglePos = nil
                    print("|cff88ccff[SmartTrack]|r Toggle position reset")
                else
                    print("|cff88ccff[SmartTrack]|r Toggle not visible, enable it first")
                end
            end },
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
        { type = "checkbox", name = "Filter World LFG", desc = "Hide LFG/LFM messages from World/LFG channels",
            get = function() return AruiQOLDB.ChatFilter.filterWorldLFG end,
            set = function(v) AruiQOLDB.ChatFilter.filterWorldLFG = v end },
        { type = "checkbox", name = "LFG: All Channels", desc = "Filter LFG content from ALL custom channels (not just World/Ascension)",
            get = function() return AruiQOLDB.ChatFilter.filterAllChannelsLFG end,
            set = function(v) AruiQOLDB.ChatFilter.filterAllChannelsLFG = v end },
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
        { type = "checkbox", name = "Filter Non-Latin", desc = "Hide messages that are mostly non-Latin characters (Cyrillic, CJK, etc.)",
            get = function() return AruiQOLDB.ChatFilter.filterNonLatin end,
            set = function(v) AruiQOLDB.ChatFilter.filterNonLatin = v end },
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

    { id = "autoaccept", name = "AutoAccept", settings = {
        { type = "header", desc = "Auto-accept resurrect, summon, auto-release PvP, auto-decline" },
        { type = "checkbox", name = "Enable AutoAccept", desc = "Master toggle for all auto-accept/decline features",
            get = function() return AruiQOLDB.AutoAccept.enabled end,
            set = function(v) AruiQOLDB.AutoAccept.enabled = v end },
        { type = "header", desc = "Auto-Accept" },
        { type = "checkbox", name = "Auto-Accept Resurrect", desc = "Automatically accept resurrect spells",
            get = function() return AruiQOLDB.AutoAccept.autoAcceptRes end,
            set = function(v) AruiQOLDB.AutoAccept.autoAcceptRes = v end },
        { type = "checkbox", name = "Skip Res in Combat", desc = "Don't auto-accept res while you're in combat",
            get = function() return AruiQOLDB.AutoAccept.skipResInCombat end,
            set = function(v) AruiQOLDB.AutoAccept.skipResInCombat = v end },
        { type = "checkbox", name = "Auto-Accept Summon", desc = "Automatically accept summon spells",
            get = function() return AruiQOLDB.AutoAccept.autoAcceptSummon end,
            set = function(v) AruiQOLDB.AutoAccept.autoAcceptSummon = v end },
        { type = "header", desc = "Auto-Release PvP" },
        { type = "checkbox", name = "Auto-Release in BG", desc = "Automatically release spirit when dying in battlegrounds",
            get = function() return AruiQOLDB.AutoAccept.autoReleasePvP end,
            set = function(v) AruiQOLDB.AutoAccept.autoReleasePvP = v end },
        { type = "checkbox", name = "Exclude Alterac Valley", desc = "Don't auto-release in Alterac Valley (so you can be ressed)",
            get = function() return AruiQOLDB.AutoAccept.excludeAlterac end,
            set = function(v) AruiQOLDB.AutoAccept.excludeAlterac = v end },
        { type = "slider", name = "Release Delay (sec)", desc = "Seconds to wait before auto-releasing in BG",
            min = 1, max = 10, step = 1,
            get = function() return AruiQOLDB.AutoAccept.releaseDelay or 3 end,
            set = function(v) AruiQOLDB.AutoAccept.releaseDelay = v end },
        { type = "header", desc = "Auto-Decline" },
        { type = "checkbox", name = "Decline Duels", desc = "Automatically decline all duel requests",
            get = function() return AruiQOLDB.AutoAccept.declineDuels end,
            set = function(v) AruiQOLDB.AutoAccept.declineDuels = v end },
        { type = "checkbox", name = "Decline Party Invites", desc = "Automatically decline party invites",
            get = function() return AruiQOLDB.AutoAccept.declinePartyInvites end,
            set = function(v) AruiQOLDB.AutoAccept.declinePartyInvites = v end },
        { type = "checkbox", name = "Accept Party from Friends", desc = "Accept party invites from friends/guildmates even if decline is on",
            get = function() return AruiQOLDB.AutoAccept.acceptPartyFromFriends end,
            set = function(v) AruiQOLDB.AutoAccept.acceptPartyFromFriends = v end },
        { type = "checkbox", name = "Decline Guild Invites", desc = "Automatically decline guild invite requests",
            get = function() return AruiQOLDB.AutoAccept.declineGuildInvites end,
            set = function(v) AruiQOLDB.AutoAccept.declineGuildInvites = v end },
        { type = "header", desc = "Test" },
        { type = "button", name = "Test Auto-Res", desc = "Simulate an auto-accept resurrect (prints to chat)",
            onClick = function()
                local db = AruiQOLDB and AruiQOLDB.AutoAccept
                if not db then return end
                print("|cff88ccff[AutoAccept]|r Test: Auto-Res = " .. (db.autoAcceptRes and "|cff00ff00ON|r" or "|cffff0000OFF|r") ..
                    ", Skip in Combat = " .. (db.skipResInCombat and "|cff00ff00ON|r" or "|cffff0000OFF|r"))
            end },
        { type = "button", name = "Test Auto-Summon", desc = "Check auto-summon status (prints to chat)",
            onClick = function()
                local db = AruiQOLDB and AruiQOLDB.AutoAccept
                if not db then return end
                print("|cff88ccff[AutoAccept]|r Test: Auto-Summon = " .. (db.autoAcceptSummon and "|cff00ff00ON|r" or "|cffff0000OFF|r"))
            end },
        { type = "button", name = "Test Auto-Release", desc = "Check auto-release PvP status",
            onClick = function()
                local db = AruiQOLDB and AruiQOLDB.AutoAccept
                if not db then return end
                local inBg = false
                local _, itype = IsInInstance()
                if itype == "pvp" then inBg = true end
                print("|cff88ccff[AutoAccept]|r Test: Auto-Release PvP = " .. (db.autoReleasePvP and "|cff00ff00ON|r" or "|cffff0000OFF|r") ..
                    ", Delay = " .. (db.releaseDelay or 3) .. "s" ..
                    ", In BG = " .. (inBg and "|cff00ff00YES|r" or "|cffff0000NO|r"))
            end },
    }},

    { id = "invitewhisper", name = "InviteWhisper", settings = {
        { type = "header", desc = "Auto-invite players who whisper a specific keyword" },
        { type = "checkbox", name = "Enable InviteWhisper", desc = "Auto-invite on keyword whisper",
            get = function() return AruiQOLDB.InviteWhisper.enabled end,
            set = function(v) AruiQOLDB.InviteWhisper.enabled = v end },
        { type = "header", desc = "Keywords - comma separated" },
        { type = "editbox", name = "Invite Keywords:", desc = "Comma-separated keywords that trigger auto-invite when whispered",
            get = function()
                local kw = AruiQOLDB.InviteWhisper.keywords or {}
                return table.concat(kw, ", ")
            end,
            set = function(v)
                AruiQOLDB.InviteWhisper.keywords = {}
                for w in string.gmatch(v or "", "[^,]+") do
                    w = string.match(w, "^%s*(.-)%s*$")
                    if w ~= "" then table.insert(AruiQOLDB.InviteWhisper.keywords, w) end
                end
            end },
        { type = "button", name = "Clear Keywords", desc = "Remove all invite keywords",
            onClick = function() AruiQOLDB.InviteWhisper.keywords = {} end },
        { type = "header", desc = "Options" },
        { type = "checkbox", name = "Auto-Convert to Raid", desc = "Convert party to raid when full and someone whispers",
            get = function() return AruiQOLDB.InviteWhisper.convertToRaid end,
            set = function(v) AruiQOLDB.InviteWhisper.convertToRaid = v end },
        { type = "checkbox", name = "Show Invite Messages", desc = "Print to chat when someone is auto-invited",
            get = function() return AruiQOLDB.InviteWhisper.announceSelf end,
            set = function(v) AruiQOLDB.InviteWhisper.announceSelf = v end },
        { type = "header", desc = "Test" },
        { type = "button", name = "List Keywords", desc = "Print current invite keywords to chat",
            onClick = function()
                local db = AruiQOLDB and AruiQOLDB.InviteWhisper
                if not db then return end
                local kw = db.keywords or {}
                if #kw == 0 then
                    print("|cff88ccff[InviteWhisper]|r No keywords set")
                else
                    print("|cff88ccff[InviteWhisper]|r Keywords: |cff88ccff" .. table.concat(kw, "|r, |cff88ccff") .. "|r")
                end
            end },
        { type = "button", name = "Test Invite", desc = "Check if invite would work in current group state",
            onClick = function()
                local db = AruiQOLDB and AruiQOLDB.InviteWhisper
                if not db then return end
                local inRaid = IsInRaid and IsInRaid()
                local inParty = GetNumPartyMembers and GetNumPartyMembers() > 0
                local canInvite = true
                if inRaid and not (IsRaidLeader() or IsRaidOfficer()) then canInvite = false end
                print("|cff88ccff[InviteWhisper]|r Test: Enabled = " .. (db.enabled and "|cff00ff00ON|r" or "|cffff0000OFF|r") ..
                    ", In Raid = " .. (inRaid and "|cff00ff00YES|r" or "|cffff0000NO|r") ..
                    ", In Party = " .. (inParty and "|cff00ff00YES|r" or "|cffff0000NO|r") ..
                    ", Can Invite = " .. (canInvite and "|cff00ff00YES|r" or "|cffff0000NO|r"))
            end },
    }},

    { id = "raidbar", name = "RaidBar", settings = {
        { type = "header", desc = "Toolbar with raid utility buttons (ready check, pull timers, pause, etc.)" },
        { type = "checkbox", name = "Enable RaidBar", desc = "Show the raid utility toolbar",
            get = function() return AruiQOLDB.RaidBar.enabled end,
            set = function(v)
                AruiQOLDB.RaidBar.enabled = v
                if v then
                    if _G.AruiQOLRaidBar_Rebuild then _G.AruiQOLRaidBar_Rebuild() end
                else
                    if _G.AruiQOLRaidBar_GetFrame then
                        local f = _G.AruiQOLRaidBar_GetFrame()
                        if f then f:Hide() end
                    end
                end
            end },
        { type = "header", desc = "Show buttons" },
        { type = "checkbox", name = "Ready Check", desc = "Show Ready Check button",
            get = function() return AruiQOLDB.RaidBar.showReadyCheck end,
            set = function(v) AruiQOLDB.RaidBar.showReadyCheck = v end },
        { type = "checkbox", name = "Pull 5s", desc = "Show 5-second pull timer button",
            get = function() return AruiQOLDB.RaidBar.showPull5 end,
            set = function(v) AruiQOLDB.RaidBar.showPull5 = v end },
        { type = "checkbox", name = "Pull 10s", desc = "Show 10-second pull timer button",
            get = function() return AruiQOLDB.RaidBar.showPull10 end,
            set = function(v) AruiQOLDB.RaidBar.showPull10 = v end },
        { type = "checkbox", name = "Pull 15s", desc = "Show 15-second pull timer button",
            get = function() return AruiQOLDB.RaidBar.showPull15 end,
            set = function(v) AruiQOLDB.RaidBar.showPull15 = v end },
        { type = "checkbox", name = "Pull (Custom)", desc = "Show custom pull timer button (left: start, right: cancel)",
            get = function() return AruiQOLDB.RaidBar.showPullTimer end,
            set = function(v) AruiQOLDB.RaidBar.showPullTimer = v end },
        { type = "checkbox", name = "Raid Pause", desc = "Show Raid Pause button (announces break in RW)",
            get = function() return AruiQOLDB.RaidBar.showRaidPause end,
            set = function(v) AruiQOLDB.RaidBar.showRaidPause = v end },
        { type = "checkbox", name = "Flask/Food Check", desc = "Show Flask/Food Check button (left: self, right: chat)",
            get = function() return AruiQOLDB.RaidBar.showFlaskCheck end,
            set = function(v) AruiQOLDB.RaidBar.showFlaskCheck = v end },
        { type = "checkbox", name = "Role Check", desc = "Show Role Check button",
            get = function() return AruiQOLDB.RaidBar.showRoleCheck end,
            set = function(v) AruiQOLDB.RaidBar.showRoleCheck = v end },
        { type = "checkbox", name = "Countdown", desc = "Show Countdown button (left: 5s, right: 10s)",
            get = function() return AruiQOLDB.RaidBar.showCountdown end,
            set = function(v) AruiQOLDB.RaidBar.showCountdown = v end },
        { type = "header", desc = "Settings" },
        { type = "slider", name = "Custom Pull Duration", desc = "Custom pull timer duration in seconds (for the Pull button)",
            min = 3, max = 30, step = 1,
            get = function() return AruiQOLDB.RaidBar.pullTimerDuration or 10 end,
            set = function(v) AruiQOLDB.RaidBar.pullTimerDuration = v end },
        { type = "radio", name = "Countdown Channel", options = {
            { id = "RW", label = "RW" },
            { id = "RAID", label = "Raid" },
            { id = "PARTY", label = "Party" },
            { id = "SAY", label = "Say" },
        },
            get = function(id) return AruiQOLDB.RaidBar.countdownChannel == id end,
            set = function(id, val) if val then AruiQOLDB.RaidBar.countdownChannel = id end end },
        { type = "editbox", name = "Pause Message:", desc = "Message sent to raid warning when Raid Pause is clicked",
            get = function() return AruiQOLDB.RaidBar.pauseMessage or "" end,
            set = function(v) AruiQOLDB.RaidBar.pauseMessage = v end },
        { type = "checkbox", name = "Only in Raid/Party", desc = "Only show the bar when in a raid or party",
            get = function() return AruiQOLDB.RaidBar.showOnlyInRaid end,
            set = function(v) AruiQOLDB.RaidBar.showOnlyInRaid = v end },
        { type = "checkbox", name = "Show in Party", desc = "Also show in party (not just raid)",
            get = function() return AruiQOLDB.RaidBar.showInParty end,
            set = function(v) AruiQOLDB.RaidBar.showInParty = v end },
        { type = "header", desc = "RaidCheck - Flask/Food buff checker" },
        { type = "checkbox", name = "Enable RaidCheck", desc = "Allow flask/food buff checking",
            get = function() return AruiQOLDB.RaidCheck.enabled end,
            set = function(v) AruiQOLDB.RaidCheck.enabled = v end },
        { type = "button", name = "Check (Self)", desc = "Check flask/food and show results in your chat only",
            onClick = function()
                if _G.AruiQOLRaidCheckDoCheck then
                    _G.AruiQOLRaidCheckDoCheck("self")
                else
                    print("|cff88ccff[RaidCheck]|r Module not loaded")
                end
            end },
        { type = "button", name = "Check (Chat)", desc = "Check flask/food and post results to raid/party chat",
            onClick = function()
                if _G.AruiQOLRaidCheckDoCheck then
                    _G.AruiQOLRaidCheckDoCheck("chat")
                else
                    print("|cff88ccff[RaidCheck]|r Module not loaded")
                end
            end },
        { type = "button", name = "Check My Buffs", desc = "Check if you personally have flask and food",
            onClick = function()
                local hasFlask, hasFood = false, false
                local FLASK_SPELLS = {
                    [53755]=true,[53760]=true,[53758]=true,[53752]=true,
                    [67019]=true,[67016]=true,[67017]=true,
                    [28518]=true,[28540]=true,[28520]=true,[28521]=true,[28519]=true,[42735]=true,
                }
                local FOOD_SPELLS = {
                    [57367]=true,[57327]=true,[57294]=true,[57360]=true,[57291]=true,
                    [57332]=true,[57356]=true,[57325]=true,[57358]=true,[57365]=true,
                    [57399]=true,[57401]=true,
                }
                for i = 1, 40 do
                    local name, _, _, _, _, _, _, _, _, _, spellId = UnitBuff("player", i)
                    if not name then break end
                    if FLASK_SPELLS[spellId] then hasFlask = true end
                    if FOOD_SPELLS[spellId] then hasFood = true end
                    if not hasFood and name and string.find(string.lower(name), "well fed") then hasFood = true end
                end
                print("|cff88ccff[RaidCheck]|r Your buffs: Flask = " .. (hasFlask and "|cff00ff00YES|r" or "|cffff0000NO|r") ..
                    ", Food = " .. (hasFood and "|cff00ff00YES|r" or "|cffff0000NO|r"))
            end },
        { type = "header", desc = "Actions" },
        { type = "button", name = "Rebuild Bar", desc = "Rebuild the RaidBar with current settings",
            onClick = function()
                if _G.AruiQOLRaidBar_Rebuild then
                    _G.AruiQOLRaidBar_Rebuild()
                    print("|cff88ccff[RaidBar]|r Rebuilt")
                end
            end },
        { type = "button", name = "Reset Position", desc = "Reset RaidBar position to default (center top)",
            onClick = function()
                AruiQOLDB.RaidBar.position = nil
                if _G.AruiQOLRaidBar_GetFrame then
                    local f = _G.AruiQOLRaidBar_GetFrame()
                    if f then
                        f:ClearAllPoints()
                        f:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
                    end
                end
                print("|cff88ccff[RaidBar]|r Position reset")
            end },
        { type = "button", name = "Test Pull Timer", desc = "Start a 5-second test pull timer (won't announce to raid)",
            onClick = function()
                print("|cff88ccff[RaidBar]|r Test: Pull Timer Duration = " .. (AruiQOLDB.RaidBar.pullTimerDuration or 10) .. "s")
                print("|cff88ccff[RaidBar]|r Click the Pull button on the bar to start a real pull timer")
            end },
        { type = "button", name = "Test Raid Pause", desc = "Preview the pause message without sending it",
            onClick = function()
                local msg = AruiQOLDB.RaidBar.pauseMessage or "--- RAID PAUSE --- Take a break, wait for RL!"
                print("|cff88ccff[RaidBar]|r Pause message preview:")
                print("|cffff5555" .. msg .. "|r")
            end },
    }},

    { id = "about", name = "About", settings = {
        { type = "spacer", height = 20 },
        { type = "title", text = "|cff88ccffArui|r |cffffffffQOL|r", size = "Large" },
        { type = "spacer", height = 4 },
        { type = "subtitle", text = "Quality of Life for  WoW" },
        { type = "spacer", height = 30 },
        { type = "links" },
        { type = "spacer", height = 20 },
        { type = "header", desc = "Advanced Settings" },
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
                local frame = _G["AruiQOLFrame"]
                if frame and frame.SetScale then frame:SetScale(v) end
            end },
        { type = "button", name = "Reset Window Position", desc = "Reset window to center of screen",
            onClick = function()
                AruiQOLDB.Settings.windowPosition = nil
                local frame = _G["AruiQOLFrame"]
                if frame and frame.ClearAllPoints then
                    frame:ClearAllPoints()
                    frame:SetPoint("CENTER")
                end
                print("|cff88ccffArui QOL:|r Position reset")
            end },
        { type = "button", name = "Reset All Settings", desc = "Reset all settings to defaults (reloads UI)",
            onClick = function()
                StaticPopup_Show("ARUIQOL_RESET_ALL")
            end },
    }},
}

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

    local valueText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    valueText:SetPoint("RIGHT", row, "RIGHT", -10, 0)
    valueText:SetTextColor(0.6, 0.8, 1)

    local step = setting.step or 1
    local isInteger = step >= 1

    local currentVal = setting.get()
    if type(currentVal) ~= "number" or currentVal < setting.min then currentVal = setting.min end
    if currentVal > setting.max then currentVal = setting.max end

    valueText:SetText(isInteger and tostring(math.floor(currentVal)) or string.format("%.2f", currentVal))

    local container, track, fill, minusBtn, plusBtn, trackWidth = CreateCustomSlider(row, setting.min, setting.max, step)

    local function UpdateVisual(val)
        local ratio = (val - setting.min) / (setting.max - setting.min)
        ratio = math.max(0, math.min(1, ratio))
        fill:SetWidth((trackWidth - 2) * ratio)
    end 

    local function SetValue(newVal)
        local rv = math.floor(newVal / step + 0.5) * step
        if rv < setting.min then rv = setting.min end
        if rv > setting.max then rv = setting.max end
        if setting.get() ~= rv then
            setting.set(rv)
        end
        valueText:SetText(isInteger and tostring(math.floor(rv)) or string.format("%.2f", rv))
        UpdateVisual(rv)
    end

    -- ERNESTO IS ALREADY IN GROUP
    UpdateVisual(currentVal)

    minusBtn:SetScript("OnClick", function(self, button)
        SetValue(setting.get() - step)
    end)

    plusBtn:SetScript("OnClick", function(self, button)
        SetValue(setting.get() + step)
    end)

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

    row:EnableMouseWheel(true)
    row:SetScript("OnMouseWheel", function(self, delta)
        SetValue(setting.get() + delta * step)
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

local function CreateToggleRow(parent, setting, yOff)
    local row = CreateFrame("Frame", nil, parent)
    row:SetWidth(parent:GetWidth() - 20)
    row:SetHeight(34)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, yOff)

    local label = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("LEFT", row, "LEFT", 0, 0)
    label:SetText(setting.name)
    label:SetTextColor(1, 1, 1)

    local toggleBtn = CreateFrame("Button", nil, row)
    toggleBtn:SetSize(52, 24)
    toggleBtn:SetPoint("RIGHT", row, "RIGHT", 0, 0)

    local trackBg = toggleBtn:CreateTexture(nil, "BACKGROUND")
    trackBg:SetAllPoints()
    trackBg:SetColorTexture(0.15, 0.15, 0.18, 1)

    local trackBorder = toggleBtn:CreateTexture(nil, "BORDER")
    trackBorder:SetPoint("TOPLEFT", -1, 1)
    trackBorder:SetPoint("BOTTOMRIGHT", 1, -1)
    trackBorder:SetColorTexture(0.4, 0.4, 0.42, 1)

    local knob = CreateFrame("Frame", nil, toggleBtn)
    knob:SetSize(20, 20)

    local knobBg = knob:CreateTexture(nil, "ARTWORK")
    knobBg:SetAllPoints()

    local stateText = toggleBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    stateText:SetPoint("CENTER", toggleBtn, "CENTER", 0, 0)

    local isOn = setting.get()

    local function UpdateVisual()
        if isOn then
            trackBg:SetColorTexture(0.12, 0.5, 0.2, 0.95)
            trackBorder:SetColorTexture(0.2, 0.7, 0.3, 1)
            knob:ClearAllPoints()
            knob:SetPoint("RIGHT", toggleBtn, "RIGHT", -2, 0)
            knobBg:SetColorTexture(0.95, 0.95, 0.95, 1)
            stateText:SetText("")
            stateText:SetTextColor(1, 1, 1, 0.9)
            label:SetTextColor(0.6, 0.9, 0.7)
        else
            trackBg:SetColorTexture(0.15, 0.15, 0.18, 1)
            trackBorder:SetColorTexture(0.4, 0.4, 0.42, 1)
            knob:ClearAllPoints()
            knob:SetPoint("LEFT", toggleBtn, "LEFT", 2, 0)
            knobBg:SetColorTexture(0.55, 0.55, 0.58, 1)
            stateText:SetText("")
            stateText:SetTextColor(0.5, 0.5, 0.5, 0.7)
            label:SetTextColor(1, 1, 1)
        end
    end

    UpdateVisual()

    toggleBtn:SetScript("OnClick", function()
        isOn = not isOn
        setting.set(isOn)
        UpdateVisual()
    end)

    toggleBtn:SetScript("OnEnter", function()
        if isOn then
            trackBorder:SetColorTexture(0.3, 0.85, 0.4, 1)
        else
            trackBorder:SetColorTexture(0.6, 0.6, 0.65, 1)
        end
    end)
    toggleBtn:SetScript("OnLeave", function()
        UpdateVisual()
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

    btn.bg = btn:CreateTexture(nil, "BACKGROUND")
    btn.bg:SetAllPoints()
    btn.bg:SetColorTexture(0.15, 0.15, 0.15, 0.9)

    btn.border = btn:CreateTexture(nil, "BORDER")
    btn.border:SetPoint("TOPLEFT", -1, 1)
    btn.border:SetPoint("BOTTOMRIGHT", 1, -1)
    btn.border:SetColorTexture(0.4, 0.4, 0.4, 0.8)

    btn.icon = btn:CreateTexture(nil, "OVERLAY")
    btn.icon:SetSize(40, 40)
    btn.icon:SetPoint("CENTER", 0, 6)
    btn.icon:SetTexture(data.icon)
    btn.icon:SetVertexColor(data.color[1], data.color[2], data.color[3])

    btn.label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    btn.label:SetPoint("BOTTOM", 0, 2)
    btn.label:SetText(data.name)
    btn.label:SetTextColor(1, 1, 1)

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
        
        if ChatEdit_GetActiveWindow then
            local editBox = ChatEdit_GetActiveWindow()
            if editBox then
                editBox:Insert(data.url)
            else
                ChatFrame_OpenChat(data.url)
            end
        else
            
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

        elseif setting.type == "toggle" then
            CreateToggleRow(scrollContent, setting, yOff)
            yOff = yOff - 36
        end
    end

    scrollContent:SetHeight(math.max(math.abs(yOff) + 50, 400))

    scrollFrame:Hide()

    return scrollFrame
end

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
            for catId, frame in pairs(categoryFrames) do
                frame:Hide()
            end

            if categoryFrames[catData.id] then
                categoryFrames[catData.id]:Show()
            end

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

        local contentArea = CreateFrame("Frame", nil, parent)
        contentArea:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", 8, 0)
        contentArea:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -5, 0)
        contentArea:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -5, 0)

        categoryFrames[catData.id] = BuildCategoryPage(contentArea, catData)

        categoryFrames[catData.id].contentParent = contentArea

        yOff = yOff - 32
    end

    if buttons[1] then
        buttons[1].bg:SetColorTexture(0.2, 0.4, 0.6, 0.8)
        buttons[1].text:SetTextColor(1, 1, 1)
    end

    return sidebar
end

StaticPopupDialogs["ARUIQOL_RESET_ALL"] = {
    text = "Reset all Arui QOL settings to defaults? This will reload the UI.",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function()
        AruiQOLDB = {
            QOL = { autoSellGreys = false, autoRepair = false, useGuildRepair = false, sellWhites = false, sellVerbose = false },
            BossAnnounce = { enabled = false, announceParty = true, announceRaid = false, announceGuild = false, showTimer = true, minBossHealth = 50, playSound = true, announceTrash = false, announceOnlyInInstance = true },
            ChatFilter = { enabled = true, filterWorldLFG = true, filterAllChannelsLFG = false, filterBoost = true, filterGuild = false, filterSpamBurst = true, filterRepeat = true, filterTrade = false, filterGeneral = false, filterLinks = false, filterWhisperSpam = true, filterNonLatin = false, replaceMode = false, customKeywords = {}, filterLFGChannels = {} },
            InterruptAnnounce = { enabled = false, visualEnabled = true, chatEnabled = true, output = "Auto", verbose = false, showParty = true, fontSize = 15 },
            ResAnnounce = { enabled = false, displaySay = true, displayParty = false, displayRaid = false, displayWhisper = false },
            SmartTrack = { enabled = true, lazy = true, raidOnly = false, impTrackingOnly = true, combatOnly = false, restore = false, ignoreDruid = false, quiet = false, debug = false },
            SpellAnnounce = { enabled = true, trackTotems = true, trackDefensives = true, trackImportant = true, visualEnabled = true, chatEnabled = false, output = "Auto", fontSize = 15, onlyOwnCDs = true },
            AutoAccept = { enabled = true, autoAcceptRes = true, autoAcceptSummon = true, autoReleasePvP = true, skipResInCombat = true, excludeAlterac = true, releaseDelay = 3, declineDuels = true, declinePartyInvites = false, declineGuildInvites = true, acceptPartyFromFriends = false },
            WhoPulled = { enabled = true, announceSelf = true, announceChat = false },
            InviteWhisper = { enabled = true, keywords = { "itsmeayro", "inv" }, convertToRaid = false, announceSelf = true },
            RaidCheck = { enabled = true },
            RaidBar = { enabled = true, showReadyCheck = true, showPullTimer = true, showRaidPause = true, showFlaskCheck = true, showRoleCheck = false, showCountdown = false, pullTimerDuration = 10, pauseMessage = "--- RAID PAUSE --- Take a break, wait for RL!", showOnlyInRaid = true, showInParty = true, position = nil },
            Settings = { uiScale = 1.0, minimapButton = true, debugMode = false, savePosition = true, windowPosition = nil },
        }
        ReloadUI()
    end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1
}

local function CreateAllSettings()
    if settingsCreated then return end
    settingsCreated = true

    local parent = AruiQOLFrame.ContentArea
    if not parent then return end

    CreateSidebar(parent)

    if categoryFrames[currentCategory] then
        categoryFrames[currentCategory]:Show()
    end
end


local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        self:UnregisterEvent("PLAYER_LOGIN")
        C_Timer.After(0.5, CreateAllSettings)
    end
end)
