
local client = require("gamelogic.lobby.client")
--查询所有房间
local function QueryAllRoom(fd, protTab)
	client.S2CQueryAllRoom(fd)
end
--查询属于自己的桌子
local function QueryMyDesk(fd, protTab)
	client.S2CQueryMyDesk(fd)
end
--创建桌子
local function CreatDesk(fd, protTab)
	client.S2CCreatDesk(fd)
end
--请求解散桌子
local function ReqJieSanDesk(fd, protTab)
	client.S2CReqJieSanDesk(fd)
end
--请求进入桌子
local function ReqEnterDesk(fd, protTab)
	client.S2CReqEnterDesk(fd)
end
--请求离开桌子
local function ReqLeaveDesk(fd, protTab)
	client.S2CReqLeaveDesk(fd)
end
--发送给桌子内部消息
local function SpeakWithRoom(fd, protTab)
	client.S2CSpeakWithRoom(fd)
end
--监听到从桌子发到大厅来的消息,一般为本地房间服务发到大厅，若大厅不在此，则转发
function g_gamelobby.notifyRoomData(gameId, roomId, userId, prottab)
	client.RoomToLobbyProtocolData(gameId, roomId, userId, prottab)
end

g_protocol.RegProtFunc(MID_Protocol_Lobby, ALobby_C2SQueryAllRoom, QueryAllRoom)
g_protocol.RegProtFunc(MID_Protocol_Lobby, ALobby_C2SQueryMyDesk, QueryMyDesk)
g_protocol.RegProtFunc(MID_Protocol_Lobby, ALobby_C2SCreatDesk, CreatDesk)
g_protocol.RegProtFunc(MID_Protocol_Lobby, ALobby_C2SReqJieSanDesk, ReqJieSanDesk)
g_protocol.RegProtFunc(MID_Protocol_Lobby, ALobby_C2SReqEnterDesk, ReqEnterDesk)
g_protocol.RegProtFunc(MID_Protocol_Lobby, ALobby_C2SReqLeaveDesk, ReqLeaveDesk)
g_protocol.RegProtFunc(MID_Protocol_Lobby, ALobby_C2SSpeakWithRoom, SpeakWithRoom)
