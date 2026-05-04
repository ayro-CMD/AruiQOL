-- ============================================================
-- Arui QOL - Track-o-Matique Module
-- Auto-switch tracking based on target creature type
-- Rewritten from Track-o-Matique 3.4.7 by Anyia
-- No Ace3 dependency - pure vanilla Lua
-- Works on classless servers where any class can have tracking
-- ============================================================

local NONE_TEX = "Interface\\Minimap\\Tracking\\None"
local FEIGN_DEATH = GetSpellInfo(5384)
local SHADOWMELD = GetSpellInfo(58984)

-- Creature type -> tracking texture mapping
local type2texture = {
    Beast     = "Interface\\Icons\\Ability_Tracking",
    Demon     = "Interface\\Icons\\Spell_Shadow_SummonFelHunter",
    Dragonkin = "Interface\\Icons\\INV_Misc_Head_Dragon_01",
    Elemental = "Interface\\Icons\\Spell_Frost_SummonWaterElemental",
    Giant     = "Interface\\Icons\\Ability_Racial_Avatar",
    Humanoid  = "Interface\\Icons\\Spell_Holy_PrayerOfHealing",
    Undead    = "Interface\\Icons\\Spell_Shadow_DarkSummoning",
}

-- Reverse lookup
local texture2type = {}
for typ, tex in pairs(type2texture) do
    texture2type[tex] = typ
end

-- Internal state
local texture2index = {}
local index2texture = {}
local type2index = {}
local expectedTrackTexture = nil
local insistFrame = nil
local insistAttempts = 0
local tickAccum = 0
local oocTrackingIndex = nil
local haveImpTracking = false

-- ==================== HELPER FUNCTIONS ====================

local function dprint(msg)
    if AruiQOLDB and AruiQOLDB.TrackOMatique and AruiQOLDB.TrackOMatique.debug then
        print("|cff88ccff[ToM]|r " .. msg)
    end
end

local function IsFeigning()
    if not FEIGN_DEATH then return false end
    local v = UnitAura("player", FEIGN_DEATH)
    return v == FEIGN_DEATH
end

local function IsShadowmelding()
    if not SHADOWMELD then return false end
    local v = UnitAura("player", SHADOWMELD)
    return v == SHADOWMELD
end

local function tex2typ(tex)
    if tex == NONE_TEX then return "None" end
    return texture2type[tex] or "miscellaneous"
end

-- ==================== TRACKING LOGIC ====================

local function UpdateLookupTables()
    local db = AruiQOLDB.TrackOMatique
    wipe(texture2index)
    wipe(index2texture)
    wipe(type2index)
    texture2index[NONE_TEX] = -1
    index2texture[-1] = NONE_TEX

    local count = 0
    local numTypes = GetNumTrackingTypes()
    for i = 1, numTypes do
        local name, texture, active, category = GetTrackingInfo(i)
        -- Classless servers may return nil for some indices
        if not texture then
            dprint("GetTrackingInfo(" .. i .. ") returned nil, skipping")
        else
            if texture2type[texture] then
                type2index[texture2type[texture]] = i
                count = count + 1
            end
            texture2index[texture] = i
            index2texture[i] = texture
        end
    end

    dprint("Tracking types: " .. count)

    -- Check if we can still track what we want
    if expectedTrackTexture and not texture2index[expectedTrackTexture] then
        dprint("Lost ability to track " .. tex2typ(expectedTrackTexture))
        InsistOff()
    end
end

local function UpdateTalentCache()
    if GetTalentInfo then
        local name, _, _, _, rank = GetTalentInfo(3, 1)
        haveImpTracking = rank and rank > 0
        dprint("Imp. Tracking: " .. tostring(haveImpTracking))
    end
end

local function InsistOff()
    if insistFrame then
        insistFrame:SetScript("OnUpdate", nil)
        insistFrame:Hide()
    end
    insistAttempts = 0
    tickAccum = 0
end

local function InsistOnTracking(elapsed)
    local interval = 0.2
    tickAccum = tickAccum + elapsed
    if tickAccum < interval then return end
    tickAccum = tickAccum - interval

    if IsFeigning() or IsShadowmelding() then return end

    insistAttempts = insistAttempts + 1
    if insistAttempts == 10 then
        UpdateLookupTables()
    end
    if insistAttempts >= 25 then
        print("|cff88ccff[ToM]|r Giving up on tracking " .. tex2typ(expectedTrackTexture))
        InsistOff()
        return
    end

    local tex = expectedTrackTexture
    if not tex then InsistOff() return end

    if tex ~= GetTrackingTexture() then
        local idx = texture2index[tex]
        if idx then SetTracking(idx) end
    else
        InsistOff()
    end
end

local function SetTrackingType(index)
    if not index then return end

    expectedTrackTexture = index2texture[index]
    if not expectedTrackTexture then return end

    local trackIdx = index
    if expectedTrackTexture == NONE_TEX then
        trackIdx = nil
    end

    local name = GetTrackingInfo(index)
    local cd = -1
    if name then cd = GetSpellCooldown(name) or 0 end

    local channeling = UnitChannelInfo("player")
    if not channeling and not IsFeigning() and not IsShadowmelding() and (cd == 0 or cd == -1) then
        SetTracking(trackIdx)
        InsistOff()
    else
        dprint("On cooldown/feigned, holding off...")
        if not insistFrame then
            insistFrame = CreateFrame("Frame")
        end
        insistFrame:Show()
        insistFrame:SetScript("OnUpdate", InsistOnTracking)
        insistAttempts = 0
        tickAccum = 0
    end
