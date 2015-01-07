-- 必须按配置表的顺序
local FieldNameMap = {
	["怒气CD"] = { name = "angryCD", type = "number" },
	["初始怒气"] = { name = "initAngerValue", type = "number" },
	["击杀怒气"] = { name = "killEnemyAnger", type = "number" },
	["阶段怒气"] = { name = "phaseAnger", type = "number" },
	["暂停战斗"] = { name = "pauseBattle", type = "number" },
	["继承怒气"] = { name = "inheritAnger", type = "number" },
	["可移动优先"] = { name = "battleMoveFirst", type = "number" },
	["技能CD"] = { name = "skillCDTime", type = "number" },
	["自动战斗检测CD"] = { name = "autoSkillCdTime", type = "number"},
	["关卡阶段回复血量"] = { name = "phaseRecoverHp", type = "number" },
	["受击失血下限"] = { name = "damagedFloor", type = "number" },
	["k1"] = { name = "k1", type = "number" },
	["k2"] = { name = "k2", type = "number" },
	["k3"] = { name = "k3", type = "number" },
	-- 武将二级属性范围
	["闪避率下限"] = { name = "missFloor", type = "number" },
	["闪避率上限"] = { name = "missCeil", type = "number" },
	["格挡率下限"] = { name = "parryFloor", type = "number" },
	["格挡率上限"] = { name = "parryCeil", type = "number" },
	["暴击率下限"] = { name = "critFloor", type = "number" },
	["暴击率上限"] = { name = "critCeil", type = "number" },
	-- 被动技能相关
	["进化等级激活被动技能1"] = { name = "passiveSkillLevel1", type = "number"},
	["进化等级激活被动技能2"] = { name = "passiveSkillLevel2", type = "number"},
	["进化等级激活被动技能3"] = { name = "passiveSkillLevel3", type = "number"},
	["好友奖励友情值"] = { name = "friendAwardPoint", type = "number" },
	["路人奖励友情值"] = { name = "strangeAwardPoint", type = "number" },
	["好友助战时间间隔"] = { name = "friendAssistCdTime", type = "number" },
	["路人助战时间间隔"] = { name = "strangeAssistCdTime", type = "number" },
	["路人等级差下限"] = { name = "strangeLevelLowDelta", type = "number" },
	["路人等级差上限"] = { name = "strangeLevelUpDelta", type = "number" },
	["等级差范围扩大"] = { name = "levelDeltaChange", type = "number" },
	["传奇副本免费刷新次数"] = { name = "refreshLegendLimit", type = "number" },
	["传奇副本挑战次数"] = { name = "legendBattleLimit", type = "number", },
	["传奇副本购买次数上限"] = { name = "legendBuyLimit", type = "number" },
	["科技洗点消耗元宝数"] = { name = "washTechNeedYuanbao", type = "number" },
	["美人品德系数"]= { name = "beautyHpFactor", type = "number"},
	["美人才艺系数"] = { name = "beautyAtkFactor", type = "number"},
	["美人美色系数"] = { name = "beautyDefFactor", type = "number"},
	["技能升级金币"] = { name = "upSkillLevelMoney", type = "map" },
	-- pvp战斗结果奖励
	["PVP胜利奖励"] = { name = "pvpWinAwardYanzhiNum", type = "number" },
	["PVP失败奖励"] = { name = "pvpLostAwardYanzhiNum", type = "number" },
	["加速战斗等级要求"] = { name = "speedupFightLevelRequired", type = "number" },
	["自动战斗等级要求"] = { name = "autoFightLevelRequired", type = "number" },
	["单次扫荡CD"] = { name = "sweepTime", type = "number"},
	["强化金币经验比值"] = { name = "intensifyGoldNum", type = "number"},
	["每日战场初始次数"] = { name = "pvpCount", type = "number" },
	["每日战场初始购买次数上限"] = { name = "pvpBuyLimit", type = "number" },
	["升级体力回复量"] = { name = "healthByUpLevel", type = "number" },
	["战斗最大时长"] = { name = "battleMaxTime", type = "number"},
	["金钱副本次数"] = { name = "moneyBattleTimes", type = "number" },
	["经验副本次数"] = { name = "expBattleTimes", type = "number"},
	["特殊副本CD"] = { name = "moneyBattleCD", type = "number"},
	["金钱副本开放"] = { name = "moneyOpenDate", type = "time"},
	["经验副本开放"] = { name = "expOpenDate", type = "time"},
	["武将包购买次数上限"] = { name = "bagHeroBuyLimit", type = "number"},
	["精英购买挑战次数价格"] = { name = "priceOfHardChallenge", type = "string"},
	["招财暴击"] = { name = "zhaoCaiCrit", type = "string"},

	["等级上限"] = { name = "levelUpLimit", type = "number" },
	["装备强化暴击"] = { name = "EquipIntensifyCrit", type = "string"},

	["商店2刷新副本条件"] = {name = "store2condition", type = "time"},
	["商店3刷新副本条件"] = {name = "store3condition", type = "time"},

	["出塞等级条件"] = {name = "limitLevel", type = "number"},
	["出塞星级条件"] = {name = "limitStar", type = "number"},

	["武将出售经验单价"] = {name = "moneyPerExp", type = "number"},

	["武将升星实力系数"] = {name = "starFactor", type = "array"},
	["武将升星碎片量"] = {name = "starUpFragment", type = "array"},
	["武将升星价格"] = {name = "starUpCost", type = "array"},
	["武将碎片将魂比"] = {name = "fragmentToSoul", type = "number"},
	["武将分解碎片量"] = {name = "decomposeFragNum", type = "array"},

	["装备进化单价"] = {name = "equipEvolPerCost", type = "number"},
	["装备进化实力系数"] = {name = "equipEvolFactor", type = "array"},

	["首充奖励"] = {name = "firstRechargeAward", type = "array"},

	["体力经验比"] = {name = "healthToExp", type = "number"},

	["爬塔开箱价格"] = {name = "towerOpenBoxPrice", type = "string"},
	
	["基金购买"] = {name = "fundCost", type = "number"},
	["基金购买等级"] = {name = "fundLevel", type = "number"},
	["神将价格"] = {name = "godHeroCost", type = "number"},

	["聊天等级限制"] = {name = "chatLevelLimit", type = "number"},
}

