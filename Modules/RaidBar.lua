-- Arui QOL - RaidBar Module

local RaidBar = {}
local BUTTON_SIZE = 30
local BUTTON_SPACING = 4
local BAR_HEIGHT = 40
local BAR_PADDING = 6
local FONT_PATH = "Fonts\\FRIZQT__.TTF"
local mainFrame = nil
local pullTimerFrame = nil
local pullTimerActive = false
local pullTimerStart = 0
local pullTimerDuration = 10
local barButtons = {}

local function SendToChannel(msg, channelOverride)
    local db = AruiQOLDB and AruiQOLDB.RaidBar
    if not db then return end

    local ch = channelOverride or db.countdownChannel or "RW"
    local inRaid = IsInRaid and IsInRaid()
    local inParty = GetNumPartyMembers and GetNumPartyMembers() > 0

    if ch == "RW" then
        if inRaid then
            SendChatMessage(msg, "RAID_WARNING")
        elseif inParty then
            SendChatMessage(msg, "PARTY")
        end
    elseif ch == "RAID" then
        if inRaid then
            SendChatMessage(msg, "RAID")
        elseif inParty then
            SendChatMessage(msg, "PARTY")
        end
    elseif ch == "PARTY" then
        if inParty then
            SendChatMessage(msg, "PARTY")
        end
    elseif ch == "SAY" then
        SendChatMessage(msg, "SAY")
    else
        
        if inRaid then
            SendChatMessage(msg, "RAID_WARNING")
        elseif inParty then
            SendChatMessage(msg, "PARTY")
        end
    end
end


local function StartPullTimer(duration)
    local db = AruiQOLDB and AruiQOLDB.RaidBar
    if not db or not db.enabled then return end

    duration = duration or db.pullTimerDuration or 10
    pullTimerActive = true
    pullTimerStart = GetTime()
    pullTimerDuration = duration

    local msg = "Pull in " .. duration .. " seconds!"
    SendToChannel(msg)

    if pullTimerFrame then
        pullTimerFrame:Show()
        pullTimerFrame.text:SetText(duration)
    end

    local remaining = duration
    local ticker
    ticker = C_Timer.NewTicker(1, function()
        remaining = remaining - 1
        if remaining <= 0 then
            pullTimerActive = false
            if pullTimerFrame then
                pullTimerFrame.text:SetText("GO!")
                C_Timer.After(1, function()
                    pullTimerFrame:Hide()
                end)
            end
            ticker:Cancel()
        else
            if pullTimerFrame then
                pullTimerFrame.text:SetText(remaining)
            end
            
            if remaining <= 3 or remaining == 5 or remaining == 10 then
                local countMsg = "Pull in " .. remaining .. "..."
                SendToChannel(countMsg)
            end
        end
    end)
end

local function CancelPullTimer()
    local db = AruiQOLDB and AruiQOLDB.RaidBar
    pullTimerActive = false
    if pullTimerFrame then pullTimerFrame:Hide() end
    SendToChannel("Pull cancelled!")
end

local function DoRaidPause()
    local db = AruiQOLDB and AruiQOLDB.RaidBar
    if not db or not db.enabled then return end

    local msg = db.pauseMessage or "--- RAID PAUSE --- Take a break, wait for RL!"
    SendToChannel(msg)
    print("|cff88ccff[RaidBar]|r Raid pause announced")
end


local _WoW_DoReadyCheck = DoReadyCheck

local function ReadyCheck()
    if (IsInRaid and IsInRaid()) or (GetNumPartyMembers and GetNumPartyMembers() > 0) then
        _WoW_DoReadyCheck()
    end
end


local function CreateButton(parent, id, label, iconPath, tooltipText, onClick)
    local btn = CreateFrame("Button", "AruiQOLRaidBar_" .. id, parent)
    btn:SetSize(BUTTON_SIZE, BUTTON_SIZE)

    btn:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 8, edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    btn:SetBackdropColor(0.04, 0.06, 0.1, 0.95)
    btn:SetBackdropBorderColor(0.2, 0.35, 0.55, 0.6)

    if iconPath then
        btn.icon = btn:CreateTexture(nil, "ARTWORK")
        btn.icon:SetTexture(iconPath)
        btn.icon:SetPoint("TOPLEFT", 4, -4)
        btn.icon:SetPoint("BOTTOMRIGHT", -4, 4)
        btn.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        btn.icon:SetAlpha(0.85)
    end

    if label then
        btn.label = btn:CreateFontString(nil, "OVERLAY")
        btn.label:SetFont(FONT_PATH, iconPath and 8 or 9, "OUTLINE")
        btn.label:SetPoint("CENTER", 0, 0)
        btn.label:SetText(label)
        btn.label:SetTextColor(0.8, 0.9, 1, 1)
    end

    btn:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(0.4, 0.7, 1, 1)
        self:SetBackdropColor(0.1, 0.14, 0.24, 0.98)
        if self.icon then self.icon:SetAlpha(1) end
        if tooltipText then
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(tooltipText, 0.8, 0.9, 1, 1, true)
            GameTooltip:Show()
        end
    end)
    btn:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(0.2, 0.35, 0.55, 0.6)
        self:SetBackdropColor(0.04, 0.06, 0.1, 0.95)
        if self.icon then self.icon:SetAlpha(0.85) end
        GameTooltip:Hide()
    end)

    btn:SetScript("OnMouseDown", function(self)
        self:SetBackdropColor(0.15, 0.2, 0.35, 0.98)
    end)
    btn:SetScript("OnMouseUp", function(self)
        self:SetBackdropColor(0.1, 0.14, 0.24, 0.98)
    end)

    btn:RegisterForClicks("LeftButtonDown", "RightButtonDown")
    btn:SetScript("OnClick", onClick)

    return btn
