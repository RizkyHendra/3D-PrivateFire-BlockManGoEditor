print("startup ui")

--Reward data table
local giftDataTb = {
    { iconPath = 'gameres|asset/apple.png', sum = 1 },
    { iconPath = 'gameres|asset/apple.png', sum = 2 },
    { iconPath = 'gameres|asset/apple.png', sum = 3 },
    { iconPath = 'gameres|asset/apple.png', sum = 4 },
    { iconPath = 'gameres|asset/apple.png', sum = 5 },
    { iconPath = 'gameres|asset/apple.png', sum = 6 },
    { iconPath = 'gameres|asset/apple.png', sum = 7 },
}

local Btn_signIn = self:GetChildByName('Btn_signIn')
local Btn_close = self:GetChildByName('Btn_close')

function self:InitText()
    local teamDayData
    local teamGiftData

    self:GetChildByName('Txt_describe').Text = Lang:toText('LangKey_loginDescribe')
    self:GetChildByName('Img_titleBG').Txt_info.Text = Lang:toText('LangKey_sevenLoginTitle')
    Btn_signIn.Txt_info.Text = Lang:toText('LangKey_signIn')
    for i = 1, 7 do
        teamDayData = self:GetChildByName('Wnd_dayData' .. i)
        teamGiftData = giftDataTb[i]
        teamDayData:GetChildByName('Img_icon').Image = teamGiftData.iconPath
        teamDayData:GetChildByName('Txt_sum').Text = 'X' .. teamGiftData.sum
    end
end

self:InitText()

local btnHandle
function self:UpdateDayData(index, haveGot)
    local teamDayData
    local count = index
    for i = 1, count do
        teamDayData = self:GetChildByName('Wnd_dayData' .. i)
        teamDayData:GetChildByName('Img_haveGotIcon').Visible = true     --Less than login days to open the received icon
    end
    if not haveGot then
        teamDayData = self:GetChildByName('Wnd_dayData' .. count + 1)      --The number of login days plus one is the reward for this login
        teamDayData:GetChildByName('Img_selectIcon').Visible = true
    end
    Btn_signIn.Disabled = haveGot

    local event = Btn_signIn:GetEvent("OnClick")
    if btnHandle then
        btnHandle:Destroy()
    end

    btnHandle = event:Bind(function()
        PackageHandlers:SendToServer("GiveLoginGift")
        UI.Root:GetChildByName('Gui/mainWnd'):HideSevenLoginRedDot()
        teamDayData:GetChildByName('Img_haveGotIcon').Visible = true
        teamDayData:GetChildByName('Img_selectIcon').Visible = false
        Btn_signIn.Disabled = true
    end)
end

local event = Btn_close:GetEvent("OnClick")
event:Bind(function()
    self:Destroy()
end)

