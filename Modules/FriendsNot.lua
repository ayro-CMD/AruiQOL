-- ============================================================
-- Arui QOL - Friends Notifications Module
-- Wrapped in pcall for safety on servers without BN features
-- ============================================================

local ok, err = pcall(function()
    local gmatch = string.gmatch
    local gsub = string.gsub

    local pattern1 = ERR_FRIEND_ONLINE_SS:gsub("%%s", "(%.+)"):gsub("%[", "%%["):gsub("%]","%%]");
    local pattern2 = ERR_FRIEND_OFFLINE_S:gsub("%%s", "(%.+)"):gsub("%[", "%%["):gsub("%]","%%]");

    function FriendsFrameBroadcastInput_OnEnterPressed(self)
        local broadcastText = self:GetText()
        if GetNumFriends() < 1 then return end
        if FriendsFrameFriendsScrollFrame and FriendsFrameFriendsScrollFrame.buttons then
            local numButtons = #FriendsFrameFriendsScrollFrame.buttons
            for i = 1, numButtons do
                local friend = _G["FriendsFrameFriendsScrollFrameButton" .. i]
                if friend and friend.id then
                    local buttonType = FRIENDS_BUTTON_TYPE_WOW
                    if buttonType and friend.buttonType == buttonType then
                        local name, level, class, zone, connected, status, note = GetFriendInfo(friend.id)
                        if connected then
                            SendChatMessage(broadcastText, "WHISPER", nil, name)
                        end
                    end
                end
            end
        end
        if FriendsFrameBroadcastInput_UpdateDisplay then
            FriendsFrameBroadcastInput_UpdateDisplay(self, broadcastText)
        end
    end

    if FriendsFrameBroadcastInput then
        FriendsFrameBroadcastInput:SetScript("OnEnterPressed", FriendsFrameBroadcastInput_OnEnterPressed)
        FriendsFrameBroadcastInput:Show()
        FriendsFrameBroadcastInput.Hide = function() end
    end

    if BNGetFriendInfoByID then
        -- Override to work with regular friend names
        local origBNGetFriendInfoByID = BNGetFriendInfoByID
        function BNGetFriendInfoByID(name)
            return nil, name, ""
        end
    end

    if BNToastFrameClickFrame and BNToastFrame then
        local function BNToastFrame_OnClick(self, btn, ...)
            local toastType = BNToastFrame.toastType
            local toastData = BNToastFrame.toastData
            local presenceID, givenName, surname
            if BNGetFriendInfoByID then
                presenceID, givenName, surname = BNGetFriendInfoByID(toastData)
            else
                givenName = toastData
            end
            if btn == "LeftButton" then
                if toastType == 1 then
                    BNToastFrame:Hide()
                    DropDownList1:Hide()
                    ChatFrame_SendTell(givenName)
                end
            elseif btn == "RightButton" then
                PlaySound("igMainMenuOptionCheckBoxOn")
                if FriendsFrame_ShowDropdown then
                    local name, level, class, area, connected = GetFriendInfo(givenName)
                    if name then
                        FriendsFrame_ShowDropdown(name, connected, nil, nil, nil, 1)
                    else
                        FriendsFrame_ShowDropdown(givenName, 1)
                    end
                end
            end
        end
        BNToastFrameClickFrame:RegisterForClicks("AnyUp", "AnyDown")
        BNToastFrameClickFrame:SetScript("OnClick", BNToastFrame_OnClick)
    end

    if BNToastFrame_AddToast then
        local BNetFrame = CreateFrame("Frame")
        BNetFrame:SetScript("OnEvent", function(self, event, arg1, ...)
            local name = arg1:gmatch(pattern1)()
            if name then
                BNToastFrame_AddToast(1, name)
                return
            end
            name = arg1:gmatch(pattern2)()
            if not name then return end
            BNToastFrame_AddToast(2, name)
        end)
        BNetFrame:RegisterEvent("CHAT_MSG_SYSTEM")
    end

    local function filter(self, event, arg1, ...)
        local name = arg1:gmatch(pattern1)() or arg1:gmatch(pattern2)()
        if name then return true end
    end
    ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", filter)
end)

if not ok then
    print("|cffff0000[FriendsNot]|r Error loading: " .. tostring(err))
end
