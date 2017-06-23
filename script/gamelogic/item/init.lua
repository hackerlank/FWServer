
if not g_gameitem.m_updateItemTab then g_gameitem.m_updateItemTab = {} end
local updateItemTab = g_gameitem.m_updateItemTab

--count为负数表示减法
function g_gameitem.addItem(userid, itemid, count)
	if not updateItemTab[userid] then updateItemTab[userid] = {} end
	local toUpdateTab = updateItemTab[userid]
	if not toUpdateTab[itemid] then toUpdateTab[itemid] = 0 end 
	toUpdateTab[itemid] = toUpdateTab[itemid] + count
end

--增加一个物品表，itemtab只有两种格式如：
--{[1003]=1,[1001]=100,[1002]=30} 或者 {{[1003]=1}, {[1001]=1}, {[1002]=1}}
--isgain为true表示获得，false表示花费
function g_gameitem.addItemTab(userid, itemtab, bcost)
	for k,v in pairs(itemtab) do
		if type(v) == "table" then
			for k1,v1 in pairs(v) do
				if not bcost then v1 = -v1 end
				g_gameitem.addItem(userid, k1, v1)
			end
		else
			if not bcost then v = -v end
			g_gameitem.addItem(userid, k, v)
		end
	end
end

--通知前端
function g_gameitem.noticeUpdateItem()
	for userid,tab in pairs(updateItemTab) do
		local rpTab = {}
    	rpTab.userId = userid
   		rpTab.itemtab = {},
		local itemdb = FGDBitem.query(userid)
		local itemtab = itemdb:get("allitem")
		for id,count in pairs(tab) do
			itemtab[id] = tonumber(itemtab[id]) + count
			rpTab.itemtab[id] = count
		end
		itemdb:set("allitem", itemtab)
		itemdb:update()
		g_protocol.sendProt(fd, MID_Protocol_Item, AItem_S2CUpdate, rpTab)
		g_gameitem.clearUpdateItem(userid)
	end
end
function g_gameitem.clearUpdateItem(userid)
	if userid then
		g_gameitem.m_updateItemTab[userid] = {}
		updateItemTab[userid] = {}
	else
		g_gameitem.m_updateItemTab = {}
		updateItemTab = {}
	end
end
