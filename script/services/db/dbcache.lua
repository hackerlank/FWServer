local dbtable = require "config.dbtable"

if not g_database.m_cache then 
	g_database.m_cache = {} 
end
if not g_database.m_ctimetab then 
	g_database.m_ctimetab = {} 
end
if not g_database.m_checktab then
	g_database.m_checktab = {}
end
local dbcache  = {}
local dbtimetab = g_database.m_ctimetab
local cache = g_database.m_cache
local dbchecktab = g_database.m_checktab
--[[
local cache={
	user = {	--表名称
		-- pkey = "userId",	--主键名称
		-- auto = true,	--主键是否自增
		-- cache = true,	--缓存，是否启动服务器时候加载
		-- desc = "登录表",	--描述
		-- detail = {	--表结构
			
		-- },
		--缓存在这里
		[userId1] = {
			gold = 0,	--金币
			diamond = 0,	--钻石
			accountName = "",	--账户名
			accountPwd = "",	--账户密码
		}
	}
}
--外部传入的记录结构如同表dbtable[tname].detail
--传入的tabledata结构是包含多个记录dbtable[tname].detail，按照数字顺序排列
dbtimetab = {
	user = { 
		__IS_CHECK_TABLE_READED=0, --用于区分所有key,是否已读
		dtab = {[reckey] = {uptime=os.time(), deltime=os.time(),},}
	}
}
--缓存写入redis时间，在写数据后移除缓存时间，两个时间间隔不大于写redis的间隔时间
--]]
function dbcache.init()
    for k,tab in pairs(dbtable) do
        cache[k] = {}
        dbtimetab[k] = {}
        dbtimetab[k].dtab = {}
    end
end
function dbcache._resetUpdateFunc(tt, key)
    local dtab = dbtimetab[tt].dtab
    if not dtab[key] then dtab[key] = {} end
	local totab = dtab[key]
	totab.uptime = os.time() + G_DB_UPDATE_TIME
	totab.deltime = os.time() + G_DB_DELETE_TIME
end
function dbcache._resetUpdateData(tname, reckey)
	if reckey then
		dbcache._resetUpdateFunc(tname, reckey)
	else
		for rkey, _ in pairs(cache[tname] or {}) do
			dbcache._resetUpdateFunc(tname, rkey)
		end
	end
end
function dbcache._checkCache(tname, nowt)
	local uptab = {}
	local deltab = {}
	local temp
	for rkey, tab in pairs(dbtimetab[tname].dtab) do
		if tab.uptime>=nowt then
			table.insert(uptab, reckey)
			tab.uptime = os.time() + G_DB_UPDATE_TIME
			temp = true
		end
		if tab.deltime>=nowt then
			table.insert(deltab, reckey)
			tab.deltime = os.time() + G_DB_DELETE_TIME
			temp = true
		end
	end
	if temp then 
		return uptab, deltab 
	end
end
function dbcache.checkCache()
	local nowt = os.time()
	for tname,_ in pairs(cache) do
		if dbtimetab[tname].__IS_CHECK_TABLE_READED~=1 then 
			dbtimetab[tname].__IS_CHECK_TABLE_READED = 1
			local uptab, deltab = dbcache._checkCache(tname, nowt)
			if uptab then return tname,uptab, deltab end
		end
	end
	for tname, _ in pairs(cache) do
		dbtimetab[tname].__IS_CHECK_TABLE_READED = nil
	end
end

function dbcache.removeRecord(tname, reckey)
	cache[tname][reckey] = nil
end

function dbcache.getField(tname, fieldname, reckey)
	local rcd = cache[tname][reckey]
	if not rcd then return end
	return rcd[fieldname]
end
function dbcache.setField(tname, reckey, fieldname, fvalue)
	local rcd = cache[tname][reckey]
	rcd[fieldname] = fvalue
	dbcache._resetUpdateData(tname, reckey)
end

function dbcache.getRecord(tname, reckey, bRm)
    if not reckey or not tname then return end
	local rectab = cache[tname][reckey]
	if bRm then
		dbcache.removeRecord(tname, reckey)
	end
    return rectab
end

function dbcache.setRecord(tname, reckey, rectab, bCopyTab) --只缓存记录，
	local prikey = dbtable[tname].pkey
	local tab = rectab
   print("-------dbcache.setRecord---11--", tname, reckey, rectab, bCopyTab, prikey)
	if not bCopyTab then
		tab = {}
        print("-------dbcache.setRecord---22--")
		for k,v in pairs(rectab) do
        print("-------dbcache.setRecord---22-11-", k,v)
			tab[k] = v
		end
	end
        print("-------dbcache.setRecord---33--", reckey)
	if reckey then
		tab[prikey] = reckey
	else
		reckey = tab[prikey]
	end
	if not cache[tname] then cache[tname] = {} end
	if not cache[tname][reckey] then
        print("-------dbcache.setRecord---44--", reckey)
		dbcache._resetUpdateData(tname, reckey)
	end
        print("-------dbcache.setRecord---55--", reckey, tab)
	cache[tname][reckey] = tab
	return tab
end

function dbcache.setDefaultRecord(tname, reckey)
	if cache[tname][reckey] then
		error("cache already fill data!")
	end
	local rectab = dbtable[tname].detail
	return dbcache.setRecord(tname, reckey, rectab, true)
end

function dbcache.updateAll(checkupdatefunc)
	for tname, tab in pairs(cache) do
		for reckey,_ in pairs(tab) do
			checkupdatefunc(tname, reckey)
		end
	end
end

return dbcache
