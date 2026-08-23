-- Arui QOL - Main Core System

AruiQOL = CreateFrame("Frame", "AruiQOLFrame", UIParent)
local AruiQOL = AruiQOL

AruiQOL:Hide()
AruiQOL:SetWidth(820)
AruiQOL:SetHeight(620)
AruiQOL:SetPoint("CENTER")
AruiQOL:SetFrameStrata("HIGH")
AruiQOL:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
    tile = true, tileSize = 32, edgeSize = 1,
    insets = { left = 0, right = 0, top = 0, bottom = 0 }
})
AruiQOL:SetBackdropColor(0.08, 0.08, 0.12, 0.97)
AruiQOL:SetBackdropBorderColor(0.2, 0.35, 0.5, 0.9)
AruiQOL:EnableMouse(true)
AruiQOL:SetMovable(true)
AruiQOL:RegisterForDrag("LeftButton")
AruiQOL:SetScript("OnDragStart", AruiQOL.StartMoving)

local titleBg = AruiQOL:CreateTexture(nil, "BACKGROUND")
titleBg:SetPoint("TOPLEFT")
titleBg:SetPoint("TOPRIGHT")
titleBg:SetHeight(35)
titleBg:SetColorTexture(0.08, 0.12, 0.18, 1)

local title = AruiQOL:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 15, -8)
title:SetText("|cff88ccffArui|r |cffffffffQOL|r")
title:SetTextColor(0.8, 0.9, 1)

local version = AruiQOL:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
version:SetPoint("TOPRIGHT", AruiQOL, "TOPRIGHT", -40, -10)
version:SetText("v1.3.2 |cffb188ffAYRO|r")
version:SetTextColor(0.6, 0.6, 0.7)

local closeBtn = CreateFrame("Button", nil, AruiQOL, "UIPanelCloseButton")
closeBtn:SetPoint("TOPRIGHT", AruiQOL, "TOPRIGHT", -2, -2)
closeBtn:SetWidth(28)
closeBtn:SetHeight(28)

local ContentArea = CreateFrame("Frame", nil, AruiQOL)
ContentArea:SetPoint("TOPLEFT", 5, -40)
ContentArea:SetPoint("BOTTOMRIGHT", -5, 5)
AruiQOL.ContentArea = ContentArea

AruiQOL:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    if AruiQOLDB and AruiQOLDB.Settings and AruiQOLDB.Settings.savePosition then
        local point, _, relativePoint, x, y = self:GetPoint()
        AruiQOLDB.Settings.windowPosition = {
            point = point, relativePoint = relativePoint, x = x, y = y
        }
    end
end)

local miniButton = CreateFrame("Button", "AruiQOLMiniMapButton", Minimap)
miniButton:SetWidth(32)
miniButton:SetHeight(32)
miniButton:SetFrameStrata("TOOLTIP")
miniButton:SetFrameLevel(99)

local miniPos = AruiQOLDB and AruiQOLDB.Settings and AruiQOLDB.Settings.minimapPos or 45
miniButton:SetPoint("CENTER", Minimap, "CENTER", miniPos, miniPos - 80)

miniButton:SetNormalTexture("Interface\\AddOns\\AruiQOL\\Media\\icon.tga")
miniButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
miniButton:EnableMouse(true)
miniButton:RegisterForDrag("LeftButton")
miniButton:SetMovable(true)
miniButton:SetClampedToScreen(true)

miniButton:SetScript("OnDragStart", function(self)
    self:StartMoving()
end)
miniButton:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local _, _, _, x, y = self:GetPoint()
    local angle = math.deg(math.atan2(y, x))
    if AruiQOLDB and AruiQOLDB.Settings then
        AruiQOLDB.Settings.minimapPos = angle
    end
