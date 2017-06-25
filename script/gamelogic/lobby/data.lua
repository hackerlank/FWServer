
local gamelist = require("common.gameconfig.gamelist")
if not g_gamelobby.m_allUserRoom then
	g_gamelobby.m_allUserRoom = {}	--用户id对应的房间配置roominfo
end
if not g_gamelobby.m_allGameRoom then
	g_gamelobby.m_allGameRoom = {}	--游戏id对应所有该游戏房间配置roominfo
end

local data = {}
function data.init()
	
end
function data.addRoomInfo(gameid, roomid)	
	if not g_gamelobby.m_allGameRoom[gameid] then 
		g_gamelobby.m_allGameRoom[gameid] = {}
	end
	g_gamelobby.m_allGameRoom[gameid][roomid] = roominfo
end
function data.addUserRoomInfo(userid, roomid, roominfo)
	if not g_gamelobby.m_allUserRoom[userid] then
		g_gamelobby.m_allUserRoom[userid] = {}
	end
	g_gamelobby.m_allUserRoom[userid][roomid] = roominfo
end
function data.rmRoomInfo(userid, gameid, roomid)
	local toinfo = g_gamelobby.m_allGameRoom[gameid][roomid]
	g_gamelobby.m_allGameRoom[gameid][roomid] = nil
	g_gamelobby.m_allUserRoom[userid][roomid] = nil
	return toinfo
end
function data.rmAllRoomInfo()
	g_gamelobby.m_allGameRoom = {}
	g_gamelobby.m_allUserRoom = {}
end
function data.allGameRoomCallFunc(gameId, func, ...)
	if gameId then
		local roomtab = g_gamelobby.m_allGameRoom[gameId]
		if not roomtab then return end
		for _,roominfo in pairs(roomtab) do
			func(roominfo, ...)			
		end
	else
		for _,roomtab in pairs(g_gamelobby.m_allGameRoom) do
			for _,roominfo in pairs(roomtab) do
				func(roominfo, ...)			
			end
		end
	end
end
--------------------------------------------------------------------
--roomid为nil则返回该用户所有房间信息列表
function data.getRoomInfoByUserId(userid, roomid)
	if not roomid then
		local roomtab = {}
		for k,v in pairs(g_gamelobby.m_allUserRoom[userid]) do
			table.insert(roomtab, v)
		end
		return roomtab
	else
		return {g_gamelobby.m_allUserRoom[userid][roomid]}
	end
end
function data.getRoomInfoByRoomId(gameid, roomid)
	if not roomid then
		local roomtab = {}
		for k,v in pairs(g_gamelobby.m_allGameRoom[gameId]) do
			table.insert(roomtab, v)
		end
		return roomtab
	else
		return {g_gamelobby.m_allGameRoom[gameId][roomid]}
	end
end

return data