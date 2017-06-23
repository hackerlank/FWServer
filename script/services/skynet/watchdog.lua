local skynet = require "skynet"
local script = require "script"
local WATCHDOG = {}
local SOCKET = {}
local agent = {}
local gate

local function close_agent(fd)
	local a = agent[fd]
	agent[fd] = nil
	if a then
        WATCHDOG.notifyDisiconnected(fd)
		skynet.call(gate, "lua", "kick", fd)
		-- disconnect never return
		skynet.send(a, "lua", "disconnect", "noret")
	end
end
local function sendData(fd, msgtab)
	local a = agent[fd]
	if a then
		skynet.send(a, "lua", "send", "noret", msgtab)
	end	
end
local function closeSocket(fd)
    skynet.error("watchdog.closeSocket", fd or "nil")
    if fd then
		close_agent(fd)
    else
		for fd,a in pairs(agent) do
			close_agent(fd)
		end
		agent = {}
	end
end
function SOCKET.open(fd, addr)
	skynet.error("New client from : " .. addr)
	local a = skynet.newservice("services/skynet/agent")
    agent[fd] = a
    
    local datatab = {
        client = fd, 
        addr = addr, 
        watchdog = skynet.self(),
    }
	skynet.call(a, "lua", "start", "ret", datatab)

	skynet.call(gate, "lua", "forward", fd, nil, a, addr) 
    print("=======WATCHDOG.open====")
end
function SOCKET.data(msg, sz)
    print("watchdog: ", msg, sz)
end
function SOCKET.opened(fd, addr)
	local a = agent[fd]
    if a then
	    skynet.send(a, "lua", "opened", "noret")
    end
end
function SOCKET.close(fd)
	close_agent(fd)
end

function SOCKET.error(fd, msg)
    print("watchdog socket error",fd, msg)
    close_agent(fd)
end

function SOCKET.warning(fd, size)
end
-----------------------------------------------------------------------
function WATCHDOG.start(conf)
	if conf then
		gate = skynet.newservice("services/skynet/gate")
		skynet.call(gate, "lua", "open", conf)
	end
	script.serverStart(skynet.self(), sendData, closeSocket)
end
-----------------------------------------------------------------------
function WATCHDOG.notifyConnected(fd, addr)
	script.notifyConnected(fd, agent[fd], addr)
end
function WATCHDOG.notifyRecvData(fd, msg)
	script.notifyRecvData(fd, msg)
end
function WATCHDOG.notifyDisiconnected(fd)
	script.notifyDisiconnected(fd)
end
-----------------------------------------------------------------------
function WATCHDOG.notifyOpenCluster(clukey)
	script.notifyOpenCluster(clukey)
end
function WATCHDOG.notifyCloseCluster(clukey)
	script.notifyCloseCluster(clukey)
end
function WATCHDOG.notifyRecvCluster(clukey, protTab)
	script.notifyRecvCluster(clukey, protTab)
end

function WATCHDOG.notifyRoomData(gameId, roomId, userId, prottab) --listen roomlogic data
	script.notifyRoomData(gameId, roomId, userId, prottab)
end

skynet.start(function()
	local dispatchfunc = function(session, source, cmd, subcmd, ...)		
		if cmd=="socket" then
			local f = SOCKET[subcmd] 
			f(...)
		else
		   	local f = assert(WATCHDOG[cmd])
		    if subcmd == "ret" then
			    skynet.ret(skynet.pack(f(...)))
		    elseif subcmd=="noret" then
			    f(...)
		    else
			    error("subcmd must be 'ret' or 'noret' to notice function to return or not return!")
		    end
		end
	end
	skynet.dispatch("lua", dispatchfunc)
    skynet.error("start service")
end)