local GlobalCsvData = {
	m_data = {},
}

function GlobalCsvData:load(fileName)
	local csvData = CsvLoader.load(fileName)

	local meta = {}
	meta.__index = function (self, key)
		local v = rawget(self, key .. "_ed")
		if v then
			return MemDecrypt(v)
		else
			return meta[key]
		end
	end

	meta.__newindex = function (self, key, value)
		if type(value) == "number" then
			rawset(self, key .. "_ed", MemEncrypt(value))
		else
			rawset(self, key, value)
		end
	end

	self.m_data = setmetatable({}, meta)

	for index = 1, #csvData do
		local item = FieldNameMap[csvData[index]["name"]]
		if item then
			if item.type == "number" then
				self.m_data[item["name"]] = tonum(csvData[index]["value"])
			end
			if item.type == "time" then
				self.m_data[item["name"]] = string.split(csvData[index]["value"], "=")
			end
			if item.type == "string" then
				self.m_data[item["name"]] = csvData[index]["value"]
			end
			if item.type == "array" then
				self.m_data[item["name"]] = string.toNumMap(csvData[index]["value"], " ")
			end
		end
	end
end

function GlobalCsvData:get(fileName)
	local csvData = CsvLoader.load(fileName)
	self.m_data = {}

	for index = 1, #csvData do
		self.m_data[csvData[index]["name"]] = csvData[index]["value"]
	end
end

-- 返回给定的域的值
-- @param field 	变量名, 对应于FieldNameMap中的key
-- @return 返回该域对应的值
function GlobalCsvData:getFieldValue(field)
	return self.m_data[field]
end

function GlobalCsvData:getComposeFragmentNum(star)
	local data = self:getFieldValue("starUpFragment")
	local num = 0
	for index = 1, star do
		num = num + tonum(data[index])
	end
	return num
end

return GlobalCsvData