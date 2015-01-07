--[[--

Split a string by string to map, string format like "123=2 222=3"

@param string str
@param string delimiter
@return map(note: type(key) == "string")

]]
function string.tomap(str, delimiter)
	delimiter = delimiter or " "
	local map = {}
	local array = string.split(string.trim(str), delimiter)
	for _, value in ipairs(array) do
		value = string.split(string.trim(value), "=")
		if #value == 2 then
			map[value[1]] = value[2]
		end
	end

	return map
end

--以数字形式存储
function string.toNumMap(str, delimiter)
	delimiter = delimiter or " "
	local map = {}
	local array = string.split(string.trim(str), delimiter)
	for _, value in ipairs(array) do
		value = string.split(string.trim(value), "=")
		if #value == 2 then
			map[tonum(value[1])] = tonum(value[2])
		end
	end

	return map
end

-- Format(xxx=xxx=xxx=xxx)
function string.toArray(str, delimiter, toNum)
	delimiter = delimiter or " "
	toNum = toNum or false
	local array = {}
	local tempArray = string.split(string.trim(str), delimiter)
	for _, value in ipairs(tempArray) do
		if string.trim(value) ~= "" then
			if toNum then value = tonum(value) end
			table.insert(array, value)
		end
	end

	return array
end

-- Format(xxx=xxx=xxx=xxx xxx=xxx=xxx=xxx)
function string.toTableArray(str, delimiter)
	delimiter = delimiter or " "
	local array = {}
	local tempArray = string.split(string.trim(str), delimiter)
	for _, value in ipairs(tempArray) do
		local trimValue = string.trim(value)
		if trimValue ~= "" then
			value = string.split(trimValue, "=")
			table.insert(array, value)
		end
	end

	return array
end

-- 将string转化为多行
function string.toLineArray(s)
	local ts = {}
	local posa = 1
	while 1 do
		local pos, chars = s:match('()([\r\n].?)', posa)
		if pos then
			local line = s:sub(posa, pos - 1)
			ts[#ts + 1] = line
			if chars == '\r\n' then pos = pos + 1 end
			posa = pos + 1
		else
			local line = s:sub(posa)
			if line ~= '' then ts[#ts + 1] = line end
			break
		end
	end
	return ts
end

function string.mySplit(inputstr, sep)
	if sep == nil then
		sep = "%s"
	end
	t={} 
	i=1
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
		t[i] = str
		i = i + 1
	end
	return t
end

-- Format(xxx=xxx=xxx=xxx xxx=xxx=xxx=xxx)
function string.toAttArray(str, delimiter)
	delimiter = delimiter or " "
	local array = {}
	local tempArray = string.split(string.trim(str), delimiter)
	for _, value in ipairs(tempArray) do
		local trimValue = string.trim(value)
		if trimValue ~= "" then
			value = string.split(trimValue, "=")
			local key = tonum(value[1])
			array[key] = {}
			for index, attValue in ipairs(value) do
				if index ~= 1 then
					table.insert(array[key], tonum(attValue))
				end
			end 
		end
	end

	return array
end

--计算长度，中文算两个
function string.myUtf8len(str)
    local len = string.len(str)
    local num = 0
    local i = 1
   	while i <= len do
		local n = string.byte(str,i)
		local delta = 2
		if n < 0x7f then
			i = i + 1
			delta = 1
		elseif n>=0xc0 and n<=0xdf then
			i = i+2
		elseif n>=0xe0 and n<=0xef then
			i = i+3
		elseif n>=0xf0 and n<=0xf7 then
			i = i+4
		elseif n>=0xf8 and n<=0xfb then
			i = i+5
		else
			i = i+6
		end
		num = num + delta
	end
	return num
end
