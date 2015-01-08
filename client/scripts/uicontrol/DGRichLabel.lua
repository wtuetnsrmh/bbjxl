
local ChineseSize = 3 -- 修正宽度缺陷(范围:3~4)
DGRichLabel = class("DGRichLabel", function()
    return display.newLayer()
end)



function DGRichLabel:ctor(params)
	params = params or {}
	self.text = params.text or ""
	self.font = params.font or ui.DEFAULT_TTF_FONT
	self.size = params.size or ui.DEFAULT_TTF_FONT_SIZE
	self.width = params.width or math.huge
	self.rowSpace = params.rowSpace or -4
	self.color = params.color or display.COLOR_WHITE
	self.offsetY =params.offsetY or 0

	self:setString(self.text)
end

function DGRichLabel:getRowNum(text)
	local textTab = self:initData(text, self.font, self.size, self.width)
	local ptab, copyVar = self:tab_addtext(textTab)
	local row = 1 
	for k,v in pairs(copyVar) do
		if v.row > row then
			row = v.row
		end
	end
	return row
end

function DGRichLabel:setOffsetY(offsetY)
	self.offsetY = offsetY
end

function DGRichLabel:setString(text)
	self:removeAllChildren()
	self.text = text

	local textTab = self:initData(self.text, self.font, self.size, self.width)
	
	local ptab, copyVar = self:tab_addtext(textTab) 
	
	local ocWidth = 0  -- 当前占宽
	local ocRow   = 1  -- 当前行
	local ocHeight = 0 -- 当前高度
	local realSize = CCSize(0, 0)
	local btn,useWidth,useHeight = 0,0,0
	for k,v in pairs(copyVar) do
		local params = {}
		self:tab_addDataTo(params, v)
		--设置默认颜色
		params.color = params.color or self.color
		-- 计算实际渲染宽度
		if params.row == ocRow then
			ocWidth = ocWidth+useWidth
		else
			ocRow = params.row
			ocWidth = 0
			-- 计算实际渲染高度
			ocHeight = ocHeight + useHeight + self.rowSpace --修正高度间距
		end
		
		local maxsize = params.size 
		local byteSize = math.floor((maxsize+2)/ChineseSize)
		params.width  = byteSize*params.breadth     -- 控件宽度
		params.height = maxsize                     -- 控件高度
		params.x = ocWidth       					-- 控件x坐标
		params.y = self.offsetY-(ocHeight)                      -- 控件y坐标
		params.scene = self
		btn,useWidth,useHeight = self:tab_createButton(params)
		
		realSize.width = realSize.width + useWidth
	end
	realSize.height = ocHeight == 0 and useHeight or ocHeight
	realSize.width = realSize.width > self.width and self.width or realSize.width
	self:setContentSize(realSize)
end

-- 初始化数据
function DGRichLabel:initData(str, font, fontSize, rowWidth)
    local tab = self:parseString(str, {font = font, size = fontSize})
    local var = {}
    var.tab = tab         -- 文本字符
    var.width = rowWidth  -- 指定宽度
    return var
end

-- 获取一个格式化后的浮点数
local function str_formatToNumber(number, num)
    local s = "%." .. num .. "f"
    return tonumber(string.format(s, number))
end

-- 全角 半角
function DGRichLabel:accountTextLen(str, tsize)
	local list = self:tab_cutText(str)
	local aLen = 0
	for k,v in pairs(list) do
		local a = string.len(v)
		-- 懒得写解析方法了
		 local label = ui.newTTFLabel({text = v, size = tsize})
    	a = tsize/(label:getContentSize().width)
    	local b = str_formatToNumber(ChineseSize/a, 4)
		aLen = aLen + b
		label:release()
	end	
	return aLen
end

function DGRichLabel:addDataToRenderTab(copyVar, tab, text, index, current)
	local tag = #copyVar+1
	copyVar[tag] = {}
	self:tab_addDataTo(copyVar[tag], tab)
	copyVar[tag].text = text 
	copyVar[tag].index = index                 
	copyVar[tag].row = current                 
	copyVar[tag].breadth = self:accountTextLen(text, tab.size)   
	copyVar[tag].tag = tag	-- 唯一下标
end

