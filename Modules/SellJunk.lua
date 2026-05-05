-- ============================================================
-- Arui QOL - Sell Junk Module
-- ============================================================

local SellJunk = {}

local GREY   = 0
local WHITE  = 1

-- Item quality names for display
local QUALITY_NAMES = {
    [0] = "|cff9d9d9dGrigio|r",
    [1] = "|cffffffffBianco|r",
}

-- ==================== SELL LOGIC ====================

local function GetItemSellPrice(itemLink)
    if not itemLink then return 0 end
    local _, _, _, _, _, _, _, _, _, _, sellPrice = GetItemInfo(itemLink)
    return sellPrice or 0
end

local function SellItems(maxQuality)
    local itemsSold = 0
    local totalCopper = 0
    local soldItems = {}

    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            local itemLink = GetContainerItemLink(bag, slot)
            if itemLink then
                local _, _, quality = GetItemInfo(itemLink)
                if quality and quality <= maxQuality then
                    local sellPrice = GetItemSellPrice(itemLink)
                    if sellPrice and sellPrice > 0 then
                        -- Get stack count
                        local _, count = GetContainerItemInfo(bag, slot)
                        count = count or 1

                        -- Calculate total for this stack
                        local stackValue = sellPrice * count

                        -- Record item name
                        local itemName = itemLink:match("%[(.-)%]") or itemLink
                        table.insert(soldItems, {
                            name = itemName,
                            count = count,
                            value = stackValue,
                        })

                        -- Sell it
                        UseContainerItem(bag, slot)
                        itemsSold = itemsSold + 1
                        totalCopper = totalCopper + stackValue
                    end
                end
            end
        end
    end

    return itemsSold, totalCopper, soldItems
end

--- Format copper to gold/silver/copper string
local function FormatMoney(copper)
    if not copper or copper <= 0 then return "|cffaaaaaa0|r" end
    local gold = floor(copper / 10000)
    local silver = floor((copper % 10000) / 100)
    local copperRemain = copper % 100
    local str = ""
    if gold > 0 then
        str = str .. "|cffffd700" .. gold .. "g|r "
    end
    if silver > 0 or gold > 0 then
        str = str .. "|cffc0c0c0" .. silver .. "s|r "
    end
    if copperRemain > 0 or (gold == 0 and silver == 0) then
        str = str .. "|cffcccc99" .. copperRemain .. "c|r"
    end
    return str
end

-- ==================== MAIN MODULE ====================

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        self:UnregisterEvent("PLAYER_LOGIN")

        local merchantFrame = CreateFrame("Frame")
        merchantFrame:RegisterEvent("MERCHANT_SHOW")
        merchantFrame:SetScript("OnEvent", function()
            if UnitAffectingCombat("player") then return end

            local db = AruiQOLDB and AruiQOLDB.QOL
            if not db then return end

            C_Timer.After(0.5, function()
                -- ====== Auto Repair ======
                if db.autoRepair then
                    local repairCost = GetRepairAllCost()
                    if repairCost and repairCost > 0 then
                        local canAfford = GetMoney() >= repairCost
                        if canAfford then
                            if db.useGuildRepair and CanGuildBankRepair then
                                RepairAllItems(true)
                                print("|cff88ccff[AruiQOL]|r Riparato con banca di gilda: " .. FormatMoney(repairCost))
                            else
                                RepairAllItems()
                                print("|cff88ccff[AruiQOL]|r Equipaggiamento riparato: " .. FormatMoney(repairCost))
                            end
                        else
                            print("|cffff4444[AruiQOL]|r Non puoi permetterti la riparazione: " .. FormatMoney(repairCost))
                        end
                    end
                end

                -- ====== Sell Grey (and optionally White) Items ======
                if db.autoSellGreys then
                    local maxQuality = GREY
                    if db.sellWhites then
                        maxQuality = WHITE
                    end

                    local itemsSold, totalCopper, soldItems = SellItems(maxQuality)

                    if itemsSold > 0 then
                        local qualityStr = QUALITY_NAMES[GREY]
                        if db.sellWhites then
                            qualityStr = QUALITY_NAMES[GREY] .. " e " .. QUALITY_NAMES[WHITE]
                        end
                        print("|cff88ccff[AruiQOL]|r Venduti " .. itemsSold .. " oggetti (" .. qualityStr .. ") per " .. FormatMoney(totalCopper))

                        -- Detailed log (up to 10 items)
                        if db.sellVerbose then
                            local show = min(#soldItems, 10)
                            for i = 1, show do
                                local item = soldItems[i]
                                local countStr = item.count > 1 and (" x" .. item.count) or ""
                                print("  |cffaaaaaa- |r" .. item.name .. countStr .. " " .. FormatMoney(item.value))
                            end
                            if #soldItems > 10 then
                                print("  |cffaaaaaa... e altri " .. (#soldItems - 10) .. " oggetti|r")
                            end
                        end
                    end
                end
            end)
        end)
    end
end)
