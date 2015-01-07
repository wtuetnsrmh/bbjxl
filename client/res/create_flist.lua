-- 生成配置文件更新列表
-- by yangkun
-- 2014.5.14

local lfs = require "lfs"
local md5 = require "md5"

local function hex(s)
	s=string.gsub(s,"(.)",function (x) return string.format("%02X",string.byte(x)) end)
	return s
end

local function readFile(path)
    local file = io.open(path, "rb")
    if file then
        local content = file:read("*all")
        local size = file:seek("end")
        io.close(file)
        return content, size
    end
    return nil
end

function fileExists(name)
    if type(name)~="string" then return false end
    return os.rename(name,name) and true or false
end

function string.split(str, delimiter)
    if (delimiter=='') then return false end
    local pos,arr = 0, {}
    -- for each divider found
    for st,sp in function() return string.find(str, delimiter, pos, true) end do
        table.insert(arr, string.sub(str, pos, st - 1))
        pos = sp + 1
    end
    table.insert(arr, string.sub(str, pos))
    return arr
end

function io.writefile(path, content, mode)
    mode = mode or "w+b"
    local file = io.open(path, mode)
    if file then
        if file:write(content) == nil then return false end
        io.close(file)
        return true
    else
        return false
    end
end

-- 不需要添加的文件
local excludes = {".", "..", ".DS_Store", "create_flist.lua", "create_flist.sh", "md5.lua", "flist"}
local loads = {"game.zip", "framework_precompiled.zip"}
local rootPath = lfs.currentdir() .. "/"

local currentList = {}
if fileExists(rootPath .. "flist") then
	currentList = dofile(rootPath .. "flist")
else
	currentList = { 
	  ver = "1.0.0", 
	  stage = {}, 
	  remove = {}, 
	} 
end

local vers = string.split(currentList.ver, ".")
local newList = {}
newList.ver = string.format("%d.%d.%d", tonumber(vers[1]), tonumber(vers[2]), tonumber(vers[3]) + 1)
newList.stage = {}
newList.remove = {}

function isFileInclude(filename)
	for _,file in pairs(excludes) do
		if file == filename then
			return false
		end
	end
	return true
end

function isFileLoads(filename)
	for _, file in pairs(loads) do
		if file == filename then
			return true
		end
	end
	return false
end

function handlePath(subPath)
	local currentPath = rootPath .. subPath
	for file in lfs.dir(currentPath) do
		if isFileInclude(file) then
			local attr = lfs.attributes( currentPath .. file )
			if attr.mode == "directory" then
				handlePath( subPath .. file .. "/")
			elseif attr.mode == "file" then
				local detail = {}
				detail.name = subPath .. file
                print(currentPath .. file)
				local data,size = readFile(currentPath .. file)
            	detail.code = md5.sumhexa(hex(data or "")) or ""
                detail.size = size

            	if isFileLoads(file) then
            		detail.act = "load"
            	end

            	table.insert(newList.stage, detail)
			end
		end
	end
end

print("生成更新文件...")
handlePath("")

print(string.format("共 %d 文件", #newList.stage))

local buf = "local list = {\n\tver = \"".. newList.ver .. "\",\n\tstage = {\n"
for _, file in pairs(newList.stage) do
	buf = buf.."\t\t{name = \""..file.name.."\", code = \"" .. file.code .. "\", size = \"" .. file.size .. "\""
    if file.act then
    	buf = buf .. ", act = \"" .. file.act .. "\"},\n"
    else
    	buf = buf .. "},\n"
    end
end
buf = buf .. "\n\t},\n\tremove = {},\n}\nreturn list"

io.writefile(rootPath .. "flist", buf)

print("更新文件生成完毕!")

