-- Arui QOL - SmartTrack Module

local NONE_TEX = "Interface\\Minimap\\Tracking\\None"
local FEIGN_DEATH = GetSpellInfo(5384)
local SHADOWMELD = GetSpellInfo(58984)


local type2texture = {
    Beast     = "Interface\\Icons\\Ability_Tracking",
    Demon     = "Interface\\Icons\\Spell_Shadow_SummonFelHunter",
    Dragonkin = "Interface\\Icons\\INV_Misc_Head_Dragon_01",
    Elemental = "Interface\\Icons\\Spell_Frost_SummonWaterElemental",
    Giant     = "Interface\\Icons\\Ability_Racial_Avatar",
    Humanoid  = "Interface\\Icons\\Spell_Holy_PrayerOfHealing",
    Undead    = "Interface\\Icons\\Spell_Shadow_DarkSummoning",
}

local type2spellname = {
    Beast     = "Track Beasts",
    Demon     = "Track Demons",
    Dragonkin = "Track Dragonkin",
    Elemental = "Track Elementals",
    Giant     = "Track Giants",
    Humanoid  = "Track Humanoids",
    Undead    = "Track Undead",
}

local texture2type = {}
for typ, tex in pairs(type2texture) do
    texture2type[tex] = typ
end

local texture2index = {}
local index2texture = {}
local index2name = {}
local type2index = {}
local expectedTrackTexture = nil
local insistFrame = nil
local insistAttempts = 0
local tickAccum = 0
local oocTrackingIndex = nil
local haveImpTracking = false
local InsistOff


local function dprint(msg)
    if AruiQOLDB and AruiQOLDB.SmartTrack and AruiQOLDB.SmartTrack.debug then
        print("|cff88ccff[SmartTrack]|r " .. msg)
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

local function UpdateLookupTables()
    wipe(texture2index)
    wipe(index2texture)
    wipe(index2name)
    wipe(type2index)
    texture2index[NONE_TEX] = -1
    index2texture[-1] = NONE_TEX

    local count = 0
    local numTypes = GetNumTrackingTypes()

    for i = 1, numTypes do
        local name, texture, active, category = GetTrackingInfo(i)

        if not name or not texture then
        else
            index2name[i] = name
            texture2index[texture] = i
            index2texture[i] = texture

            if texture2type[texture] then
                type2index[texture2type[texture]] = i
                count = count + 1
            else
                for typ, spellName in pairs(type2spellname) do
                    if not type2index[typ] and name and (name == spellName or string.find(string.lower(name), string.lower(spellName), 1, true)) then
                        type2index[typ] = i
                        count = count + 1
                        texture2type[texture] = typ
                        break
                    end
                end
            end
        end
    end

    dprint("Tracking types mapped: " .. count)

    if expectedTrackTexture and not texture2index[expectedTrackTexture] then
        dprint("Lost ability to track " .. tex2typ(expectedTrackTexture))
        InsistOff()
    end
end

local impTrackingTalentExists = false

local function UpdateTalentCache()
    if GetTalentInfo then
        local found = false
        for tab = 1, GetNumTalentTabs() do
            for i = 1, GetNumTalents(tab) do
                local name, _, _, _, rank = GetTalentInfo(tab, i)
                if name and (name == "Improved Tracking" or name == "Imp. Tracking") then
                    impTrackingTalentExists = true
                    haveImpTracking = rank and rank > 0
                    found = true
                    break
                end
            end
            if found then break end
        end
        if not found then
            
            impTrackingTalentExists = false
            haveImpTracking = true
        end
    else
        impTrackingTalentExists = false
        haveImpTracking = true
    end
end

InsistOff = function()
    if insistFrame then
        insistFrame:SetScript("OnUpdate", nil)
        insistFrame:Hide()
    end
    insistAttempts = 0
    tickAccum = 0
end

local lastTickTime = 0