end)
miniButton:SetScript("OnClick", function(self, button)
    if button == "LeftButton" then
        if AruiQOL:IsShown() then
            AruiQOL:Hide()
        else
            AruiQOL:Show()
        end
    end
end)
miniButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText("Arui QOL", 0.8, 0.9, 1)
    GameTooltip:AddLine("Left Click: Toggle Window", 1, 1, 1)
    GameTooltip:AddLine("Drag: Move Button", 0.8, 0.8, 0.8)
    GameTooltip:Show()
end)
miniButton:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
end)

SLASH_ARUIQOL1 = "/aqol"
SLASH_ARUIQOL2 = "/aruiqol"
SLASH_ARUIQOL3 = "/qol"
SlashCmdList["ARUIQOL"] = function(msg)
    if AruiQOL:IsShown() then
        AruiQOL:Hide()
    else
        AruiQOL:Show()
    end
end

local function InitDB()
    if not AruiQOLDB then AruiQOLDB = {} end

    if not AruiQOLDB.QOL then
        AruiQOLDB.QOL = {
            autoSellGreys = false,
            autoRepair = false,
            useGuildRepair = false,
            sellWhites = false,
            sellVerbose = false,
        }
    else
        -- nova cane curioso
        if AruiQOLDB.QOL.sellWhites == nil then
            AruiQOLDB.QOL.sellWhites = false
        end
        if AruiQOLDB.QOL.sellVerbose == nil then
            AruiQOLDB.QOL.sellVerbose = false
        end
    end

    if not AruiQOLDB.BossAnnounce then
        AruiQOLDB.BossAnnounce = {
            enabled = false, announceParty = true, announceRaid = false,
            announceGuild = false, showTimer = true, minBossHealth = 50,
            playSound = true, announceTrash = false, announceOnlyInInstance = true,
        }
    end

    if not AruiQOLDB.ChatFilter then
        AruiQOLDB.ChatFilter = {
            enabled = true, filterWorldLFG = true, filterBoost = true,
            filterGuild = false, filterSpamBurst = true, filterRepeat = true,
            filterTrade = false, filterGeneral = false, filterLinks = false,
            filterWhisperSpam = true, filterNonLatin = false,
            replaceMode = false, customKeywords = {}, filterLFGChannels = {},
        }
    else
        if AruiQOLDB.ChatFilter.filterSpamBurst == nil then
            AruiQOLDB.ChatFilter.filterSpamBurst = true
        end
        if AruiQOLDB.ChatFilter.filterRepeat == nil then
            AruiQOLDB.ChatFilter.filterRepeat = true
        end
        if AruiQOLDB.ChatFilter.filterTrade == nil then
            AruiQOLDB.ChatFilter.filterTrade = false
        end
        if AruiQOLDB.ChatFilter.filterGeneral == nil then
            AruiQOLDB.ChatFilter.filterGeneral = false
        end
        if AruiQOLDB.ChatFilter.filterLinks == nil then
            AruiQOLDB.ChatFilter.filterLinks = false
        end
        if AruiQOLDB.ChatFilter.filterWhisperSpam == nil then
            AruiQOLDB.ChatFilter.filterWhisperSpam = true
        end
        if AruiQOLDB.ChatFilter.filterNonLatin == nil then
            -- vinni gatto zecca
            if AruiQOLDB.ChatFilter.filterNonEnglish ~= nil then
                AruiQOLDB.ChatFilter.filterNonLatin = AruiQOLDB.ChatFilter.filterNonEnglish
                AruiQOLDB.ChatFilter.filterNonEnglish = nil
            else
                AruiQOLDB.ChatFilter.filterNonLatin = false
            end
        end
        if AruiQOLDB.ChatFilter.replaceMode == nil then
            AruiQOLDB.ChatFilter.replaceMode = false
        end
    end

    if not AruiQOLDB.InterruptAnnounce then
        AruiQOLDB.InterruptAnnounce = {
            enabled = false, visualEnabled = true, chatEnabled = true,
            output = "Auto", verbose = false, showParty = true,
            fontSize = 15, anchorPos = nil, debug = false,
        }
    else
        -- non fare l'infame
        if AruiQOLDB.InterruptAnnounce.visualEnabled == nil then
            AruiQOLDB.InterruptAnnounce.visualEnabled = true
        end
        if AruiQOLDB.InterruptAnnounce.chatEnabled == nil then
            AruiQOLDB.InterruptAnnounce.chatEnabled = true
        end
        if AruiQOLDB.InterruptAnnounce.showParty == nil then
            AruiQOLDB.InterruptAnnounce.showParty = true
        end
        if AruiQOLDB.InterruptAnnounce.fontSize == nil then
            AruiQOLDB.InterruptAnnounce.fontSize = 15
        end
        if AruiQOLDB.InterruptAnnounce.debug == nil then
            AruiQOLDB.InterruptAnnounce.debug = false
        end
    end

    if not AruiQOLDB.ResAnnounce then
        AruiQOLDB.ResAnnounce = {
            enabled = false, displaySay = true, displayParty = false,
            displayRaid = false, displayWhisper = false,
        }
    end

    if not AruiQOLDB.SmartTrack then
        AruiQOLDB.SmartTrack = {
            enabled = true, lazy = true, raidOnly = false,
            impTrackingOnly = true, combatOnly = false, restore = false,
            ignoreDruid = false, quiet = false, debug = false,
            showToggle = false, togglePos = nil,
        }
    end

    if AruiQOLDB.Redeemer and not AruiQOLDB.RezMigrated then
        AruiQOLDB.ResAnnounce = AruiQOLDB.Redeemer
        AruiQOLDB.Redeemer = nil
        AruiQOLDB.RezMigrated = true
    end
    if AruiQOLDB.RezQuotes and not AruiQOLDB.ResAnnounceMigrated then
        AruiQOLDB.ResAnnounce = AruiQOLDB.RezQuotes
        AruiQOLDB.RezQuotes = nil
        AruiQOLDB.ResAnnounceMigrated = true
    end

    if AruiQOLDB.SmartTrack then
        if AruiQOLDB.SmartTrack.showToggle == nil then
            AruiQOLDB.SmartTrack.showToggle = false
        end
        if AruiQOLDB.SmartTrack.togglePos == nil then
            AruiQOLDB.SmartTrack.togglePos = nil
        end
    end

    if AruiQOLDB.TrackOMatique and not AruiQOLDB.STMigrated then
        AruiQOLDB.SmartTrack = AruiQOLDB.TrackOMatique
        AruiQOLDB.TrackOMatique = nil
        AruiQOLDB.STMigrated = true
    end

    if not AruiQOLDB.SpellAnnounce then
        AruiQOLDB.SpellAnnounce = {
            enabled = true, trackTotems = true, trackDefensives = true,
            trackImportant = true, visualEnabled = true, chatEnabled = false,
            output = "Auto", fontSize = 15, anchorPos = nil,
            onlyOwnCDs = true,
        }
    else
        if AruiQOLDB.SpellAnnounce.trackTotems == nil then
            AruiQOLDB.SpellAnnounce.trackTotems = true
        end
        if AruiQOLDB.SpellAnnounce.trackDefensives == nil then
            AruiQOLDB.SpellAnnounce.trackDefensives = true
        end
        if AruiQOLDB.SpellAnnounce.trackImportant == nil then
            AruiQOLDB.SpellAnnounce.trackImportant = true
        end
        if AruiQOLDB.SpellAnnounce.visualEnabled == nil then
            AruiQOLDB.SpellAnnounce.visualEnabled = true
        end
        if AruiQOLDB.SpellAnnounce.chatEnabled == nil then
            AruiQOLDB.SpellAnnounce.chatEnabled = false
        end
        if AruiQOLDB.SpellAnnounce.output == nil then
            AruiQOLDB.SpellAnnounce.output = "Auto"
        end
        if AruiQOLDB.SpellAnnounce.fontSize == nil then
            AruiQOLDB.SpellAnnounce.fontSize = 15
        end
        if AruiQOLDB.SpellAnnounce.onlyOwnCDs == nil then
            AruiQOLDB.SpellAnnounce.onlyOwnCDs = true
        end
    end

    if not AruiQOLDB.Settings then
        AruiQOLDB.Settings = {
            uiScale = 1.0, minimapButton = true, debugMode = false, savePosition = true,
        }
    end

    -- ayro
    if AruiQOLDB.Settings.uiScale == nil then
        AruiQOLDB.Settings.uiScale = 1.0
    end
    if AruiQOLDB.Settings.minimapButton == nil then
        AruiQOLDB.Settings.minimapButton = true
    end
    if AruiQOLDB.Settings.debugMode == nil then
        AruiQOLDB.Settings.debugMode = false
    end
    if AruiQOLDB.Settings.savePosition == nil then
        AruiQOLDB.Settings.savePosition = true
    end


    if not AruiQOLDB.AutoAccept then
        AruiQOLDB.AutoAccept = {
            enabled = true,
            autoAcceptRes = true,
            autoAcceptSummon = true,
            autoReleasePvP = true,
            skipResInCombat = true,
            excludeAlterac = true,
            releaseDelay = 3,
            declineDuels = true,
            declinePartyInvites = false,
            declineGuildInvites = false,
            acceptPartyFromFriends = false,
        }
    else
        if AruiQOLDB.AutoAccept.autoAcceptRes == nil then AruiQOLDB.AutoAccept.autoAcceptRes = true end
        if AruiQOLDB.AutoAccept.autoAcceptSummon == nil then AruiQOLDB.AutoAccept.autoAcceptSummon = true end
        if AruiQOLDB.AutoAccept.autoReleasePvP == nil then AruiQOLDB.AutoAccept.autoReleasePvP = true end
        if AruiQOLDB.AutoAccept.skipResInCombat == nil then AruiQOLDB.AutoAccept.skipResInCombat = true end
        if AruiQOLDB.AutoAccept.excludeAlterac == nil then AruiQOLDB.AutoAccept.excludeAlterac = true end
        if AruiQOLDB.AutoAccept.releaseDelay == nil then AruiQOLDB.AutoAccept.releaseDelay = 3 end
        if AruiQOLDB.AutoAccept.declineDuels == nil then AruiQOLDB.AutoAccept.declineDuels = true end
        if AruiQOLDB.AutoAccept.declinePartyInvites == nil then AruiQOLDB.AutoAccept.declinePartyInvites = false end
        if AruiQOLDB.AutoAccept.declineGuildInvites == nil then AruiQOLDB.AutoAccept.declineGuildInvites = false end
        if AruiQOLDB.AutoAccept.acceptPartyFromFriends == nil then AruiQOLDB.AutoAccept.acceptPartyFromFriends = false end
    end

    if not AruiQOLDB.WhoPulled then
        AruiQOLDB.WhoPulled = {
            enabled = false,
            announceSelf = true,
            announceChat = false,
            trackMode = "boss",
            announceChannel = "AUTO",
        }
    else
        if AruiQOLDB.WhoPulled.announceSelf == nil then AruiQOLDB.WhoPulled.announceSelf = true end
        if AruiQOLDB.WhoPulled.announceChat == nil then AruiQOLDB.WhoPulled.announceChat = false end
        if AruiQOLDB.WhoPulled.trackMode == nil then AruiQOLDB.WhoPulled.trackMode = "boss" end
        if AruiQOLDB.WhoPulled.announceChannel == nil then AruiQOLDB.WhoPulled.announceChannel = "AUTO" end
    end

    if not AruiQOLDB.InviteWhisper then
        AruiQOLDB.InviteWhisper = {
            enabled = false,
            keywords = { "itsmeayro", "inv" },
            convertToRaid = false,
            announceSelf = true,
        }
    else
        if AruiQOLDB.InviteWhisper.keywords == nil then
            AruiQOLDB.InviteWhisper.keywords = { "itsmeayro", "inv" }
        end
        if AruiQOLDB.InviteWhisper.convertToRaid == nil then AruiQOLDB.InviteWhisper.convertToRaid = false end
        if AruiQOLDB.InviteWhisper.announceSelf == nil then AruiQOLDB.InviteWhisper.announceSelf = true end
    end

    if not AruiQOLDB.RaidCheck then
        AruiQOLDB.RaidCheck = {
            enabled = true,
        }
    end

    if not AruiQOLDB.RaidBar then
        AruiQOLDB.RaidBar = {
            enabled = false,
            showReadyCheck = true,
            showPull5 = true,
            showPull10 = true,
            showPull15 = true,
            showPullTimer = false,
            showRaidPause = true,
            showFlaskCheck = true,
            showRoleCheck = false,
            showCountdown = false,
            pullTimerDuration = 10,
            countdownChannel = "RW",
            pauseMessage = "--- RAID PAUSE --- Take a break, wait for RL!",
            showOnlyInRaid = false,
            showInParty = true,
            position = nil,
        }
    else
        if AruiQOLDB.RaidBar.showReadyCheck == nil then AruiQOLDB.RaidBar.showReadyCheck = true end
        if AruiQOLDB.RaidBar.showPull5 == nil then AruiQOLDB.RaidBar.showPull5 = true end
        if AruiQOLDB.RaidBar.showPull10 == nil then AruiQOLDB.RaidBar.showPull10 = true end
        if AruiQOLDB.RaidBar.showPull15 == nil then AruiQOLDB.RaidBar.showPull15 = true end
        if AruiQOLDB.RaidBar.showPullTimer == nil then AruiQOLDB.RaidBar.showPullTimer = false end
        if AruiQOLDB.RaidBar.showRaidPause == nil then AruiQOLDB.RaidBar.showRaidPause = true end
        if AruiQOLDB.RaidBar.showFlaskCheck == nil then AruiQOLDB.RaidBar.showFlaskCheck = true end
        if AruiQOLDB.RaidBar.showRoleCheck == nil then AruiQOLDB.RaidBar.showRoleCheck = false end
        if AruiQOLDB.RaidBar.showCountdown == nil then AruiQOLDB.RaidBar.showCountdown = false end
        if AruiQOLDB.RaidBar.pullTimerDuration == nil then AruiQOLDB.RaidBar.pullTimerDuration = 10 end
        if AruiQOLDB.RaidBar.countdownChannel == nil then AruiQOLDB.RaidBar.countdownChannel = "RW" end
        if AruiQOLDB.RaidBar.pauseMessage == nil then AruiQOLDB.RaidBar.pauseMessage = "--- RAID PAUSE --- Take a break, wait for RL!" end
        if AruiQOLDB.RaidBar.showOnlyInRaid == nil then AruiQOLDB.RaidBar.showOnlyInRaid = false end
        if AruiQOLDB.RaidBar.showInParty == nil then AruiQOLDB.RaidBar.showInParty = true end
    end
end

AruiQOL:RegisterEvent("PLAYER_LOGIN")
AruiQOL:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        self:UnregisterEvent("PLAYER_LOGIN")

        InitDB()

        if AruiQOLDB.Settings.savePosition and AruiQOLDB.Settings.windowPosition then
            local wp = AruiQOLDB.Settings.windowPosition
            self:ClearAllPoints()
            self:SetPoint(wp.point, UIParent, wp.relativePoint, wp.x, wp.y)
        end

        if AruiQOLDB.Settings.uiScale then
            self:SetScale(AruiQOLDB.Settings.uiScale)
        end

        -- GLADY FIRSTLADY
        if not AruiQOLDB.Settings.minimapButton then
            miniButton:Hide()
        end

        
    end
end)

local saveFrame = CreateFrame("Frame")
saveFrame:RegisterEvent("PLAYER_LOGOUT")
saveFrame:RegisterEvent("PLAYER_QUIT")
saveFrame:SetScript("OnEvent", function()
    if AruiQOLDB and AruiQOLDB.Settings then
        AruiQOLDB.Settings._lastSaved = time()
    end
end)
