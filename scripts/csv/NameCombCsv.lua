local NameCombCsvData = {
	pool1 = {},
	pool2 = {},
	pool3 = {},
}

function NameCombCsvData:load(fileName)
	self.pool1 = {}
	self.pool2 = {}
	self.pool3 = {}

	self.m_data = {}
	
	local csvData = CsvLoader.load(fileName)

	for index = 1, #csvData do
		local advid = tonum(csvData[index]["形容词ID"])
		if advid > 0 then
			self.pool1[advid] = {
				advid = advid,
				adv = tostring(csvData[index]["形容词"]),
			}
		end
		local fid = tonum(csvData[index]["姓氏ID"])
		if fid > 0 then
			self.pool2[fid] = {
				fid = fid,
				fname = tostring(csvData[index]["姓氏"]),
			}
		end
		local nid = tonum(csvData[index]["名字ID"])
		if nid > 0 then
			self.pool3[nid] = {
				nid = nid,
				name = tostring(csvData[index]["名字"]),
			}
		end
	end
end

--index 获取形容词
function NameCombCsvData:getAdvByIndex(index)

	return self.pool1[tonumber(index)]
end
--index 获取姓氏
function NameCombCsvData:getFNameByIndex(index)

	return self.pool2[tonumber(index)]
end

--index 获取名字
function NameCombCsvData:getNameByIndex(index)
	return self.pool3[tonumber(index)]
end

--形容词组库
function NameCombCsvData:getAdvs()

	return self.pool1
end
--姓氏组库
function NameCombCsvData:getFNames()

	return self.pool2
end

--名字组库
function NameCombCsvData:getNames()

	return self.pool3
end

return NameCombCsvData