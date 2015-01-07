local GuideRes = "resource/ui_rc/guide/"

local GuideTipsLayer = class("GuideTipsLayer", function()
	return CCLayerExtend.extend(CCSimpleRookieGuide:create())
end)

function GuideTipsLayer:ctor(params)
	params = params or {}

	-- rect 和 node 只传其一
	self.rect = params.rect
	self.node = params.node
	self.guideBtn = params.guideBtn or params.node
	if self.node then
		local worldPos = self.node:convertToWorldSpace(ccp(0, 0))
		local size = self.node:getContentSize()
		local scale = self.node:getScale()
		self.rect = CCRectMake(worldPos.x, worldPos.y, size.width * scale, size.height * scale)
	end

	self.guideData = guideCsv:getGuideById(params.guideId)
	self.onClick = params.onClick
	self:initLayer(params)
	self:zorder(1000)

	if params.opacity and params.opacity == 0 then
		self:hide()
	end
	self:setBgColor(ccc4(0, 0, 0, params.opacity or 0))	

	if self:isVisible() and not params.notDelay then
		self:hide()
		self:runAction(transition.sequence({
			CCDelayTime:create(0.15),
			CCShow:create()
		}))
	end

	local nextGuideId, curGuideId = self.guideData.nextGuideId, self.guideData.guideId
	if self.guideData.type == 0 and self.guideBtn then
		-- print("加入事件", curGuideId)
		self.btnClickHandle = game:addEventListener("btnClicked", function(event)
			-- print("收到按钮点击事件，是否是确定？", self.guideBtn == event.data)
			if self.guideBtn == event.data then
				-- print("激活下一步", nextGuideId)
				self:removeSelf()
				game:activeGuide(nextGuideId, curGuideId)
				if self.onClick then
					self.onClick()
				end
			end
		end)
	end	
end

function GuideTipsLayer:playFadeIn()
	local opacityTable = {}
	local setOpacity
	setOpacity = function(node, opacity, first)
		if first then
			opacityTable[node] = node:getOpacity()
		else
			node:setOpacity(math.min(opacity, opacityTable[node]))
		end
	
		local children = node:getChildren()
		local childsNum = node:getChildrenCount()
		for index = 0, childsNum - 1 do
			local child = tolua.cast(children:objectAtIndex(index), "CCNode")
			setOpacity(child, opacity, first)
		end
	end
	local count = 1
	local opacity = 255
	setOpacity(self, 0, true)
	self:runAction(CCRepeatForever:create(transition.sequence({
		CCDelayTime:create(0.03),
		CCCallFunc:create(function() 
			setOpacity(self, count * opacity / 10, false)
			count = count + 1
			if count > 10 then
				self:stopAllActions()
			end
		end)
	})))
end

function GuideTipsLayer:clickFunc()
	local nextGuideId, curGuideId = self.guideData.nextGuideId, self.guideData.guideId
	--type 0:点击触发下一步, 1:战斗胜利触发下一步
	if self.guideData.type > 0 then
		
		game:addEventListener("battleWin", function()
			game:activeGuide(nextGuideId, curGuideId)
			return "__REMOVE__"
		end)

		if self.onClick then
			self.onClick()
		end
		self:removeSelf()
	elseif not self.guideBtn then
		game:activeGuide(nextGuideId, curGuideId)
		if self.onClick then
			self.onClick()
		end
		self:removeSelf()
	end	
end

function GuideTipsLayer:initLayer(params)
	local nodeSize
	if self.rect then
		self:addRegion(self.rect, nil, true)
		nodeSize = self.rect.size
	else
		self:addRegion(self.node, nil, true)

		nodeSize = self.node:getContentSize()
	end

	self.arrow = display.newSprite(GuideRes .. "arrow.png")
	self:setArrow(self.arrow)

	local arrowSize = self.arrow:getContentSize()

	local distance = math.abs(math.sin(self.guideData.degree)) == 0 and (nodeSize.width + arrowSize.width) / 2
		or (nodeSize.height + arrowSize.height) / 2

	self:pointToRegionCenter(0, distance + self.guideData.distance, self.guideData.degree)

	if math.abs(self.guideData.degree) == 90 then
		self.arrow:runAction(CCRepeatForever:create(transition.sequence({
				CCMoveBy:create(0.4, ccp(0,-20)),
				CCMoveBy:create(0.4, ccp(0,20))
			})))
	else
		self.arrow:runAction(CCRepeatForever:create(transition.sequence({
				CCMoveBy:create(0.4, ccp(-20,0)),
				CCMoveBy:create(0.4, ccp(20,0))
			})))
	end

	--加入一个看不见的按钮
	DGBtn:new(GuideRes, {}, {
		priority = self:getTouchPriority(),
		swallowsTouches = false,
		soundOff = true,
		checkContain = params.checkContain,
		callback = function()
			-- print("点击新手引导隐藏按钮")	
			self:clickFunc()
		end
	}):getLayer():size(self.rect.size):pos(self.rect.origin.x, self.rect.origin.y):addTo(self)
	



	-- 对话
	if self.guideData.beautyTips ~= "" then
		local beauty = display.newSprite(GuideRes .. "beauty_new.png")
		local beautySize = beauty:getContentSize()
		local textLabel = ui.newTTFLabel({ text = self.guideData.beautyTips, size = 22, color = display.COLOR_WHITE, dimensions = CCSizeMake(230, 115) })
			:anch(0.5, 0.5):pos(373, 95):addTo(beauty)

		local isFlipX = self.guideData.flipX == 2
		beauty:setRotationY(isFlipX and 180 or 0)
		textLabel:setRotationY(isFlipX and 180 or 0)
		beauty:addTo(self):anch(isFlipX and 1 or 0, 0):scale(1)
			:pos(tonum(self.guideData.beautyPos[1]) + display.cx, tonum(self.guideData.beautyPos[2])-20)

	end
end

function GuideTipsLayer:setArrowVisible(visible)
	self.arrow:setVisible(visible)
end

function GuideTipsLayer:showHand(from, to)
	self.handSprite = display.newSprite(GuideRes .. "arrow.png")
	self.handSprite:setRotation(-90)
	self.handSprite:pos(from.x, from.y):addTo(self)

	self.handSprite:runAction(CCRepeatForever:create(transition.sequence({
			CCMoveTo:create(1.5, to),
			CCFadeOut:create(0.5),
			CCCallFunc:create(function()
					self.handSprite:setOpacity(255)
					self.handSprite:setPosition(from)
				end)
		})))
end

function GuideTipsLayer:onCleanup()
	if game.role then
		game.role:removeEventListener("btnClicked", self.btnClickHandle)
	end
end

return GuideTipsLayer