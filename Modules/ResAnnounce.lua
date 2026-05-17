-- ============================================================
-- Arui QOL - ResAnnounce Module
-- ============================================================

local resAnnounceFrame = nil
local PET_NAME = nil
local hasSoulstone = false

local function SendAnnouncement(chatMessage, target)
    if not AruiQOLDB or not AruiQOLDB.ResAnnounce then return end
    local db = AruiQOLDB.ResAnnounce
    if not db.enabled then return end

    -- Priority
    if db.displayRaid and GetNumRaidMembers() >= 1 then
        SendChatMessage(chatMessage, "RAID")
    elseif db.displayParty and GetNumPartyMembers() >= 1 then
        SendChatMessage(chatMessage, "PARTY")
    elseif db.displaySay then
        SendChatMessage(chatMessage, "SAY")
    end

    -- Also whisper the target
    if db.displayWhisper and target and string.upper(target) ~= "UNKNOWN" then
        SendChatMessage(chatMessage, "WHISPER", nil, target)
    end
end

local function PickQuote(playerClass, target)
    local chatMessage
    if string.upper(target) == "UNKNOWN" then
        chatMessage = noTargetQuotes[random(#(noTargetQuotes))]
    elseif playerClass == "Hunter" then
        chatMessage = hunterQuotes[random(#(hunterQuotes))]
    elseif playerClass == "Combat" then
        chatMessage = combatQuotes[random(#(combatQuotes))]
    elseif playerClass == "Engineer" then
        chatMessage = engineerQuotes[random(#(engineerQuotes))]
    elseif playerClass == "Warlock" then
        chatMessage = warlockQuotes[random(#(warlockQuotes))]
    elseif playerClass == "Self" then
        chatMessage = selfQuotes[random(#(selfQuotes))]
    elseif playerClass == "DeathKnightDead" then
        chatMessage = noghoulQuotes[random(#(noghoulQuotes))]
    elseif playerClass == "DeathKnightAlly" then
        chatMessage = ghoulQuotes[random(#(ghoulQuotes))]
    else
        chatMessage = otherQuotes[random(#(otherQuotes))]
    end

    if chatMessage then
        chatMessage = string.gsub(chatMessage, "%%t", target or "Unknown")
        SendAnnouncement(chatMessage, target)
    end
end

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        self:UnregisterEvent("PLAYER_LOGIN")

        resAnnounceFrame = CreateFrame("Frame")
        resAnnounceFrame:RegisterEvent("UNIT_SPELLCAST_SENT")
        resAnnounceFrame:RegisterEvent("PLAYER_DEAD")
        resAnnounceFrame:RegisterEvent("PLAYER_ALIVE")

        resAnnounceFrame:SetScript("OnEvent", function(self, ev, arg1, arg2, arg3, arg4)
            if not AruiQOLDB or not AruiQOLDB.ResAnnounce or not AruiQOLDB.ResAnnounce.enabled then return end

            if ev == "UNIT_SPELLCAST_SENT" then
                if arg1 ~= "player" then return end

                if arg2 == "Redemption" then
                    PickQuote("Paladin", arg4)
                elseif arg2 == "Resurrection" then
                    PickQuote("Priest", arg4)
                elseif arg2 == "Ancestral Spirit" then
                    PickQuote("Shaman", arg4)
                elseif arg2 == "Revive" then
                    PickQuote("Druid", arg4)
                elseif arg2 == "Revive Pet" then
                    if PET_NAME then
                        PickQuote("Hunter", PET_NAME)
                    end
                elseif arg2 == "Rebirth" then
                    PickQuote("Combat", arg4)
                elseif arg2 == "Defibrillate" then
                    PickQuote("Engineer", arg4)
                elseif arg2 == "Raise Dead" then
                    PickQuote("DeathKnightDead", arg4)
                elseif arg2 == "Raise Ally" then
                    PickQuote("DeathKnightAlly", arg4)
                elseif arg2 == "Soulstone Resurrection" then
                    PickQuote("Warlock", arg4)
                end

            elseif ev == "PLAYER_DEAD" then
                hasSoulstone = false
                for i = 1, 40 do
                    local name = UnitBuff("player", i)
                    if name and string.find(name, "Soulstone") then
                        hasSoulstone = true
                        break
                    end
                end

            elseif ev == "PLAYER_ALIVE" then
                if hasSoulstone then
                    hasSoulstone = false
                    PickQuote("Self", "self")
                end
            end
        end)
    end
end)
