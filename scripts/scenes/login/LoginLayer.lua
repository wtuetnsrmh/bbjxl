local GlobalRes = "resource/ui_rc/global/"
local LoginResRc = "resource/ui_rc/login_rc/"


local LoginLayer = class("LoginLayer", function(params)
	return display.newLayer()
end)

function LoginLayer:ctor(params)
	-- 切换到登录界面, 角色都清空
	if game.role then
		game.role:reset()
	end
	game.role = nil

	self.serverList = ServerConf[ServerIndex].serverList

	self.size = self:getContentSize()
	
	--背景
	display.newSprite(LoginResRc .. "enter_bg.jpg"):anch(0.5, 0):pos(display.cx, 0):addTo(self)

	self.canEnter = false

	self.enterBtn = DGBtn:new(LoginResRc, {"btn_start_normal.png", "btn_start_selected.png"},
		{	
			musicId = 32,
			callback = function()
				if not self.canEnter then return end

				if not GameData.lastServerId then
					DGMsgBox.new({ type = 1, text = "请选择服务器"})
					return
				end
				local serverInfo = self.serverList[GameData.lastServerId]
				game.serverInfo = serverInfo
				if game:newSocket(serverInfo.host, serverInfo.port) then
					local bin = pb.encode("RoleQueryLogin", { uid = game.platform_uid })
					game:sendData(actionCodes.RoleQueryLogin, bin)
					loadingShow()
					game:addEventListener(actionModules[actionCodes.RoleQueryResponse], function(event)
						loadingHide()
						local msg = pb.decode("RoleQueryResponse", event.data)
						if msg.ret == "RET_NOT_EXIST" then
							switchScene("login", { layer = "chooseHero", chooseStep = "start" })
						elseif msg.ret == "RET_HAS_EXISTED" then
							local bin = pb.encode("RoleLoginData", { name = msg.name })
							game:sendData(actionCodes.RoleLoginRequest, bin)
							-- loadingShow()							
							game:addEventListener(actionModules[actionCodes.RoleLoginResponse], function(event)
								socketActions:roleLoginResponse(event)
								return "__REMOVE__"
							end)
						elseif msg.ret == "INNER_ERROR" then
							game:closeSocket()
						end
						return "__REMOVE__"
					end)
					
				end
			end
		}):getLayer()
	self.enterBtn:anch(0.5, 0):pos(self.size.width / 2 + 300, 48):addTo(self)

	if GameData.user and not params.logout then
		local host = ServerConf[ServerIndex].as 

		local url = string.format("http://%s/proxy?name=%s", host, GameData.user)
		local request = network.createHTTPRequest(function(event) 
			local request = event.request
			if event.name == "completed" then
				if request:getResponseStatusCode() == 200 then
					game.platform_uid = tonumber(request:getResponseData())

					self:showCurrentServer()
				end
			end
		end, url, "GET")

		request:setTimeout(waittime or 30)
		request:start()
	else
		self:showUserAccount()
	end
end

