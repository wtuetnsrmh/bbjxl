local BulletCsvData = {
	m_data = {}
}

function BulletCsvData:load(fileName)
	self.m_data = {}
	
	local csvData = CsvLoader.load(fileName)

	for index = 1, #csvData do
		local id = tonum(csvData[index]["子弹ID"])
		local scaleX = tonum(csvData[index]["x缩放"])
		local scaleY = tonum(csvData[index]["y缩放"])
		if id > 0 then
			self.m_data[id] = {
				id = id,
				type = tonum(csvData[index]["类型"]),
				speed = tonum(csvData[index]["速度"]),
				res = csvData[index]["子弹资源"],
				actCsv = csvData[index]["子弹动作配表"],
				tipsIcon = csvData[index]["头顶icon"],
				referenceAngle = tonum(csvData[index]["基准角"]),
				playCount = tonum(csvData[index]["发射数量"]),
				playInterval = tonum(csvData[index]["播放间隔"]),
				scaleX = scaleX > 0 and scaleX or 100,
				scaleY = scaleY > 0 and scaleY or 100,
				screenShake = tonum(csvData[index]["震屏"]),
				shakeDelay = tonum(csvData[index]["震屏延迟"]),
				jump = tonum(csvData[index]["浮空"]),
				breakAttack = tonum(csvData[index]["打断"]),
				beginXOffset = tonum(csvData[index]["开始特效x"]),
				beginYOffset = tonum(csvData[index]["开始特效y"]),
				oppositeX1 = tonum(csvData[index]["相对x1"]),
				oppositeY1 = tonum(csvData[index]["相对y1"]),
				oppositeX2 = tonum(csvData[index]["相对x2"]),
				oppositeY2 = tonum(csvData[index]["相对y2"]),
				oppositeX3 = tonum(csvData[index]["相对x3"]),
				oppositeY3 = tonum(csvData[index]["相对y3"]),
				oppositeX4 = tonum(csvData[index]["相对x4"]),
				oppositeY4 = tonum(csvData[index]["相对y4"]),
				oppositeX5 = tonum(csvData[index]["相对x5"]),
				oppositeY5 = tonum(csvData[index]["相对y5"]),
			}
		end
	end
end

function BulletCsvData:getBulletById(id)
	return self.m_data[id]
end

return BulletCsvData