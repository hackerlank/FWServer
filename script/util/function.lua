local utilfunc = {}

--参数都是os.time()的返回值
function utilfunc.IntervalDay(ot1, ot2) --返回ot1的天数减去ot2的天数，可为负数，若为0则为同一天
	local h1 = math.floor(os.date("%D",tt1))
	local h2 = math.floor(os.date("%D",tt2))
	return h1-h2
end
function utilfunc.IntervalHour(ot1, ot2)		--ot1和ot2的相差小时，可为负数，若为0则为同一天
	local h1 = math.floor(os.date("%H",tt1))
	local h2 = math.floor(os.date("%H",tt2))
	return h1-h2
end
function utilfunc.IntervalMin(ot1, ot2)		--ot1和ot2的相差分钟，
	local h1 = math.floor(os.date("%M",tt1))
	local h2 = math.floor(os.date("%M",tt2))
	return h1-h2
end
function utilfunc.ZeroTime(hour) --获取当天整hour点的os.time()
	if not hour or hour>=24 then hour = 0 end
	local daytab = os.date("*t")
	daytab.hour = hour
	daytab.min = 0
	daytab.sec = 0
	return os.time(daytab)
end
-------------------------------------------------------------------------
function string.split(input, delimiter)
    input = tostring(input)
    delimiter = tostring(delimiter)
    if (delimiter=='') then return false end
    local pos,arr = 0, {}
    -- for each divider found
    for st,sp in function() return string.find(input, delimiter, pos, true) end do
        table.insert(arr, string.sub(input, pos, st - 1))
        pos = sp + 1
    end
    table.insert(arr, string.sub(input, pos))
    return arr
end
function string.splitex(str,delimiter1, delimiter2)
    if not delimiter1 then return {str} end
    local spat = string.format("[^%s]+",delimiter1)
    local spat2
    if delimiter2 then 
        spat2 = string.format("[^%s]+",delimiter2)
    end
    local function sgmatch(str, pat, pat2)
        local ret = {}
        for s in string.gmatch(str,pat) do
            if pat2 then
                local ts = sgmatch(s, pat2)
                if #ts~=0 then s =ts end
            end
            table.insert(ret,s)
        end
        return ret
    end
    return sgmatch(str, spat, spat2)
end
function string.trim(input)
    input = string.gsub(input, "^[ \t\n\r]+", "")
    return string.gsub(input, "[ \t\n\r]+$", "")
end
function utilfunc.dump(value, desciption, nesting)
    if type(nesting) ~= "number" then nesting = 3 end

    local lookupTable = {}
    local result = {}

    local function _v(v)
        if type(v) == "string" then
            v = "\"" .. v .. "\""
        end
        return tostring(v)
    end

    local traceback = string.split(debug.traceback("", 2), "\n")
    print("dump from: " .. string.trim(traceback[3]))

    local function _dump(value, desciption, indent, nest, keylen)
        desciption = desciption or "<var>"
        spc = ""
        if type(keylen) == "number" then
            spc = string.rep(" ", keylen - string.len(_v(desciption)))
        end
        if type(value) ~= "table" then
            result[#result +1 ] = string.format("%s%s%s = %s", indent, _v(desciption), spc, _v(value))
        elseif lookupTable[value] then
            result[#result +1 ] = string.format("%s%s%s = *REF*", indent, desciption, spc)
        else
            lookupTable[value] = true
            if nest > nesting then
                result[#result +1 ] = string.format("%s%s = *MAX NESTING*", indent, desciption)
            else
                result[#result +1 ] = string.format("%s%s = {", indent, _v(desciption))
                local indent2 = indent.."    "
                local keys = {}
                local keylen = 0
                local values = {}
                for k, v in pairs(value) do
                    keys[#keys + 1] = k
                    local vk = _v(k)
                    local vkl = string.len(vk)
                    if vkl > keylen then keylen = vkl end
                    values[k] = v
                end
                table.sort(keys, function(a, b)
                    if type(a) == "number" and type(b) == "number" then
                        return a < b
                    else
                        return tostring(a) < tostring(b)
                    end
                end)
                for i, k in ipairs(keys) do
                    _dump(values[k], k, indent2, nest + 1, keylen)
                end
                result[#result +1] = string.format("%s}", indent)
            end
        end
    end
    _dump(value, desciption, "- ", 1)

    for i, line in ipairs(result) do
        print(line)
    end
end

return utilfunc