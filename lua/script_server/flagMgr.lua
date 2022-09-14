local entityMgr = require "script_server.entityMgr"

local cfgName = 'myplugin/flag'
local checkLayEntityCfgName = 'myplugin/checkLay'
local flagCfg = Entity.GetCfg(cfgName)
local checkLayEntityCfg = Entity.GetCfg(checkLayEntityCfgName)
local minPos = 13

local totalCaptureFlagTime = 5    --Capture the Flag Duration(seconds)

local flagResetTime = 15    --flag reset time(seconds)

local flagActor = {
    [1] = 'red.actor', --red
    [2] = 'blue.actor', --blue
}

--Red flag generation location point
local redFlagPos = {
    Vector3.new(55.88, 44.58, 21.03),
    Vector3.new(55.38, 57.2, 17.54),
    Vector3.new(55.38, 96.17, 19.35)
}

--Blue flag generation location point
local blueFlagPos = {
    Vector3.new(56, 44.64, -139.9),
    Vector3.new(55.72, 57.2, -137),
    Vector3.new(55.99, 96.17, -135.9)
}

--total number of flags
local totalFlagSum = #redFlagPos
local curFlagSum
local curTeamScore

local flagPosTb = {
    [1] = redFlagPos,
    [2] = blueFlagPos
}

--Placing a flag triggers entity location
local checkLayEntityPos = {
    [1] = Vector3.new(102.97, 26.88, -96.19), --blue
    [2] = Vector3.new(102.9, 26.73, -22.16)     --red
}

--red flag placement point
local redFlagLayPos = {
    Vector3.new(102.97, 26.88, -98.19),
    Vector3.new(102.97, 26.88, -96.19),
    Vector3.new(102.97, 26.88, -94.19)
}

--blue flag placement point
local blueFlagLayPos = {
    Vector3.new(102.9, 26.73, -24.16),
    Vector3.new(102.9, 26.73, -22.16),
    Vector3.new(102.9, 26.73, -20.16)
}

local flagLayPosTb = {
    [1] = redFlagLayPos,
    [2] = blueFlagLayPos
}

local function TeamSendServerHandler(team, name, packet)
    local playerList = team:getEntityList()
    for i, player in pairs(playerList) do
        PackageHandlers:SendToClient(player, name, packet)
    end
end

local function CreateFlagEntity(pos, map, teamID, index)
    local createParams = { cfgName = cfgName, pos = pos, map = map }
    local entity = EntityServer.Create(createParams)
    local actorName = flagActor[teamID]
    entity:changeActor(actorName)       --Set the flag's actor
    entity:setData('teamID', teamID)    --Set the flag's team ID
    entity:setData('index', index)      --Set the flag's position index
    return entity
end

local function CreateFlag(posTb, map, teamID)
    for i, pos in ipairs(posTb) do
        CreateFlagEntity(pos, map, teamID, i)
    end
end

local function CreateCheckLayEntity(map, teamID)
    local pos = checkLayEntityPos[teamID]
    local createParams = { cfgName = checkLayEntityCfgName, pos = pos, map = map }
    local entity = EntityServer.Create(createParams)
    entity:setData('teamID', teamID)
end

local function InitEntity(map)
    CreateFlag(redFlagPos, map, 1)
    CreateFlag(blueFlagPos, map, 2)
    CreateCheckLayEntity(map, 1)
    CreateCheckLayEntity(map, 2)
end

local function ShowFlagSumTip(teamID)
    local team = Game.GetTeam(teamID)
    local enemyId = ((teamID + 2) % 2) + 1

    local enmeyScore = curTeamScore[enemyId]
    local sum = totalFlagSum - curFlagSum[teamID]
    if enmeyScore ~= sum then
        TeamSendServerHandler(team, 'SetFlagSumTip', { LangKey = 'LangKey_flagTakenTip', Sum = sum - enmeyScore })
    else
        TeamSendServerHandler(team, 'SetFlagSumTip', { LangKey = 'LangKey_flagResidueSumTip', Sum = curFlagSum[teamID] })
    end

end

local function FlagSumChange(teamID, sum)
    curFlagSum[teamID] = curFlagSum[teamID] + sum

    ShowFlagSumTip(teamID)
end

local function TeamScoreChange(teamID, sum)
    curTeamScore[teamID] = curTeamScore[teamID] + sum

    PackageHandlers:SendToAllClients("SetTeamScore", { RedScore = curTeamScore[1], BlueScore = curTeamScore[2] })
    if curTeamScore[teamID] == totalFlagSum then
        local bindableEvent = Event:GetEvent("GameOver")
        bindableEvent:Emit()
    end
end

local function CaptureFlag(player, flag)
    if player and player:isValid() then
        local flagTeamID = flag:data('teamID')
        local pos = checkLayEntityPos[flagTeamID] + Vector3.new(0, 1, 0)
        local index = flag:data('index')
        FlagSumChange(flagTeamID, -1)

        TeamSendServerHandler(Game.GetTeam(flagTeamID), 'AddInfoWnd', { LangKey = 'LangKey_takenFlag', Index = index })
        TeamSendServerHandler(Game.GetTeam(flagTeamID), 'PlaySound', { SoundName = 'takenFlag' })

        entityMgr.AddDebuff(player)
        player:setData('flagIndex', index)           --Set data, the player holds the flag
        player:setData('startCaptureFlagTime', Game.Time)
        
        PackageHandlers:SendToClient(player, "CloseCaptureFlagProcess")
        PackageHandlers:SendToClient(player, "ShowOrCloseGuide", { GuidePos = pos })
        PackageHandlers:SendToClient(player, "PlaySound", { SoundName = 'pickFlag' })
        
        flag:destroy()
    end
end

