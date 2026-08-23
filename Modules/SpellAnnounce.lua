-- Arui QOL - Spell Announce Module
local MAX_LINES      = 6
local SHOW_DURATION  = 5.0
local FADE_START     = 3.0
local LINE_PADDING   = 6
local DEFAULT_SIZE   = 15
local FONT_PATH      = "Fonts\\ARIALN.TTF"
local TOTEM_SLOTS    = MAX_TOTEMS or 4

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


-- Totems
local TOTEM_SPELLS = {
    -- Earth
    [8143] = "Tremor Totem",
    [8170] = "Cleansing Totem",
    [8181] = "Frost Resistance Totem",
    -- Fire
    [8184] = "Fire Resistance Totem",
    -- Water
    [5394] = "Healing Stream Totem",
    [983481] = "Ebbing Tides Totem",
    -- Air
    [8163] = "Nature Resistance Totem",

}

-- Defensive cooldowns
local DEFENSIVE_SPELLS = {
    --CLASSI Base
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
    -- Druid
    [22812] = "Barkskin",
    [61336] = "Survival Instincts",
    [86382] = "Efflorescence",
    -- Death Knight
    [48707] = "Anti-Magic Shell",
    [51052] = "Anti-Magic Zone",
    -- Mage
    [45438] = "Ice Block",
    [66] = "Invisibility",
    -- Rogue
    [5277] = "Evasion",
    [31224] = "Cloak of Shadows",
    -- Hunter
    [19263] = "Deterrence",
    [34477] = "Misdirection",
    -- Warlock
    [698] = "Ritual of Summoning",
    -- Shaman
    --CLASSI COA
    --Thinker
    [520445] = "Auto-Ress-Device",
    [802175] = "Defibrillate",
    --Necromancer
    --[] = "",
    --[] = "",
    --Cultist
    --[] = "",
    --[] = "",
    --Ranger
    --[] = "",
    --[] = "",
    --Pyromancer
    --[] = "",
    --[] = "",
    --Starcaller
    --[] = "",
    --[] = "",
    --SunCleric
    --[] = "",
    --[] = "",
    --Runemster
    --[] = "",
    --[] = "",
    --Primalist
    --[] = "",
    --[] = "",
    --Reaper
    --[] = "",
    --[] = "",
    --Venomancer
    --[] = "",
    --[] = "",
    --Chronomancer
    --[] = "",
    --[] = "",
    --Bloodmage
    --[] = "",
    --[] = "",
    --Guardian
    --[] = "",
    --[] = "",
    --Stormbringer
    --[] = "",
    --[] = "",
    --Felsworn
    --[] = "",
    --[] = "",
    --Barbarian
    --[] = "",
    --[] = "",
    --WitchDoctor
    --[] = "",
    --[] = "",
    --WitchHunter
    --[] = "",
    --[] = "",
    --Templar
    --[] = "",
    --[] = "",

}

-- Important interrupts/cc
local IMPORTANT_SPELLS = {
    [78675] = "Solar Beam",
    [30283] = "Shadowfury",
    [805114] = "Mass Nightmare",

}

local TOTEM_BATCH_NAMES = {
    ["Call of the Elements"] = true,
    ["Call of the Ancestors"] = true,
    ["Call of the Spirits"] = true,
}

local ALL_TRACKED = {}
for id, name in pairs(TOTEM_SPELLS) do ALL_TRACKED[id] = { name = name, cat = "totem" } end
for id, name in pairs(DEFENSIVE_SPELLS) do ALL_TRACKED[id] = { name = name, cat = "defensive" } end
for id, name in pairs(IMPORTANT_SPELLS) do ALL_TRACKED[id] = { name = name, cat = "important" } end

local SPELL_NAME_TO_ID = {}
for id, data in pairs(ALL_TRACKED) do
    if data.name and not SPELL_NAME_TO_ID[data.name] then
        SPELL_NAME_TO_ID[data.name] = id
    end
end

local classColorCache = {}
local activeMessages  = {}
local displayAnchor   = nil
local anchorVisible   = false


local spellTargets = {}


local recentAnnounces = {}
local DEDUP_WINDOW = 2.0


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

