-- pvp战场
-- by yangkun
-- 2014.7.2

local HomeRes = "resource/ui_rc/home/"
local GlobalRes = "resource/ui_rc/global/"
local PvpRes = "resource/ui_rc/pvp/"
local CarbonRes = "resource/ui_rc/carbon/"
local HeroRes = "resource/ui_rc/hero/"

local RankLayer = import(".RankLayer")
local PvpShopLayer = import(".PvpShopLayer")
local RuleTipsLayer = import("..RuleTipsLayer")
local RoleDetailLayer = import("..RoleDetailLayer")

local PvpHomeLayer = class("PvpHomeLayer", function()
	return display.newLayer()
end)

function PvpHomeLayer:ctor(params)
	params = params or {}
	self.priority = params.priority or -130

	self.bgSize = CCSize(908,577)
	self:initUI()

	local xBegin = 30
	local xInterval = (869 - 164 * 5) / 6 + 164

	local bin = pb.encode("SimpleEvent", { roleId = game.role.id })
	game:sendData(actionCodes.PvpSearchMatchRequest, bin)
	loadingShow()
	game:addEventListener(actionModules[actionCodes.PvpSearchMatchResponse], function(event)
		loadingHide()
		local msg = pb.decode("MatchRolesResponse", event.data)
		game.role:set_pvpRank(msg.pvpRank)

		local topLayer = self:createTopLayer()
		topLayer:anch(0,1):pos(0, self.bgSize.height):addTo(self)

		msg.matchRoles = msg.matchRoles or {}
		table.sort(msg.matchRoles, function(a, b) return a.pvpRank > b.pvpRank end)
		for index, opponentInfo in ipairs(msg.matchRoles) do
			local opponentCell = self:createOpponentCell(index, opponentInfo)
			opponentCell:anch(0, 1):pos(xBegin + xInterval * (index - 1), self.bgSize.height - 65)
				:addTo(self)
		end

		self.reports = msg.reports

		table.sort(self.reports, function(a,b) return a.createTime > b.createTime end )
		local resultLayer = self:createResultLayer()
		resultLayer:anch(0.5, 0):pos(self.bgSize.width / 2, 30):addTo(self)

		return "__REMOVE__"
	end)

	params.opponents = params.opponents or {}

	if params.showShop then
		local shopLayer = PvpShopLayer.new({priority = self.priority - 10, shopIndex = 5})
		shopLayer:getLayer():addTo(display.getRunningScene())
	end

	self:checkGuide()
end

