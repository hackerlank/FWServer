
if not g_gameuser.m_userToFdTab then g_gameuser.m_userToFdTab = {} end
if not g_gameuser.m_fdToUserIdTab then g_gameuser.m_fdToUserIdTab = {} end
if not g_gameuser.m_userInfoTab then g_gameuser.m_userInfoTab = {} end
local userToFdTab = g_gameuser.m_userToFdTab
local fdToUserIdTab = g_gameuser.m_fdToUserIdTab
local userInfoTab = g_gameuser.m_userInfoTab

--用户登录后，一定时间内无操作则让他重登陆
local removeUserTimer
local logoutUser

local function refreshUserHanlder(userId)
	local userdb = nil
	if userId then
		userdb = FGDBuser.query(userId)
	end
	if not userdb then
		userdb = FGDBuser.insert()
	end
	return userdb
end

function removeUserTimer(userId, bReplaceTimer)
	local usertab = g_gameuser.m_userInfoTab[userId]
	if usertab then
		if usertab.logouttimer then 
			g_timer.rmtimer(usertab.logouttimer) 
			usertab.logouttimer = nil
		end
	end
	if bReplaceTimer then
		local fd = g_gameuser.getSocketFdByUserId(userId)
		if fd then usertab.logouttimer = g_timer.addtimer(G_USER_DISCONNECT_TIME, logoutUser, fd) end
	end
end

function logoutUser(userId)
	local fd = g_gameuser.getSocketFdByUserId(userId)
	if fd then
		g_protocol.sendErrcode(fd, "M_LOGIN_REDO_LOGIN")
		g_protocol.closeSocket(fd)
	end
	removeUserTimer(userId)
	g_gameuser.m_userInfoTab[userId] = nil
end

function g_gameuser.onLoginUser(fd, userId, ischecklogin)
	-- if fdToUserIdTab[userId] then 
	-- 	local toReplaceFd = userToFdTab[userId]
	-- end
	userToFdTab[userId] = fd
	fdToUserIdTab[fd] = userId

	local userdb = refreshUserHanlder(userId)

	local rpTab = {}
	rpTab.userId = userId	  	--用户id
	rpTab.userName = userdb:get("userName")	--用户名
	rpTab.gold = userdb:get("gold")	--金币
	rpTab.diamond = userdb:get("diamond")	--钻石
	g_protocol.sendProt(fd, MID_Protocol_Login, ALogin_S2CLoginInfo, rpTab)
    print("====login success===", userId, userdb:get("userName"))
    
	local usertab = {}
	usertab.userId = userId
	usertab.fd = fd
	g_gameuser.m_userInfoTab[userId] = usertab
	g_gameuser.onProtTimer(fd)

	g_broadcast.enter(fd, G_BROADCAST_LOBBY_TAG) --进入大厅
	return true
end

function g_gameuser.onRegisterUser(userName)
	local userdb = refreshUserHanlder()
	userdb:set("userName", userName)
	userdb:set("gold", 1000)
	userdb:set("diamond", 999)
	userdb:update()
	local userId = userdb:get("userId")
	return userId
end

function g_gameuser.onLogoutUser(fd)
	local userId = fdToUserIdTab[fd]
	if userId then
		userToFdTab[userId] = nil
	end
	fdToUserIdTab[fd] = nil
	removeUserTimer(userId)
end

function g_gameuser.onProtTimer(fd)
	local userId = g_gameuser.getUserIdBySocketFd(fd)
	if not userId then return end
	removeUserTimer(userId)
end

function g_gameuser.getSocketFdByUserId(userId)
	return userToFdTab[userId]
end

function g_gameuser.getUserIdBySocketFd(fd)
	return fdToUserIdTab[fd]
end