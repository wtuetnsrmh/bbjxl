local ItemCsvData = {
	m_data = {},
}

function ItemCsvData:load( fileName )
	self.m_data = {}
	
	local csvData = CsvLoader.load(fileName)

	for index = 1, #csvData do
		local id = tonum(csvData[index]["道具ID"])

		if id ~= 0 then
			self.m_data[id] = {
				itemId = id,
				name = csvData[index]["道具名称"],
				desc = csvData[index]["道具说明"],
				stars = tonum(csvData[index]["星级"]),
				type = tonum(csvData[index]["道具类型"]),
				giftDropIds = string.split(csvData[index]["礼包掉落ID"], " "),	-- 可能会有多个礼包ID
				money = tonum(csvData[index]["金币"]),
				yuanbao = tonum(csvData[index]["元宝"]),
				health = tonum(csvData[index]["体力"]),
				zhangong = tonum(csvData[index]["战功"]),
				heroType = tonum(csvData[index]["卡牌"]),
				heroExp = tonum(csvData[index]["经验"]),
				randomIds = string.toTableArray(csvData[index]["随机道具"]),
				useType = tonum(csvData[index]["使用类型"]),
				openLevel = tonum(csvData[index]["开放等级"]),
				icon = csvData[index]["道具icon"],
				resource = csvData[index]["道具资源"],
				stackable = tonum(csvData[index]["可堆叠"]),
				stackUplimit = tonum(csvData[index]["堆叠上线"]),
				weight = tonum(csvData[index]["权值"]),
				favor = tonum(csvData[index]["好感度"]),
				itemIcon = csvData[index]["道具icon"],
				itemInclude = string.tomap(csvData[index]["内含道具"]),
				placetable = self:getPlaceTable(csvData[index]["产地"]),
				yuanbaoValue = tonum(csvData[index]["元宝价格"]),
				sellMoney = tonum(csvData[index]["银币价格"]),
			}

			self.m_data[id].source = string.trim(csvData[index]["产地"]) == "" and {} 
				or string.split(csvData[index]["产地"], " ")
			for idx = 1, 6 do
				self.m_data[id]["srcDesc" .. idx] = csvData[index]["产出描述" .. idx]
				self.m_data[id]["srcMap" .. idx] = tonum(csvData[index]["产出副本" .. idx])
				self.m_data[id]["srcCarbon" .. idx] = tonum(csvData[index]["产出关卡" .. idx])
			end
		end
	end
end

-- 用权重修正取出所有的道具权重信息
function ItemCsvData:getItemWeightArray(starModifies)
	local result = {}
	for itemId, value in pairs(self.m_data) do
		result[#result + 1] = {
			itemId = itemId,
			weight = tonum(starModifies[tostring(value.stars)]) * value.weight
		}
	end

	return result
end

-- 是否是道具
function ItemCsvData:isItem(itemTypeId)
	return itemTypeId == 4 or itemTypeId == 14 or itemTypeId == 15 or itemTypeId == 17 or itemTypeId == 18
		or itemTypeId == 19 or itemTypeId == 20 or itemTypeId == 21 or itemTypeId == 23 or itemTypeId == 1
		or itemTypeId == 24 or itemTypeId == 25 or itemTypeId == 27 or itemTypeId == 28
end

-- 消耗品
function ItemCsvData:isConsumption(type)
	return type == 4 or type == 17 or type == 19 or type == 20 or type == 21 or type == 27
end

-- 材料
function ItemCsvData:isMateriel(type)
	return type == 14 or type == 15 or type == 18 or type == 23
end

-- 将各种道具的ID转化成item表里面的道具ID, 统一发放
function ItemCsvData:calItemId(itemInfo)
	local idFunc = {
		[ItemTypeId.Gift] = function(itemId) return itemId end,
		[ItemTypeId.GoldCoin] = function(itemId) return itemId end,
		[ItemTypeId.Yuanbao] = function(itemId) return itemId end,
		[ItemTypeId.Health] = function(itemId) return itemId end,
		[ItemTypeId.PvpCount] = function(itemId) return itemId end,
		[ItemTypeId.SpecialBattleCount] = function(itemId) return itemId end,
		[ItemTypeId.Hero] = function(itemId) return itemId > 1000 and itemId or itemId + 1000 end,
		[ItemTypeId.HeroFragment] = function(itemId) return itemId > 2000 and itemId or itemId + 2000 end,
		[ItemTypeId.Skill] = function(itemId) return itemId end,
		[ItemTypeId.Lingpai] = function(itemId) return itemId end,
		[ItemTypeId.StarSoul] = function(itemId) return itemId end,
		[ItemTypeId.HeroSoul] = function(itemId) return itemId end,
		[ItemTypeId.HeroEvolution] = function(itemId) return itemId end,
		[ItemTypeId.Beauty] = function(itemId) return itemId end,
		[ItemTypeId.Package] = function(itemId) return itemId end,
		[ItemTypeId.RandomFragmentBox] = function(itemId) return itemId end,
		[ItemTypeId.RandomItemBox] = function(itemId) return itemId end,
		[ItemTypeId.ZhanGong] = function(itemId) return itemId end,
		[ItemTypeId.SkillLevel] = function(itemId) return itemId end,
		[ItemTypeId.Equip] = function(itemId) return itemId > 3000 and itemId or itemId + 3000 end,
	}

	if itemInfo.itemTypeId and idFunc[itemInfo.itemTypeId] then
		return idFunc[itemInfo.itemTypeId](tonum(itemInfo.itemId))
	else
		return tonum(itemInfo.itemId)
	end
end

-- 根据道具ID获得道具
function ItemCsvData:getItemById(itemId)
	return self.m_data[itemId]
end

function ItemCsvData:mergeItems(itemInfos)
	local result = {}

	local mergeItems = {}
	for _, itemInfo in ipairs(itemInfos) do
		local itemKey = itemInfo.itemTypeId .. "-" .. itemInfo.itemId
		if itemInfo.itemTypeId ~= ItemTypeId.Hero then
			mergeItems[itemKey] = tonum(result[itemKey]) + itemInfo.num
		else
			table.insert(result, itemInfo)
		end
	end

	for key, num in pairs(mergeItems) do
		local keyInfo = string.split(key, "-")
		table.insert(result, {
			itemTypeId = tonum(keyInfo[1]),
			itemId = tonum(keyInfo[2]),
			num = num,
		})
	end

	return result
end

function ItemCsvData:getPlaceTable(pstring)
	local r = {}
	if pstring ~= nil then
		local p = {
		["1"] = "商店",
		["2"] = "名将商店",
		["3"] = "战场奖励",
		["4"] = "普通副本",
		["5"] = "精英副本",
		["6"] = "名将",
		["7"] = "过关斩将",
		["8"] = "战场商店",
		}
		local t = string.split(tostring(pstring), " ")
		for k,v in pairs(t) do
			r[#r + 1] = p[tostring(v)]
		end
		return r
	end
end


return ItemCsvData