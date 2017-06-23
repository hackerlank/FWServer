local skynet = require "skynet"


skynet.start(function()
	print("Server start")
	--local console = skynet.newservice("console")
	local debug_port = skynet.getenv "debug_port"
	if debug_port then
		skynet.newservice("debug_console",debug_port)
	end

	local tcp_port = skynet.getenv "tcp_port"
	local max_client = skynet.getenv "max_client"
	local conf 
	if tcp_port then
		conf = {
			port = tonumber(tcp_port),
			maxclient = tonumber(max_client) or 64,
			nodelay = false, --不延迟发包(组合小包发出)
		}
	end
	local watchdog = skynet.newservice("services/skynet/watchdog")
	skynet.call(watchdog, "lua", "start", "ret", conf)

	print("listen on ", tcp_port, watchdog)
	
	skynet.exit()
end)
