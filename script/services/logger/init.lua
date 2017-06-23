
local skynet = require "skynet"

local loggersrv



function g_logger.init()
	local logpath = skynet.getenv("loggerpath") or "./"
	loggersrv = skynet.newservice("services/skynet/logger")
	skynet.call(loggersrv, "lua", "init", "ret", logpath)
end

function g_logger.logger(path, ...)	
	skynet.send(loggersrv, "lua", "save", "noret", path, ...)
end