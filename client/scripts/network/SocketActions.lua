local SocketActions = class("SocketActions")
local scheduler = require("framework.scheduler")

function SocketActions:ctor(app)
	self.app = app
end

function SocketActions:roleLoginResponse(event, params)
	params = params or {}

	print("SocketActions:roleLoginResponse")
	local msg = pb.decode("RoleLoginResponse", event.data)
	if msg.result == "SUCCESS" then
		self.app:setServerTime(msg.serverTime)
		-- 表示已经登录
		if not self.app.role then
			-- 英雄数据
			self.app.role = require("datamodel.Role").new(msg.roleInfo)
			msg.heros = msg.heros or {}
			for _, hero in ipairs(msg.heros) do
				local newHero = require("datamodel.Hero").new(hero)
				self.app.role.heros[newHero.id] = newHero

				if newHero.choose == 1 then
					table.insert(self.app.role.chooseHeros, newHero)
				end
			end

			-- 副本数据
			self.app.role:buildMapData(msg.carbons, msg.maps)

			-- 美人
			msg.beauties = msg.beauties or {}
			for _, beauty in pairs(msg.beauties) do
				local newBeauty = require("datamodel.Beauty").new(beauty)
				self.app.role.beauties[beauty.beautyId] = newBeauty
			end

			-- 背包数据
			msg.items = msg.items or {}
			for _, item in pairs(msg.items) do
				self.app.role.items[item.id] = item
			end

			-- 碎片
			msg.fragments = msg.fragments or {}
			for _, fragment in ipairs(msg.fragments) do
				self.app.role.fragments[fragment.fragmentId] = fragment.num
			end

			-- 装备
			msg.equips = msg.equips or {}
			for _, equip in ipairs(msg.equips) do
				local newEquip = require("datamodel.Equip").new(equip)
				self.app.role.equips[equip.id] = newEquip
			end

			-- 装备碎片
			msg.equipFragments = msg.equipFragments or {}
			for _, fragment in ipairs(msg.equipFragments) do
				self.app.role.equipFragments[fragment.fragmentId] = fragment.num
			end

			-- 每日数据
			for _, data in ipairs(msg.dailyData) do
				self.app.role[data.key] = data.value
			end

			-- 时间数据
			for _, data in ipairs(msg.timestamps) do
				self.app.role[data.key] = data.value
			end

			-- 公告
			self.app.role.notices = msg.notices

			self.app.role.store1StartTime = self.app.role.store1LeftTime > 0 and game:nowTime() or 0
			self.app.role.store3StartTime = self.app.role.store3LeftTime > 0 and game:nowTime() or 0 

			--刷新情缘
			self.app.role:refreshHeroRelation()

			-- push设置
			cc.push:doCommand({ command = "setAccount", args = string.sub(string.gsub(self.app.platform_uname or "", "@", "_"), 1, 32) })
			cc.push:doCommand({ command = "setTags", 
				args = { self.app.platform_uid, self.app.serverInfo.serverid } })

			loadingHide()

			-- 切换首页
			local battleLoadingLayer
			battleLoadingLayer = require("scenes.BattleLoadingLayer").new({ priority = -128,showText=true,
				callback = function()
					
				end,
				loadingInfo = {
					
				}
			})
			battleLoadingLayer:getLayer():addTo(display:getRunningScene())
			local actions={}
			actions[#actions+1]=CCCallFunc:create(function()
				-- 加载必要配表
				local configs = {
					["itemCsv"] = { parser = "ItemCsv", file = "csv/item.csv"},
					["skillLevelCsv"] = { parser = "SkillLevelCsv", file = "csv/skill_level.csv"},
					["skillPassiveLevelCsv"] = { parser = "SkillPassiveLevelCsv", file = "csv/skill_passive_level.csv"},
					["skillCsv"] = { parser = "SkillCsv", file = "csv/skill.csv",},
					["skillPassiveCsv"] = {parser = "SkillPassiveCsv", file = "csv/skill_passive.csv",},
				}
				for name, data in pairs(configs) do
					_G[name]:load(data.file)
				end

				switchScene("home", {toPopNotice = true, activesuccess = params.create })
			end)
			actions[#actions+1]=CCRemoveSelf:create()
			battleLoadingLayer:getLayer():runAction(transition.sequence(actions))
			
			-- 玩家数据需要处理
			local submitRoleData
			if device.platform == "android" then	
				submitRoleData = function()
					local javaClassName = PACKAGE_NAME
		    		local javaMethodName = "submitRoleData"
		    		local javaParams = {table.concat({ self.app.role.id, self.app.role.name, 
		    			self.app.role.level, self.app.serverInfo.serverid, 
		    			self.app.serverInfo.name, self.app.role.vipLevel, self.app.role.yuanbao }, ";")}
		    		print(javaParams)
		    		local javaMethodSig = "(Ljava/lang/String;)V"
		    		luaj.callStaticMethod(javaClassName, javaMethodName, javaParams, javaMethodSig)
				end
			else
				submitRoleData = function() end
			end

			submitRoleData()
	    	self.app.role:addEventListener("updateName", function(event) submitRoleData() end)
	    	self.app.role:addEventListener("updateLevel", function(event) submitRoleData() end)

	    	-- uc 玩家数据需要处理
			if PACKAGE_NAME == "com.koramgame.lwsg.uc.Xinsanguozhi" then
				local javaClassName = PACKAGE_NAME
		    	local javaMethodName = "submitExtendData"
		    	local javaParams = { self.app.role.id, self.app.role.name, self.app.role.level, 
		    		tonumber(self.app.serverInfo.serverid), self.app.serverInfo.name }
		    	local javaMethodSig = "(ILjava/lang/String;IILjava/lang/String;)V"
		    	luaj.callStaticMethod(javaClassName, javaMethodName, javaParams, javaMethodSig)
		    end
		else
			-- 覆盖玩家基本数据
			for _, field in pairs(self.app.role.class.pbField) do
				if field ~= "guideStep" then
					if self.app.role["set_" .. field] then
						self.app.role:updateProperty(field, msg.roleInfo[field])
					else
						self.app.role[field] = msg.roleInfo[field]
					end
				end
			end

			-- 时间数据
			for _, data in ipairs(msg.timestamps) do
				self.app.role[data.key] = data.value
			end

			-- 副本数据
			if msg.carbons or msg.maps then
				self.app.role:buildMapData(msg.carbons, msg.maps)
			end

			-- 每日数据
			if msg.dailyData then
				for _, data in ipairs(msg.dailyData) do
					if self.app.role["set_" .. data.key] then
						self.app.role:updateProperty(data.key, data.value)
					else
						self.app.role[data.key] = data.value
					end
				end
			end

			self.app.role.store1StartTime = self.app.role.store1LeftTime > 0 and game:nowTime() or 0
			self.app.role.store3StartTime = self.app.role.store3LeftTime > 0 and game:nowTime() or 0
		end

	elseif msg.result == "NOT_EXIST" then
		loadingHide()
		switchScene("login", { layer = "chooseHero" })

	elseif msg.result == "HAS_LOGIN" then
		loadingHide()

	elseif msg.result == "DB_ERROR" then
		loadingHide()
	end

	return "__REMOVE__"
end

return SocketActions