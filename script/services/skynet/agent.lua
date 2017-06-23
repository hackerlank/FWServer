local skynet = require "skynet"

local locsrc = skynet.getenv("scriptpath") or "../script"
local tolocsrc = string.format("%s/?.lua;", locsrc)
package.path = tolocsrc..package.path
-------------------------------------------------------------------------

local socket = require "socket"
local msgpack = require "common.msgpack.pack"


local AGENT = {}
local client_fd
local client_addr
local msgpackObj
local WATCHDOG
local clusterkey
local btimeoutClose

local function send_package(sdata)
    if not sdata or not client_fd then 
        error("send data must not nil!")
    end
    local package, sz =  msgpackObj:packmsg(sdata) 
    print("-----send_package-----", client_fd, sz)
    socket.write(client_fd, package, sz)
end
local function unpack_msg(msg, sz)
    if msgpackObj then
        return msgpackObj:unpackmsg(msg, sz, client_fd)
    else
        skynet.fork(unpack_msg, msg, sz) --延迟调用
    end
    --]]
end
local function close_timeout()
    print("recv timeout, close socket!")
    btimeoutClose  = true
    if WATCHDOG then
        skynet.send(WATCHDOG, "lua", "socket", "close", client_fd)
    end
end

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
	unpack = unpack_msg,
	dispatch = function (_, _, msgtab) 
        print(">>>>>>>client>>>dispatch>>>>>>>>>>>", msgtab or "nil") 
        if msgtab then
        print(">>>>>>>client>>>dispatch>>>>>11>>>>>>", #msgtab) 
            for _,msg in ipairs(msgtab) do
                AGENT.recv(client_fd, msg)
            end
        end
	end
}
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
function AGENT.start(conf)
	WATCHDOG = conf.watchdog
	client_fd = conf.client
	client_addr = conf.addr
    if WATCHDOG then
        local sendfunc = function(msg) --sendfunc do not package
            if btimeoutClose then return end
            send_package(msg)
        end
        local finishfunc = function() --handshake end function
            if btimeoutClose then return end
	        skynet.send(WATCHDOG, "lua", "notifyConnected", "noret", client_fd, client_addr)
        end

        btimeoutClose  = nil
	    msgpackObj = msgpack.new(sendfunc, finishfunc)
    end
    print("-------AGENT.start----------", client_fd, client_addr, WATCHDOG )
end
function AGENT.opened()
    print("------AGENT.opened-----------")
    if WATCHDOG then
        msgpackObj:start()
        local ltime = 5 --can not recv repeat in 3 second,will close socket
        --skynet.timeout(ltime*100, close_timeout)
    end
end
function AGENT.disconnect()
	-- todo: do something before exit
    print("======AGENT.disconnect========")
    skynet.call(WATCHDOG, "lua", "notifyDisiconnected", "ret", client_fd)
    skynet.exit()
end

-----------------------------------------------------------------------
function AGENT.send(data)
    send_package(data)
end
function AGENT.recv(fd, msg)
	skynet.send(WATCHDOG, "lua", "notifyRecvData", "noret", fd, msg)
end
-----------------------------------------------------------------------
-----------------------------------------------------------------------
function AGENT.startcluster(conf)
    WATCHDOG = conf.watchdog
    clusterkey = conf.client
    skynet.send(WATCHDOG, "lua", "notifyOpenCluster", "noret", clusterkey)
end
function AGENT.recvcluster(msgData)
	skynet.send(WATCHDOG, "lua", "notifyRecvCluster","noret", clusterkey, msgData)
end
function AGENT.closecluster()
	skynet.call(WATCHDOG, "lua", "notifyCloseCluster", "ret", clusterkey)
    skynet.exit()
end

skynet.start(function()
    skynet.error("start service")
	skynet.dispatch("lua", function(session, source, cmd, subcmd, ...)
		local f = assert(AGENT[cmd])
		if subcmd == "ret" then
			skynet.ret(skynet.pack(f(...)))
		elseif subcmd=="noret" then
			f(...)
		else
			error("subcmd must be 'ret' or 'noret' to notice function to return or not return!")
		end
	end)
end)