local function FindUnitByGUID(guid)
    if not guid then return nil end
    if UnitGUID("player") == guid then return "player" end
    if GetNumPartyMembers then
        for i = 1, GetNumPartyMembers() do
            if UnitGUID("party" .. i) == guid then return "party" .. i end
        end
    end
    if GetNumRaidMembers then
        for i = 1, GetNumRaidMembers() do
            if UnitGUID("raid" .. i) == guid then return "raid" .. i end
        end
    end
    return nil
end

local function IsGroupMember(sourceGUID)
    if not sourceGUID then return false end
    if UnitGUID("player") == sourceGUID then return true end
    if GetNumPartyMembers then
        for i = 1, GetNumPartyMembers() do
            if UnitGUID("party" .. i) == sourceGUID then return true end
        end
    end
    if GetNumRaidMembers then
        for i = 1, GetNumRaidMembers() do
            if UnitGUID("raid" .. i) == sourceGUID then return true end
        end
    end
    return false
end

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

local CAT_COLORS = {
    totem     = "33ff99",
    defensive = "ff9933",
    important = "ff3366",
}


local function AnnounceSpell(spellId, sourceName, sourceGUID, targetName)
    local db = AruiQOLDB and AruiQOLDB.SpellAnnounce
    if not db or not db.enabled then return end

    local tracked = ALL_TRACKED[spellId]
    if not tracked then return end

    if tracked.cat == "totem" and not db.trackTotems then return end
    if tracked.cat == "defensive" and not db.trackDefensives then return end
    if tracked.cat == "important" and not db.trackImportant then return end

    if db.onlyOwnCDs and tracked.cat == "defensive" then
        local playerGUID = UnitGUID("player")
        if sourceGUID ~= playerGUID then return end
    end


    local dedupKey = tostring(sourceGUID) .. ":" .. tostring(spellId)
    local now = GetTime()
    if recentAnnounces[dedupKey] and (now - recentAnnounces[dedupKey]) < DEDUP_WINDOW then
        return
    end
    recentAnnounces[dedupKey] = now

    local sourceColored = ColorName(sourceName, sourceGUID, false)
    local catColor = CAT_COLORS[tracked.cat] or "ffffff"
    local spellColored = string.format("|cff%s%s|r", catColor, tracked.name)

    local msg = nil
    local chatMsg = nil

    if tracked.cat == "defensive" then
        
        if targetName and targetName ~= "" then
            local targetStripped = string.gsub(targetName, "%-.*", "")
            local targetColored = ColorName(targetName, nil, false)
            msg = sourceColored .. " cast " .. spellColored .. " on " .. targetColored
            chatMsg = string.gsub(sourceName, "%-.*", "") .. " cast " .. tracked.name .. " on " .. targetStripped
        else
            
            msg = sourceColored .. " cast " .. spellColored
            chatMsg = string.gsub(sourceName or "Unknown", "%-.*", "") .. " cast " .. tracked.name
        end
    elseif tracked.cat == "totem" then
       
        msg = sourceColored .. " - " .. spellColored
        chatMsg = string.gsub(sourceName or "Unknown", "%-.*", "") .. " - " .. tracked.name
    else
        
        msg = sourceColored .. " - " .. spellColored .. "!!"
        chatMsg = string.gsub(sourceName or "Unknown", "%-.*", "") .. " - " .. tracked.name .. "!!"
    end

    if db.visualEnabled then
        ShowVisualMessage(msg)
    end

    if db.chatEnabled then
        local output = db.output or "Auto"
        if output == "Self" then
            print("|cff88ccff[SpellAnnounce]|r " .. msg)
        elseif output == "Say" then
            SendThrottledChat(chatMsg, "SAY")
        elseif output == "Auto" then
            if GetNumRaidMembers and GetNumRaidMembers() >= 1 then
                SendThrottledChat(chatMsg, "RAID")
            elseif GetNumPartyMembers and GetNumPartyMembers() >= 1 then
                SendThrottledChat(chatMsg, "PARTY")
            else
                SendThrottledChat(chatMsg, "SAY")
            end
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