local function InsistOnTracking(self, elapsed)
    
    if type(elapsed) ~= "number" then
        elapsed = GetTime() - (lastTickTime or GetTime())
    end
    lastTickTime = GetTime()

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
        print("|cff88ccff[SmartTrack]|r Giving up on tracking " .. tex2typ(expectedTrackTexture))
        InsistOff()
        return
    end

    local tex = expectedTrackTexture
    if not tex then InsistOff() return end

    local currentTex = GetTrackingTexture()
    if tex ~= currentTex then
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

    local name = index2name[index] or GetTrackingInfo(index)
    local cd = 0
    if name and GetSpellCooldown then
        local spellCd = GetSpellCooldown(name)
        if spellCd and type(spellCd) == "number" then
            cd = spellCd
        elseif spellCd and type(spellCd) == "table" then
            cd = spellCd.start and (spellCd.start + spellCd.duration - GetTime()) or 0
        end
    end

    local channeling = UnitChannelInfo("player")
    if not channeling and not IsFeigning() and not IsShadowmelding() and (cd == 0 or cd <= 0) then
        dprint("Switch -> " .. tostring(name))
        SetTracking(trackIdx)
        InsistOff()
    else
        dprint("On cooldown, retrying...")
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
    local db = AruiQOLDB.SmartTrack
    local currentTexture = GetTrackingTexture()
    local currentType = currentTexture and texture2type[currentTexture] or nil

    
    local useLazy = db.lazy and impTrackingTalentExists

    if useLazy then
        return (type2texture[targetType] and not currentType)
    else
        local wantedTexture = type2texture[targetType]
        return (wantedTexture and wantedTexture ~= currentTexture)
    end
end

local function AutoTrack()
    if not UnitExists("target") then return end
    local dead = UnitIsDead("target")
    local attackable = UnitCanAttack("player", "target")
    local targetType = UnitCreatureType("target")

    if dead or not attackable or not targetType then return end

    if RetrackForBonus(targetType) then
        local index = type2index[targetType]
        if index then
            dprint("Target " .. targetType .. " -> Track index " .. index)
            SetTrackingType(index)
            return true
        end
    end
end

local function MaybeUpdateTracking()
    local db = AruiQOLDB.SmartTrack
    if not db or not db.enabled then return end
    if db.raidOnly and not IsInInstance() then return end
    if db.impTrackingOnly and not haveImpTracking then
        if impTrackingTalentExists then return end
    end
    if db.combatOnly and not UnitAffectingCombat("player") then return end
    if db.ignoreDruid then
        local _, class = UnitClass("target")
        if class == "DRUID" then return end
    end
    AutoTrack()
end

local eventFrame = nil

local function OnEvent(self, event, ...)
    local db = AruiQOLDB.SmartTrack
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
            end
        end
        MaybeUpdateTracking()

    elseif event == "PLAYER_REGEN_ENABLED" then
        if db.enabled and db.combatOnly and db.restore and oocTrackingIndex then
            local currentIdx = texture2index[GetTrackingTexture()]
            if oocTrackingIndex ~= currentIdx then
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


local toggleFrame = nil
local toggleKnob = nil

local function UpdateToggleVisual()
    if not toggleFrame then return end
    local db = AruiQOLDB and AruiQOLDB.SmartTrack
    if not db then return end

    if db.enabled then
        toggleFrame.bg:SetColorTexture(0.15, 0.65, 0.25, 0.95)
        toggleFrame.border:SetColorTexture(0.2, 0.8, 0.3, 1)
        toggleKnob:ClearAllPoints()
        toggleKnob:SetPoint("RIGHT", toggleFrame, "RIGHT", -2, 0)
        toggleKnob.bg:SetColorTexture(0.95, 0.95, 0.95, 1)
        toggleFrame.label:SetText("ST")
        toggleFrame.label:SetTextColor(1, 1, 1, 0.95)
    else
        toggleFrame.bg:SetColorTexture(0.2, 0.2, 0.22, 0.95)
        toggleFrame.border:SetColorTexture(0.4, 0.4, 0.42, 1)
        toggleKnob:ClearAllPoints()
        toggleKnob:SetPoint("LEFT", toggleFrame, "LEFT", 2, 0)
        toggleKnob.bg:SetColorTexture(0.6, 0.6, 0.6, 1)
        toggleFrame.label:SetText("ST")
        toggleFrame.label:SetTextColor(0.5, 0.5, 0.5, 0.8)
    end
