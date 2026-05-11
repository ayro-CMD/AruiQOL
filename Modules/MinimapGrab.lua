-- ============================================================
-- Arui QOL - Minimap Button Grabber Module
-- Collects all minimap buttons into a single expandable bar
-- Compatible with 3.3.5 and Cataclysm+ clients
-- ============================================================

local MinimapGrab = {}
local grabBar = nil
local isExpanded = false
local grabbedButtons = {}
local BUTTON_SIZE = 28
local BUTTON_SPACING = 4
local MAX_COLS = 10

-- Frames we must NEVER grab (exact name match)
local PROTECTED_FRAMES = {
    "Minimap", "MinimapBackdrop", "MinimapCluster", "MinimapBorder",
    "MinimapBorderTop", "MinimapZoomIn", "MinimapZoomOut", "MinimapNorthTag",
    "MiniMapMailFrame", "MiniMapMailBorder", "MiniMapMailIcon",
    "MiniMapTracking", "MiniMapTrackingFrame", "MiniMapTrackingIcon",
    "MiniMapTrackingButton", "MiniMapVoiceChatFrame", "MiniMapWorldMapButton",
    "MinimapZoneTextButton", "TimeManagerClockButton", "GameTimeFrame",
    "MinimapToggleButton", "FeedbackUIButton", "HelpOpenTicketButton",
    "MiniMapLFGFrame", "MiniMapBattlefieldFrame",
    "AruiQOL_TimerFrame", "AruiQOLMinimapGrabBar",
    "MinimapTooltip", "UIParent",
    -- NOTE: "AruiQOLMiniMapButton" is NOT here — we grab it too
}

-- Build a lookup set for fast checking
local protectedSet = {}
for _, v in ipairs(PROTECTED_FRAMES) do protectedSet[v] = true end

-- Name substrings that mean EXCLUDE (check with string.find, case-insensitive)
-- This catches "LibDBIcon10_FrostSeek" etc
local EXCLUDED_SUBSTRINGS = {
    "FrostSeek",
}

-- Prefixes that mean PROTECT unless it's a known addon
local PROTECTED_PREFIXES = {
    "MiniMap",
    "Minimap",
}

-- Known addon button name patterns — always grab these
local KNOWN_ADDON_PATTERNS = {
    "LibDBIcon",
    "DBM",
    "Omen",
    "Recount",
    "Skada",
    "Titan",
    "HealBot",
    "VuhDo",
    "Bartender",
    "ElvUI",
    "TidyPlates",
    "AtlasLoot",
    "GatherMate",
    "Gatherer",
    "Routes",
    "Carbonite",
    "Chinchilla",
    "SexyMap",
    "MinimapButtonFrame",
    "mbb",
    "AruiQOL",  -- Grab the main AruiQOL minimap button too
}

-- ==================== HELPER ====================

local function IsExcluded(name)
    if not name or name == "" then return true end
    -- Exact match against protected set
    if protectedSet[name] then return true end
    -- Check if name contains any excluded substring (case-insensitive)
    local lower = string.lower(name)
    for _, sub in ipairs(EXCLUDED_SUBSTRINGS) do
        if string.find(lower, string.lower(sub), 1, true) then
            return true
        end
    end
    -- Check if name starts with a protected prefix AND isn't a known addon
    for _, prefix in ipairs(PROTECTED_PREFIXES) do
        if string.lower(prefix) == string.lower(string.sub(name, 1, string.len(prefix))) then
            local isAddon = false
            for _, apat in ipairs(KNOWN_ADDON_PATTERNS) do
                if string.find(name, apat, 1, true) then isAddon = true; break end
            end
            if not isAddon then return true end
        end
    end
    return false
end

local function IsKnownAddonButton(name)
    if not name then return false end
    for _, pattern in ipairs(KNOWN_ADDON_PATTERNS) do
        if string.find(name, pattern, 1, true) then return true end
    end
    return false
end

