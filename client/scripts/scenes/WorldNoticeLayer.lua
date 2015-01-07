local HomeRes = "resource/ui_rc/home/"

local scheduler = require("framework.scheduler")

local WorldNoticeLayer = class("WorldNoticeLayer", function(params)
	 return display.newLayer(HomeRes .. "world_notice_bg.png") 
end)

function WorldNoticeLayer:ctor(params)
	params = params or {}

	self.priority = params.priority or -130
	self.size = self:getContentSize()
	local yPos = display.cy + 120
	self:anch(0, 0.5):pos(display.width, yPos):addTo(display.getRunningScene(), 9999)

	self.text = ui.newTTFRichLabel({text = params.text, size = 24})
	self.text:anch(0.5, 0.5):pos(self.size.width/2, self.size.height/2):addTo(self)
	self:runAction(transition.sequence({
		CCEaseIn:create(CCMoveTo:create(0.2, ccp(display.width/2 - self.size.width/2, yPos)), 2),
		CCDelayTime:create(2),
		CCMoveTo:create(2, ccp(-self.size.width, yPos)),
		CCCallFunc:create(function()
			self.autoExit = true
			self:removeSelf()
			if params.closeCallback then
				params.closeCallback()
			end
		end),
	}))
end

function WorldNoticeLayer:onExit()
	if not self.autoExit then
		--不是主动删除，为场景切换，需要重新添加
		self:removeFromParentAndCleanup(false)
		CCDirector:sharedDirector():getActionManager():pauseTarget(self)
		self.newMsgUpdate = scheduler.scheduleGlobal(function()
			scheduler.unscheduleGlobal(self.newMsgUpdate)
			self:addTo(display.getRunningScene())
			CCDirector:sharedDirector():getActionManager():resumeTarget(self) 
		end, 0.1)
	end
end

return WorldNoticeLayer
