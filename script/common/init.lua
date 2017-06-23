
require "common.errcode"
require "common.prot.init"
require "common.mprotocol"


function FWCreateProtBuffer(mainId, assistid, datatab)
	local toProt = {}
	toProt.M = mainId
	toProt.A = assistid
	if datatab then
		if type(datatab)=="table" then
			toProt.D = datatab
		else
			toProt.D = {datatab}
		end
	end
	return toProt
end
function FWAnalysisProtBuffer(protDataTab)
	return protDataTab.M, protDataTab.A, protDataTab.D
end