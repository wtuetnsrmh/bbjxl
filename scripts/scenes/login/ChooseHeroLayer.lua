local HomeRes = "resource/ui_rc/home/"
local GlobalRes = "resource/ui_rc/global/"
local LoginRes = "resource/ui_rc/login_rc/"
local ChooseRes = "resource/ui_rc/login_new/"
local AwardRes = "resource/ui_rc/carbon/award/"

local BattlePlotLayer = require("scenes.battle.BattlePlotLayer")
local BattleLoadingLayer=require("scenes.BattleLoadingLayer")

local ChooseHeroLayer = class("ChooseHeroLayer", function()
	return display.newLayer(AwardRes .. "box_small_bg.png")
end)

function ChooseHeroLayer:ctor(params)
	self.params = params or {}
	self.size = self:getContentSize()
	self.priority = params.priority or -98
	self.chooseStep = params.chooseStep or "start"

	self.mask = DGMask:new({ item = self, priority = self.priority + 1, bg = HomeRes .. "home.jpg" })
	self:anch(0.5,0.5):pos(display.cx, display.cy)
	self:hide()

	if not OPEN_STAR_BATTLE then 
		self.chooseStep = "chooseBorn" 
	end
		
	if self.chooseStep == "start" then
		local battleLoadingLayer
		battleLoadingLayer = BattleLoadingLayer.new({ priority = -128,showText=true,
			callback = function()
				
			end,
			loadingInfo = {
				
			}
		})
		battleLoadingLayer:getLayer():addTo(self.mask:getLayer())
		local actions={}
		actions[#actions+1]=CCDelayTime:create(1)
		actions[#actions+1]=CCRemoveSelf:create()
		actions[#actions+1]=CCCallFunc:create(function()
			local plotLayer = BattlePlotLayer.new({ carbonId = 10000, phase = 1, onComplete = handler(self, self.showStartFight)})
			plotLayer:anch(0.5,0):pos(display.cx, 0):addTo(self.mask:getLayer())
		end)
		battleLoadingLayer:getLayer():runAction(transition.sequence(actions))
		
	elseif self.chooseStep == "chooseBorn" then
		local plotLayer = BattlePlotLayer.new({ carbonId = 20001, phase = 1, onComplete = handler(self, self.showTextField)})
		plotLayer:anch(0.5,0):pos(display.cx, 0):addTo(self.mask:getLayer())
	end
end

function ChooseHeroLayer:getLayer()
	return self.mask:getLayer()
end

--跳转至战斗
function ChooseHeroLayer:showStartFight()
	switchScene("battle", {battleType = BattleType.Start , angryUnitNum = 2.5, angryCD = 1500 })
end

--显示输入框部分
function ChooseHeroLayer:showTextField(params)
	self:show()
	--标题
	display.newSprite(ChooseRes .. "name_tips_text.png")
		:anch(0.5, 1):pos(self.size.width/2, self.size.height - 15):addTo(self)
	--起名框
	local yy = 60
	local boxbg = display.newSprite(ChooseRes .. "name_bg.png")
	boxbg:anch(0.5, 0.5):pos(self.size.width/2, self.size.height/2):addTo(self)
	local boxSize = boxbg:getContentSize()

	local nameInputBox = ui.newEditBox({
		image = LoginRes .. "input_null.png",
		 size = CCSize(355, 39),
		listener = function(event, editbox)
			if event == "began" then
			elseif event == "ended" then
			elseif event == "return" then
			elseif event == "changed" then
			end
		end
	})
	nameInputBox:setFontColor(display.COLOR_DARKYELLOW)
	nameInputBox:setReturnType(kKeyboardReturnTypeSend)
	nameInputBox:anch(0.5, 0.5):pos(boxSize.width/2, boxSize.height/2 - 5):addTo(boxbg)
	nameInputBox:setMaxLength(12)
	nameInputBox:setFontColor(uihelper.hex2rgb("#0ff0e8"))
	nameInputBox:setFontSize(28)
	nameInputBox:setTag(7676)
	nameInputBox:setText("请输入角色名")

	local function randomNameRequest()
		local bin = pb.encode("SimpleEvent", { })
		game:sendData(actionCodes.RoleRandomNameRequest, bin)
		game:addEventListener(actionModules[actionCodes.RoleRandomNameResponse], function(event)
			local msg = pb.decode("RoleDetail", event.data)
			nameInputBox:setText(msg.name)

			return "__REMOVE__"
		end)
	end
	randomNameRequest()

	--随机名字
	local randomBut = DGBtn:new(ChooseRes, {"random_sel.png","random_nor.png"},
		{	
			scale = 1.1,
			priority = self.priority,
			callback = function()
				randomNameRequest()
			end,
		})
		randomBut:getLayer()
		:anch(0.5, 0.5)
		:addTo(boxbg)
		:pos(boxSize.width, boxSize.height/2)

	local confirmBtn = DGBtn:new(GlobalRes, {"middle_normal.png", "middle_selected.png"},
		{	
			text = { text ="确定", font = ChineseFont, size = 30, strokeColor = display.COLOR_FONT, strokeSize = 2 },
			priority = self.priority,
			callback = function()
				local userName = nameInputBox:getText()
				if #userName == 0 or userName == "请输入角色名" then
					DGMsgBox.new({ type = 1, text = "请输入名字" })
					return
				end

				self.roleName = nameInputBox:getText()

				local errorStr = ChooseHeroLayer.sIsNewNameRight(self.roleName)

				if errorStr ~= nil then
					DGMsgBox.new({ type = 1, text = errorStr })
					return
				end

				if game.tcpSocket then
					local bin = pb.encode("RoleCreate", { uid = game.platform_uid, 
						name = self.roleName, heroType = self.chooseHeroType, uname = game.platform_uname,
						packageName = PACKAGE_NAME, deviceId = game.device })
					game:sendData(actionCodes.RoleCreate, bin)
					loadingShow(true)
					game:addEventListener(actionModules[actionCodes.RoleCreateResponse], handler(self, self.createRoleResponse))
				end
			end,
		})
	confirmBtn:getLayer():anch(0.5, 0):addTo(self)
		:pos(self.size.width/2, 20)
end

function ChooseHeroLayer:createRoleResponse(event)
	loadingHide()

	local msg = pb.decode("RoleCreateResponse", event.data)

	if msg.result == "DB_ERROR" then
	elseif msg.result == "EXIST" then
		DGMsgBox.new({ type = 1, text = "名字已存在！请换个名字吧~" })
	elseif msg.result == "ILLEGAL_NAME" then
		DGMsgBox.new({ type = 1, text = "名字中含有敏感字！请换个名字吧~" })
	else
		GameState.save(GameData)
		-- 登录玩家
		local bin = pb.encode("RoleLoginData", { name = self.roleName, packageName = PACKAGE_NAME,
			deviceId = game.device })
		game:sendData(actionCodes.RoleLoginRequest, bin)
		loadingShow()
		game:addEventListener(actionModules[actionCodes.RoleLoginResponse], function(event)
			socketActions:roleLoginResponse(event, { create = true })
		end)
		print("成功创建角色。。。")
	end
	return "__REMOVE__"
end

--随机产生名称：
function ChooseHeroLayer:randomNameStr()
	local newName = nil
	local advRecord = nameCombCsv:getAdvs()
	local fNameRecord = nameCombCsv:getFNames()
	local nameRecord = nameCombCsv:getNames()

	local i1 = math.random(tonumber(advRecord[1].advid) , tonumber(advRecord[#advRecord].advid))
	local i2 = math.random(tonumber(fNameRecord[1].fid) , tonumber(fNameRecord[#fNameRecord].fid))
	local i3 = math.random(tonumber(nameRecord[1].nid) , tonumber(nameRecord[#nameRecord].nid))

	local adv = nameCombCsv:getAdvByIndex(i1).adv
	local fname = nameCombCsv:getFNameByIndex(i2).fname
	local name = nameCombCsv:getNameByIndex(i3).name
	newName = adv..fname..name

	if newName and string.utf8len(newName) < 7 then
		return tostring(newName)
	else
		self:randomNameStr()
	end

end

--长度限制
local function lengthOfString(nameStr)
	
	local len = string.utf8len(nameStr)
  	for s in string.gfind(nameStr, "[\128-\254]+") do
  		len = len + string.utf8len(s)
  	end
  	return (len < 13 and len > 5) and true or false 
end

--非法字符
local function forbidCharacterJudge(nameStr)
	if string.find(nameStr, " ") then
		return false
	end

	for _, data in pairs(nameNonCsv:getAllData()) do
		if string.find(nameStr, data.name, 1, true) then
			return false
		end
	end 
	return true
end  

--1.长度校验（小于6汉字和12字符） 2.敏感词汇校验  3.重复校验
function ChooseHeroLayer.sIsNewNameRight(newNameStr)

	local errStr = nil

	if not lengthOfString(newNameStr) then
		errStr = "长度控制在6至12个字符之间！"
		return errStr
	end

	if not forbidCharacterJudge(newNameStr) then
		errStr = "名字中含有敏感字！请换个名字吧~"
		return errStr
	end

	-- if false then
	-- 	errStr = "名称已占用！"
	-- 	return errStr
	-- end

	return errStr

end 


--重复
function ChooseHeroLayer:isAlreadyExist(s)

end

function ChooseHeroLayer:onCleanup()
	game:removeAllEventListenersForEvent(actionModules[actionCodes.RoleCreateResponse])

--	CCArmatureDataManager:purge()
	display.removeUnusedSpriteFrames()
	armatureManager:dispose()
end

return ChooseHeroLayer