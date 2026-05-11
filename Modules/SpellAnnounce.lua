-- ============================================================
-- Arui QOL - Spell Announce Module
-- Totems, Defensive Cooldowns, Solar Beam
-- ============================================================

-- ==================== CONSTANTS ====================
local MAX_LINES      = 6
local SHOW_DURATION  = 5.0
local FADE_START     = 3.0
local LINE_PADDING   = 6
local DEFAULT_SIZE   = 15
local FONT_PATH      = "Fonts\\ARIALN.TTF"

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

-- ==================== SPELL CATEGORIES ====================

-- Totems (Shaman)
local TOTEM_SPELLS = {
    -- Earth
    [2484] = "Earthbind Totem",
    [8143] = "Tremor Totem",
    [8177] = "Grounding Totem",
    [5730] = "Stoneclaw Totem",
    [3599] = "Stoneskin Totem",
    [8071] = "Stoneskin Totem",
    [8075] = "Strength of Earth Totem",
    [8166] = "Poison Cleansing Totem",
    [8170] = "Cleansing Totem",
    [2062] = "Earth Elemental Totem",
    [8181] = "Frost Resistance Totem",
    -- Fire
    [8190] = "Magma Totem",
    [8184] = "Fire Resistance Totem",
    [2894] = "Fire Elemental Totem",
    [8167] = "Flametongue Totem",
    [8186] = "Searing Totem",
    [30706] = "Totem of Wrath",
    -- Water
    [5394] = "Healing Stream Totem",
    [5675] = "Mana Spring Totem",
    [8172] = "Disease Cleansing Totem",
    [8160] = "Mana Tide Totem",
    -- Air
    [8177] = "Grounding Totem",
    [8072] = "Windfury Totem",
    [8163] = "Nature Resistance Totem",
    [8512] = "Windwall Totem",
    [10595] = "Grace of Air Totem",
    [6495] = "Sentry Totem",
}

-- Defensive cooldowns
local DEFENSIVE_SPELLS = {
    -- Paladin
    [642] = "Divine Shield",
    [1022] = "Hand of Protection",
    [1044] = "Hand of Freedom",
    [1038] = "Hand of Salvation",
    [6940] = "Hand of Sacrifice",
    [31821] = "Aura Mastery",
    [31850] = "Ardent Defender",
    [498] = "Divine Protection",
    [633] = "Lay on Hands",
    -- Priest
    [33206] = "Pain Suppression",
    [47788] = "Guardian Spirit",
    [62618] = "Power Word: Barrier",
    [47585] = "Dispersion",
    -- Warrior
    [871] = "Shield Wall",
    [12975] = "Last Stand",
    [2565] = "Shield Block",
    [55694] = "Enraged Regeneration",
    [23920] = "Spell Reflection",
    -- Druid
    [22812] = "Barkskin",
    [61336] = "Survival Instincts",
    [33891] = "Tree of Life",
    -- Death Knight
    [48792] = "Icebound Fortitude",
    [49039] = "Lichborne",
    [55233] = "Vampiric Blood",
    [49222] = "Bone Shield",
    [49028] = "Dancing Rune Weapon",
    [48707] = "Anti-Magic Shell",
    [51052] = "Anti-Magic Zone",
    -- Mage
    [45438] = "Ice Block",
    [66] = "Invisibility",
    [86949] = "Cauterize",
    -- Rogue
    [5277] = "Evasion",
    [31224] = "Cloak of Shadows",
    [1856] = "Vanish",
    -- Hunter
    [19263] = "Deterrence",
    [34477] = "Misdirection",
    -- Warlock
    [47867] = "Demonic Circle: Teleport",
    -- Shaman
    [30823] = "Shamanistic Rage",
}

-- Solar Beam and other important interrupts/cc
local IMPORTANT_SPELLS = {
    [78675] = "Solar Beam",
}

-- Combine all tracked spells
local ALL_TRACKED = {}
for id, name in pairs(TOTEM_SPELLS) do ALL_TRACKED[id] = { name = name, cat = "totem" } end
for id, name in pairs(DEFENSIVE_SPELLS) do ALL_TRACKED[id] = { name = name, cat = "defensive" } end
for id, name in pairs(IMPORTANT_SPELLS) do ALL_TRACKED[id] = { name = name, cat = "important" } end

-- ==================== STATE ====================
local classColorCache = {}
local activeMessages  = {}
local displayAnchor   = nil
local anchorVisible   = false

-- ==================== HELPER FUNCTIONS ====================

local function ColorName(name, guid, isNPC)
    if not name then return "|cffc74040Unknown|r" end
    local displayName = string.gsub(name, "%-.*", "")
    if isNPC then
        return string.format("|cffc74040%s|r", displayName)
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
    local db = AruiQOLDB and AruiQOLDB.SpellAnnounce
    local fontSize = (db and db.fontSize) or DEFAULT_SIZE
    for i, entry in ipairs(activeMessages) do
        entry.fontString:ClearAllPoints()
        entry.fontString:SetPoint("TOPLEFT", displayAnchor, "TOPLEFT", 2, -offset)
        offset = offset + fontSize + LINE_PADDING
    end
