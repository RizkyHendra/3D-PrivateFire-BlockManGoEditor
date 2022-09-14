local giftDataTb = {
    { itemPath = 'myplugin/apple', sum = 1 },
    { itemPath = 'myplugin/apple', sum = 2 },
    { itemPath = 'myplugin/apple', sum = 3 },
    { itemPath = 'myplugin/apple', sum = 4 },
    { itemPath = 'myplugin/apple', sum = 5 },
    { itemPath = 'myplugin/apple', sum = 6 },
    { itemPath = 'myplugin/apple', sum = 7 },
}

local function JudgeCanGetGift(dateData)
    local time1 = tonumber(dateData.lastDay)
    local time2 = tonumber(Lib.getYearDayStr(os.time()))
    return time1 == time2                                --Incity means that no reward has been received today
end

local function JudgeCanUpdateWeekData(dateData, player)
    local time1 = tonumber(dateData.curtWeek)
    local time2 = tonumber(Lib.getYearWeekStr(os.time()))
    if time1 ~= time2 then                              --The incupities indicate that the date data is reset for different weeks
        dateData.curtWeek = time2                       --The number of update weeks
        dateData.totalLoginCount = 0                    --Reset the number of login days
        player:setValue("dateData", dateData)            --Update data
    end
end

local function UpdateDateData(dateData, player)
    dateData.totalLoginCount = dateData.totalLoginCount + 1  --The cumulative number of login days plus one
    dateData.lastDay = Lib.getYearDayStr(os.time())          --Record today's date
    player:setValue("dateData", dateData)                    --Save the data
end

--Get player data, update the seven-day login interface
PackageHandlers:Receive("GetSevenLoginData", function(player, packet)
    local dateData = player:getValue("dateData")
    PackageHandlers:SendToClient(player, 'OpenSevenLoginWnd', { Index = dateData.totalLoginCount, HaveGot = JudgeCanGetGift(dateData) })
end)

--Give out rewards
PackageHandlers:Receive("GiveLoginGift", function(player, packet)
    local dateData = player:getValue("dateData")

    local totalLoginCount = tonumber(dateData.totalLoginCount) + 1
    local curDayGift = giftDataTb[totalLoginCount]
    player:addItem(curDayGift.itemPath, curDayGift.sum, nil, "enter")
    UpdateDateData(dateData, player)
end)

local function CheckDateData(player)
    local dateData = player:getValue("dateData")
    if not JudgeCanGetGift(dateData) then
        JudgeCanUpdateWeekData(dateData, player)                              -- Check to see if it is the same week
        PackageHandlers:SendToClient(player, 'ShowSevenLoginRedDot')     -- Turn on the red dot prompt
    end
end

local bindableEvent = Event:GetEvent("OnPlayerEnter")
bindableEvent:Bind(CheckDateData)

--When the computing server is turned on, the deadline of today is used to refresh the seven-day login prompt
local hour = tonumber(os.date("%H"))
local minute = tonumber(os.date("%M"))
local second = tonumber(os.date("%S"))

local dayEndTime = (24 - hour - 1) * 60 * 60 * 20 + (60 - minute - 1) * 60 * 20 + (60 - second) * 20

local timer = Timer.new(dayEndTime, function()
    for i, player in pairs(Game.GetAllPlayers()) do
        CheckDateData(player)
    end
end)

timer:Start()
timer.Loop = true
timer.Delay = 24 * 60 * 60 * 20
