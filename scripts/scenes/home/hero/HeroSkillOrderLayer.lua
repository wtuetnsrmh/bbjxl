local GlobalRes = "resource/ui_rc/global/"
local HeroRes = "resource/ui_rc/hero/"
local HeroChooseRes = "resource/ui_rc/hero/choose/"
local HeroRelationLayer = import(".HeroRelationLayer")
local HeroPartnerChooseLayer = import(".HeroPartnerChooseLayer")

local HeroSkillOrderLayer = class("HeroSkillOrderLayer", function(params) 
	return display.newLayer(HeroRes .. "skill_order_bg.png") 
end)

function HeroSkillOrderLayer:ctor(params)

	params = params or {}

	self.priority = params.priority or -129
	self.size = self:getContentSize()
	self:anch(0.5,0.5):pos(display.cx, display.cy)
	self.mask = DGMask:new({ item = self, priority = self.priority, ObjSize = self.size, clickOut = function()
		self:remove()
	end})

	self.xBegin, self.xInterval = 40, 127
	ui.newTTFLabel({text = "自动战斗中，武将技能将按照分配顺序循环自动释放", size = 18, color = uihelper.hex2rgb("#ffeecd")})
		:anch(0.5, 1):pos(self.size.width/2, self.size.height - 27):addTo(self)
	self:initUI()
	--确定
	local btn = DGBtn:new(GlobalRes, {"btn_ellipse_normal.png", "btn_ellipse_selected.png"}, {
		priority = self.priority - 1,
		text = {text = "确定", size = 26, font = ChineseFont, strokeColor = display.COLOR_FONT},
		callback = function()
			self:remove()
		end,
		}):getLayer()
	btn:anch(0.5, 0):pos(self.size.width/2, 36):addTo(self)
end

function HeroSkillOrderLayer:remove()
	local function updateSkillOrder()
		if self.changed then
			local bin = pb.encode("RoleUpdateProperty", { key = "skillOrderJson", newValue = json.encode(game.role.skillOrder), roleId = game.role.id })
			game:sendData(actionCodes.RoleUpdateProperty, bin, #bin)
		end
		self.mask:remove()
	end

	if table.nums(game.role.chooseHeros) ~= table.nums(game.role.skillOrder) then
		DGMsgBox.new({text = "还有武将未进行技能顺序配置，自动战斗中该武将将不释放技能，是否确定？", type = 2, 
			button2Data = {
				callback = function()
					updateSkillOrder()
				end
			},
		})
	else
		updateSkillOrder()
	end
end

function HeroSkillOrderLayer:initUI()
	if self.mainLayer then
		self.mainLayer:removeSelf()
	end
	self.mainLayer = display.newLayer()
	self.mainLayer:size(self.size):addTo(self)

	self:initChoosedHeros()
	self:initSkillOrderHeros()
end

function HeroSkillOrderLayer:initChoosedHeros()	
	--武将
	local count = 1
	for index = 1, 5 do
		local hero = game.role.heros[checkTable(game.role.slots, tostring(index)).heroId]
		if hero then
			local xPos, yPos = self.xBegin + (count - 1) * self.xInterval, 270
			local heroBtn = HeroHead.new( 
				{
					type = hero.type,
					wakeLevel = hero.wakeLevel,
					star = hero.star,
					evolutionCount = hero.evolutionCount,
					heroLevel = hero.level,
					hideStars = true,
					priority = self.priority - 1,
					isOn = table.find(game.role.skillOrder, hero.id) and 1 or 0,
					callback = function()
						local slot = table.keyOfItem(game.role.skillOrder, hero.id)
						if not slot then
							for index = 1, 5 do
								local heroId = tonum(game.role.skillOrder[index])
								if heroId == 0 then
									slot = index
									break
								end 
							end
							game.role.skillOrder[slot] = hero.id
						else
							game.role.skillOrder[slot] = nil
						end
						self.changed = true
						self:initUI()
					end,
				})
			heroBtn:getLayer():anch(0, 0):pos(xPos, yPos):addTo(self.mainLayer)

			count = count + 1
		end
	end
end

function HeroSkillOrderLayer:initSkillOrderHeros()
	--武将
	for index = 1, 5 do
		local hero = game.role.heros[tonum(game.role.skillOrder[index])]
		local xPos, yPos = self.xBegin + (index - 1) * self.xInterval, 93
		if hero then			
			local heroBtn = HeroHead.new( 
				{
					type = hero.type,
					wakeLevel = hero.wakeLevel or 1,
					star = hero.star,
					evolutionCount = hero.evolutionCount,
					heroLevel = hero.level,
					hideStars = true,
					priority = self.priority - 1,
					callback = function()
						game.role.skillOrder[index] = nil
						self.changed = true
						self:initUI()
					end,
				})
			heroBtn:getLayer():anch(0, 0):pos(xPos, yPos):addTo(self.mainLayer)
		end
	end
end

function HeroSkillOrderLayer:getLayer()
	return self.mask:getLayer()
end


return HeroSkillOrderLayer