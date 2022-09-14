local entityMgr = require "script_server.entityMgr"

local STATE = {
    WAIT = 'wait',
    REDAYSTART = 'readyStart',
    START = 'start'
}

local rebirthPos = {
    Vector3.new(100, 26.5, -3), --red
    Vector3.new(100, 26.5, -116)  --blue
}

local minPlayerSum = 2  --Minimum number of people to start the game

local gameTotalTime = 10 * 60 --Game duration (seconds)

local gameReadyTime = 10 --Preparation time (seconds)

local curGameState = STATE.WAIT

local readyPlayerList = {}

local curMap

local gameStageMgr = {}
gameStageMgr.Timer = nil                 --游戏阶段循环计时器函数

local function SendServerHandlerToReadyPlayer(name, pakcet)
    for i, player in pairs(readyPlayerList) do
        if player and player:isValid() then
            PackageHandlers:SendToClient(player, name, pakcet)
        else
            readyPlayerList[i] = nil
        end
    end
end

local function GameStateChange(state)
    curGameState = state
    SendServerHandlerToReadyPlayer("PlayGlobalSound", { SoundName = curGameState })
end

--Balance the number of teams
local function BalaneceTeam(team1, team2)
    for i, player in pairs(team1:getEntityList()) do
        entityMgr.LeaveTeam(team1, player)
        entityMgr.JoinTeam(team2, player)
        player:setData('teamID', team2.id)
        return
    end
end

-- Compare the number of teams
local function CompareTeamPlayerNum()
    local team1 = Game.GetTeam(1, true)
    local team2 = Game.GetTeam(2, true)

    local count1 = team1.playerCount
    local count2 = team2.playerCount
    if math.abs(count1 - count2) > 1 then
        if count1 > count2 then
            BalaneceTeam(team1, team2)
        else
            BalaneceTeam(team2, team1)
        end
    end
end

local function AllPlayerExitTeam()
    for id, player in pairs(readyPlayerList) do
        local team = player:getTeam()
        entityMgr.LeaveTeam(team, player)
    end
end

function gameStageMgr.HandlerSwitchState(state, time, func)
    GameStateChange(state)
    if gameStageMgr.Timer then
        gameStageMgr.Timer:Stop()
    end

    if func then
        gameStageMgr.Time = time
        gameStageMgr.Timer = Timer.new(20, function()
            gameStageMgr.Time = gameStageMgr.Time - 1
            func(gameStageMgr.Time)
        end)
        gameStageMgr.Timer.Loop = true
        gameStageMgr.Timer:Start()
    end
end

function gameStageMgr.GameOver()
    local redRankData, blueRankData, victoryTeamID = entityMgr.GetAllPlayerCaptureFlagData(readyPlayerList)
    for i, player in pairs(readyPlayerList) do
        if player and player:isValid() then
            local teamID = player:getTeam().id
            local rankData = player:getTeam().id == 1 and redRankData or blueRankData
            PackageHandlers:SendToClient(player, "OpenRankWnd", { RankData = rankData, IsVictory = victoryTeamID == teamID })
        end
    end
    SendServerHandlerToReadyPlayer("PlayGlobalSound", { SoundName = 'finish' })
    AllPlayerExitTeam()

    readyPlayerList = {}
    gameStageMgr.HandlerSwitchState(STATE.WAIT)
    curMap = World:GetStaticMap("map001") --New map
end

local function SetRebirthPos(map, player)
    local id = player:getTeam().id
    local pos = rebirthPos[id]
    player:setRebirthPos(pos, map)
    player:serverRebirth()
end

function gameStageMgr.GameStart()
    curMap = World:CreateDynamicMap("map001", true) --New map
    for i, player in pairs(readyPlayerList) do
        --Start the game and transfer the map
        SetRebirthPos(curMap, player)
    end

    local bindableEvent = Event:GetEvent("OnGameStart")
    bindableEvent:Emit(curMap)

    gameStageMgr.HandlerSwitchState(STATE.START, gameTotalTime, function(time)
        if curMap and curMap:IsValid() then
            local timeInfo = {}
            timeInfo.Minute = math.floor(time / 60)
            timeInfo.Second = math.floor(time) % 60
            SendServerHandlerToReadyPlayer("SetTime", timeInfo)
            if time <= 0 then
                gameStageMgr.Timer.Loop = false
                gameStageMgr.GameOver()
            end
        end
    end)
end
function gameStageMgr.GameRedayStart()
    gameStageMgr.HandlerSwitchState(STATE.REDAYSTART, gameReadyTime, function(time)
        SendServerHandlerToReadyPlayer("SetTipText", { 'LangKey_gameStartCountdownTip', time })
        if time <= 0 then
            gameStageMgr.Timer.Loop = false
            gameStageMgr.GameStart()
        end
    end)
end

--player enter game
local function PlayerEnter(player)
    entityMgr.InitPlayerData(player)
    readyPlayerList[player.objID] = player --Add players to the ready list
    --Assign team
    local team = player:getTeam()
    local useless = team and entityMgr.LeaveTeam(team, player)
    local team1 = Game.GetTeam(1, true)
    local team2 = Game.GetTeam(2, true)

    if team1.playerCount >= team2.playerCount then
        entityMgr.JoinTeam(team2, player)
        player:setData('teamID', 1)
    else
        entityMgr.JoinTeam(team1, player)
        player:setData('teamID', 2)
    end

    local count = Lib.getTableSize(readyPlayerList)

    --Whether to meet the conditions to start the game
    if count >= minPlayerSum and curGameState == STATE.WAIT then
        gameStageMgr.GameRedayStart()
    elseif curGameState == STATE.START then
        SetRebirthPos(curMap, player)

        local bindableEvent = Event:GetEvent("SetFlagSum")
        bindableEvent:Emit(player)

    else
        PackageHandlers:SendToClient(player, "SetTipText", { 'LangKey_waitPlayerEnter' })
    end
    PackageHandlers:SendToClient(player, "PlayGlobalSound", { SoundName = curGameState })
    useless = curMap and player:setMap(curMap)

end

local bindableEvent = Event:GetEvent("OnPlayerEnter")
bindableEvent:Bind(PlayerEnter)

PackageHandlers:Receive("PlayerEnter", function(player, packet)
    PlayerEnter(player)
end)

-- player exit game
local function PlayerExit(objID)
    local player = readyPlayerList[objID]
    if player and player.isPlayer then
        readyPlayerList[objID] = nil     --Remove the player from the ready list
        if curGameState == STATE.START then
            local team1 = Game.GetTeam(1, true)
            local team2 = Game.GetTeam(2, true)

            if team1.playerCount == 0 or team2.playerCount == 0 then
                gameStageMgr.GameOver()
            end
        else
            CompareTeamPlayerNum()
        end

        local count = Lib.getTableSize(readyPlayerList)
        if count < minPlayerSum and curGameState == STATE.REDAYSTART then
            --Insufficient people cancel to start the game
            gameStageMgr.HandlerSwitchState(STATE.WAIT)
            SendServerHandlerToReadyPlayer("SetTipText", { 'LangKey_waitPlayerEnter' })
        end
    end
end

local bindableEvent = Event:GetEvent("OnPlayerExit")
bindableEvent:Bind(PlayerExit)

local bindableEvent = Event:GetEvent("GameOver")
bindableEvent:Bind(gameStageMgr.GameOver)
