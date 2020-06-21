
-----Settings-----

KACSettings = {
    rope = {
    	update = 2, 
    	threshold = 5, 
    	requireTrace = false,
    	isTool = true
    },
    stacker = {
    	update = 3, 
    	threshold = 6, 
    	requireTrace = true,
    	isTool = true
    },
    stacker_improved = {
    	update = 3, 
    	threshold = 6, 
    	requireTrace = true,
    	isTool = true
    },
    light = {
    	update = 1, 
    	threshold = 5, 
    	requireTrace = false,
    	isTool = true
    },
    lamp = {
    	update = 1, 
    	threshold = 5, 
    	requireTrace = false,
    	isTool = true
    },
    fading_door = {
    	update = 3, 
    	threshold = 5, 
    	requireTrace = true,
    	isTool = true
    },
    balloon = {
    	update = 2, 
    	threshold = 5, 
    	requireTrace = true,
    	isTool = true
    },
    collisions = {
    	update = 1, 
    	threshold = 5, 
    	requireTrace = false,
    	isTool = false
    }
}

-----Loads-----

if SERVER then
	print("[KAC] ======Initalize Server======")
	include("kac/sv_kac.lua")
	include("kac/sv_kac_ac.lua")
	AddCSLuaFile("kac/cl_kac.lua")
	print("[KAC] ============================")
	if ULib ~= nil then
		ULib.ucl.registerAccess("kac_notify", {"admin", "superadmin"}, "Allows users to see KAC notifications", "")
	end
elseif CLIENT then
	print("[KAC] ======Initalize Client======")
	include("kac/cl_kac.lua")
	print("[KAC] ============================")
end