function DGRichLabel:tab_addtext(var)
	local allTab = {}  
	-- local endRowUse = 0 
	local copyVar = {}  
	local useLen = 0   
	local str = ""		
	local current = 1 	
	for ktb,tab in ipairs(var.tab) do
		local txtTab, member = self:tab_cutText(tab.text)   
		local num = math.floor( (var.width)/ math.ceil((tab.size+2)/ChineseSize) )
		
		if useLen > 0 then
			local remain = num - useLen
			local txtLen = self:accountTextLen(tab.text, tab.size)--string.len(tab.text)
			if txtLen <= remain then 
				allTab[current] = allTab[current] .. tab.text
				self:addDataToRenderTab(copyVar, tab, tab.text, (useLen+1), current)
				useLen = useLen + txtLen
				txtTab = {}
			else 
				local cTag = 0
				local mstr = ""
				local sIndex = useLen+1
				for k,element in pairs(txtTab) do
					local sLen = self:accountTextLen(element, tab.size)--string.len(element)
					if (useLen + sLen) <= num then
						useLen = useLen + sLen
						cTag = k
						mstr = mstr .. element
					else
						if string.len(mstr) > 0 then
							allTab[current] = allTab[current] .. mstr
							self:addDataToRenderTab(copyVar, tab, mstr, (sIndex), current)
						end
						current = current+1
						useLen = 0          
						str = ""            
						break
					end
				end
				for i=1,cTag do
					table.remove(txtTab, 1)
				end
			end	
		end
		-- 填充字符
		local maxRow = math.ceil((member/num))                    
		for k,element in pairs(txtTab) do
			local sLen = self:accountTextLen(element, tab.size)--string.len(element)
			if (useLen + sLen) <= num then 
				useLen = useLen + sLen 
				str = str .. element   
			else
				allTab[current] =  str  
				self:addDataToRenderTab(copyVar, tab, str, 1, current)
				current = current + 1  
				useLen = sLen          
				str = element          
			end
			if k == #txtTab then 
				if useLen <= num then 
					allTab[current] = str
					self:addDataToRenderTab(copyVar, tab, str, 1, current)
				end
			end
		end
	end
	return allTab, copyVar
end

-- 拆分出单个字符
function DGRichLabel:tab_cutText(str)
    local list = {}
    local len = string.len(str)
    local i = 1 
    while i <= len do
        local c = string.byte(str, i)
        local shift = 1
        if c > 0 and c <= 127 then
            shift = 1
        elseif (c >= 192 and c <= 223) then
            shift = 2
        elseif (c >= 224 and c <= 239) then
            shift = 3
        elseif (c >= 240 and c <= 247) then
            shift = 4
        end
        local char = string.sub(str, i, i+shift-1)
        i = i + shift
        table.insert(list, char)
    end
	return list, len
end

function DGRichLabel:tab_createButton(params)
    local btn = cc.ui.UIPushButton.new(GlobalRes .. "rich_btn.png", {scale9 = true})
        :setButtonSize(params.width, params.height)
        :setButtonLabel("normal", ui.newTTFLabel({
            text  = params.text,
            size  = params.size,
            color = params.color,
            font  = params.font,
        }))
        :onButtonPressed(function(event)
        	event.target:getButtonLabel("normal"):setPosition(ccp(0, 0))
        end)
        :onButtonClicked(function(event)
            event.target:getButtonLabel("normal"):setPosition(ccp(0, 0))
            if self.listener then self.listener(event.target, params) end
        end)
        :onButtonRelease(function(event)
        	event.target:getButtonLabel("normal"):setPosition(ccp(0, 0))
    	end)
        :align(display.BOTTOM_LEFT, params.x, params.y)
        :addTo(params.scene)
    btn:setButtonLabelAlignment(display.BOTTOM_LEFT)
    btn:setAnchorPoint(ccp(0.5,0.5))
    local normalLab = btn:getButtonLabel("normal")
    normalLab:setPosition(ccp(0, 0))
    local useWidth = normalLab:getBoundingBox().size.width
    local useHeight = normalLab:getBoundingBox().size.height
    if params.image then
    	self:imageManage(btn, params, useWidth)
    end
    return btn,useWidth,useHeight
end

-- 图片标签处理
function DGRichLabel:imageManage(object, params, useWidth)
	local g = display.newSprite(params.image, 0, -4)
    g:setScaleX(useWidth / g:getContentSize().width)
    g:setScaleY(params.size / g:getContentSize().height)
    g:setAnchorPoint(ccp(0, 1))
	object:addChild(g, 1)
	object:setButtonLabelString("normal", "")
	local move1 = CCMoveBy:create(0.5, ccp(0, 2))
    local move2 = CCMoveBy:create(0.5, ccp(0, -2))
    g:runAction(CCRepeatForever:create(CCSequence:createWithTwoActions(move1, move2)))
    object.imageSprite = g
