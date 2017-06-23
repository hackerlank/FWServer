
local errcodetab = {}
local function _lRegErrcode(var, code, errstr)
	local tab = {var, code, errstr}
	errcodetab[var] = tab
	errcodetab[code] = tab	
end
function FWGetErrDiscByCode(code) --通过错误码获取错误描述字符串
	return errcodetab[code][3]
end
function FWGetErrNumErrcode(var) --通过参数获取错误描述码
	return errcodetab[var][2]
end
-------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------
_lRegErrcode("SYS_UNKNOW_ERROR",						1,		"系统错误")--如“协议解析失败”、“没有定义的协议ID”等等
_lRegErrcode("SYS_VERSION",               				2, 		"版本过低，请更新客户端")

--登录模块
_lRegErrcode("M_LOGIN_ACC_EMPTY",					21,		"用户名不能为空")
_lRegErrcode("M_LOGIN_PWD_EMPTY",					22,		"密码不能为空")
_lRegErrcode("M_LOGIN_ACC_OR_PWD_ERROR",			23,		"用户名或密码错误")
_lRegErrcode("M_LOGIN_REPLACE",						24,		"被玩家替换下线")
_lRegErrcode("M_LOGIN_REDO_LOGIN",					25,		"离线时间太长，请重新登录")
_lRegErrcode("M_REGISTER_SUCCESS_ACC",				30,		"注册成功！")
_lRegErrcode("M_REGISTER_ALREADY_ACC",				31,		"用户名已经被注册！")
_lRegErrcode("M_REGISTER_LONGERR_ACC",				32,		"用户名或密码太短！(少于6个字符)")


_lRegErrcode("M_LOBBY_CREATEROOM_TO_LIMITED",				1001,	"创建房间失败，游戏容纳的房间数量已经达到上限！")
_lRegErrcode("M_LOBBY_CREATEROOM_CONFIG_ERR",				1002,	"创建房间失败，配置错误！")

_lRegErrcode("M_LOBBY_DELETEROOM_PLAYING",				1101,	"解散房间失败，游戏已经开始！")
_lRegErrcode("M_LOBBY_DELETEROOM_USER_ERR",				1102,	"解散房间失败，你不是房主！")

_lRegErrcode("M_LOBBY_ENTERROOM_TO_LIMITED",			1201,	"坐下失败，房间人数已满！")
_lRegErrcode("M_LOBBY_ENTERROOM_PLAYING",				1202,	"坐下失败，游戏已经开始！")
