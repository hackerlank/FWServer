
local skynet = require "skynet"
local dbtable = require("config.dbtable")
local dbcache = require("services.db.dbcache")

local baseG = _G
local command = {}
local dbfunc = {}
local numhandler = 1
local maxhandler
local lredishandler

function g_database.init(redismax)
	maxhandler = redismax or 4
	g_database.m_hredistab = {}
	for i=1,maxhandler do
		local handler = skynet.newservice("services/skynet/dbredis")
        skynet.call(handler, "lua", "init", "ret", G_DBREDIS_CONFIG)
        g_database.m_hredistab[i] = handler
	end
    --
    dbcache.init()
	for tname,tab in pairs(dbtable) do
		local thandle = dbfunc.checkdbFunc(tname, tab)
		if tab.cache then	--从数据库中拿出表中的所有数据
			thandle.query()
		end
	end
	--调整缓存更新时间
	local uptime = G_DB_UPDATE_TIME
	local deltime = G_DB_DELETE_TIME
	if deltime<=uptime+G_DB_CHECK_TIME+1 or deltime>uptime then deltime = math.floor(uptime * 1.5) end
	
	G_DB_UPDATE_TIME = uptime
	G_DB_DELETE_TIME = deltime

	--启动定时器
	dbfunc.timer_checkdb()

end
function g_database.destroy()
    skynet.error("===database:destroy:begin===")
	g_database.m_isdestroyAll = true
	dbcache.updateAll(function(tname, rkey)
		dbfunc.updateTab(tname, reckey, true)
	end)
	local redis = lredishandler()
	skynet.call(redis, "lua", "closeAll", "ret")
    skynet.error("===database:destroy:end===")
end
--创建一条房间记录
function g_database.createRoomRecord()
	while true do
		local toId = math.random(100000, 999999)
		if not FGDBroom.exist(toId) then
 			return FGDBroom.new(toId), toId
		end
	end
end
---------------------------------------------------------------------
---------------------------------------------------------------------
function dbfunc.timer_checkdb()
	if g_database.m_isdestroyAll then return end
	local tname,uptab, deltab = dbcache.checkCache()
	if tname then
		for _,rkey in ipairs(uptab) do
			dbfunc.updateTab(tname, reckey, false)
		end
		if not dbtable[tname].cache then
			for _,rkey in ipairs(deltab) do
				dbfunc.updateTab(tname, reckey, true)
			end
		end
	end
	g_timer.addtimer(G_DB_CHECK_TIME, dbfunc.timer_checkdb)
end
---------------------------------------------------------------------
---------------------------------------------------------------------
function lredishandler()
	numhandler = numhandler + 1
	local index = (numhandler % (maxhandler-1)) + 1
	return g_database.m_hredistab[index]
end

function dbfunc.new(tname, key, binsert)
	local instance = setmetatable({}, {__index = command})
    instance.class = cls
    instance:init(tname, key, binsert)
    return instance
end
function dbfunc.isExist(tname, reckey)
	if not tname or not reckey then return end
	local rectab = dbcache.getRecord(tname, reckey)
    if rectab then return true end 
	local redis = lredishandler()
	local rtab = skynet.call(redis, "lua", "query", "ret", tname, reckey)
    if rtab[1] then
    	for _, tab in ipairs(rtab) do
			dbcache.setRecord(tname, nil, tab, true)
    	end
        return true
    end
end
function dbfunc.updateTab(tname, reckey, bRmCache)
	local redis = lredishandler()
	local rectab = dbcache.getRecord(tname, reckey)
	if rectab then
		local ret = skynet.call(redis, "lua", "update", "ret", tname, rectab)
		if ret and bRmCache then
			dbcache.removeRecord(tname, reckey)
		end
	end
end
function dbfunc.remove(tname, reckey)
	if not reckey or not tname then return end
	skynet.call(redis, "lua", "remove", "ret", tname, reckey)
	dbcache.removeRecord(tname, reckey)
end
---------------------------------------------------------------------
function dbfunc.checkdbFunc(tname, dbtab)
	local tt = {}
	tt.query = function(key)    --query record
		local t = setmetatable({}, {__index=tt})
		t.db = dbfunc.new(tname, key, false)
		return t
	end
    tt.insert = function(key)   --insert record
		local t = setmetatable({}, {__index=tt})
		t.db = dbfunc.new(tname, key, true)
        return t
    end
    tt.remove = function(key)
    	dbfunc.remove(tname, key)
    end
	tt.exist = function(key)
		return dbfunc.isExist(tname, key)
	end
    tt.get = function(self, k)  --get field
	    local field = self.db:get(k)
	    assert(dbtab.detail[k], "db table not define the fieldname!")
		if not field then 
		    field = dbtab.detail[k]
		end
		return field
	end
	tt.set = function(self,k, fv)   --set field
	    local tov = fv
	    assert(dbtab.detail[k], "db table not define the fieldname!")
		if not fv then 
		    tov = dbtab.detail[k] 
		end
        print("--------db-set------", k, fv, tov)
		self.db:set(k, tov)
	end
	tt.update = function(self)
		self.db:update()
	end
    local tfuncname = "FGDB"..tname
    assert(not baseG[tfuncname], "global function must nil!")
	baseG[tfuncname] = tt
	return tt
end

---------------------------------------------------------------------
---------------------------------------------------------------------
function command:init(tname, key, binsert)
    print("-----command:init----11---", tname, key, binsert)
	local redis = lredishandler()
	self._tabname = tname
	self._recordKey = key
	local rectab = dbcache.getRecord(tname, key)
	if rectab then return end
    local ret 
    print("-----command:init--i1--22---", binsert)
    if not binsert then
	    ret = skynet.call(redis, "lua", "query", "ret", tname, key)
    else
        if not key and not dbtable[tname].auto then
            error("the autoincrement table must insert an not nil key!")
        end
	    ret = skynet.call(redis, "lua", "insert", "ret", tname, key)
    end
	if binsert then
		self._recordKey = ret
		local rectab = dbcache.setDefaultRecord(tname, ret)
		skynet.call(redis, "lua", "update", "ret", tname, rectab)
	elseif ret then
		for _,rtab in ipairs(ret) do	
		    dbcache.setRecord(tname, nil, rtab, true)
		end
	end
    print("-----command:init----33---", binsert)
end
---------------------------------------------------------------------
function command:get(field) --获取记录
	local tname = self._tabname
	local reckey = self._recordKey
	local rectab = dbcache.getRecord(tname, reckey)
    print("------command:get-----", field, tname, reckey, rectab)
	if field then 
        if not rectab then return end
        return rectab[field]
    end

	return rectab
end

function command:set(field, value)	--设置记录
    local dtab = dbtable[self._tabname]
    if field==dtab.pkey then 
        error("the primarykey can not be modified!")
    end
	local tname = self._tabname
	local reckey = self._recordKey
	local rectab = dbcache.getRecord(tname, reckey)
    if not rectab then return end

    rectab[field] = value or dtab.detail[field]
end
function command:update()
	if not self._tabname or not self._recordKey then return end
	dbfunc.updateTab(self._tabname, self._recordKey)
end