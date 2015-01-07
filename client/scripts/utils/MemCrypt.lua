local function rand_key(num)
    local str = 'abcdefghijklmnhopqrstuvwxyz0123456789' 
 
    local ret = ''
    for i = 1, num do --根据长度生成字符串
        local pos = math.random(1, string.len(str))
        ret = ret .. string.sub(str, pos, pos)
    end
 
    return ret
end

local key = rand_key(32)

function MemEncrypt(num)
	return crypto.encryptXXTEA(tostring(num), key)
end

function MemDecrypt(str)
	return tonum(crypto.decryptXXTEA(str, key))
end