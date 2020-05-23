
-----Settings-----

KACSettings = {
    rope = {
    	update = 2, 
    	threshold = 5, 
    	requireTrace = false
    },
    stacker = {
    	update = 3, 
    	threshold = 6, 
    	requireTrace = true
    },
    stacker_improved = {
    	update = 3, 
    	threshold = 6, 
    	requireTrace = true
    },
    light = {
    	update = 1, 
    	threshold = 5, 
    	requireTrace = false
    },
    lamp = {
    	update = 1, 
    	threshold = 5, 
    	requireTrace = false
    },
    fading_door = {
    	update = 3, 
    	threshold = 5, 
    	requireTrace = true
    },
    balloon = {
    	update = 2, 
    	threshold = 5, 
    	requireTrace = true
    }
}

-----Loads-----

if SERVER then
	include("kac/sv_kac.lua")
	AddCSLuaFile("kac/cl_kac.lua")
elseif CLIENT then
	include("kac/cl_kac.lua")
end
