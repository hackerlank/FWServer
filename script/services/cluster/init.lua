
local skynet = require "skynet"
require "skynet.manager"

local cluster 
local console 
local selfclukey


function g_cluster.init(watchdog)
	selfclukey = skynet.getenv("clusterKey")	-- 打开一个节点，必须是clustername.lua里面的一个key,默认打开本地的
	assert(selfclukey and selfclukey~="", "you must set \'clusterKey\' to config file!")
	cluster = skynet.uniqueservice("services/skynet/cluster")
	skynet.call(cluster, "lua", "init", "ret", watchdog, selfclukey, false)

	local isopen = skynet.getenv("open_console")
	if isopen and tonumber(isopen)==1 then --打开输入窗
		console = skynet.newservice("services/skynet/console")
		skynet.send(console, "lua", "open", "noret", cluster)
	end
end
function g_cluster.destroy()
    print("===cluster:destroy:begin===")
	if cluster then
		skynet.call(cluster, "lua", "close", "ret", selfclukey)
        skynet.kill(cluster)
	end
    if console then
		skynet.send(console, "lua", "close", "noret", cluster)
    end
	cluster = nil
	console = nil
    print("===cluster:destroy:end===")
end
---------------------------------------------------------------------------
---------------------------------------------------------------------------
function g_cluster.getselfkey()
	return selfclukey
end
function g_cluster.send(ckey, protTab)
	if cluster then
		skynet.send(cluster, "lua", "send", "noret", ckey, protTab)
	end
end

function g_cluster.sendself(protTab)
	if cluster then
		skynet.send(cluster, "lua", "send", "noret", selfclukey, protTab)
	end
end