local function IsNearMinimap(frame)
    if not frame or not frame:IsVisible() then return false end
    local scale = frame:GetEffectiveScale()
    if not scale or scale == 0 then return false end

    local fLeft = frame:GetLeft()
    local fRight = frame:GetRight()
    local fTop = frame:GetTop()
    local fBottom = frame:GetBottom()
    if not fLeft or not fRight or not fTop or not fBottom then return false end

    local mLeft = Minimap:GetLeft()
    local mRight = Minimap:GetRight()
    local mTop = Minimap:GetTop()
    local mBottom = Minimap:GetBottom()
    if not mLeft or not mRight or not mTop or not mBottom then return false end

    local margin = 150
    local nearHoriz = (fRight > (mLeft - margin)) and (fLeft < (mRight + margin))
    local nearVert = (fTop > (mBottom - margin)) and (fBottom < (mTop + margin))
    return nearHoriz and nearVert
end

local function LooksLikeMinimapButton(frame)
    if not frame then return false end
    local w = frame:GetWidth()
    local h = frame:GetHeight()
    if not w or not h then return false end
    if w < 10 or w > 60 or h < 10 or h > 60 then return false end
    local frameType = frame:GetObjectType()
    if frameType == "Button" then return true end
    if frame:IsMouseEnabled() then return true end
    return false
end

-- ==================== SCAN ALL CANDIDATE FRAMES ====================

local function CollectAllCandidates()
    local candidates = {}
    local seen = {}

    -- 1) Direct children of Minimap
    local children = { Minimap:GetChildren() }
    for _, child in ipairs(children) do
        local name = child:GetName()
        if name and not seen[name] then
            seen[name] = true
            table.insert(candidates, child)
        end
    end

    -- 2) Children of MinimapBackdrop
    if MinimapBackdrop then
        local ok, bdChildren = pcall(function() return { MinimapBackdrop:GetChildren() } end)
        if ok and bdChildren then
            for _, child in ipairs(bdChildren) do
                local name = child:GetName()
                if name and not seen[name] then
                    seen[name] = true
                    table.insert(candidates, child)
                end
            end
        end
    end

    -- 3) Children of MinimapCluster
    if MinimapCluster then
        local ok, clusterChildren = pcall(function() return { MinimapCluster:GetChildren() } end)
        if ok and clusterChildren then
            for _, child in ipairs(clusterChildren) do
                local name = child:GetName()
                if name and not seen[name] then
                    seen[name] = true
                    table.insert(candidates, child)
                end
            end
        end
    end

    -- 4) Scan _G for known addon button patterns
    for name, frame in pairs(_G) do
        if type(name) == "string" and type(frame) == "table" then
            local ok, isFrame = pcall(function() return frame.GetObjectType ~= nil end)
            if ok and isFrame and not seen[name] then
                if IsKnownAddonButton(name) then
                    seen[name] = true
                    table.insert(candidates, frame)
                end
            end
        end
    end

    -- 5) Check grandchildren of Minimap (some addons nest buttons)
    for _, child in ipairs(children) do
        local ok, grandChildren = pcall(function() return { child:GetChildren() } end)
        if ok and grandChildren then
            for _, grand in ipairs(grandChildren) do
                local name = grand:GetName()
                if name and not seen[name] then
                    seen[name] = true
                    table.insert(candidates, grand)
                end
            end
        end
    end

    return candidates
end

-- ==================== GRAB BAR CREATION ====================

