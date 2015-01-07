require("utils.StringUtil")

BulletActionId = {
	["begin"]= 1,
	["progress"] = 2,
	["end"] = 3,
	["hurt"] = 4,
}

local BulletActCsvData = {
	m_data = {},
}

function BulletActCsvData:load(fileName)
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
				musicId = tonum(csvData[index]["音效ID"]),
				layer = tonum(csvData[index]["模型下层"]),
			}
		end
	end
end

function BulletActCsvData:getActDataById(actionId)
	return self.m_data[actionId]
end

return BulletActCsvData