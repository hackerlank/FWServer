
local REQgamelist = require("common.gameconfig.gamelist")
local REQroominfo = require("gamelogic.lobby.roominfo")
local REQlobbydata = require("gamelogic.lobby.data")
local client = {}

function client.RoomToLobbyProtocolData(gameId, roomId, userId, prottab)
	-- body
end
--查询所有房间
function client.S2CQueryAllRoom(fd, protTab)
	local userId = g_gameuser.getUserIdBySocketFd(fd)
	if not userId then 
		return g_protocol.sendErrcode(fd, "SYS_UNKNOW_ERROR") --系统错误
	end
	-- body
end
--查询属于自己的桌子
function client.S2CQueryMyDesk(fd, protTab)
	-- body
end
--创建桌子
function client.S2CCreatDesk(fd, protTab)
	local userId = g_gameuser.getUserIdBySocketFd(fd)
	if not userId or userId ~= protTab.userId then 
		return g_protocol.sendErrcode(fd, "SYS_UNKNOW_ERROR") --系统错误
	end
	if not protTab.gameId or not REQgamelist[protTab.gameId] then
		return g_protocol.sendErrcode(fd, "M_LOBBY_CREATEROOM_CONFIG_ERR") --配置错误
	end
	local gameConfigInfo = REQgamelist[protTab.gameId]
	--[[
	protTab.confg = {
		jushu=1, --局数
		maxPlayer = 1, --最大玩家
		baseScore = 0,  --基本分数，nil or 0
		baseBeiLv = 1,  --基本倍率， nil or 1
		... --其他自定义字段
	}
	--]]
	local jushuNum 
	local maxPlayer
	local bScore 
	local bBeiLv
	--第一步，查看客户端有木有发过配置过来，否则，使用内部最低档次配置数据
	if protTab.confg then
		jushuNum = protTab.confg.jushu
		maxPlayer = protTab.confg.maxPlayer
		bScore = protTab.confg.baseScore
		bBeiLv = protTab.confg.baseBeiLv
	end
	if not jushuNum then
		local minJuShu
		for num,_ in pairs(gameConfigInfo.jushuLimit) do
			if not jushu or num<minJuShu then minJuShu = num end
		end
		jushuNum = minJuShu
	end
	if not maxPlayer then maxPlayer = gameConfigInfo.maxPlayers[1] end
	if not bScore then bScore = gameConfigInfo.baseScore end
	if not bBeiLv then bBeiLv = gameConfigInfo.baseBeiLv end
	--第二步，检查配置数据是否在正确范围内
	local isLegalPlayers
	for _,cnum in ipairs(gameConfigInfo.maxPlayers) do
		if cnum==maxPlayer then
			isLegalPlayers = true
			break
		end
	end
	if not gameConfigInfo.jushuLimit[jushuNum] or not isLegalPlayers then
		return g_protocol.sendErrcode(fd, "M_LOBBY_CREATEROOM_CONFIG_ERR") --配置错误
	end
	--第三步，已经校验完数据，开始创建数据库记录
	local dbroom, roomid = g_database.createRoomRecord(userId)
	if not dbroom then
		return g_protocol.sendErrcode(fd, "M_LOBBY_CREATEROOM_TO_LIMITED") --房间数量上限
	end
	--最后创建房间，保存数据
	local roominfo = g_gamelobby.newRoom(userId, protTab.gameId, roomid)
	roominfo:setRoomConfig(protTab.confg or {})
	roominfo:setMaxJuShu(jushuNum)
	roominfo:setOwnerUserID(userId)
	roominfo:setBaseScore(bScore)
	roominfo:setBaseBeiLv(bBeiLv)
	roominfo:setIsPlaying(false)
	roominfo:setRoomPwd(protTab.pwd or "")

	REQlobbydata.addUserRoomInfo(userId, roomid, roominfo)
	roominfo:SaveToDataBase(dbroom)

	local rpTab = {}
	rpTab.roomOwer = roominfo:getOwnerUserID() 	--房主id
    rpTab.roomId = roominfo:getRoomID()	    --桌子号
    rpTab.gameId = roominfo:getGameID()
    rpTab.config = roominfo:getRoomConfig()
	g_protocol.sendProt(fd, MID_Protocol_Lobby, ALobby_S2CCreatDesk, rpTab)
