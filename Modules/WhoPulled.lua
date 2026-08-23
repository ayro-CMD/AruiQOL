-- Arui QOL - WhoPulled Module

local WhoPulled = {}


local pullState = {
    lastPullTime = nil,
    lastBossName = nil,
    whoPulled = nil,
    isPetPull = nil,
    pullSpell = nil,
    inCombat = false,
    firstCombatUnit = nil,
    firstCombatTime = nil,
    combatEntries = {},
    bossFound = false,
}


local CLASS_COLORS = {
    WARRIOR     = "cffC79C6C",
    MAGE        = "cff69CCF0",
    ROGUE       = "cffFFF569",
    DRUID       = "cffFF7D0A",
    HUNTER      = "cffABD473",
    SHAMAN      = "cff0070DE",
    PRIEST      = "cffFFFFFF",
    WARLOCK     = "cff9482C9",
    PALADIN     = "cffF58CBA",
    DEATHKNIGHT = "cffC41F3B",
}

local function ColorName(name)
    if not name then return "|cffffffffUnknown|r" end
    local displayName = string.gsub(name, "%-.*", "")

    local unit = nil
    if UnitName("player") == name then unit = "player" end
    if not unit and GetNumRaidMembers() > 0 then
        for i = 1, GetNumRaidMembers() do
            if UnitName("raid" .. i) == name then unit = "raid" .. i; break end
        end
    end
    if not unit and GetNumPartyMembers() > 0 then
        for i = 1, GetNumPartyMembers() do
            if UnitName("party" .. i) == name then unit = "party" .. i; break end
        end
    end

    if unit then
        local _, class = UnitClass(unit)
        if class and CLASS_COLORS[class] then
            return "|" .. CLASS_COLORS[class] .. displayName .. "|r"
        end
    end

    return "|cffffffff" .. displayName .. "|r"
end

local BOSS_CLASSIFICATIONS_BOSS = { worldboss = true, rareelite = true }
local BOSS_CLASSIFICATIONS_DUNGEON = { worldboss = true, rareelite = true, elite = true }

local function GetBossClassifications()
    local db = AruiQOLDB and AruiQOLDB.WhoPulled
    if not db then return BOSS_CLASSIFICATIONS_BOSS end
    local mode = db.trackMode or "boss"
    if mode == "dungeon" then
        return BOSS_CLASSIFICATIONS_DUNGEON
    end
    return BOSS_CLASSIFICATIONS_BOSS
end

local function ScanForBoss()
    local classifications = GetBossClassifications()

    
    for i = 1, 5 do
        if UnitExists("boss" .. i) then
            return UnitName("boss" .. i)
        end
    end

    -- strunz non copiare
    for _, unit in ipairs({ "target", "focus", "mouseover" }) do
        if UnitExists(unit) and UnitAffectingCombat(unit) then
            local class = UnitClassification(unit)
            if classifications[class] then
                return UnitName(unit)
            end
        end
    end

    -- centolire
    if GetNumRaidMembers() > 0 then
        for i = 1, GetNumRaidMembers() do
            local targetUnit = "raid" .. i .. "target"
            if UnitExists(targetUnit) then
                local class = UnitClassification(targetUnit)
                if classifications[class] then
                    return UnitName(targetUnit)
                end
            end
        end
    elseif GetNumPartyMembers() > 0 then
        -- gennarino
        for i = 1, GetNumPartyMembers() do
            local targetUnit = "party" .. i .. "target"
            if UnitExists(targetUnit) then
                local class = UnitClassification(targetUnit)
                if classifications[class] then
                    return UnitName(targetUnit)
                end
            end
        end
    end

    return nil
end

local function ResetPullState()
    wipe(pullState.combatEntries)
    pullState.firstCombatUnit = nil
    pullState.firstCombatTime = nil
    pullState.pullSpell = nil
    pullState.isPetPull = nil
    pullState.bossFound = false
end