end

local function CreateSmartTrackToggle()
    if toggleFrame then
        toggleFrame:Show()
        UpdateToggleVisual()
        return
    end

    local db = AruiQOLDB and AruiQOLDB.SmartTrack
    if not db then return end

    toggleFrame = CreateFrame("Button", "AruiQOLSmartTrackToggle", UIParent)
    toggleFrame:SetSize(70, 26)
    toggleFrame:SetFrameStrata("MEDIUM")
    toggleFrame:SetClampedToScreen(true)
    toggleFrame:EnableMouse(true)
    toggleFrame:RegisterForClicks("LeftButtonUp")

    toggleFrame.bg = toggleFrame:CreateTexture(nil, "BACKGROUND")
    toggleFrame.bg:SetAllPoints()
    toggleFrame.bg:SetColorTexture(0.2, 0.2, 0.22, 0.95)

    toggleFrame.border = toggleFrame:CreateTexture(nil, "BORDER")
    toggleFrame.border:SetPoint("TOPLEFT", -1, 1)
    toggleFrame.border:SetPoint("BOTTOMRIGHT", 1, -1)
    toggleFrame.border:SetColorTexture(0.4, 0.4, 0.42, 1)

    toggleFrame.label = toggleFrame:CreateFontString(nil, "OVERLAY")
    toggleFrame.label:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    toggleFrame.label:SetPoint("LEFT", toggleFrame, "LEFT", 6, 0)
    toggleFrame.label:SetText("ST")

    toggleKnob = CreateFrame("Frame", nil, toggleFrame)
    toggleKnob:SetSize(20, 20)
    toggleKnob.bg = toggleKnob:CreateTexture(nil, "ARTWORK")
    toggleKnob.bg:SetAllPoints()
    toggleKnob.bg:SetColorTexture(0.6, 0.6, 0.6, 1)

    
    toggleFrame:SetScript("OnClick", function(self)
        local d = AruiQOLDB and AruiQOLDB.SmartTrack
        if not d then return end
        d.enabled = not d.enabled
        UpdateToggleVisual()
        print("|cff88ccff[SmartTrack]|r " ..
            (d.enabled and "|cff00ff00ON|r" or "|cffff0000OFF|r"))
    end)

    toggleFrame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("SmartTrack Toggle", 0.8, 0.9, 1)
        local d = AruiQOLDB and AruiQOLDB.SmartTrack
        if d then
            GameTooltip:AddLine("Status: " .. (d.enabled and "|cff00ff00ON|r" or "|cffff0000OFF|r"), 1, 1, 1)
        end
        GameTooltip:AddLine("Click to toggle SmartTrack", 0.7, 0.7, 0.7)
        GameTooltip:AddLine("Alt+Drag to move", 0.5, 0.5, 0.5)
        GameTooltip:Show()
    end)
    toggleFrame:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    
    toggleFrame:SetMovable(true)
    toggleFrame:RegisterForDrag("LeftButton")
    toggleFrame:SetScript("OnDragStart", function(self)
        if IsAltKeyDown() then
            self:StartMoving()
            self.isMoving = true
        end
    end)
    toggleFrame:SetScript("OnDragStop", function(self)
        if self.isMoving then
            self:StopMovingOrSizing()
            self.isMoving = false
            local point, _, relativePoint, xOfs, yOfs = self:GetPoint()
            local d = AruiQOLDB and AruiQOLDB.SmartTrack
            if d then
                d.togglePos = {
                    point = point,
                    relativePoint = relativePoint,
                    x = xOfs,
                    y = yOfs,
                }
            end
        end
    end)

    if db.togglePos then
        toggleFrame:ClearAllPoints()
        toggleFrame:SetPoint(db.togglePos.point, UIParent, db.togglePos.relativePoint, db.togglePos.x, db.togglePos.y)
    else
        toggleFrame:ClearAllPoints()
        toggleFrame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -200, -200)
    end

    if db.showToggle == false then
        toggleFrame:Hide()
    end

    UpdateToggleVisual()

    
    toggleFrame.UpdateVisual = UpdateToggleVisual
