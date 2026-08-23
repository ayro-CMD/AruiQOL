-- Arui QOL - InviteWhisper Module

local InviteWhisper = {}


local lastInviteTime = 0
local INVITE_THROTTLE = 2.0


local function MatchesKeyword(message)
    local db = AruiQOLDB and AruiQOLDB.InviteWhisper
    if not db or not db.enabled then return false end

    local keywords = db.keywords or {}
    local lowerMsg = string.lower(message or "")

    for _, keyword in ipairs(keywords) do
        if keyword and keyword ~= "" then
            if string.find(lowerMsg, string.lower(keyword), 1, true) then
                return true
            end
        end
    end

    return false
end


local function TryInvite(sender)
    local db = AruiQOLDB and AruiQOLDB.InviteWhisper
    if not db or not db.enabled then return end

   
    if sender == UnitName("player") then return end

   
    local now = GetTime()
    if (now - lastInviteTime) < INVITE_THROTTLE then return end

   
    if IsInRaid and IsInRaid() then
        
        if not (IsRaidLeader() or IsRaidOfficer()) then
            if db.announceSelf ~= false then
                print("|cff88ccff[InviteWhisper]|r Can't invite - no assist in raid")
            end
            return
        end
    end

    local groupSize = 0
    if GetNumRaidMembers then groupSize = GetNumRaidMembers() end
    if groupSize == 0 and GetNumPartyMembers then groupSize = GetNumPartyMembers() + 1 end

    if IsInRaid and IsInRaid() and groupSize >= 40 then
        return
    end

    if not (IsInRaid and IsInRaid()) and groupSize >= 5 then
        
        if db.convertToRaid then
            ConvertToRaid()
            C_Timer.After(0.5, function()
                InviteUnit(sender)
            end)
            return
        else
            if db.announceSelf ~= false then
                print("|cff88ccff[InviteWhisper]|r Party full and auto-convert is off")
            end
            return
        end
    end

  
    local cleanSender = string.gsub(sender, "%-.*", "")

    lastInviteTime = GetTime()
    InviteUnit(cleanSender)

    if db.announceSelf ~= false then
        print("|cff88ccff[InviteWhisper]|r Invited |cff88ccff" .. cleanSender .. "|r")
    end
end


local function OnWhisper(self, event, msg, sender)
    local db = AruiQOLDB and AruiQOLDB.InviteWhisper
    if not db or not db.enabled then return end
    --ayro code
    local cleanSender = string.gsub(sender or "", "%-.*", "")
    if cleanSender == UnitName("player") then return end
    if UnitInParty(cleanSender) or UnitInRaid(cleanSender) then return end

    if MatchesKeyword(msg) then
        TryInvite(cleanSender)
    end
end


local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        self:UnregisterEvent("PLAYER_LOGIN")

        local db = AruiQOLDB and AruiQOLDB.InviteWhisper
        if not db then return end

        local whisperFrame = CreateFrame("Frame")
        whisperFrame:RegisterEvent("CHAT_MSG_WHISPER")
        whisperFrame:SetScript("OnEvent", OnWhisper)

        local keywordStr = table.concat(db.keywords or {}, ", ")
        print("|cff88ccff[InviteWhisper]|r Loaded - Keywords: |cff88ccff" .. keywordStr .. "|r")
    end
end)

SLASH_ARUIQOLIW1 = "/aqoliw"
SlashCmdList["ARUIQOLIW"] = function(msg)
    local db = AruiQOLDB and AruiQOLDB.InviteWhisper
    if not db then return end

    local cmd = string.lower(msg or "")

    if cmd == "toggle" then
        db.enabled = not db.enabled
        print("|cff88ccff[InviteWhisper]|r " .. (db.enabled and "|cff00ff00ON|r" or "|cffff0000OFF|r"))
    elseif string.sub(cmd, 1, 4) == "add " then
        local keyword = string.sub(msg, 5)
        if keyword and keyword ~= "" then
            table.insert(db.keywords, keyword)
            print("|cff88ccff[InviteWhisper]|r Added keyword: |cff88ccff" .. keyword .. "|r")
        end
    elseif string.sub(cmd, 1, 7) == "remove " then
        local keyword = string.sub(msg, 8)
        for i, kw in ipairs(db.keywords) do
            if string.lower(kw) == string.lower(keyword) then
                table.remove(db.keywords, i)
                print("|cff88ccff[InviteWhisper]|r Removed keyword: |cff88ccff" .. keyword .. "|r")
                break
            end
        end
    elseif cmd == "list" then
        print("|cff88ccff[InviteWhisper]|r Keywords:")
        for i, kw in ipairs(db.keywords or {}) do
            print("  " .. i .. ". |cff88ccff" .. kw .. "|r")
        end
    else
        print("|cff88ccff[InviteWhisper]|r Commands:")
        print("  /aqoliw toggle - Toggle on/off")
        print("  /aqoliw add <word> - Add keyword")
        print("  /aqoliw remove <word> - Remove keyword")
        print("  /aqoliw list - List keywords")
    end
end

_G.AruiQOLInviteWhisper = InviteWhisper
