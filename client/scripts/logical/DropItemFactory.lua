local DropItemFactory = {}

-- 关卡普掉
-- @param carbonId	关卡ID
-- @param battleStarNum	战斗结果星级
function DropItemFactory.commonDrop(carbonId, battleStarNum)
	local result = {}

	local dropDatas = dropCsv:getDropData(carbonId)
	-- 没有普掉数据
	if not dropDatas or #dropDatas == 0 then return result end

	for _, dropData in ipairs(dropDatas) do
		-- 随机物品类型
		local weightArray = {}
		for _, value in ipairs(dropData.commonDrop) do
			if #value == 3 then
				weightArray[#weightArray + 1] = {
					itemTypeId = tonumber(value[1]),
					num = tonumber(value[2]),
					weight = tonumber(value[3]),
				}
			end
		end

		local propability = dropData.commonDropProbability * tonumber(dropData.commonStarModify[tostring(battleStarNum)]) / 100.0
		for count = 1, dropData.commonDropTime do
			if randomFloat(0, 100.0) <= propability then
				local randIndex = randWeight(weightArray)
				if randIndex then 
					-- item weight 数据
					local itemTypeId = weightArray[randIndex].itemTypeId
					local itemWeightModifyData = itemWeightModifyCsv:getModifyData(itemTypeId)

					-- 取出来的结构都是 { itemId=xxxx, weight = xxxx, }
					local itemWeightArray = nil
					if itemTypeId == ItemTypeId.Item then
						itemWeightArray = itemCsv:getItemWeightArray(itemWeightModifyData)
					elseif itemTypeId == ItemTypeId.Hero then
						itemWeightArray = unitCsv:getUnitWeightArray({ 
							starWeights = dropData.commonStarModify,
						})
					end

					for index = 1, weightArray[randIndex].num do
						local randIndex = randWeight(itemWeightArray)
						if randIndex then
							result[#result + 1] = {
								itemTypeId = itemTypeId,
								itemId = itemWeightArray[randIndex].itemId,
								num = 1,
							}
						end
					end
				end
			end
		end
	end

	return result
end

-- 关卡特掉
-- @param carbonId	关卡ID
-- @param battleStarNum	战斗结果星级
function DropItemFactory.specialDrop(carbonId, battleStarNum)
	local result = {}

	local dropDatas = dropCsv:getDropData(carbonId)
	-- 没有普掉数据
	if not dropDatas or #dropDatas == 0 then return result end

	for _, dropData in ipairs(dropDatas) do
		for index = 1, 3 do
			-- 随机物品类型
			local weightArray = {}
			for _, value in ipairs(dropData["specialDrop" .. index]) do
				if #value == 4 then
					weightArray[#weightArray + 1] = {
						itemTypeId = tonumber(value[1]),
						itemId = tonumber(value[2]),
						num = tonumber(value[3]),
						weight = tonumber(value[4]),
					}
				end
			end

			local propability = dropData["specialDropProbability" .. index] * tonumber(dropData.specialStarModify[tostring(battleStarNum)]) / 100.0
			for count = 1, dropData["specialDropTime" .. index] do
				if randomFloat(0, 100.0) <= propability then
					local randIndex = randWeight(weightArray)
					if randIndex then
						result[#result + 1] = {
							itemTypeId = weightArray[randIndex].itemTypeId,
							itemId = weightArray[randIndex].itemId,
							num = weightArray[randIndex].num,
						}
					end
				end
			end
		end
	end
	return result
end

