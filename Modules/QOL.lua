-- ============================================================
-- Arui QOL - Quality of Life Module
-- ============================================================

local QOL = {}
local merchantFrame = nil

local function SetupMerchantFrame()
    if merchantFrame then return end
    merchantFrame = CreateFrame("Frame")
    merchantFrame:RegisterEvent("MERCHANT_SHOW")
    merchantFrame:SetScript("OnEvent", function()
        if UnitAffectingCombat("player") then return end

        C_Timer.After(0.5, function()
            if not AruiQOLDB or not AruiQOLDB.QOL then return end

            -- Sell grey items
            if AruiQOLDB.QOL.autoSellGreys then
                local totalSold = 0
                for bag = 0, 4 do
                    for slot = 1, GetContainerNumSlots(bag) do
                        local itemLink = GetContainerItemLink(bag, slot)
                        if itemLink then
                            local _, _, quality = GetItemInfo(itemLink)
                            if quality == 0 then
                                UseContainerItem(bag, slot)
                                totalSold = totalSold + 1
                            end
                        end
                    end
                end
                if totalSold > 0 then
                    print("|cff88ccff[Arui QOL]|r Sold " .. totalSold .. " grey items")
                end
            end

            -- Auto repair
            if AruiQOLDB.QOL.autoRepair then
                local repairCost = GetRepairAllCost()
                if repairCost and repairCost > 0 then
                    if AruiQOLDB.QOL.useGuildRepair and CanGuildBankRepair() then
                        RepairAllItems(true)
                        print("|cff88ccff[Arui QOL]|r Repaired with guild bank")
                    else
                        RepairAllItems()
                        print("|cff88ccff[Arui QOL]|r Equipment repaired")
                    end
                end
            end
        end)
    end)
end

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        self:UnregisterEvent("PLAYER_LOGIN")
        SetupMerchantFrame()
        
    end
end)
