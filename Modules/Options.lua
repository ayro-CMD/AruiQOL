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

-- Custom checkbox button (no template needed)
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

    -- Track background (must be Button for OnClick in WoW 3.3.5)
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

    -- Fill bar (shows current value visually)
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
        { type = "checkbox", name = "Auto-Sell Grey Items", desc = "Automatically sell grey items when visiting a vendor",
            get = function() return AruiQOLDB.QOL.autoSellGreys end,
            set = function(v) AruiQOLDB.QOL.autoSellGreys = v end },
        { type = "checkbox", name = "Auto-Repair Equipment", desc = "Automatically repair equipment when visiting a vendor",
            get = function() return AruiQOLDB.QOL.autoRepair end,
            set = function(v) AruiQOLDB.QOL.autoRepair = v end },
        { type = "checkbox", name = "Use Guild Bank for Repair", desc = "Use guild bank funds for repairs when available",
            get = function() return AruiQOLDB.QOL.useGuildRepair end,
            set = function(v) AruiQOLDB.QOL.useGuildRepair = v end },
    }},

    { id = "redeemer", name = "Redeemer", settings = {
        { type = "header", desc = "Resurrection quotes - say funny messages when you rez someone" },
        { type = "checkbox", name = "Enable Redeemer", desc = "Show resurrection quotes when casting rez spells",
            get = function() return AruiQOLDB.Redeemer.enabled end,
            set = function(v) AruiQOLDB.Redeemer.enabled = v end },
        { type = "header", desc = "Choose which channels to send quotes to" },
        { type = "checkbox", name = "Send to /say", desc = "Post quotes in Say chat",
            get = function() return AruiQOLDB.Redeemer.displaySay end,
            set = function(v) AruiQOLDB.Redeemer.displaySay = v end },
        { type = "checkbox", name = "Send to /party", desc = "Post quotes in Party chat",
            get = function() return AruiQOLDB.Redeemer.displayParty end,
            set = function(v) AruiQOLDB.Redeemer.displayParty = v end },
        { type = "checkbox", name = "Send to /raid", desc = "Post quotes in Raid chat",
            get = function() return AruiQOLDB.Redeemer.displayRaid end,
            set = function(v) AruiQOLDB.Redeemer.displayRaid = v end },
        { type = "checkbox", name = "Whisper target", desc = "Also whisper the quote to the resurrected player",
            get = function() return AruiQOLDB.Redeemer.displayWhisper end,
            set = function(v) AruiQOLDB.Redeemer.displayWhisper = v end },
    }},

    { id = "trackomatic", name = "Track-o-Matique", settings = {
        { type = "header", desc = "Automatic tracking for Hunters - switches tracking based on target creature type" },
        { type = "checkbox", name = "Enable Auto-Tracking", desc = "Automatically change tracking when you target something",
            get = function() return AruiQOLDB.TrackOMatique.enabled end,
            set = function(v) AruiQOLDB.TrackOMatique.enabled = v end },
        { type = "header", desc = "Condition filters - only track when these conditions are met" },
        { type = "checkbox", name = "Lazy Tracking", desc = "Only change tracking if not already tracking something with Imp. Tracking bonus",
            get = function() return AruiQOLDB.TrackOMatique.lazy end,
            set = function(v) AruiQOLDB.TrackOMatique.lazy = v end },
        { type = "checkbox", name = "Only in Instances", desc = "Only switch tracking while inside a dungeon/raid",
            get = function() return AruiQOLDB.TrackOMatique.raidOnly end,
            set = function(v) AruiQOLDB.TrackOMatique.raidOnly = v end },
        { type = "checkbox", name = "Only with Imp. Tracking", desc = "Only when talented for Improved Tracking",
            get = function() return AruiQOLDB.TrackOMatique.impTrackingOnly end,
            set = function(v) AruiQOLDB.TrackOMatique.impTrackingOnly = v end },
        { type = "checkbox", name = "Only in Combat", desc = "Only switch tracking while in combat",
            get = function() return AruiQOLDB.TrackOMatique.combatOnly end,
            set = function(v) AruiQOLDB.TrackOMatique.combatOnly = v end },
        { type = "checkbox", name = "Restore After Combat", desc = "Restore previous tracking type after leaving combat",
            get = function() return AruiQOLDB.TrackOMatique.restore end,
            set = function(v) AruiQOLDB.TrackOMatique.restore = v end },
        { type = "checkbox", name = "Ignore Druids", desc = "Don't waste time tracking Druid shapeshifting",
            get = function() return AruiQOLDB.TrackOMatique.ignoreDruid end,
            set = function(v) AruiQOLDB.TrackOMatique.ignoreDruid = v end },
        { type = "header", desc = "Misc" },
        { type = "checkbox", name = "Quiet Login", desc = "Suppress the login status message",
            get = function() return AruiQOLDB.TrackOMatique.quiet end,
            set = function(v) AruiQOLDB.TrackOMatique.quiet = v end },
        { type = "button", name = "Test Auto-Track", desc = "Manually trigger tracking update for current target",
            onClick = function()
                if UnitExists("target") and UnitCanAttack("player", "target") then
                    -- Force a tracking update
                    local targetType = UnitCreatureType("target")
                    if targetType then
                        print("|cff88ccff[ToM]|r Current target type: " .. targetType)
                    end
                else
                    print("|cff88ccff[ToM]|r Target a hostile unit first")
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
        { type = "header", desc = "Toggle specific filter types" },
        { type = "checkbox", name = "Filter World LFG", desc = "Hide LFG/LFM messages from World channel",
            get = function() return AruiQOLDB.ChatFilter.filterWorldLFG end,
            set = function(v) AruiQOLDB.ChatFilter.filterWorldLFG = v end },
        { type = "checkbox", name = "Filter Boost/WTS/WTB", desc = "Hide boost selling, WTS, WTB messages",
            get = function() return AruiQOLDB.ChatFilter.filterBoost end,
            set = function(v) AruiQOLDB.ChatFilter.filterBoost = v end },
        { type = "checkbox", name = "Filter Guild Recruitment", desc = "Hide guild recruitment messages",
            get = function() return AruiQOLDB.ChatFilter.filterGuild end,
            set = function(v) AruiQOLDB.ChatFilter.filterGuild = v end },
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
    }},

    { id = "interruptannounce", name = "Interrupt", settings = {
        { type = "header", desc = "Announce spell interrupts in chat" },
        { type = "checkbox", name = "Enable Interrupt Announce", desc = "Announce when you interrupt a spell",
            get = function() return AruiQOLDB.InterruptAnnounce.enabled end,
            set = function(v) AruiQOLDB.InterruptAnnounce.enabled = v end },
        { type = "header", desc = "Output channel (radio buttons)" },
        { type = "radio", name = "Channel", options = {
            { id = "Auto", label = "Auto" },
            { id = "Say", label = "Say" },
            { id = "Party", label = "Party" },
            { id = "Raid", label = "Raid" },
            { id = "Self", label = "Self Only" },
        },
            get = function(id) return AruiQOLDB.InterruptAnnounce.output == id end,
            set = function(id, val) if val then AruiQOLDB.InterruptAnnounce.output = id end end },
        { type = "checkbox", name = "Verbose Messages", desc = "Use '=> Interrupted:' prefix",
            get = function() return AruiQOLDB.InterruptAnnounce.verbose end,
            set = function(v) AruiQOLDB.InterruptAnnounce.verbose = v end },
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

    -- Set initial state
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

-- ==================== BUILD A CATEGORY PAGE ====================
local function BuildCategoryPage(contentArea, catData)
    -- CRITICAL: Use UIPanelScrollFrameTemplate for proper mouse event handling in 3.3.5
    -- A bare CreateFrame("ScrollFrame") intercepts mouse events and blocks sliders
    local scrollFrame = CreateFrame("ScrollFrame", nil, contentArea, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 0, 0)
    scrollFrame:SetPoint("BOTTOMRIGHT", -25, 0)

    local scrollContent = CreateFrame("Frame", nil, scrollFrame)
    scrollContent:SetSize(contentArea:GetWidth() - 20, 800)
    scrollFrame:SetScrollChild(scrollContent)

    local yOff = -10

    for _, setting in ipairs(catData.settings) do
        if setting.type == "header" then
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
            Redeemer = { enabled = false, displaySay = true, displayParty = false, displayRaid = false, displayWhisper = false },
            TrackOMatique = { enabled = true, lazy = true, raidOnly = false, impTrackingOnly = true, combatOnly = false, restore = false, ignoreDruid = false, quiet = false, debug = false },
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
