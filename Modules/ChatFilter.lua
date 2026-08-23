-- Arui QOL - Chat Filter Module

local ChatFilter = {}
local FILTER_LOG_LIMIT = 50
local DEDUPLICATE_INTERVAL = 0.5
local MAX_SPAM_MESSAGES_PER_PLAYER = 5
local SPAM_WINDOW = 30
local REPEAT_WINDOW = 10
local filterLog = {}
local spamTracker = {}
local repeatTracker = {}
local lastDedupeKey = nil
local lastDedupeTime = 0
local filtersRegistered = false

local function AddLog(player, msg, trigger)
    local key = player .. "|" .. (trigger or "") .. "|" .. (msg or "")
    if lastDedupeKey == key and (GetTime() - lastDedupeTime) < DEDUPLICATE_INTERVAL then return end
    lastDedupeKey = key
    lastDedupeTime = GetTime()
    local entry = string.format("|cff88ccff[Filtered]|r |cffff8800[%s]|r |cffd3d3d3%s: %s|r",
        trigger or "unknown", player or "?", msg or "")
    table.insert(filterLog, 1, entry)
    if #filterLog > FILTER_LOG_LIMIT then table.remove(filterLog) end
end

local function IsSpamBurst(sender)
    local db = AruiQOLDB and AruiQOLDB.ChatFilter
    if not db or not db.filterSpamBurst then return false end
    if not spamTracker[sender] then
        spamTracker[sender] = { count = 0, startTime = GetTime() }
    end
    local entry = spamTracker[sender]
    local now = GetTime()
    if (now - entry.startTime) > SPAM_WINDOW then
        entry.count = 1
        entry.startTime = now
        return false
    end
    entry.count = entry.count + 1
    return entry.count > MAX_SPAM_MESSAGES_PER_PLAYER
end

local function IsRepeatMessage(sender, msg)
    local db = AruiQOLDB and AruiQOLDB.ChatFilter
    if not db or not db.filterRepeat then return false end
    local key = sender .. ":" .. string.lower(msg)
    local now = GetTime()
    if repeatTracker[key] then
        local entry = repeatTracker[key]
        if (now - entry.time) < REPEAT_WINDOW then
            entry.count = entry.count + 1
            if entry.count >= 3 then
                return true
            end
        else
            entry.count = 1
            entry.time = now
        end
    else
        repeatTracker[key] = { count = 1, time = now }
    end
    return false
end

local function MatchesCustomKeywords(msg)
    local db = AruiQOLDB and AruiQOLDB.ChatFilter
    if not db or not db.customKeywords then return false, nil end
    local lowerMsg = string.lower(msg)
    for _, word in ipairs(db.customKeywords) do
        if word ~= "" and string.find(lowerMsg, string.lower(word), 1, true) then
            return true, "Keyword: " .. word
        end
    end
    return false, nil
end

local LFG_CHANNEL_NAMES = { "world", "ascension", "lfg", "global", "lookingforgroup" }

local function IsLFGChannel(channelName)
    if not channelName then return false end
    local lower = string.lower(channelName)
    for _, name in ipairs(LFG_CHANNEL_NAMES) do
        if string.find(lower, name, 1, true) then
            return true
        end
    end
    return false
end

local function MatchesChannelLFG(event, msg, channelName, ...)
    local db = AruiQOLDB and AruiQOLDB.ChatFilter
    if not db or not db.filterWorldLFG then return false, nil end
    if event ~= "CHAT_MSG_CHANNEL" then return false, nil end

    local isTargetChannel = false
    if db.filterAllChannelsLFG then
        isTargetChannel = true
    end

    if not isTargetChannel and IsLFGChannel(channelName) then
        isTargetChannel = true
    end

    if not isTargetChannel then
        local channelBaseName = select(5, ...)
        if IsLFGChannel(channelBaseName) then
            isTargetChannel = true
        end
    end

    if not isTargetChannel and db.filterLFGChannels then
        local channelIndex = select(4, ...)
        if channelIndex and db.filterLFGChannels[channelIndex] then
            isTargetChannel = true
        end
    end
    if not isTargetChannel then return false, nil end

    local lowerMsg = string.lower(msg)

    if string.find(lowerMsg, "lfg", 1, true) or string.find(lowerMsg, "lfm", 1, true) then
        return true, "Channel LFG"
    end

    if string.find(lowerMsg, "lf ", 1, true) or string.find(lowerMsg, "lf%d", 1) then
        local roles = { "dps", "tank", "heal", "healer", "heals" }
        for _, role in ipairs(roles) do
            if string.find(lowerMsg, role, 1, true) then
                return true, "Channel LF Role"
            end
        end
    end

    local roleForPatterns = {
        "healer for", "heals for", "tank for", "dps for",
        "need healer", "need tank", "need dps", "need heal", "need heals",
        "looking for healer", "looking for tank", "looking for dps",
        "looking for heal", "looking for heals",
        "looking for group", "looking for more", "looking for members",
    }
    for _, pattern in ipairs(roleForPatterns) do
        if string.find(lowerMsg, pattern, 1, true) then
            return true, "Channel LFG"
        end
    end

    if string.find(lowerMsg, "%d+ ?healer", 1) or string.find(lowerMsg, "%d+ ?tank", 1) or
       string.find(lowerMsg, "%d+ ?dps", 1) or string.find(lowerMsg, "%d+ ?heal", 1) then
        return true, "Channel LFG"
    end

    return false, nil
