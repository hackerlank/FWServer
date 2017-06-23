local skynet = require "skynet"
require "skynet.manager"
local ltable_unpack = table.unpack
local ltable_insert = table.insert

local LOGGER = {}
local loggerpath
local loggertab = {}

local function lwrite_log(filename,...)
	local texts = {...}
	local t = os.time()
	local text = os.date("[%H:%M:%S]",t)
    local filetext = os.date("@%Y-%m-%d",t) 
	local file = filename..filetext
	local tostr = ""
	for k,v in pairs(texts) do
		local str = string.format("%s  ",tostring(v))
		tostr = tostr .. str
	end
	text = text .. tostr .. "\n"
	local f = nil
	local parent_path = loggerpath..filename
	local abs_filename = string.format("%s/%s.log",parent_path, file)
	f,err = io.open(abs_filename, "a+")
	if not f then
		os.execute("mkdir -p " .. parent_path)	
		f,err = assert(io.open(abs_filename,"a+"))
	end
	f:write(text)
	f:flush()
end

local function llogger_loop()
	while true do
		if loggertab[1] then
			lwrite_log(ltable_unpack(loggertab[1]))
		end
	end
end

function LOGGER.save(path, ...)
	lwrite_log(path, ...)
	--ltable_insert(loggertab, {path, ...})
end

function LOGGER.init(path)
	loggerpath = path
end

skynet.start(function()
    skynet.error("start service")
	skynet.dispatch("lua", function(session, source, cmd, subcmd, ...)
		local f = assert(LOGGER[cmd])
		if subcmd == "ret" then
			skynet.ret(skynet.pack(f(...)))
		elseif subcmd=="noret" then
			f(...)
		else
			error("subcmd must be 'ret' or 'noret' to notice function to return or not return!")
		end
	end)
end)
