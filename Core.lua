-- ============================================================
-- Arui QOL - Main Core System
-- ============================================================

AruiQOL = CreateFrame("Frame", "AruiQOLFrame", UIParent)
local AruiQOL = AruiQOL

AruiQOL:Hide()
AruiQOL:SetWidth(820)
AruiQOL:SetHeight(620)
AruiQOL:SetPoint("CENTER")
AruiQOL:SetFrameStrata("HIGH")
AruiQOL:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 16,
    insets = { left = 5, right = 5, top = 5, bottom = 5 }
})
AruiQOL:SetBackdropColor(0.1, 0.1, 0.1, 0.95)
AruiQOL:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
AruiQOL:EnableMouse(true)
AruiQOL:SetMovable(true)
AruiQOL:RegisterForDrag("LeftButton")
AruiQOL:SetScript("OnDragStart", AruiQOL.StartMoving)

-- ==================== TITLE BAR ====================
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
version:SetText("v1.2 |cffb188ffAYRO|r")
version:SetTextColor(0.6, 0.6, 0.7)

-- Close button
local closeBtn = CreateFrame("Button", nil, AruiQOL, "UIPanelCloseButton")
closeBtn:SetPoint("TOPRIGHT", AruiQOL, "TOPRIGHT", -2, -2)
closeBtn:SetWidth(28)
closeBtn:SetHeight(28)

-- ==================== CONTENT AREA ====================
local ContentArea = CreateFrame("Frame", nil, AruiQOL)
ContentArea:SetPoint("TOPLEFT", 5, -40)
ContentArea:SetPoint("BOTTOMRIGHT", -5, 5)
AruiQOL.ContentArea = ContentArea

-- ==================== DRAG STOP + POSITION SAVE ====================
AruiQOL:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    if AruiQOLDB and AruiQOLDB.Settings and AruiQOLDB.Settings.savePosition then
        local point, _, relativePoint, x, y = self:GetPoint()
        AruiQOLDB.Settings.windowPosition = {
            point = point, relativePoint = relativePoint, x = x, y = y
        }
    end
end)

-- ==================== MINIMAP BUTTON ====================
local miniButton = CreateFrame("Button", "AruiQOLMiniMapButton", Minimap)
miniButton:SetWidth(32)
miniButton:SetHeight(32)
miniButton:SetFrameStrata("TOOLTIP")
miniButton:SetFrameLevel(99)

local miniPos = AruiQOLDB and AruiQOLDB.Settings and AruiQOLDB.Settings.minimapPos or 45
miniButton:SetPoint("CENTER", Minimap, "CENTER", miniPos, miniPos - 80)

miniButton:SetNormalTexture("Interface\\AddOns\\AruiQOL\\Media\\africa")
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

-- ==================== SLASH COMMANDS ====================
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

-- ==================== DATABASE SETUP ====================
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
            filterGuild = false, customKeywords = {}, filterLFGChannels = {},
        }
    end

    if not AruiQOLDB.InterruptAnnounce then
        AruiQOLDB.InterruptAnnounce = {
            enabled = false, visualEnabled = true, chatEnabled = false,
            output = "Auto", verbose = false, showParty = true,
            fontSize = 15, anchorPos = nil, debug = false,
        }
    else
        -- non fare l'infame
        if AruiQOLDB.InterruptAnnounce.visualEnabled == nil then
            AruiQOLDB.InterruptAnnounce.visualEnabled = true
        end
        if AruiQOLDB.InterruptAnnounce.chatEnabled == nil then
            AruiQOLDB.InterruptAnnounce.chatEnabled = false
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

    if not AruiQOLDB.RezQuotes then
        AruiQOLDB.RezQuotes = {
            enabled = false, displaySay = true, displayParty = false,
            displayRaid = false, displayWhisper = false,
        }
    end

    if not AruiQOLDB.SmartTrack then
        AruiQOLDB.SmartTrack = {
            enabled = true, lazy = true, raidOnly = false,
            impTrackingOnly = true, combatOnly = false, restore = false,
            ignoreDruid = false, quiet = false, debug = false,
        }
    end

    -- non copiare
    if AruiQOLDB.Redeemer and not AruiQOLDB.RezMigrated then
        AruiQOLDB.RezQuotes = AruiQOLDB.Redeemer
        AruiQOLDB.Redeemer = nil
        AruiQOLDB.RezMigrated = true
    end
    if AruiQOLDB.TrackOMatique and not AruiQOLDB.STMigrated then
        AruiQOLDB.SmartTrack = AruiQOLDB.TrackOMatique
        AruiQOLDB.TrackOMatique = nil
        AruiQOLDB.STMigrated = true
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
end

-- ==================== PLAYER_LOGIN ====================
AruiQOL:RegisterEvent("PLAYER_LOGIN")
AruiQOL:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        self:UnregisterEvent("PLAYER_LOGIN")

        InitDB()

        -- Restore window position
        if AruiQOLDB.Settings.savePosition and AruiQOLDB.Settings.windowPosition then
            local wp = AruiQOLDB.Settings.windowPosition
            self:ClearAllPoints()
            self:SetPoint(wp.point, UIParent, wp.relativePoint, wp.x, wp.y)
        end

        -- Apply scale
        if AruiQOLDB.Settings.uiScale then
            self:SetScale(AruiQOLDB.Settings.uiScale)
        end

        -- Minimap button visibility
        if not AruiQOLDB.Settings.minimapButton then
            miniButton:Hide()
        end

        
    end
end)

-- ==================== SAVE ON LOGOUT ====================
local saveFrame = CreateFrame("Frame")
saveFrame:RegisterEvent("PLAYER_LOGOUT")
saveFrame:RegisterEvent("PLAYER_QUIT")
saveFrame:SetScript("OnEvent", function()
    if AruiQOLDB and AruiQOLDB.Settings then
        AruiQOLDB.Settings._lastSaved = time()
    end
end)
