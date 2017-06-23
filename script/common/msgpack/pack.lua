local cryptpack = require "common.msgpack.crypt"
local msgpack = require "msgpack"
local MessagePack = require "common.msgpack.MessagePack"
local isclient = 0 --客户端为1，服务器为0
local checknotip = "protbuf"
local nethandshakekey
local netcheckpackflag = "WTF\n" 
local filterqueue
local dispatch_msg

local pack = setmetatable({}, { __gc = function() msgpack.clear(filterqueue) end })
----------------------------------------------------------------
function pack.new(sendfunc, endfunc)
	local handle = setmetatable({}, {__index = pack})
	handle:init(sendfunc, endfunc)
	return handle
end
function pack:init(sendfunc, endfunc)
	print("nethandshakekey: >>>>>>>>>>>> ", nethandshakekey)
	print("netcheckpackflag: >>>>>>>>>>>> ", netcheckpackflag)
    self.m_sendfunc = sendfunc
    self.m_endfunc = endfunc
    --self:checkHandShake()
end
function pack:start()
    print("-----pack:start======")
	self.m_state = 1
	self.m_proto = ""
	if isclient==1 then 
		self:_sendhandshake(checknotip)
	elseif isclient==0 then
		self.m_proto = netcheckpackflag	 --表示如何打包解包, 服务器设置为"WTF\n"则加密，否则不加密
		self.m_ckey = cryptpack.randomKey() --无论是否加密，都声称加密key
	end
end
function pack:ishandshake()
	return self.m_state ~= 3
end
function pack:packmsg(msg)
    return self:_checkmsg(msg, nil, true)
end
function pack:unpackmsg(msg, sz, fd)
    print("======pack:unpackmsg======", msg,sz, fd, self.m_state)
    return self:dispatch(msgpack.filter(filterqueue, msg, sz, fd))
end
-------------------------------------------------------------
function pack:execute_msg(fd, msg, sz)
    local tomsg = self:_checkmsg(msg, sz, false)    
    print("-----pack:execute_msg---state---", tomsg or "nil", fd or "nil", self.m_state,self.m_proto)
    if self.m_state==3 then 
        return tomsg
    end 
    self:_recvhandshake(tomsg)
end
function dispatch_msg(obj,fd, msg, sz)
    print("===dispatch_msg====", obj, fd, msg, sz)
	return {obj:execute_msg(fd, msg, sz)}
end
local function dispatch_queue(obj)
	local fd, msg, sz = msgpack.pop(filterqueue)
	if fd then
		local rs = {}
		local r = dispatch_msg(obj, fd, msg, sz)
		if r then
			rs[#rs+1] = r
		end
		for fd, msg, sz in msgpack.pop, filterqueue do
			r = dispatch_msg(obj, fd, msg, sz)
			if r then
				rs[#rs+1] = r
			end
		end
		return rs
	end
end

local MSGFilter = {}
MSGFilter.data = dispatch_msg
MSGFilter.more = dispatch_queue

function pack:dispatch(q, type, ...)
	filterqueue = q
	if type then
		return MSGFilter[type](self,...)
	end
end
-------------------------------------------------------------
function pack:_sendhandshake(proto, state)
	local nowt = os.time()
	local tab = {
		state = state,
		proto = proto,
		isclient = isclient,
	}
	if state==3 and isclient==0 then
		tab.ckey = self.m_ckey
	end
	tab[nowt] = nowt
    --local sdata = self:packmsg(tab)
    print("=============pack:_sendhandshake====", tab)
    self.m_sendfunc(tab)
    return tab
end
function pack:_recvhandshake(msgtab)
    for k,v in pairs(msgtab) do
        print("----pack:_recvhandshake---1---", k,v)
    end
	if self.m_state==1 then
		if self:_isClient(msgtab) then	--对方是client
			if msgtab.proto==checknotip then
				self.m_state = 2
				self:_sendhandshake(checknotip, self.m_state)
				return 
			end
		elseif self:_isServer(msgtab) then --对方是server
			if msgtab.proto==checknotip then
				self.m_state = msgtab.state
				self:_sendhandshake(checknotip, self.m_state)
				return
			end
		end
	elseif self.m_state==2 then
		if self:_isClient(msgtab) then	--对方是client
			if msgtab.state==2 and msgtab.proto==checknotip then
				local state = 3
				self:_sendhandshake(self.m_proto, state)
				self.m_state = state
				if self.m_state==3 and self.m_endfunc then self.m_endfunc() end
				return
			end
		elseif self:_isServer(msgtab) then --对方是server
			self.m_state = msgtab.state
			self.m_proto = msgtab.proto
			self.m_ckey = msgtab.ckey
			if self.m_state==3 and self.m_endfunc then self.m_endfunc() end
			return 
		end
	end
	self.m_state = 1 	--若握手不成功则重置
	self.m_proto = ""
end
function pack:_isServer(tab)
	return tab.isclient==0 and isclient==1
end
function pack:_isClient(tab)
	return tab.isclient==1 and isclient==0
end
function pack:_checkmsg(data, size, bsend)
	--[[
	打包分三步：
	1、传入要发送的lua表或者字符串，使用json序列化
	2、加密，可有可无，看服务器控制 
	3、转换成二进制数据流
	--]]
	if bsend then
		local msg = MessagePack.pack(data)
        print("=======_checkmsg==send=11=", self.m_state)
        if self.m_state~=3  then
		    msg = cryptpack.encode(nil, msg)
		elseif self.m_proto==netcheckpackflag then
		    msg = cryptpack.encode(self.m_ckey, msg)
		end
		local udata, ulen = msgpack.pack(msg)
		local sdata = msgpack.tostring(udata, ulen)
        print("=======_checkmsg==send=22=", string.len(sdata))
        return sdata, string.len(sdata)
	else
		local msg = msgpack.tostring(data, size)
        print("=======_checkmsg==recv=11==", self.m_state, size)
        if self.m_state~=3  then
		    msg = cryptpack.decode(nil, msg)
		elseif self.m_proto==netcheckpackflag then
		    msg = cryptpack.decode(self.m_ckey, msg)
		end
        print("=======_checkmsg==recv=22==")
		return MessagePack.unpack(msg)
	end
end

return pack
