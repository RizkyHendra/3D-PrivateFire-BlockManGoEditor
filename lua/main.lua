if World.IsClient then
require "script_client.main"
else
require "script_server.main"
end
require "script_common.main"