end

local function MatchesBoostFilter(msg)
    local db = AruiQOLDB and AruiQOLDB.ChatFilter
    if not db or not db.filterBoost then return false, nil end
    local lowerMsg = string.lower(msg)
    local boostWords = { "wts", "wtb", "selling", "boost", "boosting", "carry", "gdkp",
                         "pilot", "piloted", "cheap", "price", "service", "wtt", "trading gold",
                         "buying gold", "sell gold", "run for gold", "gold run" }
    for _, word in ipairs(boostWords) do
        if string.find(lowerMsg, word, 1, true) then return true, "Boost/Trade" end
    end
    return false, nil
end


local function MatchesGuildFilter(msg)
    local db = AruiQOLDB and AruiQOLDB.ChatFilter
    if not db or not db.filterGuild then return false, nil end
    local lowerMsg = string.lower(msg)
    local guildWords = { "guild", "community", "recruit", "recruiting", "roster",
                         "lf members", "lf guild", "new guild", "apply", "core group",
                         "static group", "raid team", "looking for members", "we raid" }
    for _, word in ipairs(guildWords) do
        if string.find(lowerMsg, word, 1, true) then return true, "Guild Recruit" end
    end
    return false, nil
end

local function MatchesTradeFilter(event, msg, channelName)
    local db = AruiQOLDB and AruiQOLDB.ChatFilter
    if not db or not db.filterTrade then return false, nil end
    if event ~= "CHAT_MSG_CHANNEL" then return false, nil end
    if not channelName then return false, nil end
    local lowerChan = string.lower(channelName)
    if string.find(lowerChan, "trade", 1, true) or string.find(lowerChan, "commercio", 1, true) then
        return true, "Trade Channel"
    end
    return false, nil
end

local function MatchesGeneralFilter(event, msg, channelName)
    local db = AruiQOLDB and AruiQOLDB.ChatFilter
    if not db or not db.filterGeneral then return false, nil end
    if event ~= "CHAT_MSG_CHANNEL" then return false, nil end
    if not channelName then return false, nil end
    local lowerChan = string.lower(channelName)
    if string.find(lowerChan, "general", 1, true) or string.find(lowerChan, "generale", 1, true) then
        return true, "General Channel"
    end
    return false, nil
end


local function MatchesLinkFilter(msg)
    local db = AruiQOLDB and AruiQOLDB.ChatFilter
    if not db or not db.filterLinks then return false, nil end
    if string.find(msg, "|Hitem:", 1, true) or string.find(msg, "|Hachievement:", 1, true) then
        return false, nil
    end
    if string.find(msg, "www%.", 1, true) or string.find(msg, "http://", 1, true) or
       string.find(msg, "https://", 1, true) or string.find(msg, "%.com", 1, true) or
       string.find(msg, "%.net", 1, true) or string.find(msg, "%.org", 1, true) then
        return true, "Link"
    end
    return false, nil
end

local function MatchesWhisperFilter(event, msg)
    local db = AruiQOLDB and AruiQOLDB.ChatFilter
    if not db or not db.filterWhisperSpam then return false, nil end
    if event ~= "CHAT_MSG_WHISPER" then return false, nil end
    local lowerMsg = string.lower(msg)
    local spamWords = { "boost", "carry", "gold", "buy", "sell", "cheap", "wts", "wtb",
                        "visit", "click", "free gold", "account", "login" }
    for _, word in ipairs(spamWords) do
        if string.find(lowerMsg, word, 1, true) then
            return true, "Whisper Spam"
        end
    end
    return false, nil
end

