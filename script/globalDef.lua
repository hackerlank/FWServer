
G_GLOBAL_ALREADY_EXIT = false   --是否已经退出

--数据库操作时间
G_DB_CHECK_TIME 	= 10 * 60	--轮询间隔，单位秒
G_DB_UPDATE_TIME	= 10 * 60 	--写缓存时间，单位秒
G_DB_DELETE_TIME	= 15 * 60	--移除缓存时间，大于等于G_UPDATE_CACHE_MINUTE，且小于G_UPDATE_CACHE_MINUTE*2

--用户无操作断线时间
G_USER_DISCONNECT_TIME = 5*60 --5分钟

--广播标记, 这里记录连接登录/大厅的标记，其他游戏内部的标记放在游戏配置里面
G_BROADCAST_LOGIN_TAG = 0
G_BROADCAST_LOBBY_TAG = 1

G_DBREDIS_CONFIG =  {
    host = "127.0.0.1",
    port = 6379,
    db   = 0,
    auth = "nomogadbpwd"
}