end

local function SaveBarPosition()
    if not mainFrame then return end
    local db = AruiQOLDB and AruiQOLDB.RaidBar
    if not db then return end
    local point, _, relativePoint, xOfs, yOfs = mainFrame:GetPoint()
    if point then
        db.position = {
            point = point,
            relativePoint = relativePoint,
            x = xOfs,
            y = yOfs,
        }
    end
end


local function CreateRaidBar()
    local db = AruiQOLDB and AruiQOLDB.RaidBar
    if not db then return end

    local buttons = {}
    if db.showReadyCheck then table.insert(buttons, "readycheck") end
    if db.showPull5 then table.insert(buttons, "pull5") end
    if db.showPull10 then table.insert(buttons, "pull10") end
    if db.showPull15 then table.insert(buttons, "pull15") end
    if db.showPullTimer then table.insert(buttons, "pull") end
    if db.showRaidPause then table.insert(buttons, "pause") end
    if db.showFlaskCheck then table.insert(buttons, "flask") end
    if db.showRoleCheck then table.insert(buttons, "roles") end
    if db.showCountdown then table.insert(buttons, "countdown") end

    local numButtons = #buttons
    if numButtons == 0 then
        if mainFrame then mainFrame:Hide() end
        return
    end

    local totalWidth = BAR_PADDING * 2 + numButtons * BUTTON_SIZE + (numButtons - 1) * BUTTON_SPACING

    if mainFrame then
        for _, btn in ipairs(barButtons) do
            if btn then
                btn:Hide()
                pcall(function() btn:SetScript("OnClick", nil) end)
                pcall(function() btn:SetScript("OnEnter", nil) end)
                pcall(function() btn:SetScript("OnLeave", nil) end)
                pcall(function() btn:SetScript("OnMouseDown", nil) end)
                pcall(function() btn:SetScript("OnMouseUp", nil) end)
                if btn.UnregisterAllEvents then btn:UnregisterAllEvents() end
                btn:SetParent(nil)
            end
        end
        wipe(barButtons)
    else
        mainFrame = CreateFrame("Frame", "AruiQOLRaidBarFrame", UIParent)
        mainFrame:SetMovable(true)
        mainFrame:SetClampedToScreen(true)
        mainFrame:EnableMouse(true)
        mainFrame:RegisterForDrag("LeftButton")
        mainFrame.isMoving = false
        mainFrame:SetScript("OnDragStart", function(self)
            if IsAltKeyDown() and self:IsMovable() then
                self:StartMoving()
                self.isMoving = true
            end
        end)
        mainFrame:SetScript("OnDragStop", function(self)
            if self.isMoving then
                self:StopMovingOrSizing()
                self.isMoving = false
                SaveBarPosition()
            end
        end)

        mainFrame:SetScript("OnEnter", function(self)
            if IsAltKeyDown() then
                GameTooltip:SetOwner(self, "ANCHOR_TOP")
                GameTooltip:SetText("RaidBar", 0.8, 0.9, 1)
                GameTooltip:AddLine("Alt+Drag to move", 0.5, 0.7, 1)
                GameTooltip:AddLine("/aqolrb reset - Reset position", 0.5, 0.7, 1)
                GameTooltip:Show()
            end
        end)
        mainFrame:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
        end)

        _G["AruiQOLRaidBarFrame"] = mainFrame
    end

    mainFrame:SetSize(totalWidth, BAR_HEIGHT)
    mainFrame:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
        tile = true, tileSize = 32, edgeSize = 1,
    })
    mainFrame:SetBackdropColor(0.03, 0.04, 0.08, 0.94)
    mainFrame:SetBackdropBorderColor(0.15, 0.28, 0.45, 0.9)

    if mainFrame.accentLine then
        mainFrame.accentLine:Show()
    else
        mainFrame.accentLine = mainFrame:CreateTexture(nil, "OVERLAY")
        mainFrame.accentLine:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 2, -1)
        mainFrame.accentLine:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -2, -1)
        mainFrame.accentLine:SetHeight(2)
        mainFrame.accentLine:SetColorTexture(0.25, 0.55, 0.9, 0.7)
    end

    if mainFrame.bottomLine then
        mainFrame.bottomLine:Show()
    else
        mainFrame.bottomLine = mainFrame:CreateTexture(nil, "OVERLAY")
        mainFrame.bottomLine:SetPoint("BOTTOMLEFT", mainFrame, "BOTTOMLEFT", 2, 1)
        mainFrame.bottomLine:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -2, 1)
        mainFrame.bottomLine:SetHeight(1)
        mainFrame.bottomLine:SetColorTexture(0.15, 0.3, 0.5, 0.4)
    end

    if db.position then
        mainFrame:ClearAllPoints()
        mainFrame:SetPoint(db.position.point, UIParent, db.position.relativePoint, db.position.x, db.position.y)
    else
        mainFrame:ClearAllPoints()
        mainFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
    end

    local xOffset = BAR_PADDING

    for i, btnId in ipairs(buttons) do
        local btn

        if btnId == "readycheck" then
            btn = CreateButton(mainFrame, "ReadyCheck", nil,
                "Interface\\RaidFrame\\ReadyCheck-Ready",
                "Ready Check\nClick to start",
                function(self, button)
                    ReadyCheck()
                end)

        elseif btnId == "pull5" then
            btn = CreateButton(mainFrame, "Pull5", "5",
                "Interface\\AddOns\\AruiQOL\\Media\\1.tga",
                "Pull 5s\nStart 5-second pull timer",
                function(self, button)
                    StartPullTimer(5)
                end)

        elseif btnId == "pull10" then
            btn = CreateButton(mainFrame, "Pull10", "10",
                "Interface\\AddOns\\AruiQOL\\Media\\2.tga",
                "Pull 10s\nStart 10-second pull timer",
                function(self, button)
                    StartPullTimer(10)
                end)

        elseif btnId == "pull15" then
            btn = CreateButton(mainFrame, "Pull15", "15",
                "Interface\\AddOns\\AruiQOL\\Media\\3.tga",
                "Pull 15s\nStart 15-second pull timer",
                function(self, button)
                    StartPullTimer(15)
                end)

        elseif btnId == "pull" then
            btn = CreateButton(mainFrame, "Pull", nil,
                "Interface\\AddOns\\AruiQOL\\Media\\5.tga",
                "Pull Timer (" .. (db.pullTimerDuration or 10) .. "s)\nLeft: Start\nRight: Cancel",
                function(self, button)
                    if button == "RightButton" then
                        CancelPullTimer()
                    else
                        StartPullTimer(db.pullTimerDuration or 10)
                    end
                end)

        elseif btnId == "pause" then
            btn = CreateButton(mainFrame, "Pause", nil,
                "Interface\\AddOns\\AruiQOL\\Media\\4.tga",
                "Raid Pause\nAnnounce a break",
                function(self, button)
                    DoRaidPause()
                end)

        elseif btnId == "flask" then
            btn = CreateButton(mainFrame, "Flask", nil,
                "Interface\\Icons\\INV_Potion_51",
                "Flask/Food Check\nLeft: Self, Right: Chat",
                function(self, button)
                    if _G.AruiQOLRaidCheckDoCheck then
                        _G.AruiQOLRaidCheckDoCheck(button == "RightButton" and "chat" or "self")
                    end
                end)

        elseif btnId == "roles" then
            btn = CreateButton(mainFrame, "Roles", nil,
                "Interface\\Icons\\INV_Helmet_15",
                "Role Check\nInitiate a role check",
                function(self, button)
                    InitiateRolePoll()
                end)

        elseif btnId == "countdown" then
            btn = CreateButton(mainFrame, "Countdown", nil,
                "Interface\\Icons\\INV_Misc_PocketWatch_01",
                "Countdown\nLeft: 5s, Right: 10s",
                function(self, button)
                    local dur = button == "RightButton" and 10 or 5
                    if C_PartyInfo and C_PartyInfo.DoCountdown then
                        C_PartyInfo.DoCountdown(dur)
                    else
                        StartPullTimer(dur)
                    end
                end)
        end

        if btn then
            btn:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", xOffset, -BAR_PADDING)
            xOffset = xOffset + BUTTON_SIZE + BUTTON_SPACING
            table.insert(barButtons, btn)
        end
    end

    if not pullTimerFrame then
        pullTimerFrame = CreateFrame("Frame", "AruiQOLRaidBarPullTimer", UIParent)
        pullTimerFrame:SetSize(120, 60)
        pullTimerFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 300)
        pullTimerFrame:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 16,
        })
        pullTimerFrame:SetBackdropColor(0, 0, 0, 0.85)
        pullTimerFrame:SetBackdropBorderColor(1, 0.3, 0.3, 1)

        pullTimerFrame.text = pullTimerFrame:CreateFontString(nil, "OVERLAY")
        pullTimerFrame.text:SetFont("Fonts\\skurri.ttf", 36, "OUTLINE")
        pullTimerFrame.text:SetPoint("CENTER", 0, 0)
        pullTimerFrame.text:SetTextColor(1, 0.3, 0.3)
        pullTimerFrame.text:SetShadowColor(0, 0, 0, 0.8)
        pullTimerFrame.text:SetShadowOffset(2, -2)
        pullTimerFrame:Hide()
    end

    if db.showOnlyInRaid then
        if IsInRaid and IsInRaid() then
            mainFrame:Show()
        elseif db.showInParty and GetNumPartyMembers and GetNumPartyMembers() > 0 then
            mainFrame:Show()
        else
            mainFrame:Hide()
        end
    else
        mainFrame:Show()
    end
