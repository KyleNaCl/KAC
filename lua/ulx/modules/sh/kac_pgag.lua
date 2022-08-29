local CATEGORY_NAME = "HG Custom"

local KAC_NGag = {}

hook.Add("PlayerCanHearPlayersVoice", "KAC_Gag", function(listener, talker)
	local s64 = talker:SteamID64() .. "_"
	local time = KAC_NGag[s64] or 0
	if time == -1 or time > CurTime() then return false end
end)

if SERVER then
	local perma_file = file.Read("kac_perma.txt")
	if perma_file and perma_file != nil and perma_file != "" then
		KAC_NGag = util.JSONToTable(perma_file)
	end
end

local function updateFile(s64, isperma)
	local perma_file = file.Read("kac_perma.txt")
	local perma_table = util.JSONToTable(perma_file)
	perma_table[s64] = isperma
	file.Write("kac_perma.txt", util.TableToJSON(perma_table, true))
end

local function kgag_control(s64, time)
	time = time or -10
	--KAC.debug(s64 .. " | " .. time)
	if time == -20 then
		timer.Remove("kac_gag_" .. s64)
		KAC_NGag[s64] = nil
		updateFile(s64)
	elseif time == -10 then
		KAC_NGag[s64] = nil
	elseif time == 0 then
		timer.Remove("kac_gag_" .. s64)
		KAC_NGag[s64] = -1
		updateFile(s64, -1)
	else
		timer.Remove("kac_gag_" .. s64)
		timer.Simple(0, function() timer.Create("kac_gag_" .. s64, time, 1, function() kgag_control(s64) end) end)
		KAC_NGag[s64] = CurTime() + time
	end
end

function ulx_kac_gag(calling_ply, target_plys, time)

	local shouldgag = time != -1
	time = time or 0

	if #target_plys > 1 then
		if time == 0 then ULib.tsayError(calling_ply, "Command \"ulx pgag\", Can not perma shut up multiple targets", true) return end

		for i = 1, #target_plys do
			local p = target_plys[i]
			if p:IsBot() then continue end -- Skip Bots's
			local s64 = p:SteamID64() .. "_"
			if KAC_NGag[s64] == -1 then continue end -- Skip Perma's
			if shouldgag then
				kgag_control(s64, time * 60)
			else
				kgag_control(s64, -10)
			end
		end

		if shouldgag then
			ulx.fancyLogAdmin(calling_ply, "#A shut up #T for #i minutes(s)", target_plys, time)
		else
			ulx.fancyLogAdmin(calling_ply, "#A unshut up'ed #T", target_plys)
		end
	else
		if target_plys[1]:IsBot() then ULib.tsayError(calling_ply, "Command \"ulx pgag\", argument #1: target is a bot!", true) return end

		local s64 = target_plys[1]:SteamID64() .. "_"
		
		if not shouldgag then
			if KAC_NGag[s64] == nil then 
				ULib.tsayError(calling_ply, target_plys[1]:Nick() .. " is not shut up'ed", true)
			else
				if KAC_NGag[s64] == -1 then
					ulx.fancyLogAdmin(calling_ply, "#A perma unshut up #T ", target_plys)
					kgag_control(s64, -20)
				else
					ulx.fancyLogAdmin(calling_ply, "#A unshut up'ed #T ", target_plys)
					kgag_control(s64, -10)
				end
			end
		else
			if KAC_NGag[s64] == -1 then
				ULib.tsayError(calling_ply, target_plys[1]:Nick() .. " is already perma shut up'ed", true)
			else
				if time == 0 then
					if KAC_NGag[s64] != nil then
						ulx.fancyLogAdmin(calling_ply, "#A updated #T's shut up to perma", target_plys)
					else
						ulx.fancyLogAdmin(calling_ply, "#A perma shut up #T", target_plys)
					end
					kgag_control(s64, 0)
				else
					if KAC_NGag[s64] != nil then
						ulx.fancyLogAdmin(calling_ply, "#A updated #T's shut up to #i minutes(s) from now", target_plys, time)
					else
						ulx.fancyLogAdmin(calling_ply, "#A shut up #T for #i minutes(s)", target_plys, time)
					end
					kgag_control(s64, time * 60)
				end
			end
		end
	end
end
local ulx_shut_cmd = ulx.command(CATEGORY_NAME, "ulx pgag", ulx_kac_gag, "!pgag")
ulx_shut_cmd:addParam{ type=ULib.cmds.PlayersArg }
ulx_shut_cmd:addParam{ type=ULib.cmds.NumArg, min=0, default=0, hint="time", ULib.cmds.optional, ULib.cmds.round }
ulx_shut_cmd:defaultAccess(ULib.ACCESS_OPERATOR)
ulx_shut_cmd:help("Disables voice chat on a target for a certain amount of time or permamently.")
ulx_shut_cmd:setOpposite( "ulx unpgag", {_, _, -1}, "!unpgag" )

function ulx_kac_print_gag(calling_ply)
	local perma_file = file.Read("kac_perma.txt")
	local perma_table = util.JSONToTable(perma_file)
	local Count = table.Count(perma_table)
	
	if Count > 0 then
		local Print = "List of permament gags: " .. Count .. " player(s) "
		for k, v in pairs(perma_table) do
			local sid64 = string.sub(k,1,#k - 1)
			Print = Print .. "\n>" .. util.SteamIDFrom64(sid64) .. " "
		end
		ULib.tsay(calling_ply, Print, true)
	else
		ULib.tsay(calling_ply, "There are no players permamently gag'ed.", true)
	end
end
local ulx_printshut_cmd = ulx.command(CATEGORY_NAME, "ulx printpgags", ulx_kac_print_gag, "!printpgags", true)
ulx_printshut_cmd:defaultAccess(ULib.ACCESS_OPERATOR)
ulx_printshut_cmd:help("Prints a list of all permament gags")

function ulx_kac_print_gag_temp(calling_ply)
	local Count = table.Count(KAC_NGag)
	
	if Count > 0 then
		local Print = "List of gags: " .. Count .. " player(s) "
		local time = CurTime()
		for k, v in pairs(KAC_NGag) do
			local sid64 = string.sub(k,1,#k - 1)
			local ply = player.GetBySteamID64(sid64)
			local name = "[Disconnected]"
			if ply then name = ply:Name() end
			if time == -1 then
				Print = Print .. "\n>" .. name .. "(" .. util.SteamIDFrom64(sid64) .. ") > perma"
			else
				Print = Print .. "\n>" ..name .. "(" .. util.SteamIDFrom64(sid64) .. ") > " .. math.floor(v - time) .. " left"
			end
		end
		ULib.tsay(calling_ply, Print, true)
	else
		ULib.tsay(calling_ply, "There are no players gag'ed.", true)
	end
end
local ulx_printshut_temp_cmd = ulx.command(CATEGORY_NAME, "ulx printgags", ulx_kac_print_gag_temp, "!printgags", true)
ulx_printshut_temp_cmd:defaultAccess(ULib.ACCESS_OPERATOR)
ulx_printshut_temp_cmd:help("Prints a list of all current gags")
