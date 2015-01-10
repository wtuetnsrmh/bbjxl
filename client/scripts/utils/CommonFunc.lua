require "socket"

function sleep(sec)
    socket.select(nil, nil, sec)
end

-- 时间转换  
function timeConvert(value, key)
	local hour, min, sec
	hour = math.floor(value / 3600)
	if hour >= 1 then
		min = math.floor((value - hour * 3600) / 60)
	else
		min = math.floor(value / 60)
	end
	sec = math.floor(value % 60 )
	
	if key == "hour" then return hour end
	if key == "min" then return min end
	if key == "sec" then return sec end
	
	return hour, min, sec
end

-- 查找上限
-- [10, 20, 30, 40] 查找15, 返回指向10的元素
function lowerBoundSeach(data, searchKey)
	-- 先排序
	local lastKey = nil
	local keys = table.keys(data)
	table.sort(keys)
	for _, key in ipairs(keys) do
		if key > searchKey then
			break
		end
		lastKey = key
	end

	return lastKey and data[lastKey] or nil
end

-- 初始化
function randomInit(seed)
	seed = seed or os.time()
	math.randomseed(tonumber(tostring(seed):reverse():sub(1,#tostring(seed))))
end

-- 随机浮点数
function randomFloat(lower, greater, callback)
	if type(callback) == "function" then callback() end

    return lower + math.random()  * (greater - lower);
end

function randomInt(lower, greater, callback)
	if type(callback) == "function" then callback() end

	local ret = math.random(lower, greater)
	return ret
end

-- 根据权重值从数据集合里面随机出
-- @param dataset	数据集合
-- @param field 	权重域
function randWeight(dataset, field)
	if not dataset then return nil end
	
	field = field or "weight"

	-- 计算权值总和
	local weightSum = 0
	for key, value in pairs(dataset) do
		weightSum = weightSum + tonumber(value[field])
	end

	local randWeight = randomFloat(0, weightSum)
	for key, value in pairs(dataset) do
		if randWeight > tonumber(value[field]) then
			randWeight = randWeight - tonumber(value[field])
		else
			return key
		end
	end

	return nil
end

-- 到下一个时间点的秒数差和下一个时间点的unixtime
function diffTime(params)
	params = params or {}
	local currentTime = game:nowTime()

	local curTm = os.date("*t", currentTime)
	local nextYear = params.year or curTm.year
	local nextMonth = params.month or curTm.month
	local nextDay = params.day or curTm.day + 1
	local nextHour = params.hour or 0
	local nextMinute = params.min or 0
	local nextSecond = params.sec or 0

	local nextUnixTime = os.time({ year = nextYear, month = nextMonth, day = nextDay, hour = nextHour, min = nextMinute, sec = nextSecond})
	return os.difftime(nextUnixTime, currentTime), nextUnixTime
end

-- YYYY/MM/DD-YYYY/MM/DD 转化成unixtime数组
-- @params 	dateStr 转化的时间字符串
function toDateArray(dateStr)
	if string.trim(dateStr) == "" then
		dateStr = "2014/01/01-2020/01/01"
	end
	local dateArray = string.split(dateStr, "-")

	local openDate = {}
	if #dateArray == 1 then
		local array = string.split(string.trim(dateArray[1]), "/")
		openDate[1] = os.time{ year=array[1], month=array[2], day=array[3], hour=0,min=0,sec=0}
		openDate[2] = os.time{ year=array[1], month=array[2], day=array[3], hour=23,min=59,sec=59}
	elseif #dateArray == 2 then
		local array = string.split(string.trim(dateArray[1]), "/")
		openDate[1] =  os.time{ year=array[1], month=array[2], day=array[3], hour=0,min=0,sec=0}
		local array = string.split(string.trim(dateArray[2]), "/")
		openDate[2] = os.time{ year=array[1], month=array[2], day=array[3], hour=0,min=0,sec=0}
	end

	return openDate
end

-- 判断时间点是不是当天
function isToday(curTimestamp)
	local curTm = os.date("*t", curTimestamp)
	local nowTm = os.date("*t", game:nowTime())
	return curTm.year == nowTm.year and curTm.month == nowTm.month and curTm.day == nowTm.day
end

function checkTable(v, key)
	v[key] = v[key] or {}
	return v[key]
end

--Point
function p(_x,_y)
    if nil == _y then
         return { x = _x.x, y = _x.y }
    else
         return { x = _x, y = _y }
    end
end

function pAdd(pt1,pt2)
    return {x = pt1.x + pt2.x , y = pt1.y + pt2.y }
end

function pSub(pt1,pt2)
    return {x = pt1.x - pt2.x , y = pt1.y - pt2.y }
end

function pMul(pt1,factor)
    return { x = pt1.x * factor , y = pt1.y * factor }
end

function pMidpoint(pt1,pt2)
    return { x = (pt1.x + pt2.x) / 2.0 , y = ( pt1.y + pt2.y) / 2.0 }
end

function pForAngle(a)
    return { x = math.cos(a), y = math.sin(a) }
end

function pGetLength(pt)
    return math.sqrt( pt.x * pt.x + pt.y * pt.y )
end

function pNormalize(pt)
    local length = pGetLength(pt)
    if 0 == length then
        return { x = 1.0,y = 0.0 }
    end

    return { x = pt.x / length, y = pt.y / length }
end

function pCross(self,other)
    return self.x * other.y - self.y * other.x
end

function pDot(self,other)
    return self.x * other.x + self.y * other.y
end

function pToAngleSelf(self)
    return math.atan2(self.y, self.x)
end

function pGetAngle(self,other)
    local a2 = pNormalize(self)
    local b2 = pNormalize(other)
    local angle = math.atan2(pCross(a2, b2), pDot(a2, b2) )
    if math.abs(angle) < 1.192092896e-7 then
        return 0.0
    end

    return angle
end

function pGetDistance(startP,endP)
    return pGetLength(pSub(startP,endP))
end

