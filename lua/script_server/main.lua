print('script_server:hello world')
Event:RegisterCustomEvent("OnPlayerEnter")
Event:RegisterCustomEvent("OnPlayerExit")
Event:RegisterCustomEvent("OnGameStart")
Event:RegisterCustomEvent("SetFlagSum")
Event:RegisterCustomEvent("GameOver")
Event:RegisterCustomEvent("CreateFlagInOutside")
require "script_server.gameStateMgr"
require "script_server.flagMgr"
require "script_server.entityMgr"
require "script_server.sevenLoginMgr"
