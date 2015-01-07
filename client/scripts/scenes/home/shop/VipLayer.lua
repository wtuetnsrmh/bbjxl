local ShopRes = "resource/ui_rc/shop/"
local VipRes = "resource/ui_rc/shop/vip/" 
local RechargeRes = "resource/ui_rc/shop/recharge/"
local ActivityRes = "resource/ui_rc/activity/"

local VipLayer = class("VipLayer", function(params)
	return display.newLayer(ActivityRes .. "bg.jpg")
end)

function VipLayer:ctor(params)
	params = params or {}
	self.priority = params.priority or -130

	self.size = self:getContentSize()

	self:anch(0.5, 0):pos(display.cx, 20)
	self.mask = DGMask:new({ item = self, priority = self.priority + 1 })

	self.w = self:getContentSize().width;
	self.h = self:getContentSize().height;

	self:createVipNode(1)

	local frame = display.newSprite(ActivityRes .. "bg_frame.png")
	frame:anch(0.5, 0):pos(self.w / 2, -10):addTo(self, 10)
	--title
	display.newSprite(VipRes.."desc_text.png"):anch(0.5,1):pos(frame:getContentSize().width / 2, frame:getContentSize().height - 15):addTo(frame)

	--close btn
	local closeBtn = DGBtn:new(GlobalRes, {"close_normal.png", "close_selected.png"},
		{	
			touchScale = 1.5,
			priority = self.priority - 2,
			callback = function()
				self:getLayer():removeSelf()
			 end,
		}):getLayer()
	closeBtn:anch(1, 1):pos((display.width + 960) / 2, display.height):addTo(self:getLayer())

	--girle bg 
	display.newSprite(VipRes.."vip_beauty.png"):pos(140,290):addTo(self, 20) -- .mainLayer
end

function VipLayer:createVipNode(vipLevel)
	if self.mainLayer then
		self.mainLayer:removeSelf()
	end

	self.mainLayer = display.newLayer()
	self.mainLayer:size(self.size):addTo(self)
	local topBgSize = CCSizeMake(650, 200)


	local posY = 460
	local xBegin = 60
	local vipLevelScroll = DGScrollView:new({size = CCSizeMake(topBgSize.width - 2 * xBegin, 100),
		divider = 15, horizontal = true, dataSource = vipCsv.m_data, priority = self.priority - 1 })
	self.totalBt={}
	for level = 1, table.nums(vipCsv.m_data) - 1 do
		local levelRes = string.format("recharge/vip_text_%d.png", level)
		local vipBtn = DGBtn:new(ShopRes, {levelRes},
			{
				priority = self.priority,
				scale = 1,
				parent = vipLevelScroll:getLayer(),
				callback = function()
					self.scrollOffset = vipLevelScroll:getOffset()
					self:setContentByIndex(level)
				end,
			}):getLayer()
		self.totalBt[level]=vipBtn

		vipLevelScroll:addChild(vipBtn)
	end
	vipLevelScroll:alignCenter()
	vipLevelScroll:getLayer():anch(0, 0.5):pos(330, posY)
		:addTo(self.mainLayer)
	vipLevelScroll:setOffset(self.scrollOffset or 0)

	--间隔线：
	--display.newSprite(VipRes.."splitter.png"):pos(670,400):addTo(self.mainLayer)

	--左右箭头：
	local leftFlag = DGBtn:new(VipRes, {"arrow_left.png", "arrow_left.png"},
		{	
			priority = self.priority,
			callback = function()
				
			end,
		})
	leftFlag:getLayer():anch(0.5, 0.5):pos(vipLevelScroll:getLayer():getPositionX() - leftFlag:getLayer():getContentSize().width, posY)
	:addTo(self.mainLayer)

	local closeBtn = DGBtn:new(VipRes, {"arrow_right.png", "arrow_right.png"},
		{	
			priority = self.priority,
			callback = function()
			end,
		})
	closeBtn:getLayer():anch(0.5, 0.5):pos(vipLevelScroll:getLayer():getPositionX() + vipLevelScroll:getLayer():getContentSize().width + leftFlag:getLayer():getContentSize().width, posY)
	:addTo(self.mainLayer)

	local vipTextBg=display.newSprite(VipRes.."text_bg.png"):pos(290+590/2,380):addTo(self.mainLayer)
	--wordsp 特权：
	self.vipText=display.newSprite(VipRes..string.format("vip_%d.png",vipLevel)):pos(vipTextBg:getContentSize().width/2-30,15):addTo(vipTextBg)
	--wordLayer 当前特权
	self.curVip=display.newSprite(VipRes.."specilText.png"):anch(0,0.5)
		:pos(self.vipText:getPositionX()+self.vipText:getContentSize().width/2,self.vipText:getPositionY()):addTo(vipTextBg)

	--left dirtribution 这个需要mac模拟器测试；
	local vsize = CCSizeMake(590, 330)
	local content = CCFileUtils:sharedFileUtils():getFileDataXXTEA(string.format("txt/VIP/vip_describe_%d.txt", vipLevel))
	self.descLabel = ui.newTTFRichLabel({ text = content, dimensions = vsize, size = 22,
		valign = ui.TEXT_VALIGN_TOP })

	self.descScroll = CCScrollView:create()
    self.descScroll:setViewSize(vsize)
    self.descScroll:ignoreAnchorPointForPosition(true)
    self.descScroll:setContainer(self.descLabel)
    self.descScroll:updateInset()
    self.descScroll:setContentOffset(ccp(0, vsize.height - self.descLabel:getContentSize().height))
    self.descScroll:setDirection(kCCScrollViewDirectionVertical)
    self.descScroll:setClippingToBounds(true)
    self.descScroll:setTouchPriority(self.priority - 1)
	self.descScroll:setAnchorPoint(ccp(0, 0))
    self.descScroll:setPosition(ccp(330, 20))
	self.mainLayer:addChild(self.descScroll)

	self:setContentByIndex(1)
end

function VipLayer:setContentByIndex(vipLevel)
	local tempTexture=CCTextureCache:sharedTextureCache():addImage(
        VipRes..string.format("vip_%d.png",vipLevel))
	self.vipText:setTexture(tempTexture)

	for _,bt in pairs(self.totalBt) do
		bt:removeChildByTag(1000)
	end
	display.newSprite(ShopRes .. "vip/halo.png"):addTo(self.totalBt[vipLevel],1,1000)
		:pos(self.totalBt[vipLevel]:getContentSize().width / 2, self.totalBt[vipLevel]:getContentSize().height / 2)

	self.totalContent=self.totalContent or {}
	local function returnContent()
		return CCFileUtils:sharedFileUtils():getFileDataXXTEA(string.format("txt/VIP/vip_describe_%d.txt", vipLevel))
	end
	local content=self.totalContent[vipLevel] or returnContent()
	self.totalContent[vipLevel]=content

	local vsize = CCSizeMake(590, 330)
	self.descLabel:setString(tostring(content))
	self.descScroll:updateInset()
    self.descScroll:setContentOffset(ccp(0, vsize.height - self.descLabel:getContentSize().height))
	
end

function VipLayer:getLayer()
	return self.mask:getLayer()
end

return VipLayer