function PvpHomeLayer:initUI()

	local TopBarLayer = require("scenes.TopBarLayer")
	local layer  = TopBarLayer.new({priority = self.priority})
	:anch(0,1):pos(0,display.height):addTo(self)

	self.innerBg = display.newSprite(PvpRes .. "frame_red.png")
	self.size = self.innerBg:getContentSize()
	self.innerBg:anch(0.5,0.5):pos(self.size.width/2, self.size.height/2+5):addTo(self)

	-- 遮罩层
	self:anch(0, 0):pos((display.width - 960) / 2, 0)
	self.mask = DGMask:new({ item = self, priority = self.priority + 1 })

	local closeBtn = DGBtn:new(GlobalRes, {"close_normal.png", "close_selected.png"},
		{	
			touchScale = 1.5,
			priority = self.priority,
			callback = function()
				switchScene("home")
			end,
		}):getLayer()
	closeBtn:anch(0.7, 0.5):pos(self.size.width, self.size.height):addTo(self,100)

	self.tabCursor = display.newSprite(GlobalRes .. "tab_arrow.png")
	self.tabCursor:anch(0, 0.5):pos(self.size.width - 25, 470):addTo(self,100)

	local tabRadio = DGRadioGroup:new()
	local pvpBtn = DGBtn:new(GlobalRes, {"tab_normal.png", "tab_selected.png"},
		{	
			priority = self.priority,
			callback = function()
			end
		}, tabRadio)
	pvpBtn:getLayer():anch(0, 0.5):pos(self.size.width - 14, 470):addTo(self)
	
	local tabSize = pvpBtn:getLayer():getContentSize()
	ui.newTTFLabelWithStroke({ text = "战场", dimensions = CCSizeMake(tabSize.width / 2, tabSize.height), size = 26, font = ChineseFont,
		color = display.COLOR_WHITE, strokeColor = uihelper.hex2rgb("#242424") })
		:pos(tabSize.width / 2, tabSize.height / 2):addTo(pvpBtn:getLayer())

	-- 战功商店
	local shopBtn = DGBtn:new(GlobalRes, {"vertical_normal.png", "vertical_selected.png", "vertical_disabled.png"},
		{	
			priority = self.priority,
			front=PvpRes.."text_shop.png",
			touchScale = { 2, 1 },
			callback = function()
				local shopLayer = PvpShopLayer.new({priority = self.priority - 10, shopIndex = 5})
				shopLayer:getLayer():addTo(display.getRunningScene())
			end,
		}):getLayer()
	shopBtn:anch(0, 0.5):pos(self.size.width - 13, 360):addTo(self)

	-- 排行榜
	local rankBtn = DGBtn:new(GlobalRes, {"vertical_normal.png", "vertical_selected.png", "vertical_disabled.png"},
		{	
			priority = self.priority,
			touchScale = { 2, 1 },
			callback = function()
				local RankMainLayer = require("scenes.home.rank.RankMainLayer")
				local layer = RankMainLayer.new({ parent = self, priority = self.priority - 10, tag = 2 })
				layer:getLayer():addTo(display.getRunningScene())
			end,
		}):getLayer()
	rankBtn:anch(0, 0.5):pos(self.size.width - 13, 250):addTo(self)
	ui.newTTFLabelWithStroke({ text = "排行榜", dimensions = CCSizeMake(tabSize.width / 2, tabSize.height), size = 22, font = ChineseFont,
		color = display.COLOR_WHITE, strokeColor = uihelper.hex2rgb("#242424") })
		:pos(tabSize.width / 2, tabSize.height / 2):addTo(rankBtn)

	-- 规则
	local ruleBtn = DGBtn:new(GlobalRes, {"vertical_normal.png", "vertical_selected.png", "vertical_disabled.png"},
		{	
			priority = self.priority,
			--front = PvpRes .. "text_rule.png",
			touchScale = { 2, 1 },
			callback = function()
				local giftData = pvpGiftCsv:getGiftData(game.role.pvpRank)
				local ruleLayer = RuleTipsLayer.new({ priority = self.priority - 100, 
					file = "txt/function/pvp_rule.txt",
					args = { giftData.money, giftData.yuanbao, giftData.zhangong }
				})
				ruleLayer:getLayer():addTo(display.getRunningScene())	
			end,
		}):getLayer()
	ruleBtn:anch(0, 0.5):pos(self.size.width - 13, 140):addTo(self)
	ui.newTTFLabelWithStroke({ text = "规则", dimensions = CCSizeMake(tabSize.width / 2, tabSize.height), size = 26, font = ChineseFont,
		color = display.COLOR_WHITE, strokeColor = uihelper.hex2rgb("#242424") })
		:pos(tabSize.width / 2, tabSize.height / 2):addTo(ruleBtn)
end

