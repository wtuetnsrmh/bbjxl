uihelper = {}

function degrees2radians(angle)
	return angle * math.pi / 180
end

function radians2degrees(angle)
	return angle * 180 / math.pi
end

-- 定义颜色
display.COLOR_LIGHTYELLOW = ccc3(231, 217, 185)
display.COLOR_DARKYELLOW = ccc3(66, 40, 32)
display.COLOR_YELLOW = ccc3(255, 255, 0)
display.COLOR_BLUE = ccc3(0, 153, 204)
display.COLOR_GREEN = ccc3(11, 241, 6)
display.COLOR_BLACK = ccc3(0, 0, 0)
display.COLOR_ORANGE = ccc3(255, 144, 0)
display.COLOR_ORANGERED = ccc3(248, 82, 0)
display.COLOR_WHITE = ccc3(255, 255, 255)
display.COLOR_LIGHTGRAY = ccc3(169, 169, 169)
display.COLOR_LIGHTGREEN = ccc3(50, 205, 50)
display.COLOR_DARKBLUE = ccc3(0, 139, 139)
display.COLOR_FONT = ccc3(36, 36, 36)	
display.COLOR_FONTGREEN = ccc3(2, 70, 30)	-- 绿色按钮上 ccc3(2, 99, 46)
display.COLOR_BUTTON_STROKE = ccc3(36, 36, 36)	-- 所有按钮上描边 #242424
display.COLOR_SHADOW = ccc3(0, 0, 0)
display.COLOR_BROWN = ccc3(111, 85, 71)
display.COLOR_DARKBROWN = ccc3(66, 45, 23)
display.COLOR_BORDER_BROWN = ccc3(49, 22, 0)
display.COLOR_BROWNSTROKE = ccc3(77, 42, 29)
display.COLOR_ORANGE = ccc3(254, 201, 16) --橙色
display.COLOR_LIGHTBLUE = ccc3(0, 255, 216) --水蓝色



-- 定义标题字体
ChineseFont = "font/FZYiHei-M20S.ttf"

-- 切换场景
-- @param name 场景名字
-- @param params    传递给下一个场景的参数
-- @param callback  回调函数
-- @param transitionParams  切换效果参数
function switchScene(name, params, callback, transitionParams)
	-- 去掉所有未完成的动作
	-- CCDirector:sharedDirector():getActionManager():removeAllActions()

	params = params or {}
	params.closemode = 1

	local scene = require(string.format("scenes.%s.scene", name))
	if transitionParams then
		display.replaceScene(scene.new(params), transitionParams.transitionType, transitionParams.time, transitionParams.more)
	else
		display.replaceScene(scene.new(params))
	end

	if type(callback) == "function" then
		-- 必须延迟，不然会在替换场景之前执行
		local handle
		handle = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(function()
			CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(handle)
			handle = nil
			callback()
		end, 0.5 , false)
	end
end

function pushScene(name, params)
	params = params or {}
	params.closemode = 2
	local scene = require(string.format("scenes.%s.scene", name))
	CCDirector:sharedDirector():pushScene(scene.new(params))
end

function popScene()
	CCDirector:sharedDirector():popScene()
end

