local skynet = require "skynet"
local socket = require "socket"
local itoservice
local CMD = {}

local function split_cmdline(cmdline)
	local split = {}
	for i in string.gmatch(cmdline, "%S+") do
		table.insert(split,i)
	end
	return split
end

local function console_main_loop()
	local stdin = socket.stdin()
	socket.lock(stdin)
	while true do
		local cmdline = socket.readline(stdin, "\n")
		local split = split_cmdline(cmdline)
		local command = split[1]
		if itoservice and #split>0 and cmdline ~= "" then
			skynet.send(itoservice, "lua", "consoleInput", "noret", split)
		end
	end
	socket.unlock(stdin)
end

function CMD.open(toservice)
    skynet.error("open console", toservice, skynet.self())
	itoservice = toservice
end
function CMD.close()
    itoservice = nil
    skynet.exit()
end

skynet.start(function()
    skynet.error("start service")
	skynet.dispatch("lua", function(session, source, cmd, subcmd, ...)
		local f = assert(CMD[cmd])
		if subcmd == "ret" then
			skynet.ret(skynet.pack(f(...)))
		elseif subcmd=="noret" then
			f(...)
		else
			error("subcmd must be 'ret' or 'noret' to notice function to return or not return!")
		end
	end)
    skynet.fork(console_main_loop)
end)
