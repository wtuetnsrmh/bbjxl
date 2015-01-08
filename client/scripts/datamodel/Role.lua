local json = require("framework.json")
local scheduler = require("framework.scheduler")

local Role = class("Role")

Role.pbField = {
	"id", "name", "level", "exp", "health", "money", "yuanbao", "pvpRank", "friendCnt", 
	"monthSignDay", "lastLoginTime", "pveFormationJson", "yzFormationJson", "mainHeroId", "mainHeroType", 
	"friendValue", "heroSoulNum", "lingpaiNum", "professionData", "starSoulNum", "reputation",
	"starPoint", "rechargeRMB", "vipLevel", "sweepCarbonId", "sweepResult", 
	"zhangongNum", "guideStep", "levelGiftsJson", "serverGiftsJson", "loginDays", "slotsJson", 
	"store2DailyCount", "store3DailyCount", "bagHeroBuyCount", "activedGuide", "firstRechargeJson", "battleSpeed", "partnersJson",
	"firstRechargeAwardState", "rechargeGiftsJson", "skillOrderJson", "fundJson","legendCardonIdIndex",
	"renameCount",
}

function Role:ctor(pbSource)
	require("framework.api.EventProtocol").extend(self)

	for _, field in pairs(self.class.pbField) do
		self[field] = pbSource[field]
	end
	self.oldHealth = self.health
	-- json 数据转化
	self.professionBonuses = json.decode(self.professionData)
	
	self.levelGifts = json.decode(self.levelGiftsJson) or {}
	self.serverGifts = json.decode(self.serverGiftsJson) or {}
	self.slots = json.decode(self.slotsJson) or {}
	self.pveFormation = json.decode(self.pveFormationJson) or {}
	self.yzFormation = json.decode(self.yzFormationJson) or {}
	self.firstRecharge = json.decode(self.firstRechargeJson) or {}
	self.partners = json.decode(self.partnersJson) or {}
	self.rechargeGifts = json.decode(self.rechargeGiftsJson) or {}
	self.skillOrder = json.decode(self.skillOrderJson) or {}
	self.fund = json.decode(self.fundJson) or {}

	self.friendCnt = 0
	self.status = RoleStatus.Idle

	self.mapTypeDataset = {}
	self.mapDataset = {}
	self.carbonDataset = {}

	self.heros = {}

	self.chooseHeros = {}

	-- 玩家的美人信息
	self.beauties = {}

	-- 玩家的刷塔数据
	self.townData = nil

	-- 玩家的远征数据
	self.expeditionData = nil

	-- 玩家的武将碎片
	self.fragments = {}

	-- 玩家的背包物品
	self.items = {}

	-- 装备
	self.equips = {}
	--装备碎片
	self.equipFragments = {}

	-- 战场左侧总人数：
	self.leftMembers = 0

	self.legendCheckPoint = game:nowTime()	-- 当前登录时间点
	self.pvpCheckPoint = game:nowTime()

	-- 玩家所有的聊天消息
	self.chats = {}

	self.guideSubStep = 0

	--新手引导
	-- self.guideStep = 1000
	local curGuide = guideCsv:getStepStartGuide(self.guideStep)
	game.guideId = curGuide and curGuide.guideId or 0
	self.oldGuideStep = self.guideStep

	--是否今天首次登陆
	self.firstLogin = not isToday(self.lastLoginTime)

	game:addEventListener(actionModules[actionCodes.RoleUpdateProperty], function(event)
		local msg = pb.decode("RoleUpdateProperty", event.data)
		self:updateProperty(msg.key, msg.newValue, msg.oldValue)
	end)

	game:addEventListener(actionModules[actionCodes.RoleUpdateProperties], function(event)
		local msg = pb.decode("RoleUpdateProperties", event.data)
		self:updateProperties(msg.tab)
	end)

	game:addEventListener(actionModules[actionCodes.CarbonLoadDataSet], function(event)
		local msg = pb.decode("CarbonResponse", event.data)
		self:buildMapData(msg.carbons, msg.maps)
	end)

	game:addEventListener(actionModules[actionCodes.HeroLoadDataSet], function(event)
		local msg = pb.decode("HeroResponse", event.data)

		for _, hero in ipairs(msg.heros) do
			local newHero = require("datamodel.Hero").new(hero)
			self.heros[newHero.id] = newHero

			if newHero.choose == 1 then
				table.insert(self.chooseHeros, newHero)
			end
		end
	end)

	game:addEventListener(actionModules[actionCodes.ItemUpdateProperty], function(event)
		local msg = pb.decode("SimpleEvent", event.data)
		self:addItem({itemId = msg.param1, count = msg.param2})
	end)

	game:addEventListener(actionModules[actionCodes.HeroUpdateProperty], function(event)
		local msg = pb.decode("HeroUpdateProperty", event.data)
		local hero = self.heros[msg.id]
		if hero == nil then return end

		hero:updateProperty(msg.key, msg.newValue)
	end)

	game:addEventListener(actionModules[actionCodes.EquipUpdateProperty], function(event)
		local msg = pb.decode("EquipUpdateProperty", event.data)
		local equip = self.equips[msg.id]
		if equip == nil then return end

		equip:updateProperty(msg.key, msg.newValue)
	end)

	game:addEventListener(actionModules[actionCodes.FragmentLoadDataSet], function(event)
		local msg = pb.decode("FragmentList", event.data)
		self:addFragments(msg.fragments)
	end)

	-- 处理聊天消息
	game:addEventListener(actionModules[actionCodes.ChatReceiveResponse], function(event)
		local msg = pb.decode("ChatMsg",event.data)

		self:addChat(msg)
	end)

	-- 服务端新事件通知
	game:addEventListener(actionModules[actionCodes.RoleNotifyNewEvents], function(event)
		local msg = pb.decode("NewMessageNotify", event.data)
		for _, event in ipairs(msg.newEvents) do
			local actionResult
			if event.value > 0 then
				actionResult = "add"
			end
			self:dispatchEvent({ name = "notifyNewMessage", type = event.key, action = actionResult })
		end
	end)

	--装备
	game:addEventListener(actionModules[actionCodes.EquipLoadDataSet], function(event)
		local msg = pb.decode("EquipDetail", event.data)
		self.equips[msg.id] = require("datamodel.Equip").new(msg)
	end)

	--装备碎片
	game:addEventListener(actionModules[actionCodes.EquipFragmentLoadDataSet], function(event)
		local msg = pb.decode("FragmentList", event.data)
		self:addEquipFragments(msg.fragments)
	end)

	-- 踢下线
	game:addEventListener(actionModules[actionCodes.RoleKickDown], function (event)
		-- disconnect socket
		game:closeSocket()	
	end)

	game:addEventListener(actionModules[actionCodes.RoleUpdateDailyProps], function (event) 
		local msg = pb.decode("NewMessageNotify", event.data)
		for _, prop in ipairs(msg.newEvents) do
			self[prop.key] = prop.value
		end
	end)

	-- 商店刷新
	game:addEventListener(actionModules[actionCodes.RoleShopRefresResponse], function(event)
		local msg = pb.decode("RoleShopDataResponse", event.data)
		self:dispatchEvent({ name = "shopRefreshTimer", data = msg })
	end)

	game:addEventListener(actionModules[actionCodes.SysErrorMsg], handler(self, self.processErrorCode))

	-- 系统一般公告
	game:addEventListener(actionModules[actionCodes.SysCommonNotice], function(event)
		local msg = pb.decode("GmEvent", event.data)

		DGMsgBox.new({ type = 1, text = msg.cmd })
	end)

	-- 系统维护公告
	game:addEventListener(actionModules[actionCodes.SysMaintainNotice], function(event)
		local msg = pb.decode("GmEvent", event.data)
		local dialog = ConfirmDialog.new({
			priority = -10000,
			showText = { text = msg.cmd, size = 28, },
			button1Data = {
			callback = function()
				CCDirector:sharedDirector():endToLua()
			end,
			},
		})

		dialog:getLayer():anch(0.5, 0.5):pos(display.cx, display.cy):addTo(display.getRunningScene(), 100)
	end)

	--活动时间
	game:addEventListener(actionModules[actionCodes.RoleGetActivityTimeListRespose], function(event)
		local msg = pb.decode("SimpleEvent", event.data)
		local tempData = json.decode(msg.param5)
		self.activityTimeList = tempData["activityTimeList"]
		self:dispatchEvent({name = "ActivityTimeListRefresh"})
	end)
