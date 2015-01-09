local GlobalRes = "resource/ui_rc/global/"
local LoginRes = "resource/ui_rc/login_rc/"

local RenameLayer = class("RenameLayer", function() return display.newLayer(GlobalRes .. "panel_small.png") end)

function RenameLayer:ctor(params)
	params = params or {}
	self.priority = params.priority
	local bgSize = self:getContentSize()

	self:anch(0.5, 0.5):pos(display.cx, display.cy)
	self.mask = DGMask:new({ item = self, priority = self.priority + 1,ObjSize = self:getContentSize(),
		click = function()
		end,
		clickOut = function()
			-- self:removeAllChildren()
			-- self:getLayer():removeFromParent()
		end,})

	--tile bg
	local title = display.newSprite(GlobalRes.."title_bar.png"):anch(0.5, 1):pos(bgSize.width/2, bgSize.height - 12):addTo(self)
	--tile word
	display.newSprite(LoginRes.."cname_title.png"):pos(title:getContentSize().width/2, title:getContentSize().height/2):addTo(title)
	--random saizi

	--input tip
	ui.newTTFLabelWithStroke({text = "请主公输入新昵称", size = 32, color = uihelper.hex2rgb("#fffc00"), strokeColor = display.COLOR_FONT})
		:anch(0.5, 0):pos(bgSize.width/2, 213):addTo(self)

	--cost tip
	local tipsBg = display.newSprite(GlobalRes .. "label_middle_bg.png")
	tipsBg:anch(0.5, 0):pos(bgSize.width/2, 96):addTo(self)

	ui.newTTFLabel({ text = "修改昵称需要", size = 20 })
		:anch(0, 0.5):pos(12, tipsBg:getContentSize().height/2):addTo(tipsBg)

	--cost num
	local changeData = functionCostCsv:getFieldValue("cNameCost")
	local firstRename = game.role.renameCount == 0
	local costNum = firstRename and 0 or (changeData and changeData.initValue or 100)
	ui.newTTFLabel({ text = tostring(costNum), size = 20, color = costNum <= game.role.yuanbao and uihelper.hex2rgb("#7ce810") or display.COLOR_RED})
		:anch(1, 0.5):pos(240, tipsBg:getContentSize().height/2):addTo(tipsBg)

	--yuanbao bg
	display.newSprite(GlobalRes.."yuanbao.png"):anch(0, 0.5):pos(255, tipsBg:getContentSize().height/2):addTo(tipsBg)

	--input bg 
	local boxbg = display.newSprite(LoginRes .. "cname_input_bg.png")
	boxbg:anch(0.5, 0.5):pos(bgSize.width/2, bgSize.height/2):addTo(self)

	local nameInputBox
	self:performWithDelay(function()
		--input content 
		local ixx , iyy = self:getPositionX(),self:getPositionY()
		nameInputBox = ui.newEditBox({
		image = LoginRes .. "input_null.png",
		size = CCSize(350, 35),
		listener = function(event, editbox)
			if event == "began" then
				self:runAction(CCMoveTo:create(0.1, ccp(ixx, iyy)))
			elseif event == "ended" then

			elseif event == "return" then
				self:runAction(CCMoveTo:create(0.1, ccp(ixx, iyy + 200)))
			elseif event == "changed" then
			end
		end
		})

		CCDirector:sharedDirector():getRunningScene():setTouchPriority(self.priority - 1)
		nameInputBox:setFontColor(display.COLOR_GREEN)
		nameInputBox:setReturnType(kKeyboardReturnTypeSend)
		nameInputBox:anch(0.5, 0.5):pos(boxbg:getContentSize().width/2 + 10, boxbg:getContentSize().height/2 - 5):addTo(boxbg)
		nameInputBox:setMaxLength(12)
		nameInputBox:setTouchPriority(self.priority - 10)
		nameInputBox:setTag(7676)
		-- nameInputBox:setPlaceHolder("请输入新名字")
	end, 0.1)
	


	local posY = 25
	local offset = 100
	local canselBut = DGBtn:new(GlobalRes, {"middle_normal.png", "middle_selected.png"},
			{	
				priority = self.priority -1,
				text = { text = "取消", size = 28, font = ChineseFont, strokeColor = display.COLOR_FONT, strokeSize = 2},
				callback = function()
					self:removeAllChildren()
					self:getLayer():removeSelf()
				end,
			}):getLayer()
		canselBut:anch(0.5, 0):pos(bgSize.width/2 - offset, posY):addTo(self)


	local sureBut = DGBtn:new(GlobalRes, {"btn_green_nol.png", "btn_green_sel.png"},
		{	
			priority = self.priority -1,
			text = { text = "确定", size = 28, font = ChineseFont, strokeColor = display.COLOR_FONT, strokeSize = 2},
			callback = function()
				local ChooseHeroLayer = require("scenes.login.ChooseHeroLayer")
				local errorStr = ChooseHeroLayer.sIsNewNameRight(nameInputBox:getText())
				if errorStr ~= nil then
					DGMsgBox.new({ type = 1, text = errorStr })
					return
				end
				
				if game.role.yuanbao >= tonumber(costNum) then
					local useRequest = { roleId = game.role.id,param1 = nameInputBox:getText()}
					local bin = pb.encode("RenameEvent", useRequest)
					game:sendData(actionCodes.RoleRenameRequest, bin, #bin)
					game:addEventListener(actionModules[actionCodes.RoleRenameRequest], function(event)
						local msg = pb.decode("RenameEvent", event.data)
						print("msg.param2 === ",msg.param2)
						if msg.param2 == 200 then
							self:removeAllChildren()
							self:getLayer():removeFromParent()
						elseif msg.param2 == 1 then
							DGMsgBox.new({ type = 1, text = "名字已存在！请换个名字吧~"})
						elseif msg.param2 == 2 then
							DGMsgBox.new({ type = 1, text = "元宝数量不足！"})
						elseif msg.param2 == 3 then
							DGMsgBox.new({ type = 1, text = "名字中含有敏感字！请换个名字吧~"})
						end
						return "__REMOVE__"
					end)
				else
					DGMsgBox.new({ type = 1, text = "元宝数量不足哦！"})
				end		
			end,
		}):getLayer()
	sureBut:anch(0.5, 0):pos(bgSize.width/2 + offset, posY):addTo(self)
	--提示：
	-- local descLabel = ui.newTTFRichLabel({ 
	-- 	text = "长度控制在6---12个字符之间！", 
	-- 	align = ui.TEXT_ALIGN_CENTER, 
	-- 	dimensions = CCSizeMake(500, 80), 
	-- 	color = display.COLOR_DARKYELLOW,
	-- 	size = 22,
	-- 	 })
	-- descLabel:anch(0.5, 0):pos(240, 10):addTo(self)

end

function RenameLayer:getLayer()
	return self.mask:getLayer()
end

function RenameLayer:onCleanup()
	display.removeUnusedSpriteFrames()
end

return RenameLayer