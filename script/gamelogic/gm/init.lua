
function onRegister(prot)
    print("onRegister")
	local command = prot[1]
	if command == "exit" then
		return command
	elseif command=="hotfix" then

	end
end


--g_protocol.RegClusterFunc("exit", onRegister)
