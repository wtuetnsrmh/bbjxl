local SOCKET_TICK_TIME = 0.1 			-- check socket data interval
local SOCKET_RECONNECT_TIME = 5			-- socket reconnect try interval
local SOCKET_CONNECT_FAIL_TIMEOUT = 5	-- socket failure timeout

local STATUS_CLOSED = "closed"
local STATUS_NOT_CONNECTED = "Socket is not connected"
local STATUS_ALREADY_CONNECTED = "already connected"
local STATUS_ALREADY_IN_PROGRESS = "Operation already in progress"
local STATUS_TIMEOUT = "timeout"

local scheduler = require("framework.scheduler")
local socket = require "socket"

local TcpSocket = class("TcpSocket")

TcpSocket.EVENT_DATA = "SOCKET_TCP_DATA"
TcpSocket.EVENT_CLOSE = "SOCKET_TCP_CLOSE"
TcpSocket.EVENT_CLOSED = "SOCKET_TCP_CLOSED"
TcpSocket.EVENT_CONNECTED = "SOCKET_TCP_CONNECTED"
TcpSocket.EVENT_CONNECT_FAILURE = "SOCKET_TCP_CONNECT_FAILURE"

TcpSocket._VERSION = socket._VERSION
TcpSocket._DEBUG = socket._DEBUG

function TcpSocket.getTime()
	return socket.gettime()
end

function TcpSocket:ctor(__host, __port, __retryConnectWhenFailure)
	require("framework.api.EventProtocol").extend(self)
    self.host = __host
    self.port = __port
	self.tickScheduler = nil			-- timer for data
	self.reconnectScheduler = nil		-- timer for reconnect
	self.connectTimeTickScheduler = nil	-- timer for connect timeout
	self.name = 'TcpSocket'
	self.tcp = nil
	self.isRetryConnect = __retryConnectWhenFailure
	self.isConnected = false
end

function TcpSocket:setName( __name )
	self.name = __name
	return self
end

function TcpSocket:setTickTime(__time)
	SOCKET_TICK_TIME = __time
	return self
end

function TcpSocket:setReconnTime(__time)
	SOCKET_RECONNECT_TIME = __time
	return self
end

function TcpSocket:setConnFailTime(__time)
	SOCKET_CONNECT_FAIL_TIMEOUT = __time
	return self
end

function TcpSocket:connect(__host, __port, __retryConnectWhenFailure)
	if __host then self.host = __host end
	if __port then self.port = __port end
	if __retryConnectWhenFailure ~= nil then self.isRetryConnect = __retryConnectWhenFailure end
	assert(self.host or self.port, "Host and port are necessary!")
	self.tcp = socket.tcp()
	self.tcp:settimeout(SOCKET_CONNECT_FAIL_TIMEOUT)

	local __succ = self:_connect() 
	if __succ then
		self:_onConnected()
		self.tcp:settimeout(0)
	else
		self:dispatchEvent({ name=TcpSocket.EVENT_CONNECT_FAILURE })
	end

	return __succ


	-- local function __checkConnect()
	-- 	local __succ = self:_connect() 
	-- 	if __succ then
	-- 		self:_onConnected()
	-- 		self.tcp:settimeout(0)
	-- 	end
	-- 	return __succ
	-- end

	-- if not __checkConnect() then
	-- 	-- check whether connection is success
	-- 	-- the connection is failure if socket isn't connected after SOCKET_CONNECT_FAIL_TIMEOUT seconds
	-- 	local __connectTimeTick = function ()
	-- 		if self.isConnected then return end
	-- 		self.waitConnect = self.waitConnect or 0
	-- 		self.waitConnect = self.waitConnect + SOCKET_TICK_TIME
	-- 		if self.waitConnect >= SOCKET_CONNECT_FAIL_TIMEOUT then
	-- 			self.waitConnect = nil
	-- 			self:close()
	-- 			self:_connectFailure()
	-- 		end
	-- 		__checkConnect()
	-- 	end
	-- 	self.connectTimeTickScheduler = scheduler.scheduleGlobal(__connectTimeTick, SOCKET_TICK_TIME)
	-- end
end

