--
-- Author: yzm
-- Date: 2014-10-14 10:43:35
--玩家详情



local GlobalRes = "resource/ui_rc/global/"
local ExpeditonRes = "resource/ui_rc/expedition/"

local ChooseHeroLayer=import(".ChooseHeroLayer")

local PlayerInfor = class("PlayerInfor", function(params) 
	return display.newLayer(ExpeditonRes.."bg_playerDetail.png") 
end)

function PlayerInfor:ctor(params)
	self.params = params or {}

	self.curMapId=params.curMapId
	self.size = self:getContentSize()--CCSizeMake(962, 584)
	self.priority = params.priority or -129
	self.challenge=params.challenge or false

	self:initData()
	self:initMaskLayer()
	self:initContentLayer()
	
end

function PlayerInfor:initData()
	self.data=self.params.data or {}
end

-- 遮罩层
function PlayerInfor:initMaskLayer()

	-- 遮罩层
	self:anch(0.5, 0.5):pos(display.cx, display.cy)
	self.maskLayer = DGMask:new({ item = self , priority = self.priority, ObjSize = self.size, clickOut = function() self.maskLayer:remove() end })

end

-- 内容层
function PlayerInfor:initContentLayer()
	if self.contentLayer then
		self.contentLayer:removeSelf()
	end

	self.contentLayer = display.newLayer()
	self.contentLayer:setContentSize(self:getContentSize())
	self.contentLayer:addTo(self)

	local contentText= "[color=FFFFFFFF][color=FFFFD200]lv%s.[/color][color=FFFFFFFF]%s[/color]([color=FF7CE810]%s[/color]/15)[/color]"
	local titleLabel=ui.newTTFRichLabel({ text = string.format(contentText,self.data.level,self.data.name,self.data.id),  size = 24,font=ChineseFont})
		:anch(0,0.5):pos(28,162):addTo(self.contentLayer)

	local gap=10

	-- dump(self.data.heroList)
	for index,soldier in ipairs(self.data.heroList) do
		if soldier then
			local headBtn 
			headBtn = HeroHead.new(
				{
					type = soldier.heroId,
					blood=soldier.blood,
					wakeLevel = soldier.wakeLevel,
					star = soldier.star,
					evolutionCount = soldier.evolutionCount,
					callback = function() 
						
					end,
				})
			headBtn:setEnable(false)
			
			headBtn:getLayer():pos(-80+index*100+gap*index,30):addTo(self.contentLayer)

			--local nat=math.floor(index/3)
			--headBtn:getLayer():pos(initX+(index%3)*100+gap*(index%3),270-100*nat-nat*gap):addTo(self.contentLayer)
			--index=index+1
		end
		
	end

	--dump(self.data)
	--挑战
	if self.challenge then
		local challengeBtn=DGBtn:new(ExpeditonRes,{"chenllengbtn_normal.png","chenllengbtn_pressed.png"},{
			--text = { text = "挑战", size = 26, font = ChineseFont, color=display.COLOR_WHITE, strokeColor = display.COLOR_FONT, strokeSize = 2},
			priority = self.priority-10,
			callback = function()
				local chooseHerolLayer=ChooseHeroLayer.new({priority=self.priority-11,curMapId=self.curMapId,curMapData=self.data})
				chooseHerolLayer:getLayer():addTo(display.getRunningScene())
				self:getLayer():removeSelf()
			end}):getLayer()
		challengeBtn:anch(0.5,0.5):pos(self:getContentSize().width-90,80):addTo(self.contentLayer)
	end
	
	
end


function PlayerInfor:getLayer()
	return self.maskLayer:getLayer()
end

function PlayerInfor:onExit()
end


return PlayerInfor