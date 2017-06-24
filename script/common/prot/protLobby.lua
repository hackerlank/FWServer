--大厅协议

ALobby_C2SQueryAllRoom = 10        --查询大厅房间信息
ALobby_C2SQueryMyDesk = 11         --玩家查询属于自己创建的桌子房间状态
ALobby_C2SCreatDesk = 12           --创建桌子房间
ALobby_C2SReqJieSanDesk = 13       --请求解散桌子房间
ALobby_C2SReqEnterDesk = 14        --请求进入房间
ALobby_C2SReqLeaveDesk = 15        --请求离开房间
ALobby_C2SSpeakWithRoom = 16       --和房间交互信息

ALobby_S2CQueryAllRoom = 200       --查询大厅房间信息
ALobby_S2CQueryMyDesk = 201         --玩家查询属于自己创建的桌子房间状态
ALobby_S2CCreatDesk = 202           --创建桌子房间
ALobby_S2CReqJieSanDesk = 203       --请求解散桌子房间
ALobby_S2CReqEnterDesk = 204        --请求进入房间
ALobby_S2CReqLeaveDesk = 205        --请求离开房间
ALobby_S2CSpeakWithRoom = 206       --和房间交互信息

-------------------------------------------------------------
local C2SQueryAllRoom_DTAB = { -- c_to_s
    gameId = 0,	--游戏名称
    roomId = 0,	--房间id， 例如初级房，高级房
}
local S2CQueryAllRoom_DTAB = { -- c_to_s
    roomTab = {}, 	--房间表，保存当前房间所有桌子
}
-------------------------------------------------------------
local C2SQueryMyDesk_DTAB = {
    userId = 0, --自己的userId
}
local S2CQueryMyDesk_DTAB = {
    deskId = 0, --桌子号
    userTab = {},   --已经有的玩家表格
    isFull = 0, --桌子是否已经满人了
    leftCount = -1, --这个桌子房间还剩多少局就会关闭，若没有局数限制则为-1
}
-------------------------------------------------------------
--创建桌子房间
local C2SCreatDesk_DTAB = {
    gameId = 0, --游戏名称
    userId = 0, --自己用户id
    pwd = "", --房间密码
    config = {},    --创建配置
}
local S2CCreatDesk_DTAB = {
    roomOwer = 0, 	--房主id
    roomId = 0,	    --桌子号
    gameId = 0, --游戏名称
    pwd = "", --房间密码
    roominfo = {},   --房间信息
    config = {},    --创建配置
}
-------------------------------------------------------------
--请求删除桌子房间
local C2SReqJieSanDesk_DTAB = {
    roomId = 0,	--桌子号
    gameId = 0, --游戏id
}
local S2CReqJieSanDesk_DTAB = {
    roomId = 0,	--桌子号
    gameId = 0, --游戏id
}

-------------------------------------------------------------
--请求进入房间
local C2SReqEnterDesk_DATB = {
    userId = 0, --自己的userId
    gameId = 0, --游戏id
    roomId = -1, --若为-1表示快速加入，否则进入对应的桌子号
}
local S2CReqEnterDesk_DATB = {
    userId = 0, --自己的userId
    gameId = 0, --游戏id
    roomId = -1, --若为-1表示快速加入，否则进入对应的桌子号
    seatNo = 0, --进入桌子后，所分配的座位号
}
-------------------------------------------------------------
--请求离开房间
local C2SReqLeaveDesk_DATB = {
    userId = 0, --自己的userId
    gameId = 0, --游戏id
    roomId = -1, --若为-1表示快速加入，否则进入对应的桌子号
}
local S2CReqLeaveDesk_DATB = {
    isSuccess = 0,  --成功返回1，失败返回0, 具体的错误code通过错误协议返回
}

-------------------------------------------------------------
--通过大厅和房间通信协议
local C2SSpeakWithRoom_DATB = {
    gameId = 0,
    roomId = 0,
    data = {},  --房间内部协议
}
local S2CSpeakWithRoom_DATB = {
    data = {},  --房间内部协议
}