function PvpHomeLayer:createTopLayer()
	local tempLayer = display.newLayer()
	tempLayer:size(CCSizeMake(self.size.width,52))

	display.newSprite(PvpRes .. "bar_1.png"):anch(0,0.5):pos(30,26):addTo(tempLayer)
	ui.newTTFLabel({ text = "我的排名:", size = 20, font = ChineseFont, color = display.COLOR_WHITE })
		:anch(0, 0.5):pos(50, tempLayer:getContentSize().height/2 ):addTo(tempLayer)
	ui.newTTFLabel({ text = string.format("%d", game.role.pvpRank), size = 20, font = ChineseFont, color = uihelper.hex2rgb("#7ce810")})
		:anch(0, 0.5):pos(135, tempLayer:getContentSize().height/2 ):addTo(tempLayer)

	local infoBg = display.newLayer()
	infoBg:size(CCSizeMake(473, 38))
	infoBg:anch(0,0):pos(197, 0):addTo(tempLayer)
	local infoSize = infoBg:getContentSize()

	display.newSprite(PvpRes .. "bar_1.png"):anch(0,0.5):pos(20,26):addTo(infoBg)
	display.newSprite(GlobalRes .. "label_middle_bg.png"):anch(1,0.5):pos(infoSize.width+197, 26):addTo(infoBg)

	display.newSprite(PvpRes .. "zhangong.png"):anch(0.5,0.5):pos(70, 26):addTo(infoBg)
	self.zhangongLabel = ui.newTTFLabel({text = game.role.zhangongNum, size = 20, color = display.COLOR_WHITE})
	:anch(0,0.5):pos(100, 26):addTo(infoBg)
	self.zhangongUpdateHandler = game.role:addEventListener("updateZhangongNum", function(event)
			self.zhangongLabel:setString(event.zhangongNum)
		end)

	-- pvp 次数
	local pvpCountValue = ui.newTTFLabel({ text = "挑战次数: ", size = 20, color = display.COLOR_WHITE })
	pvpCountValue:anch(0, 0.5):pos(390, 26):addTo(infoBg)
	local pvpCountLable=ui.newTTFLabel({text=game.role.pvpCount,size=20,color=uihelper.hex2rgb("#7ce810")})
	pvpCountLable:anch(0,0.5):pos(pvpCountValue:getPositionX()+pvpCountValue:getContentSize().width,pvpCountValue:getPositionY()):addTo(infoBg)
	self.pvpCntHandler = game.role:addEventListener("updatePvpCount", function(event)
		pvpCountLable:setString(event.pvpCount)
		if event.pvpCount == 0 then
			pvpCountValue:setColor(display.COLOR_RED)
		end
	end)
	local addPvpCountBtn = DGBtn:new(HomeRes, {"add.png","add_pressed.png"},
		{	
			priority = self.priority,
			scale = 1.05,
			callback = function()
				local buyLimit = game.role:getPvpBuyLimit()
				if buyLimit > 0 and game.role.pvpBuyCount >= buyLimit then
					DGMsgBox.new({ msgId = 100 })
				else
					local costYuanbao = functionCostCsv:getCostValue("pvpCount", game.role.pvpBuyCount)
					
					local showText = string.format(sysMsgCsv:getMsgbyId(101).text, costYuanbao)
					DGMsgBox.new({ text = showText, type = 2,
						button2Data = {
							callback = function()
								-- 通知服务端
								local bin = pb.encode("SimpleEvent", { roleId = game.role.id })
								game:sendData(actionCodes.PvpBuyCount, bin)
							end,
						}
					})
				end
			end,
		}):getLayer()
	addPvpCountBtn:anch(0, 0.5):pos(pvpCountValue:getPositionX() + pvpCountValue:getContentSize().width+10, 26):addTo(infoBg)

	-- cd时间
	local eraseCdBtn = DGBtn:new(PvpRes, {"erase_cd.png","erase_cd_pressed.png"},
		{	
			scale = 1.05,
			priority = self.priority,
			callback = function()
				local vipData = vipCsv:getDataByLevel(game.role.vipLevel)
				local leftSeconds = game:nowTime() - PVP_CD_TIME > game.role.lastPvpTime and 0 or game.role.lastPvpTime + PVP_CD_TIME - game:nowTime()
				leftSeconds = (vipData and vipData.pvpCd) and 0 or leftSeconds
				if leftSeconds <= 0 then return end

				local showText = string.format(sysMsgCsv:getMsgbyId(102).text, functionCostCsv:getFieldValue("eraseCdTime").initValue)
				DGMsgBox.new({ text = showText, type = 2, 
					button2Data = {
						callback = function()
							local erasePvpCdTimeRequest = { roleId = game.role.id, }
							local bin = pb.encode("SimpleEvent", { roleId = game.role.id })
							game:sendData(actionCodes.PvpEraceCdTime, bin)
						end,
					}
				})
			end,
		}):getLayer()
	eraseCdBtn:anch(1, 0.5):pos(infoBg:getPositionX()+infoSize.width - 5, 26):addTo(infoBg)

	local cdTimeLabel = ui.newTTFLabel({ text = "", size = 20, color = uihelper.hex2rgb("#7ce810")})
	local vipData = vipCsv:getDataByLevel(game.role.vipLevel)
	local leftSeconds = game:nowTime() - PVP_CD_TIME > game.role.lastPvpTime and 0 or game.role.lastPvpTime + PVP_CD_TIME - game:nowTime()
	leftSeconds = (vipData and vipData.pvpCd) and 0 or leftSeconds
	self.pvpCdTimeHandler = game.role:addEventListener("updateLastPvpTime", function(event)
		leftSeconds = game:nowTime() - PVP_CD_TIME > event.lastPvpTime and 0 or event.lastPvpTime + PVP_CD_TIME - game:nowTime()
	end)

	local setCdTime
	setCdTime = function()
		if leftSeconds > 0 then
			cdTimeLabel:setColor(uihelper.hex2rgb("#7ce810"))
		else
			cdTimeLabel:setColor(display.COLOR_WHITE)
		end

		if leftSeconds > 0 then
			leftSeconds = leftSeconds - 1
			local _, minutes, second = timeConvert(leftSeconds)
			cdTimeLabel:setString(string.format("%02d", minutes) .. ":" .. string.format("%02d", second))
			cdTimeLabel:runAction(transition.sequence({
				CCDelayTime:create(1),
				CCCallFunc:create(setCdTime),
			}))
		else
			cdTimeLabel:setString("00:00")
		end
	end
	setCdTime()
	cdTimeLabel:anch(1, 0.5):pos(infoBg:getPositionX()+infoSize.width  - eraseCdBtn:getContentSize().width, 26)
		:addTo(infoBg)

	return tempLayer
