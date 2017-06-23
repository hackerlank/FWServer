local crypt = require "crypt"
local msgpack = require "msgpack"

local cryptpack = {}

function cryptpack.encode(key, msg)
	if not key then
		key = msgpack.gethandshakekey()
	end
	local deskey = crypt.hashkey(key)
	return crypt.desencode(deskey, msg)
end

function cryptpack.decode(key, msg)
	if not key then
		key = msgpack.gethandshakekey()
	end
	local deskey = crypt.hashkey(key)
	return crypt.desdecode(deskey, msg)
end

function cryptpack.randomKey()
	return crypt.dhexchange(crypt.randomkey())
end

function cryptpack.getcheckpack()
	return msgpack.getcheckpack()
end


return cryptpack