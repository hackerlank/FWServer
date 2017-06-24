local skynet = require("skynet")
local REQlobbydata = require("gamelogic.lobby.data")
local REQroominfo = require("gamelogic.lobby.roominfo")
local lobbyhandler = g_gamelobby.m_watchdogHandler

function g_gamelobby.init(watchdog)
	g_gamelobby.m_watchdogHandler = watchdog
	lobbyhandler = g_gamelobby.m_watchdogHandler
end

--通过游戏名称新建一个房间
--ownerUserId为房主用户id,gameId为游戏id, datatab为附带数据
function g_gamelobby.newRoom(ownerUserId, gameId, roomId, datatab) 
	local handler = skynet.newservice("gamelogic.lobby.roomservice")

	local rinfo = REQroominfo.new(gameId, roomId)
	rinfo:setOwnerUserID(ownerUserId)
	rinfo:setMaxJuShu(datatab.maxJuShu)
	rinfo:setBaseScore(datatab.baseScore)
	rinfo:setBaseBeiLv(datatab.baseBeiLv)
	rinfo:setMaxPeople(datatab.maxPeople)
	rinfo:setSrvHandler(handler)

	REQlobbydata.addRoomInfo(rinfo)

	local srvpath = rinfo:getScriptSrvPath()
	skynet.send(handler, "lua", "open", lobbyhandler, srvpath, datatab)
	return rinfo
end

function g_gamelobby.sendDataRoom(gameid, roomid, eventtype, ...)
	local rinfotab = REQlobbydata.getRoomInfoByUserId(gameid, roomid)
	for _,rinfo in ipairs(rinfotab) do
		if rinfo:getSrvHandler() then
			skynet.send(rinfo:getSrvHandler(), "lua", eventtype, ...)
		end
	end
end
function g_gamelobby.sendGameRoom(gameId, datatab) --发送数据到所有gameName房间
	local function callroomfunc(rinfo, ...)
		if rinfo:getSrvHandler() then
			skynet.send(rinfo:getSrvHandler(), "lua", "data", ...)
		end
	end
	REQlobbydata.allGameRoomCallFunc(gameId, callroomfunc, datatab)
end

function g_gamelobby.closeAllRoom(datatab) --移除所有房间
	local function callroomfunc(rinfo, ...)
		if rinfo:getSrvHandler() then
			skynet.send(rinfo:getSrvHandler(), "lua", "close", ...)
		end
	end
	REQlobbydata.allGameRoomCallFunc(nil, callroomfunc, datatab)
	REQlobbydata.rmAllRoomInfo()
end
function g_gamelobby.closeRoom(gameid, roomid)  --移除对应的房间
	local rinfotab = REQlobbydata.getRoomInfoByRoomId(gameid, roomid)
	for _,rinfo in ipairs(rinfotab) do
		if rinfo:getSrvHandler() then
			skynet.call(rinfo:getSrvHandler(), "lua", "close", datatab)	
		end
	end
	REQlobbydata.rmRoomInfo(gameid, roomid)
end
-------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------
function g_gamelobby.sendRoomUserEnter(gameid, roomid, seatNo, datatab)
	g_gamelobby.sendDataRoom(userid, gameid, roomid, "userEnter", seatNo, datatab)
end
function g_gamelobby.sendRoomUserLeave(gameid, roomid, seatNo, datatab)
	g_gamelobby.sendDataRoom(userid, gameid, roomid, "userLeave", seatNo, datatab)
end
function g_gamelobby.sendRoomSocketMsg(gameid, roomid, datatab)
	g_gamelobby.sendDataRoom(userid, gameid, roomid, "onSocketMessage", datatab)
end