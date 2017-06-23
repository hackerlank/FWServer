local skynet = require "skynet"

if not g_timer.m_timer_id then
    g_timer.m_timer_id = 0
end

local max_int = 2147483600 --int的最大值2147483647
local timer_id = g_timer.m_timer_id 
local timer_tab = g_timer
local function checkToUsed(t)
	if not timer_tab[t] then 
		timer_id = t
		return t
	end
end
local function genTimerId()
	local t = timer_id+1
	local usedid = checkToUsed(t)
	if usedid then return usedid end
	t = t+1
    if t<=max_int then
	    for i=t,max_int,1 do
		    usedid = checkToUsed(i)
		    if usedid then return usedid end
	    end
    end
    if t-1>=1 then
	    for i=1,t-1,1 do
		    usedid = checkToUsed(i)
		    if usedid then return usedid end
	    end
    end
end
function g_timer.addtimer(delaySec, func, ...) --延迟秒，runCount回调次数(间隔delaySec)，func回调函数，"..."是不定参数
    if not func then return end
    local tid = genTimerId()
    timer_tab[tid] = 1 
    timer_id = tid 
    local paramTab = {...}
    local callfunc = function()
        --print("-------callfunc-----", timer_tab[tid], tid)
        local tcount = timer_tab[tid]
        if tcount and tcount>0 then
            func(table.unpack(paramTab))
            tcount = tcount - 1
            if tcount<=0 then tcount = nil end
        end
        timer_tab[tid] = tcount 
    end 
    local delay = delaySec*100
	if delay <= 0 then
		delay = 1
	end
    skynet.timeout(delay, callfunc)
    return tid 
end

function g_timer.rmtimer(tid) --移除对应的timerid
    if tid and timer_tab[tid] then
        timer_tab[tid] = timer_tab[tid] - 1 
        if timer_tab[tid]<=0 then timer_tab[tid]=nil end 
    end 
end

