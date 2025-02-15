local ItemTotals = CreateFrame("Frame")
local totalGuildBankTabs = 5 -- WORS currently using 5 tabs
local isScanning = false   -- Prevent overlapping scans

-- Saved Variables
ItemTotalsDB = ItemTotalsDB or {}
ItemTotalsDB.bankTotals = ItemTotalsDB.bankTotals or {}
ItemTotalsDB.bagTotals = ItemTotalsDB.bagTotals or {}
ItemTotalsDB.toolLeprechaun = ItemTotalsDB.toolLeprechaun or {}
ItemTotalsDB.equippedTotals = ItemTotalsDB.equippedTotals or {}
ItemTotalsDB.debugMode = ItemTotalsDB.debugMode or false

function debugPrint(message)
    if WORS_DropTrackerDB.debugMode then  -- Corrected the condition
        print("Debug: " .. message)
    end
end

local function formatOSRSNumber(value)
    local formattedValue
    local color
    if type(value) ~= "number" then
        return "|cffff0000Invalid Value|r"  -- Return red error if not a number
    end
    if value < 100000 then
        formattedValue = BreakUpLargeNumbers(tostring(value))  -- Just the number itself
        color = "|cffffff00"  -- Yellow
    elseif value >= 100000 and value <= 9999999 then
        formattedValue = BreakUpLargeNumbers(math.floor(value / 1000)) .. "K"  -- Format in thousands
        color = "|cffffffff"  -- White
    elseif value >= 10000000 then
        formattedValue = BreakUpLargeNumbers(math.floor(value / 1000000)) .. "M"  -- Format in millions
        color = "|cff00ff00"  -- Green
    end
    return color .. formattedValue .. "|r"
end

-- Function to scan all guild bank tabs (Player Bank)
local function ScanGuildBank()
    if isScanning then return end  -- Prevent overlapping scans
    isScanning = true
    wipe(ItemTotalsDB.bankTotals)  -- Clear previous guild bank data
    -- Scan guild bank tabs
    for tab = 1, totalGuildBankTabs do
        QueryGuildBankTab(tab)  -- Query each tab
    end
    -- Wait for the data to fully load and then scan
    C_Timer.After(0.5, function()
        for tab = 1, totalGuildBankTabs do
            for slot = 1, 98 do  -- 98 slots per tab
                local link = GetGuildBankItemLink(tab, slot)
                if link then
                    local itemName = GetItemInfo(link)
                    local _, itemCount = GetGuildBankItemInfo(tab, slot)
                    if itemName and itemCount then
                        ItemTotalsDB.bankTotals[itemName] = (ItemTotalsDB.bankTotals[itemName] or 0) + itemCount
                    end
                end
            end
        end
        isScanning = false  -- Allow future scans
    end)
end

-- Function to scan the player's bags (inventory)
local function ScanBags()
    wipe(ItemTotalsDB.bagTotals)  -- Clear previous inventory data
    for bag = 0, 4 do  -- Bags 0-4
        for slot = 1, GetContainerNumSlots(bag) do
            local link = GetContainerItemLink(bag, slot)
            if link then
                local itemName = GetItemInfo(link)
                local _, itemCount = GetContainerItemInfo(bag, slot)
                if itemName and itemCount then
                    ItemTotalsDB.bagTotals[itemName] = (ItemTotalsDB.bagTotals[itemName] or 0) + itemCount
                end
            end
        end
    end
end

local function ScanEquippedItems()
        wipe(ItemTotalsDB.equippedTotals)
    for slot = 1, 19 do
        local link = GetInventoryItemLink("player", slot)
        if link then
            local itemName = GetItemInfo(link)
            local itemCount = 1  -- equiped always 1 need test and prob find workaround for darts / knifes  
            if itemName then
                -- Store the count of equipped items
                ItemTotalsDB.equippedTotals[itemName] = (ItemTotalsDB.equippedTotals[itemName] or 0) + itemCount 
            end
        end
    end
end



-- Function to load saved data on login
local function LoadSavedData()
    if ItemTotalsDB.bankTotals then
        ItemTotalsDB.bankTotals = ItemTotalsDB.bankTotals
    end
    if ItemTotalsDB.bagTotals then
        ItemTotalsDB.bagTotals = ItemTotalsDB.bagTotals
    end
	if ItemTotalsDB.equippedTotals then
		ItemTotalsDB.equippedTotals = ItemTotalsDB.equippedTotals
	end
