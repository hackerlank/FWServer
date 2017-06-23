
local skynet = require("skynet")
local SOCKET = {}
local lobbyhandler
local gameId
local roomId
local roomhandler

function sendToLobby(userId, prottab) --toUserId不为nil，则发送给对应的玩家
	skynet.send(lobbyhandler, "lua", "notifyRoomData", gameId, roomId, userId, prottab)
end

function SOCKET.open(handler, srvpath, datatab) --new service and open
	lobbyhandler = handler
	gameId = datatab.gameId
	roomId = datatab.roomId
	roomhandler = require(srvpath).new(sendToLobby)
	assert(roomhandler, "")
end
function SOCKET.userEnter(seatNo, datatab)
	 roomhandler:onUserEnter(seatNo, datatab)
end
function SOCKET.userLeave(seatNo, datatab)
	 roomhandler:onUserLeave(seatNo, datatab)
end
function SOCKET.onSocketMessage(datatab)
	roomhandler:onSocketMessage(datatab)
end
function SOCKET.close(datatab) --recv lobby close service
	skynet.exit()
end


skynet.start(function()
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