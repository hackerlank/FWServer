local skynet = require "skynet"

local broadcast = g_broadcast.m_broadCastHandler

function g_broadcast.init()
	broadcast = skynet.uniqueservice("services/skynet/broadcast")
    g_broadcast.m_broadCastHandler = broadcast
end

function g_broadcast.connected(fd, agent)
	skynet.send(broadcast, "lua", "connected", "noret", fd, agent)
	g_broadcast.enter(fd, G_BROADCAST_LOGIN_TAG)
end

function g_broadcast.disconnect(fd)
	skynet.send(broadcast, "lua", "disconnect", "noret", fd)
end

function g_broadcast.enter(fd, mapid)
	skynet.send(broadcast, "lua", "enter", "noret", fd, mapid)
end

function g_broadcast.broadcastUser(fd, msgtab)
	skynet.send(broadcast, "lua", "broadcast", "noret", fd, nil, nil, msgtab)
end

function g_broadcast.broadcastMap(mapid, msgtab) --对应的mapid
	skynet.send(broadcast, "lua", "broadcast", "noret", nil, mapid, nil, msgtab)
end

function g_broadcast.broadcastMinMap(minmapid, msgtab) --大于等于minmapid
	skynet.send(broadcast, "lua", "broadcast", "noret", nil, nil, minmapid, msgtab)
end
