local skynet = require "skynet"

if not g_protocol.m_RegProtTab then g_protocol.m_RegProtTab = {} end
if not g_protocol.m_RegClusterTab then g_protocol.m_RegClusterTab = {} end
local registertab = g_protocol.m_RegProtTab
local regclustertab = g_protocol.m_RegClusterTab

function g_protocol.init()
end

function g_protocol.destroy()--关闭网络接口
    print("===protocol:destroy:begin===")
	registertab = {}
	regclustertab = {}
	g_protocol.m_closeSockFunc()
    print("===protocol:destroy:end===")
end
function g_protocol.sendProt(fd, mainId, assistId, dataTab)
	local protTab = FWCreateProtBuffer(mainId, assistId, dataTab)
	if protTab then
		if g_protocol.m_sendfunc then g_protocol.m_sendfunc(fd, protTab) end
	else
		error("sendProt error!")
	end
end
function g_protocol.sendErrcode(fd, code, attachdata)
	print("-------g_protocol.sendErrcode----", fd, code, attachdata)
	g_protocol.sendProt(fd, MID_Protocol_Errcode, FWGetErrNumErrcode(code), attachtab)
end
function g_protocol.closeSocket(fd)
	if not fd then return end
	g_protocol.m_closeSockFunc(fd)
end
---------------------------------------------------------------
---------------------------------------------------------------
function g_protocol.RegProtFunc(mainId, assistId, regfunc)
	if not registertab[mainId] then registertab[mainId] = {} end
	registertab[mainId][assistId] = regfunc
end
function g_protocol.CheckRegFunc(fd, recvDataTab)
	local mid, aid, datatab = FWAnalysisProtBuffer(recvDataTab)
	registertab[mid][aid](fd, datatab)
end

---------------------------------------------------------------
---------------------------------------------------------------
