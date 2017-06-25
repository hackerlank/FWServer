--所有表的定义均写在此处
local dbtable = {}

dbtable.account = {	--key值为表名称
	pkey = "accountName",	--主键名称
	auto = false,	--主键是否自增
	cache = false,	--缓存，是否启动服务器时候加载
	desc = "账户表",	--描述
	detail = {	--表结构
		accountName = "",	--账户名
		accountPwd = "",	--账户密码
		userId = 0,			--用户id
		loginip = "",		--上次登录ip
	},
}
dbtable.user = {	--表名称
	pkey = "userId",	--主键名称
	auto = true,	--主键是否自增，以当前主键配置值往上自增，如userId=1000，则新建一个用户则userId=1000
	cache = false,	--缓存，是否启动服务器时候加载
	desc = "用户表",	--描述
	detail = {	--表结构
		userId = 1000, --用户id, 
		userName = "",	--用户名
		gold = 0,	--金币
		diamond = 0,	--钻石
		viplevel = 0,	--vip等级
	},
}
dbtable.room = {
	pkey = "roomId",	--主键名称
	auto = false,	--主键是否自增
	cache = true,	--缓存，是否启动服务器时候加载所有数据
	desc = "房间表",	--描述
	detail = {	--表结构
		roomId = 1000, --房间id
		roomName = "",	--房间名
		roomPwd = 0,	--房间密码
		gameId = 0,	--房间所属游戏id
		maxPlayer = 0,	--房间最大进入人数
		openNumPlayer = 0, --房间开局的最大人数
		baseBeiLv = 0,	--基本倍率
		baseScore = 0, 	--基本分数
		curJuShu = 0,	--当前局数
		maxJuShu = 0, 	--最大局数
		ownUserId = 0,	--房主用户Id
		playertab = {},	--玩家数据表
		config = {},	--创建房间配置
	},
}
dbtable.item = {
	pkey = "userId",	--主键名称
	auto = false,	--主键是否自增，以当前主键配置值往上自增，如userId=1000，则新建一个用户则userId=1000
	cache = false,	--缓存，是否启动服务器时候加载
	desc = "用户表",	--描述
	detail = {	--表结构
		userId = 1000, --用户id, 
		allitem = {},	--用户物品, 表示是用json字符串存储
	},
}

---------------------------------------------------------------------------
return dbtable