end


local function UpdateVisibility()
    local db = AruiQOLDB and AruiQOLDB.RaidBar
    if not db or not db.enabled or not mainFrame then return end

    if db.showOnlyInRaid then
        if IsInRaid and IsInRaid() then
            mainFrame:Show()
        elseif db.showInParty and GetNumPartyMembers and GetNumPartyMembers() > 0 then
            mainFrame:Show()
        else
            mainFrame:Hide()
        end
    else
        mainFrame:Show()
    end
end


local function GetRaidBarFrame()
    local f = _G["AruiQOLRaidBarFrame"]
    if f and type(f) == "table" and f.IsObjectType and f:IsObjectType("Frame") then
        return f
    end
    return mainFrame
end

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        self:UnregisterEvent("PLAYER_LOGIN")

        local db = AruiQOLDB and AruiQOLDB.RaidBar
        if not db or not db.enabled then return end

        CreateRaidBar()

        local groupFrame = CreateFrame("Frame")
        groupFrame:RegisterEvent("RAID_ROSTER_UPDATE")
        groupFrame:RegisterEvent("PARTY_MEMBERS_CHANGED")
        groupFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
        groupFrame:SetScript("OnEvent", function(self, ev)
            C_Timer.After(0.5, UpdateVisibility)
        end)

        print("|cff88ccff[RaidBar]|r Loaded - Alt+Drag to move, /aqolrb for options")
    end