local function OnCombatLogEvent(...)
    local db = AruiQOLDB and AruiQOLDB.SpellAnnounce
    if not db or not db.enabled then return end

    local args = { ... }
    if #args < 11 then return end

    local combatEvent, sourceGUID, sourceName, spellId, spellName
    local destGUID, destName

    if type(args[3]) == "boolean" then
        combatEvent = args[2]
        sourceGUID  = args[4]
        sourceName  = args[5]
        destGUID    = args[8]
        destName    = args[9]
        spellId     = args[12]
        spellName   = args[13]
    else
        combatEvent = args[2]
        sourceGUID  = args[3]
        sourceName  = args[4]
        destGUID    = args[7]
        destName    = args[8]
        spellId     = args[11]
        spellName   = args[12]
    end

    if not combatEvent or not spellId then return end
    if combatEvent ~= "SPELL_CAST_SUCCESS" and combatEvent ~= "SPELL_SUMMON" then return end
    if not IsGroupMember(sourceGUID) then return end

    if spellDebug then
        print("|cffffaa00[SNIFF-COMBAT]|r event=" .. tostring(combatEvent) ..
            " source=" .. tostring(sourceName) ..
            " spellId=" .. tostring(spellId) ..
            " spell=" .. tostring(spellName))
    end

    AnnounceSpell(spellId, sourceName, sourceGUID, destName)
end

local batchAnnounced = {}

local function ScanAndAnnounceTotems(sourceName, sourceGUID, passNum)
    local db = AruiQOLDB and AruiQOLDB.SpellAnnounce
    if not db or not db.enabled or not db.trackTotems then return end

    local now = GetTime()
    for slot = 1, TOTEM_SLOTS do
     
        local haveTotem, totemName, startTime, duration, icon = GetTotemInfo(slot)

        if spellDebug then
            print("|cffffaa00[TOTEM-SCAN]|r pass=" .. (passNum or 0) ..
                " slot=" .. slot ..
                " have=" .. tostring(haveTotem) ..
                " name=" .. tostring(totemName) ..
                " start=" .. string.format("%.1f", startTime or 0) ..
                " dur=" .. tostring(duration) ..
                " age=" .. string.format("%.1f", startTime and (now - startTime) or 999))
        end

        if haveTotem and totemName and totemName ~= "" then
         
            if startTime and (now - startTime) < 5.0 then
              
                if not batchAnnounced[totemName] then
                    batchAnnounced[totemName] = true
                    local foundId = SPELL_NAME_TO_ID[totemName]
                    if foundId then
                        AnnounceSpell(foundId, sourceName, sourceGUID, nil)
                    elseif spellDebug then
                        print("|cffffaa00[TOTEM-SCAN]|r Unknown totem: " .. totemName)
                    end
                end
            end
        end
    end
end

local function ScheduleTotemScan(sourceName, sourceGUID)
   
    wipe(batchAnnounced)

    local delays = {0.3, 0.8, 1.5}
    for i, delay in ipairs(delays) do
        local f = CreateFrame("Frame")
        f._passNum = i
        f:SetScript("OnUpdate", function(self, elapsed)
            self._elapsed = (self._elapsed or 0) + elapsed
            if self._elapsed >= delay then
                ScanAndAnnounceTotems(sourceName, sourceGUID, self._passNum)
                self:SetScript("OnUpdate", nil)
            end
        end)
    end
end

