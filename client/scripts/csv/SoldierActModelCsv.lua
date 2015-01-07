local SoldierActModelCsvData = {
	m_data = {},
}

function SoldierActModelCsvData:load(fileName)
	self.m_data = {}
	
	local csvData = CsvLoader.load(fileName)
	for index = 1, #csvData do
		local id = tonum(csvData[index]["id"])
		if id > 0 then
			local act = {}
			act.id = id
			act.action = csvData[index]["动作"]
			act.actionPrefix = csvData[index]["动作前缀"]
			act.frameRate = csvData[index]["帧率"]
			act.starFrame = csvData[index]["起始帧"]
			act.endFrame =p arser:getString(index, "结束帧")	

			m_data[id] = act
		end
	end
end