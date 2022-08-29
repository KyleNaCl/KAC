
print("[KAC] \tLoaded sv_kac.lua")

local CollisionsMinCVAR = CreateConVar("sv_kac_min_collisions", 100, 128, "prop over this amount will recieve a cooldown until they recieve a collisions check", 1, 10000)
local CollisionsMaxCVAR = CreateConVar("sv_kac_max_collisions", 2000, 128, "prop over this amount will always have collisions with props disabled", 1, 10000)
local FadingDoorPenetrateMax = CreateConVar("sv_kac_max_fading_door_penetrate", 3, 128, "max amount of toggled fading doors penetrating together", 1, 100)
local PropLooperTimerCVAR = CreateConVar("sv_kac_proplooper_timer", 0.01, 128, "prop loop timer interval", 0.005, 1)
local PlayerLooperTimerCVAR = CreateConVar("sv_kac_playerlooper_timer", 0.01, 128, "player loop timer interval", 0.005, 1)
local PenetratePercentCVAR = CreateConVar("sv_kac_penetrate_percent", 0.65, 128, "percent for raycast upon penetration check", 0.1, 1)
local LockDownCVAR = CreateConVar("sv_kac_lockdown", 0, 128, "Enables Server Lockdown (0=Disabled,1=Member+,2=Addict+,3=Staff Only)", 0, 3)
local AntiVPNCVAR = CreateConVar("sv_kac_vpn", 2, 128, "Enables Anti-VPN (0=Disabled,1=Member+,2=Addict+,3=Staff Only)", 0, 3)

local Explosives = {
    models_props_junk_gascan001a_mdl = 1,
    models_props_junk_propane_tank001a_mdl = 1,
    models_props_phx_misc_potato_launcher_explosive_mdl = 1,
    models_props_c17_oildrum001_explosive_mdl = 1,
    models_props_phx_oildrum001_explosive_mdl = 1,
    models_props_phx_ww2bomb_mdl = 1,
    models_props_phx_amraam_mdl = 1,
    models_props_phx_mk_82_mdl = 1,
    models_props_phx_torpedo_mdl = 1,
    models_props_phx_misc_flakshell_big_mdl = 1,
    models_props_phx_cannonball_mdl = 1,
    models_props_phx_cannonball_solid_mdl = 1,
    models_props_phx_ball_mdl = 1,
    models_chippy_f86_bomb_mdl = 1,
    
    gascan001a = 1,
    propane_tank001a = 1,
    potato_launcher_explosive = 1,
    oildrum001_explosive = 1,
    ww2bomb = 1,
    amraam = 1,
    mk_82 = 1,
    torpedo = 1,
    flakshell_big = 1,
    cannonball = 1,
    cannonball_solid = 1,
    ball = 1,
    bomb = 1
}

local function isOwner(ply, ent)
    if not ply then return false end
    if not ent then return false end
    if not ply:IsPlayer() then return false end
    local owner = KAC.GetOwner(ent)
    if IsValid(owner) then
        return ply == owner
    end
    return false
end

