-- ============================================================
-- Arui QOL - Redeemer Module
-- Resurrection quotes adapted from Redeemer by Ryplinn/Lightball
-- 3.3.5 WotLK compatible
-- ============================================================

local redeemerFrame = nil
local PET_NAME = nil
local hasSoulstone = false

local function Redeemer_SendQuotes(chatMessage, target)
    if not AruiQOLDB or not AruiQOLDB.Redeemer then return end
    local db = AruiQOLDB.Redeemer
    if not db.enabled then return end

    -- Priority: Raid > Party > Say
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

local function Redeemer_Quotes(playerClass, target)
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
        Redeemer_SendQuotes(chatMessage, target)
    end
end

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        self:UnregisterEvent("PLAYER_LOGIN")

        redeemerFrame = CreateFrame("Frame")
        redeemerFrame:RegisterEvent("UNIT_SPELLCAST_SENT")
        redeemerFrame:RegisterEvent("PLAYER_DEAD")
        redeemerFrame:RegisterEvent("PLAYER_ALIVE")

        redeemerFrame:SetScript("OnEvent", function(self, ev, arg1, arg2, arg3, arg4)
            if not AruiQOLDB or not AruiQOLDB.Redeemer or not AruiQOLDB.Redeemer.enabled then return end

            if ev == "UNIT_SPELLCAST_SENT" then
                -- arg1 = unit, arg2 = spell, arg3 = rank, arg4 = target
                if arg1 ~= "player" then return end

                if arg2 == "Redemption" then
                    Redeemer_Quotes("Paladin", arg4)
                elseif arg2 == "Resurrection" then
                    Redeemer_Quotes("Priest", arg4)
                elseif arg2 == "Ancestral Spirit" then
                    Redeemer_Quotes("Shaman", arg4)
                elseif arg2 == "Revive" then
                    Redeemer_Quotes("Druid", arg4)
                elseif arg2 == "Revive Pet" then
                    if PET_NAME then
                        Redeemer_Quotes("Hunter", PET_NAME)
                    end
                elseif arg2 == "Rebirth" then
                    Redeemer_Quotes("Combat", arg4)
                elseif arg2 == "Defibrillate" then
                    Redeemer_Quotes("Engineer", arg4)
                elseif arg2 == "Raise Dead" then
                    Redeemer_Quotes("DeathKnightDead", arg4)
                elseif arg2 == "Raise Ally" then
                    Redeemer_Quotes("DeathKnightAlly", arg4)
                elseif arg2 == "Soulstone Resurrection" then
                    Redeemer_Quotes("Warlock", arg4)
                end

            elseif ev == "PLAYER_DEAD" then
                -- Simple soulstone check via buff
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
                    Redeemer_Quotes("Self", "self")
                end
            end
        end)

        
    end
end)
