local CATEGORY_NAME = "HG Custom"

function ulx_kac_send(calling_ply)
	if KAC.LastTrigger != nil then
		local target_ply = Player(KAC.LastTrigger)
		
		if not target_ply then ULib.tsayError(calling_ply, "Command \"ulx s\", Player not found.", true) return end
		if calling_ply == target_ply then ULib.tsayError(calling_ply, "Command \"ulx s\", You are the target player.", true) return end
		if not calling_ply:Alive() then ULib.tsayError(calling_ply, "Command \"ulx s\", You are dead.", true) return end

		if calling_ply:InVehicle() then calling_ply:ExitVehicle() end
		if calling_ply:GetMoveType() != MOVETYPE_NOCLIP then calling_ply:SetMoveType(MOVETYPE_NOCLIP) end

		local min, max = target_ply:GetCollisionBounds()
		local pos = target_ply:GetPos()

		local newpos = pos + Vector(0,0,10) + Angle(0,target_ply:EyeAngles().y,0):Forward() * (math.max(min[1],min[2],max[1],max[2]) * -1.2)

		local newang = (pos - newpos):Angle()

		calling_ply:SetPos(newpos)
		calling_ply:SetEyeAngles(newang)
		calling_ply:SetLocalVelocity(Vector())

		ulx.fancyLogAdmin(calling_ply, "#A teleported to #T", target_ply)
	else
		ULib.tsayError(calling_ply, "Command \"ulx s\", No recent KAC trigger.", true)
	end
end
local ulx_send_cmd = ulx.command(CATEGORY_NAME, "ulx s", ulx_kac_send, "!s")
ulx_send_cmd:defaultAccess(ULib.ACCESS_OPERATOR)
ulx_send_cmd:help("Teleports you to recent KAC trigger'er")

function ulx_kac_print_info(calling_ply, target_ply)
	
	if not target_ply then
		local aim = calling_ply:GetEyeTrace()
		if aim.Entity then

		end
	else
		local ptable = ""
		local targetid = target_ply:SteamID64()
        local ownerid = target_ply:OwnerSteamID64()
        if targetid == ownerid then ptable = ptable .. "\nPlayer Owns Their Game"
        else ptable = ptable .. "\n" .. ownerid .. " Is Game Owner" end
        local ftime = string.FormattedTime(target_ply:TimeConnected())
        ptable = ptable .. "Connected: " .. ftime.h .. "h, " .. ftime.m .. "m"
        ptable = ptable .. "Ping: " .. target_ply:Ping()
        if calling_ply:IsAdmin() then
        	ptable = ptable .. "IP: " .. string.Split(target_ply:IPAddress(),":")[1]
        end

		KAC.printClient(calling_ply:UserID(),-4,target_ply:Name() .. "(" .. target_ply:SteamID() .. "): " .. ptable)
	end

end
local ulx_printinfo_cmd = ulx.command(CATEGORY_NAME, "ulx info", ulx_kac_print_info, "!info")
ulx_printinfo_cmd:defaultAccess(ULib.ACCESS_OPERATOR)
ulx_printinfo_cmd:addParam{ type=ULib.cmds.PlayerArg, ULib.cmds.optional }
ulx_printinfo_cmd:help("Prints info about a player or aim entity")