-- UI震动效果
function uihelper.shake(args, target)
	local target = target or display.getRunningScene()
	args = args or {}
	local time = args.time or 0.01
	local x = args.x or 5
	local y = args.y or 5
	local shakeCount = args.count or 5
	local onComplete = args.onComplete or nil

	local actions = {}
	actions[#actions + 1] = CCMoveBy:create(time, ccp(x, y))
	for count = 1, shakeCount do
		actions[#actions + 1] = CCMoveBy:create(time * 2, ccp(0 - x * 2, 0 - y * 2))
		actions[#actions + 1] = CCMoveBy:create(time * 2, ccp(x * 2, y * 2))
	end
	actions[#actions + 1] = CCMoveBy:create(time, ccp(-x, -y))
	
	target:runAction(transition.sequence(actions))
end

-- params的参数说明
-- @param:node 欲描边的显示对象
-- @param:storkeSize 描边宽度
-- @param:color 描边颜色
-- @param:opacity 描边透明度
function uihelper.createStroke(params)
	assert(type(params) == "table", "uihelper.createStroke invalid params")

	local node = params.node
	local strokeSize = params.strokeSize or 4
	local strokeColor = params.strokeColor or ccc3(0, 0, 0)
	local opacity = params.opacity or 100

	local w = node:getTexture():getContentSize().width + strokeSize * 2
	local h = node:getTexture():getContentSize().height + strokeSize * 2
	local rt = CCRenderTexture:create(w, h)

	-- 记录原始位置
	local originX, originY = node:getPosition()
	-- 记录原始颜色RGB信息
	local originColorR = node:getColor().r
	local originColorG = node:getColor().g
	local originColorB = node:getColor().b
	-- 记录原始透明度信息
	local originOpacity = node:getOpacity()
	-- 记录原始是否显示
	local originVisibility = node:isVisible()
	-- 记录原始混合模式
	local originBlend = node:getBlendFunc()

	-- 设置颜色、透明度、显示
	node:setColor(strokeColor)
	node:setOpacity(opacity)
	node:setVisible(true)
	-- 设置新的混合模式
	local blendFuc = ccBlendFunc:new()
	blendFuc.src = GL_SRC_ALPHA
	blendFuc.dst = GL_ONE
	-- blendFuc.dst = GL_ONE_MINUS_SRC_COLOR
	node:setBlendFunc(blendFuc)

	-- 这里考虑到锚点的位置，如果锚点刚好在中心处，代码可能会更好理解点
	local bottomLeftX = node:getTexture():getContentSize().width * node:getAnchorPoint().x + strokeSize 
	local bottomLeftY = node:getTexture():getContentSize().height * node:getAnchorPoint().y + strokeSize

	local positionOffsetX = node:getTexture():getContentSize().width * node:getAnchorPoint().x - node:getTexture():getContentSize().width / 2
	local positionOffsetY = node:getTexture():getContentSize().height * node:getAnchorPoint().y - node:getTexture():getContentSize().height / 2

	local rtPosition = ccp(originX - positionOffsetX, originY - positionOffsetY)

	rt:begin()
	-- 步进值这里为10，不同的步进值描边的精细度也不同
	for i = 0, 360, 10 do
		-- 这里解释了为什么要保存原来的初始信息
		node:setPosition(ccp(bottomLeftX + math.sin(degrees2radians(i)) * strokeSize, bottomLeftY + math.cos(degrees2radians(i)) * strokeSize))
		node:visit()
	end
	rt:endToLua()

	-- 恢复原状
	node:setPosition(originX, originY)
	node:setColor(ccc3(originColorR, originColorG, originColorB))
	node:setBlendFunc(originBlend)
	node:setVisible(originVisibility)
	node:setOpacity(originOpacity)

	rt:setPosition(rtPosition)
	rt:getSprite():getTexture():setAntiAliasTexParameters()

	return CCNodeExtend.extend(rt)
end

--文字换行处理
function uihelper.createLabel(params)
	params = params or {}
	local text = params.text or ""
	local totalWidth = params.width or 100     -- 文字总宽度
	local color = params.color or display.COLOR_WHITE
	local font = params.font or ui.DEFAULT_TTF_FONT
	local size = params.size or 24
	local line = 1          
	local enterNum = string.utf8len(text) - string.utf8len(string.gsub(text, "\n", ""))
	local label
	if params.strokeColor then
		label = ui.newTTFLabelWithStroke({text = text, size = size, color = color, 
			strokeColor = params.strokeColor,strokeSize = params.strokeSize })
	elseif params.isRichLabel then
		label = ui.newTTFRichLabel({text = text, size = size, color = color })
	else
		label = ui.newTTFLabel({text = text, size = size, color = color })
	end
	local labelSize = label:getContentSize()
	local lineHeight = labelSize.height
	if enterNum > 1 then
		lineHeight = lineHeight / (enterNum - 1)
	end

	if labelSize.width > totalWidth then          -- 大于一行
		--@remark +0.01是修正某些机型上显示不完全的问题
		line = math.ceil(labelSize.width / totalWidth + 0.01)
	end
	line = line + enterNum
	label:setDimensions(CCSizeMake(totalWidth, line * lineHeight))
	label:setHorizontalAlignment(ui.TEXT_ALIGN_LEFT)
	return label, line
end

function uihelper.popupNode(node, scale)
	scale = scale or 1
	node:scale(0.1 * scale)
	local actions = transition.sequence({
		CCScaleTo:create(0.1, 1.2 * scale),
		CCScaleTo:create(0.2, 0.9 * scale),
		CCScaleTo:create(0.1, 1 * scale)
	})

	node:runAction(actions)
end

function uihelper.shrinkNode(node, onComplete)
	local actions = transition.sequence({
		CCScaleTo:create(0.1, 1.2),
		CCScaleTo:create(0.1, 0.1),
		CCRemoveSelf:create(),
		CCCallFunc:create(function() onComplete() end)
	})

	node:runAction(actions)
end

function uihelper.hex2rgb(hex)
    hex = hex:gsub("#","")
    return ccc3(tonumber("0x"..hex:sub(1,2)), 
    	tonumber("0x"..hex:sub(3,4)), tonumber("0x"..hex:sub(5,6)))
end

function uihelper.newMsgTag(node,point)
	local xx,yy = 0,0
	local tag = node:getChildByTag(9999)
	if not tolua.isnull(tag) then return end
	
	local size = node:getContentSize()
	if point then
		xx = size.width - point.x
		yy = size.height - point.y
	else
		xx = size.width - 5
		yy = size.height - 5
	end
	display.newSprite("resource/ui_rc/global/msg_new.png")
		:anch(1, 1):pos(xx, yy):addTo(node, 10, 9999)
end

function uihelper.nodeContainTouchPoint(node, touchPoint, touchScale)
	local pointTarget = node:convertToNodeSpace(touchPoint)

	local contentSize = node:getContentSize()
	touchScale = touchScale or { 1, 1 }

	return contentSize.width * (1 - touchScale[1]) / 2 <= pointTarget.x and pointTarget.x <= contentSize.width * (touchScale[1] + 1) / 2
		and contentSize.height * (1 - touchScale[2]) / 2 <= pointTarget.y and pointTarget.y <= contentSize.height * (touchScale[2] + 1) / 2
end

--对应文件是否可以读取：
function fileCanGetOnPath(path)
    local fullname = CCFileUtils:sharedFileUtils():fullPathForFilename(path)
    local isFind = CCFileUtils:sharedFileUtils():isFileExist(fullname)
    if not isFind then print(" error : this path cannot find ==",path) end
    return isFind
end

--position,tag,res,parent,zorder,scale,file
function showParticleEffect(params)
	if params and params.parent and fileCanGetOnPath(params.res) then
		local s = params.scale or 1
		local t = params.tag or 100
		local p = params.position or ccp(0, 0)
		local r = params.res or "resource/ui_rc/particle/kaifu_icon.plist"
		local nd = CCNode:create()
		nd:setPosition(params.position)
		params.parent:addChild(nd,t)
		local deathSoul = CCNodeExtend.extend(CCParticleSystemQuad:create(r))
		deathSoul:setAnchorPoint(p)
		nd:addChild(deathSoul)
		nd:setScale(tonumber(s))
		nd:setTag(tonumber(params.tag))
	end
end

--- steRes:模板,isFlip:模板翻转；color4:纯色,clipRes:被剪切资源,isInverted:是否取反,node:被剪切node；
function getShaderNode(params)
	local clip = nil
	local params = params or {}
	local steRes = params.steRes
	local color4 = params.color4
	local clipRes= params.clipRes
	local isInverted = params.isInverted or false
	local node = params.node
	local isFlip = params.isFlip or false

	if params and steRes and (steRes or color4) then

		local sten = CCSprite:create(steRes)
		sten:setFlipX(isFlip)
	    clip = CCClippingNode:create()
	    clip:setStencil(sten)
	    clip:setInverted(isInverted)
	    clip:setPosition(ccp(display.cx, display.cy))
	    clip:setAlphaThreshold(0)

	    if color4 then
	    	local flayer = CCLayerColor:create(color4)
		    flayer:setPosition(ccp(-display.cx, -display.cy))
		    clip:addChild(flayer)
	    elseif clipRes then
	    	local sten = CCSprite:create(clipRes)
	    	sten:setPosition(ccp(clip:getContentSize().width/2, clip:getContentSize().height/2))
	    	clip:addChild(sten)

	    elseif node then 
	    	node:setFlipX(isFlip)
	    	node:setPosition(ccp(clip:getContentSize().width/2, clip:getContentSize().height/2))
	    	clip:addChild(node)
	    end
	end
	return clip 
end

function pushLayerAction(node,isRun)
	if isRun then
		node:setScale(0.1)
		node:runAction(transition.sequence({
			-- CCEaseOut:create(CCScaleTo:create(0.1, 1.3), 10),
			CCScaleTo:create(0.1, 1.2),
			CCScaleTo:create(0.1, 0.95),
			CCScaleTo:create(0.1, 1),
		}))
	end
end

function loadingShow(hold)
	local loadingMask = require("scenes.LoadingLayer"):new():getLayer()
	loadingMask:setTag(333888)
	loadingMask:hide()
	display.getRunningScene():addChild(loadingMask, 1000)
	--过个1.5秒再显示
	loadingMask:runAction(transition.sequence{
			CCDelayTime:create(1.5),
			CCShow:create(),
		})
	if not hold then
		loadingMask:runAction(transition.sequence{
			CCDelayTime:create(4.5),
			CCRemoveSelf:create(),
		})
	end
end

function loadingHide()
	local layer = display.getRunningScene():getChildByTag(333888)
	if layer then
		layer:stopAllActions()
		layer:removeSelf()
	end
end

function showMaskLayer(params)
	params = params or {}
	local mask = DGMask:new({priority = -9997, opacity = params.opacity or 0, click = params.click}):getLayer()
	mask:addTo(display.getRunningScene())
	mask:setTag(265486)
	mask:runAction(transition.sequence({
		CCDelayTime:create(params.delay or 3),
		CCRemoveSelf:create(),
		}))
	return mask
end

function hideMaskLayer(params)
	local layer = display.getRunningScene():getChildByTag(265486)
	if layer then
		layer:stopAllActions()
		layer:removeSelf()
	end
end

--调试时候暂用下
function showinfile(logTitle,showContent)

	if showContent ~= nil and type(showContent) == "string" then
		if not logTitle then
			logTitle = "log"
		end
		local content = "-------"..logTitle.." == "..showContent.."\n"
		local pathStr = "res/show"      
	    local path = CCFileUtils:sharedFileUtils():fullPathForFilename(pathStr)  ---获取全路径
	    if io.writefile(path,content,"a+") then    -------参数：路径，写入内容，写入模式；
	        print("***** WR *****")
	    else
	         print("***** WN *****")
	    end
	end
end

--获得月天数
function getDaysInMonth(year, month)
	local curTime = game and os.date("*t", game:nowTime()) or os.time()
	year = year or tonum(curTime.year)
	month = month or tonum(curTime.month)
	month = (month + 1) % 12
	local calcTime = os.time({year = year, month = month, day = 1, hour = 0, min = 0, sec = 0}) - 1
	return tonum(os.date("*t", calcTime).day)
end

function table.contain(a, b, isKey)
	isKey = isKey or false
	if isKey then
		a = table.keys(a)
		b = table.keys(b)
	end
	local aContainb = true
	for key, value in pairs(b) do
		if not table.find(a, value) then
			aContainb = false
			break
		end
	end
	return aContainb
end

function uihelper.sShowAttrsChange(params)
	params = params or {}
	local curAttrs, oldAttrs = params.curAttrs, params.oldAttrs
	if not curAttrs or not oldAttrs then return end
	local parent = params.parent or display.getRunningScene()
	local offset = params.offset or ccp(0, 0)
	local fontSize = params.fontSize or 26

	local offsetY = 40
	local delayTime = 0
	for key, value in pairs(EquipAttEnum) do
		local deltaValue = (curAttrs[key] or 0) - (oldAttrs[key] or 0)
		if deltaValue ~= 0 then
			local midSymbol = deltaValue > 0 and "+" or ""
			local color = deltaValue > 0 and display.COLOR_GREEN or display.COLOR_RED
			local deltaY = deltaValue > 0 and offsetY or -offsetY
			local text = ui.newTTFLabelWithStroke({text = EquipAttName[value] .. midSymbol .. deltaValue, size = fontSize, font = ChineseFont, color = color})
			text:anch(0.5, 0.5):pos(display.cx + offset.x, display.cy + offset.y - deltaY):addTo(parent)
			local fadeInTime, fadeOutTime = 0.1, 0.15
			text:runAction(transition.sequence({
				CCCallFunc:create(function() uihelper.fadeTree({node = text, from = 255, to = 0, effectTime = 0}) end),
				CCDelayTime:create(delayTime),
				-- CCSpawn:createWithTwoActions(CCFadeIn:create(0.1), CCMoveBy:create(0.15, ccp(0, deltaY))),
				CCCallFunc:create(function() uihelper.fadeTree({node = text, from = 0, to = 255, effectTime = fadeInTime}) end),
				CCSpawn:createWithTwoActions(CCDelayTime:create(fadeInTime), CCMoveBy:create(0.15, ccp(0, deltaY))),
				CCDelayTime:create(0.65),
				-- CCSpawn:createWithTwoActions(CCFadeOut:create(0.15), CCMoveBy:create(0.15, ccp(0, deltaY))),
				CCCallFunc:create(function() uihelper.fadeTree({node = text, from = 255, to = 0, effectTime = fadeOutTime}) end),
				CCSpawn:createWithTwoActions(CCDelayTime:create(fadeOutTime), CCMoveBy:create(0.15, ccp(0, deltaY))),
				CCRemoveSelf:create(),
				}))
			delayTime = delayTime + 0.8
		end
	end
end

function uihelper.loadAnimation(res, fileName, frameNum, fps)
	display.addSpriteFramesWithFile(res..fileName..".plist", res..fileName..".png")

	local frames = {}
	for index = 1, frameNum do
		local frameId = string.format("%02d", index)
		frames[#frames + 1] = display.newSpriteFrame(fileName.."_" .. frameId .. ".png")
	end

	fps = fps or frameNum
	local animation = display.newAnimation(frames, 1.0 / fps)
	local sprite = display.newSprite(frames[1])
	return {sprite = sprite, animation = animation}
end

--返回黑白图遮罩sprite
function uihelper.createMaskSprite(srcImg,maskImg)
	local existPng=string.split(maskImg,".png")
	if #existPng>1 then
		echoInfo("exist png file=%s",tostring(maskImg))
		return display.newSprite(srcImg)
	end
	local texture=CCDGHelper:createMaskSprite(maskImg,srcImg)
	local returnSp
	if texture then
		returnSp=CCSprite:createWithTexture(texture)
		CCSpriteExtend.extend(returnSp)
	else
		echoError("uihelper.createMaskSprite - create texture failure, srcImg %s,maskImg %s", tostring(srcImg),tostring(maskImg))
        returnSp = CCSprite:create()
	end
	
	return returnSp
end

function uihelper.getCardFrame(evolutionCount)
	evolutionCount = evolutionCount or 0
	local frameNum = 1
	for index = 1, #EvolutionThreshold do
		if evolutionCount < EvolutionThreshold[index] then
			frameNum = index
			break
		end
	end
	return frameNum
end

local colorDesc = {"灰色", "绿色", "蓝色", "紫色", "金色"}
function uihelper.getEvolColorDesc(evolutionCount)
	return colorDesc[uihelper.getCardFrame(evolutionCount)]
end

local colorSchema = {
	[1] = display.COLOR_WHITE,
	[2] = ccc3(0, 255, 0),  -- display.COLOR_GREEN
	[3] = ccc3(0, 150, 255),  -- display.COLOR_BLUE
	[4] = ccc3(225, 0, 225), -- 紫色
	[5] = display.COLOR_YELLOW
}
function uihelper.getEvolColor(evolutionCount)
	return colorSchema[uihelper.getCardFrame(evolutionCount)]
end

function uihelper.getShowEvolutionCount(evolutionCount)
	evolutionCount = evolutionCount or 0 
	for index = 1, #EvolutionThreshold do
		if evolutionCount < EvolutionThreshold[index] then
			evolutionCount = evolutionCount - tonum(EvolutionThreshold[index - 1])
			break
		end
	end
	return evolutionCount
end

function uihelper.numVaryEffect(params)
	params = params or {}
	if not params.node then return end

	local effectTime = params.effectTime or 0.5
	local repeatTimes = effectTime * (params.fps or 30)
	local stringFormat = params.stringFormat or "%d"

	local count = 1
	params.node:runAction(CCRepeat:create(transition.sequence({
			CCCallFunc:create(function() 
				params.node:setString(string.format(stringFormat, params.num/repeatTimes * count))
				count = count + 1
			end),
			CCDelayTime:create(effectTime/repeatTimes),
		}), repeatTimes + 1))
end

function uihelper.fadeTree(params)
	params = params or {}
	if not params.node then return end

	-- local opacityTable = {}
	local setOpacity
	setOpacity = function(node, opacity, first)
		-- if first then
		-- 	opacityTable[node] = node:getOpacity()
		-- else
		-- 	node:setOpacity(math.min(opacity, opacityTable[node]))
		-- end
		node:setOpacity(opacity)
		local children = node:getChildren()
		local childsNum = node:getChildrenCount()
		for index = 0, childsNum - 1 do
			local child = tolua.cast(children:objectAtIndex(index), "CCNode")
			setOpacity(child, opacity, first)
		end
	end

	local opacity = params.to - params.from
	local effectTime = params.effectTime or 0.5
	local repeatTimes = effectTime * (params.fps or 30)
	local count = 1
	setOpacity(params.node, params.from, true)
	if effectTime <= 0 then
		setOpacity(params.node, params.to, false)
	else	
		params.node:runAction(CCRepeat:create(transition.sequence({
			CCCallFunc:create(function()
				if count > repeatTimes then return end
				setOpacity(params.node, params.from + opacity/repeatTimes * count, false)
				count = count + 1
			end),
			CCDelayTime:create(effectTime/repeatTimes),
		}), repeatTimes + 1))
	end
end
