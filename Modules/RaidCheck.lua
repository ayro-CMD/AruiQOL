-- ============================================================
-- Arui QOL - RaidCheck Module
-- ============================================================

local RaidCheck = {}

-- ==================== WOTLK 3.3.5 FLASK IDs ====================

local FLASK_SPELLS = {
    -- Northrend Flasks
    [53755] = true,  -- Flask of the Frost Wyrm (SP)
    [53760] = true,  -- Flask of Endless Rage (AP)
    [53758] = true,  -- Flask of Stoneblood (HP)
    [53752] = true,  -- Flask of Pure Mojo (MP5)
    [67019] = true,  -- Flask of the North (SP - alchemist)
    [67016] = true,  -- Flask of the North (AP - alchemist)
    [67017] = true,  -- Flask of the North (STR - alchemist)
    -- Outland Flasks
    [28518] = true,  -- Flask of Pure Death
    [28540] = true,  -- Flask of Mighty Restoration
    [28520] = true,  -- Flask of Relentless Assault
    [28521] = true,  -- Flask of Fortification
    [28519] = true,  -- Flask of Blinding Light
    [42735] = true,  -- Flask of Chromatic Resistance
    -- Elixirs that count as flasks (Shattrath)
    [41609] = true,  -- Shattrath Flask of Pure Death
    [41610] = true,  -- Shattrath Flask of Fortification
    [41611] = true,  -- Shattrath Flask of Mighty Restoration
    [46837] = true,  -- Shattrath Flask of Relentless Assault
    [46839] = true,  -- Shattrath Flask of Blinding Light
    -- Ascension / Custom server flasks
    [54212] = true,  -- Flask of the North variant
    [62380] = true,  -- Flask of the North variant
    -- Battle Elixirs 
    [28497] = true,  -- Elixir of Mighty Agility
    [33721] = true,  -- Elixir of Mighty Strength
    [28491] = true,  -- Elixir of Mighty Thoughts
    [28501] = true,  -- Elixir of Spirit
    [28493] = true,  -- Elixir of Deadly Strikes
    [28490] = true,  -- Elixir of Expertise
    [28503] = true,  -- Elixir of Armor Piercing
    [28496] = true,  -- Elixir of Mighty Defense
    [28489] = true,  -- Elixir of Protection
    [28509] = true,  -- Elixir of Mighty Fortitude
    [28502] = true,  -- Elixir of Mighty Mageblood
    [28514] = true,  -- Elixir of Lightning Speed
    [28511] = true,  -- Elixir of Mighty Strength
}

-- ==================== WOTLK 3.3.5 FOOD BUFF IDs ====================

local FOOD_SPELLS = {
    -- Well Fed buffs
    [57367] = true,  -- Rhino's Warm Jurkey (40 stam)
    [57327] = true,  -- Dragonfin Filet (40 STR)
    [57294] = true,  -- Spicy Fried Herring (40 SPI)
    [57360] = true,  -- Snapper Extreme (40 EXP)
    [57291] = true,  -- Imperial Manta Steak (40 AP)
    [57332] = true,  -- Hearty Rhino (40 ARP)
    [57356] = true,  -- Firecracker Salmon (40 SP)
    [57325] = true,  -- Tender Shoveltusk Steak (40 HIT)
    [57358] = true,  -- Worg Tartare (40 Haste)
    [57365] = true,  -- Critter Bite Bites (40 crit)
    -- Fish Feasts
    [57399] = true,  -- Great Feast
    [57401] = true,  -- Fish Feast
    -- Lower tier food
    [43722] = true,  -- Crunchy Serpent (20 stat)
    [43764] = true,  -- Mok'Nathal Shortribs (20 stat)
    [33254] = true,  -- Spicy Crawfish
    [33256] = true,  -- Feltail Delight
    [33257] = true,  -- Golden Fish Sticks
    [33263] = true,  -- Skulled Berries
    [33265] = true,  -- Crunchy Serpent
    [33268] = true,  -- Mok'Nathal Shortribs
    [35272] = true,  -- Buzzard Bites
    [45619] = true,  -- Argent Tournament food
    -- Custom server / Ascension food
    [87635] = true,  [87552] = true,  [87549] = true,
    [87556] = true,  [87564] = true,  [87554] = true,
    [87562] = true,  [87550] = true,  [87548] = true,
    [87551] = true,  [87561] = true,  [87563] = true,
}

-- ==================== WELL FED NAME CACHE ====================

local wellFedName = nil
local WELL_FED_IDS = {57367, 57327, 57294, 57360, 57291, 57332, 57356, 57325, 57358, 57365}

local function GetWellFedName()
    if wellFedName then return wellFedName end
    for _, id in ipairs(WELL_FED_IDS) do
        local name = GetSpellInfo(id)
        if name and name ~= "" then
            wellFedName = name
            return name
        end
    end
    return nil
end

-- ==================== CHECK LOGIC ====================

local function CheckPlayer(unit)
    local hasFlask = false
    local hasFood = false

    for i = 1, 40 do
        local name, rank, icon, count, debuffType, duration, expirationTime,
              unitCaster, isStealable, shouldConsolidate, spellId = UnitBuff(unit, i)

        if not name then break end

        if FLASK_SPELLS[spellId] then
            hasFlask = true
        end

        if FOOD_SPELLS[spellId] then
            hasFood = true
        end

        -- Check by name as fallback
        if not hasFood then
            local wfName = GetWellFedName()
            if wfName and name == wfName then
                hasFood = true
            end
        end
    end

    return hasFlask, hasFood
end

