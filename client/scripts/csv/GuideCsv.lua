local GuideCsvData = {
	m_data = {},
	m_step_index = {}
}

function GuideCsvData:load(fileName)
	self.m_data = {}
	self.m_step_index = {}

	local csvData = CsvLoader.load(fileName)

	for index = 1, #csvData do
		local guideId = tonum(csvData[index]["引导ID"])
		if guideId > 0 then
			self.m_data[guideId] = {
				guideId = guideId,
				type = tonum(csvData[index]["类型"]),
				step = tonum(csvData[index]["记录ID"]),
				beautyPos = string.split(string.trim(csvData[index]["小人对话左下角坐标"]), " "),
				beautyTips = csvData[index]["小人内容"],
				talkId = tonum(csvData[index]["talkID"]),
				nextGuideId = tonum(csvData[index]["触发新引导ID"]),
				flipX = tonum(csvData[index]["小人对话方向"]),
				degree = tonum(csvData[index]["旋转角度"]),
				distance = tonum(csvData[index]["距离"]),
				updateStep = tonum(csvData[index]["步骤跳转"]),
			}

			local step = self.m_data[guideId].step
			if step > 0 then
				self.m_step_index[step] = self.m_data[guideId]
			end
		end
	end
end

function GuideCsvData:getGuideById(id)
	return self.m_data[id]
end

function GuideCsvData:getStepStartGuide(step)
	return self.m_step_index[step]
end

return GuideCsvData