function TcpSocket:send(__data)
	if not self.isConnected then
		return false
	end

	local dataLength = string.len(__data)

	local result, status, pos_send 	-- 返回值
	local pos_begin = 1
	local send_length = 0 		-- 已发送长度

	result, status, pos_send = self.tcp:send(__data, pos_begin)
	while true do
		if result == nil then
			if status == STATUS_CLOSED then
				self:_onDisconnect(__data)
				return false
			end

			send_length = send_length + pos_send - pos_begin + 1

			if send_length == dataLength then
				-- 发送成功
				return true
			end

			pos_begin = pos_send + 1
			result, status, pos_send = self.tcp:send(__data, pos_begin)
		else
			send_length = send_length + result - pos_begin + 1

			if send_length == dataLength then
				return true
			end

			pos_begin = result + 1
			result, status, pos_send = self.tcp:send(__data, pos_begin)
		end
	end
end

function TcpSocket:close( ... )
	--echoInfo("%s.close", self.name)
	self.tcp:close();

	if self.reconnectScheduler then scheduler.unscheduleGlobal(self.reconnectScheduler) end
	if self.tickScheduler then scheduler.unscheduleGlobal(self.tickScheduler) end
	if self.connectTimeTickScheduler then scheduler.unscheduleGlobal(self.connectTimeTickScheduler) end
	-- self:dispatchEvent({name=TcpSocket.EVENT_CLOSE})
end

-- disconnect on user's own initiative.
function TcpSocket:disconnect()
	self:_disconnect()
	self.isRetryConnect = false -- initiative to disconnect, no reconnect.
end

--------------------
-- private
--------------------

--- When connect a connected socket server, it will return "already connected"
-- @see: http://lua-users.org/lists/lua-l/2009-10/msg00584.html
function TcpSocket:_connect()
	local __succ, __status = self.tcp:connect(self.host, self.port)
	return __succ == 1 or __status == STATUS_ALREADY_CONNECTED
end

function TcpSocket:_disconnect()
	self.isConnected = false
	self.tcp:shutdown()
	self:dispatchEvent({name=TcpSocket.EVENT_CLOSED})
end

function TcpSocket:_onDisconnect(__data)
	self.isConnected = false
	self:dispatchEvent({ name=TcpSocket.EVENT_CLOSED, data = __data })
	self:_reconnect();
end

-- connecte success, cancel the connection timerout timer
function TcpSocket:_onConnected()
	self.isConnected = true
	self:dispatchEvent({name=TcpSocket.EVENT_CONNECTED,})
	if self.connectTimeTickScheduler then scheduler.unscheduleGlobal(self.connectTimeTickScheduler) end

	local __tick = function()
		while true do
			-- if use "*l" pattern, some buffer will be discarded, why?
			local __body, __status, __partial = self.tcp:receive(2048)	-- read the package body
			-- print("body:", __body, "__status:", __status, "__partial:", __partial)
    	    if __status == STATUS_CLOSED or __status == STATUS_NOT_CONNECTED then
		    	self:close()
		    	if self.isConnected then
		    		self:_onDisconnect()
		    	else 
		    		self:_connectFailure()
		    	end
		   		return
	    	end
		    if 	(__body and string.len(__body) == 0) or
				(__partial and string.len(__partial) == 0)
			then return end
			if __body and __partial then __body = __body .. __partial end
			self:dispatchEvent({name=TcpSocket.EVENT_DATA, data=(__partial or __body), partial=__partial, body=__body})
		end
	end

	-- start to read TCP data
	self.tickScheduler = scheduler.scheduleGlobal(__tick, SOCKET_TICK_TIME)
end

function TcpSocket:_connectFailure(status)
	self:dispatchEvent({name=TcpSocket.EVENT_CONNECT_FAILURE})
	self:_reconnect();
end

-- if connection is initiative, do not reconnect
function TcpSocket:_reconnect(__immediately)
	if not self.isRetryConnect then return end

	if __immediately then self:connect() return end

	if self.reconnectScheduler then scheduler.unscheduleGlobal(self.reconnectScheduler) end

	local __doReConnect = function () self:connect() end
	self.reconnectScheduler = scheduler.performWithDelayGlobal(__doReConnect, SOCKET_RECONNECT_TIME)
end

return TcpSocket