local function ScanGroupCombat()
    local db = AruiQOLDB and AruiQOLDB.WhoPulled
    if not db or not db.enabled then return end

    local now = GetTime()

    local function CheckUnit(unit, petUnit)
        if UnitExists(unit) and UnitAffectingCombat(unit) then
            local name = UnitName(unit)
            if name and not pullState.combatEntries[name] then
                pullState.combatEntries[name] = now

                if not pullState.firstCombatTime or now < pullState.firstCombatTime then
                    pullState.firstCombatUnit = name
                    pullState.firstCombatTime = now
                    pullState.isPetPull = nil
                end
            end
        end

        if petUnit and UnitExists(petUnit) and UnitAffectingCombat(petUnit) then
            local petName = UnitName(petUnit)
            local ownerName = UnitName(unit)
            if petName and not pullState.combatEntries[petName] then
                pullState.combatEntries[petName] = now
                if not pullState.firstCombatTime or now < pullState.firstCombatTime then
                    pullState.firstCombatUnit = ownerName or petName
                    pullState.firstCombatTime = now
                    pullState.isPetPull = ownerName and petName or nil
                end
            end
        end
    end

    if GetNumRaidMembers() > 0 then
        for i = 1, GetNumRaidMembers() do
            CheckUnit("raid" .. i, "raidpet" .. i)
        end
    else
        CheckUnit("player", "pet")
        for i = 1, GetNumPartyMembers() do
            CheckUnit("party" .. i, "partypet" .. i)
        end
    end
end

local function AnnouncePull()
    local db = AruiQOLDB and AruiQOLDB.WhoPulled
    if not db or not db.enabled then return end

    if not pullState.firstCombatUnit then return end

    pullState.whoPulled = pullState.firstCombatUnit
    pullState.lastPullTime = time()
    pullState.lastBossName = ScanForBoss()

    local trackMode = db.trackMode or "boss"


    if trackMode ~= "all" and not pullState.lastBossName then
    
        return
    end

    pullState.bossFound = true

    local coloredName = ColorName(pullState.whoPulled)
    local msg = "|cff88ccff[WhoPulled]|r " .. coloredName

    if pullState.isPetPull then
        msg = msg .. " (pet: " .. pullState.isPetPull .. ")"
    end

    if pullState.lastBossName then
        msg = msg .. " pulled |cffff5555" .. pullState.lastBossName .. "|r"
    end

    if pullState.pullSpell then
        msg = msg .. " with |cff88ff88" .. pullState.pullSpell .. "|r"
    end

    if db.announceSelf ~= false then
        print(msg)
    end

    if db.announceChat then
        local plainMsg = pullState.whoPulled
        if pullState.isPetPull then plainMsg = plainMsg .. " (pet)" end
        if pullState.lastBossName then plainMsg = plainMsg .. " pulled " .. pullState.lastBossName end
        if pullState.pullSpell then plainMsg = plainMsg .. " with " .. pullState.pullSpell end

        local channel = db.announceChannel or "AUTO"
        if channel == "SELF" then
            
        elseif channel == "RAID_WARNING" then
            if GetNumRaidMembers() > 0 then
                SendChatMessage(plainMsg, "RAID_WARNING")
            elseif GetNumPartyMembers() > 0 then
                SendChatMessage(plainMsg, "PARTY")
            end
        elseif channel == "RAID" then
            if GetNumRaidMembers() > 0 then
                SendChatMessage(plainMsg, "RAID")
            elseif GetNumPartyMembers() > 0 then
                SendChatMessage(plainMsg, "PARTY")
            end
        elseif channel == "PARTY" then
            if GetNumPartyMembers() > 0 then
                SendChatMessage(plainMsg, "PARTY")
            end
        elseif channel == "SAY" then
            SendChatMessage(plainMsg, "SAY")
        else
            
            if GetNumRaidMembers() > 0 then
                SendChatMessage(plainMsg, "RAID")
            elseif GetNumPartyMembers() > 0 then
                SendChatMessage(plainMsg, "PARTY")
            end
        end
    end
end


local AFFIL_MASK = 0x00000007
local HOSTILE_MASK = 0x00000040

local cleuFirstHostile = {}
local cleuFirstSpell = {}