end

function Role:reset()
	self:removeAllEventListeners()

	game:removeAllEventListenersForEvent(actionModules[actionCodes.RoleUpdateProperty])
	game:removeAllEventListenersForEvent(actionModules[actionCodes.CarbonLoadDataSet])
	game:removeAllEventListenersForEvent(actionModules[actionCodes.HeroLoadDataSet])
	game:removeAllEventListenersForEvent(actionModules[actionCodes.HeroUpdateProperty])
	game:removeAllEventListenersForEvent(actionModules[actionCodes.ChatReceiveResponse])
	game:removeAllEventListenersForEvent(actionModules[actionCodes.EquipUpdateProperty])
	game:removeAllEventListenersForEvent(actionModules[actionCodes.RoleGetActivityTimeListRespose])
end

function Role:addFragments(fragments)
	for _, fragment in ipairs(fragments) do
		local oldNum = tonum(self.fragments[fragment.fragmentId])
		self.fragments[fragment.fragmentId] = oldNum + fragment.num
	end	
	self:dispatchEvent({ name = "notifyHeroFragmentUpdate" })
end

function Role:addEquipFragments(fragments)
	for _, fragment in ipairs(fragments) do
		local oldNum = tonum(self.equipFragments[fragment.fragmentId])
		self.equipFragments[fragment.fragmentId] = oldNum + fragment.num
	end
end

function Role:addItem(data)
	self.items[data.itemId] = self.items[data.itemId] or {}
	self.items[data.itemId].id = data.itemId
	self.items[data.itemId].count = tonum(self.items[data.itemId].count) + data.count or 1
	if self.items[data.itemId].count <= 0 then
		self.items[data.itemId] = nil
	end
	self:dispatchEvent({ name = "notifyItemUpdate" })
end

function Role:awardItemCsv(itemId, params)
	params = params or {}
	
	itemId = tonum(itemId)
	local itemInfo = itemCsv:getItemById(itemId)
	if not itemInfo then return false end

	if itemInfo.type == ItemTypeId.GoldCoin then
		self:set_money(self.money + itemInfo.money * (params.num or 1))

	elseif itemInfo.type == ItemTypeId.Yuanbao then
		self:set_yuanbao(self.yuanbao + itemInfo.yuanbao * (params.num or 1))

	elseif itemInfo.type == ItemTypeId.ZhanGong then
		self:set_zhangongNum(self.zhangongNum + itemInfo.zhangong * (params.num or 1))

	elseif itemInfo.type == ItemTypeId.HeroFragment then
		self:addFragments({{ fragmentId = itemInfo.heroType + 2000, num = params.num or 1 }})

	elseif itemInfo.type == ItemTypeId.Lingpai then
		self:set_lingpaiNum(self.lingpaiNum + params.num)

	elseif itemInfo.type == ItemTypeId.StarSoul then
		self:set_starSoulNum(self.starSoulNum + params.num)

	elseif itemInfo.type == ItemTypeId.HeroSoul then
		self:set_heroSoulNum(self.heroSoulNum + params.num)

	elseif itemInfo.type == ItemTypeId.EquipFragment then
		self:addEquipFragments({{ fragmentId = itemId, num = params.num or 1 }})		

	elseif itemInfo.type == ItemTypeId.Equip then
		
	elseif itemCsv:isItem(itemInfo.type) then
		self:addItem({ itemId = itemId, count = params.num or 1 })
	end

	return true
end

-- 更新属性的接口
function Role:updateProperty(property, ...)
	local method = self["set_" .. property]
	if type(method) ~= "function" then
        print("ERROR_PROPERTY_SETTING_METHOD", property)
        return
    end
    method(self, ...)
end

function Role:updateProperties(modify_tab)
	for _, v in pairs(modify_tab) do
		self:updateProperty(v.key, v.newValue)
	end
end