end
--请求解散桌子,只有房主能解散,在当局游戏结束或者局数到了才能解散
function client.S2CReqJieSanDesk(fd, protTab)
	local userId = g_gameuser.getUserIdBySocketFd(fd)
	if not userId or userId ~= protTab.userId then 
		return g_protocol.sendErrcode(fd, "SYS_UNKNOW_ERROR") --系统错误
	end
	if not protTab.roomId or not protTab.gameId or 
		not REQgamelist[protTab.gameId] then
		return g_protocol.sendErrcode(fd, "SYS_UNKNOW_ERROR") --配置错误
	end
	local roominfo = REQlobbydata.getRoomInfoByRoomId(protTab.gameId, protTab.roomId)
	if roominfo:getOwnerUserID()~=userId then
		return g_protocol.sendErrcode(fd, "M_LOBBY_DELETEROOM_USER_ERR") --你不是房主
	end
	if roominfo:IsPlaying() then	
		return g_protocol.sendErrcode(fd, "M_LOBBY_DELETEROOM_PLAYING") --游戏已经开始
	end
	g_gamelobby.closeRoom(protTab.gameId, protTab.roomId)
	FGDBroom.remove(protTab.roomId)

	local rpTab = {}
    rpTab.roomId = protTab.roomId	    --桌子号
    rpTab.gameId = protTab.gameId
	g_protocol.sendProt(fd, MID_Protocol_Lobby, ALobby_S2CReqJieSanDesk, rpTab)
end
--请求进入桌子
function client.S2CReqEnterDesk(fd, protTab)
	local userId = g_gameuser.getUserIdBySocketFd(fd)
	if not userId or userId ~= protTab.userId then 
		return g_protocol.sendErrcode(fd, "SYS_UNKNOW_ERROR") --系统错误
	end
	if not protTab.roomId or not protTab.gameId or 
		not REQgamelist[protTab.gameId] then
		return g_protocol.sendErrcode(fd, "SYS_UNKNOW_ERROR") --配置错误
	end
	local roominfo = REQlobbydata.getRoomInfoByRoomId(protTab.gameId, protTab.roomId)
	local userTab,userCount = roominfo:getUserIdTab()
	local findSeatNo
	for i=1,userCount do
		if userTab[i]==userId then
			findSeatNo = i
			break
		end
	end
	if not findSeatNo then
		if roominfo:IsPlaying() then
			return g_protocol.sendErrcode(fd, "M_LOBBY_ENTERROOM_PLAYING") 
		end
		if userCount>=roominfo:getMaxPeople() then
			return g_protocol.sendErrcode(fd, "M_LOBBY_ENTERROOM_TO_LIMITED") 
		end
	end
	if not findSeatNo then
		findSeatNo = roominfo:addUserID(userId)
	end

	local rpTab = {}
    rpTab.roomId = protTab.gameId	    --桌子号
    rpTab.gameId = protTab.gameId
    rpTab.userId = userId
    rpTab.seatNo = findSeatNo
	for i=1,userCount do
		local toUserId = userTab[i]
		local tofd = g_gameuser.getSocketFdByUserId(toUserId)
		g_protocol.sendProt(tofd, MID_Protocol_Lobby, ALobby_S2CReqEnterDesk, rpTab)
	end
	g_gamelobby.sendRoomUserEnter(protTab.gameId, protTab.roomId, findSeatNo, rpTab)
end
--请求离开桌子
function client.S2CReqLeaveDesk(fd, protTab)
	local userId = g_gameuser.getUserIdBySocketFd(fd)
	if not userId or userId ~= protTab.userId then 
		return g_protocol.sendErrcode(fd, "SYS_UNKNOW_ERROR") --系统错误
	end
	if not protTab.roomId or not protTab.gameId or 
		not REQgamelist[protTab.gameId] then
		return g_protocol.sendErrcode(fd, "SYS_UNKNOW_ERROR") --配置错误
	end
	local roomtab = REQlobbydata.getRoomInfoByUserId(userId, protTab.roomId)
	if not roomtab[1] then
		return g_protocol.sendErrcode(fd, "SYS_UNKNOW_ERROR") --配置错误
	end
	local rpTab = g_protocol.newProt(g_protdef.Lobby_C2S_ReqLeaveDesk)
    rpTab.isSuccess = true
	for i=1,userCount do
		local toUserId = userTab[i]
		local tofd = g_gameuser.getSocketFdByUserId(toUserId)
		g_protocol.sendProt(tofd, MID_Protocol_Lobby, ALobby_S2CReqLeaveDesk,rpTab)
	end
	g_gamelobby.sendRoomUserLeave(protTab.gameId, protTab.roomId, findSeatNo)
	roomtab[1]:rmUserID(userId)
end
--发送给桌子内部消息
function client.S2CSpeakWithRoom(fd, protTab)
	local userId = g_gameuser.getUserIdBySocketFd(fd)
	g_gamelobby.sendRoomSocketMsg(protTab.gameId, protTab.roomId, protTab.data)
end



return client