local function DoCheck(checkType)
    local db = AruiQOLDB and AruiQOLDB.RaidCheck
    if not db or not db.enabled then return end

    local noFlask = {}
    local noFood = {}
    local noBoth = {}

    local numPlayers = 0

    if IsInRaid and IsInRaid() then
        numPlayers = GetNumRaidMembers()
        for i = 1, numPlayers do
            local unit = "raid" .. i
            if UnitExists(unit) and not UnitIsDeadOrGhost(unit) and UnitIsConnected(unit) then
                local hasFlask, hasFood = CheckPlayer(unit)
                local name = UnitName(unit)

                if not hasFlask and not hasFood then
                    table.insert(noBoth, name)
                elseif not hasFlask then
                    table.insert(noFlask, name)
                elseif not hasFood then
                    table.insert(noFood, name)
                end
            end
        end
    elseif GetNumPartyMembers and GetNumPartyMembers() > 0 then
        numPlayers = GetNumPartyMembers() + 1
        -- Check self
        local hasFlask, hasFood = CheckPlayer("player")
        local myName = UnitName("player")
        if not hasFlask and not hasFood then
            table.insert(noBoth, myName)
        elseif not hasFlask then
            table.insert(noFlask, myName)
        elseif not hasFood then
            table.insert(noFood, myName)
        end
        -- Check party
        for i = 1, GetNumPartyMembers() do
            local unit = "party" .. i
            if UnitExists(unit) and not UnitIsDeadOrGhost(unit) and UnitIsConnected(unit) then
                local hasFlask, hasFood = CheckPlayer(unit)
                local pName = UnitName(unit)
                if not hasFlask and not hasFood then
                    table.insert(noBoth, pName)
                elseif not hasFlask then
                    table.insert(noFlask, pName)
                elseif not hasFood then
                    table.insert(noFood, pName)
                end
            end
        end
    else
        print("|cff88ccff[RaidCheck]|r You are not in a group")
        return
    end

    -- Build output
    local totalChecked = #noFlask + #noFood + #noBoth
    local totalBad = #noFlask + #noFood + #noBoth - #noBoth  -- count unique players missing something

    -- Consolidate: noBoth players are in both lists
    local missingFlask = {}
    for _, name in ipairs(noFlask) do table.insert(missingFlask, name) end
    for _, name in ipairs(noBoth) do table.insert(missingFlask, name) end

    local missingFood = {}
    for _, name in ipairs(noFood) do table.insert(missingFood, name) end
    for _, name in ipairs(noBoth) do table.insert(missingFood, name) end

    -- Output
    local chatType = "RAID"
    if not (IsInRaid and IsInRaid()) then chatType = "PARTY" end

    if #missingFlask == 0 and #missingFood == 0 then
        local msg = "All players have flask and food! (" .. numPlayers .. " checked)"
        if checkType == "chat" then
            SendChatMessage(msg, chatType)
        end
        print("|cff88ccff[RaidCheck]|r " .. msg)
        return
    end

    -- Flask report
    if #missingFlask > 0 then
        local flaskStr = "No Flask (" .. #missingFlask .. "): " .. table.concat(missingFlask, ", ")
        if checkType == "chat" then
            -- Split long messages
            if #flaskStr > 240 then
                SendChatMessage("No Flask (" .. #missingFlask .. "):", chatType)
                local chunk = ""
                for i, name in ipairs(missingFlask) do
                    chunk = chunk .. name .. ", "
                    if #chunk > 200 then
                        SendChatMessage(chunk, chatType)
                        chunk = ""
                    end
                end
                if chunk ~= "" then SendChatMessage(chunk, chatType) end
            else
                SendChatMessage(flaskStr, chatType)
            end
        end
        print("|cffff5555[RaidCheck]|r |cffff5555No Flask (" .. #missingFlask .. "):|r " .. table.concat(missingFlask, ", "))
    end

    -- Food report
    if #missingFood > 0 then
        local foodStr = "No Food (" .. #missingFood .. "): " .. table.concat(missingFood, ", ")
        if checkType == "chat" then
            if #foodStr > 240 then
                SendChatMessage("No Food (" .. #missingFood .. "):", chatType)
                local chunk = ""
                for i, name in ipairs(missingFood) do
                    chunk = chunk .. name .. ", "
                    if #chunk > 200 then
                        SendChatMessage(chunk, chatType)
                        chunk = ""
                    end
                end
                if chunk ~= "" then SendChatMessage(chunk, chatType) end
            else
                SendChatMessage(foodStr, chatType)
            end
        end
        print("|cffffaa00[RaidCheck]|r |cffffaa00No Food (" .. #missingFood .. "):|r " .. table.concat(missingFood, ", "))
    end

    -- Summary
    local summary = string.format("Checked %d players - Missing: %d flask, %d food",
        numPlayers, #missingFlask, #missingFood)
    if checkType == "chat" then
        SendChatMessage(summary, chatType)
    end
    print("|cff88ccff[RaidCheck]|r " .. summary)
end

-- ==================== INIT ====================

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        self:UnregisterEvent("PLAYER_LOGIN")

        local db = AruiQOLDB and AruiQOLDB.RaidCheck
        if not db then return end

        print("|cff88ccff[RaidCheck]|r Loaded - /aqolrc to check")
    end
end)

-- ==================== SLASH COMMANDS ====================

SLASH_ARUIQOLRC1 = "/aqolrc"
SlashCmdList["ARUIQOLRC"] = function(msg)
    local cmd = string.lower(msg or "")
    if cmd == "chat" then
        DoCheck("chat")
    elseif cmd == "self" or cmd == "" then
        DoCheck("self")
    else
        print("|cff88ccff[RaidCheck]|r Commands:")
        print("  /aqolrc - Check flask/food (self only)")
        print("  /aqolrc chat - Check and post to raid/party chat")
    end
end

_G.AruiQOLRaidCheck = RaidCheck
_G.AruiQOLRaidCheckDoCheck = DoCheck
