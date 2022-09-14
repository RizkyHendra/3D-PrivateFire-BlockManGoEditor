print('script_client:hello world')
require "script_client.audioMgr"
local mainWnd

local bindableEvent = Event:GetEvent("OnClientInitDone")
bindableEvent:Bind(function()
    mainWnd = UI:CreateGUIWindow("Gui/mainWnd")
    UI.Root:AddChild(mainWnd)
    UI.Root:AddChild(UI:CreateGUIWindow("Gui/helpWnd"))
end)

PackageHandlers:Receive("ShowOrCloseGuide", function(player, packet)
    local pos = packet and packet.GuidePos
    if pos then
        Me:setGuideTarget(pos, 'guide.png', 0.1)
    else
        Me:delGuideTarget()
    end
end)

PackageHandlers:Receive("OpenRankWnd", function(player, packet)
    local rankWnd = UI:CreateGUIWindow("Gui/rankListWnd")
    UI.Root:AddChild(rankWnd)
    rankWnd:SetRankData(packet)
    mainWnd:SetFlagSumTip()
end)

PackageHandlers:Receive("OpenSevenLoginWnd", function(player, packet)
    local sevenLoginWnd =UI:CreateGUIWindow("Gui/sevenLoginWnd")
    UI.Root:AddChild(sevenLoginWnd)
    sevenLoginWnd:UpdateDayData(packet.Index, packet.HaveGot)
end)


