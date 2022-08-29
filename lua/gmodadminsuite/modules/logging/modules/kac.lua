
local MODULE = GAS.Logging:MODULE()
MODULE.Category = "General"
MODULE.Name = "KAC"
MODULE.Colour = Color(100,100,255)

MODULE:Setup(function()

	MODULE:Hook("KAC_Log", "kac_log", function(message, tab)

		if tab != nil then
			MODULE:Log(message, unpack(tab))
		else
			MODULE:Log(message)
		end

	end)

end)

GAS.Logging:AddModule(MODULE)