local function OnCLEU(...)
    if pullState.inCombat then return end

    local args = { ... }
    local subEvent, srcName, srcFlags, dstName, dstFlags, spellName

    -- 3.3.5 format
    if type(args[3]) == "string" then
        subEvent  = args[2]
        srcName   = args[4]
        srcFlags  = args[5]
        dstName   = args[7]
        dstFlags  = args[8]
        spellName = args[10]
    else
        -- Cata+ format
        subEvent  = args[2]
        srcName   = args[5]
        srcFlags  = args[6]
        dstName   = args[9]
        dstFlags  = args[11]
        spellName = args[13]
    end

    if not subEvent or not srcFlags or not dstFlags then return end

    if subEvent == "UNIT_DIED" or subEvent == "UNIT_DESTROYED" or subEvent == "PARTY_KILL" then return end

    if bit.band(srcFlags, AFFIL_MASK) ~= 0 and bit.band(dstFlags, HOSTILE_MASK) ~= 0 then
        if srcName and not cleuFirstHostile[srcName] then
            cleuFirstHostile[srcName] = GetTime()
            if spellName and subEvent and (
                string.find(subEvent, "SPELL") or
                string.find(subEvent, "RANGE")
            ) then
                if spellName and spellName ~= "" then
                    cleuFirstSpell[srcName] = spellName
                end
            elseif subEvent and (
                subEvent == "SWING_DAMAGE" or subEvent == "SWING_MISSED"
            ) then
                cleuFirstSpell[srcName] = "Auto Attack"
            end
        end
    end
end

local pollFrame = nil
local pollAccum = 0
local POLL_INTERVAL = 0.1
local ANNOUNCE_DELAY = 0.5
local BOSS_SCAN_TIMEOUT = 3.0
local combatStartTime = nil

local function PollOnUpdate(self, elapsed)
    pollAccum = pollAccum + elapsed
    if pollAccum < POLL_INTERVAL then return end
    pollAccum = 0

    if pullState.inCombat then return end

    ScanGroupCombat()

    if not pullState.firstCombatTime then return end

    local now = GetTime()
    local elapsedSinceCombat = now - pullState.firstCombatTime

    
    if cleuFirstHostile then
        local bestName = pullState.firstCombatUnit
        local bestTime = cleuFirstHostile[bestName] or math.huge

        for name, t in pairs(cleuFirstHostile) do
            if t < bestTime then
                bestName = name
                bestTime = t
            end
        end

        if bestTime < math.huge then
            pullState.firstCombatUnit = bestName
            if cleuFirstSpell[bestName] then
                pullState.pullSpell = cleuFirstSpell[bestName]
            end
        end
    end

    local trackMode = (AruiQOLDB and AruiQOLDB.WhoPulled and AruiQOLDB.WhoPulled.trackMode) or "boss"

    if trackMode ~= "all" then
        
        local bossName = ScanForBoss()
        if bossName then
            pullState.lastBossName = bossName
            pullState.inCombat = true
            pullState.bossFound = true
            AnnouncePull()
            return
        end

        
        if elapsedSinceCombat < BOSS_SCAN_TIMEOUT then
            return
        end

        pullState.inCombat = true
        return
    end

    if elapsedSinceCombat < ANNOUNCE_DELAY then return end

    pullState.inCombat = true
    AnnouncePull()
end

local eventFrame = nil

local function OnEvent(self, ev, ...)
    local db = AruiQOLDB and AruiQOLDB.WhoPulled
    if not db or not db.enabled then return end

    if ev == "PLAYER_REGEN_DISABLED" then
        ResetPullState()
        wipe(cleuFirstHostile)
        wipe(cleuFirstSpell)
        pullState.inCombat = false
        combatStartTime = GetTime()
        pollAccum = 0
        if pollFrame then pollFrame:Show() end

    elseif ev == "PLAYER_REGEN_ENABLED" then
        pullState.inCombat = false
        combatStartTime = nil
        if pollFrame then pollFrame:Hide() end

    elseif ev == "ENCOUNTER_START" then
        
        local encounterID, encounterName = ...
        pullState.lastBossName = encounterName
        pullState.lastPullTime = time()

        if not pullState.inCombat then
            if not pullState.whoPulled or pullState.whoPulled == "" then
                pullState.lastBossName = encounterName
                if pullState.firstCombatUnit then
                    pullState.inCombat = true
                    pullState.bossFound = true
                    AnnouncePull()
                end
            end
        end

    elseif ev == "ZONE_CHANGED_NEW_AREA" then
        local _, zoneType = IsInInstance()
        if zoneType == "raid" or zoneType == "party" then
            self:RegisterEvent("PLAYER_REGEN_DISABLED")
            self:RegisterEvent("PLAYER_REGEN_ENABLED")
            self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
            self:RegisterEvent("ENCOUNTER_START")
            if pollFrame then pollFrame:Show() end
        else
            self:UnregisterEvent("PLAYER_REGEN_DISABLED")
            self:UnregisterEvent("PLAYER_REGEN_ENABLED")
            self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
            self:UnregisterEvent("ENCOUNTER_START")
            if pollFrame then pollFrame:Hide() end
        end

    elseif ev == "COMBAT_LOG_EVENT_UNFILTERED" then
        OnCLEU(...)
    end
