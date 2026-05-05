-- ============================================================
-- Arui QOL - Interrupt Announce Module
-- ============================================================

-- ==================== CONSTANTS ====================
local MAX_LINES      = 5
local SHOW_DURATION  = 4.0
local FADE_START     = 2.0
local LINE_PADDING   = 6
local DEFAULT_SIZE   = 15
local FONT_PATH      = "Fonts\\ARIALN.TTF"
local NPC_COLOR      = "c74040"
local SPELL_COLOR    = "7ad5ff"

-- ==================== RAID ICONS ====================
local RAID_ICONS = { [0] = "" }
for i = 1, 8 do
    RAID_ICONS[bit.lshift(1, i - 1)] = string.format("{rt%d}", i)
end

-- ==================== CLASS COLORS ====================
local CLASS_COLORS = {
    WARRIOR     = { r = 0.78, g = 0.61, b = 0.43 },
    MAGE        = { r = 0.41, g = 0.80, b = 0.94 },
    ROGUE       = { r = 1.00, g = 0.96, b = 0.41 },
    DRUID       = { r = 1.00, g = 0.49, b = 0.04 },
    HUNTER      = { r = 0.67, g = 0.83, b = 0.45 },
    SHAMAN      = { r = 0.00, g = 0.44, b = 0.87 },
    PRIEST      = { r = 1.00, g = 1.00, b = 1.00 },
    WARLOCK     = { r = 0.58, g = 0.51, b = 0.79 },
    PALADIN     = { r = 0.96, g = 0.55, b = 0.73 },
    DEATHKNIGHT = { r = 0.77, g = 0.12, b = 0.23 },
}

-- ==================== STATE ====================
local classColorCache = {}
local activeMessages  = {}
local displayAnchor   = nil
local anchorVisible   = false

-- ==================== HELPER FUNCTIONS ====================

local function ColorName(name, guid, isNPC)
    if not name then return "|cff" .. NPC_COLOR .. "Unknown|r" end
    local displayName = string.gsub(name, "%-.*", "")
    if isNPC then
        return string.format("|cff%s%s|r", NPC_COLOR, displayName)
    end
    if guid and classColorCache[guid] then
        return classColorCache[guid]
    end
    local classColor = nil
    if guid then
        local unit = nil
        if UnitGUID("player") == guid then unit = "player" end
        if not unit and GetNumPartyMembers and GetNumPartyMembers() > 0 then
            for i = 1, GetNumPartyMembers() do
                if UnitGUID("party" .. i) == guid then unit = "party" .. i; break end
            end
        end
        if not unit and GetNumRaidMembers and GetNumRaidMembers() > 0 then
            for i = 1, GetNumRaidMembers() do
                if UnitGUID("raid" .. i) == guid then unit = "raid" .. i; break end
            end
        end
        if unit then
            local _, class = UnitClass(unit)
            if class and CLASS_COLORS[class] then classColor = CLASS_COLORS[class] end
        end
    end
    local result
    if classColor then
        result = string.format("|cff%02x%02x%02x%s|r",
            classColor.r * 255, classColor.g * 255, classColor.b * 255, displayName)
        if guid then classColorCache[guid] = result end
    else
        result = string.format("|cffffffff%s|r", displayName)
    end
    return result
end

local function GetRaidIcon(raidFlags)
    if not raidFlags or raidFlags == 0 then return "" end
    return RAID_ICONS[raidFlags] or ""
end

local function IsPlayerGUID(guid)
    if not guid then return false end
    return string.sub(guid, 1, 6) == "Player"
end

local function IsGroupMember(sourceGUID)
    if not sourceGUID then return false end
    if UnitGUID("player") == sourceGUID then return true end
    if GetNumPartyMembers and GetNumPartyMembers() > 0 then
        for i = 1, GetNumPartyMembers() do
            if UnitGUID("party" .. i) == sourceGUID then return true end
        end
    end
    if GetNumRaidMembers and GetNumRaidMembers() > 0 then
        for i = 1, GetNumRaidMembers() do
            if UnitGUID("raid" .. i) == sourceGUID then return true end
        end
    end
    return false
end

-- ==================== VISUAL DISPLAY ====================

