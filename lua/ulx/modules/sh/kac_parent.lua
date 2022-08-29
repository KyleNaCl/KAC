local CATEGORY_NAME = "HG Custom"

local KAC_Limit = {}
local KAC_Parent = {}

if SERVER then
	local parent_file = file.Read("kac_parent.txt")
	if parent_file and parent_file != nil and parent_file != "" then
		KAC_Limit = util.JSONToTable(parent_file)
	end
end

local function updateFile(s64, time)
	local parent_file = file.Read("kac_parent.txt")
	local parent_table = {}
	if parent_file != nil then parent_table = util.JSONToTable(parent_file) end
	parent_table[s64] = time
	file.Write("kac_parent.txt", util.TableToJSON(parent_table, true))
end

gameevent.Listen("player_connect")
hook.Add("player_connect", "KAC_Parent_Connect", function(data)
	timer.Simple(10, function()
		if IsValid(data) then
			local s64 = util.SteamIDTo64(data.networkid)
			if KAC_Limit[s64] != nil and KAC_Limit[s64] > 0 then
				if KAC_Parent[s64] != nil and KAC_Parent[s64] >= KAC_Limit[s64] then
					local hour = math.Truncate(KAC_Limit[s64] / 60, 2)
					game.KickID(data.userid, "Reached Max Playtime, " .. hour .. "h (Parental Controls) [By: KAC]")
				end
			end
		end
	end)
end)

local function pollUsers()
	if player.GetCount() == 0 then return end
	for k, ply in pairs(player.GetHumans()) do
		local s64 = ply:SteamID64() .. "_"
		KAC_Parent[s64] = (KAC_Parent[s64] or 0) + 1
		if KAC_Limit[s64] != nil and KAC_Limit[s64] > 0 then
			if KAC_Parent[s64] != nil and KAC_Parent[s64] > KAC_Limit[s64] then
				local hour = math.Truncate(KAC_Limit[s64] / 60, 2)
				game.KickID(ply:UserID(), "Reached Max Playtime, " .. hour .. "h (Parental Controls) [By: KAC]")
			end
		end
	end
end

if SERVER then
	timer.Simple(5, function()
		timer.Create("KAC_Parent_PollUsers", 60, 0, pollUsers)

		if player.GetCount() == 0 then return end
		for k, ply in pairs(player.GetHumans()) do
			local s64 = ply:SteamID64() .. "_"
			KAC_Parent[s64] = math.floor(ply:TimeConnected() / 60)
		end
	end)
end

function ulx_kac_parent(calling_ply, target_ply, time)

	if target_ply:IsBot() then ULib.tsayError(calling_ply, "Command \"ulx parent\", argument #1: target is a bot!", true) return end

	local s64 = target_ply:SteamID64() .. "_"

	if KAC_Limit[s64] != nil and KAC_Limit[s64] > 0 then
		ulx.fancyLogAdmin(calling_ply, "#A updated #T's parental controls to #i minutes(s)", target_ply, time)
	else
		ulx.fancyLogAdmin(calling_ply, "#A parental controlled #T for #i minutes(s)", target_ply, time)
	end

	KAC_Limit[s64] = time
	updateFile(s64, time)

end
local ulx_parent_cmd = ulx.command(CATEGORY_NAME, "ulx parent", ulx_kac_parent, "!parent")
ulx_parent_cmd:addParam{ type=ULib.cmds.PlayerArg }
ulx_parent_cmd:addParam{ type=ULib.cmds.NumArg, min=30, max=1440, default=30, hint="time", ULib.cmds.round }
ulx_parent_cmd:defaultAccess(ULib.ACCESS_SUPERADMIN)
ulx_parent_cmd:help("Parental Playtime Control, time in minutes")

function ulx_kac_parentid(calling_ply, steamid, time)

	steamid = string.upper(steamid)
	if not ULib.isValidSteamID(steamid) then ULib.tsayError(calling_ply, "Command \"ulx parentid\", argument #1: invalid steamid!", true) return end

	local s64 = util.SteamIDTo64(steamid) .. "_"

	if KAC_Limit[s64] != nil and KAC_Limit[s64] > 0 then
		ulx.fancyLogAdmin(calling_ply, "#A updated #s parental controls to #i minutes(s)", steamid, time)
	else
		ulx.fancyLogAdmin(calling_ply, "#A parental controlled #s for #i minutes(s)", steamid, time)
	end

	KAC_Limit[s64] = time
	updateFile(s64, time)

end
local ulx_parentid_cmd = ulx.command(CATEGORY_NAME, "ulx parentid", ulx_kac_parentid, "!parentid")
ulx_parentid_cmd:addParam{ type=ULib.cmds.StringArg, hint="steamid" }
ulx_parentid_cmd:addParam{ type=ULib.cmds.NumArg, min=30, max=1440, default=30, hint="time", ULib.cmds.round }
ulx_parentid_cmd:defaultAccess(ULib.ACCESS_SUPERADMIN)
ulx_parentid_cmd:help("Parental Playtime Control via steamID, time in minutes")

function ulx_kac_unparent(calling_ply, steamid)

	steamid = string.upper(steamid)
	if not ULib.isValidSteamID(steamid) then ULib.tsayError(calling_ply, "Command \"ulx unparent\", argument #1: invalid steamid!", true) return end

	local s64 = util.SteamIDTo64(steamid) .. "_"

	if KAC_Limit[s64] != nil and KAC_Limit[s64] > 0 then
		ulx.fancyLogAdmin(calling_ply, "#A removed #s parental controls", steamid)

		KAC_Limit[s64] = nil
		updateFile(s64, nil)
	end

end
local ulx_unparent_cmd = ulx.command(CATEGORY_NAME, "ulx unparent", ulx_kac_unparent, "!unparent")
ulx_unparent_cmd:addParam{ type=ULib.cmds.StringArg, hint="steamid" }
ulx_unparent_cmd:defaultAccess(ULib.ACCESS_SUPERADMIN)
ulx_unparent_cmd:help("Remove Parental Playtime Control, time in minutes")
