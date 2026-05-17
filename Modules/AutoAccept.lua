-- ============================================================
-- Arui QOL - AutoAccept Module
-- ============================================================

local AutoAccept = {}

-- ==================== HELPERS ====================

local function IsInBattleground()
    local _, instanceType = IsInInstance()
    return instanceType == "pvp"
end

local function IsInArena()
    local _, instanceType = IsInInstance()
    return instanceType == "arena"
end

-- ==================== AUTO ACCEPT RESURRECT ====================

local function HandleResurrect()
    local db = AruiQOLDB and AruiQOLDB.AutoAccept
    if not db or not db.autoAcceptRes then return end
    if db.skipResInCombat then
        if UnitAffectingCombat("player") then return end
    end

    if StaticPopup1 and StaticPopup1:IsVisible() then
        for i = 1, STATICPOPUP_NUMDIALOGS do
            local frame = _G["StaticPopup" .. i]
            if frame and frame:IsVisible() and frame.which == "RESURRECT" then
                StaticPopup1Button1:Click()
                return
            end
        end
    end

    
    if AcceptResurrect then
        pcall(AcceptResurrect)
    end
end

-- ==================== AUTO ACCEPT SUMMON ====================

local function HandleSummon()
    local db = AruiQOLDB and AruiQOLDB.AutoAccept
    if not db or not db.autoAcceptSummon then return end

    if StaticPopup1 and StaticPopup1:IsVisible() then
        for i = 1, STATICPOPUP_NUMDIALOGS do
            local frame = _G["StaticPopup" .. i]
            if frame and frame:IsVisible() and frame.which == "CONFIRM_SUMMON" then
                if ConfirmSummon then pcall(ConfirmSummon) end
                StaticPopup1Button1:Click()
                return
            end
        end
    end

    if ConfirmSummon then
        pcall(ConfirmSummon)
    end
end

-- ==================== AUTO RELEASE PVP ====================

local function HandleAutoRelease()
    local db = AruiQOLDB and AruiQOLDB.AutoAccept
    if not db or not db.autoReleasePvP then return end

    if not IsInBattleground() then return end

    if db.excludeAlterac then
        local zoneName = GetZoneText()
        if zoneName and string.find(string.lower(zoneName), "alterac") then return end
    end

    local delay = db.releaseDelay or 3
    C_Timer.After(delay, function()
        if UnitIsDeadOrGhost("player") and IsInBattleground() then
            RepopMe()
        end
    end)
end

-- ==================== AUTO DECLINE ====================

local function HandleDeclineDuel()
    local db = AruiQOLDB and AruiQOLDB.AutoAccept
    if not db or not db.declineDuels then return end
    CancelDuel()
    if StaticPopup1 and StaticPopup1:IsVisible() and StaticPopup1.which == "DUEL_REQUESTED" then
        StaticPopup1Button2:Click()
    end
end

local function HandleDeclineParty()
    local db = AruiQOLDB and AruiQOLDB.AutoAccept
    if not db then return end

    if db.acceptPartyFromFriends then
        local sender = arg1 or ""
        if UnitIsFriend("player", sender) or UnitInGuild(sender) then
            AcceptGroup()
            return
        end
    end

    if db.declinePartyInvites then
        DeclineGroup()
        if StaticPopup1 and StaticPopup1:IsVisible() and StaticPopup1.which == "PARTY_INVITE" then
            StaticPopup1Button2:Click()
        end
    end
end

local function HandleDeclineGuild()
    local db = AruiQOLDB and AruiQOLDB.AutoAccept
    if not db or not db.declineGuildInvites then return end
    DeclineGuild()
    if StaticPopup1 and StaticPopup1:IsVisible() then
        for i = 1, STATICPOPUP_NUMDIALOGS do
            local frame = _G["StaticPopup" .. i]
            if frame and frame:IsVisible() and frame.which == "GUILD_INVITE" then
                StaticPopup1Button2:Click()
                return
            end
        end
    end
end

-- ==================== EVENT FRAME ====================

local eventFrame = nil
local confirmFrame = nil
local deadFrame = nil

-- ==================== INIT ====================

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        self:UnregisterEvent("PLAYER_LOGIN")

        local db = AruiQOLDB and AruiQOLDB.AutoAccept
        if not db then return end

        eventFrame = CreateFrame("Frame")
        eventFrame:RegisterEvent("RESURRECT_REQUEST")
        eventFrame:RegisterEvent("DUEL_REQUESTED")
        eventFrame:RegisterEvent("PARTY_INVITE_REQUEST")
        eventFrame:RegisterEvent("GUILD_INVITE_REQUEST")
        eventFrame:SetScript("OnEvent", function(self, ev, ...)
            if ev == "RESURRECT_REQUEST" then
                C_Timer.After(0.5, HandleResurrect)
            elseif ev == "DUEL_REQUESTED" then
                C_Timer.After(0.1, HandleDeclineDuel)
            elseif ev == "PARTY_INVITE_REQUEST" then
                C_Timer.After(0.1, HandleDeclineParty)
            elseif ev == "GUILD_INVITE_REQUEST" then
                C_Timer.After(0.1, HandleDeclineGuild)
            end
        end)

        confirmFrame = CreateFrame("Frame")
        confirmFrame:RegisterEvent("CONFIRM_SUMMON")
        confirmFrame:SetScript("OnEvent", function(self, ev, ...)
            C_Timer.After(0.5, HandleSummon)
        end)

        deadFrame = CreateFrame("Frame")
        deadFrame:RegisterEvent("PLAYER_DEAD")
        deadFrame:SetScript("OnEvent", function(self, ev, ...)
            HandleAutoRelease()
        end)

        print("|cff88ccff[AutoAccept]|r Loaded - /aqolaa for options")
    end
end)

-- ==================== SLASH COMMANDS ====================

SLASH_ARUIQOLAA1 = "/aqolaa"
SlashCmdList["ARUIQOLAA"] = function(msg)
    local db = AruiQOLDB and AruiQOLDB.AutoAccept
    if not db then return end

    local cmd = string.lower(msg or "")

    if cmd == "res" then
        db.autoAcceptRes = not db.autoAcceptRes
        print("|cff88ccff[AutoAccept]|r Auto Res: " .. (db.autoAcceptRes and "|cff00ff00ON|r" or "|cffff0000OFF|r"))
    elseif cmd == "summon" then
        db.autoAcceptSummon = not db.autoAcceptSummon
        print("|cff88ccff[AutoAccept]|r Auto Summon: " .. (db.autoAcceptSummon and "|cff00ff00ON|r" or "|cffff0000OFF|r"))
    elseif cmd == "pvp" then
        db.autoReleasePvP = not db.autoReleasePvP
        print("|cff88ccff[AutoAccept]|r Auto Release PvP: " .. (db.autoReleasePvP and "|cff00ff00ON|r" or "|cffff0000OFF|r"))
    elseif cmd == "duel" then
        db.declineDuels = not db.declineDuels
        print("|cff88ccff[AutoAccept]|r Decline Duels: " .. (db.declineDuels and "|cff00ff00ON|r" or "|cffff0000OFF|r"))
    else
        print("|cff88ccff[AutoAccept]|r Commands:")
        print("  /aqolaa res - Toggle auto accept resurrect")
        print("  /aqolaa summon - Toggle auto accept summon")
        print("  /aqolaa pvp - Toggle auto release in BG")
        print("  /aqolaa duel - Toggle decline duels")
    end
end

_G.AruiQOLAutoAccept = AutoAccept
