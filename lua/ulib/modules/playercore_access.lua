
if SERVER then
	if ULib ~= nil then
		ULib.ucl.registerAccess("target_himself",	{"user"},		"", "PlayerCore")
		ULib.ucl.registerAccess("target_friends",	{"user"},		"", "PlayerCore")
		ULib.ucl.registerAccess("target_byrank",	{"operator"},	"", "PlayerCore")
		ULib.ucl.registerAccess("target_everyone",	{"admin"},		"", "PlayerCore")

		ULib.ucl.registerAccess("applyforce",		{"user", "operator", "admin", "superadmin"},	"",	"PlayerCore")
		ULib.ucl.registerAccess("setpos",			{"user", "operator", "admin", "superadmin"},	"",	"PlayerCore")
		ULib.ucl.registerAccess("setang",			{"user", "operator", "admin", "superadmin"},	"",	"PlayerCore")
		ULib.ucl.registerAccess("noclip",			{"user", "operator", "admin", "superadmin"},	"",	"PlayerCore")
		ULib.ucl.registerAccess("unnoclip",			{"user", "operator", "admin", "superadmin"},	"",	"PlayerCore")
		ULib.ucl.registerAccess("sethealth",		{"user", "operator", "admin", "superadmin"},	"",	"PlayerCore")
		ULib.ucl.registerAccess("setarmor",			{"user", "operator", "admin", "superadmin"},	"",	"PlayerCore")
		ULib.ucl.registerAccess("setmass",			{"user", "operator", "admin", "superadmin"},	"",	"PlayerCore")
		ULib.ucl.registerAccess("setjumppower",		{"user", "operator", "admin", "superadmin"},	"",	"PlayerCore")
		ULib.ucl.registerAccess("setgravity",		{"user", "operator", "admin", "superadmin"},	"",	"PlayerCore")
		ULib.ucl.registerAccess("setspeed",			{"user", "operator", "admin", "superadmin"},	"",	"PlayerCore")
		ULib.ucl.registerAccess("setrunspeed",		{"user", "operator", "admin", "superadmin"},	"",	"PlayerCore")
		ULib.ucl.registerAccess("setwalkspeed",		{"user", "operator", "admin", "superadmin"},	"",	"PlayerCore")
		ULib.ucl.registerAccess("resetsettings",	{"user", "operator", "admin", "superadmin"},	"",	"PlayerCore")
		ULib.ucl.registerAccess("entervehicle",		{"user", "operator", "admin", "superadmin"},	"",	"PlayerCore")
		ULib.ucl.registerAccess("exitvehicle",		{"user", "operator", "admin", "superadmin"},	"",	"PlayerCore")
		ULib.ucl.registerAccess("spawn",			{"user", "operator", "admin", "superadmin"},	"",	"PlayerCore")
		ULib.ucl.registerAccess("god",				{"user", "operator", "admin", "superadmin"},	"",	"PlayerCore")
		ULib.ucl.registerAccess("ignite",			{"user", "operator", "admin", "superadmin"},	"",	"PlayerCore")
		ULib.ucl.registerAccess("extinguish",		{"user", "operator", "admin", "superadmin"},	"",	"PlayerCore")
		ULib.ucl.registerAccess("ungod",			{"user", "operator", "admin", "superadmin"},	"",	"PlayerCore")
		ULib.ucl.registerAccess("freeze",			{"operator", "admin", "superadmin"},			"",	"PlayerCore")
		ULib.ucl.registerAccess("disablenoclip",	{"operator", "admin", "superadmin"},			"",	"PlayerCore")

		ULib.ucl.registerAccess("getip", {"admin", "superadmin"}, "", "PlayerCore")

		ULib.ucl.registerAccess("message",				{"user", "operator", "admin", "superadmin"},	"",	"PlayerCore")
		ULib.ucl.registerAccess("messagecenter",		{"user", "operator", "admin", "superadmin"},	"",	"PlayerCore")
		ULib.ucl.registerAccess("messagecolor",			{"user", "operator", "admin", "superadmin"},	"",	"PlayerCore")
		ULib.ucl.registerAccess("globalmessage",		{"user", "operator", "admin", "superadmin"},	"",	"PlayerCore")
		ULib.ucl.registerAccess("globalmessagecenter",	{"user", "operator", "admin", "superadmin"},	"",	"PlayerCore")
		ULib.ucl.registerAccess("globalmessagecolor",	{"user", "operator", "admin", "superadmin"},	"",	"PlayerCore")

	    hook.Add("PlyCoreCommand", "ULX_PlyCore_Access", function(ply, target, command)
	        if ULib.ucl.query(ply, command) then
	            if not IsValid(target) then return true end

	            if ULib.ucl.query(ply, "target_himself") then
	                if ply == target then
	                    return true
	                end
	            end

	            if ULib.ucl.query(ply, "target_everyone") then
	                return true
	            end

	            if ULib.ucl.query(ply, "target_friends") then
	                if CPPI then
	                    local friends = target:CPPIGetFriends()
	                    if istable(friends) then
	                        for k, v in pairs(friends) do
	                            if v == ply then
	                                return true
	                            end
	                        end
	                    end
	                end
	            end

	            local access, tag = ULib.ucl.query(ply, "target_byrank")
	            if access then
	                local restrictions = {}
	                ULib.cmds.PlayerArg.processRestrictions(restrictions, ply, {}, tag and ULib.splitArgs(tag)[1] )
	                if not (restrictions.restrictedTargets == false or (restrictions.restrictedTargets and not table.HasValue(restrictions.restrictedTargets, target))) then
	                    return true
	                end
	            end
	        end
	        return false
	    end)
	end
end