local function MatchesNonLatinFilter(msg)
    local db = AruiQOLDB and AruiQOLDB.ChatFilter
    if not db or not db.filterNonLatin then return false, nil end
    local clean = string.gsub(msg, "|c%x%x%x%x%x%x%x%x", "")
    clean = string.gsub(clean, "|r", "")
    clean = string.gsub(clean, "|H[^|]*|h[^|]*|h", "")
    clean = string.gsub(clean, "[%s%p%d]", "")
    if clean == "" then return false, nil end
    local total = string.len(clean)
    local latin = 0
    for i = 1, total do
        local byte = string.byte(clean, i)
        if byte and byte >= 32 and byte <= 126 then
            latin = latin + 1
        end
    end
    
    if total > 3 and (latin / total) < 0.3 then
        return true, "Non-Latin"
    end
    return false, nil
end

local function ShouldReplace()
    local db = AruiQOLDB and AruiQOLDB.ChatFilter
    return db and db.replaceMode
end

local function ChatFilter_OnEvent(self, event, msg, player, language, channelName, ...)
    local db = AruiQOLDB and AruiQOLDB.ChatFilter
    if not db or not db.enabled then return false end
    if not msg or not player then return false end

    player = string.gsub(player, "%-[^|]+", "")
    if player == UnitName("player") then return false end

    if IsSpamBurst(player) then
        AddLog(player, msg, "Spam Burst")
        if ShouldReplace() then return false, string.format("|cff666666[Spam Filtered]|r") end
        return true
    end

    if IsRepeatMessage(player, msg) then
        AddLog(player, msg, "Repeat")
        if ShouldReplace() then return false, string.format("|cff666666[Repeat Filtered]|r") end
        return true
    end

    local matched, trigger = MatchesCustomKeywords(msg)
    if matched then
        AddLog(player, msg, trigger)
        if ShouldReplace() then return false, string.format("|cff666666[Keyword Filtered]|r") end
        return true
    end

    matched, trigger = MatchesChannelLFG(event, msg, channelName, ...)
    if matched then
        AddLog(player, msg, trigger)
        if ShouldReplace() then return false, string.format("|cff666666[LFG Filtered]|r") end
        return true
    end

    matched, trigger = MatchesBoostFilter(msg)
    if matched then
        AddLog(player, msg, trigger)
        if ShouldReplace() then return false, string.format("|cff666666[Boost Filtered]|r") end
        return true
    end

    matched, trigger = MatchesGuildFilter(msg)
    if matched then
        AddLog(player, msg, trigger)
        if ShouldReplace() then return false, string.format("|cff666666[Guild Filtered]|r") end
        return true
    end

    matched, trigger = MatchesTradeFilter(event, msg, channelName)
    if matched then
        AddLog(player, msg, trigger)
        if ShouldReplace() then return false, string.format("|cff666666[Trade Filtered]|r") end
        return true
    end

    matched, trigger = MatchesGeneralFilter(event, msg, channelName)
    if matched then
        AddLog(player, msg, trigger)
        if ShouldReplace() then return false, string.format("|cff666666[General Filtered]|r") end
        return true
    end

    matched, trigger = MatchesLinkFilter(msg)
    if matched then
        AddLog(player, msg, trigger)
        if ShouldReplace() then return false, string.format("|cff666666[Link Filtered]|r") end
        return true
    end

    matched, trigger = MatchesWhisperFilter(event, msg)
    if matched then
        AddLog(player, msg, trigger)
        if ShouldReplace() then return false, string.format("|cff666666[Whisper Spam Filtered]|r") end
        return true
    end

    matched, trigger = MatchesNonLatinFilter(msg)
    if matched then
        AddLog(player, msg, trigger)
        if ShouldReplace() then return false, string.format("|cff666666[Non-Latin Filtered]|r") end
        return true
    end

    return false
end

function ChatFilter.GetLog()
    return filterLog
end

function ChatFilter.ClearLog()
    wipe(filterLog)
end

local function RegisterFilters()
    if filtersRegistered then return end
    filtersRegistered = true
    ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", ChatFilter_OnEvent)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_SAY", ChatFilter_OnEvent)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_YELL", ChatFilter_OnEvent)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", ChatFilter_OnEvent)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_EMOTE", ChatFilter_OnEvent)
end

C_Timer.NewTicker(60, function()
    local now = GetTime()
    for name, entry in pairs(spamTracker) do
        if (now - entry.startTime) > SPAM_WINDOW * 2 then
            spamTracker[name] = nil
        end
    end
    for key, entry in pairs(repeatTracker) do
        if (now - entry.time) > REPEAT_WINDOW * 2 then
            repeatTracker[key] = nil
        end
    end
end)

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        self:UnregisterEvent("PLAYER_LOGIN")
        RegisterFilters()
    end
end)

_G.AruiQOLChatFilter = ChatFilter
