
local gameConfig = {
	[1001] = {
		gameId = 1001,
		baseScore = 0,
		baseBeiLv = 1,
		jushuLimit = {[8]={[1003]=1}, [16] ={[1003]=2},}, --局数，8局1张房卡，16局2张
		maxPlayers = {2},	--最大人数2人，可添加3人
		jiesanleftTime = 150,	--解散房间倒计时
		gameName = "ErRenDDZ",
		desc = "二人斗地主",		
	},	

}


return gameConfig