
if SERVER then
	print("[KAC] ======Initalize Server======")
	include("kac/sv_kac_lib.lua")
	include("kac/sv_kac.lua")
	include("kac/sv_kac_ac.lua")
	include("kac/sv_kac_weapon.lua")
	include("kac/sv_kac_speedlimit.lua")
	print("[KAC] ============================")
	AddCSLuaFile("kac/cl_kac.lua")
elseif CLIENT then
	print("[KAC] ======Initalize Client======")
	include("kac/cl_kac.lua")
	print("[KAC] ============================")
end