local function CreateGrabBar()
    if grabBar then return end

    local db = AruiQOLDB and AruiQOLDB.MinimapGrab
    if not db then return end

    grabBar = CreateFrame("Frame", "AruiQOLMinimapGrabBar", UIParent)
    grabBar:SetSize(BUTTON_SIZE + 8, BUTTON_SIZE + 8)
    grabBar:SetFrameStrata("MEDIUM")
    grabBar:SetFrameLevel(50)
    grabBar:SetClampedToScreen(true)

    -- Position
    if db.barPos then
        grabBar:SetPoint(db.barPos.point, UIParent, db.barPos.relativePoint, db.barPos.x, db.barPos.y)
    else
        grabBar:SetPoint("TOPRIGHT", Minimap, "TOPLEFT", -10, 0)
    end

    -- Draggable on the frame itself
    grabBar:SetMovable(true)
    grabBar:EnableMouse(true)
    grabBar:RegisterForDrag("LeftButton")
    grabBar:SetScript("OnDragStart", function(self) self:StartMoving() end)
    grabBar:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relativePoint, x, y = self:GetPoint()
        if AruiQOLDB and AruiQOLDB.MinimapGrab then
            AruiQOLDB.MinimapGrab.barPos = {
                point = point, relativePoint = relativePoint, x = x, y = y,
            }
        end
    end)

    -- Toggle button - clean flat style, NO golden border
    local toggleBtn = CreateFrame("Button", nil, grabBar)
    toggleBtn:SetAllPoints()
    -- Register for drag so we can move the bar by dragging the toggle button
    toggleBtn:RegisterForDrag("LeftButton")
    toggleBtn:SetMovable(true)

    local toggleBg = toggleBtn:CreateTexture(nil, "BACKGROUND")
    toggleBg:SetAllPoints()
    toggleBg:SetColorTexture(0.1, 0.1, 0.15, 0.85)

    local toggleHighlight = toggleBtn:CreateTexture(nil, "HIGHLIGHT")
    toggleHighlight:SetAllPoints()
    toggleHighlight:SetColorTexture(0.5, 0.7, 1, 0.15)

    local toggleIcon = toggleBtn:CreateTexture(nil, "ARTWORK")
    toggleIcon:SetSize(18, 18)
    toggleIcon:SetPoint("CENTER")
    toggleIcon:SetTexture("Interface\\AddOns\\AruiQOL\\Media\\africa")

    -- Click to expand/collapse
    toggleBtn:SetScript("OnClick", function()
        if isExpanded then
            MinimapGrab.Collapse()
        else
            MinimapGrab.Expand()
        end
    end)

    -- Drag the bar when dragging the toggle button
    toggleBtn:SetScript("OnDragStart", function(self)
        grabBar:StartMoving()
    end)
    toggleBtn:SetScript("OnDragStop", function(self)
        grabBar:StopMovingOrSizing()
        local point, _, relativePoint, x, y = grabBar:GetPoint()
        if AruiQOLDB and AruiQOLDB.MinimapGrab then
            AruiQOLDB.MinimapGrab.barPos = {
                point = point, relativePoint = relativePoint, x = x, y = y,
            }
        end
    end)

    toggleBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("AruiQOL Minimap Buttons", 0.6, 0.8, 1)
        GameTooltip:AddLine("Click to expand/collapse", 1, 1, 1)
        GameTooltip:AddLine(string.format("%d buttons collected", #grabbedButtons), 0.8, 0.8, 0.8)
        GameTooltip:AddLine("Drag to move the bar", 0.6, 0.6, 0.6)
        GameTooltip:Show()
    end)
    toggleBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    grabBar.toggleBtn = toggleBtn
    grabBar.toggleIcon = toggleIcon
end

-- ==================== COLLECT BUTTONS ====================

local function ScanAndCollect()
    if not grabBar then return end
    local db = AruiQOLDB and AruiQOLDB.MinimapGrab
    if not db or not db.enabled then return end

    -- First restore any previously grabbed buttons
    for _, btnData in ipairs(grabbedButtons) do
        if btnData.frame and btnData.originalParent then
            pcall(function()
                btnData.frame:SetParent(btnData.originalParent)
                btnData.frame:ClearAllPoints()
                if btnData.originalPoint and btnData.originalPoint.point then
                    btnData.frame:SetPoint(
                        btnData.originalPoint.point,
                        btnData.originalPoint.relativeTo,
                        btnData.originalPoint.relativePoint,
                        btnData.originalPoint.x,
                        btnData.originalPoint.y
                    )
                end
                btnData.frame:SetScale(btnData.originalScale or 1)
                btnData.frame:Show()
            end)
        end
    end
    wipe(grabbedButtons)

    -- Get all candidates
    local candidates = CollectAllCandidates()

    local function alreadyGrabbed(name)
        for _, bd in ipairs(grabbedButtons) do
            if bd.name == name then return true end
        end
        return false
    end

    for _, frame in ipairs(candidates) do
        local name = frame:GetName()
        local skip = false
        if not name or name == "" then skip = true end
        if not skip and IsExcluded(name) then skip = true end
        if not skip and alreadyGrabbed(name) then skip = true end

        if not skip then
            local shouldGrab = false

            -- 1) Known addon pattern = always grab
            if IsKnownAddonButton(name) then
                shouldGrab = true
            -- 2) Looks like a button AND is near the minimap
            elseif LooksLikeMinimapButton(frame) and IsNearMinimap(frame) then
                shouldGrab = true
            -- 3) Direct child of Minimap and looks like a button
            elseif frame:GetParent() == Minimap and LooksLikeMinimapButton(frame) then
                shouldGrab = true
            end

            if shouldGrab then
                -- Save original state BEFORE touching the frame
                local point, relativeTo, relativePoint, x, y
                pcall(function() point, relativeTo, relativePoint, x, y = frame:GetPoint() end)
                local origScale = frame:GetScale()
                local origParent = frame:GetParent()

                local btnData = {
                    frame = frame,
                    name = name,
                    originalParent = origParent,
                    originalPoint = {
                        point = point,
                        relativeTo = relativeTo,
                        relativePoint = relativePoint,
                        x = x,
                        y = y,
                    },
                    originalScale = origScale,
                }
                table.insert(grabbedButtons, btnData)

                -- Reparent to grabBar immediately
                pcall(function()
                    frame:SetParent(grabBar)
                    -- Scale to fit BUTTON_SIZE but do NOT SetSize
                    local origW = frame:GetWidth() or 32
                    local origH = frame:GetHeight() or 32
                    local fitScale = BUTTON_SIZE / math.max(origW, origH, 1)
                    if fitScale < 0.3 then fitScale = 0.3 end
                    if fitScale > 2.0 then fitScale = 2.0 end
                    frame:SetScale(fitScale)
                    frame:ClearAllPoints()
                    frame:Hide()
                end)
            end
        end
    end

    print("|cff88ccff[MinimapGrab]|r Found " .. #grabbedButtons .. " minimap buttons.")
end

-- ==================== EXPAND / COLLAPSE ====================

function MinimapGrab.Expand()
    if not grabBar then return end

    -- Re-scan if empty
    if #grabbedButtons == 0 then
        ScanAndCollect()
    end

    isExpanded = true
    local count = #grabbedButtons
    if count == 0 then
        print("|cff88ccff[MinimapGrab]|r No minimap buttons found. Try /aqolmmb scan after all addons loaded.")
        return
    end

    -- Calculate grid layout
    local cols = math.min(count, MAX_COLS)
    local rows = math.ceil(count / cols)
    local totalWidth = cols * (BUTTON_SIZE + BUTTON_SPACING)
    local totalHeight = rows * (BUTTON_SIZE + BUTTON_SPACING)

    -- Resize bar to fit grid + toggle row at bottom
    grabBar:SetSize(totalWidth + 12, totalHeight + BUTTON_SIZE + BUTTON_SPACING + 12)

    -- Background panel
    if not grabBar.bgPanel then
        grabBar.bgPanel = grabBar:CreateTexture(nil, "BACKGROUND")
        grabBar.bgPanel:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    end
    grabBar.bgPanel:SetAllPoints()
    grabBar.bgPanel:SetVertexColor(0.05, 0.05, 0.1, 0.92)
    grabBar.bgPanel:Show()

    -- Simple dark border (NOT the golden tooltip border)
    if not grabBar.backdropApplied then
        grabBar:SetBackdrop({
            bgFile = "",
            edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
            tile = true, tileSize = 8, edgeSize = 1,
            insets = { left = 0, right = 0, top = 0, bottom = 0 }
        })
        grabBar:SetBackdropBorderColor(0.3, 0.4, 0.55, 0.8)
        grabBar.backdropApplied = true
    end

    -- Position toggle button at bottom center
    grabBar.toggleBtn:ClearAllPoints()
    grabBar.toggleBtn:SetPoint("BOTTOM", grabBar, "BOTTOM", 0, 4)
    grabBar.toggleBtn:SetSize(BUTTON_SIZE, BUTTON_SIZE)

    -- Layout grabbed buttons in grid
    for i, btnData in ipairs(grabbedButtons) do
        local row = math.ceil(i / cols)
        local col = ((i - 1) % cols) + 1
        local xOff = (col - 1) * (BUTTON_SIZE + BUTTON_SPACING) + 6
        local yOff = (row - 1) * (BUTTON_SIZE + BUTTON_SPACING) + 6

        pcall(function()
            btnData.frame:ClearAllPoints()
            btnData.frame:SetPoint("TOPLEFT", grabBar, "TOPLEFT", xOff, -yOff)
            btnData.frame:Show()
        end)
    end
end

function MinimapGrab.Collapse()
    if not grabBar then return end
    isExpanded = false

    -- Just hide buttons, keep them parented to grabBar
    for _, btnData in ipairs(grabbedButtons) do
        pcall(function() btnData.frame:Hide() end)
    end

    -- Shrink bar back to toggle-only size
    grabBar:SetSize(BUTTON_SIZE + 8, BUTTON_SIZE + 8)

    -- Reset toggle button
    grabBar.toggleBtn:ClearAllPoints()
    grabBar.toggleBtn:SetAllPoints()

    -- Hide panel
    if grabBar.bgPanel then grabBar.bgPanel:Hide() end
    if grabBar.backdropApplied then
        grabBar:SetBackdrop(nil)
        grabBar.backdropApplied = false
    end
end

-- ==================== RESTORE ALL ====================

function MinimapGrab.RestoreAll()
    for _, btnData in ipairs(grabbedButtons) do
        if btnData.frame and btnData.originalParent then
            pcall(function()
                btnData.frame:SetParent(btnData.originalParent)
                btnData.frame:ClearAllPoints()
                if btnData.originalPoint and btnData.originalPoint.point then
                    btnData.frame:SetPoint(
                        btnData.originalPoint.point,
                        btnData.originalPoint.relativeTo,
                        btnData.originalPoint.relativePoint,
                        btnData.originalPoint.x,
                        btnData.originalPoint.y
                    )
                end
                btnData.frame:SetScale(btnData.originalScale or 1)
                btnData.frame:Show()
            end)
        end
    end
    wipe(grabbedButtons)
    isExpanded = false
    if grabBar then
        grabBar:SetSize(BUTTON_SIZE + 8, BUTTON_SIZE + 8)
        grabBar.toggleBtn:ClearAllPoints()
        grabBar.toggleBtn:SetAllPoints()
        if grabBar.bgPanel then grabBar.bgPanel:Hide() end
        if grabBar.backdropApplied then
            grabBar:SetBackdrop(nil)
            grabBar.backdropApplied = false
        end
    end
    print("|cff88ccff[MinimapGrab]|r All buttons restored to original positions.")
end

-- ==================== LIVE ENABLE/DISABLE (no relog needed) ====================

function MinimapGrab.EnableLive()
    if not grabBar then CreateGrabBar() end
    if grabBar then
        grabBar:Show()
        ScanAndCollect()
        local db = AruiQOLDB and AruiQOLDB.MinimapGrab
        if db and db.startCollapsed then
            MinimapGrab.Collapse()
        else
            MinimapGrab.Expand()
        end
    end
end

function MinimapGrab.DisableLive()
    MinimapGrab.RestoreAll()
    if grabBar then
        grabBar:Hide()
    end
end

-- ==================== INIT ====================

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        self:UnregisterEvent("PLAYER_LOGIN")

        local db = AruiQOLDB and AruiQOLDB.MinimapGrab
        if not db then return end

        -- Create bar immediately
        CreateGrabBar()

        if db.enabled then
            -- Delay scan so other addons have loaded their buttons
            C_Timer.After(5, function()
                ScanAndCollect()
                if db.startCollapsed then
                    MinimapGrab.Collapse()
                else
                    MinimapGrab.Expand()
                end
            end)
            -- Second pass after 15s for slow-loading addons
            C_Timer.After(15, function()
                ScanAndCollect()
                if isExpanded then
                    MinimapGrab.Expand()
                end
            end)
        end

        -- Slash command
        SLASH_ARUIQOLMINIMAPGRAB1 = "/aqolmmb"
        SlashCmdList["ARUIQOLMINIMAPGRAB"] = function(msg)
            if msg == "restore" then
                MinimapGrab.RestoreAll()
            elseif msg == "scan" then
                ScanAndCollect()
                if isExpanded then MinimapGrab.Expand() end
            elseif msg == "expand" then
                MinimapGrab.Expand()
            elseif msg == "collapse" then
                MinimapGrab.Collapse()
            else
                print("|cff88ccff[MinimapGrab]|r Commands: /aqolmmb scan | expand | collapse | restore")
            end
        end
    end
end)

-- Expose globally
_G.AruiQOLMinimapGrab = MinimapGrab
