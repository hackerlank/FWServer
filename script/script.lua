require "include"
local util = require "util.function"
local script = {}

function script.serverStart(watchdoghandler, sendfunc, closeFunc)	--起服
    assert(watchdoghandler, "watchdoghandler must not nil!")
    assert(sendfunc, "sendfunc must not nil!")
    assert(closeFunc, "closeAllFunc must not nil!")
    
	g_protocol.m_sendfunc = sendfunc
	g_protocol.m_closeSockFunc = closeFunc
	
	g_broadcast.init()
	g_logger.init()
	g_database.init()
	g_protocol.init()
	g_cluster.init(watchdoghandler)
    -- local obj = FGDBaccount.insert("fanfangyou")
    -- print("---dbaccount-new------", obj:get("accountName"))
    -- obj:set("accountPwd", "111111")
	g_logger.logger("script", "------------script.serverStart-----------")
end

function script.serverClose()	--关服
    print("===============serverClose==============")
  	--协议、分布式、数据库处理，
	g_protocol.destroy()	--关闭网络
    g_cluster.destroy()		--通知其他节点
	g_database.destroy() 	--数据库退出


	-- local function exitfunc()
	-- 	if not G_GLOBAL_ALREADY_EXIT then
	-- 		g_timer:addtimer(1, exitfunc)
	-- 	end
	-- 	os.exit()
	-- end
	-- G_GLOBAL_ALREADY_EXIT = true
	-- g_timer:addtimer(1, exitfunc)
end

function script.notifyConnected(fd, agent, addr)
	g_broadcast.connected(fd, agent)
	print("---------script.notifyConnected------", fd, addr)
	-- body
end
function script.notifyDisiconnected(fd)
	print("---------script.notifyDisiconnected------", fd)
	g_gameuser.onLogoutUser(fd)
	g_broadcast.disconnect(fd)
end
function script.notifyRecvData(fd, protTab)
	print("---------script.notifyRecvData------", fd)
    util.dump(protTab)
	g_protocol.CheckRegFunc(fd, protTab)
	g_gameuser.onProtTimer(fd)
end
---------------------------------------------------------------------------
function script.notifyOpenCluster(clukey)
	print("---------script.notifyOpenCluster------", clukey)
end
function script.notifyCloseCluster(clukey)
	print("---------script.notifyCloseCluster------", clukey)
end
function script.notifyRecvCluster(clukey, protTab)
	print("---script.notifyRecvCluster---", clukey,g_cluster.getselfkey(), table.unpack(protTab))
    --[[
    if g_cluster.getselfkey()~="mainlogic" then
        g_cluster.send("mainlogic", protTab)
    elseif clukey~="gmlogic" then
        g_cluster.send("gmlogic", protTab)
    end
    --]]
    --g_protocol.CheckRegClusterFunc(protTab[1], protTab)
    if protTab[1]=="exit" then
        script.serverClose()
    end
end
---------------------------------------------------------------------------
function script.notifyRoomData(gameId, roomId, userId, prottab) --监听逻辑游戏服发送过来的数据
	g_gamelobby.notifyRoomData(gameId, roomId, userId, prottab)
end
return script
