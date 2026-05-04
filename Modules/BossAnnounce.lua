-- ============================================================
-- Arui QOL - Boss Announce Module
-- ============================================================

local BossAnnounce = {}
local bossName = nil
local startTime = 0
local isFighting = false
local announcedHealth = {}
local bossEventFrame = nil
local healthCheckTicker = nil

local function SendAnnouncement(message)
    local db = AruiQOLDB and AruiQOLDB.BossAnnounce
    if not db or not db.enabled then return end

    if db.announceParty and IsInGroup() and not IsInRaid() then
        SendChatMessage(message, "PARTY")
    end
    if db.announceRaid and IsInRaid() then
        SendChatMessage(message, "RAID")
    end
    if db.announceGuild and IsInGuild() then
        SendChatMessage(message, "GUILD")
    end
end

local function FormatDuration(seconds)
    local mins = math.floor(seconds / 60)
    local secs = math.floor(seconds % 60)
    return string.format("%02d:%02d", mins, secs)
end

local function ResetFightState()
    bossName = nil
    startTime = 0
    isFighting = false
    announcedHealth = {}
    if healthCheckTicker then healthCheckTicker:Cancel() healthCheckTicker = nil end
end

local function StartHealthCheck()
    if healthCheckTicker then healthCheckTicker:Cancel() end
    healthCheckTicker = C_Timer.NewTicker(0.5, function()
        if not isFighting then
            if healthCheckTicker then healthCheckTicker:Cancel() end
            healthCheckTicker = nil
            return
        end
        local db = AruiQOLDB and AruiQOLDB.BossAnnounce
        if not db or not db.enabled or not db.minBossHealth or db.minBossHealth <= 0 then return end

        for i = 1, 5 do
            local unit = "boss" .. i
            if UnitExists(unit) then
                local name = UnitName(unit)
                if name and not announcedHealth[name] then
                    local healthPct = (UnitHealth(unit) / UnitHealthMax(unit)) * 100
                    if healthPct <= db.minBossHealth then
                        announcedHealth[name] = true
                        SendAnnouncement("!! " .. name .. " below " .. db.minBossHealth .. "% HP !!")
                    end
                end
            end
        end
    end)
end

local function OnBossEvent(event)
    local db = AruiQOLDB and AruiQOLDB.BossAnnounce
    if not db or not db.enabled then return end

    if db.announceOnlyInInstance then
        local _, instanceType = GetInstanceInfo()
        if instanceType ~= "party" and instanceType ~= "raid" then return end
    end

    local currentBoss = nil
    for i = 1, 5 do
        if UnitExists("boss" .. i) then
            currentBoss = UnitName("boss" .. i)
            break
        end
    end

    if (event == "INSTANCE_ENCOUNTER_ENGAGE_UNIT" or event == "PLAYER_REGEN_DISABLED") then
        if currentBoss and not isFighting then
            bossName = currentBoss
            startTime = GetTime()
            isFighting = true
            announcedHealth = {}

            local msg = "Boss fight: " .. bossName
            SendAnnouncement(msg)
            if db.playSound then PlaySound("RaidWarning") end
            if db.minBossHealth and db.minBossHealth > 0 then
                StartHealthCheck()
            end
        end
    end

    if event == "INSTANCE_ENCOUNTER_ENGAGE_UNIT" and not currentBoss and isFighting then
        local duration = GetTime() - startTime
        local timeStr = FormatDuration(duration)
        local msg = "Boss down: " .. bossName
        if db.showTimer then msg = msg .. " (" .. timeStr .. ")" end
        SendAnnouncement(msg)
        ResetFightState()
    end

    if event == "PLAYER_REGEN_ENABLED" and not currentBoss and isFighting then
        ResetFightState()
    end
end

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        self:UnregisterEvent("PLAYER_LOGIN")

        bossEventFrame = CreateFrame("Frame")
        bossEventFrame:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
        bossEventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
        bossEventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
        bossEventFrame:SetScript("OnEvent", function(self, ev)
            OnBossEvent(ev)
        end)

        
    end
end)