function Role:set_level(newLevel)
	local origLevel = self.level
	self.level = tonumber(newLevel)
	-- display.getRunningScene():performWithDelay(function()	
		if origLevel < self.level then
			local RoleUpLevelLayer = require("scenes.battle.RoleUpLevelLayer")
			local upLevelLayer = RoleUpLevelLayer.new({
				origLevel = origLevel, curLevel = self.level, priority = -9998,
			})
			display.getRunningScene():addChild(upLevelLayer:getLayer(), 10)
		end
	-- end, 1.8)
	self:dispatchEvent({name = "updateLevel", level = self.level, origLevel = origLevel })

	return true
end

function Role:set_exp(newExp)
	self:addExp(tonumber(newExp) - self.exp)
	self:dispatchEvent({name = "updateExp", exp = self.exp})
end

function Role:set_health(newHealth, origHealth)
	self.oldHealth = tonumber(origHealth or newHealth)
	self.health = tonumber(newHealth)
	self:dispatchEvent({name = "updateHealth", health = self.health})
end

function Role:set_lastHealthTime(newTime)
	self.lastHealthTime = tonum(newTime)
end

function Role:set_yuekaDeadline(newTime)
	self.yuekaDeadline = tonum(newTime)
end

function Role:set_specialStore2EndTime(newTime)
	self.specialStore2EndTime = tonum(newTime)
	DGMsgBox.new({text = "月英的藏宝阁已开启，快去商店看看吧！", type = 1})
	self:dispatchEvent({ name = "specialStoreOpened" })
end

function Role:set_specialStore3EndTime(newTime)
	self.specialStore3EndTime = tonum(newTime)
	DGMsgBox.new({text = "庞统的百宝箱已开启，快去商店看看吧！", type = 1})
	self:dispatchEvent({ name = "specialStoreOpened" })
end

function Role:set_money(newMoney)
	self.money = tonumber(newMoney)
	self:dispatchEvent({name = "updateMoney", money = self.money})
end

function Role:set_yuanbao(newYuanbao)
	self.yuanbao = tonumber(newYuanbao)
	self:dispatchEvent({name = "updateYuanbao", yuanbao = self.yuanbao})
end

function Role:set_name(newName)
	self.name = tostring(newName)
	self:dispatchEvent({name = "updateName", rolename = self.name})
end

function Role:set_yanzhi(newYanzhi)
	self.yanzhi = tonumber(newYanzhi)
	self:dispatchEvent({name = "updateYanzhi", yanzhi = self.yanzhi})
end

function Role:set_friendValue(newFriendValue)
	self.friendValue = tonumber(newFriendValue)
	self:dispatchEvent({name = "updateFriendValue", friendValue = self.friendValue})	
end

function Role:set_pvpCount(newCnt)
	self.pvpCount = tonumber(newCnt)
	self:dispatchEvent({name = "updatePvpCount", pvpCount = self.pvpCount})
end

function Role:set_pvpBuyCount(newBuyCnt)
	self.pvpBuyCount = tonumber(newBuyCnt)
	self:dispatchEvent({name = "updatePvpBuyCount", pvpBuyCount = self.pvpBuyCount})
end

function Role:set_lastPvpTime(newPvpTime)
	self.lastPvpTime = tonumber(newPvpTime)
	self:dispatchEvent({name = "updateLastPvpTime", lastPvpTime = self.lastPvpTime})
end

function Role:set_heroSoulNum(newHeroSoulNum)
	self.heroSoulNum = tonumber(newHeroSoulNum)
	self:dispatchEvent({name = "updateHeroSoulNum", heroSoulNum = self.heroSoulNum})
end

function Role:set_zhangongNum(newZhangongNum)
	self.zhangongNum = tonumber(newZhangongNum)
	self:dispatchEvent({name = "updateZhangongNum", zhangongNum = self.zhangongNum})
end

function Role:set_reputation(newReputation)
	self.reputation = tonumber(newReputation)
	self:dispatchEvent({name = "updateReputation", reputation = self.reputation})
end

function Role:set_healthBuyCount(newHealthBuyCount)
	self.healthBuyCount = tonumber(newHealthBuyCount)
end

function Role:set_refreshLegendLimit(newValue)
	self.refreshLegendLimit = newValue
end

function Role:set_pvpRank(pvpRank)
	self.pvpRank = tonumber(pvpRank)
	self:dispatchEvent({name = "updatePvpRank", pvpRank = self.pvpRank})
end

function Role:setFriendCnt(friendCnt)
	self.friendCnt = friendCnt
	self:dispatchEvent({name = "updateFriendCnt", friendCnt = self.friendCnt})
end

function Role:set_mainHeroId(mainHeroId)
	self.mainHeroId = tonumber(mainHeroId)
	self:dispatchEvent({ name = "updateMainHeroId", mainHeroId = self.mainHeroId })
end

function Role:set_pveFormationJson(newFormationJson)
	self.pveFormationJson = newFormationJson
	self.pveFormation = json.decode(newFormationJson) or {}
end

function Role:set_lingpaiNum(lingpaiNum)
	self.lingpaiNum = tonumber(lingpaiNum)
	self:dispatchEvent({name = "updateLingpaiNum", lingpaiNum = self.lingpaiNum})
end

function Role:set_starPoint(starPoint)
	self.starPoint = tonumber(starPoint)
	self:dispatchEvent({name = "updateStarPoint", starPoint = self.starPoint})
end

function Role:set_starSoulNum(starSoulNum)
	self.starSoulNum = tonumber(starSoulNum)
	self:dispatchEvent({name = "updateStarSoulNum", starSoulNum = self.starSoulNum})
end

function Role:set_vipLevel(vipLevel)
	self.vipLevel = tonumber(vipLevel)
	self:dispatchEvent({name = "updateVipLevel", vipLevel = self.vipLevel})
end

function Role:set_rechargeRMB(rechargeRMB)
	self.rechargeRMB = tonumber(rechargeRMB)
	self:dispatchEvent({name = "updateRechargeRMB", rechargeRMB = self.rechargeRMB})
end

function Role:set_professionData(professionDataStr)
	self.profressionData = professionDataStr
	self.professionBonuses = json.decode(professionDataStr)
	self:dispatchEvent({name = "updateProfessionData"})
end

function Role:set_legendBattleLimit(legendBattleLimit)
	self.legendBattleLimit = legendBattleLimit
	self:dispatchEvent({ name = "updateLegendBattleLimit", legendBattleLimit = self.legendBattleLimit })
