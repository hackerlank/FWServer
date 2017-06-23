--斗地主协议

AErRenDDZ_C2SEnterRoom = 10     --进入房间
AErRenDDZ_C2SPrepared  = 11     --准备
AErRenDDZ_C2SCallLandlord = 12  --叫地主
AErRenDDZ_C2SOutCard    = 13    --出牌
AErRenDDZ_C2SBuChu  = 14   --不出
AErRenDDZ_C2SSendCard  = 15  --发牌
AErRenDDZ_C2SGiveUp = 16   --认输
AErRenDDZ_C2STuoGuan = 17   --托管

AErRenDDZ_S2CEnterRoom = 200     --进入房间
AErRenDDZ_S2CPrepared  = 201     --准备
AErRenDDZ_S2CCallLandlord = 202  --叫地主
AErRenDDZ_S2COutCard    = 203    --出牌
AErRenDDZ_S2CBuChu  = 204   --不出
AErRenDDZ_S2CSendCard  = 205  --发牌
AErRenDDZ_S2CGiveUp = 206   --认输
AErRenDDZ_S2CTuoGuan = 207   --托管
AErRenDDZ_S2CGameFinish = 208    --游戏结束
-------------------------------------------------------------
--进入房间
local C2SEnterRoom_DTAB = {
    roomId = 0,
}
local S2CEnterRoom_DTAB = {
    playerId= "0",
    playerName= "ffy",
    playerGold= 0,
}
-------------------------------------------------------------
--请求准备
local C2SPrepared_DTAB = {
    seatNo= 0,
}
local S2CPrepared_DTAB = {
    seatNo= 0,
}
-------------------------------------------------------------
--叫地主
local C2SCallLandlord_DTAB = {
    seatNo= 0,
    score= 0,
}
local S2CCallLandlord_DTAB = {
    seatNo= 0,
    curSeatNo= 0,
    score= 0,
    bEnd= 0,
    curBeiShu= 0,
    landCount= 0,
}
-------------------------------------------------------------
--出牌
local C2SOutCard_DTAB = {
    seatNo= 0,
    cardType = 0,
    cardCount= 0,
    cardTab= "",  --1_1
}
local S2COutCard_DTAB = {
    cardCount= 0,
    cardTab= "",
    cardType = 0,
    curSeatNo= 0,
    outSeatNo= 0,
}
-------------------------------------------------------------
--不出
local C2SBuChu_DTAB = {
    seatNo= 0,
}
local S2CBuChu_DTAB = {
    BuChuSeatNo= 0,
    curSeatNo= 0,
}
-------------------------------------------------------------
--请求发牌
local C2SSendCard_DTAB = {
    seatNo= 0,
}
local S2CSendCard_DTAB = {
    cardCount= "", --"20_17_17"
    cardTab= "",   --"1_1"|"2_2"|"4_2"
    mingCard= 0,
}
-------------------------------------------------------------
--认输
local C2SGiveUp_DTAB = {
    seatNo= 0,
}
local S2CGiveUp_DTAB = {
    giveUpSeatNo= 0,
}
-------------------------------------------------------------
--托管
local C2STuoGuan_DTAB = {
    seatNo= 0,
}
local S2CTuoGuan_DTAB = {
    seatNo= 0,
}
-------------------------------------------------------------
--请求游戏结束
local S2CGameFinish_DTAB = {
    winScore= "",  --"100_100_-200"
    winSeatNo= 0,
    totalBeiShu= 0,
    dipaiBeiShu= 0,
    zhadanBeiShu= 0,
    springBeiShu= 0,  
}