local function RepositionMessages()
    local offset = 0
    local db = AruiQOLDB and AruiQOLDB.InterruptAnnounce
    local fontSize = (db and db.fontSize) or DEFAULT_SIZE
    for i, entry in ipairs(activeMessages) do
        entry.fontString:ClearAllPoints()
        entry.fontString:SetPoint("TOPLEFT", displayAnchor, "TOPLEFT", 2, -offset)
        offset = offset + fontSize + LINE_PADDING
    end
end

local function ShowVisualMessage(text)
    if not displayAnchor then return end
    local db = AruiQOLDB and AruiQOLDB.InterruptAnnounce
    local fontSize = (db and db.fontSize) or DEFAULT_SIZE
    local fs = displayAnchor:CreateFontString(nil, "OVERLAY")
    fs:SetFont(FONT_PATH, fontSize, "OUTLINE")
    fs:SetShadowColor(0, 0, 0, 0.8)
    fs:SetShadowOffset(1, -1)
    fs:SetText(text)
    fs:SetAlpha(1)
    table.insert(activeMessages, 1, { fontString = fs, startTime = GetTime() })
    while #activeMessages > MAX_LINES do
        local old = table.remove(activeMessages)
        old.fontString:Hide()
        old.fontString:SetText("")
    end
    RepositionMessages()
end

local function VisualOnUpdate(self, elapsed)
    if type(elapsed) ~= "number" then
        elapsed = GetTime() - (self._lastTick or GetTime())
    end
    self._lastTick = GetTime()
    local now = GetTime()
    local changed = false
    for i = #activeMessages, 1, -1 do
        local entry = activeMessages[i]
        local age = now - entry.startTime
        if age >= SHOW_DURATION then
            entry.fontString:Hide()
            entry.fontString:SetText("")
            table.remove(activeMessages, i)
            changed = true
        elseif age >= FADE_START then
            entry.fontString:SetAlpha(max(0, 1 - (age - FADE_START) / (SHOW_DURATION - FADE_START)))
        end
    end
    if changed then RepositionMessages() end
end

-- ==================== ANCHOR TOGGLE ====================

local function ToggleAnchor()
    if not displayAnchor then return end
    anchorVisible = not anchorVisible
    if anchorVisible then
        displayAnchor:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 8, edgeSize = 12,
            insets = { left = 2, right = 2, top = 2, bottom = 2 }
        })
        displayAnchor:SetBackdropColor(0, 0, 0, 0.6)
        displayAnchor:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.8)
        displayAnchor:EnableMouse(true)
        -- Show close button + label
        if displayAnchor.closeBtn then displayAnchor.closeBtn:Show() end
        if displayAnchor.anchorLabel then displayAnchor.anchorLabel:Show() end
        print("|cff88ccff[AruiQOL]|r Anchor visibile - trascina per spostare. Posizione salvata automaticamente.")
    else
        displayAnchor:SetBackdrop(nil)
        displayAnchor:EnableMouse(false)
        -- Hide close button + label
        if displayAnchor.closeBtn then displayAnchor.closeBtn:Hide() end
        if displayAnchor.anchorLabel then displayAnchor.anchorLabel:Hide() end
        print("|cff88ccff[AruiQOL]|r Anchor nascosta. Posizione salvata nel DB.")
    end
end

-- Expose globally for Options.lua button
AruiQOL_InterruptToggleAnchor = ToggleAnchor