end


local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        self:UnregisterEvent("PLAYER_LOGIN")

        local db = AruiQOLDB and AruiQOLDB.WhoPulled
        if not db then return end

        pollFrame = CreateFrame("Frame")
        pollFrame:Hide()
        pollFrame:SetScript("OnUpdate", PollOnUpdate)

        eventFrame = CreateFrame("Frame")
        eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
        eventFrame:RegisterEvent("ENCOUNTER_START")
        eventFrame:SetScript("OnEvent", OnEvent)

        C_Timer.After(2, function()
            OnEvent(eventFrame, "ZONE_CHANGED_NEW_AREA")
        end)

        print("|cff88ccff[WhoPulled]|r Loaded - Mode: " .. (db.trackMode or "boss"))
    end
end)

SLASH_ARUIQOLWP1 = "/aqolwp"
SlashCmdList["ARUIQOLWP"] = function(msg)
    local db = AruiQOLDB and AruiQOLDB.WhoPulled
    if not db then return end

    local cmd = string.lower(msg or "")

    if cmd == "mode" then
        local modes = { "boss", "dungeon", "all" }
        local current = db.trackMode or "boss"
        local nextIndex = 1
        for i, m in ipairs(modes) do
            if m == current then nextIndex = (i % #modes) + 1; break end
        end
        db.trackMode = modes[nextIndex]
        local modeNames = { boss = "|cffff5555Boss Only|r", dungeon = "|cff55ff55Boss + Dungeon|r", all = "|cff00ff00All (Boss + Adds)|r" }
        print("|cff88ccff[WhoPulled]|r Track mode: " .. (modeNames[db.trackMode] or db.trackMode))
    elseif cmd == "test" then
        local _, itype = IsInInstance()
        print("|cff88ccff[WhoPulled]|r Test:")
        print("  Enabled = " .. (db.enabled and "|cff00ff00ON|r" or "|cffff0000OFF|r"))
        print("  Mode = " .. (db.trackMode == "boss" and "|cffff5555Boss Only|r" or db.trackMode == "dungeon" and "|cff55ff55Boss + Dungeon|r" or "|cff00ff00All|r"))
        print("  Channel = " .. (db.announceChannel or "Auto"))
        print("  In Instance = " .. ((itype == "raid" or itype == "party") and "|cff00ff00YES|r" or "|cffff0000NO|r") .. " (" .. (itype or "none") .. ")")
        print("  Last Pull = " .. (pullState.whoPulled and ColorName(pullState.whoPulled) or "None"))
        if pullState.lastBossName then print("  Last Boss = |cffff5555" .. pullState.lastBossName .. "|r") end
        if pullState.pullSpell then print("  Pull Spell = |cff88ff88" .. pullState.pullSpell .. "|r") end
        local boss = ScanForBoss()
        print("  Boss Scan = " .. (boss and "|cff00ff00" .. boss .. "|r" or "|cffff0000No boss found|r"))
    elseif pullState.whoPulled then
        local t = date("%H:%M:%S", pullState.lastPullTime or 0)
        local info = ColorName(pullState.whoPulled)
        if pullState.lastBossName then info = info .. " pulled " .. pullState.lastBossName end
        if pullState.pullSpell then info = info .. " with " .. pullState.pullSpell end
        print("|cff88ccff[WhoPulled]|r Last: " .. info .. " at " .. t)
    else
        print("|cff88ccff[WhoPulled]|r No pull recorded yet")
    end
end

_G.AruiQOLWhoPulled = WhoPulled
