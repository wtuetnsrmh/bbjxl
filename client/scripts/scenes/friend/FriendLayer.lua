-- 好友界面
-- revised by yangkun
-- 2014.7.4

local FriendRes = "resource/ui_rc/friend/"
local GlobalRes = "resource/ui_rc/global/"
local HeroRes = "resource/ui_rc/hero/"

local RoleDetailLayer = import("..RoleDetailLayer")
local TopBarLayer = import("..TopBarLayer")

local FriendLayer = class("FriendLayer", function()
	return display.newLayer(GlobalRes .. "inner_bg.png")
end)

function FriendLayer:ctor(params)
	self.params = params or {}
	self.priority = params.priority or -130

	self:initUI()

	self.scrollSize = CCSizeMake(844,490)
	self.cellSize = CCSizeMake(839, 131)

	local layer  = TopBarLayer.new({priority = self.priority})
	layer:anch(0,1):pos(0,display.height):addTo(self)
end

function FriendLayer:initUI()
	self.size = self:getContentSize()

	-- 遮罩层
	self:anch(0, 0):pos((display.width - 960) / 2, 0)
	self.mask = DGMask:new({ item = self, priority = self.priority + 1 })

	local closeBtn = DGBtn:new(GlobalRes, {"close_normal.png", "close_selected.png"},
		{	
			touchScale = 1.5,
			priority = self.priority,
			callback = function()
				if self.params.closemode == 2 then
					popScene()
				else
					switchScene("home")
				end
			end,
		}):getLayer()
	closeBtn:anch(0.7, 0.5):pos(self.size.width, self.size.height):addTo(self,100)

	self.tabCursor = display.newSprite(GlobalRes .. "tab_arrow.png")
	self.tabCursor:anch(1, 0.5):pos(self.size.width, 470):addTo(self, 100)

	local tabRadio = DGRadioGroup:new()
	local friendBtn = DGBtn:new(GlobalRes, {"tab_normal.png", "tab_selected.png"},
		{	
			id = 1,
			priority = self.priority,
			callback = function()
				self.tabCursor:pos(self.size.width, 470)

				local bin = pb.encode("SimpleEvent", { roleId = game.role.id })
				game:sendData(actionCodes.FriendListFriendRequest, bin)
				game:addEventListener(actionModules[actionCodes.FriendListFriendResponse], function(event)
					local msg = pb.decode("FriendList", event.data)
					game.role:setFriendCnt(msg.friends and #msg.friends or 0)
					self.friends = msg.friends
					self.searchFriends = msg.friends
					self:showSelfFriends() 

					return "__REMOVE__"
				end)
			end
		}, tabRadio)
	friendBtn:getLayer():anch(0, 0.5):pos(self.size.width - 14, 470):addTo(self)
	local btnSize = friendBtn:getLayer():getContentSize()
	ui.newTTFLabelWithStroke({ text = "好友", dimensions = CCSizeMake(btnSize.width / 2, btnSize.height), font = ChineseFont,
		size = 26, color = display.COLOR_WHITE, strokeColor = uihelper.hex2rgb("#242424") })
		:pos(btnSize.width / 2, btnSize.height / 2):addTo(friendBtn:getLayer(), 10)

	self.healthTag = game.role:addEventListener("notifyNewMessage", function(event)
		if event.type == "friendHealth" then
			friendBtn:getLayer():removeChildByTag(9999)
			if event.action == "add" then
				uihelper.newMsgTag(friendBtn:getLayer(), ccp(-5, -5))
			end
		end
	end)

	local addBtn = DGBtn:new(GlobalRes, {"tab_normal.png", "tab_selected.png"},
		{	
			id = 2,
			priority = self.priority,
			callback = function()
				self.tabCursor:pos(self.size.width, 360)

				local bin = pb.encode("SimpleEvent", { roleId = game.role.id })
				game:sendData(actionCodes.FriendRandomSearch, bin)
				loadingShow()
				game:addEventListener(actionModules[actionCodes.FriendMatchedRoleResponse], function(event)
					loadingHide()
					local msg = pb.decode("SearchRoleList", event.data)
					self.searchRoles = msg.searchRoles
					self:showAddFriendLayer() 

					return "__REMOVE__"
				end)
			end
		}, tabRadio)
	addBtn:getLayer():anch(0, 0.5):pos(self.size.width - 14, 360):addTo(self)
	ui.newTTFLabelWithStroke({ text = "添加", dimensions = CCSizeMake(btnSize.width / 2, btnSize.height), font = ChineseFont,
		size = 26, color = display.COLOR_WHITE, strokeColor = uihelper.hex2rgb("#242424") })
		:pos(btnSize.width / 2, btnSize.height / 2):addTo(addBtn:getLayer(), 100)

	local messageBtn = DGBtn:new(GlobalRes, {"tab_normal.png", "tab_selected.png"},
		{	
			id = 3,
			priority = self.priority,
			callback = function()
				self.tabCursor:pos(self.size.width, 250)

				local bin = pb.encode("SimpleEvent", { roleId = game.role.id })
				game:sendData(actionCodes.FriendApplicationsRequest, bin)
				loadingShow()
				game:addEventListener(actionModules[actionCodes.FriendApplicationsResponse], function(event)
					loadingHide()
					local msg = pb.decode("ApplicationList", event.data)
					self:showApplicationLayer(msg.applications) 

					return "__REMOVE__"
				end)
			end
		}, tabRadio)
	messageBtn:getLayer():anch(0, 0.5):pos(self.size.width - 14, 250):addTo(self)
	ui.newTTFLabelWithStroke({ text = "消息", dimensions = CCSizeMake(btnSize.width / 2, btnSize.height), font = ChineseFont,
		size = 26, color = display.COLOR_WHITE, strokeColor = uihelper.hex2rgb("#242424") })
		:pos(btnSize.width / 2, btnSize.height / 2):addTo(messageBtn:getLayer(), 100)
	self.messageTag = game.role:addEventListener("notifyNewMessage", function(event)
		if event.type == "friendApplication" then
			messageBtn:getLayer():removeChildByTag(9999)
			if event.action == "add" then
				uihelper.newMsgTag(messageBtn:getLayer(), ccp(-5, -5))
			end
		end
	end)

	tabRadio:chooseById(1, true)
	self.tableRadioGrp = tabRadio
end

function FriendLayer:showTopBar(curLayer)
	local nameInputBox = ui.newEditBox({
		image = FriendRes .. "input_box.png",
		size = CCSize(302, 32),
		listener = function(event, editbox)
			if event == "began" then
			elseif event == "ended" then
			elseif event == "return" then
			elseif event == "changed" then
			end
		end
	})

	self:getLayer():getParent():setTouchPriority(-132)
	nameInputBox:setFontColor(display.COLOR_DARKYELLOW)	
	nameInputBox:setReturnType(kKeyboardReturnTypeSend)
	nameInputBox:anch(0, 0):pos(28, self.size.height - 48):addTo(self.contentLayer)

	local searchBtn = DGBtn:new(GlobalRes, { "topbar_normal.png", "topbar_selected.png" },  
		{
			priority = -140,
			text = {text = "搜索", size = 22, font = ChineseFont, strokeColor = uihelper.hex2rgb("#242424")},
			callback = function()
				if curLayer == "friend" then
					local namePattern = nameInputBox:getText()

					local searchFriends = {}
					for _, friendInfo in pairs(self.friends) do
						print(friendInfo.name)
						if string.find(friendInfo.name, namePattern) then
							table.insert(searchFriends, friendInfo)
						end
					end	
					self.scrollView:reloadData(searchFriends)
				elseif curLayer == "addFriend" then
					local namePattern = nameInputBox:getText()
					if #namePattern == 0 then
						DGMsgBox.new({ type = 1, text = "请输入查找的玩家名" })
						return
					end
					local searchRoleByNameRequest = {
							roleId = game.role.id,
							namePattern = namePattern,
						}
					local bin = pb.encode("SearchRoleByName", searchRoleByNameRequest)
					game:sendData(actionCodes.FriendSearchByName, bin)
					loadingShow()
					game:addEventListener(actionModules[actionCodes.FriendMatchedRoleResponse], function(event)
						loadingHide()
						local msg = pb.decode("SearchRoleList", event.data)

						self.scrollView:reloadData(msg.searchRoles)

						return "__REMOVE__"
					end)
				end
			end,
		})
	searchBtn:getLayer():anch(0, 0):pos(nameInputBox:getContentSize().width-30, 0):addTo(nameInputBox)

	if curLayer == "friend" then
		ui.newTTFLabel({text = string.format("当前好友: %d",table.nums(self.friends)), size = 20, color = uihelper.hex2rgb("#ffda7d")})
		:anch(0, 0):pos(530, self.size.height - 48):addTo(self.contentLayer)
	elseif curLayer == "addFriend" then
		local refreshBtn = DGBtn:new(GlobalRes, {"topbar_normal.png", "topbar_selected.png"},
			{
				priority = self.priority -1,
				text = { text = "换一批", size = 22, font = ChineseFont, strokeColor = uihelper.hex2rgb("#242424")},
				callback = function() 
					local randomSearchRoleRequest = { roleId = game.role.id }
					local bin = pb.encode("SimpleEvent", randomSearchRoleRequest)
					game:sendData(actionCodes.FriendRandomSearch, bin)
					game:addEventListener(actionModules[actionCodes.FriendMatchedRoleResponse], function(event)
						local msg = pb.decode("SearchRoleList", event.data)

						self.scrollView:reloadData(msg.searchRoles)
						self.searchRoles = msg.searchRoles

						return "__REMOVE__"
					end)
				end,
			}):getLayer()
		refreshBtn:anch(0, 0):pos(700, self.size.height - 48):addTo(self.contentLayer)
	end
end

function FriendLayer:getLayer()
	return self.mask:getLayer()
end

function FriendLayer:showSelfFriends()
	if self.contentLayer then
		self.contentLayer:removeSelf()
		self.contentLayer = nil
	end

	self.contentLayer = display.newLayer()
	self.contentLayer:size(self.size)
	self.contentLayer:anch(0,0):pos(0,0):addTo(self)

	self:showTopBar("friend")

	local function createFriendNode(parentNode, cellIndex)
		parentNode:removeAllChildren()
		local friendInfo = self.searchFriends[#self.searchFriends - cellIndex]

		local bgBtn = display.newSprite(FriendRes .. "friend_cell_bg.png"):anch(0, 0):addTo(parentNode)
		local btnSize = bgBtn:getContentSize()

		local mainHeroIcon = HeroHead.new({ 
			type = friendInfo.mainHeroType, 
			wakeLevel = friendInfo.wakeLevel,
			star = friendInfo.star,
			evolutionCount = friendInfo.evolutionCount,
			priority = self.priority,
			touchScale = {1.2, 1}, 
			callback = function()
				local bin = pb.encode("SimpleEvent", { roleId = friendInfo.roleId })
				game:sendData(actionCodes.RoleDigestInfoRequest, bin)
				game:addEventListener(actionModules[actionCodes.RoleDigestInfoResponse], function(event)
					local roleDigest = pb.decode("RoleLoginResponse", event.data)
					local roleDigestLayer = RoleDetailLayer.new({ priority = self.priority - 10, roleDigest = roleDigest,
						-- button1Data = { text = "私聊" },
						button1Data = { text = "删除好友", callback = function() 
							local deleteFriendRequest = { roleId = game.role.id, objectId = friendInfo.roleId }
							local bin = pb.encode("DeleteFriend", deleteFriendRequest)
							game:sendData(actionCodes.FriendDelete, bin)

							self.tableRadioGrp:chooseById(1, true)
						end } 
					})
					roleDigestLayer:getLayer():addTo(display.getRunningScene())

					return "__REMOVE__"
				end)
			end,
		 }):getLayer()
		if friendInfo.vipLevel > 0 then
			display.newSprite(string.format("resource/ui_rc/shop/recharge/vip_text_%d.png", friendInfo.vipLevel))
				:scale(0.8):anch(0.5, 0):pos(mainHeroIcon:getContentSize().width - 14, 0):addTo(mainHeroIcon)
		end
		mainHeroIcon:anch(0, 0.5):pos(25, btnSize.height / 2):addTo(bgBtn)

		local infoBg = display.newSprite(GlobalRes .. "cell_namebar.png")
		local infoSize = infoBg:getContentSize()
		local name = ui.newTTFLabel({text = friendInfo.name, size = 26, color = display.COLOR_WHITE, font = ChineseFont })
			:anch(0, 0.5):pos(20, infoSize.height / 2):addTo(infoBg)
		ui.newTTFLabel({text = "Lv. " .. friendInfo.level, size = 22, color = uihelper.hex2rgb("#ffdc7d") })
			:anch(0, 0):pos(name:getContentSize().width + 2, 0):addTo(name)

		local pvpGiftData = pvpGiftCsv:getGiftData(friendInfo.pvpRank)
		if pvpGiftData then
			infoBg:anch(0, 1):pos(200, btnSize.height - 30):addTo(bgBtn)
			ui.newTTFLabelWithStroke({ text = "称号:", size = 20, font = ChineseFont, color = display.COLOR_WHITE })
				:anch(0, 0):pos(200, 20):addTo(bgBtn)
			ui.newTTFLabelWithStroke({ text = pvpGiftData.name, size = 20, font = ChineseFont, color = uihelper.hex2rgb("#ffd200") })
				:anch(0, 0):pos(260, 20):addTo(bgBtn)
		else
			infoBg:anch(0, 0.5):pos(200, btnSize.height / 2):addTo(bgBtn)
		end

		-- local chatBtn = DGBtn:new(GlobalRes, {"btn_green_nol.png", "btn_green_sel.png",}, {
		-- 		text = {text = "私聊", font = ChineseFont, color=display.COLOR_WHITE, strokeColor = display.COLOR_FONT, strokeSize = 2 },
		-- 		priority = self.priority -1,
		-- 		callback = function()

		-- 		end,
		-- 	}):getLayer()
		-- chatBtn:anch(1, 0.5):pos(btnSize.width - 20, btnSize.height / 2):addTo(bgBtn)

		-- 体力按钮
		local btnText, btnCallback, res
		local donateCallback = function()
			local donateRequest = { roleId = game.role.id, objectId = friendInfo.roleId }
			local bin = pb.encode("DonateHealthToFriend", donateRequest)
			game:sendData(actionCodes.FriendDonateHealth, bin)
			loadingShow()
			game.role:addEventListener("ErrorCode" .. SYS_ERR_FRIEND_DONATE_SUCCESS, function(event)
				loadingHide()
				DGMsgBox.new({ msgId = SYS_ERR_FRIEND_DONATE_SUCCESS })
				friendInfo.canDonate = 0

				self:reloadData()
				return "__REMOVE__"
			end)
		end
		local receiveCallback = function()
			local donateRequest = { roleId = game.role.id, objectId = friendInfo.roleId }
			local bin = pb.encode("ReceiveDonatedHealth", donateRequest)
			game:sendData(actionCodes.FriendReceiveHealth, bin)
			loadingShow()
			game.role:addEventListener("ErrorCode" .. SYS_ERR_FRIEND_RECV_SUCCESS, function(event)
				loadingHide()
				DGMsgBox.new({ msgId = SYS_ERR_FRIEND_RECV_SUCCESS })
				friendInfo.canReceive = 0

				self:reloadData()

				game.role:dispatchEvent({ name = "notifyNewMessage", type = "friendHealth" })
				return "__REMOVE__"
			end)
		end

		if friendInfo.canReceive == 1 then
			btnText = { text = "领取体力", size = 26, font = ChineseFont, strokeColor = uihelper.hex2rgb("#242424") }
			btnCallback = receiveCallback
			res = {"btn_green_nol.png", "btn_green_sel.png", "middle_disabled.png"}
		elseif friendInfo.canDonate == 1 then
			btnText = { text = "赠送体力", size = 26, font = ChineseFont, strokeColor = uihelper.hex2rgb("#242424") }
			btnCallback = donateCallback
			res = {"middle_normal.png", "middle_selected.png", "middle_disabled.png"}
		end

		if not btnText then return bgBtn end

		local healthBtn = DGBtn:new(GlobalRes, res,
			{
				parent = self.contentLayer,
				text = btnText,
				priority = self.priority - 1,
				callback = btnCallback,
			})
		healthBtn:getLayer():anch(1, 0.5):pos(btnSize.width - 20, btnSize.height / 2):addTo(bgBtn)
	end

	local viewHandler = LuaEventHandler:create(function(fn, table, a1, a2)
		local result
		if fn == "cellSize" then
			result = self.cellSize

		elseif fn == "cellAtIndex" then
			if not a2 then
				a2 = CCTableViewCell:new()
				local cell = display.newNode()
				a2:addChild(cell, 0, 1)
			end

			-- 更新cell
			local cell = tolua.cast(a2:getChildByTag(1), "CCNode")
			createFriendNode(cell, a1)
			result = a2

		elseif fn == "numberOfCells" then
			result = math.ceil(#self.searchFriends)
		end

		return result
	end)

	self.scrollView = CCNodeExtend.extend(LuaTableView:createWithHandler(viewHandler, self.scrollSize))
	self.scrollView:setBounceable(true)
	self.scrollView:setTouchPriority(self.priority - 1)
	self.scrollView:anch(0.5, 0):pos(self.size.width / 2, 30):addTo(self.contentLayer)


	if table.nums(self.searchFriends) == 0 then
		ui.newTTFLabel({text = "您还没有好友，快去添加好友吧！", font = ChineseFont, size = 30}):anch(0.5, 0.5):pos(self.size.width/2, self.size.height/2):addTo(self.contentLayer)
	end
end

function FriendLayer:showAddFriendLayer()
	if self.contentLayer then
		self.contentLayer:removeSelf()
		self.contentLayer = nil
	end

	self.contentLayer = display.newLayer()
	self.contentLayer:size(self.size)
	self.contentLayer:anch(0,0):pos(0,0):addTo(self)

	self:showTopBar("addFriend")

	local function createSearchCell(roleInfo)
		--动态cell
		local bgBtn = DGBtn:new(FriendRes, { "friend_cell_bg.png" }, {
			parent = self.scrollView:getLayer(),
			priority = self.priority,
			callback = function()
				local bin = pb.encode("SimpleEvent", { roleId = roleInfo.roleId })
				game:sendData(actionCodes.RoleDigestInfoRequest, bin)
				game:addEventListener(actionModules[actionCodes.RoleDigestInfoResponse], function(event)
					local roleDigest = pb.decode("RoleLoginResponse", event.data)
					local roleDigestLayer = RoleDetailLayer.new({ priority = self.priority - 10, roleDigest = roleDigest })
					roleDigestLayer:getLayer():addTo(display.getRunningScene())

					return "__REMOVE__"
				end)
			end
		}):getLayer()
		local btnSize = bgBtn:getContentSize()

		local mainHeroIcon = HeroHead.new({ type = roleInfo.mainHeroType, wakeLevel = roleInfo.wakeLevel, star = roleInfo.star, evolutionCount = roleInfo.evolutionCount }):getLayer()
		if roleInfo.vipLevel > 0 then
			display.newSprite(string.format("resource/ui_rc/shop/recharge/vip_text_%d.png", roleInfo.vipLevel))
				:scale(0.8):anch(0.5, 0):pos(mainHeroIcon:getContentSize().width - 14, 0):addTo(mainHeroIcon)
		end
		mainHeroIcon:anch(0, 0.5):pos(25, btnSize.height / 2):addTo(bgBtn)

		local infoBg = display.newSprite(GlobalRes .. "cell_namebar.png")
		local infoSize = infoBg:getContentSize()
		local name = ui.newTTFLabel({text = roleInfo.name, size = 26, color = display.COLOR_WHITE, font = ChineseFont })
			:anch(0, 0.5):pos(20, infoSize.height / 2):addTo(infoBg)
		ui.newTTFLabel({text = "Lv. " .. roleInfo.level, size = 22, color = uihelper.hex2rgb("#ffdc7d") })
			:anch(0, 0):pos(name:getContentSize().width + 2, 0):addTo(name)

		local pvpGiftData = pvpGiftCsv:getGiftData(roleInfo.pvpRank)
		if pvpGiftData then
			infoBg:anch(0, 1):pos(220, btnSize.height - 30):addTo(bgBtn)

			ui.newTTFLabelWithStroke({ text = "称号:", size = 20, font = ChineseFont, color = display.COLOR_WHITE })
				:anch(0, 0):pos(220, 20):addTo(bgBtn)
			ui.newTTFLabelWithStroke({ text = pvpGiftData.name, size = 20, font = ChineseFont, color = uihelper.hex2rgb("#ffd200") })
				:anch(0, 0):pos(280, 20):addTo(bgBtn)
		else
			infoBg:anch(0, 0.5):pos(220, btnSize.height / 2):addTo(bgBtn)
		end

		local addFriendBtn 
		addFriendBtn = DGBtn:new(GlobalRes, {"btn_green_nol.png", "btn_green_sel.png", "middle_disabled.png"},
			{
				parent = self.scrollView:getLayer(),
				text = { text = "加好友", size = 26, font = ChineseFont, color=display.COLOR_WHITE, strokeColor = uihelper.hex2rgb("#242424") },
				priority = self.priority - 1,
				callback = function()
					local applicationInfo = {
						roleId = game.role.id,
						objectId = roleInfo.roleId,
						timestamp = game:nowTime(),
					}

					local bin = pb.encode("ApplicationInfo", applicationInfo)
					game:sendData(actionCodes.FriendCreateApplication, bin)
					addFriendBtn:setEnable(false)

					-- 弹框
					DGMsgBox.new({ msgId = 160 })
					-- 已经添加过的不在显示
					local deleteIndex
					for pos, searchRole in ipairs(self.searchRoles) do
						if roleInfo.roleId and searchRole.roleId == roleInfo.roleId then
							deleteIndex = pos
						end
					end
					table.remove(self.searchRoles, deleteIndex)
					self.scrollView:reloadData(self.searchRoles)
				end,
			})
		addFriendBtn:getLayer():anch(1, 0.5):pos(btnSize.width - 40, btnSize.height / 2):addTo(bgBtn)
		return bgBtn
	end
	
	self.scrollView = DGScrollView:new({ 
		size = self.scrollSize, divider = 5,
		priority = self.priority - 1,
		dataSource = self.searchRoles,
		cellAtIndex = function(roleInfo)
			return createSearchCell(roleInfo)
		end
	})

	self.scrollView:reloadData()
	self.scrollView:getLayer():anch(0.5, 0):pos(self.size.width / 2, 25):addTo(self.contentLayer)
end

function FriendLayer:showApplicationLayer(applications)
	if self.contentLayer then
		self.contentLayer:removeSelf()
		self.contentLayer = nil
	end

	self.contentLayer = display.newLayer()
	self.contentLayer:size(self.size)
	self.contentLayer:anch(0,0):pos(0,0):addTo(self)

	local function createApplicationNode(parentNode, cellIndex)
		parentNode:removeAllChildren()

		local applicationInfo = applications[#applications - cellIndex]
		local bgBtn = DGBtn:new(FriendRes, { "friend_cell_bg.png" }, {
			parent = self.contentLayer,
			priority = self.priority,
			callback = function()
				local bin = pb.encode("SimpleEvent", { roleId = applicationInfo.roleId })
				game:sendData(actionCodes.RoleDigestInfoRequest, bin)
				game:addEventListener(actionModules[actionCodes.RoleDigestInfoResponse], function(event)
					local roleDigest = pb.decode("RoleLoginResponse", event.data)
					local roleDigestLayer = RoleDetailLayer.new({ priority = self.priority - 10, roleDigest = roleDigest })
					roleDigestLayer:getLayer():addTo(display.getRunningScene())

					return "__REMOVE__"
				end)
			end
		}):getLayer():addTo(parentNode)
		local btnSize = bgBtn:getContentSize()

		local infoBg = display.newSprite(GlobalRes .. "cell_namebar.png")
		local infoSize = infoBg:getContentSize()
		local name = ui.newTTFLabel({text = applicationInfo.name, size = 26, color = display.COLOR_WHITE, font = ChineseFont })
			:anch(0, 0.5):pos(20, infoSize.height / 2):addTo(infoBg)
		ui.newTTFLabel({text = "Lv. " .. applicationInfo.level, size = 22, color = uihelper.hex2rgb("#ffdc7d") })
			:anch(0, 0):pos(name:getContentSize().width + 2, 0):addTo(name)

		local pvpGiftData = pvpGiftCsv:getGiftData(applicationInfo.pvpRank)
		if pvpGiftData then
			infoBg:anch(0, 1):pos(30, btnSize.height - 30):addTo(bgBtn)

			ui.newTTFLabelWithStroke({ text = "称号:", size = 20, font = ChineseFont, color = display.COLOR_WHITE })
				:anch(0, 0):pos(30, 20):addTo(bgBtn)
			ui.newTTFLabelWithStroke({ text = pvpGiftData.name, size = 20, font = ChineseFont, color = uihelper.hex2rgb("#ffd200") })
				:anch(0, 0):pos(90, 20):addTo(bgBtn)
		else
			infoBg:anch(0, 0.5):pos(30, btnSize.height / 2):addTo(bgBtn)
		end

		ui.newTTFLabel({text = "想加你为好友!", size = 26, color = uihelper.hex2rgb("#b0420b")})
			:anch(0, 0.5):pos(300, btnSize.height / 2):addTo(bgBtn)

		local agreeBtn = DGBtn:new(GlobalRes, {"btn_green_nol.png", "btn_green_sel.png"},
			{
				parent = self.contentLayer,
				priority = self.priority - 1,
				callback = function()
					local handleApplication = {
						roleId = game.role.id,
						objectId = applicationInfo.roleId,
						handleCode = "Agree",
					}

					local bin = pb.encode("HandleApplication", handleApplication)
					game:sendData(actionCodes.FriendHandleApplication, bin)
					game.role:addEventListener("ErrorCode71", function(event)
						game.role:dispatchEvent({ name = "notifyNewMessage", type = "friendApplication" })

						local deleteIndex
						for index, application in ipairs(applications) do
							if application.roleId == applicationInfo.roleId then
								deleteIndex = index
							end
						end		
						table.remove(applications, deleteIndex)

						self:reloadData()
						return "__REMOVE__"
					end)
				end,
				text = { text = "同意", size = 26, font = ChineseFont, color=display.COLOR_WHITE, strokeColor = uihelper.hex2rgb("#242424") }
			})
		agreeBtn:getLayer():anch(1, 0.5):pos(btnSize.width - 20, btnSize.height / 2):addTo(bgBtn)

		local denyBtn = DGBtn:new(GlobalRes, {"middle_normal.png", "middle_selected.png", "middle_disabled.png"},
			{
				parent = self.contentLayer,
				priority = self.priority - 1,
				callback = function()
					local handleApplication = {
						roleId = game.role.id,
						objectId = applicationInfo.roleId,
						handleCode = "Deny",
					}

					local bin = pb.encode("HandleApplication", handleApplication)
					game:sendData(actionCodes.FriendHandleApplication, bin)
					game.role:addEventListener("ErrorCode72", function(event)
						game.role:dispatchEvent({ name = "notifyNewMessage", type = "friendApplication" })
						
						local deleteIndex
						for index, application in ipairs(applications) do
							if application.roleId == applicationInfo.roleId then
								deleteIndex = index
							end
						end
						table.remove(applications, deleteIndex)

						self:reloadData()
						return "__REMOVE__"
					end)
				end,
				text = { text = "拒绝", size = 26, font = ChineseFont, color=display.COLOR_WHITE, strokeColor = uihelper.hex2rgb("#242424") }
			})
		denyBtn:getLayer():anch(1, 0.5):pos(btnSize.width - 170, btnSize.height / 2):addTo(bgBtn)
	end

	-- if #applications > 0 then
	-- 	uihelper.newMsgTag(self.tableRadioGrp:getChooseBtn():getLayer())
	-- end

	local viewHandler = LuaEventHandler:create(function(fn, table, a1, a2)
		local result
		if fn == "cellSize" then
			result = self.cellSize

		elseif fn == "cellAtIndex" then
			if not a2 then
				a2 = CCTableViewCell:new()
				local cell = display.newNode()
				a2:addChild(cell, 0, 1)
			end

			-- 更新cell
			local cell = tolua.cast(a2:getChildByTag(1), "CCNode")
			createApplicationNode(cell, a1)
			result = a2

		elseif fn == "numberOfCells" then
			result = math.ceil(#applications)
		end

		return result
	end)

	self.scrollView = CCNodeExtend.extend(LuaTableView:createWithHandler(viewHandler, self.scrollSize))
	self.scrollView:setBounceable(true)
	self.scrollView:setTouchPriority(self.priority - 1)
	self.scrollView:anch(0.5, 0):pos(self.size.width / 2, 30):addTo(self.contentLayer)
end

function FriendLayer:reloadData()
	if self.scrollView then
		local offset = self.scrollView:getContentOffset()
		self.scrollView:reloadData()
		self.scrollView:setBounceable(false)
		self.scrollView:setContentOffset(offset)
		self.scrollView:setBounceable(true)
	end
end

function FriendLayer:onExit()
	if self.messageTag then
		game.role:removeEventListener("notifyNewMessage", self.messageTag)
	end

	if self.healthTag then
		game.role:removeEventListener("notifyNewMessage", self.healthTag)
	end

	display.removeUnusedSpriteFrames()
end

return FriendLayer