end

local function ToggleSmartTrackVisibility()
    if not toggleFrame then
        CreateSmartTrackToggle()
        return
    end
    if toggleFrame:IsShown() then
        toggleFrame:Hide()
        local db = AruiQOLDB and AruiQOLDB.SmartTrack
        if db then db.showToggle = false end
        print("|cff88ccff[SmartTrack]|r Toggle hidden")
    else
        toggleFrame:Show()
        local db = AruiQOLDB and AruiQOLDB.SmartTrack
        if db then db.showToggle = true end
        UpdateToggleVisual()
        print("|cff88ccff[SmartTrack]|r Toggle shown")
    end
end

_G.AruiQOLSmartTrackToggleFrame = toggleFrame
_G.AruiQOLSmartTrackToggleVisibility = ToggleSmartTrackVisibility

SLASH_SMARTTRACK1 = "/st"
SLASH_SMARTTRACK2 = "/smarttrack"
SlashCmdList["SMARTTRACK"] = function(msg)
    if msg == "" or msg == "toggle" then
        AruiQOLDB.SmartTrack.enabled = not AruiQOLDB.SmartTrack.enabled
        print("|cff88ccff[SmartTrack]|r " ..
            (AruiQOLDB.SmartTrack.enabled and "|cff00ff00ON|r" or "|cffff0000OFF|r"))
        UpdateToggleVisual()
    elseif msg == "debug" then
        AruiQOLDB.SmartTrack.debug = not AruiQOLDB.SmartTrack.debug
        print("|cff88ccff[SmartTrack]|r Debug: " ..
            (AruiQOLDB.SmartTrack.debug and "|cff00ff00ON|r" or "|cffff0000OFF|r"))
        if AruiQOLDB.SmartTrack.debug then
            UpdateLookupTables()
        end
    elseif msg == "button" or msg == "ui" then
        ToggleSmartTrackVisibility()
    else
        AutoTrack()
    end
end


local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        self:UnregisterEvent("PLAYER_LOGIN")

        -- TANK DE PAPEL
        local hasTracking = false
        local numTypes = GetNumTrackingTypes()
        for i = 1, numTypes do
            local name, texture, active, category = GetTrackingInfo(i)
            if name and texture then
                hasTracking = true
                break
            end
        end

        if not hasTracking then
            print("|cff88ccff[SmartTrack]|r No tracking abilities found")
            return
        end

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

        insistFrame = CreateFrame("Frame")
        insistFrame:Hide()

        C_Timer.After(2, function()
            UpdateLookupTables()
            UpdateTalentCache()

            if AruiQOLDB.SmartTrack.showToggle ~= false then
                CreateSmartTrackToggle()
            end

            _G.AruiQOLSmartTrackToggleFrame = toggleFrame

            if not AruiQOLDB.SmartTrack.quiet then
                local mapped = 0
                for _ in pairs(type2index) do mapped = mapped + 1 end
                if AruiQOLDB.SmartTrack.enabled then
                    print("|cff88ccff[SmartTrack]|r |cff00ff00ON|r - " .. mapped .. " tracking types | /st for options")
                else
                    print("|cff88ccff[SmartTrack]|r |cffff0000OFF|r - /st to enable")
                end
            end
        end)
    end
end)
