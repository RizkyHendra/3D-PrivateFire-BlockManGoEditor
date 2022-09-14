local entityMgr = {}
local cfg = Entity.GetCfg('myplugin/player1')

local blueSkinData = {
    clothes = 'armor_chest_blue',
    shoes = 'armor_foot_blue',
    hair = 'armor_head_blue',
    pants = 'armor_thigh_blue'
}

local redSkinData = {
    clothes = 'armor_chest_red',
    shoes = 'armor_foot_red',
    hair = 'armor_head_red',
    pants = 'armor_thigh_red'
}

function entityMgr.AddDebuff(player)
    player:setProp('moveSpeed', player:data('moveSpeed') * 0.7)
    local isRed = player:getTeam().id == 1
    local skinData = {
        flag = isRed and 'blue_flag' or 'red_flag'
    }
    player:changeSkin(skinData)
end

function entityMgr.RemoveDebuff(player)
    local skinData = {
        flag = ''
    }
    player:changeSkin(skinData)
    player:setProp('moveSpeed', player:data('moveSpeed'))
end

local function GetNumberData(player, name)
    local data = player:data(name)
    return type(data) == 'number' and data or 0
end

local function ClearCaptureFlagData(player)
    entityMgr.RemoveDebuff(player)
    player:setData('flagIndex', nil)
    PackageHandlers:SendToClient(player, "ShowOrCloseGuide")
end

function entityMgr.InitPlayerData(player)
    ClearCaptureFlagData(player)
    player:setData('handFlagTime', 0)
    player:setData('startCaptureFlagTime', nil)
    player:setData('captureFlagSum', 0)
    entityMgr.StopCaptureFlagTimer(player)
end

function entityMgr.AddHandFlagTime(player)
    local startCaptureFlagTime = player:data('startCaptureFlagTime')
    if type(startCaptureFlagTime) ~= 'number' then
        return
    end
    local now = Game.Time

    local handFlagTime = GetNumberData(player, 'handFlagTime')
    handFlagTime = handFlagTime + (now - startCaptureFlagTime)
    player:setData('handFlagTime', handFlagTime)
    player:setData('startCaptureFlagTime', nil)
end

function entityMgr.CaptureFlag(player)
    local captureFlagSum = GetNumberData(player, 'captureFlagSum')
    player:setData('captureFlagSum', captureFlagSum + 1)
end

function entityMgr.HandlerLayFlag(player)
    entityMgr.AddHandFlagTime(player)
    entityMgr.RemoveDebuff(player)
    entityMgr.CaptureFlag(player)          --Player Capture the Flag successfully processed data
end

function entityMgr.StopCaptureFlagTimer(player)
    local captureFlagTimer = player:data('captureFlagTimer')
    if captureFlagTimer.Delay then
        captureFlagTimer:Stop()
        player:setData('captureFlagTimer', nil)
    end
end

function entityMgr.GetAllPlayerCaptureFlagData(playerList)
    local redRankData = {}
    local blueRankData = {}
    local redHandFlagTime, blueHandFlagTime = 0, 0
    local redCaptureSum, blueCaptureSum = 0, 0
    for id, player in pairs(playerList) do
        if player and player:isValid() then
            entityMgr.AddHandFlagTime(player)
            local captureFlagSum = GetNumberData(player, 'captureFlagSum')
            local handFlagTime = GetNumberData(player, 'handFlagTime')
            local isRed = player:getTeam().id == 1
            local rankData = isRed and redRankData or blueRankData
            redHandFlagTime = isRed and redHandFlagTime + handFlagTime or redHandFlagTime
            blueHandFlagTime = isRed and blueHandFlagTime or blueHandFlagTime + handFlagTime
            redCaptureSum = isRed and redCaptureSum + captureFlagSum or redCaptureSum
            blueCaptureSum = isRed and blueCaptureSum or blueCaptureSum + captureFlagSum

            handFlagTime = string.format("%.2f", handFlagTime / 20)
            table.insert(rankData, { CaptureFlagSum = captureFlagSum, HandFlagTime = handFlagTime, Name = player.name })
        end
    end
    table.sort(redRankData, function(data1, data2)
        if data1.captureFlagSum > data2.captureFlagSum or
                data1.captureFlagSum == data2.captureFlagSum and
                        data1.handFlagTime > data2.handFlagTime then
            return true
        end
    end)
    table.sort(blueRankData, function(data1, data2)
        if data1.captureFlagSum > data2.captureFlagSum or
                data1.captureFlagSum == data2.captureFlagSum and
                        data1.handFlagTime > data2.handFlagTime then
            return true
        end
    end)
    local victoryTeamID
    if (redCaptureSum > blueCaptureSum
            or redCaptureSum == blueCaptureSum
            and redHandFlagTime > blueHandFlagTime) or #blueRankData == 0 then
        victoryTeamID = 1
    else
        victoryTeamID = 2
    end
    return redRankData, blueRankData, victoryTeamID
end

function entityMgr.JoinTeam(team,player)
    team:joinEntity(player)
    local skinData = team.id == 1 and redSkinData or blueSkinData
    player:changeSkin(skinData)
end

function entityMgr.LeaveTeam(team,player)
    team:leaveEntity(player)
end


Trigger.RegisterHandler(cfg, "ENTITY_DIE", function(context)
    local player = context.obj1
    if type(player:data('flagIndex')) == 'number' then
        entityMgr.StopCaptureFlagTimer(player)
        local bindableEvent = Event:GetEvent("CreateFlagInOutside")
        bindableEvent:Emit(player)
        entityMgr.AddHandFlagTime(player)
        ClearCaptureFlagData(player)
    end
end)

Trigger.RegisterHandler(cfg, "ENTITY_ENTER", function(context)
    local player = context.obj1
    local defaultMoveSpeed = player:prop('moveSpeed')
    player:setData('moveSpeed', defaultMoveSpeed)
    local bindableEvent = Event:GetEvent("OnPlayerEnter")
    bindableEvent:Emit(player)
end)

Trigger.RegisterHandler(cfg, "ENTITY_LEAVE", function(context)
    local player = context.obj1
    local bindableEvent = Event:GetEvent("OnPlayerExit")
    bindableEvent:Emit(player.objID)
end)

return entityMgr