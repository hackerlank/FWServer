local skynet = require "skynet"
require "skynet.manager"
local redis  = require "redis"
--local dbcache = require "services.db.dbcache"
local dbtable = require "config.dbtable"
local MessagePack = require "common.msgpack.MessagePack"
local lstring_gmatch = string.gmatch
local lconntab = {} 
local CMD = {}
local autoincr_key = "_cmy_AUTOINCRMENT_KEY"
local conconfig

-------------------------------------------
local function lredishandler(tname)
	local rhandler = lconntab[tname]
	if not rhandler then
		rhandler = redis.connect(conconfig)
		lconntab[tname] = rhandler
		--检测并设置自增初始值
		if dbtable[tname].auto then
			local keytab = rhandler:hmget(tname, autoincr_key)
	        mauto = keytab[1]
			if mauto then mauto = tonumber(mauto) end
	        if not mauto or mauto<=0 then 
				local prikey = dbtable[tname].pkey
				mauto = dbtable[tname].detail[prikey]
				rhandler:hmset(tname, autoincr_key, mauto)
			end
		end
	end
	return rhandler
end
local function lredisclose(tname)
	local rhandler = lconntab[tname]
	if not rhandler then return end
	rhandler:disconnect()
	lconntab[tname] = nil
end
local function lpackrecord(tname, recordtab, tokey)
	local prikey = dbtable[tname].pkey
	local detailTab = dbtable[tname].detail
	local fstr = MessagePack.pack(recordtab)
    skynet.error("-----lpackrecord-----", tname, tokey, fstr)
    local retkeyd = tokey
    if not tokey then retkeyd = recordtab[prikey] end
	return fstr, retkeyd
end
local function lunpackrecord(tname, recordstr)
    print("---lunpackrecord-------", tname, recordstr)
	local detailTab = dbtable[tname].detail

	local rtab = MessagePack.unpack(recordstr)
	for _,fname in ipairs(detailTab) do
        if not rtab[fname] then rtab[fname] = detailTab[fname] end
	end
	--dbcache.setRecord(tname, nil, rtab, true)
	return rtab
end
local function lautoincrement(tname)
	local rhandler = lconntab[tname]
	if not rhandler then return end

	local mauto
	if dbtable[tname].auto then
		mauto = rhandler:hincrby(tname, autoincr_key, 1)
		print("=======lautoincrement========", mauto)
	end
	assert(mauto, "the table not autoincrement!")
	return mauto
end 
-------------------------------------------
--[[
[tname..":desc"] = 
{
	--db/dbtable.lua里面的表
}
[tname..":"..rkey] = "field1 field2 field3 ..."--具体字段排列参照db/dbtable.lua里面的表
--]]

function CMD.query(tname, key)
	local rectab = {}
	local rhandler = lredishandler(tname)
    print("=---CMD.query------1----")
	if not key then 
		local resultTab = rhandler:hgetall(tname)
		for i=1,#resultTab, 2 do
			local tokey = resultTab[i]
			if tokey~=autoincr_key then
				local toval = resultTab[i+1]
				rectab[#rectab+1] = lunpackrecord(tname, toval)
			end
		end
		return rectab
	end
    print("=---CMD.query----11--2----",tname, key)
	local rettab = rhandler:hmget(tname, key)
    local recstr = rettab[1]
    print("=---CMD.query------2----", recstr)
	if not recstr or recstr=="" then return rectab end
	rectab[#rectab+1] = lunpackrecord(tname, recstr)
    print("=---CMD.query------3----")
	return rectab
end

function CMD.update(tname, rectab)
	if not tname or not rectab then return end

	local packstr, packkey = lpackrecord(tname, rectab)
	if not packstr or not packkey then return end
	local rhandler = lredishandler(tname)
	rhandler:hmset(tname, packkey, packstr)
	return true
end

function CMD.insert(tname, key)
	local rhandler = lredishandler(tname)
    if not key and dbtable[tname].auto then
	    return lautoincrement(tname)
    end
    local rectab = dbtable[tname].detail
	local packstr, packkey = lpackrecord(tname, rectab, key)
	rhandler:hmset(tname, packkey, packstr)
    return packkey
end
function CMD.remove(tname, key)
	if not key then return end
	local rhandler = lredishandler(tname)
	rhandler:hdel(tname, packkey)
end

function CMD.closeAll()
    skynet.error("dbredis.closeAll")
	for t,db in pairs(lconntab) do
		lredisclose(t)
	end
	lconntab = {}
end

function CMD.init(config)
    conconfig = config
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
end)