local function OnUnitSpellcastSucceeded(unit, spellName, spellRank, lineID, spellID)
    local db = AruiQOLDB and AruiQOLDB.SpellAnnounce
    if not db or not db.enabled then return end
    if not spellName then return end

    local sourceGUID = UnitGUID(unit)
    local sourceName = UnitName(unit)

    if not sourceGUID then
        if sourceName and sourceName == UnitName("player") then
            sourceGUID = UnitGUID("player")
        else
            return
        end
    end

    if not IsGroupMember(sourceGUID) then return end

    if TOTEM_BATCH_NAMES[spellName] then
        if db.trackTotems then
            ScheduleTotemScan(sourceName, sourceGUID)
        end
        return
    end

    local tracked = nil
    local foundId = nil
    if spellID and type(spellID) == "number" and spellID > 0 then
        tracked = ALL_TRACKED[spellID]
        foundId = spellID
    end
    if not tracked then
        foundId = SPELL_NAME_TO_ID[spellName]
        if foundId then
            tracked = ALL_TRACKED[foundId]
        end
    end

    if not tracked or not foundId then return end

    local targetName = nil
    local cacheKey = unit .. ":" .. spellName
    if spellTargets[cacheKey] then
        targetName = spellTargets[cacheKey]
        spellTargets[cacheKey] = nil
    end

    if not targetName then
        local guidKey = sourceGUID .. ":" .. spellName
        if spellTargets[guidKey] then
            targetName = spellTargets[guidKey]
            spellTargets[guidKey] = nil
        end
    end

    
    if not targetName then
        local uTarget = unit .. "target"
        if UnitExists(uTarget) then
            local tName = UnitName(uTarget)
            if tName and IsGroupMember(UnitGUID(uTarget)) then
                targetName = tName
            end
        end
    end

    
    if not targetName and sourceGUID == UnitGUID("player") then
        if UnitExists("target") and (not UnitCanAttack("player", "target") or UnitIsFriend("player", "target")) then
            targetName = UnitName("target")
        end
    end

    AnnounceSpell(foundId, sourceName, sourceGUID, targetName)
end

local spellDebug = false

local function DoDebug()
    local db = AruiQOLDB and AruiQOLDB.SpellAnnounce
    if not db then
        print("|cff88ccff[SpellAnnounce]|r DB not found!")
        return
    end
    print("|cff88ccff[SpellAnnounce]|r === DEBUG ===")
    print("  enabled: " .. tostring(db.enabled))
    print("  trackTotems: " .. tostring(db.trackTotems))
    print("  trackDefensives: " .. tostring(db.trackDefensives))
    print("  trackImportant: " .. tostring(db.trackImportant))
    print("  visualEnabled: " .. tostring(db.visualEnabled))
    print("  chatEnabled: " .. tostring(db.chatEnabled))
    print("  output: " .. tostring(db.output))
    print("  onlyOwnCDs: " .. tostring(db.onlyOwnCDs))
    print("  playerGUID: " .. tostring(UnitGUID("player")))
end
AruiQOL_SpellDebug = DoDebug

local function ToggleSpellDebug()
    spellDebug = not spellDebug
    if spellDebug then
        print("|cff88ccff[SpellAnnounce]|r SNIFFER ON - cast spells now!")
    else
        print("|cff88ccff[SpellAnnounce]|r Sniffer OFF")
    end
end
AruiQOL_SpellSniff = ToggleSpellDebug


local function DoTest()
    local pName = UnitName("player")
    local pGUID = UnitGUID("player")
    local pColored = ColorName(pName, pGUID, false)

    ShowVisualMessage(pColored .. " - " .. string.format("|cff33ff99Tremor Totem|r"))
    local tColored = ColorName("TargetPlayer", nil, false)
    ShowVisualMessage(pColored .. " cast " .. string.format("|cffff9933Pain Suppression|r") .. " on " .. tColored)
    ShowVisualMessage(pColored .. " cast " .. string.format("|cffff9933Divine Shield|r") .. " on " .. pColored)
    ShowVisualMessage(pColored .. " - " .. string.format("|cffff3366Solar Beam|r") .. "!!")

    local db = AruiQOLDB and AruiQOLDB.SpellAnnounce
    if db and db.chatEnabled then
        local output = db.output or "Auto"
        local plainName = string.gsub(pName, "%-.*", "")
        print("|cff88ccff[SpellAnnounce]|r Test chat -> " .. output)
        if output == "Say" then
            SendThrottledChat(plainName .. " - Tremor Totem", "SAY")
        elseif output == "Self" then
            print("|cff88ccff[SpellAnnounce]|r " .. plainName .. " - Tremor Totem")
        end
    end