end

function Role:set_activedGuide(value)
	self.activedGuide = value
end

function Role:set_legendBuyCount(legendBuyCount)
	self.legendBuyCount = tonum(legendBuyCount)
end

function Role:set_levelGiftsJson(levelGiftsJson)
	self.levelGifts = json.decode(levelGiftsJson) or {}
end

function Role:set_serverGiftsJson(serverGiftsJson)
	self.serverGifts = json.decode(serverGiftsJson) or {}
end

function Role:set_shop1RefreshCount(shop1RefreshCount)
	self.shop1RefreshCount = tonum(shop1RefreshCount)
end

function Role:set_shop2RefreshCount(shop2RefreshCount)
	self.shop2RefreshCount = tonum(shop2RefreshCount)
end

function Role:set_shop3RefreshCount(shop3RefreshCount)
	self.shop3RefreshCount = tonum(shop3RefreshCount)
end

function Role:set_shop4RefreshCount(shop4RefreshCount)
	self.shop4RefreshCount = tonum(shop4RefreshCount)
end

function Role:set_shop5RefreshCount(shop5RefreshCount)
	self.shop5RefreshCount = tonum(shop5RefreshCount)
end

function Role:set_shop6RefreshCount(shop6RefreshCount)
	self.shop6RefreshCount = tonum(shop6RefreshCount)
end

function Role:set_shop7RefreshCount(shop7RefreshCount)
	self.shop7RefreshCount = tonum(shop7RefreshCount)
end

--招财活动次数
function Role:set_moneybuytimes(moneybuytimes)
	self.moneybuytimes = moneybuytimes
end

-- --当前战斗扣除体力：
-- function Role:set_oldHealth(oldHealth)
-- 	self.oldHealth = oldHealth
-- end

-- 每日任务
function Role:set_commonCarbonCount(commonCarbonCount)
	self.commonCarbonCount = tonum(commonCarbonCount)
end

function Role:set_specialCarbonCount(specialCarbonCount)
	self.specialCarbonCount = tonum(specialCarbonCount)
end

function Role:set_heroIntensifyCount(heroIntensifyCount)
	self.heroIntensifyCount = tonum(heroIntensifyCount)
end

function Role:set_pvpBattleCount(pvpBattleCount)
	self.pvpBattleCount = tonum(pvpBattleCount)
end

function Role:set_techLevelUpCount(techLevelUpCount)
	self.techLevelUpCount = tonum(techLevelUpCount)
end

function Role:set_beautyTrainCount(beautyTrainCount)
	self.beautyTrainCount = tonum(beautyTrainCount)
end

function Role:set_towerBattleCount(towerBattleCount)
	self.towerBattleCount = tonum(towerBattleCount)
end
--特殊副本--moneybattle
function Role:set_moneyBattleCount(moneyBattleCount)
	self.moneyBattleCount = tonum(moneyBattleCount)
end

function Role:set_expBattleCount(expBattleCount)
	self.expBattleCount = tonum(expBattleCount)
end

function Role:set_qunBattleCount(qunBattleCount)
	self.qunBattleCount = tonum(qunBattleCount)
end

function Role:set_weiBattleCount(weiBattleCount)
	self.weiBattleCount = tonum(weiBattleCount)
end

function Role:set_shuBattleCount(shuBattleCount)
	self.shuBattleCount = tonum(shuBattleCount)
end

function Role:set_wuBattleCount(wuBattleCount)
	self.wuBattleCount = tonum(wuBattleCount)
end

function Role:set_beautyBattleCount(beautyBattleCount)
	self.beautyBattleCount = tonum(beautyBattleCount)
end

function Role:set_qunBattleCD(qunBattleCD)
	self.qunBattleCD = tonum(qunBattleCD)
end

function Role:set_weiBattleCD(weiBattleCD)
	self.weiBattleCD = tonum(weiBattleCD)
end

function Role:set_shuBattleCD(shuBattleCD)
	self.shuBattleCD = tonum(shuBattleCD)
end

function Role:set_wuBattleCD(wuBattleCD)
	self.wuBattleCD = tonum(wuBattleCD)
end

function Role:set_beautyBattleCD(beautyBattleCD)
	self.beautyBattleCD = tonum(beautyBattleCD)
end

function Role:set_heroStarCount(heroStarCount)
	self.heroStarCount = tonum(heroStarCount)
end

function Role:set_legendBattleCount(legendBattleCount)
	self.legendBattleCount = tonum(legendBattleCount)
end

function Role:set_zhaoCaiCount(zhaoCaiCount)
	self.zhaoCaiCount = tonum(zhaoCaiCount)
end

function Role:set_yuekaCount(yuekaCount)
	self.yuekaCount = tonum(yuekaCount)
end

function Role:set_drawCardCount(drawCardCount)
	self.drawCardCount = tonum(drawCardCount)
end

function Role:set_trainCarbonCount(trainCarbonCount)
	self.trainCarbonCount = tonum(trainCarbonCount)
end

function Role:set_expeditionCount(expeditionCount)
	self.expeditionCount = tonum(expeditionCount)
end

function Role:set_guideStep(guideStep)
	self.guideStep = tonum(guideStep)
end

function Role:set_bagHeroBuyCount(bagHeroBuyCount)
	self.bagHeroBuyCount = tonum(bagHeroBuyCount)
end

function Role:set_slotsJson(slotsJson)
	self.slots = json.decode(slotsJson) or {}
	self:refreshHeroRelation()
end

function Role:set_partnersJson(partnersJson)
	self.partners = json.decode(partnersJson) or {}
	self:refreshHeroRelation()
end

function Role:set_skillOrderJson(skillOrderJson)
	self.skillOrder = json.decode(skillOrderJson) or {}
end

function Role:set_fundJson(fundJson)
	self.fund = json.decode(fundJson) or {}
	dump(self.fund)
end

function Role:set_firstRechargeJson(firstRechargeJson)
	self.firstRecharge = json.decode(firstRechargeJson) or {}
end

function Role:set_store1LeftTime(store1LeftTime)
	self.store1LeftTime = tonum(store1LeftTime)
	self.store1StartTime = self.store1LeftTime > 0 and game:nowTime() or 0
end

