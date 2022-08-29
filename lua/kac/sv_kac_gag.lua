
print("[KAC] \tLoaded sv_kac_gag.lua")

KAC_Gag = {}

hook.Add("PlayerCanHearPlayersVoice", "KAC_Gag", function(listener, talker)
	local S64 = talker:SteamID64()
	if KAC_Gag[S64] = -1 or KAC_Gag[S64] > CurTime() then return false end
end)

function KAC_Gag.control(s64, time)
	time = time or -10
	if time == -10 then
		KAC_Gag[s64] = nil
	elseif time == 0 then
		KAC_Gag[s64] = -1
	else
		KAC_Gag[s64] = CurTime() + time
	end
end
