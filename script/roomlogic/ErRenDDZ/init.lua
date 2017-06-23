
local GameService = {}
function GameService.new(...)
	local hand = setmetatable({}, {__index=GameService})
	hand:ctor(...)
	return hand
end

function GameService:ctor(sendlobbyfunc)
	-- body
end
function GameService:onUserEnter(seatNo, datatab)
	-- body
end
function GameService:onUserLeave(seatNo, datatab)
	-- body
end
function GameService:onSocketMessage(datatab)
	-- body
end


return GameService