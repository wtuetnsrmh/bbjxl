--所有武将的动作ID
HeroActionId = {
    ["standby"] = 1,
    ["attack"] = 2,
    ["move"] = 3,
    ["dead"] = 4,
    ["skillAttack"] = 5,
}

local ActionModelCsvData = {
	m_data = {},
}

function ActionModelCsvData:load(fileName)
	self.m_data = {}
	
	local csvData = CsvLoader.load(fileName)

	for index = 1, #csvData do
		local actionId = tonum(csvData[index]["id"])
		local actionFrames = string.trim(csvData[index]["动作帧"])
		if id ~= 0  then
			self.m_data[actionId] = {
				id = actionId,
				name = csvData[index]["动作"],
				fps = tonum(csvData[index]["帧率"]),
				frameIDs = actionFrames == "" and {} or string.split(actionFrames, " "),
				effectFrame = csvData[index]["特效开始帧"],
			}
		end
	end
end

function ActionModelCsvData:getActionById(actionId)
	return self.m_data[actionId]
end

return ActionModelCsvData