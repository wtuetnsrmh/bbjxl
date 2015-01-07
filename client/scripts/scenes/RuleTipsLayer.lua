local GlobalRes = "resource/ui_rc/global/"

local RuleTipsLayer = class("RuleTipsLayer", function(params)
	return display.newSprite(GlobalRes .. "rule/rule_bg.png")
end)

function RuleTipsLayer:ctor(params)
	params = params or {}

	self.priority = params.priority or -130
	self.size = self:getContentSize()

	self:pos(display.cx, display.cy)
	self.mask = DGMask:new({item = self, priority = self.priority + 1, ObjSize = self.size,
		clickOut = function() self:getLayer():removeSelf() end })

	local titleBg = display.newSprite(GlobalRes .. "title_bar.png")
	display.newSprite(GlobalRes .. "rule/rule_title.png"):addTo(titleBg)
		:pos(titleBg:getContentSize().width / 2, titleBg:getContentSize().height / 2)

	titleBg:anch(0.5, 1):pos(self.size.width / 2, self.size.height - 15):addTo(self)

	local textBg = display.newSprite(GlobalRes .. "rule/rule_contenbg.png")
	local textBgSize = textBg:getContentSize()

	textBg:anch(0.5, 0):pos(self.size.width / 2, 30):addTo(self)

	local labelString = params.text
	if params.file then
		local content = CCFileUtils:sharedFileUtils():getFileDataXXTEA(params.file)

		labelString = content
		if params.args and #params.args > 0 then
			labelString = string.format(content, unpack(params.args))
		end
	end

	local ruleScroll = CCScrollView:create()
    local function scrollView1DidScroll()
    end
    local function scrollView1DidZoom()
    end
    ruleScroll:setViewSize(CCSizeMake(textBgSize.width, textBgSize.height - 10))
    ruleScroll:ignoreAnchorPointForPosition(true)
	local label = ui.newTTFRichLabel({text = labelString, size = 24, dimensions = CCSizeMake(textBgSize.width - 30, textBgSize.height),})-- dimensions = showSize,
    ruleScroll:setContainer(label)
    ruleScroll:updateInset()
    ruleScroll:setContentOffset(ccp(0, textBgSize.height - label:getContentSize().height))
    ruleScroll:setDirection(kCCScrollViewDirectionVertical)
    ruleScroll:setClippingToBounds(true)
    ruleScroll:setTouchPriority(self.priority - 1)
    ruleScroll:registerScriptHandler(scrollView1DidScroll,CCScrollView.kScrollViewScroll)
    ruleScroll:registerScriptHandler(scrollView1DidZoom,CCScrollView.kScrollViewZoom)
	ruleScroll:setAnchorPoint(ccp(0, 0))
    ruleScroll:setPosition(ccp(10, 5))
	textBg:addChild(ruleScroll)
end

function RuleTipsLayer:getLayer()
	return self.mask:getLayer()
end

return RuleTipsLayer