end

local function RetrackForBonus(targetType)
    local db = AruiQOLDB.TrackOMatique
    local currentTexture = GetTrackingTexture()

    if db.lazy then
        return (type2texture[targetType] and not texture2type[currentTexture])
    else
        local wantedTexture = type2texture[targetType]
        return (wantedTexture and wantedTexture ~= currentTexture)
    end
end

local function AutoTrack()
    local dead = UnitIsDead("target")
    local attackable = UnitCanAttack("player", "target")
    local targetType = UnitCreatureType("target")

    if dead or not attackable or not targetType then return end

    if RetrackForBonus(targetType) then
        local index = type2index[targetType]
        if index then
            dprint("Switching to track: " .. targetType)
            SetTrackingType(index)
            return true
        end
    end
end

local function MaybeUpdateTracking()
    local db = AruiQOLDB.TrackOMatique
    if not db or not db.enabled then return end
    if db.raidOnly and not IsInInstance() then return end
    if db.impTrackingOnly and not haveImpTracking then return end
    if db.combatOnly and not UnitAffectingCombat("player") then return end
    if db.ignoreDruid then
        local _, class = UnitClass("target")
        if class == "DRUID" then return end
    end
    AutoTrack()
end

-- ==================== EVENT HANDLERS ====================

local eventFrame = nil

local function OnEvent(self, event, ...)
    local db = AruiQOLDB.TrackOMatique
    if not db then return end

    if event == "PLAYER_ENTERING_WORLD" then
        UpdateLookupTables()
        UpdateTalentCache()

    elseif event == "PLAYER_TARGET_CHANGED" then
        if not UnitExists("target") then return end
        MaybeUpdateTracking()

    elseif event == "PLAYER_REGEN_DISABLED" then
        if db.impTrackingOnly and not haveImpTracking then
            MaybeUpdateTracking()
            return
        end
        if db.enabled and db.combatOnly and db.restore then
            local tex = GetTrackingTexture()
            if tex and not oocTrackingIndex then
                oocTrackingIndex = texture2index[tex]
                dprint("Saved tracking index: " .. tostring(oocTrackingIndex))
            end
        end
        MaybeUpdateTracking()

    elseif event == "PLAYER_REGEN_ENABLED" then
        if db.enabled and db.combatOnly and db.restore and oocTrackingIndex then
            local currentIdx = texture2index[GetTrackingTexture()]
            if oocTrackingIndex ~= currentIdx then
                dprint("Restoring tracking index: " .. tostring(oocTrackingIndex))
                SetTrackingType(oocTrackingIndex)
            end
            oocTrackingIndex = nil
        end

    elseif event == "PLAYER_ALIVE" then
        UpdateLookupTables()
        UpdateTalentCache()

    elseif event == "CHARACTER_POINTS_CHANGED" then
        UpdateTalentCache()

    elseif event == "UNIT_MODEL_CHANGED" then
        local targetID = ...
        if targetID == "player" then
            UpdateLookupTables()
        end

    elseif event == "LEARNED_SPELL_IN_TAB" then
        UpdateLookupTables()
    end
end

-- ==================== SLASH COMMAND /TOM ====================

SLASH_TRACKOM1 = "/tom"
SlashCmdList["TRACKOM"] = function(msg)
    if msg == "" or msg == "toggle" then
        AruiQOLDB.TrackOMatique.enabled = not AruiQOLDB.TrackOMatique.enabled
        print("|cff88ccff[ToM]|r Automatic tracking: " ..
            (AruiQOLDB.TrackOMatique.enabled and "|cff00ff00ON|r" or "|cffff0000OFF|r"))
    else
        AutoTrack()
    end
end

-- ==================== INITIALIZATION ====================

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        self:UnregisterEvent("PLAYER_LOGIN")

        -- Check if player has any tracking abilities (classless server support)
        local hasTracking = false
        for i = 1, GetNumTrackingTypes() do
            local name, texture, active, category = GetTrackingInfo(i)
            if category == "spell" then
                hasTracking = true
                break
            end
        end

        if not hasTracking then
            print("|cff88ccff[ToM]|r No tracking abilities found - module not loaded")
            return
        end

        -- Create event frame
        eventFrame = CreateFrame("Frame")
        eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
        eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
        eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
        eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
        eventFrame:RegisterEvent("PLAYER_ALIVE")
        eventFrame:RegisterEvent("CHARACTER_POINTS_CHANGED")
        eventFrame:RegisterEvent("UNIT_MODEL_CHANGED")
        eventFrame:RegisterEvent("LEARNED_SPELL_IN_TAB")
        eventFrame:SetScript("OnEvent", OnEvent)

        -- Create insist frame (hidden)
        insistFrame = CreateFrame("Frame")
        insistFrame:Hide()

        -- Delayed init (wait for character data)
        C_Timer.After(2, function()
            UpdateLookupTables()
            UpdateTalentCache()

            if not AruiQOLDB.TrackOMatique.quiet then
                if AruiQOLDB.TrackOMatique.enabled then
                    
                else
                    
                end
            end
        end)

        
    end
end)
