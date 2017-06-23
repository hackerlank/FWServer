
local function lrequire(fname)
	require("gamelogic."..fname..".init")
end
---------------------------------------------------------
lrequire("login")
lrequire("lobby")
--lrequire("DouDiZhu")
lrequire("gm")
lrequire("user")