-- ==================== MAIN MODULE ====================

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        self:UnregisterEvent("PLAYER_LOGIN")

        local db = AruiQOLDB and AruiQOLDB.InterruptAnnounce
        if not db then return end

        -- Clear class color cache on zone/group change
        local cacheFrame = CreateFrame("Frame")
        cacheFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
        cacheFrame:RegisterEvent("PARTY_MEMBERS_CHANGED")
        cacheFrame:RegisterEvent("RAID_ROSTER_UPDATE")
        cacheFrame:SetScript("OnEvent", function()
            wipe(classColorCache)
        end)

        -- ====== Create visual display anchor ======
        displayAnchor = CreateFrame("Frame", "AruiQOLInterruptAnchor", UIParent)
        displayAnchor:SetSize(350, (MAX_LINES * (DEFAULT_SIZE + LINE_PADDING)) + 20)
        displayAnchor:SetPoint("CENTER", UIParent, "CENTER", 0, 100)

        if db.anchorPos then
            local pos = db.anchorPos
            displayAnchor:ClearAllPoints()
            displayAnchor:SetPoint(pos.point, UIParent, pos.relativePoint, pos.xOfs, pos.yOfs)
        end

        -- Draggable anchor
        displayAnchor:SetMovable(true)
        displayAnchor:EnableMouse(false)
        displayAnchor:RegisterForDrag("LeftButton")
        displayAnchor:SetScript("OnDragStart", function(self)
            if anchorVisible then
                self:StartMoving()
            end
        end)
        displayAnchor:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing()
            local point, _, relativePoint, xOfs, yOfs = self:GetPoint()
            if db then
                db.anchorPos = {
                    point = point,
                    relativePoint = relativePoint,
                    xOfs = xOfs,
                    yOfs = yOfs,
                }
            end
        end)

        -- OnUpdate for fading messages
        displayAnchor:SetScript("OnUpdate", VisualOnUpdate)

        -- ====== Close button (X) on anchor ======
        local closeBtn = CreateFrame("Button", nil, displayAnchor, "UIPanelCloseButton")
        closeBtn:SetSize(20, 20)
        closeBtn:SetPoint("TOPRIGHT", displayAnchor, "TOPRIGHT", 2, 2)
        closeBtn:SetScript("OnClick", ToggleAnchor)
        closeBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT")
            GameTooltip:SetText("Chiudi ancora", 1, 1, 1)
            GameTooltip:Show()
        end)
        closeBtn:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
        end)
        closeBtn:Hide()
        displayAnchor.closeBtn = closeBtn

        -- Label text on anchor (visible only when anchor is shown)
        local anchorLabel = displayAnchor:CreateFontString(nil, "OVERLAY")
        anchorLabel:SetFont(FONT_PATH, 10)
        anchorLabel:SetPoint("TOPLEFT", displayAnchor, "TOPLEFT", 6, -4)
        anchorLabel:SetTextColor(0.6, 0.6, 0.6, 0.8)
        anchorLabel:SetText("Interrupt Display")
        anchorLabel:Hide()
        displayAnchor.anchorLabel = anchorLabel

        -- Slash command to toggle anchor
        SLASH_INTERRUPTTOGGLE1 = "/aqolinterrupt"
        SlashCmdList["INTERRUPTTOGGLE"] = ToggleAnchor

        -- Test command
        local function DoTest()
            local testSource = ColorName(UnitName("player"), UnitGUID("player"), false)
            local testDest   = "|cffc74040Nasty Mob|r"
            local testSpell  = string.format("|cff%s[Shadow Bolt]|r", SPELL_COLOR)
            ShowVisualMessage(testSource .. " " .. testDest .. " " .. testSpell)
        end
        AruiQOL_InterruptTest = DoTest
        SLASH_INTERRUPTTEST1 = "/aqolinterrupttest"
        SlashCmdList["INTERRUPTTEST"] = DoTest

        -- ====== Delayed chat announce helper ======
        -- SendChatMessage cannot be called from COMBAT_LOG_EVENT_UNFILTERED in combat
        local pendingChat = {}
        local chatFrame = CreateFrame("Frame")
        chatFrame:SetScript("OnUpdate", function(self)
            if #pendingChat > 0 then
                for i, data in ipairs(pendingChat) do
                    local ok, err = pcall(SendChatMessage, data.msg, data.channel)
                    if not ok then
                        print("|cffff4444[Interrupt]|r Chat error: " .. tostring(err))
                    end
                end
                wipe(pendingChat)
            end
        end)

        -- ====== Combat log event handler ======
        local interruptFrame = CreateFrame("Frame")
        interruptFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        interruptFrame:SetScript("OnEvent", function(self, ev, ...)
            if ev ~= "COMBAT_LOG_EVENT_UNFILTERED" then return end

            local db = AruiQOLDB and AruiQOLDB.InterruptAnnounce
            if not db or not db.enabled then return end

            -- Parse combat log event
            local args = { ... }
            local timestamp, combatEvent, sourceGUID, sourceName,
                  sourceFlags, destGUID, destName,
                  destFlags, destRaidFlags, spellName, spellSchool,
                  extraSpellID, extraSpellName, extraSpellSchool

            
            local isAscension = type(args[3]) == "string"

            local ok, err = pcall(function()
                if isAscension then
                    timestamp      = args[1]
                    combatEvent    = args[2]
                    sourceGUID     = args[3]
                    sourceName     = args[4]
                    sourceFlags    = args[5]
                    destGUID       = args[6]
                    destName       = args[7]
                    destFlags      = args[8]
                    destRaidFlags  = args[9]
                    spellName      = args[10]
                    spellSchool    = args[11]
                    extraSpellID   = args[12]
                    extraSpellName = args[13]
                    extraSpellSchool = args[14]
                elseif args and args[1] then
                    timestamp      = args[1]
                    combatEvent    = args[2]
                    sourceGUID     = args[4]
                    sourceName     = args[5]
                    sourceFlags    = args[6]
                    destGUID       = args[8]
                    destName       = args[9]
                    destFlags      = args[10]
                    destRaidFlags  = args[11]
                    spellName      = args[13]
                    spellSchool    = args[14]
                    extraSpellID   = args[15]
                    extraSpellName = args[16]
                    extraSpellSchool = args[17]
                end
            end)

            if not ok then return end

            -- Match interrupt event
            if combatEvent ~= "SPELL_INTERRUPT" then
                if not (combatEvent and string.find(string.lower(combatEvent), "interrupt")) then
                    return
                end
            end

            -- Filter: only show own interrupts or group interrupts
            local isSelf = sourceGUID and (sourceGUID == UnitGUID("player"))
            if not isSelf and sourceName then
                local strippedName = string.gsub(sourceName, "%-.*", "")
                local playerName = UnitName("player") or ""
                if strippedName == playerName then isSelf = true end
            end

            if not isSelf and not (db.showParty and IsGroupMember(sourceGUID)) then
                return
            end

            -- ====== Build formatted message ======
            local sourceColored = ColorName(sourceName, sourceGUID, false)
            local raidIcon      = GetRaidIcon(destRaidFlags)
            local destIsPlayer  = IsPlayerGUID(destGUID)
            local destColored   = ColorName(destName, destGUID, not destIsPlayer)
            local spellColored  = string.format("|cff%s[%s]|r", SPELL_COLOR, extraSpellName or "Spell")

            local msg
            if raidIcon ~= "" then
                msg = sourceColored .. " " .. raidIcon .. " " .. destColored .. " " .. spellColored
            else
                msg = sourceColored .. " " .. destColored .. " " .. spellColored
            end

            -- ====== Visual display ======
            if db.visualEnabled then
                ShowVisualMessage(msg)
            end

            -- ====== Chat announce (delayed to avoid taint) ======
            if db.chatEnabled then
                local chatMsg = msg
                if db.verbose then chatMsg = "=> " .. chatMsg end

                local output = db.output or "Auto"
                if output == "Self" then
                    print("|cff88ccff[Interrupt]|r " .. chatMsg)
                elseif output == "Auto" then
                    if GetNumRaidMembers and GetNumRaidMembers() >= 1 then
                        table.insert(pendingChat, { msg = chatMsg, channel = "RAID" })
                    elseif GetNumPartyMembers and GetNumPartyMembers() >= 1 then
                        table.insert(pendingChat, { msg = chatMsg, channel = "PARTY" })
                    else
                        print("|cff88ccff[Interrupt]|r " .. chatMsg)
                    end
                elseif output == "Say" then
                    table.insert(pendingChat, { msg = chatMsg, channel = "SAY" })
                elseif output == "Party" then
                    if GetNumPartyMembers and GetNumPartyMembers() >= 1 then
                        table.insert(pendingChat, { msg = chatMsg, channel = "PARTY" })
                    end
                elseif output == "Raid" then
                    if GetNumRaidMembers and GetNumRaidMembers() >= 1 then
                        table.insert(pendingChat, { msg = chatMsg, channel = "RAID" })
                    end
                end
            end
        end)
    end
end)