end

local function ShowVisualMessage(text)
    if not displayAnchor then return end
    local db = AruiQOLDB and AruiQOLDB.SpellAnnounce
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
            entry.fontString:SetAlpha(math.max(0, 1 - (age - FADE_START) / (SHOW_DURATION - FADE_START)))
        end
    end
    if changed then RepositionMessages() end
end

-- ==================== ANCHOR ====================

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
        if displayAnchor.closeBtn then displayAnchor.closeBtn:Show() end
        if displayAnchor.anchorLabel then displayAnchor.anchorLabel:Show() end
        print("|cff88ccff[SpellAnnounce]|r Anchor visibile - trascina per spostare.")
    else
        displayAnchor:SetBackdrop(nil)
        displayAnchor:EnableMouse(false)
        if displayAnchor.closeBtn then displayAnchor.closeBtn:Hide() end
        if displayAnchor.anchorLabel then displayAnchor.anchorLabel:Hide() end
        print("|cff88ccff[SpellAnnounce]|r Anchor nascosta.")
    end
end

AruiQOL_SpellToggleAnchor = ToggleAnchor

-- ==================== CHAT OUTPUT ====================

local pendingChat = {}
local lastChatTime = 0
local CHAT_THROTTLE = 1.0

local function StripColors(text)
    if not text then return "" end
    text = string.gsub(text, "|c%x%x%x%x%x%x%x%x", "")
    text = string.gsub(text, "|r", "")
    return text
end

local chatFrame = nil

local function SendThrottledChat(msg, channel)
    table.insert(pendingChat, { msg = msg, channel = channel })
end

local function ProcessChatQueue()
    if not chatFrame then return end
    if #pendingChat == 0 then return end
    local now = GetTime()
    local remaining = {}
    for i, data in ipairs(pendingChat) do
        if now - lastChatTime >= CHAT_THROTTLE then
            local plainMsg = StripColors(data.msg)
            pcall(SendChatMessage, plainMsg, data.channel)
            lastChatTime = now
        else
            table.insert(remaining, data)
        end
    end
    pendingChat = remaining
end

-- ==================== CATEGORY COLORS FOR MESSAGES ====================

local CAT_COLORS = {
    totem     = "33ff99",  -- green
    defensive = "ff9933",  -- orange
    important = "ff3366",  -- red/pink (Solar Beam etc)
}

local CAT_ICONS = {
    totem     = "|cff33ff99[TOTEM]|r",
    defensive = "|cffff9933[DEF]|r",
    important = "|cffff3366[!!]|r",
}

-- ==================== MAIN COMBAT LOG HANDLER ====================

local function OnCombatLogEvent(...)
    local db = AruiQOLDB and AruiQOLDB.SpellAnnounce
    if not db or not db.enabled then return end

    local args = { ... }
    local combatEvent, sourceGUID, sourceName, sourceFlags,
          destGUID, destName, destFlags, destRaidFlags,
          spellId, spellName, extraSpellName

    -- Parse combat log args (compatible with both 3.3.5 and Ascension)
    if type(args[3]) == "string" then
        -- Ascension-style: no hideCaster
        combatEvent   = args[2]
        sourceGUID    = args[3]
        sourceName    = args[4]
        sourceFlags   = args[5]
        destGUID      = args[6]
        destName      = args[7]
        destFlags     = args[8]
        destRaidFlags = args[9]
        spellId       = args[10]
        spellName     = args[11]
    elseif args[1] then
        -- Standard 3.3.5: arg 3 = hideCaster
        combatEvent   = args[2]
        sourceGUID    = args[4]
        sourceName    = args[5]
        sourceFlags   = args[6]
        destGUID      = args[8]
        destName      = args[9]
        destFlags     = args[10]
        destRaidFlags = args[11]
        spellId       = args[13]
        spellName     = args[14]
    end

    if not combatEvent or not spellId then return end

    -- We only care about SPELL_CAST_SUCCESS and SPELL_SUMMON
    if combatEvent ~= "SPELL_CAST_SUCCESS" and combatEvent ~= "SPELL_SUMMON" then return end

    local tracked = ALL_TRACKED[spellId]
    if not tracked then return end

    -- Category check
    if tracked.cat == "totem" and not db.trackTotems then return end
    if tracked.cat == "defensive" and not db.trackDefensives then return end
    if tracked.cat == "important" and not db.trackImportant then return end

    -- Only group members
    if not IsGroupMember(sourceGUID) then return end

    -- Build message
    local sourceColored = ColorName(sourceName, sourceGUID, false)
    local destColored = ""
    if destGUID and destName then
        local destIsPlayer = destGUID and (string.sub(destGUID, 1, 6) == "Player")
        if destIsPlayer and destGUID ~= sourceGUID then
            destColored = " -> " .. ColorName(destName, destGUID, false)
        end
    end

    local catColor = CAT_COLORS[tracked.cat] or "ffffff"
    local catIcon = CAT_ICONS[tracked.cat] or ""
    local spellColored = string.format("|cff%s[%s]|r", catColor, tracked.name)

    local msg = catIcon .. " " .. sourceColored .. destColored .. " " .. spellColored

    -- Visual display
    if db.visualEnabled then
        ShowVisualMessage(msg)
    end

    -- Chat announce
    if db.chatEnabled then
        local chatMsg = msg
        local output = db.output or "Auto"
        if output == "Self" then
            print("|cff88ccff[SpellAnnounce]|r " .. chatMsg)
        elseif output == "Auto" then
            if GetNumRaidMembers and GetNumRaidMembers() >= 1 then
                SendThrottledChat(chatMsg, "RAID")
            elseif GetNumPartyMembers and GetNumPartyMembers() >= 1 then
                SendThrottledChat(chatMsg, "PARTY")
            else
                print("|cff88ccff[SpellAnnounce]|r " .. chatMsg)
            end
        elseif output == "Say" then
            SendThrottledChat(chatMsg, "SAY")
        elseif output == "Party" then
            if GetNumPartyMembers and GetNumPartyMembers() >= 1 then
                SendThrottledChat(chatMsg, "PARTY")
            end
        elseif output == "Raid" then
            if GetNumRaidMembers and GetNumRaidMembers() >= 1 then
                SendThrottledChat(chatMsg, "RAID")
            end
        end
    end