end

function DGRichLabel:tab_addDataTo(tab, src)
    for k,v in pairs(src) do
        tab[k] = v
    end
end

-- string.split()
function DGRichLabel:strSplit(str, flag)
	local tab = {}
	while true do
		local n = string.find(str, flag)
		if n then
			local first = string.sub(str, 1, n-1) 
			str = string.sub(str, n+1, #str) 
			table.insert(tab, first)
		else
			table.insert(tab, str)
			break
		end
	end
	return tab
end

-- 解析输入的文本
function DGRichLabel:parseString(str, param)
	local clumpheadTab = {} -- 标签头
	for w in string.gmatch(str, "%b[]") do 
		if  string.sub(w,2,2) ~= "/" then-- 去尾
			table.insert(clumpheadTab, w)
		end
	end
	-- 解析标签
	local totalTab = {}
	-- 普通格式label显示
	local index = string.find(str, "%[")
	if not index or index > 1 then
		local ptab = {}
		if index then
			ptab.text = string.sub(str, 0, index - 1)
			str = string.sub(str, index)
		else
			ptab.text = str
			str = ""
		end
		if param then
			param.number = 1
			self:tab_addDataTo(ptab, param) 
		end
		table.insert(totalTab, ptab)
	end

	for k,ns in pairs(clumpheadTab) do
		local tab = {}
		local tStr  
		-- 第一个等号前为块标签名
		string.gsub(ns, string.sub(ns, 2, #ns-1), function (w)
			local n = string.find(w, "=")
			if n then
				local temTab = self:strSplit(w, " ") -- 支持标签内嵌
				for k,pstr in pairs(temTab) do
					local temtab1 = self:strSplit(pstr, "=")
					
					local pname = temtab1[1]
					if k == 1 then tStr = pname end -- 标签头
					
					local js = temtab1[2]
					local p = string.find(js, "[^%d.]")
        			if not p then js = tonumber(js) end
					if pname == "color" then
						tab[pname] = self:GetTextColor(js)
					else
						tab[pname] = js
					end
				end
			end
		end)
		if tStr then
			-- 取出文本
			local beginFind,endFind = string.find(str, "%[%/"..tStr.."%]")
			local endNumber = beginFind-1
			local gs = string.sub(str, #ns+1, endNumber)
			-- print(gs)
			if string.find(gs, "%[") then
				tab["text"] = gs
			else
				string.gsub(str, gs, function (w)
					tab["text"] = w
				end)
			end
			-- 截掉已经解析的字符
			str = string.sub(str, endFind+1, #str)
			if param then
				if not tab.number then  param.number = k end -- 未指定number则自动生成
				self:tab_addDataTo(tab, param) 
			end
			table.insert(totalTab, tab)
		end
	end

	if #str > 0 then
		local ptab = {}
		ptab.text = str
		if param then
			param.number = 1
			self:tab_addDataTo(ptab, param) 
		end
		table.insert(totalTab, ptab)
	end
	
	return totalTab
end

--[[解析16进制颜色rgb值]]
function  DGRichLabel:GetTextColor(xStr)
    if string.len(xStr) == 6 then
        local tmp = {}
        for i = 0,5 do
            local str =  string.sub(xStr,i+1,i+1)
            if(str >= '0' and str <= '9') then
                tmp[6-i] = str - '0'
            elseif(str == 'A' or str == 'a') then
                tmp[6-i] = 10
            elseif(str == 'B' or str == 'b') then
                tmp[6-i] = 11
            elseif(str == 'C' or str == 'c') then
                tmp[6-i] = 12
            elseif(str == 'D' or str == 'd') then
                tmp[6-i] = 13
            elseif(str == 'E' or str == 'e') then
                tmp[6-i] = 14
            elseif(str == 'F' or str == 'f') then
                tmp[6-i] = 15
            else
                print("Wrong color value.")
                tmp[6-i] = 0
            end
        end
        local r = tmp[6] * 16 + tmp[5]
        local g = tmp[4] * 16 + tmp[3]
        local b = tmp[2] * 16 + tmp[1]
        return ccc3(r,g,b)
    end
    return ccc3(255,255,255)
end

-- 设置监听函数
function  DGRichLabel:setClilckEventListener(eventName)
	self.listener = eventName
end

return DGRichLabel