end

function PvpHomeLayer:createOpponentCell(index, opponentInfo)
	local itemBg = display.newSprite(PvpRes .. "item_bg.png")
	local itemSize = itemBg:getContentSize()

	ui.newTTFLabelWithStroke({ text = opponentInfo.name,font=ChineseFont , size = 22, color = display.COLOR_WHITE, strokeSize = 2,strokeColor=display.COLOR_BUTTON_STROKE })
		:anch(0.5, 1):pos(itemSize.width / 2, itemSize.height - 10):addTo(itemBg)
	ui.newTTFLabelWithStroke({ text = "Lv." .. opponentInfo.level, size = 20, color = uihelper.hex2rgb("#ffff00"),strokeColor=display.COLOR_BUTTON_STROKE  })
		:anch(0.5, 1):pos(itemSize.width / 2, itemSize.height - 35):addTo(itemBg)

	local headFrame = HeroHead.new({ 
		type = opponentInfo.mainHeroType, 
		wakeLevel = opponentInfo.mainHeroWakeLevel,
		star = opponentInfo.mainHeroStar,
		evolutionCount = opponentInfo.mainHeroEvolutionCount,
		priority = self.priority - 1,
		callback = function()
			local bin = pb.encode("SimpleEvent", { roleId = opponentInfo.id })
			game:sendData(actionCodes.RoleDigestInfoRequest, bin)
			game:addEventListener(actionModules[actionCodes.RoleDigestInfoResponse], function(event)
				local roleDigest = pb.decode("RoleLoginResponse", event.data)
				local roleDigestLayer = RoleDetailLayer.new({ priority = self.priority - 10, roleDigest = roleDigest })
				roleDigestLayer:getLayer():addTo(display.getRunningScene())

				return "__REMOVE__"
			end)
		end
	}):getLayer()
	headFrame:anch(0.5, 0):pos(itemSize.width / 2, 129):addTo(itemBg)

	ui.newTTFLabelWithStroke({ text = opponentInfo.pvpRank, size = 26, color = uihelper.hex2rgb("#ffff00"), strokeSize = 2,strokeColor=display.COLOR_BUTTON_STROKE }):pos(itemSize.width / 2, 110):addTo(itemBg)

	local challengeBtn = DGBtn:new(GlobalRes, {"middle_normal.png", "middle_selected.png","middle_disabled.png"},
		{
			priority = self.priority,
			text = { text = "挑战", size = 28, font = ChineseFont, color=display.COLOR_WHITE, strokeColor = display.COLOR_BUTTON_STROKE, strokeSize = 2},
			callback = function()
				-- 检查次数
				if game.role.pvpCount <= 0 then
					if game.role.pvpBuyCount >= game.role:getPvpBuyLimit() then
						DGMsgBox.new({ msgId = 100 })
						return
					else
						local showText = string.format(sysMsgCsv:getMsgbyId(101).text, functionCostCsv:getCostValue("pvpCount", game.role.pvpBuyCount))
						DGMsgBox.new({ text = showText, type = 2,
							button2Data = {
								callback = function()
									local bin = pb.encode("SimpleEvent", { roleId = game.role.id })
									game:sendData(actionCodes.PvpBuyCount, bin)
								end,
							}
						})
						return
					end
				end

				local function chooseRequest()
					local chooseOpponent = {
						roleId = game.role.id,
						opponentRoleId = opponentInfo.id,
						opponentRank = opponentInfo.pvpRank
					}
					local bin = pb.encode("ChoosePvpOpponent", chooseOpponent)
					game:sendData(actionCodes.PvpChooseOpponent, bin)
					loadingShow()
					game:addEventListener(actionModules[actionCodes.PvpFormationInfo], function(event)
						local msg = pb.decode("BattleData", event.data)
						loadingHide()

						local opponentHeros = {}

						for _, hero in ipairs(msg.heros) do
							local attrs = json.decode(hero.attrsJson)
							local pvpHero = {
								id = hero.id,
								type = hero.type,
								index = hero.index,
								level = hero.level,
								evolutionCount = hero.evolutionCount,
								skillLevelJson = hero.skillLevelJson,
								skillOrder = hero.skillOrder ~= 0 and hero.skillOrder or nil,
							}
							table.merge(pvpHero, attrs)
							pvpHero.attack = pvpHero.atk
							pvpHero.defense = pvpHero.def
							table.insert(opponentHeros, pvpHero)
						end

						switchScene("battle", { battleType = BattleType.PvP, opponentRoleId = msg.roleId, 
							rightPassiveSkills = msg.passiveSkills, rightBeauties = msg.beauties,
							rightHeros = opponentHeros })

						return "__REMOVE__"
					end)
				end

				local vipData = vipCsv:getDataByLevel(game.role.vipLevel)
				--vip特权
				local isVipEnough = vipCsv:getDataByLevel(game.role.vipLevel).pvpCd
				if not tobool(isVipEnough) then
					-- 检查CD
					local leftSeconds = game:nowTime() - PVP_CD_TIME > game.role.lastPvpTime and 0 or game.role.lastPvpTime + PVP_CD_TIME - game:nowTime()
					if leftSeconds > 0 and (vipData and not vipData.pvpCd) then
						local showText = string.format(sysMsgCsv:getMsgbyId(102).text, functionCostCsv:getFieldValue("eraseCdTime").initValue)
						DGMsgBox.new({ text = showText, type = 2, 
							button2Data = {
								callback = function()
									local erasePvpCdTimeRequest = { roleId = game.role.id, }
									local bin = pb.encode("SimpleEvent", { roleId = game.role.id })
									game:sendData(actionCodes.PvpEraceCdTime, bin)
									game.role:addEventListener("updateLastPvpTime", function(event)
										chooseRequest()
										return "__REMOVE__"
									end)
								end,
							}
						})
						return
					end
				end

				chooseRequest()
			end,
		})
	challengeBtn:getLayer():anch(0.5, 0):pos(itemSize.width / 2, 14):addTo(itemBg)

	return itemBg
