

--队列  
function list_newList()
	local list = {}
	local listManager = {}

	function listManager.insert(obj, n)
		local _n = n or #list + 1
    	if _n < 1 or _n > #list + 1 then
    		error("n is not in range!")
    	end

		for i=#list, _n, -1 do
			list[i+1] = list[i]
		end
		list[_n] = obj
    end

    function listManager.remove(n)
    	local _n = n or #list
    	if _n < 1 or _n > #list then
    		error("n is not in range!")
    	end

        local ret = list[_n]

    	for i=_n,#list - 1 do
    		list[i] = list[i+1]
    	end
    	list[#list] = nil
        return ret
    end

    function listManager.indexAt(i)
    	return list[i]
    end

    function listManager.size()
    	return #list
    end

    function listManager.print()
      print(table.concat(list,","))
    end

    return listManager
end