function Role:set_store3LeftTime(store3LeftTime)
	self.store3LeftTime = tonum(store3LeftTime)
	self.store3StartTime = self.store3LeftTime > 0 and game:nowTime() or 0
end

function Role:set_store2DailyCount(store2DailyCount)
	self.store2DailyCount = tonum(store2DailyCount)
end

function Role:set_store3DailyCount(store3DailyCount)
	self.store3DailyCount = tonum(store3DailyCount)
end

function Role:set_card1DrawFreeCount(newFreeCount)
	self.card1DrawFreeCount = tonum(newFreeCount)
end

function Role:set_card3DrawFreeCount(newFreeCount)
	self.card3DrawFreeCount = tonum(newFreeCount)
end

function Role:set_equipIntensifyCount(newCount)
	self.equipIntensifyCount = tonum(newCount)
end

function Role:set_sweepCount(sweepCount)
	self.sweepCount = tonum(sweepCount)
end

function Role:set_battleSpeed(battleSpeed)
	self.battleSpeed = tonum(battleSpeed)
end

function Role:set_firstRechargeAwardState(state)
	self.firstRechargeAwardState = tonum(state)
end

function Role:set_rechargeGiftsJson(rechargeGiftsJson)
	self.rechargeGifts = json.decode(rechargeGiftsJson) or {}
end

function Role:set_worldChatCount(worldChatCount)
	self.worldChatCount = worldChatCount
end

function Role:set_renameCount(renameCount)
	self.renameCount = renameCount
end

function Role:setStatus(status)
	self.status = status
end

function Role:addExp(deltaPoint)
	local csvData = roleInfoCsv:getDataByLevel(self.level + 1)
	if csvData == nil then return end
	
	local oldExp, oldLevel = self.exp, self.level
	local nowExp = oldExp + deltaPoint
	while nowExp >= csvData.upLevelExp do
		if not self:set_level(self.level + 1) then
			nowExp = csvData.upLevelExp
			break
		else
			nowExp = nowExp - csvData.upLevelExp
		end

		csvData = roleInfoCsv:getDataByLevel(self.level + 1)
	end

	self.exp = math.floor(nowExp)

	return oldLevel, self.level
end

function Role:updateTowerData(params)
	local updatedProperty = { roleId = self.id }
	for key, value in pairs(params) do
		self.towerData[key] = value
	end

	for key, value in pairs(self.towerData) do
		updatedProperty[key] = value
	end

	local bin = pb.encode("TowerData", updatedProperty)
	game:sendData(actionCodes.TowerDataSave, bin)
end