end

function PvpHomeLayer:createResultLayer()
	local awardBg = display.newSprite(PvpRes .. "text_bg.png")

	local function createPvpReport(battleReport)
		-- 1. 防守成功
		-- 2. 防守失败
		-- 3. 进攻成功
		-- 4. 进攻失败
		
		local result, text
		local attack = game.role.id == battleReport.roleId
		if attack then
			if battleReport.deltaRank == 0 then -- 进攻失败
				result = 4
			elseif battleReport.deltaRank < 0 then
				result = 5
			else
				result = 3
			end
		else
			if battleReport.deltaRank == 0 then
				result = 1
			elseif battleReport.deltaRank > 0 then
				result = 2
			else
				result = 6
			end
		end

		local resultText = {
			[1] = { 
				content = "[%s]在竞技场挑战你，你战胜了他，守住了排名", 
				label = "竞技场防守成功",
				btnText = "固若金汤",
			},
			[2] = { 
				content = "[%s]在竞技场挑战你，你战败了，排名下降 %d 名",
				label = "竞技场防守失败",
				btnText = "纸老虎",
			},
			[3] = { 
				content = "你在战场挑战[%s]，你战胜了他，排名上升 %d 名，获得了 %d 战功", 
				label = "竞技场进攻成功",
				btnText = "势不可挡",
			},
			[4] = { 
				content = "你在战场挑战[%s]，你战败了，排名不变，获得了 %d 战功",
				label = "竞技场进攻失败",
				btnText = "无语",
			},
			[5] = { 
				content = "你在战场挑战[%s]，你战胜了他，排名不变，获得了 %d 战功",
				label = "竞技场进攻成功",
				btnText = "无语",
			},
			[6] = { 
				content = "[%s]在竞技场挑战你，你战败了，排名不变",
				label = "竞技场防守失败",
				btnText = "无语",
			},
		}

		local content
		if attack then
			if result == 3 then
				content = string.format(resultText[result].content, battleReport.opponentRoleName, battleReport.deltaRank, battleReport.zhangong)
			else
				content = string.format(resultText[result].content, battleReport.opponentRoleName, battleReport.zhangong)
			end
		else
			content = string.format(resultText[result].content, battleReport.roleName, battleReport.deltaRank)
		end

		local resultLabel = ui.newTTFLabelWithStroke({ text = content, color = display.COLOR_WHITE, size = 20, strokeSize = 2,strokeColor=display.COLOR_BUTTON_STROKE})

		return resultLabel
	end

	local startY = 110
	local hasContent = false
	for index = 1, 3 do
		local report = self.reports[index]
		if report then
			hasContent = true
			local label = createPvpReport(report)
			label:anch(0,0):pos(30,startY - (index - 1) * 40):addTo(awardBg)
		end
	end

	if not hasContent then
		ui.newTTFLabelWithStroke({ text = "暂无战报，快去挑战吧！", color = display.COLOR_WHITE, font = ChineseFont, size = 30, strokeSize = 2, strokeColor=display.COLOR_BUTTON_STROKE })
		:anch(0,0):pos(30, startY):addTo(awardBg)
	end

	return awardBg
end

function PvpHomeLayer:checkGuide()

end

function PvpHomeLayer:getLayer()
	return self.mask:getLayer()
end

function PvpHomeLayer:onExit()
	game.role:removeEventListener("updateLastPvpTime", self.pvpCdTimeHandler)
	game.role:removeEventListener("updatePvpCount", self.pvpCntHandler)
	game.role:removeEventListener("updateZhangongNum", self.zhangongUpdateHandler)
end

return PvpHomeLayer