end)

SLASH_ARUIQOLRB1 = "/aqolrb"
SlashCmdList["ARUIQOLRB"] = function(msg)
    local db = AruiQOLDB and AruiQOLDB.RaidBar
    if not db then return end

    local cmd = string.lower(msg or "")

    if cmd == "reset" then
        db.position = nil
        local f = GetRaidBarFrame()
        if f then
            f:ClearAllPoints()
            f:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
        end
        print("|cff88ccff[RaidBar]|r Position reset")
    elseif cmd == "toggle" then
        db.enabled = not db.enabled
        if db.enabled then
            CreateRaidBar()
            print("|cff88ccff[RaidBar]|r |cff00ff00ON|r")
        else
            local f = GetRaidBarFrame()
            if f then f:Hide() end
            print("|cff88ccff[RaidBar]|r |cffff0000OFF|r")
        end
    elseif cmd == "pull" then
        StartPullTimer(db.pullTimerDuration or 10)
    elseif cmd == "pull5" then
        StartPullTimer(5)
    elseif cmd == "pull10" then
        StartPullTimer(10)
    elseif cmd == "pull15" then
        StartPullTimer(15)
    elseif cmd == "cancel" then
        CancelPullTimer()
    elseif cmd == "rebuild" then
        CreateRaidBar()
        print("|cff88ccff[RaidBar]|r Rebuilt")
    else
        print("|cff88ccff[RaidBar]|r Commands:")
        print("  /aqolrb toggle - Toggle on/off")
        print("  /aqolrb pull - Start pull timer")
        print("  /aqolrb pull5 - 5s pull timer")
        print("  /aqolrb pull10 - 10s pull timer")
        print("  /aqolrb pull15 - 15s pull timer")
        print("  /aqolrb cancel - Cancel pull timer")
        print("  /aqolrb reset - Reset position")
        print("  /aqolrb rebuild - Rebuild bar")
        print("  Alt+Drag to move the bar")
    end
end

_G.AruiQOLRaidBarModule = RaidBar
_G.AruiQOLRaidBar_Rebuild = CreateRaidBar
_G.AruiQOLRaidBar_GetFrame = GetRaidBarFrame
