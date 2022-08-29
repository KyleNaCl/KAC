
local MODULE = GAS.Logging:MODULE()
MODULE.Category = "General"
MODULE.Name = "KAC Wiremod"
MODULE.Colour = Color(100,100,255)

MODULE:Setup(function()

	MODULE:Hook("KAC_Log_Wiremod", "kac_log_wiremod", function(message, tab)

		if tab != nil then
			MODULE:Log(message, unpack(tab))
		else
			MODULE:Log(message)
		end

	end)

end)

GAS.Logging:AddModule(MODULE)