function Role:updateExpeditionFormation()
	self.yzFormationJson = json.encode(self.yzFormation)

	local updateFormation = { key = "yzFormationJson", newValue = self.yzFormationJson, roleId = self.id }
	local bin = pb.encode("RoleUpdateProperty", updateFormation)
	game:sendData(actionCodes.RoleUpdateProperty, bin, #bin)
end

function Role:updatePveFormation()
	self.pveFormationJson = json.encode(self.pveFormation)

	local updateFormation = { key = "pveFormationJson", newValue = self.pveFormationJson, roleId = self.id }
	local bin = pb.encode("RoleUpdateProperty", updateFormation)
	game:sendData(actionCodes.RoleUpdateProperty, bin, #bin)
end

function Role:updateGuideStep(step)
	-- if step < 100 then 
	-- 	if self.activedGuide == "" then
	-- 		for index = 1, 32 do
	-- 			self.activedGuide = self.activedGuide .. 0
	-- 		end
	-- 	end
	-- 	print(self.activedGuide)
	-- 	if string.byte(self.activedGuide, step) == 49 then return false end
	-- 	self.activedGuide = string.sub(self.activedGuide, 1, step-1) .. "1" .. string.sub(self.activedGuide, step+1)
	-- 	local bin = pb.encode("RoleUpdateProperty", { key = "activedGuide", newValue = self.activedGuide, roleId = self.id })
	-- 	game:sendData(actionCodes.RoleUpdateProperty, bin, #bin)
	-- end
	if self.guideStep ~= step then
		self.oldGuideStep = self.guideStep
		self.guideStep = step
		local bin = pb.encode("RoleUpdateProperty", { key = "guideStep", newValue = step, roleId = self.id })
		game:sendData(actionCodes.RoleUpdateProperty, bin, #bin)
	end
	return true
end

function Role:buildMapData(pbCarbons, pbMaps)
	pbMaps = pbMaps or {}
	pbCarbons = pbCarbons or {}

	for _, map in ipairs(pbMaps) do
		-- 构建地图类型信息
		local mapInfo = mapInfoCsv:getMapById(map.mapId)
		if mapInfo then
			self.mapTypeDataset[mapInfo.type] = self.mapTypeDataset[mapInfo.type] or {}
			self.mapTypeDataset[mapInfo.type][map.mapId] = self.mapTypeDataset[mapInfo.type][map.mapId] or {}
			self.mapTypeDataset[mapInfo.type][map.mapId].award1Status = map.award1Status
			self.mapTypeDataset[mapInfo.type][map.mapId].award2Status = map.award2Status
			self.mapTypeDataset[mapInfo.type][map.mapId].award3Status = map.award3Status
		end
	end

	for _, carbon in ipairs(pbCarbons) do
		local mapId = math.floor(carbon.carbonId / 100)

		-- 构建副本信息
		self.carbonDataset[carbon.carbonId] = self.carbonDataset[carbon.carbonId] or {}
		self.carbonDataset[carbon.carbonId].carbonId = carbon.carbonId
		self.carbonDataset[carbon.carbonId].starNum = carbon.starNum
		self.carbonDataset[carbon.carbonId].status = carbon.status
		self.carbonDataset[carbon.carbonId].playCnt = carbon.playCnt
		self.carbonDataset[carbon.carbonId].buyCnt = carbon.buyCnt

		-- 构建单个地图信息
		self.mapDataset[mapId] = self.mapDataset[mapId] or {}
		self.mapDataset[mapId][carbon.carbonId] = true
	end
end

-- 计算玩家给定职业的属性加成值
function Role:getProfessionBonus(profession)
	if not self.professionBonuses[profession] then
		return {0, 0, 0, 0, 0}
	end

	local phase = self.professionBonuses[profession][1]
	local totalAtkBonus, totalDefBonus, totalHpBonus, totalRestraintBonus, totalLingpaiNum = 0, 0, 0, 0, 0
	for p = 1, phase do
		-- atk
		local lMax = p < phase and 4 or self.professionBonuses[profession][2]
		for l = 1, lMax do
			local levelData = professionLevelCsv:getDataByLevel(profession, p, l)
			totalAtkBonus = totalAtkBonus + levelData.atkBonus
			totalLingpaiNum = totalLingpaiNum + levelData.lingpaiNum
		end

		-- def
		local lMax = p < phase and 4 or self.professionBonuses[profession][3]
		for l = 1, lMax do
			local levelData = professionLevelCsv:getDataByLevel(profession, p, l)
			totalDefBonus = totalDefBonus + levelData.defBonus
			totalLingpaiNum = totalLingpaiNum + levelData.lingpaiNum
		end

		-- hp
		local lMax = p < phase and 4 or self.professionBonuses[profession][4]
		-- 等级加成
		for l = 1, lMax do
			local levelData = professionLevelCsv:getDataByLevel(profession, p, l)
			totalHpBonus = totalHpBonus + levelData.hpBonus
			totalLingpaiNum = totalLingpaiNum + levelData.lingpaiNum
		end

		-- restraint
		local lMax = p < phase and 4 or self.professionBonuses[profession][5]
		for l = 1, lMax do
			local levelData = professionLevelCsv:getDataByLevel(profession, p, l)
			totalRestraintBonus = totalRestraintBonus + levelData.restraintBonus
			totalLingpaiNum = totalLingpaiNum + levelData.lingpaiNum
		end

		-- 进阶加成
		if p < phase then
			local phaseData = professionPhaseCsv:getDataByPhase(profession, p)
			totalAtkBonus = totalAtkBonus + phaseData.atkBonus
			totalDefBonus = totalDefBonus + phaseData.defBonus
			totalHpBonus = totalHpBonus + phaseData.hpBonus
			totalRestraintBonus = totalRestraintBonus + phaseData.restraintBonus

			totalLingpaiNum = totalLingpaiNum + phaseData.lingpaiNum
		end
	end
	return { totalAtkBonus, totalDefBonus, totalHpBonus, totalRestraintBonus, totalLingpaiNum }
end

function Role:getNextStarAttrId(starPoint)
	if (starPoint % 100 + 1) > 12 then
		local nextMapType = math.floor(starPoint / 100) + 1
		local nextMapData = heroStarInfoCsv:getDataByType(nextMapType)
		if not nextMapData then
			return nil
		end

		return nextMapType * 100 + 1
	end

	return starPoint + 1
end

function Role:calStarAttrBonuses(starPoint)
	if not starPoint then starPoint = self.starPoint end

	local attrBonuses = { [1] = {}, [2] = {}, [3] = {}, [4] = {} }
	-- 1 = 血, 2 = 攻, 3 = 防
	local starAttrName = { [1] = "hp", [2] = "atk", [3] = "def" }

	local beginPoint = 101
	if beginPoint > starPoint then return attrBonuses end

	while true do
		local starAttrData = heroStarAttrCsv:getDataById(beginPoint)
		attrBonuses[starAttrData.camp][starAttrName[starAttrData.attrId] .. "Bonus"] = 
			attrBonuses[starAttrData.camp][starAttrName[starAttrData.attrId] .. "Bonus"] or 0
		attrBonuses[starAttrData.camp][starAttrName[starAttrData.attrId] .. "Bonus"] = 
			attrBonuses[starAttrData.camp][starAttrName[starAttrData.attrId] .. "Bonus"] + starAttrData.attrValue

		beginPoint = self:getNextStarAttrId(beginPoint)
		if not beginPoint or beginPoint > starPoint then
			break
		end
	end

	return attrBonuses
end

-- 武将上限
function Role:getBagHeroLimit(level)
	return math.huge
end

-- 体力上限
function Role:getHealthLimit()
	local roleData = roleInfoCsv:getDataByLevel(self.level)
	local healthLimit = roleData and roleData.healthLimit or 50

	local vipData = vipCsv:getDataByLevel(self.vipLevel)
	if not vipData then return healthLimit end
	return healthLimit + vipData.healthLimit
end

-- 体力购买次数上限
function Role:getHealthBuyCount()
	local vipData = vipCsv:getDataByLevel(self.vipLevel)
	if not vipData then return 0 end

	return vipData.healthBuyCount
end

-- 战场次数上限
function Role:getPvpCountLimit()
	local pvpCount = globalCsv:getFieldValue("pvpCount")

	local vipData = vipCsv:getDataByLevel(self.vipLevel)
	if not vipData then return pvpCount end

	return pvpCount + vipData.pvpCount
end

-- 战场购买次数上限
function Role:getPvpBuyLimit()
	local pvpBuyCount = globalCsv:getFieldValue("pvpBuyLimit")

	local vipData = vipCsv:getDataByLevel(self.vipLevel)
	if not vipData then return pvpBuyCount end

	return pvpBuyCount + vipData.pvpBuyCount
end

-- 传奇副本购买次数上限
function Role:getLegendBuyLimit()
	local buyCount = globalCsv:getFieldValue("legendBuyLimit")

	local vipData = vipCsv:getDataByLevel(self.vipLevel)
	if not vipData then return buyCount end

	return buyCount + vipData.legendBuyCount
end

function Role:getChosenHeroNum()
	local num = 0
	table.foreach(self.heros, function(k, v) if v.choose > 0 then num = num + 1 end end)
	return num
end

function Role:getFightBeauties()
	local beauties = {}
	for _,beauty in pairs(self.beauties) do
		if beauty.status == beauty.class.STATUS_FIGHT then
			table.insert(beauties, beauty)
		end
	end
	return beauties
end

function Role:getFightBeautySkills()
	local skills, beauties = {}, {}
	for _,beauty in pairs(self.beauties) do
		if beauty.status == beauty.class.STATUS_FIGHT then
			local beautyData = beautyListCsv:getBeautyById(beauty.beautyId)

			if beauty.evolutionCount == 1 then
				table.insert(skills, beautyData.beautySkill1)
			elseif beauty.evolutionCount == 2 then
				table.insertTo(skills, {beautyData.beautySkill1, beautyData.beautySkill2})
			else
				table.insertTo(skills, {beautyData.beautySkill1, beautyData.beautySkill2, beautyData.beautySkill3})
			end

			table.insert(beauties, beauty)
		end
	end

	return skills, beauties
end

function Role:hasBeauty(beautyId)
	for _,beauty in pairs(self.beauties) do
		if beauty.beautyId == beautyId then
			return true
		end
	end
	return false
end

function Role:isHeroBagFull()
	if table.nums(self.heros) >= self:getBagHeroLimit() then
		return true
	end

	return false
end

function Role:addChat(chat)
	if chat.err == 0 then
		if table.nums(self.chats) == 50 then
			for index = 1, table.nums(self.chats) do
				self.chats[index] = self.chats[index + 1]
			end
			self.chats[50] = chat
		else
			self.chats[table.nums(self.chats) + 1] = chat
		end
	end

	self:dispatchEvent({name = "updateChat", msg = chat})
end

function Role:getHeroSlot(heroId)
	for slot, data in pairs(self.slots) do
		if data.heroId == heroId then
			return tonumber(slot)
		end
	end
	return 0
end

function Role:isChooseHeroType(heroType)
	for _, hero in ipairs(self.chooseHeros) do
		if hero.type == heroType then return true end
	end

	return false
end

function Role:getSelfFormationHeros()
	local heros = {}
	local selfHeroIndex = {}

	for index, heroId in pairs(self.pveFormation) do
		local hero = self.heros[heroId]
		if hero then
			selfHeroIndex[index] = true
			local attrValues = hero:getTotalAttrValues()
			local heroInfo = {
				id = heroId,
				type = hero.type,
				index = index,
				level = hero.level,
				evolutionCount = hero.evolutionCount,
				wakeLevel = hero.wakeLevel,
				star = hero.star,
				skillLevelJson = hero.skillLevelJson,
				skillOrder = table.keyOfItem(self.skillOrder, hero.id),
			}

			for key in pairs(EquipAttEnum) do
				heroInfo[key] = attrValues[key]
			end
			--兼容以前代码
			heroInfo.attack = heroInfo.atk
			heroInfo.defense = heroInfo.def
			table.insert(heros, heroInfo)
		end
	end

	return heros
end

function Role:updateNewMsgTag()
	-- 开服礼包
	if self.loginDays > table.nums(self.serverGifts) then
		self:dispatchEvent({ name = "notifyNewMessage", type = "serverGift", action = "add" })
	end

	-- 等级礼包
	for level, levelData in pairs(levelGiftCsv.m_data) do
		if self.level >= level and not self.levelGifts[tostring(level)] then
			self:dispatchEvent({ name = "notifyNewMessage", type = "levelGift", action = "add" })
			break
		end
	end

	-- 点将位置
	local roleInfo = roleInfoCsv:getDataByLevel(self.level)
	local curHeroNums = table.nums(self.chooseHeros)
	if curHeroNums < roleInfo.chooseHeroNum and table.nums(self.heros) > curHeroNums then
		self:dispatchEvent({ name = "notifyNewMessage", type = "chooseHero", action = "add" })
	else
		self:dispatchEvent({ name = "notifyNewMessage", type = "chooseHero", })
	end

	-- 点将的里面红点提示
	local addChoose = false
	for _, hero in ipairs(self.chooseHeros) do
		if hero:canEvolution() or hero:canBattleSoul() then
			addChoose = addChoose or true
 			-- hero:dispatchEvent({ name = "notifyNewMessage", type = "evolution", action = "add"})
		else
			-- hero:dispatchEvent({ name = "notifyNewMessage", type = "evolution",})
		end

		if hero:canStarUp() and roleInfo.heroStarUpOpen >= 0 then
			addChoose = addChoose or true
			-- hero:dispatchEvent({ name = "notifyNewMessage", type = "wakeup", action = "add"})
		else
			-- hero:dispatchEvent({ name = "notifyNewMessage", type = "wakeup" })
		end

		if hero:canSkillUp() then
			addChoose = addChoose or true
		end
	end
	if addChoose then
		self:dispatchEvent({ name = "notifyNewMessage", type = "chooseHero", action = "add" })
	end

	if not addChoose then
		for _, hero in pairs(self.heros) do
			if hero.choose == 0 and (hero:canEvolution() or hero:canBattleSoul() or (hero:canStarUp() and roleInfo.heroStarUpOpen >= 0) or hero:canSkillUp()) then
				addChoose = true
				break
			end
		end
	end
	if addChoose then
		self:dispatchEvent({ name = "notifyNewMessage", type = "heroList", action = "add" })
	end


	-- 每日任务
	if roleInfo.dailyTaskOpen >= 0 then
		local DailyTaskField = {
			[1] = { name = "commonCarbonCount", },
			[2] = { name = "specialCarbonCount", },
			[3] = { name = "heroIntensifyCount", },
			[4] = { name = "pvpBattleCount", },
			[5] = { name = "techLevelUpCount", },
			[6] = { name = "beautyTrainCount", },
			[7] = { name = "towerBattleCount", },
			[8] = { name = "heroStarCount", },
			[9] = { name = "legendBattleCount", },
			[10] = { name = "zhaoCaiCount", },
			[11] = { name = "yuekaCount" },
			[13] = { name = "equipIntensifyCount" },
			[14] = { name = "drawCardCount" },
			[15] = { name = "trainCarbonCount" },
			[16] = { name = "expeditionCount" },
		}
		local maxTaskNums = #DailyTaskField
		for taskId, data in pairs(dailyTaskCsv.m_data) do
			if taskId <= maxTaskNums then
				local taskData = dailyTaskCsv:getTaskById(taskId)
				if self[DailyTaskField[taskId].name] >= 0 and self.level >= data.openLevel then
					local finishCount = self[DailyTaskField[taskId].name]
					if finishCount >= taskData.count then
						local dispatch = true
						if taskId == 11 and self:isYuekaExpired() then
							dispatch = false
						end

						if dispatch then
							self:dispatchEvent({ name = "notifyNewMessage", type = "dailyTask", action = "add" })
							break
						end
					end
				end
			end
		end
	end

	-- 碎片
	for type, num in pairs(self.fragments) do
		-- 检查是否可以合成
		local unitData = unitCsv:getUnitByType(math.floor(type - 2000))
		if unitData and num >= globalCsv:getComposeFragmentNum(unitData.stars) then
			local dispatch = true
			
			if self.heros[unitData.type] then
				dispatch = false
			end

			if dispatch then
				self:dispatchEvent({ name = "notifyNewMessage", type = "composeFragment", action = "add" })
				break
			end
		end
	end


	-- 装备碎片
	for type, num in pairs(self.equipFragments) do
		-- 检查是否可以合成
		local equipData = equipCsv:getDataByType(type - Equip2ItemIndex.FragmentTypeIndex)
		if equipData and num >= equipData.composeNum then
			self:dispatchEvent({ name = "notifyNewMessage", type = "composeEquipFragment", action = "add" })
			break
		end
	end

	--基金
	if self.fund["isBought"] then
		local levels = table.keys(fundCsv.m_data)
		table.sort(levels)
		for _, level in ipairs(levels) do
			if not self.fund[tostring(level)] and level <= self.level then
				self:dispatchEvent({ name = "notifyNewMessage", type = "fund", action = "add" })
				break
			end
		end
	end

	--神将
	local ActiveMainLayer = require("scenes.activity.ActiveMainLayer")
	if self.firstLogin and not self.sendGodHero and ActiveMainLayer.inLimitTime(2, game:nowTime()) then
		self:dispatchEvent({ name = "notifyNewMessage", type = "godHero", action = "add" })
	end
end

function Role:processErrorCode(event)
	local msg = pb.decode("SysErrMsg", event.data)

	loadingHide()
	print("erro_code", msg.errCode)

	local flashErrorCodes = {
		[SYS_ERR_CARBON_PLAY_COUNT_LIMIT] = true,
		[SYS_ERR_TOWER_PLAY_COUNT_LIMIT] = true,
		[SYS_ERR_FRIEND_RECV_LIMIT]= true,
		[SYS_ERR_HEALTH_FULL] = true,
		[SYS_ERR_HERO_MAIN_LEVEL_LIMIT] = true,
		[SYS_ERR_MONEY_NOT_ENOUGH] = true, 
		[SYS_ERR_LINGPAI_NOT_ENOUGH] = true, 
		[SYS_ERR_STAR_SOUL_NOT_ENOUGH] = true,
		[SYS_ERR_PVP_BUY_COUNT_LIMIT] = true,
		[SYS_ERR_STORE_DAILY_BUY_LIMIT] = true,
		[SYS_ERR_HERO_BAG_BUY_LIMIT] = true,
		[SYS_ERR_HERO_BAG_LIMIT] = true,
		[SYS_ERR_FRIEND_VALUE_NOT_ENOUGH] = true,
		[SYS_ERR_FINAL_HEALTH_FULL] = true,
		[SYS_ERR_CHOOSE_SAME_TYPE_HERO] = true,
		[SYS_ERR_FRIEND_DONATE_HEALTH_LIMIT] = true,
	}

	if msg.errCode == SYS_ERR_YUANBAO_NOT_ENOUGH then
		DGMsgBox.new({ text = "元宝不够, 请捐赠票子", type = 2, button2Data = {
			text = "请充值",
			priority = -9000,
			callback = function() 
				local rechargeLayer = require("scenes.home.shop.ReChargeLayer").new({ priority = -9000 })
				rechargeLayer:getLayer():addTo(display.getRunningScene())
			end
		}})
	elseif msg.errCode == SYS_ERR_MONEY_NOT_ENOUGH then
		DGMsgBox.new({ msgId = 303, type = 2, button2Data = {
			text = "招财",
			priority = -9000,
			callback = function() 
				local getMoney = require("scenes.activity.GetMoneyLayer")
				getMoney.new({ priority = -9000 }):getLayer():addTo(display.getRunningScene())	
			end
		}})
	elseif flashErrorCodes[msg.errCode] then
		DGMsgBox.new({ msgId = msg.errCode })
	else
		-- 需要特殊处理
		self:dispatchEvent({ name = "ErrorCode" .. msg.errCode, errCode = msg.errCode, param1 = msg.param1,
			param2 = msg.param2, param3 = msg.param3, param4 = msg.param4 })
	end
end

function Role:isYuekaExpired()
	return game:nowTime() >= self.yuekaDeadline
end

function Role:refreshHeroRelation()
	--清除以前的情缘
	for _, hero in pairs(self.heros) do
		hero.relation = nil
	end
	--清除以前的装备到英雄的索引
	for _, equip in pairs(self.equips) do	
		equip.masterId = 0
	end
	-- 设置现在的激活的情缘
	--记录当前出战英雄的types集合
	local heroTypes = {}
	for _, value in pairs(self.slots) do
		local hero = self.heros[value.heroId]
		if hero then 
			table.insert(heroTypes, hero.type)
		end
	end
	--加入小伙伴types
	for _, heroType in pairs(self.partners) do
		if not heroType or heroType ~= 0 then
			table.insert(heroTypes, heroType)
		end
	end

	for slot, value in pairs(self.slots) do
		local hero = self.heros[value.heroId]
		local equipTypes = {}
		value.equips = value.equips or {}
		for _, equipId in pairs(value.equips) do
			table.insert(equipTypes, self.equips[equipId].type)
			self.equips[equipId].masterId = hero and hero.type or -1
		end
		if hero then
			hero.relation = {}
			if hero.unitData.relation then
				for _, relation in pairs(hero.unitData.relation) do
					if relation[1] == 1 and table.contain(heroTypes, relation[2]) then
						table.insert(hero.relation, relation)
					elseif relation[1] == 2 and table.contain(equipTypes, relation[2]) then
						table.insert(hero.relation, relation)
					end
				end
			end
		end
	end
end

function Role:heroExist(heroType)
	return self.heros[heroType] and true or false
end

function Role:isActiveRelation(heroType)
	for _, value in pairs(self.slots) do
		local hero = self.heros[value.heroId]
		if hero and hero.unitData.relation then
			for _, relation in ipairs(hero.unitData.relation) do
				if relation and relation[1] == 1 and table.find(relation[2], heroType) then
					return true
				end
			end
		end
	end
	return false
end

return Role