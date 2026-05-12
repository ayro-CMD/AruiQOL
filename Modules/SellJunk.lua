-- ============================================================
-- Arui QOL - Sell Junk & Auto Repair Module
-- ============================================================

local SellJunk = {}

local GREY   = 0
local WHITE  = 1

-- Item quality names for display
local QUALITY_NAMES = {
    [0] = "|cff9d9d9dGrey|r",
    [1] = "|cffffffffWhite|r",
}

-- ==================== FORMAT MONEY ====================

local function FormatMoney(copper)
    if not copper or copper <= 0 then return "|cffaaaaaa0|r" end
    local gold = math.floor(copper / 10000)
    local silver = math.floor((copper % 10000) / 100)
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

-- ==================== SELL ITEMS ====================

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
        local slots = GetContainerNumSlots(bag)
        if slots then
            for slot = 1, slots do
                local itemLink = GetContainerItemLink(bag, slot)
                if itemLink then
                    local _, _, quality = GetItemInfo(itemLink)
                    if quality and quality <= maxQuality then
                        local sellPrice = GetItemSellPrice(itemLink)
                        if sellPrice and sellPrice > 0 then
                            local _, count = GetContainerItemInfo(bag, slot)
                            count = count or 1
                            local stackValue = sellPrice * count
                            local itemName = itemLink:match("%[(.-)%]") or itemLink
                            table.insert(soldItems, {
                                name = itemName,
                                count = count,
                                value = stackValue,
                            })
                            UseContainerItem(bag, slot)
                            itemsSold = itemsSold + 1
                            totalCopper = totalCopper + stackValue
                        end
                    end
                end
            end
        end
    end

    return itemsSold, totalCopper, soldItems
end

-- ==================== AUTO REPAIR ====================

local repairAttempt = 0
local MAX_REPAIR_ATTEMPTS = 8

local function DoRepair()
    local db = AruiQOLDB and AruiQOLDB.QOL
    if not db or not db.autoRepair then return end

    -- Check if merchant can repair
    local canRepair = false
    if CanMerchantRepair then
        canRepair = CanMerchantRepair()
    end

    if not canRepair then
        repairAttempt = repairAttempt + 1
        if repairAttempt < MAX_REPAIR_ATTEMPTS then
            -- Retry -- merchant data might not be ready yet on 3.3.5
            C_Timer.After(0.3, DoRepair)
        else
            -- Silently fail - vendor just can't repair
        end
        return
    end

    local repairCost = GetRepairAllCost()
    if not repairCost or repairCost == 0 then
        return
    end

    local money = GetMoney()
    if not money or money < repairCost then
        print("|cffff4444[AruiQOL]|r Can't afford repair: " .. FormatMoney(repairCost) .. " (have " .. FormatMoney(money) .. ")")
        return
    end

    -- Try guild repair first if enabled
    if db.useGuildRepair then
        if CanGuildBankRepair and CanGuildBankRepair() then
            RepairAllItems(1)  -- 1 = guild bank on 3.3.5
            print("|cff88ccff[AruiQOL]|r Repaired (guild): " .. FormatMoney(repairCost))
            return
        end
    end

    -- Normal repair - RepairAllItems() with no arg = personal gold on 3.3.5
    RepairAllItems()
    print("|cff88ccff[AruiQOL]|r Repaired: " .. FormatMoney(repairCost))
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
            -- Don't process if in combat
            if UnitAffectingCombat("player") then return end

            local db = AruiQOLDB and AruiQOLDB.QOL
            if not db then return end

            -- Auto Repair: delay first attempt so merchant data is ready on 3.3.5
            if db.autoRepair then
                repairAttempt = 0
                C_Timer.After(0.2, DoRepair)
            end

            -- Auto Sell: delay to ensure repair finished first
            C_Timer.After(0.8, function()
                if db.autoSellGreys then
                    local maxQuality = GREY
                    if db.sellWhites then
                        maxQuality = WHITE
                    end

                    local itemsSold, totalCopper, soldItems = SellItems(maxQuality)

                    if itemsSold > 0 then
                        local qualityStr = QUALITY_NAMES[GREY]
                        if db.sellWhites then
                            qualityStr = QUALITY_NAMES[GREY] .. " + " .. QUALITY_NAMES[WHITE]
                        end
                        print("|cff88ccff[AruiQOL]|r Sold " .. itemsSold .. " items (" .. qualityStr .. ") for " .. FormatMoney(totalCopper))

                        if db.sellVerbose then
                            local show = math.min(#soldItems, 10)
                            for i = 1, show do
                                local item = soldItems[i]
                                local countStr = item.count > 1 and (" x" .. item.count) or ""
                                print("  |cffaaaaaa- |r" .. item.name .. countStr .. " " .. FormatMoney(item.value))
                            end
                            if #soldItems > 10 then
                                print("  |cffaaaaaa... and " .. (#soldItems - 10) .. " more|r")
                            end
                        end
                    end
                end
            end)
        end)
    end
end)
