DailyTaskIdMap = {
	CommonCarbon = 1,
	SpecialCarbon = 2,
	HeroIntensify = 3,
	PvpBattle = 4,
	TechLevelUp = 5,
	BeautyTrain = 6,
	TowerBattle = 7,
	HeroStar = 8,
	LegendBattle = 9,
}

local DailyTaskCsvData = {
	m_data = {},
}

function DailyTaskCsvData:load(fileName)
	self.m_data = {}

	local csvData = CsvLoader.load(fileName)

	for index = 1, #csvData do
		local taskId = tonum(csvData[index]["任务ID"])
		if taskId > 0 then
			self.m_data[taskId] = {
				taskId = taskId,
				name = csvData[index]["任务名"],
				desc = csvData[index]["任务描述"],
				openLevel = tonum(csvData[index]["开放等级"]),
				count = tonum(csvData[index]["次数"]),
				exp = tonum(csvData[index]["经验"]),
				money = tonum(csvData[index]["银币"]),
				yuanbao = tonum(csvData[index]["元宝"]),
				zhangong = tonum(csvData[index]["战功"]),
				starSoul = tonum(csvData[index]["星魂"]),
				heroSoul = tonum(csvData[index]["将魂"]),
				items = string.tomap(csvData[index]["道具"]),
				icon = csvData[index]["icon"],
			}
		end
	end
end

function DailyTaskCsvData:getTaskById(taskId)
	return self.m_data[taskId]
end

return DailyTaskCsvData