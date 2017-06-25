--房间数据
local gamelist = require("common.gameconfig.gamelist")
local roominfo = {}

function roominfo.new(gameid, roomid)
	local handler = setmetatable({}, {__index=roominfo})
	handler:ctor(gameid, roomid)
	return handler
end
--如果不是按照局数来限定的游戏，则maxJuShu传入nil或-1
function roominfo:ctor(gameid, roomid) 
	self._roomID = roomid 	--房间id
	self._gameID = gameid 	--游戏id
	self._maxJuShu = -1 	 --最大局数
	self._curJuShu = 1		--当前局数，游戏没开始表示第一局，第一局打完就成为第二局
	self._baseScore = 0		--基本分,当前局数变化分数加上基本分就是变化分
	self._baseBeiLv = 1		--基本倍数，依据当前倍率往上递增，如胡牌赢了2倍，基本倍率为2，则赢了2+2倍
	self._userTab = {}	--已经进入房间的用户id列表
	self._ownerUserID = 0  --创建房间的用户id(房主)
	self._isPlaying = false	--是否正在玩, 一局结束到开始之间表示false，只有正在玩才为true
	self._maxPeople = -1  --游戏最大人数，若无限制人数，则按其他条件开始游戏
	self._roomPwd = ""		--房间密码
	self._config = {}	--创建房间的配置选项

	--只有服务器才有的
	self._srvHandler = nil	--服务句柄
	self._scriptSrvPath = "roomlogic/" .. gamelist[self._gameID].gameName .. "/init"
end
function roominfo:SaveToDataBase(dbroom)
	dbroom:set("gameId", self._gameID)
	dbroom:set("maxPlayer", self._roomID)
	dbroom:set("openNumPlayer", self.maxPlayer)
	dbroom:set("baseScore", self._baseScore)
	dbroom:set("baseBeiLv", self._baseBeiLv)
	dbroom:set("curJuShu", 0)
	dbroom:set("maxJuShu", self._maxJuShu)
	dbroom:set("ownUserId", self._ownerUserID)
	dbroom:set("roomPwd", self._roomPwd or "")
	dbroom:set("playertab", self._userTab)
	dbroom:set("config", self:getRoomConfig())
	dbroom:update()
end
function roominfo:getRoomID()
	return self._roomID
end
function roominfo:getGameID()
	return self._gameID
end
function roominfo:getSrvHandler()
	return self._srvHandler
end
function roominfo:setSrvHandler(handler)
	self._srvHandler = handler
end
function roominfo:getScriptSrvPath()
	return self._scriptSrvPath
end
function roominfo:getMaxJuShu()
	return self._maxJuShu
end
function roominfo:setMaxJuShu(num)
	self._maxJuShu = num
end
function roominfo:getCurJuShu()
	return self._curJuShu
end
function roominfo:getOwnerUserID()
	return self._ownerUserID
end
function roominfo:setOwnerUserID(userid)
	self._ownerUserID = userid
end
function roominfo:addUserID(userid)
	table.insert(self._userTab, userid)
	return #self._userTab
end
function roominfo:rmUserID(userid)
	if not userid then return end
	for i=1,self._maxPeople do
		if self._userTab[i] == userid then
			self._userTab[i] = nil
			return true
		end
	end
end

function roominfo:getUserIdTab()
	return self._userTab, #self._userTab
end
function roominfo:addOneJuShu() --增加一局
	self._curJuShu = self._curJuShu + 1
end
function roominfo:IsJushuFinish()  --是否局数已尽
	if self._maxJuShu>0 then
		return self._curJuShu>self._maxJuShu
	end
end
function roominfo:getBaseScore()
	return self._baseScore
end
function roominfo:setBaseScore(score)
	self._baseScore = score
end
function roominfo:getBaseBeiLv()
	return self._baseBeiLv
end
function roominfo:setBaseBeiLv(beilv)
	self._baseBeiLv = beilv
end
function roominfo:getMaxPeople()
	return self._maxPeople
end
function roominfo:setMaxPeople(num)
	self._maxPeople = num
end
function roominfo:IsPlaying()
	return self._isPlaying
end
function roominfo:setIsPlaying(isplay)
	self._isPlaying = isplay
end

function roominfo:setRoomConfig(configtab)
	self._config = {}
	if not configtab then return end 
	for k,v in pairs(configtab) do
		self._config[k] = v
	end
end
function roominfo:getRoomConfig()
	local tab = {}
	for k,v in pairs(self._config) do
		tab[k] = v
	end
	return tab
end
function roominfo:setRoomPwd(pwd)
	self._roomPwd = pwd
end
function roominfo:getRoomPwd()
	return self._roomPwd
end

return roominfo