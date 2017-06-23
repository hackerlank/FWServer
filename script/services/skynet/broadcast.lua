local skynet = require "skynet"
local SOCKET = {}

local agentTab = {}
local fdMap = {}

local function sendAgentData(fd, msgtab)
	local a = agentTab[fd]
	if a then
		skynet.send(a, "lua", "send", "noret", msgtab)
	end	
end

function SOCKET.connected(fd, agent)
	agentTab[fd] = agent

	if not fdMap[fd] then fdMap[fd] = 0 end --防止断线重连, 断线重连仅仅替换agent
end
function SOCKET.disconnect(fd)
	agentTab[fd] = nil
	fdMap[fd] = nil
end

function SOCKET.enter(fd, mapid)
	fdMap[fd] = mapid
end

--mapid对应的mapid, minmapid对应最小mapid,只要大于等于minmapid的都被广播
function SOCKET.broadcast(fd, mapid, minmapid, msgtab)
	if fd then
		if fdMap[fd] == mapid and agent then
			sendAgentData(fd, msgtab)
		end
	elseif mapid or minmapid then
		for tofd, tomapid in pairs(fdMap) do
			if mapid and mapid==tomapid then
				sendAgentData(tofd, msgtab)
			elseif minmapid and mapid>=minmapid then
				sendAgentData(tofd, msgtab)
			end
		end
	end
end


skynet.start(function()
    skynet.error("start service")
	skynet.dispatch("lua", function(session, source, cmd, subcmd, ...)
		local f = assert(SOCKET[cmd])
		if subcmd == "ret" then
			skynet.ret(skynet.pack(f(...)))
		elseif subcmd=="noret" then
			f(...)
		else
			error("subcmd must be 'ret' or 'noret' to notice function to return or not return!")
		end
	end)
end)
