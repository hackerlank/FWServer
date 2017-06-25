--登录协议

ALogin_C2SSignIN = 10       --正常流程登陆
ALogin_C2SRegAccount = 11   --正常注册
ALogin_C2SCheckSignIN = 12  --断线重连时候发送账号密码验证
ALogin_C2SSignOut = 13      --主动登出

ALogin_S2CSignIN = 200
ALogin_S2CRegAccount = 201
ALogin_S2CLoginInfo = 202   --登录成功时候返回登陆数据
ALogin_S2CReplaceLogin = 203--被替换下线
ALogin_S2CReDoLogin = 204   --请重新登陆
ALogin_S2CCheckSignIN = 205  --断线重连时候发送账号密码验证
-------------------------------------------------------------
-------------------------------------------------------------
local C2SSignIN_DATAB = {
    loginName = "ffy", --登录用户名，base64加密成字符串
    loginPwd = "111111", --用户密码, md5
}
local S2CSignIN_DATAB = {
    loginIn = 0,    --成功返回1，失败返回0
}
local C2SRegAccount_DATAB = {
    accName = "",   --注册账户名，base64加密成字符串
    accPwd = "",    --注册密码，md5加密
    userName = "",  --用户名称
    desc = {},      --描述，如什么平台
}
local S2CRegAccount_DATAB = {
    isSuccess = 0,  --是否成功,或许还有其他状态
}

--登录成功时候返回值
local S2CLoginInfo_DATAB = {
    userId = 0,     --用户id
    userName = "",  --用户名
    gold = 0,   --金币
    diamond = 0,    --钻石
}

--被替换下线
local S2CReplaceLogin_DATAB = {
    rpUserId = 0,       --用户id
    rpUserName = "",    --用户名
}
