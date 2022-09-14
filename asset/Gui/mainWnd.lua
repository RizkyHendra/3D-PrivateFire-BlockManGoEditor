print("startup ui")

local PB_captureFlag = self:GetChildByName('PB_captureFlag')
local Txt_timer = self:GetChildByName('Txt_timer')
local Txt_tip = self:GetChildByName('Txt_tip')
local Txt_redScore = self:GetChildByName('Txt_redScore')
local Txt_blueScore = self:GetChildByName('Txt_blueScore')
local Btn_sevenLogin = self:GetChildByName('Btn_sevenLogin')
local Img_redDot = self:GetChildByName('Img_redDot')
local DW_left = self:GetChildByName('DW_left')
local DW_info = self:GetChildByName('DW_info'):Clone()

local layerLangKey = {
    'LangKey_down',
    'LangKey_mid',
    'LangKey_up'
}

local function ZeroFill(timeInfo)
    for index, v in pairs(timeInfo or {}) do
        timeInfo[index] = v > 9 and v or ("0" .. v)
    end
end


function self:RefreshCaptureFlagProcess(totalTime, curTime)
    PB_captureFlag.Visible = true
    local progress = curTime / totalTime
    PB_captureFlag.Progress = progress
end

function self:CloseCaptureFlagProcess()
    PB_captureFlag.Visible = false
end

--txt is table
function self:SetTipText(txt)
    Txt_tip.Text = Lang:toText(txt)
end

function self:SetFlagSumTip(langKey,sum)
    local txt = Lang:toText({ langKey, sum })
    Txt_tip.Text = txt
end

function self:SetTime(timeInfo)
    ZeroFill(timeInfo)
    Txt_timer.Text = timeInfo and timeInfo.Minute .. ":" .. timeInfo.Second
end

function self:SetTeamScore(redScore, blueScore)
    Txt_redScore.Text = redScore
    Txt_blueScore.Text = blueScore
end

function self:InitTeamInfo()
    self:SetTeamScore(0, 0)
    self:SetFlagSumTip(0)
    self:SetTipText('LangKey_waitPlayerEnter')
end

function self:ShowSevenLoginRedDot()
    Img_redDot.Visible = true
end

function self:HideSevenLoginRedDot()
    Img_redDot.Visible = false
end

local event = Btn_sevenLogin:GetEvent("OnClick")
event:Bind(function()
    PackageHandlers:SendToServer("GetSevenLoginData")
end)

local infoWndList = {}
local infoLayoutInterval = 3
local infoHeight = 50

local infoWndMaxSum = 3
local intervalTime = 5    --移动时间（帧）

local totalLiveTime = 8  --消息存在总时间
local normalShowTime = 2  --正常显示时间
local function PosTween(wnd, posY, func)
    local detailPosY = -(infoHeight + infoLayoutInterval) / intervalTime
    local rate = 1
    local minPosY = posY
    local useless = wnd.PosTweenTimer and wnd.PosTweenTimer:Stop()
    wnd.PosTweenTimer = Timer.new(1,function()
        if not wnd:isAlive() then
            wnd.PosTweenTimer:Stop()
            return
        end

        local pos = wnd.Position
        print(minPosY,pos[2],detailPosY)
        pos[2][2] = pos[2][2] + (detailPosY * rate)
        pos[2][2] = math.max(minPosY, pos[2][2])

        if pos[2][2] < minPosY then
            rate = 0.8
        end
        wnd.Position = pos
        if minPosY >= pos[2][2] then
            func()
            wnd.PosTweenTimer:Stop()
        end
    end)
    wnd.PosTweenTimer.Loop = true
    wnd.PosTweenTimer:Start()
end

local function RemoveInfoWnd(wnd)
    if wnd:isAlive() then
        DW_left:RemoveChild(wnd)
        wnd:Destroy()
        table.remove(infoWndList, 1)
    end
end

local function AlphaTween(wnd)
    local time = (totalLiveTime - normalShowTime) * 20
    local rate = 1
    local intervalAlpha = 1 / time
    local timer
    timer = Timer.new(1,function()

        if not wnd:isAlive() then
            return
        end

        local alpha = tonumber(wnd.Alpha)
        alpha = alpha - (intervalAlpha * rate)

        alpha = math.max(0, alpha)
        if alpha < 0.7 then
            rate = 0.7
        end
        wnd.Alpha = tostring(alpha)
        if alpha == 0 then
            RemoveInfoWnd(wnd)
            timer:Stop()
        end
    end)
    timer.Loop = true
    timer:Start()
end

function self:AddInfoWnd(langKey,index)
    local teamWnd = DW_info:Clone()
    table.insert(infoWndList, teamWnd)
    DW_left:AddChild(teamWnd)

    local txt = Lang:toText({langKey,layerLangKey[index]})
    local Txt_width = teamWnd:GetChildByName('Txt_width')
    Txt_width.Text = txt

    local width = Txt_width.TextWidth
    Txt_width.AutoFrameSize = Enum.AutoFrameSize.Fixed
    Txt_width.Text = ''

    Txt_width.TextWidth = width
    teamWnd:GetChildByName('Txt_info').Text = txt

    local curSum = #infoWndList
    if curSum == infoWndMaxSum + 1 then
        RemoveInfoWnd(infoWndList[1])
        curSum = infoWndMaxSum
    end

    teamWnd.Visible = false
    for i, infoWnd in ipairs(infoWndList) do
        if i ~= curSum then
            local posY = -(curSum - i) * (infoHeight + infoLayoutInterval)
            PosTween(infoWnd, posY, function()
                if teamWnd:isAlive() then
                    teamWnd.Visible = true
                end
            end)
        end
    end
    if curSum == 1 then
        teamWnd.Visible = true
    end

    local timer
    timer = Timer.new(normalShowTime * 20, function()
        AlphaTween(teamWnd)
    end)
    timer:Start()
end

PackageHandlers:Receive("ShowSevenLoginRedDot", function(player, packet)
    self:ShowSevenLoginRedDot()
end)

PackageHandlers:Receive("RefreshCaptureFlagProcess", function(player, packet)
    self:RefreshCaptureFlagProcess(packet.TotalTime,packet.CurTime)
end)

PackageHandlers:Receive("CloseCaptureFlagProcess", function(player, packet)
    self:CloseCaptureFlagProcess()
end)

PackageHandlers:Receive("SetTipText", function(player, packet)
    self:SetTipText(packet)
end)

PackageHandlers:Receive("SetTime", function(player, packet)
    self:SetTime(packet)
end)

PackageHandlers:Receive("SetTeamScore", function(player, packet)
    self:SetTeamScore(packet.RedScore,packet.BlueScore)
end)

PackageHandlers:Receive("SetFlagSumTip", function(player, packet)
    self:SetFlagSumTip(packet.LangKey,packet.Sum)
end)

PackageHandlers:Receive("AddInfoWnd", function(player, packet)
    self:AddInfoWnd(packet.LangKey,packet.Index)
end)

function self:Init()
    DW_left:DestroyAllChildren()
    self:InitTeamInfo()
end

self:Init()
