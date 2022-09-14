local Btn_confirm = self:GetChildByName('Btn_confirm')
local Txt_info1 = self:GetChildByName('Txt_info1')
local Txt_info2 = self:GetChildByName('Txt_info2')
local Txt_info3 = self:GetChildByName('Txt_info3')

function self:Init()
  Txt_info1.Text = Lang:toText('LangKey_helpInfo1')
  Txt_info2.Text = Lang:toText('LangKey_helpInfo2')
  Txt_info3.Text = Lang:toText('LangKey_helpInfo3')
end

local event = Btn_confirm:GetEvent("OnTouchDown")
event:Bind(function()
  self:Destroy()
end)

self:Init()