function LoginLayer:showServerList()
	if self.serverLayer then
		self.serverLayer:removeSelf()
	end

	self.enterBtn:setVisible(false)
	self.enterBtn:setTouchEnabled(false)

	self.serverLayer = display.newLayer(LoginResRc .. "server_bg.png")
	self.serverLayer:anch(0.5, 0):pos(self.size.width / 2, 50):addTo(self, 99)
	local bgSize = self.serverLayer:getContentSize()

	local function initCellByServer(cell, serverInfo)
		local cellSize = cell:getContentSize()

		local col = GameData.lastServerId == serverInfo.id and uihelper.hex2rgb("#f8e716") or display.COLOR_WHITE
		ui.newTTFLabel({text = string.format("%d区-%s", serverInfo.id, serverInfo.name), size = 22, color = col})
			:anch(0, 0.5):pos(52, cellSize.height / 2):addTo(cell)

		display.newSprite(LoginResRc .. (serverInfo.free < 0.5 and "hot_server.png" or "new_server.png"))
			:scale(0.8):anch(0, 0.5):pos(12, cellSize.height / 2):addTo(cell)
	end

	local xBegin = 30
	-- 最近登录
	local lastServerId = GameData.lastServerId
	local lastServerBtn = DGBtn:new(LoginResRc, {"server_listcell_long.png", "server_listcell_long_sel.png"},
		{	
			callback = function()
				self:showCurrentServer()
			end,
		})
	lastServerBtn:setEnable(false)

	local btnSize = lastServerBtn:getLayer():getContentSize()
	if lastServerId then
		lastServerBtn:setEnable(true)

		local serverInfo = self.serverList[lastServerId]
		initCellByServer(lastServerBtn:getLayer(), serverInfo) 
	else
		ui.newTTFLabelWithStroke({text = "请选择服务器", size = 26 })
			:pos(btnSize.width / 2, btnSize.height / 2):addTo(lastServerBtn:getLayer())
	end
	lastServerBtn:getLayer():anch(0.5, 1):pos(bgSize.width/2, bgSize.height - 48)
		:addTo(self.serverLayer)

	local xInterval = bgSize.width - 2 * xBegin - 2 * 196
	-- 服务器列表
	local serverScroll = DGScrollView:new({ size = CCSizeMake(bgSize.width, 170), divider = 10})
	for index = 1, math.ceil(#self.serverList) do
		local cellNode = display.newNode()
		cellNode:size(bgSize.width, 60)
		for inner = 1, 2 do
			local serverInfo = self.serverList[(index - 1) * 2 + inner]
			if serverInfo then
				local serverBtn = DGBtn:new(LoginResRc, {"server_listcell.png", "server_listcell_sel.png"},
					{	
						callback = function()
							GameData.lastServerId = serverInfo.id
							GameState.save(GameData)

							self:showCurrentServer()
						end,
					}):getLayer()
				initCellByServer(serverBtn, serverInfo)
				serverBtn:pos(xBegin + (inner - 1) * (196 + xInterval), 0):addTo(cellNode)
			end
		end

		serverScroll:addChild(cellNode)
	end

	serverScroll:getLayer():anch(0.5, 0):pos(bgSize.width / 2, 10):addTo(self.serverLayer)
end

function LoginLayer:showUserAccount()
	local priority = -200
	-- 屏蔽点击
	local mask = display.newColorLayer(ccc4(100, 100, 100, 100))
	mask:setTouchEnabled(true)
	mask:registerScriptTouchHandler(function(eventType, x, y)
		if eventType == "began" then return true end
		if eventType == "moved" then return true end
		if eventType == "end" then return true end
		end, false, priority, false)
	mask:anch(0.5, 0.5):pos(self.size.width / 2, self.size.height / 2):addTo(self, 100)

	local userNameDialog = display.newLayer(GlobalRes .. "tips_middle.png")
	userNameDialog:anch(0.5, 0.5):pos(display.cx, display.cy):addTo(mask)
	-- userNameDialog:setTouchPriority(priority - 1)
	local bgSize = userNameDialog:getContentSize()

	-- 最近登录
	display.newTextSprite(LoginResRc .. "server_splitter.png", { text = "用户名", size = 28 })
		:pos(bgSize.width / 2, bgSize.height - 40):addTo(userNameDialog)

	local userInputBox = ui.newEditBox({
		image = LoginResRc .. "server_cell.png",
		size = CCSize(258, 58),
		listener = function(event, editbox)
			if event == "began" then
			elseif event == "ended" then
			elseif event == "return" then
			elseif event == "changed" then
			end
		end
	})
	userInputBox:setMaxLength(12)
	userInputBox:setTouchPriority(priority - 1)
	userInputBox:setFontColor(display.COLOR_DARKYELLOW)
	userInputBox:setReturnType(kKeyboardReturnTypeSend)
	userInputBox:anch(0.5, 0):pos(bgSize.width / 2, 80):addTo(userNameDialog)
	userInputBox:setFontColor(ccc3(0, 255, 0))

	local confirmBtn = DGBtn:new(GlobalRes, {"btn_small_nol.png", "btn_small_sel.png"},
		{	
			priority = priority - 1,
			text = { text = "确定", font = ChineseFont, strokeColor = display.COLOR_FONT },
			callback = function()
				local userName = userInputBox:getText()
				if #userName == 0 then 
					DGMsgBox.new({ type = 1, text = "请输入账号" })
					return 
				end

				local host = ServerConf[ServerIndex].as

				local url = string.format("http://%s/proxy?name=%s", host, userName)
				local request = network.createHTTPRequest(function(event) 
					local request = event.request
					if event.name == "completed" then
						if request:getResponseStatusCode() == 200 then
							game.platform_uid = tonumber(request:getResponseData())
							
							GameData.user = userName
							GameState.save(GameData)

							mask:removeSelf()
							self:showCurrentServer()
						end
					end
				end, url, "GET")

				request:setTimeout(waittime or 30)
				request:start()
			end,
		}):getLayer()
	confirmBtn:anch(0.5, 0):pos(bgSize.width / 2, 20):addTo(userNameDialog)
end

function LoginLayer:showCurrentServer()
	if self.serverLayer then
		self.serverLayer:removeSelf()
	end

	self.enterBtn:setVisible(true)
	self.enterBtn:setTouchEnabled(true)

	self.serverLayer = DGBtn:new(LoginResRc, {"server_cell.png", "server_cell_sel.png"},
		{	
			callback = function()
				self:showServerList()
			end,
		}):getLayer()
	self.serverLayer:anch(0.5, 0):pos(self.size.width / 2, 50):addTo(self)

	local cellSize = self.serverLayer:getContentSize()

	local lastServerId = GameData.lastServerId
	if not lastServerId or lastServerId > #self.serverList then
		GameData.lastServerId = 1
		GameState.save(GameData)
	end

	local serverInfo = self.serverList[GameData.lastServerId]
	local cellSize = self.serverLayer:getContentSize()

	ui.newTTFLabel({text = string.format("%d区-%s", serverInfo.id, serverInfo.name), size = 24})
		:anch(0, 0.5):pos(85, cellSize.height / 2):addTo(self.serverLayer)

	display.newSprite(LoginResRc .. (serverInfo.free < 0.5 and "hot_server.png" or "new_server.png"))
		:anch(0, 0.5):pos(23, cellSize.height / 2):addTo(self.serverLayer)

	ui.newTTFLabel({text = "点击换区", size = 24, color = uihelper.hex2rgb("#ffe613") })
		:anch(1, 0.5):pos(cellSize.width - 30, cellSize.height / 2):addTo(self.serverLayer)

	self.canEnter = true
end

return LoginLayer