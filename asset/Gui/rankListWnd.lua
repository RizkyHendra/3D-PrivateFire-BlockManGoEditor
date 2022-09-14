print("startup ui")

local Txt_rankTip = self:GetChildByName('Txt_rankTip')
local Txt_nameTip = self:GetChildByName('Txt_nameTip')
local Txt_captureFlagTimeTip = self:GetChildByName('Txt_captureFlagTimeTip')
local Txt_flagSumTip = self:GetChildByName('Txt_flagSumTip')
local Btn_exitGame = self:GetChildByName('Btn_exitGame')
local Btn_replay = self:GetChildByName('Btn_replay')
local V_rankListLayout = self:GetChildByName('V_rankListLayout')
local Img_title = self:GetChildByName('Img_title')
local Wnd_info = V_rankListLayout:GetChildByName('Wnd_info'):Clone()
local rankIconPath = "gameres|asset/Texture/icon/Rank/%s.png"

function self:Init()
    Txt_rankTip.Text = Lang:toText({ 'LangKey_rankTip' })
    Txt_nameTip.Text = Lang:toText({ 'LangKey_nameTip' })
    Txt_captureFlagTimeTip.Text = Lang:toText({ 'LangKey_captureFlagTimeTip' })
    Txt_flagSumTip.Text = Lang:toText({ 'LangKey_flagSumTip' })
    Btn_exitGame.Txt_info.Text = Lang:toText({ 'LangKey_exitGame' })
    Btn_replay.Txt_info.Text = Lang:toText({ 'LangKey_rePlay' })
end

function self:SetRankData(packet)
    local rankList = packet.RankData
    V_rankListLayout:DestroyAllChildren()
    for i, info in ipairs(rankList) do
        local teamInfo = Wnd_info:Clone()
        V_rankListLayout:AddChild(teamInfo)
        teamInfo:GetChildByName('Txt_rank').Text = i
        teamInfo:GetChildByName('Txt_name').Text = info.Name
        teamInfo:GetChildByName('Txt_captureFlagTime').Text = info.HandFlagTime
        teamInfo:GetChildByName('Txt_flagSum').Text = info.CaptureFlagSum
        if info.Name == Me.name then
            teamInfo:GetChildByName('Img_bg').Visible = true
            teamInfo:GetChildByName('Txt_name').TextColor = Color3.new(0, 1, 1)
            teamInfo:GetChildByName('Txt_rank').TextColor = Color3.new(0, 1, 1)
            teamInfo:GetChildByName('Txt_captureFlagTime').TextColor = Color3.new(0, 1, 1)
            teamInfo:GetChildByName('Txt_flagSum').TextColor = Color3.new(0, 1, 1)
        end

        if i <= 3 then
            local Img_rankBG = teamInfo:GetChildByName('Img_rankBG')
            Img_rankBG.Visible = true
            Img_rankBG.Image = string.format(rankIconPath,i)
            teamInfo:GetChildByName('Txt_rank').Text = ''
        end
    end
    if packet.IsVictory then
        Img_title.Image = string.format(rankIconPath,'title_win')
        Img_title:GetChildByName('Img_result').Image = string.format(rankIconPath,'icon_win')
    end
end

local event = Btn_exitGame:GetEvent("OnClick")
event:Bind(function()
    CGame.instance:exitGame()
end)

local event = Btn_replay:GetEvent("OnClick")
event:Bind(function()
    PackageHandlers:SendToServer("PlayerEnter")
    UI.Root:GetChildByName('Gui/mainWnd'):InitTeamInfo()
    self:Destroy()
end)


self:Init()