local function returnModel(string_)
    if string_ == "" or not string_ then return "<Error>" end
    string_ = string.Replace(string_, "-", "_")
    local str = string.Explode("/", string.lower(string_))
    return string.Explode(".", str[#str])[1]
end

local function callback_collisions(player_)
    local count = 0
    local find = ents.FindByClass("prop_*")
    if #find > 0 then
        for k, v in ipairs(find) do
            if isOwner(player_,v) then
                count = count + 1
                local phys = v:GetPhysicsObject()
                if IsValid(phys) then
                    phys:EnableMotion(false)
                end
            end
        end
    end
    KAC.pushTrigger(player_, "prop_spam", -4)
    KAC.debug("[KAC] Info: " .. player_:Name() .. ": Froze " .. count .. " props")
end

local Expression2s = {}
local function callback_cpu(player_, threshold, time)
    for _,k in pairs(Expression2s) do
        if isOwner(player_,k) then
            k:Error("E2 CPU Overload [Stopped By: KAC]", "Stopped By: KAC")
            k:PCallHook('destruct')
        end
    end
    KAC.printClient(player_:UserID(), -2, "Alert# E2 CPU Overload, Haulting E2s [" .. threshold .." detections over " .. time .."sec]")
end

local function updateTool(player_, tool, trace, hide, callback)
    if not KACSettings then KAC.debug("[KAC] Error: KACSettings not loaded in updateTool()") return false end
    if not KACSettings[tool] then return false end
    if not player_ then KAC.debug("[KAC] Error: Unknown Player in updateTool() for " .. tool) return false end
    local steamC = KAC.returnData(player_)
    if not steamC then KAC.debug("[KAC] Error: " .. player_:Name() .. ": steamC failed in updateTool()") return false end
    if not KAC[steamC] then KAC.debug("[KAC] Error: " .. player_:Name() .. ": Data Table nil in updateTool()") return false end    
    local Tab = nil
    if not KAC[steamC][tool] then
        KAC[steamC][tool] = { warns = 0, kicked = false }
        if KACSettings[tool].threshold then
            for i = 1, KACSettings[tool].threshold, 1 do
                table.insert(KAC[steamC][tool], i, 0)
            end
        end
    end
    if KAC[steamC][tool] then Tab = KAC[steamC] end
    if not Tab then KAC.debug("[KAC] Error: " .. player_:Name() .. ": Data Table nil in updateTool()") return false end

    hide = hide or nil

    local aim = nil
    if trace != nil then aim = trace.entity end
    if KACSettings[tool].requireTrace == true and not aim then return false end
    if KACSettings[tool].threshold == 0 then return false end

    for i = 1, KACSettings[tool].threshold - 1, 1 do Tab[tool][i] = Tab[tool][i+1] end -- Tool Push Back
    Tab[tool][KACSettings[tool].threshold] = SysTime()
    if Tab[tool][1] != 0 then
        local trigger = math.Round(Tab[tool][KACSettings[tool].threshold] - Tab[tool][1],2)
        if trigger < KACSettings[tool].update then
            local add = ""
            if aim then 
                add = add .. "[" .. returnModel(aim:GetModel()) .. "]"
            end
            if hide == false or hide == nil then
                if KACSettings[tool].isTool then
                    KAC.printClient(player_:UserID(), -1, "Alert# " .. KACSettings[tool].threshold .. " uses of " .. tool .. " in " .. trigger .. " sec " .. add)
                else
                    KAC.printClient(player_:UserID(), -1, "Alert# " .. KACSettings[tool].threshold .. " detections of " .. tool .. " in " .. trigger .. " sec " .. add)
                end
            end
            if callback != nil then
                callback(player_, KACSettings[tool].threshold, trigger)
            end
            for i = 1, KACSettings[tool].threshold, 1 do Tab[tool][i] = 0 end -- Reset Tool Table
        end
    end
    return Tab != nil
end

timer.Simple(1, function()
    if player.GetCount() > 0 then
        net.Start("KAC_Settings")
            net.WriteColor(KACSettings.KACCol)
            net.WriteColor(KACSettings.TextSep)
            net.WriteColor(KACSettings.TextCol)
        net.Broadcast()
    end
end)

hook.Add("PlayerDeath", "KAC_Death", function(victim, inflictor, attacker)

    if IsValid(attacker) and IsValid(victim) then

        if not attacker:IsPlayer() then attacker = KAC.GetOwner(attacker) end
        if inflictor:IsPlayer() then inflictor = inflictor:GetActiveWeapon() end

        if IsValid(attacker) and IsValid(inflictor) and IsValid(victim) then 
            if attacker:IsPlayer() and attacker != victim then
                local Weap = inflictor:GetClass()
                local TargetID = attacker:UserID()
                local VictimID = victim:UserID()
                local model = returnModel(inflictor:GetModel())

                local HideBuild = false
                if Weap == "pac_projectile" then
                    KAC.printClient(TargetID, VictimID, "killed#using a pac_projectile", true)
                    KAC.SendPunishment(attacker, "pac", victim)
                elseif inflictor:IsVehicle() then
                    local Driver = inflictor:GetDriver()
                    if IsValid(Driver) then
                        if Driver:IsPlayer() then
                            if KAC.InBuild(Driver) then
                                HideBuild = true
                                if Driver == attacker then 
                                    KAC.printClient(TargetID, VictimID, "ran over#using '" .. model .. "' while in Buildmode")
                                    KAC.SendPunishment(attacker, "buildmode", victim)
                                else
                                    KAC.printClient(Driver:UserID(), VictimID, "ran over#using " .. (owner(inflictor):Name()) .. "'s '" .. model .. "' while in Buildmode")
                                    KAC.SendPunishment(Driver, "buildmode", victim)
                                end
                            end
                        end
                    else
                        KAC.printClient(TargetID, VictimID, "vehicle propkilled#using '" .. model .. "'", true)
                        KAC.SendPunishment(attacker, "propkill", victim, inflictor)
                    end
                elseif Weap == "prop_physics" or inflictor:IsRagdoll() then
                    local e2text = ""
                    if inflictor.Expression2 then e2text = "e2 " end
                    local Type = "propkilled"
                    local Explosive = Explosives[model] == 1
                    if Explosive then Type = "explosive killed" end
                    KAC.printClient(TargetID, VictimID, e2text .. Type .. "#using '" .. model .. "'", not Explosive)
                    if not Explosive then
                        KAC.SendPunishment(attacker, "propkill", victim, inflictor)
                    end
                end
                if Weap != "gmod_wire_expression2" and string.sub(Weap, 1, 10) == "gmod_wire_" then
                    KAC.printClient(TargetID, VictimID, "killed#using '" .. Weap .. "'")
                end
                if not attacker:InVehicle() then
                    local Min, Max = attacker:GetCollisionBounds()
                    local Box = Vector(math.abs(Min.x) + math.abs(Max.x),math.abs(Min.y) + math.abs(Max.y),math.abs(Min.z) + math.abs(Max.z))
                    local Z = 72
                    if attacker:Crouching() then Z = 36 end
                    if Box.x < 32 or Box.y < 32 or Box.z < Z then
                        KAC.printClient(TargetID, VictimID, "killed#with illegal hitbox [" .. math.Truncate(Box.x / 32, 2) .. "," .. math.Truncate(Box.y / 32, 2) .. "," .. math.Truncate(Box.z / Z, 2) .. "]", true)
                        KAC.SendPunishment(attacker, "pac", victim)
                    end
                end

                if not HideBuild then
                    local steamC = KAC.returnData(attacker)
                    if KAC[steamC] then
                        local IsBuild = KAC.InBuild(attacker)
                        if IsBuild then 
                            KAC.printClient(TargetID, VictimID, "killed#while in Buildmode", true)
                            KAC.SendPunishment(attacker, "buildmode", victim)
                        elseif not IsBuild and (KAC[steamC].syncedBuildmode or 0) + 5 > CurTime() then
                            KAC.printClient(TargetID, VictimID, "killed#after Buildmode toggle [" .. math.Truncate(CurTime() - KAC[steamC].syncedBuildmode,2) .. "sec]", true)
                            KAC.SendPunishment(attacker, "buildmode", victim)
                        end
                    end
                end
                if attacker:HasGodMode() then KAC.printClient(TargetID, VictimID, "killed#while in Godmode") --[[ echoSave(attacker, "godmode killed",victim) ]] end
                if attacker:GetColor()["a"] == 0 then KAC.printClient(TargetID, VictimID, "killed#while Invisible") --[[ echoSave(attacker, "invisible killed",victim) ]] end
            end
        elseif IsValid(victim) and IsValid(inflictor) and not victim:InVehicle() then
            if not inflictor:IsWorld() and inflictor:GetMoveType() == MOVETYPE_VPHYSICS then 
	            local Owner = KAC.GetOwner(inflictor)
                local e2text = ""
                if inflictor.Expression2 then e2text = "e2 " end
	            if IsValid(Owner) and Owner:IsPlayer() then
	                KAC.printClient(-1, victim:UserID(), e2text .. "killed#using " .. Owner:Name() .. "'s '" .. returnModel(inflictor:GetModel()) .. "'")
	            else
	                KAC.printClient(-1, victim:UserID(), e2text .. "killed#using '" .. returnModel(inflictor:GetModel()) .. "'")
	            end
	        end
        end
    end
end)

local UserTabBlacklist = {
    ["user"] = true,
    ["member"] = true,
    ["trusted"] = true,
    ["dedicated"] = true,
}
-- (0=Disabled,1=Member+,2=Addict+,3=Staff Only)
local UserLockDownBlacklist = {
    ["0"] = {},
    ["1"] = {
        ["user"] = true,
    },
    ["2"] = {
        ["user"] = true,
        ["member"] = true,
        ["trusted"] = true,
        ["dedicated"] = true,
    },
    ["3"] = {
        ["user"] = true,
        ["member"] = true,
        ["trusted"] = true,
        ["dedicated"] = true,
        ["addict"] = true,
        ["veteran"] = true,
        ["premium"] = true,
        ["premiumplus"] = true,
    },
}

local function getRank(Tab)
    if not Tab then return "user" end
    return Tab.group or "user"
end

local function handleLockDownMsg(value)
    value = value or 0
    if value == 1 then
        return "[Rank of Member Required]"
    elseif value == 2 then
        return "[Rank of Addict Required]"
    elseif value == 3 then
        return "[Rank of Staff Required]"
    end
    return "You Shouldn't Have Gotten This Message"
end
local function handleLockDown(value, rank)
    value = value or 0
    rank = rank or "user"
    if value > 0 then
        return not (UserLockDownBlacklist[tostring(value)][rank] or true)
    end
    return true
end

local function checkban(name, steamid)
    http.Fetch("https://api.steampowered.com/ISteamUser/GetPlayerBans/v1/?key=B863EC0B235DBF24DAED60E8DAD3E6D2&steamids=" .. util.SteamIDTo64(steamid), 
        function(body, len, headers, code)
            local tab = util.JSONToTable(body)
            if tab and tab.players then
                if tab.players[1].VACBanned then
                    KAC.debug("[KAC] " .. name .. "<" .. steamid .. "> " .. tab.players[1].NumberOfVACBans .. " VAC Ban(s), " .. tab.players[1].DaysSinceLastBan .. " day(s) since last ban", true)
                    KAC.printClient(-1,-1, name .. " " .. tab.players[1].NumberOfVACBans .. " VAC Ban(s), " .. tab.players[1].DaysSinceLastBan .. " day(s) since last ban")
                end
                if tab.players[1].NumberOfGameBans > 0 then
                    KAC.debug("[KAC] " .. name .. "<" .. steamid .. "> " .. tab.players[1].NumberOfGameBans .. " Game Ban(s), " .. tab.players[1].DaysSinceLastBan .. " day(s) since last ban", true)
                    KAC.printClient(-1,-1, name .. " " .. tab.players[1].NumberOfGameBans .. " Game Ban(s), " .. tab.players[1].DaysSinceLastBan .. " day(s) since last ban")
                end
                if tab.players[1].CommunityBanned then
                    KAC.debug("[KAC] " .. name .. "<" .. steamid .. "> Is Community Banned", true)
                    KAC.printClient(-1,-1, name .. " " .. "Is Community Banned")
                end
            end
        end,
        function(error)
            KAC.debug("[KAC] Error: " .. name .. "<" .. steamid .. "> VAC Check failed with error: " .. error )
        end
    )
end

gameevent.Listen("player_connect")
hook.Add("player_connect", "KAC_Connect", function(data)
    local name = data.name          // Same as Player:Nick()
    local steamid = data.networkid  // Same as Player:SteamID()
    local ip = string.Trim(string.Explode(":",data.address)[1]) // Same as Player:IPAddress()
    local userid = data.userid      // Same as Player:UserID()
    local bot = data.bot            // Same as Player:IsBot()
    local index = data.index        // Same as Player:EntIndex()

    if steamid == "BOT" then
        KAC.PrintJoin(1, name, steamid)
        return
    end

    --[[
    -1 Invalid no input
    -2 Invalid IP address
    -3 Unroutable address / private address
    -4 Unable to reach database, most likely the database is being updated. Keep an eye on twitter for more information.
    -5 Your connecting IP has been banned from the system or you do not have permission to access a particular service. Did you exceed your query limits? Did you use an invalid email address? If you want more information, please use the contact links below.
    -6 You did not provide any contact information with your query or the contact information is invalid.
    ]]

    if steamid != "BOT" and data.address != "none" and data.address != "loopback" then 
        local replace_id = string.Replace(steamid, ":", "_")
        timer.Create(replace_id, 10, 1, function()
            local DontSend = false
            if ULib and ULib.ucl then
                local rank = getRank(ULib.ucl.users[steamid]) or "user"
                local lockdown = LockDownCVAR:GetInt()
                if lockdown == 0 or not (UserLockDownBlacklist[tostring(lockdown)][rank] or false) then
                    local lockdownvpn = AntiVPNCVAR:GetInt()
                    local vpnlock = UserLockDownBlacklist[tostring(lockdownvpn)][rank] or false
                    if UserTabBlacklist[rank] or vpnlock then
                        local URL = "ip=" .. ip .. "&contact=null"
                        http.Fetch("http://check.getipintel.net/check.php?" .. URL,
                            function(body, len, headers, code)
                                body = math.floor(tonumber(body) * 100)
                                if body > 98 then
                                    if vpnlock then
                                        DontSend = true
                                        game.KickID(userid, "VPN/Proxy Use Prohibited [By: KAC]")
                                        KAC.debug("[KAC] " .. name .. "<" .. steamid .. "> Detected VPN/Proxy [" .. body .. "%][" .. ip .. "]")
                                    else
                                        KAC.printClient(-1,-1, name .. " (" .. steamid ..") Detected VPN/Proxy [" .. body .. "%]")
                                        KAC.PrintJoin(1, name, steamid)
                                        checkban(name, steamid)
                                    end
                                else
                                    if body > 90 then
                                        KAC.printClient(-1,-1, name .. " (" .. steamid ..") Possible VPN/Proxy [" .. body .. "%]")
                                    else
                                        KAC.debug("[KAC] " .. name .. "<" .. steamid .. "> IP address Valid [" .. body .. "%]")
                                    end
                                    KAC.PrintJoin(1, name, steamid)
                                    checkban(name, steamid)
                                end
                            end,
                            function(error)
                                KAC.debug("[KAC] Error: " .. name .. "<" .. steamid .. "><" .. URL .. "> VPN Check failed with error: " .. error )
                                KAC.PrintJoin(1, name, steamid)
                                checkban(name, steamid)
                            end
                        )
                    else
                        KAC.debug("[KAC] " .. name .. "<" .. steamid .. "> connected as [" .. rank .. "]")
                        KAC.PrintJoin(1, name, steamid)
                        checkban(name, steamid)
                    end
                else
                    DontSend = true
                    game.KickID(userid, "Server In Lockdown " .. handleLockDownMsg(lockdown) .. " [By: KAC]")
                    KAC.debug("[KAC] " .. name .. "<" .. steamid .. "> attempted to connect [" .. lockdown .. "][" .. rank .. "]")
                end
            end
        end)
    end
end)

gameevent.Listen("player_disconnect")
hook.Add("player_disconnect", "KAC_Disconnect", function(data)
    local name = data.name          // Same as Player:Nick()
    local steamid = data.networkid  // Same as Player:SteamID()
    local userid = data.userid      // Same as Player:UserID()
    local bot = data.bot            // Same as Player:IsBot()
    local reason = data.reason

    if steamid == "BOT" then 
        KAC.PrintJoin(3, name, steamid, "removed")
        return
    end

    if steamid == nil then return end

    local replace_id = string.Replace(steamid, ":", "_")

    if not timer.Exists(replace_id) then
        local steamC = tonumber(string.Explode(":", steamid)[3]) * 2
        if KAC[steamC] then
            KAC[steamC].punishment = { 
                wait = false,
                wait_target = 0,
                wait_reason = ""
            }
        end

        KAC.debug("[KAC] Info: " .. name .. "<" .. steamid .. "> disconnect: " .. string.Replace(reason, "\n", ";"))
        if string.find(string.lower(reason), "banned") then 
            reason = "banned"
        elseif string.find(string.lower(reason), "kicked") then
            reason = "kicked"
        end
        KAC.PrintJoin(3, name, steamid, reason)
    else
        KAC.debug("[KAC] " .. name .. "<" .. steamid .. "> disconnected after connecting for " .. math.Truncate(10 - timer.TimeLeft(replace_id),2) .. "sec")
        timer.Remove(replace_id)
    end
end)

hook.Add("PlayerFullyLoaded", "KAC_Auth", function(ply)

    local name = ply:Name()
    local steamid = ply:SteamID()

    if ply:IsBot() then KAC.PrintJoin(2, name, steamid) return end

    local ip = string.Explode(":",ply:IPAddress())[1]
    KAC.debug("[KAC] Info: " .. name .. "<" .. steamid .. "><" .. ply:UniqueID() .. "> finished loading")
    local DontSend = false

    local Owner = util.SteamIDFrom64(ply:OwnerSteamID64())
    local OwnerTab = ULib.bans[Owner]
    if Owner and steamid then
        if Owner != steamid then
            if OwnerTab then
                KAC.printClient(ply:UserID(),-1,"Alert# GameSharing w/ Banned Account " .. OwnerTab["name"] .. "(" .. OwnerTab["steamID"] ..")")
                if not ply:IsListenServerHost() then
                    timer.Simple(1,function()
                        RunConsoleCommand("ulx", "banid", Owner, 0, OwnerTab["reason"] .. "\n - Extended: Joined On Alt Via GameShare [By: KAC]")
                        RunConsoleCommand("ulx", "banid", steamid, 0, "GameSharing w/ Banned Account (" .. OwnerTab["steamID"] .. ") [By: KAC]")
                        RunConsoleCommand("ulx", "banip", 0, ip)
                    end)
                end
                DontSend = true
            else
                KAC.printClient(ply:UserID(),-1,"Info## GameSharing w/ " .. Owner)
            end
            KAC.debug("[KAC] " .. name .. "<" .. steamid .. "> doesn't own their game (" .. Owner ..")", true)
        end
    end
    if DontSend == false then
        KAC.PrintJoin(2, name, steamid)

        ply:SendLua("hook.Remove('PreDrawViewModels','ArcCW_PreDrawViewmodels_Grad')")
        ply:SendLua("GetConVar('easychat_tag_image'):SetBool(false)")
        ply:SendLua("hook.Remove('ECPostAddText','EasyChatModuleSFCompat')")

        if IsValid(ply) then
            net.Start("KAC_Settings")
                net.WriteColor(KACSettings.KACCol)
                net.WriteColor(KACSettings.TextSep)
                net.WriteColor(KACSettings.TextCol)
            net.Send(ply)

            local steamC = KAC.returnData(ply)
            if KAC[steamC] then
                KAC[steamC].weaponData.deathTime = CurTime() + 20
            end

            if file.Size("kac_log.txt", "DATA") > 100000000 then
                KAC.printClient(-1, -1, "(SILENT) Warning: KAC Log File > 100MB, Notify Kyle")
            end
        end
    end
end)

local function collisionCount(ent)
    if not IsValid(ent) then return 0, nil end
    local phys = ent:GetPhysicsObject()
    if not IsValid(phys) then return 0, nil end
    local mes = phys:GetMesh()
    if not mes then return 0, nil end
    return #mes, phys
end

local function unAABB(min, max)
    local NewMin = Vector(99999,99999,99999)
    local NewMax = Vector(-99999,-99999,-99999)

    if min.x < NewMin.x then NewMin.x = min.x end
    if min.y < NewMin.y then NewMin.y = min.y end
    if min.z < NewMin.z then NewMin.z = min.z end
    if max.x < NewMin.x then NewMin.x = max.x end
    if max.y < NewMin.y then NewMin.y = max.y end
    if max.z < NewMin.z then NewMin.z = max.z end

    if min.x > NewMax.x then NewMax.x = min.x end
    if min.y > NewMax.y then NewMax.y = min.y end
    if min.z > NewMax.z then NewMax.z = min.z end
    if max.x > NewMax.x then NewMax.x = max.x end
    if max.y > NewMax.y then NewMax.y = max.y end
    if max.z > NewMax.z then NewMax.z = max.z end

    return NewMin, NewMax
end

local function checkPenetrate(ply, ent, hide, overcount, scale)
    local pCount = {}
    hide = hide or 0
    overcount = overcount or -1
    scale = scale or 1

    if not ply then return true, pCount end
    if not ent then return true, pCount end

    if ent:GetMoveType() != MOVETYPE_VPHYSICS then return true, pCount end
    if IsValid(ent:GetParent()) then return true, pCount end
    if collisionCount(ent) < overcount then return true, pCount end

    local valid = true
    local Min, Max = ent:GetCollisionBounds()
    local NewMin, NewMax = unAABB(ent:GetPos() + Min * scale,ent:GetPos() + Max * scale)

    local tab = ents.FindInBox(NewMin,NewMax)
    if tab != nil then
        for _,e in ipairs(tab) do
            if e == ent then continue end
            if e:GetMoveType() != MOVETYPE_VPHYSICS then continue end
            if IsValid(e:GetParent()) then continue end
            if collisionCount(e) < overcount then continue end
            if not isOwner(ply, e) then continue end

            if hide == 0 then
                table.insert(pCount, 1, e)
                valid = false
            elseif hide < 0 then
                if e:GetCollisionGroup() * -1 == hide then
                    table.insert(pCount, 1, e)
                    valid = false
                end
            elseif hide > 0 then
                if e:GetCollisionGroup() != hide then
                    table.insert(pCount, 1, e)
                    valid = false
                end
            end
        end
    end
    return valid, pCount
end

local function checkPenetrate2(ply, ent, class)

    if not ply then return false end
    if not ent then return false end
    class = class or "prop_physics"

    if IsValid(ent:GetParent()) then return false end

    if collisionCount(ent) < CollisionsMinCVAR:GetInt() then return false end

    local Min, Max = ent:GetCollisionBounds()

    Min = Min * PenetratePercentCVAR:GetFloat()
    Max = Max * PenetratePercentCVAR:GetFloat()

    local Trace1 = util.TraceLine({
        start = ent:LocalToWorld(Min),
        endpos = ent:LocalToWorld(Max),
        filter = ent,
        ignoreworld = true,
        collisiongroup = COLLISION_GROUP_NONE
    })
    local Trace2 = util.TraceLine({
        start = ent:LocalToWorld(Vector(Min[1],Max[2],Max[3])),
        endpos = ent:LocalToWorld(Vector(Max[1],Min[2],Min[3])),
        filter = ent,
        ignoreworld = true,
        collisiongroup = COLLISION_GROUP_NONE
    })

    local TH1 = false
    local TH2 = false
    local THE1 = nil
    local THE2 = nil

    if IsValid(Trace1["Entity"]) then
        TH1 = string.find(Trace1["Entity"]:GetClass(),class) and not IsValid(Trace1["Entity"]:GetParent()) and isOwner(ply,Trace1["Entity"]) and collisionCount(Trace1["Entity"]) >= CollisionsMinCVAR:GetInt() and Trace1["Entity"]:GetCollisionGroup() != COLLISION_GROUP_PLAYER
        if TH1 then
            THE1 = Trace1["Entity"]
        end
    end
    if IsValid(Trace2["Entity"]) then
        TH2 = string.find(Trace2["Entity"]:GetClass(),class) and not IsValid(Trace2["Entity"]:GetParent()) and isOwner(ply,Trace2["Entity"]) and collisionCount(Trace2["Entity"]) >= CollisionsMinCVAR:GetInt() and Trace2["Entity"]:GetCollisionGroup() != COLLISION_GROUP_PLAYER
        if TH2 then
            THE2 = Trace2["Entity"]
        end
    end

    return (TH1 or TH2), THE1, THE2
end

local function checkFadingDoor(ply, ent)
    local t = 0
    local valid, pCount = checkPenetrate(ply, ent, 0, 0, 0.8)
    if not valid then
        local max = CollisionsMaxCVAR:GetInt()
        for _,e in ipairs(pCount) do
            if e.isFadingDoor then
                if collisionCount(e) >= max then
                    t = t + 1
                end
            end
        end
        if t >= FadingDoorPenetrateMax:GetInt() then
            local model = returnModel(ent:GetModel())
            KAC.debug("[KAC] Alert: " .. ply:Name() .. "<" .. ply:SteamID() .. "> defusing fading door crash on " .. (t + 1) .. " entities using " .. model, true)
            KAC.printClient(ply:UserID(), -3, "Anti-Crash# Defusing Fading Door Crash [" .. (t + 1) .. "][" .. model .. "]")
            KAC.pushTrigger(ply, "fading")
            table.insert(pCount, 1, ent)
            for _,e in ipairs(pCount) do e:Remove() end
            return false
        end
    end
end

hook.Add("CanTool", "KAC_Tool", function(ply, trace, tool)
    if updateTool(ply, tool, trace) then
        if IsValid(trace.Entity) then 
            KAC.debug("[KAC] " .. ply:Name() .. "<" .. ply:SteamID() .. "> -> " .. tool .. " -> " .. returnModel(trace.Entity:GetModel()))
        else
            KAC.debug("[KAC] " .. ply:Name() .. "<" .. ply:SteamID() .. "> -> " .. tool .. " -> world")
        end
    elseif not IsValid(trace.Entity) then
        KAC.debug("[KAC] " .. ply:Name() .. "<" .. ply:SteamID() .. "> -> " .. tool .. " -> world", true)
    end
    if tool == "fading_door" then
        local ent = trace.Entity
        if IsValid(ent) then
            checkFadingDoor(ply, ent)
        end
    elseif tool == "streamradio" then
        timer.Simple(0,function()
            local hit = util.QuickTrace(trace.HitPos + (trace.StartPos - trace.HitPos):GetNormalized(), trace.StartPos)
            local ent = hit.Entity
            if IsValid(ent) and isOwner(ply,ent) and ent:GetClass() == "sent_streamradio" then
                if CurTime() - ent:GetCreationTime() < 0.1 then
                    timer.Simple(1,function()
                        if IsValid(ent) then
                            local URL = ent:GetSettings().StreamUrl
                            local Ex = string.Explode("/", URL)
                            KAC.debug("[KAC] " .. ply:Name() .. "<" .. ply:SteamID() .. "> spawned streamradio: " .. Ex[#Ex])
                            if GAS and GAS.Logging then
                                hook.Run("KAC_Log","{1} spawned streamradio: " .. URL,{GAS.Logging:FormatPlayer(ply)})
                            end
                        end
                    end)
                end
            end
        end)
    end
end)

hook.Add("PlayerSpawnedProp", "KAC_SpawnProp", function(ply, model, ent)
    if not ply then return end
    if IsValid(ent:GetParent()) then return end

    local pname = ply:Name()
    local sid = ply:SteamID()
    model = returnModel(model)

    local eMeshC, phys = collisionCount(ent)
    if not IsValid(phys) then KAC.debug("[KAC] Error: " .. pname .. "<" .. sid .. "> spawned " .. model .. " with no physics object") return end

    if eMeshC == 0 or eMeshC < CollisionsMinCVAR:GetInt() then 
        timer.Simple(0, function()
            if IsValid(phys) then
                if ent.PropSpawner == nil and ent.Expression2 == nil then
                    phys:EnableMotion(false)
                end
            end
        end)
        return
    end

    local IsPene, Ent1, Ent2 = checkPenetrate2(ply, ent)
    local MaxCol = eMeshC >= CollisionsMaxCVAR:GetInt()

    if IsPene and not MaxCol then
        KAC.debug("[KAC] " .. pname .. "<" .. sid .. "> spawned " .. model .. " while colliding")
        ent:SetCollisionGroup(COLLISION_GROUP_NPC_SCRIPTED)
    elseif not IsPene and MaxCol then
        KAC.debug("[KAC] " .. pname .. "<" .. sid .. "> spawned " .. model .. " with " .. eMeshC .. " collisions", true)
        ent:SetCollisionGroup(COLLISION_GROUP_NPC_SCRIPTED)
    elseif IsPene and MaxCol then
        KAC.debug("[KAC] " .. pname .. "<" .. sid .. "> spawned " .. model .. " with " .. eMeshC .. " collisions while colliding")
        ent:SetCollisionGroup(COLLISION_GROUP_NPC_SCRIPTED)
    end

    phys = ent:GetPhysicsObject()
    timer.Simple(0, function()
        if IsValid(phys) then
            if ent.PropSpawner == nil and ent.Expression2 == nil then
                phys:EnableMotion(false)
            end
        end
    end)

    if IsPene then 
        ent:SetCollisionGroup(COLLISION_GROUP_NPC_SCRIPTED)
        phys:EnableMotion(false)
        updateTool(ply, "collisions", nil, false, callback_collisions)
        if IsValid(Ent1) then 
            Ent1:SetCollisionGroup(COLLISION_GROUP_NPC_SCRIPTED)
            local Phys1 = Ent1:GetPhysicsObject()
            if IsValid(Phys1) then Phys1:EnableMotion(false) end
        end
        if IsValid(Ent2) then 
            Ent2:SetCollisionGroup(COLLISION_GROUP_NPC_SCRIPTED)
            local Phys2 = Ent2:GetPhysicsObject()
            if IsValid(Phys2) then Phys2:EnableMotion(false) end
        end
    end
end)

hook.Add("PlayerSpawnedSWEP", "KAC_SpawnSWEP", function(ply, ent)
    ent:SetCollisionGroup(COLLISION_GROUP_INTERACTIVE_DEBRIS)
end)

hook.Add("PlayerSpawnedSENT", "KAC_SpawnSENT", function(ply, ent)
    ent:SetCollisionGroup(COLLISION_GROUP_INTERACTIVE_DEBRIS)
end)

hook.Add("PlayerSpawnedRagdoll", "KAC_SpawnRagdoll", function(ply, mdl, ent)
    ent:SetCollisionGroup(COLLISION_GROUP_INTERACTIVE_DEBRIS)
end)

hook.Add("PlayerSpawnedVehicle", "KAC_SpawnVehicle", function(ply, veh)
    local model = returnModel(veh:GetModel())
    local t = 0
    local valid, pCount = checkPenetrate(ply, veh, 0, 0, 1)
    if not valid then
        local class = veh:GetClass()
        local Phys1 = veh:GetPhysicsObject()
        for _,e in ipairs(pCount) do
            if class == e:GetClass() then
                veh:SetCollisionGroup(COLLISION_GROUP_INTERACTIVE_DEBRIS)
                if IsValid(Phys1) then Phys1:EnableMotion(false) end
                e:SetCollisionGroup(COLLISION_GROUP_INTERACTIVE_DEBRIS)
                local Phys2 = e:GetPhysicsObject()
                if IsValid(Phys2) then Phys2:EnableMotion(false) end
                t = t + 1
            end
        end
    end
    if t > 0 then
        KAC.debug("[KAC] " .. ply:Name() .. "<" .. ply:SteamID() .. "> spawned " .. model .. " while colliding")
    end
    if t >= 3 and veh:GetClass() == "gmod_sent_vehicle_fphysics_base" then
        KAC.debug("[KAC] Alert: " .. ply:Name() .. "<" .. ply:SteamID() .. "> defusing simfphys crash on " .. t .. " entities using " .. model, true)
        KAC.printClient(ply:UserID(), -3, "Anti-Crash# Defusing Simfphys Crash [" .. t .. "][" .. model .. "]")
        KAC.pushTrigger(ply, "simfphys")
        table.insert(pCount, 1, veh)
        for _,e in ipairs(pCount) do e:Remove() end
        return false
    end
end)

local Props = {}
local Iter = 1
local IterC = 0
local IterCooldown = 2
local IterCurtime = CurTime()
local IterSwap = false

local function checkProp(o, ent)

    if IsValid(o) and IsValid(ent) then
        local pname = o:Name()
        local sid = o:SteamID()
        local model = returnModel(ent:GetModel())

        if IterSwap == true then
            local constraints_weld = constraint.FindConstraints(ent, "Weld")
            if #constraints_weld > 100 then
                local IsRemoved, IsCount = constraint.RemoveConstraints(ent, "Weld")
                if IsRemoved then
                    KAC.printClient(o:UserID(), -2, "Info## Removed " .. IsCount .. " weld constraints on " .. model)
                end
            end
        else
            local constraints_collide = constraint.FindConstraints(ent, "NoCollide")
            if #constraints_collide > 50 then
                local IsRemoved, IsCount = constraint.RemoveConstraints(ent, "NoCollide")
                if IsRemoved then
                    ent:SetCollisionGroup(COLLISION_GROUP_NPC_SCRIPTED)
                    KAC.printClient(o:UserID(), -2, "Info## Removed " .. IsCount .. " no-collide constraints on " .. model)
                end
            end
        end
        local col = collisionCount(ent)
        if col >= CollisionsMaxCVAR:GetInt() then

            local group = ent:GetCollisionGroup()
            if group == COLLISION_GROUP_NPC_SCRIPTED or group == COLLISION_GROUP_PLAYER or group == COLLISION_GROUP_WORLD then return end

            ent:SetCollisionGroup(COLLISION_GROUP_NPC_SCRIPTED)

            KAC.debug("[KAC] " .. pname .. "<" .. sid .. "> forced collision change on " .. model .. " [" .. group .. ">->19]")

            if ent.isFadingDoor then
                checkFadingDoor(o, ent)
            end

        elseif col >= CollisionsMinCVAR:GetInt() then

            local group = ent:GetCollisionGroup()

            if group == COLLISION_GROUP_NPC_SCRIPTED or group == COLLISION_GROUP_PLAYER or group == COLLISION_GROUP_WORLD then return end

            local IsPene, Ent1, Ent2 = checkPenetrate2(o, ent)

            if IsPene then
                updateTool(o, "collisions", nil, true, callback_collisions)

                ent:SetCollisionGroup(COLLISION_GROUP_NPC_SCRIPTED)
                local Phys = ent:GetPhysicsObject()
                if IsValid(Phys) then Phys:EnableMotion(false) end

                local With = " with "
                local Ent1V = IsValid(Ent1)
                if Ent1V then 
                    With = With .. returnModel(Ent1:GetModel())
                    Ent1:SetCollisionGroup(COLLISION_GROUP_NPC_SCRIPTED)
                    local Phys1 = Ent1:GetPhysicsObject()
                    if IsValid(Phys1) then Phys1:EnableMotion(false) end
                end
                local Ent2V = IsValid(Ent2)
                if Ent2V then 
                    if Ent1V then With = With .. " and " .. returnModel(Ent2:GetModel()) else With = With .. returnModel(Ent2:GetModel()) end
                    Ent2:SetCollisionGroup(COLLISION_GROUP_NPC_SCRIPTED)
                    local Phys2 = Ent2:GetPhysicsObject()
                    if IsValid(Phys2) then Phys2:EnableMotion(false) end
                end

                if not Ent1V and not Ent2V then With = "" end

                KAC.debug("[KAC] " .. pname .. "<" .. sid .. "> " .. model .. " is colliding" .. With)
            end

            if ent.isFadingDoor then
                checkFadingDoor(o, ent)
            end
        end
        return true
    end
    return false
end

local function loopProps()
    if IterC > CurTime() then return true end
    if Iter > #Props then
        Props = ents.FindByClass("prop_physics")
        --KAC.debug("[KAC] Loop Reset: " .. #Props .. " props | Looped in: " .. math.floor(CurTime() - IterCurtime) .. "s", true)

        Iter = 1
        IterCurtime = CurTime()
        IterSwap = not IterSwap
        if #Props == 0 then IterC = CurTime() + IterCooldown end

        Expression2s = ents.FindByClass("gmod_wire_expression2")
    elseif #Props > 0 then
        local ent = Props[Iter]
        if IsValid(ent) then 
            if not IsValid(ent:GetParent()) then 
                local o = KAC.GetOwner(ent)
                if IsValid(o) and o:IsPlayer() then 
                    checkProp(o, ent)
                end
            end
        end
        Iter = Iter + 1
    end
end
timer.Create("KAC_PropLooper", PropLooperTimerCVAR:GetFloat(), 0, loopProps)

local function rgbmatch(col1, col2)
    return col1.r == col2.r and col1.g == col2.g and col1.b == col2.b
end

local IterP = 0
local function loopPlayer()
    
    if player.GetCount() == 0 then return end

    IterP = IterP + 1
    if IterP > player.GetCount() then IterP = 1 end

    local ply = player.GetAll()[IterP]
    if not ply then return end
    KAC.UpdateData(ply)

    local steamC = KAC.returnData(ply)
    if KAC[steamC] then
        local model = ply:GetModel()
        if model != nil then
            local IsSkele = model == "models/player/skeleton.mdl"
            local IsMat = ply:GetMaterial() == "debug/debugdrawflat"
            local IsCol = rgbmatch(ply:GetColor(),team.GetColor(ply:Team()))
            if KAC[steamC].IsSkeleton != IsSkele or (IsSkele and (IsSkele != IsMat or IsSkele != IsCol)) then
                if IsSkele then
                    ply:SetMaterial("debug/debugdrawflat")
                    ply:SetColor(team.GetColor(ply:Team()))
                    KAC.debug("[KAC] " .. ply:Name() .. "<" .. ply:SteamID() .. "> Using Skeleton Model")
                    KAC.printClient(ply:UserID(), -4, "You are using a Skeleton Base Model, your model will be highlighted")
                else
                    ply:SetMaterial("")
                    ply:SetColor(Color(255,255,255,255))
                end
            end
            KAC[steamC].IsSkeleton = IsSkele
        else
            KAC[steamC].IsSkeleton = false
        end
    end
    
    if not ply:InVehicle() then return end

    local veh = ply:GetVehicle()
    if IsValid(veh:GetParent()) then return end
    if veh.playerdynseat then return end

    local col = veh:GetCollisionGroup()
    if col == COLLISION_GROUP_WORLD then
        veh:SetCollisionGroup(COLLISION_GROUP_NONE)
        KAC.printClient(ply:UserID(), -2, "Info## Blocked Collision change on " .. returnModel(veh:GetModel()))
    end
end
timer.Create("KAC_PlayerLooper", PlayerLooperTimerCVAR:GetFloat(), 0, loopPlayer)

local Cache_Expression2s = {}

local function loopExpression2()
    if #Expression2s == 0 then return end
    local Temp = {}
    for _,k in pairs(Expression2s) do
        if not IsValid(k) then continue end
        if not IsValid(k.player) then continue end
        Temp[k:EntIndex()] = { ['ent'] = k, ['owner'] = k.player:Name(), ['sid'] = k.player:SteamID(), ['name'] = (k.name or "generic") }
        if k.error then continue end
        if not k.context then continue end
        local time = math.Round(k.context.timebench * 1000000)
        if time > 5000 then
            updateTool(k.player, "cpu", nil, true, callback_cpu)
            KAC.debug("[KAC] Alert: " .. k.player:Name() .. ": high cpu -> " .. (k.name or "generic") .. " -> " .. time .. "us")
            if GAS and GAS.Logging then
                hook.Run("KAC_Log_Wiremod","{1} E2 {2} high cpu {3}",{GAS.Logging:FormatPlayer(k.player),GAS.Logging:Highlight(string.PatternSafe(k.name) or "generic"),GAS.Logging:Highlight(tostring(time))})
            end
        end
    end
    local TC = table.Count(Temp)
    local CC = table.Count(Cache_Expression2s)
    if TC > CC then
        for _,k in pairs(Temp) do
            if Cache_Expression2s[_] == nil then
                KAC.debug("[KAC] " .. k.owner .. "<" .. k.sid .. "> spawned expression2 -> " .. k.name)
                if GAS and GAS.Logging then
                    hook.Run("KAC_Log_Wiremod","{1} spawned expression2 {2}",{GAS.Logging:FormatPlayer(k.ent.player),GAS.Logging:Highlight(string.PatternSafe(k.name) or "generic")})
                end
            end
        end
    elseif TC < CC then
        for _,k in pairs(Cache_Expression2s) do
            if Temp[_] == nil then
                KAC.debug("[KAC] " .. k.owner .. "<" .. k.sid .. "> removed expression2 -> " .. k.name)
            end
        end
    end
    Cache_Expression2s = Temp
end
timer.Create("KAC_Expression2", 0.25, 0, loopExpression2)

hook.Add("PlayerEnteredVehicle", "KAC_EnterVehicle", function(ply, veh, id)
    if not ply then return end
    if IsValid(veh:GetParent()) then return end
    if veh.playerdynseat then return end

    local col = veh:GetCollisionGroup()
    if col == COLLISION_GROUP_WORLD then
        veh:SetCollisionGroup(COLLISION_GROUP_NONE)
        KAC.printClient(ply:UserID(), -2, "Info## Blocked Collision change on " .. returnModel(veh:GetModel()))
    end
end)

local token = {}

hook.Add("PlayerSpray", "KAC_Spray", function(ply)
    local tok = math.random(1, 255)
    token[ply:AccountID() .. "_"] = tok
    net.Start("KAC_Spray")
        net.WriteUInt(tok, 8)
    net.Send(ply)
end)

net.Receive("KAC_Spray", function(len, ply)
    local tok = net.ReadUInt(8)
    if token[ply:AccountID() .. "_"] != tok then
        KAC.detected_net(ply, "KAC_Spray")
    else
        local address = string.PatternSafe(net.ReadString() or "nil")
        KAC.debug("[KAC] " .. ply:Name() .. ": placed decal: " .. address .. ".vtf")
        if GAS and GAS.Logging then
            hook.Run("KAC_Log","{1} placed decal {2}",{GAS.Logging:FormatPlayer(ply),GAS.Logging:Highlight(address .. ".vtf")})
        end
    end
end)
