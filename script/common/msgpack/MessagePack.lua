
local MessagePack

if _VERSION < "Lua 5.3" then
	MessagePack = require "common.msgpack.MessagePack51"
else
	MessagePack = require "common.msgpack.MessagePack53"
end

return MessagePack