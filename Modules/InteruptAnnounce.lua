-- ============================================================
-- Arui QOL - Interrupt Announce Module
-- Uses select() on event args for 3.3.5 compatibility
-- ============================================================

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        self:UnregisterEvent("PLAYER_LOGIN")

        local interruptFrame = CreateFrame("Frame")
        interruptFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        interruptFrame:SetScript("OnEvent", function(self, ev, ...)
            if ev ~= "COMBAT_LOG_EVENT_UNFILTERED" then return end

            local db = AruiQOLDB and AruiQOLDB.InterruptAnnounce
            if not db or not db.enabled then return end

            -- In 3.3.5, combat log args come as varargs:
            -- 1=timestamp, 2=combatEvent, 3=hideCaster, 4=sourceGUID, 5=sourceName,
            -- 6=sourceFlags, 7=sourceRaidFlags, 8=destGUID, 9=destName,
            -- 10=destFlags, 11=destRaidFlags, 12=spellID, 13=spellName, 14=spellSchool
            -- For SPELL_INTERRUPT: 15=extraSpellID, 16=extraSpellName, 17=extraSpellSchool
            local timestamp, combatEvent, hideCaster, sourceGUID, sourceName,
                  sourceFlags, sourceRaidFlags, destGUID, destName,
                  destFlags, destRaidFlags, spellID, spellName, spellSchool,
                  extraSpellID, extraSpellName, extraSpellSchool = select(1, ...)

            if combatEvent ~= "SPELL_INTERRUPT" then return end

            local isSelf = sourceName and (sourceName == UnitName("player"))
            if not isSelf then return end

            local intSpellLink = GetSpellLink(extraSpellID) or ""

            local msg
            if db.verbose then
                msg = "=> Interrupted: " .. (destName or "Unknown") .. "'s " .. intSpellLink .. "."
            else
                msg = "Interrupted: " .. (destName or "Unknown") .. "'s " .. intSpellLink .. "."
            end

            local output = db.output or "Auto"
            if output == "Self" then
                return
            elseif output == "Auto" then
                if GetNumRaidMembers() >= 1 then
                    SendChatMessage(msg, "RAID")
                elseif GetNumPartyMembers() >= 1 then
                    SendChatMessage(msg, "PARTY")
                end
            elseif output == "Say" then
                SendChatMessage(msg, "SAY")
            elseif output == "Party" then
                if GetNumPartyMembers() >= 1 then
                    SendChatMessage(msg, "PARTY")
                end
            elseif output == "Raid" then
                if GetNumRaidMembers() >= 1 then
                    SendChatMessage(msg, "RAID")
                end
            end
        end)

        
    end
end)
