local TowerSceneCsvData = {
	m_data = {}
}

function TowerSceneCsvData:load(fileName)
	self.m_data = {}

	local csvData = CsvLoader.load(fileName)

	for index = 1, #csvData do
		local sceneId = tonum(csvData[index]["场景ID"])
		if sceneId > 0 then
			self.m_data[sceneId] = {
				sceneId = sceneId,
				heroType = tonum(csvData[index]["武将1"]),
				sceneCsv = csvData[index]["场景配表"],
				sceneBg = csvData[index]["场景背景"],
			}
		end
	end
end

function TowerSceneCsvData:getSceneData(sceneId)
	return self.m_data[sceneId]
end

return TowerSceneCsvData