end


local function AddItemCountsToTooltip(tooltip)
    local itemName = tooltip:GetItem()
    if itemName then
        local guildBankCount = ItemTotalsDB.bankTotals[itemName] or 0
        local bagCount = ItemTotalsDB.bagTotals[itemName] or 0
        local equippedCount = ItemTotalsDB.equippedTotals[itemName] or 0
        local totalCount = guildBankCount + bagCount + equippedCount
        if totalCount > 0 then
            local leftText = "|cffffcc00Total:|r " .. formatOSRSNumber(totalCount) 
			local rightText = ""
            -- If holding Shift, show all values (including bank, bags, and equipped)
            if IsShiftKeyDown() then
				if totalCount < 100000 then
					leftText = "|cffffcc00Total:|r " .. "|cffffff00" .. BreakUpLargeNumbers(totalCount).."|r"
				elseif totalCount >= 100000 and totalCount <= 9999999 then
					leftText = "|cffffcc00Total:|r " .. "|cffffffff" .. BreakUpLargeNumbers(totalCount).."|r"
				elseif totalCount >= 10000000 then
					leftText = "|cffffcc00Total:|r " .. "|cff00ff00" .. BreakUpLargeNumbers(totalCount).."|r"
				end
				if guildBankCount > 0 then
                    rightText = rightText .. "|cffffcc00Bank:|r " .. formatOSRSNumber(guildBankCount)
                end
                if equippedCount > 0 then
                    if rightText ~= "" then
                        rightText = rightText .. " |cffffcc00Equipped:|r " .. formatOSRSNumber(equippedCount)
                    else
                        rightText = "|cffffcc00Equipped:|r " .. formatOSRSNumber(equippedCount)
                    end
                end
				if bagCount > 0 then
                    if rightText ~= "" then
                        rightText = rightText .. " |cffffcc00Bags:|r " .. formatOSRSNumber(bagCount)
                    else
                        rightText = "|cffffcc00Bags:|r " .. formatOSRSNumber(bagCount)
                    end
                end
            else                
                if bagCount > 0 then
                    rightText = "|cffffcc00Bags:|r " .. formatOSRSNumber(bagCount)
                end
            end
            -- Add the line with left and right text to the tooltip
            tooltip:AddDoubleLine(leftText, rightText, 1, 1, 1, 1, 1, 1)
            tooltip:Show()
        end
    end
end

-- Hook tooltips
GameTooltip:HookScript("OnTooltipSetItem", AddItemCountsToTooltip)
ItemRefTooltip:HookScript("OnTooltipSetItem", AddItemCountsToTooltip)
-- Hook events to track guild bank, player's bags, and equipped items
ItemTotals:RegisterEvent("GUILDBANKBAGSLOTS_CHANGED")  -- Track guild bank changes (deposit/withdraw)
ItemTotals:RegisterEvent("GUILDBANKFRAME_OPENED")  -- Track when the guild bank is opened
ItemTotals:RegisterEvent("BAG_UPDATE")  -- Track changes to player's inventory
ItemTotals:RegisterEvent("PLAYER_LOGIN")  -- Track login event
ItemTotals:RegisterEvent("EQUIPMENT_SLOT_CHANGED")  -- Track when equipped items change (equip/unequip)

ItemTotals:SetScript("OnEvent", function(self, event)
    if event == "GUILDBANKFRAME_OPENED" then
        ScanGuildBank()  -- Start scan when the guild bank is opened
    elseif event == "GUILDBANKBAGSLOTS_CHANGED" then
        ScanGuildBank()  -- Update scan when items are moved in/out of the guild bank
    elseif event == "BAG_UPDATE" then
        ScanBags()  -- Update scan when inventory changes
    elseif event == "EQUIPMENT_SLOT_CHANGED" then
        ScanEquippedItems()  -- Scan equipped items when the player equips or unequips an item
	elseif event == "PLAYER_LOGIN" then
        LoadSavedData()  -- Load saved data when logging in
        ScanEquippedItems()  -- Scan equipped items on login
    end
end)