end
AruiQOL_SpellTest = DoTest

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        self:UnregisterEvent("PLAYER_LOGIN")

        local db = AruiQOLDB and AruiQOLDB.SpellAnnounce
        if not db then return end

        local cacheFrame = CreateFrame("Frame")
        cacheFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
        cacheFrame:RegisterEvent("PARTY_MEMBERS_CHANGED")
        cacheFrame:RegisterEvent("RAID_ROSTER_UPDATE")
        cacheFrame:SetScript("OnEvent", function()
            wipe(classColorCache)
        end)

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

        local closeBtn = CreateFrame("Button", nil, displayAnchor, "UIPanelCloseButton")
        closeBtn:SetSize(20, 20)
        closeBtn:SetPoint("TOPRIGHT", displayAnchor, "TOPRIGHT", 2, 2)
        closeBtn:SetScript("OnClick", ToggleAnchor)
        closeBtn:Hide()
        displayAnchor.closeBtn = closeBtn

        local anchorLabel = displayAnchor:CreateFontString(nil, "OVERLAY")
        anchorLabel:SetFont(FONT_PATH, 10)
        anchorLabel:SetPoint("TOPLEFT", displayAnchor, "TOPLEFT", 6, -4)
        anchorLabel:SetTextColor(0.6, 0.6, 0.6, 0.8)
        anchorLabel:SetText("Spell Announce")
        anchorLabel:Hide()
        displayAnchor.anchorLabel = anchorLabel

        chatFrame = CreateFrame("Frame")
        chatFrame:SetScript("OnUpdate", ProcessChatQueue)

        local sentFrame = CreateFrame("Frame")
        sentFrame:RegisterEvent("UNIT_SPELLCAST_SENT")
        sentFrame:SetScript("OnEvent", function(self, ev, ...)
            if ev ~= "UNIT_SPELLCAST_SENT" then return end
            local unit, sentSpellName, spellRank, targetName = ...

            if spellDebug then
                print("|cffffaa00[SNIFF-SENT]|r unit=" .. tostring(unit) ..
                    " spell=" .. tostring(sentSpellName) ..
                    " rank=" .. tostring(spellRank) ..
                    " target=" .. tostring(targetName))
            end

            if targetName and targetName ~= "" and sentSpellName then
                local key1 = unit .. ":" .. sentSpellName
                spellTargets[key1] = targetName

                
                local guid = UnitGUID(unit)
                if guid then
                    local key2 = guid .. ":" .. sentSpellName
                    spellTargets[key2] = targetName
                end
            end
        end)

       
        local unitSpellFrame = CreateFrame("Frame")
        unitSpellFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
        unitSpellFrame:SetScript("OnEvent", function(self, ev, ...)
            if ev ~= "UNIT_SPELLCAST_SUCCEEDED" then return end

            local unit, spellName, spellRank, lineID, spellID = ...

            if spellDebug then
                print("|cffffaa00[SNIFF-SUCCESS]|r unit=" .. tostring(unit) ..
                    " name=" .. tostring(spellName) ..
                    " rank=" .. tostring(spellRank) ..
                    " spellID=" .. tostring(spellID))
            end

            OnUnitSpellcastSucceeded(unit, spellName, spellRank, lineID, spellID)
        end)

        
        local combatFrame = CreateFrame("Frame")
        combatFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        combatFrame:SetScript("OnEvent", function(self, ev, ...)
            if ev ~= "COMBAT_LOG_EVENT_UNFILTERED" then return end
            OnCombatLogEvent(...)
        end)

        local cleanupFrame = CreateFrame("Frame")
        cleanupFrame:SetScript("OnUpdate", function(self, elapsed)
            self._elapsed = (self._elapsed or 0) + elapsed
            if self._elapsed > 5 then
                self._elapsed = 0
                wipe(spellTargets)
                local now = GetTime()
                for k, t in pairs(recentAnnounces) do
                    if (now - t) > DEDUP_WINDOW then
                        recentAnnounces[k] = nil
                    end
                end
            end
        end)

        SLASH_ARUIQOLSPELL1 = "/aqolspell"
        SlashCmdList["ARUIQOLSPELL"] = ToggleAnchor

        print("|cff88ccff[SpellAnnounce]|r Loaded - /aqolspell | /run AruiQOL_SpellTest() | /run AruiQOL_SpellSniff()")
    end
end)