-- 礼包掉落
function DropItemFactory.giftDrop(giftDropId, params)
	local result = {}

	local giftDropData = giftDropCsv:getDropData(giftDropId)
	if not giftDropData then return result end

	-- 随机物品类型
	local weightArray = {}
	for _, value in ipairs(giftDropData.specialDrop) do
		if #value == 2 then
			weightArray[#weightArray + 1] = {
				itemTypeId = giftDropData.itemTypeId,
				itemId = tonumber(value[1]),
				num = 1,
				weight = tonumber(value[2]),
			}
		end
	end

	local specialDropDown = false
	for cnt = 1, giftDropData.specialDropTime do
		if randomFloat(0, 100.0) <= giftDropData.specialDropProbability then
			specialDropDown = true

			local randIndex = randWeight(weightArray)
			if randIndex then
				result[#result + 1] = {
						itemTypeId = weightArray[randIndex].itemTypeId,
						itemId = weightArray[randIndex].itemId,
						num = weightArray[randIndex].num,
					}
			end
		end
	end

	-- 特掉成功后不触发普掉
	if specialDropDown then return result end

	-- 特掉没有掉，开始普掉
	local starWeightData = clone(giftDropData.starModify)
	if table.nums(starWeightData) == 0 or starWeightData["0"] ~= nil then
		starWeightData = { ["1"] = 1, ["2"] = 1, ["3"] = 1, ["4"] = 1, ["5"] = 1}
	end

	for cnt = 1, giftDropData.commonDropTime do
		-- 武将有星级阀值限定
		if giftDropData.itemTypeId == ItemTypeId.Hero or giftDropData.itemTypeId == ItemTypeId.HeroFragment then
			local starThresholdWeights = {}
			-- 计算玩家阀值星级的权重
			for star, floor in pairs(giftDropData.starThresholdFloor) do
				local floor = tonumber(floor)
				local ceil = tonumber(giftDropData.starThresholdCeil[star])
				local currentCount = game.redisClient:hget(string.format("role:%d:giftDrop:%d", params.roleId, giftDropId), star)
				if tonum(currentCount) < floor then
					starThresholdWeights[star] = 0
				elseif tonum(currentCount) >= ceil then
					starThresholdWeights[star] = 100
				else
					starThresholdWeights[star] = 100 * (tonum(currentCount) - floor) / (ceil - floor)
				end
			end

			local totalThresholdWeights = 0
			for star, weight in pairs(starThresholdWeights) do
				totalThresholdWeights = totalThresholdWeights + weight
			end

			if totalThresholdWeights >= 100 then
				-- 此时阀值里面的星级一定要抽出来, 只考虑阀值的星级卡牌
				local thresholdModify = {}
				for star, weight in pairs(starThresholdWeights) do
					thresholdModify[star] = weight / totalThresholdWeights * 100
				end
				starWeightData = thresholdModify

			elseif totalThresholdWeights == 0 then
				-- 阀值里面的星级一定不能出来
				for star, weight in pairs(starThresholdWeights) do
					starWeightData[star] = 0
				end

			else
				-- 可以缓缓, 抽出其他星级的武将, 不排除阀值星级武将
				-- 权值可以优化
				for star, weight in pairs(starThresholdWeights) do
					starWeightData[star] = weight
				end
			end

			local itemWeightArray = unitCsv:getUnitWeightArray({ 
				professionWeights = giftDropData.professionWeights, 
				campWeights = giftDropData.campWeights, 
				starWeights = starWeightData
			})

			local randIndex = randWeight(itemWeightArray)
			result[#result + 1] = {
				itemTypeId = giftDropData.itemTypeId,
				itemId = itemWeightArray[randIndex].itemId,
				num = 1,
			}

			-- 更新玩家阀值星级的次数
			local unitData = unitCsv:getUnitByType(itemWeightArray[randIndex].itemId)
			for star, floor in pairs(giftDropData.starThresholdFloor) do
				local currentCount = game.redisClient:hget(string.format("role:%d:giftDrop:%d", params.roleId, giftDropId), star)
				if unitData.stars == tonumber(star) then
					-- 选中后, 次数清零
					game.redisClient:hset(string.format("role:%d:giftDrop:%d", params.roleId, giftDropId), star, "0")
				else
					-- 未选中, 次数增加
					game.redisClient:hset(string.format("role:%d:giftDrop:%d", params.roleId, giftDropId), star, tonum(currentCount) + 1)
				end
			end
		else
			local itemWeightArray = unitCsv:getUnitWeightArray({ 
				professionWeights = giftDropData.professionWeights, 
				campWeights = giftDropData.campWeights, 
				starWeights = starWeightData
			})

			local randIndex = randWeight(itemWeightArray)
			result[#result + 1] = {
				itemTypeId = giftDropData.itemTypeId,
				itemId = itemWeightArray[randIndex].itemId,
				num = 1,
			}
		end
	end

	return result
end

return DropItemFactory