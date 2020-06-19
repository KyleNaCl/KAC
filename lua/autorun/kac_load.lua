
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
    	update = 3, 
    	threshold = 5, 
    	requireTrace = false,
    	isTool = false
    }
}

-----Loads-----

if SERVER then
	include("kac/sv_kac.lua")
	AddCSLuaFile("kac/cl_kac.lua")

	if ULib ~= nil then
		ULib.ucl.registerAccess("kac_notify", {"admin", "superadmin"}, "Allows users to see KAC notifications", "")
	end
elseif CLIENT then
	include("kac/cl_kac.lua")
end
