

local roombase = {}

function roombase.new( ... )
	local handler = setmetatable({}, {__index=roombase})
	handler:ctor()
	return handler
end

function roombase:ctor( ... )
	-- body
end

function roombase:UserEnterRoom( ... )
	-- body
end
function roombase:UserLeaveRoom( ... )
	-- body
end

function roombase:OnSocketMessage(...)
	-- body
end
function roombase:OnLobbyMessage( ... )
	-- body
end

return roombase