local function CaptureFlagCountdown(player, flag)
    local time = 0
    local totalTime = totalCaptureFlagTime * 20
    PackageHandlers:SendToClient(player, "PlaySound", { SoundName = 'CaptureFlag' })
    local captureFlagTimer
    captureFlagTimer = Timer.new(1, function()
        if player and player:isValid() then
            time = time + 1
            --Update client progress bar step size
            PackageHandlers:SendToClient(player, "RefreshCaptureFlagProcess", { CurTime = time, TotalTime = totalTime })
            if time >= totalTime then
                CaptureFlag(player, flag)         --capture the flag success
                captureFlagTimer:Stop()
            end
        end
    end)
    captureFlagTimer:Start()
    captureFlagTimer.Loop = true
    player:setData('captureFlagTimer', captureFlagTimer)   --Cancel capture the flag timer
end

local bindableEvent = Event:GetEvent("OnGameStart")
bindableEvent:Bind(function(map)
    curFlagSum = {
        totalFlagSum,
        totalFlagSum
    }
    curTeamScore = {
        0,
        0
    }
    InitEntity(map)
    TeamSendServerHandler(Game.GetTeam(1), 'SetFlagSumTip', { LangKey = 'LangKey_flagResidueSumTip', Sum = curFlagSum[1] })
    TeamSendServerHandler(Game.GetTeam(2), 'SetFlagSumTip', { LangKey = 'LangKey_flagResidueSumTip', Sum = curFlagSum[1] })
end)

--Capture the flag, according to the state of the flag and the player team, there are different processing methods
Trigger.RegisterHandler(flagCfg, "ENTITY_TOUCH_ALL", function(context)
    local flag = context.obj1
    local player = context.obj2

    --The flag that has been placed at the end cannot be operated
    if flag:data('isLay') == true then
        return
    end

    local teamID = player:getTeam().id
    if player.isPlayer and teamID ~= flag:data('teamID') and type(player:data('flagIndex')) ~= 'number' then
        if flag:data('outside') == true then
            entityMgr.StopCaptureFlagTimer(player)
            
            --Flags dropped outside can be picked up directly
            CaptureFlag(player, flag)
        else
            CaptureFlagCountdown(player, flag)
        end
    end
end)

--Leave the capture flag area cancel the capture flag
Trigger.RegisterHandler(flagCfg, "ENTITY_APART", function(context)
    local flag = context.obj1
    local player = context.obj2

    --The flag that has been placed at the end cannot be operated
    if flag:data('isLay') == true then
        return
    end

    local teamID = player:getTeam().id
    if player.isPlayer and teamID ~= flag:data('teamID') then
        entityMgr.StopCaptureFlagTimer(player)
        
        PackageHandlers:SendToClient(player, "StopSound", { SoundName = 'captureFlag' })
        PackageHandlers:SendToClient(player, "CloseCaptureFlagProcess")
    end
end)

--Place the flag at the end point, and update the data, etc.
Trigger.RegisterHandler(checkLayEntityCfg, "ENTITY_TOUCH_ALL", function(context)
    local checkLayEntity = context.obj1
    local player = context.obj2

    local teamID = checkLayEntity:data('teamID')
    if player.isPlayer and player:getTeam().id ~= teamID and type(player:data('flagIndex')) == 'number' then
        local posTb = flagLayPosTb[teamID]
        local index = player:data('flagIndex')
        local pos = posTb[index]
        local entity = CreateFlagEntity(pos, player.map, teamID)   --Generate flag at target point
        entity:setData('isLay', true)           --set the state of that flag

        player:setData('flagIndex', nil)        --Changed stats, players no longer have flags

        entityMgr.HandlerLayFlag(player)
        
        TeamScoreChange(player:getTeam().id, 1) --Change team score
        ShowFlagSumTip(teamID)
        
        TeamSendServerHandler(Game.GetTeam(teamID), 'AddInfoWnd', { LangKey = 'LangKey_loseFlag', Index = index })
        TeamSendServerHandler(Game.GetTeam(teamID), 'PlaySound', { SoundName = 'loseFlag' })
        TeamSendServerHandler(player:getTeam(), 'PlaySound', { SoundName = 'addScore' })
        PackageHandlers:SendToClient(player, "ShowOrCloseGuide")
    end
end)

--The player holding the flag dies, the handling of the flag
local bindableEvent = Event:GetEvent("CreateFlagInOutside")
bindableEvent:Bind(function(player)
    local pos = player:getPosition()
    local enemyTeamID = player:getTeam().id == 1 and 2 or 1
    local index = player:data('flagIndex')
    local posTb = flagPosTb[enemyTeamID]
    local map = player.map
    if pos.y < minPos then
        --Fall into the void and die. The flag goes straight back to the starting point
        pos = posTb[index]
        CreateFlagEntity(pos, map, enemyTeamID, index)
        FlagSumChange(enemyTeamID, 1)
    else
        local entity = CreateFlagEntity(pos, map, enemyTeamID, index)
        entity:setData('outside', true)

        --After 15 seconds, no one picked up the flag, and the flag returned to the initial position
        local timer = Timer.new(flagResetTime * 20, function()
            if map and map:IsValid() and entity and entity:isValid() then
                pos = posTb[index]
                CreateFlagEntity(pos, map, enemyTeamID, index)
                FlagSumChange(enemyTeamID, 1)
                entity:destroy()
            end
        end)
        timer:Start()
    end
end)

local bindableEvent = Event:GetEvent("SetFlagSum")
bindableEvent:Bind(function(player)
    local teamID = player:getTeam().id
    PackageHandlers:SendToClient(player,'SetFlagSumTip', { LangKey = 'LangKey_flagResidueSumTip', Sum = curFlagSum[teamID]})
end)