end

-- ==================== TEST FUNCTION ====================

local function DoTest()
    local testSource = ColorName(UnitName("player"), UnitGUID("player"), false)
    ShowVisualMessage(CAT_ICONS.important .. " " .. testSource .. " " .. string.format("|cff%s[Solar Beam]|r", CAT_COLORS.important))
    ShowVisualMessage(CAT_ICONS.defensive .. " " .. testSource .. " " .. string.format("|cff%s[Divine Shield]|r", CAT_COLORS.defensive))
    ShowVisualMessage(CAT_ICONS.totem .. " " .. testSource .. " " .. string.format("|cff%s[Tremor Totem]|r", CAT_COLORS.totem))
end
AruiQOL_SpellTest = DoTest

-- ==================== INIT ====================

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        self:UnregisterEvent("PLAYER_LOGIN")

        local db = AruiQOLDB and AruiQOLDB.SpellAnnounce
        if not db then return end

        -- Clear class color cache
        local cacheFrame = CreateFrame("Frame")
        cacheFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
        cacheFrame:RegisterEvent("PARTY_MEMBERS_CHANGED")
        cacheFrame:RegisterEvent("RAID_ROSTER_UPDATE")
        cacheFrame:SetScript("OnEvent", function()
            wipe(classColorCache)
        end)

        -- Create visual display anchor
        displayAnchor = CreateFrame("Frame", "AruiQOLSpellAnchor", UIParent)
        displayAnchor:SetSize(400, (MAX_LINES * (DEFAULT_SIZE + LINE_PADDING)) + 20)
        displayAnchor:SetPoint("CENTER", UIParent, "CENTER", 0, 200)

        if db.anchorPos then
            local pos = db.anchorPos
            displayAnchor:ClearAllPoints()
            displayAnchor:SetPoint(pos.point, UIParent, pos.relativePoint, pos.xOfs, pos.yOfs)
        end

        displayAnchor:SetMovable(true)
        displayAnchor:EnableMouse(false)
        displayAnchor:RegisterForDrag("LeftButton")
        displayAnchor:SetScript("OnDragStart", function(self)
            if anchorVisible then self:StartMoving() end
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
        displayAnchor:SetScript("OnUpdate", VisualOnUpdate)

        -- Close button
        local closeBtn = CreateFrame("Button", nil, displayAnchor, "UIPanelCloseButton")
        closeBtn:SetSize(20, 20)
        closeBtn:SetPoint("TOPRIGHT", displayAnchor, "TOPRIGHT", 2, 2)
        closeBtn:SetScript("OnClick", ToggleAnchor)
        closeBtn:Hide()
        displayAnchor.closeBtn = closeBtn

        -- Label
        local anchorLabel = displayAnchor:CreateFontString(nil, "OVERLAY")
        anchorLabel:SetFont(FONT_PATH, 10)
        anchorLabel:SetPoint("TOPLEFT", displayAnchor, "TOPLEFT", 6, -4)
        anchorLabel:SetTextColor(0.6, 0.6, 0.6, 0.8)
        anchorLabel:SetText("Spell Announce")
        anchorLabel:Hide()
        displayAnchor.anchorLabel = anchorLabel

        -- Chat queue processor
        chatFrame = CreateFrame("Frame")
        chatFrame:SetScript("OnUpdate", ProcessChatQueue)

        -- Combat log listener
        local spellFrame = CreateFrame("Frame")
        spellFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        spellFrame:SetScript("OnEvent", function(self, ev, ...)
            if ev ~= "COMBAT_LOG_EVENT_UNFILTERED" then return end
            OnCombatLogEvent(...)
        end)

        -- Slash commands
        SLASH_ARUIQOLSPELL1 = "/aqolspell"
        SlashCmdList["ARUIQOLSPELL"] = ToggleAnchor
    end
end)
