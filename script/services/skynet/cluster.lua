local skynet = require "skynet"
require "skynet.manager"
local cluster = require "cluster"

local SOCKET = {}
local clustertab = {}
local agenttab = {}
local CMD = {}
local selfclukey
local registerKey = "gamecluster"
local WATCHDOG
local function openAgent(clukey)
	skynet.error("New cluster client from : " .. clukey, WATCHDOG)
	agenttab[clukey] = skynet.newservice("services/skynet/agent")

	local conf = {
		client = clukey, 
		watchdog = WATCHDOG,
        iscluster = true,
	}

	skynet.call(agenttab[clukey], "lua", "startcluster", "ret", conf)
end
local function sendAgentMsg(clukey, msgData)
	local a = agenttab[clukey]
	if a and msgData then
		skynet.send(a, "lua", "recvcluster", "noret", msgData)
	end
end

function SOCKET.open(clukey)
	openAgent(clukey)
end

function SOCKET.data(clukey, msgData)
    sendAgentMsg(clukey, msgData)
end

function SOCKET.close(clukey)
    print("cluster:close ["..clukey.."], selfkey="..selfclukey)
    if clukey~=selfclukey then
        clustertab[clukey] = nil
        return
    end
	local a = agenttab[clukey]
	agenttab[clukey] = nil
	if a then
		skynet.send(a, "lua", "closecluster", "noret", clukey)
	end
    for key,asrc in pairs(clustertab) do
        skynet.send(asrc, "lua", "socket", "close", "noret", selfclukey)
    end
    clustertab = {}
end

------------------------------------------------------------------
------------------------------------------------------------------
function CMD.init(watchdog, clukey, breload)
	skynet.error(((breload and "reload") or "Open").." cluster key : " .. clukey, watchdog)
	if breload then
		cluster.reload(clukey)
	else
		cluster.open(clukey)
	end
	cluster.register(registerKey, skynet.self())

	WATCHDOG = watchdog
	selfclukey = clukey
	openAgent(clukey)
end

function CMD.send(clukey, msgData)
	if selfclukey==clukey then
        return sendAgentMsg(clukey, msgData)
	end
	local asrc = clustertab[clukey]
	if not asrc then
		local tt = cluster.query(clukey, registerKey)
		asrc = cluster.proxy(clukey, tt)	
		if asrc then 
			clustertab[clukey] = asrc
			skynet.call(asrc, "lua", "socket", "open", "ret", selfclukey)
		end
	end
	if not asrc then
		error("cluster ["..clukey.."] can not Open!")
	end
	skynet.send(asrc, "lua", "socket", "data", "noret", selfclukey, msgData)
end
function CMD.close()
	SOCKET.close(selfclukey)
end
function CMD.consoleInput(data)
	sendAgentMsg(selfclukey, data)
end
skynet.start(function()
	local dispatchfunc = function(session, source, cmd, subcmd, sockstate, ...)			
		if cmd=="socket" then
			local f = SOCKET[subcmd] 
		    if sockstate == "ret" then
			    skynet.ret(skynet.pack(f(...)))
		    elseif sockstate=="noret" then
			    f(...)
		    else
			    error("subcmd must be 'ret' or 'noret' to notice function to return or not return!")
		    end
		else
		   	local f = assert(CMD[cmd])
		    if subcmd == "ret" then
			    skynet.ret(skynet.pack(f(sockstate, ...)))
		    elseif subcmd=="noret" then
			    f(sockstate, ...)
		    else
			    error("subcmd must be 'ret' or 'noret' to notice function to return or not return!")
		    end
		end
	end
	skynet.dispatch("lua", dispatchfunc)
    skynet.error("start service")
end)
