
print("[KAC] Initialized Serverside")

util.AddNetworkString("KAC_Client")

local BHopMaxCVAR = CreateConVar("sv_kac_bhop_max", 10, 128, "max amount of triggers until autoban for bhop scripts", 1 , 30)
local BHopNotifyIntervalCVAR = CreateConVar("sv_kac_bhop_notify_interval", 3, 128, "amount of triggers until staff get a notify", 1 , 10)
local CollisionsPenetrateMaxCVAR = CreateConVar("sv_kac_max_penetrate", 5, 128, "max amount of props colliding together before being auto defused", 1, 50)
local CollisionsCooldownTimerCVAR = CreateConVar("sv_kac_cooldown_timer", 5, 128, "seconds after prop spawn to check for collisions", 1, 60)
local CollisionsMinCVAR = CreateConVar("sv_kac_min_collisions", 500, 128, "prop over this amount will recieve a cooldown until they recieve a collisions check", 1, 10000)
local CollisionsMaxCVAR = CreateConVar("sv_kac_max_collisions", 2500, 128, "prop over this amount will always have collisions with props disabled", 1, 10000)
local FadingDoorPenetrateMax = CreateConVar("sv_kac_max_fading_door_penetrate", 3, 128, "max amount of toggled fading doors penetrating together", 1, 10000)

local Data = {}

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
    models_chippy_f86_bomb_mdl = 1
}

local PMT = FindMetaTable("Player")

local function owner(entity) -- Function Used From Wiremod Source --
    if entity == nil then return end
    if entity.GetPlayer then
        local ply = entity:GetPlayer()
        if IsValid(ply) then return ply end
    end

    local OnDieFunctions = entity.OnDieFunctions
    if OnDieFunctions then
        if OnDieFunctions.GetCountUpdate then
            if OnDieFunctions.GetCountUpdate.Args then
                if OnDieFunctions.GetCountUpdate.Args[1] then return OnDieFunctions.GetCountUpdate.Args[1] end
            end
        end
        if OnDieFunctions.undo1 then
            if OnDieFunctions.undo1.Args then
                if OnDieFunctions.undo1.Args[2] then return OnDieFunctions.undo1.Args[2] end
            end
        end
    end

    if entity.GetOwner then
        local ply = entity:GetOwner()
        if IsValid(ply) then return ply end
    end

    return nil
end

function PMT:IsBuild()
    local ply = PMT
    local co = owner(ply)
    if co:IsPlayer() then ply = co end
    if not ply:IsPlayer() then return false end
    if PMT.isBuild then return PMT:isBuild() end 
    return false
end

local LastTrigger = 0
--[[
    victimID = -1, sends to admins
    victimID = -2, sends to admins + targetID
    victimID = -3, sends to all players
    victimID = -4, sends to only target
]]--
local function printClient(targetID, victimID, message, showVictim)
    showVictim = showVictim or false
    if targetID == 0 or victimID == 0 then print("[KAC] Error: NetMSG TargetID[" .. targetID .. "] VictimID[" .. victimID .. "] " .. message) return end

    if victimID == -4 then
        local Str = targetID .. "^"  .. victimID .. "^" .. message
        net.Start("KAC_Client")
            net.WriteString(Str)
        net.Send(Player(targetID))
    else
        LastTrigger = targetID
        for k, ply in pairs(player.GetAll()) do
            if ply:IsBot() then continue end
            if ply:IsAdmin() or (ply:UserID() == victimID and showVictim) or (targetID == ply:UserID() and victimID  == -2) or victimID == -3 then 
                local Str = targetID .. "^"  .. victimID .. "^" .. message
                net.Start("KAC_Client")
                    net.WriteString(Str)
                net.Send(ply)
            end
        end
    end
end

local function returnModel(string_)
    if string_ == "" or not string_ then return "<Error>" end
    local str = string.Explode("/", string.lower(string_))
    return string.Explode(".", str[table.Count(str)])[1]
end

local function steam(player_)
    if not player_ or player_:IsBot() then return "" end
    return string.Explode(":", player_:SteamID())[3]
end

local function checkData(player_)
    if not player_ then print("[KAC] Error: Unknown Player in checkData()") return false end
    local steamC = steam(player_)
    if not steamC then print("[KAC] Error: steam() retuned nil in checkData() for " .. player_:Name()) return false end
    if not Data[steamC] then
        Data[steamC] = { valid = true, bhop = 0, button = { jump = -1 } }
        print("[KAC] Info: Creating: " .. player_:Name() .. ": Main Data table")
    end
    return steamC
end

local function validate(player_, tool)
    if not KACSettings[tool] then print("[KAC] Error: KACSettings not loaded in validate()") return false end
    if not player_ then print("[KAC] Error: Unknown Player in validate() for " .. tool) return false end
    if not tool then print("[KAC] Error: " .. player_:Name() .. ": Unknown Tool in validate()") return false end
    local steamC = checkData(player_)
    if not steamC then print("[KAC] Error: " .. player_:Name() .. ": checkData() failed in validate()") return false end
    if not Data[steamC] then print("[KAC] Error: " .. player_:Name() .. ": Data Table nil in validate()") return false end

    if not Data[steamC][tool] then
        Data[steamC][tool] = { warns = 0, kicked = false }
        if KACSettings[tool].threshold then
            for i = 1, KACSettings[tool].threshold, 1 do
                table.insert(Data[steamC][tool], i, 0)
            end
        end
        print("[KAC] Info: Creating: " .. player_:Name() .. ": " .. tool .. " table")
    end
    if Data[steamC][tool] then return Data[steamC] end
end

local function updateTool(player_, tool, trace)
    if not KACSettings[tool] then print("[KAC] Error: KACSettings not loaded in updateTool()") return false end
    if not player_ then print("[KAC] Error: Unknown Player: Failed updateTool() for " .. tool) return false end

    local Tab = validate(player_, tool)
    if not Tab then print("[KAC] Error: " .. player_:Name() .. ": Data Table nil in updateTool()") return false end

    local aim = trace.entity or nil
    if KACSettings[tool].requireTrace == true and not aim then return false end

    if KACSettings[tool].threshold == 0 then return end

    for i = 1, KACSettings[tool].threshold - 1, 1 do Tab[tool][i] = Tab[tool][i+1] end -- Tool Push Back
    Tab[tool][KACSettings[tool].threshold] = CurTime()
    --print("Pushed: " .. player_:Name() .. "'s " .. tool .. " table -> " .. CurTime())
    if Tab[tool][1] != 0 then
        local trigger = math.Round(Tab[tool][KACSettings[tool].threshold] - Tab[tool][1],2)
        if trigger < KACSettings[tool].update then
            local add = ""
            if aim then 
                add = add .. "[" .. returnModel(aim:GetModel()) .. "]"
            end
            printClient(player_:UserID(), -1, "Alert# " .. KACSettings[tool].threshold .. " uses of " .. tool .. " in " .. trigger .. " sec " .. add)
            for i = 1, KACSettings[tool].threshold, 1 do Tab[tool][i] = 0 end -- Reset Tool Table
        end
    end
    return Tab != nil
end

hook.Add("PlayerDeath", "Death_Notification", function(victim, inflictor, attacker)

    if IsValid(attacker) and IsValid(victim) then

        if not attacker:IsPlayer() then attacker = owner(attacker) end
        if inflictor:IsPlayer() then inflictor = inflictor:GetActiveWeapon() end

        if attacker and inflictor and victim then 
            if attacker:IsPlayer() and attacker != victim then
                local Weap = inflictor:GetClass()
                local TargetID = attacker:UserID()
                local VictimID = victim:UserID()
                local model = returnModel(inflictor:GetModel())

                if Weap == "pac_projectile" then
                    printClient(TargetID, VictimID, "killed#using a pac_projectile", true)
                elseif inflictor:IsVehicle() then
                    local Driver = inflictor:GetDriver()
                    if IsValid(Driver) then
                        if Driver:IsPlayer() then
                            --if Driver:IsBuild() then
                            --    if Driver == attacker then 
                            --        printClient(TargetID, VictimID, "ran over#using '" .. model .. "'")
                            --    else 
                            --        printClient(Driver:UserID(), VictimID, "ran over#using " .. (owner(inflictor):Name()) .. "'s '" .. model .. "'")
                            --    end
                            --end
                        end
                    else
                        printClient(TargetID, VictimID, "vehicle propkilled killed#using '" .. model .. "'", true)
                    end
                elseif Weap == "prop_physics" or inflictor:IsRagdoll() then
                    local Type = "propkilled"
                    local Explosive = Explosives[string.Replace(string.Replace(string.Replace(inflictor:GetModel(),".","_"),"-","_"),"/","_")] == 1
                    if Explosive then Type = "explosive killed" end
                    printClient(TargetID, VictimID, Type .. "#using '" .. model .. "'", true)
                end

                if attacker:InVehicle() then
                    if inflictor:IsWeapon() then
                        --printClient(TargetID, VictimID, "killed#using '" .. inflictor:GetPrintName() .. "' while in '" .. returnModel(attacker:GetVehicle():GetModel()) .. "'")
                    end
                else
                    local Min, Max = attacker:GetCollisionBounds()
                    local Box = Vector(math.abs(Min.x) + math.abs(Max.x),math.abs(Min.y) + math.abs(Max.y),math.abs(Min.z) + math.abs(Max.z))
                    local Z = 72
                    if attacker:Crouching() then Z = 36 end
                    if Box.x < 32 or Box.y < 32 or Box.z < Z then
                        printClient(TargetID, -1, "Alert# Invalid Hitbox [" .. math.Round(Box.x / 32, 2) .. "," .. math.Round(Box.y / 32, 2) .. "," .. math.Round(Box.z / Z, 2) .. "]")
                    end
                end

                --if attacker:IsBuild() then printClient(TargetID, VictimID, "killed#while in Buildmode") end
                if attacker:HasGodMode() then printClient(TargetID, VictimID, "killed#while in Godmode") end
                if attacker:GetColor()["a"] == 0 then printClient(TargetID, VictimID, "killed#while Invisible") end
            end
        elseif victim and inflictor and not victim:InVehicle() then
            if not inflictor:IsWorld() then 
	            local Owner = owner(inflictor)
	            if IsValid(Owner) then
	                printClient(-1, victim:UserID(), "killed#using " .. Owner:Name() .. "'s '" .. returnModel(inflictor:GetModel()) .. "'")
	            else
	                printClient(-1, victim:UserID(), "killed#using '" .. returnModel(inflictor:GetModel()) .. "'")
	            end
	        end
        end
    end
end)

local function collisionCount(ent)
    if not ent then return 0 end
    local phys = ent:GetPhysicsObject()
    if not phys then return 0 end
    local mes = phys:GetMesh()
    if not mes then return 0 end
    return table.Count(mes)
end

local function checkPenetrate(ent, hide, overcount, scale)
    local pCount = { }
    if not ent then return true, pCount end
    --local phys = ent:GetPhysicsObject()
    --if not phys then return true, pCount end
    --if not phys:IsPenetrating() then return true, pCount end

    local hide = hide or 0
    local overcount = overcount or -1
    local scale = scale or 1

    if ent:GetMoveType() != MOVETYPE_VPHYSICS then return true, pCount end
    if collisionCount(ent) < overcount then return true, pCount end

    local Min, Max = ent:GetCollisionBounds()
    local valid = true
    for _,e in ipairs(ents.FindInBox(ent:GetPos() + (Min * scale),ent:GetPos() + (Max * scale))) do
        if e == ent then continue end
        if e:GetMoveType() != MOVETYPE_VPHYSICS then continue end
        if collisionCount(e) < overcount then continue end

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
    return valid, pCount
end

hook.Add("CanTool", "Tool_Notification", function(ply, trace, tool)
    if updateTool(ply, tool, trace) then
        if trace.Entity then 
            print("[KAC] Info: " .. ply:Name() .. "<" .. ply:SteamID() .. "> -> " .. tool .. " -> " .. returnModel(trace.Entity:GetModel()))
        else
            print("[KAC] Info: " .. ply:Name() .. "<" .. ply:SteamID() .. "> -> " .. tool .. " -> " .. "world")
        end
    end
    if tool == "fading_door" then
        local ent = trace.Entity
        if ent then
            local t = 0
            local valid, pCount = checkPenetrate(ent)
            if not valid then
                for _,e in ipairs(pCount) do
                    if e:GetSolidFlags() == FSOLID_NOT_SOLID then
                        t = t + 1
                    end
                end
                if t >= FadingDoorPenetrateMax:GetInt() then
                    local model = returnModel(ent:GetModel())
                    print(ply:Name() .. "<" .. ply:SteamID() .. "> defusing fading door crash on " .. (t + 1) .. " entities using " .. model)
                    printClient(ply:UserID(), -1, "Alert# Defusing Fading Door Crash [" .. (t + 1) .. "][" .. model .. "]")
                    table.insert(pCount, 1, ent)
                    for _,e in ipairs(pCount) do e:Remove() end
                    return false
                end
            end
        end
    end
end)

hook.Add("PlayerSpawnedProp", "SpawnEntity_Notification", function(ply, model, ent)
    if not ply then return end

    local eMeshC = collisionCount(ent)
    if eMeshC == 0 or eMeshC < CollisionsMinCVAR:GetInt() then return end

    local pname = ply:Name()
    local sid = ply:SteamID()
    local model = returnModel(ent:GetModel())

    ent:SetCollisionGroup(COLLISION_GROUP_NPC_SCRIPTED)
    --local name = tostring(ent) .. "[" .. model .. "]"

    if eMeshC < CollisionsMaxCVAR:GetInt() then
        print("[KAC] Info: " .. pname .. "<" .. sid .. "> spawned " .. model .. " with " .. eMeshC .. " collisions")
        timer.Simple(CollisionsCooldownTimerCVAR:GetInt(),function()
            if not IsValid(ent) then return end
            if not ply then print("[KAC] Info: " .. pname .. "<" .. sid .. "> " .. model .. " defusing due to player missing") ent:SetCollisionGroup(COLLISION_GROUP_DEBRIS) ent:GetPhysicsObject():EnableMotion(false) return end

            local group = ent:GetCollisionGroup()
            if group == COLLISION_GROUP_DEBRIS then
                --print("[KAC] Info: " .. pname .. "<" .. sid .. "> " .. name .. " prop is part of defuse") 
                local valid2, pCount2 = checkPenetrate(ent, COLLISION_GROUP_DEBRIS, CollisionsMinCVAR:GetInt())
                if not valid2 then
                    for _,e in ipairs(pCount2) do
                        e:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
                        print("[KAC] Info: " .. pname .. "<" .. sid .. "> " .. tostring(e) .. "[" .. returnModel(e:GetModel()) .."] is colliding with defuse " .. name)
                    end
                end
            else
                local valid, pCount = checkPenetrate(ent, 0, CollisionsMinCVAR:GetInt())
                local tc = table.Count(pCount)
                if not valid and tc > CollisionsPenetrateMaxCVAR:GetInt() then
                    print(pname .. "<" .. sid .. "> defusing " .. tc .. " entity collisions on " .. model)
                    printClient(ply:UserID(),-1,"Alert# Defusing High Collisions [" .. tc .. "][" .. model .."]")
                    --game.ConsoleCommand("ulx jail \"" .. ply:Name() .. "\" 30\n")
                    table.insert(pCount, 1, ent)
                    for _,e in ipairs(pCount) do e:SetCollisionGroup(COLLISION_GROUP_DEBRIS) end
                else
                    if ent:GetCollisionGroup() == COLLISION_GROUP_NPC_SCRIPTED then ent:SetCollisionGroup(COLLISION_GROUP_NONE) end
                    --print(pname .. "<" .. sid .. "> " .. name .. " verified")
                end --else print(pname .. "<" .. sid .. "> " .. name .. " inside prop after spawn") end
            end
        end)
    else
        print("[KAC] Info: " .. pname .. "<" .. sid .. "> spawned " .. model .. " with " .. eMeshC .. " collisions")
    end
end)

hook.Add("PlayerSpawnedSWEP","SpawnSWEP_Notification",function(ply, ent)
    ent:SetCollisionGroup(COLLISION_GROUP_INTERACTIVE_DEBRIS)
end)

hook.Add("PlayerSpawnedSENT","SpawnSENT_Notification",function(ply, ent)
    ent:SetCollisionGroup(COLLISION_GROUP_INTERACTIVE_DEBRIS)
end)

timer.Simple(5,function() -- Wait for WireLib to be mounted

    if WireLib then
        hook.Add("PlayerBindDown", "BindDown_Notification", function(ply, binding, button) -- Wiremod Hook
            if binding then
                local steamC = checkData(ply)
                if steamC then
                    Data[steamC].button[binding] = 1
                end
            end
        end)

        hook.Add("PlayerBindUp", "BindUp_Notification", function(ply, binding, button) -- Wiremod Hook
            if binding then
                local steamC = checkData(ply)
                if steamC then
                    Data[steamC].button[binding] = -1
                end
            end
        end)
    end

end)

hook.Add("OnPlayerHitGround", "Ground_Notification",function(ply, inWater, onFloater, speed)
    local steamC = checkData(ply)
    if not ply or not ply:Alive() or inWater or onFloater then return end

    local isJump = Data[steamC].button.jump
    if isJump == 1 then
        timer.Simple(0,function() 
            local vel = ply:GetVelocity()
            if vel[3] <= 0 or Data[steamC].button.jump == -1 then return end

            print("[KAC] Info: " .. ply:Name() .. "<" .. ply:SteamID() .. ">  bhop detected [x " .. math.Round(vel[1]) ", y " .. math.Round(vel[2]) .."]")
            Data[steamC].bhop = Data[steamC].bhop + 1

            if Data[steamC].bhop >= BHopMaxCVAR:GetInt() then
                print("[KAC] Info: " .. ply:Name() .. "<" .. ply:SteamID() .. "> banning for bhop scripts [" .. Data[steamC].bhop .. "]")
                printClient(player_:UserID(), -1, "Banned# BHOP Scripts")
                ply:Lock()
                Data[steamC].bhop = 0
                timer.Simple(1,function() 
                    RunConsoleCommand("ulx", "ban", ply:Nick(), 0, "BHOP Scripts [Banned By: KAC]")
                end)
            else
                if Data[steamC].bhop % BHopNotifyIntervalCVAR:GetInt() == 0 then
                    printClient(ply:UserID(), -1, "Detected BHop Scripts")
                end
            end
        end)
    end
end)

local Props = {}
local Iter = 0
local IterC = 0
local IterCooldown = 10

local Unlock = {}
local UnlockAdmin = 0
local UnlockTarget = 0

local function rec(admin, ply)
   local max = table.Count(Unlock)
   if max > 0 then
        if IsValid(Unlock[1]) then
            print("[KAC] Info: " .. tostring(Unlock[1]) .. " running")
            if collisionCount(Unlock[1]) < CollisionsMaxCVAR:GetInt() then
                local c = Unlock[1]:GetCollisionGroup()
                if c == COLLISION_GROUP_NPC_SCRIPTED or c == COLLISION_GROUP_DEBRIS then
                    Unlock[1]:SetCollisionGroup(COLLISION_GROUP_PLAYER)
                    print("[KAC] Info: " .. Player(UnlockAdmin):Name() .. " approving [" .. tostring(Unlock[1]) .. "] for " .. Player(UnlockTarget):Name())
                end
            end
        end
        table.remove(Unlock, 1)
        timer.Simple(0.02,function()
            rec(admin, ply)
        end)
    else
        UnlockAdmin = 0
        UnlockTarget = 0
        Unlock = {}
        printClient(admin, ply, "Prop Unlock Completed For#", true)
    end
end

local function unlock(admin, ply)
    if UnlockAdmin != 0 then printClient(ply:UserID(), -1, "Approval Denied: Another Approval in Progress") return end
    if not ply:IsPlayer() then return end
    if table.Count(Props) > 0 then
        local push = {}
        for _,e in ipairs(Props) do
            if owner(e) != ply then continue end
            table.insert(push, 1, e)
        end
        if table.Count(push) == 0 then
           printClient(ply:UserID(), ply:UserID(), "Approval Denied: No Props Detected for#", true)
        else
            UnlockAdmin = admin:UserID()
            UnlockTarget = ply:UserID()
            Unlock = push
            rec(UnlockAdmin, UnlockTarget)
        end
    else
        printClient(ply:UserID(), -1, "Approval Denied: No Props on Map")
    end
end

local function getPlayer(name) 
    if not name then return nil end
    name = string.lower(name)

    for k, ply in pairs(player.GetAll()) do
        local s = string.find(string.lower(ply:Name()), name)
        if s then return ply end
    end
    return nil
end

hook.Add("PlayerSay", "Chat_Notification", function(ply, text, isTeam)
    text = string.lower(text)
    text = string.TrimRight(text)
    timer.Simple(0.05,function()
        if text[1] == "!" then
            text = string.SetChar(text, 1, "")
            local a = string.Explode(" ", text)
            if a[1] == "kac" then
                if ply:IsAdmin() then
                    if a[2] == "approve" then
                        local target = getPlayer(a[3])
                        if target then
                            printClient(ply:UserID(), target:UserID(), "Processing Prop Unlock Request For#", true)
                            unlock(ply, target)
                        else
                            printClient(ply:UserID(), -4, "Player Not Found [" .. a[3] .."]")
                        end
                    elseif a[2] == "s" then
                        if IsValid(Player(LastTrigger)) then
                            RunConsoleCommand("ulx", "send", ply:Name(), Player(LastTrigger):Name())
                        else
                            printClient(ply:UserID(), -4, "Player Not Found")
                        end
                    elseif a[2] == "update" then
                        if ply:IsSuperAdmin() then
                            printClient(ply:UserID(), -1, "Alert# Initialized Update Process")
                            kac_update()
                        else
                            printClient(ply:UserID(), -4, "Insufficient Permissions")
                        end
                    end
                else
                    printClient(ply:UserID(), -4, "Insufficient Permissions")
                end
            end
        end
    end)
end)

local function loopProps()
    if IterC > 0 then IterC = IterC - 0.03 return end
    local Count = table.Count(Props)
    Iter = Iter + 1
    if Iter > Count then
        Iter = 0
        Props = ents.FindByClass("prop_physics")
        if table.Count(Props) == 0 then IterC = IterCooldown end
    elseif Count > 0 then
        local ent = Props[Iter]
        if not IsValid(ent) then return end
        if IsValid(ent:GetParent()) then return end
        if (CurTime() - ent:GetCreationTime()) < CollisionsCooldownTimerCVAR:GetInt() then return end

        local col = collisionCount(ent)
        if col > CollisionsMaxCVAR:GetInt() then

            local group = ent:GetCollisionGroup()
            if group == COLLISION_GROUP_DEBRIS or group == COLLISION_GROUP_NPC_SCRIPTED then return end
            ent:SetCollisionGroup(COLLISION_GROUP_NPC_SCRIPTED)

            local o = owner(ent)
            if not o or not o:IsPlayer() then return end

            local model = returnModel(ent:GetModel())
            print("[KAC] Info: " .. o:Name() .. "<" .. o:SteamID() .. "> denied collision change on '" .. model .. "''")
            printClient(o:UserID(), -1, "Denied Collision change on '" .. model .. "'")

        elseif col > CollisionsMinCVAR:GetInt() then

            local o = owner(ent)
            if not o or not o:IsPlayer() then return end

            local group = ent:GetCollisionGroup()
            if group == COLLISION_GROUP_DEBRIS or group == COLLISION_GROUP_NPC_SCRIPTED or group == COLLISION_GROUP_PLAYER then return end

            local valid, pCount = checkPenetrate(ent, 0, CollisionsMinCVAR:GetInt())
            local tc1 = table.Count(pCount)
            if valid or tc1 == 0 or tc1 < CollisionsPenetrateMaxCVAR:GetInt() then return end
            local pCount2 = {}
            for _,e in ipairs(pCount) do
                local g = e:GetCollisionGroup()
                if g != COLLISION_GROUP_DEBRIS and g != COLLISION_GROUP_NPC_SCRIPTED then
                    table.insert(pCount2, 1, e)
                end
            end

            local tc = table.Count(pCount2)
            if tc < CollisionsPenetrateMaxCVAR:GetInt() then return end

            local model = returnModel(ent:GetModel())
            print("[KAC] Info: " .. o:Name() .. "<" .. o:SteamID() .. "> defusing " .. tc .. " entity collisions on " .. model)
            printClient(o:UserID(), -1, "Defusing Collisions [" .. tc .. "][" .. model .. "]")
            --game.ConsoleCommand("ulx jail \"" .. o:Name() .. "\" 30\n")
            table.insert(pCount2, 1, ent)
            for _,e in ipairs(pCount2) do e:SetCollisionGroup(COLLISION_GROUP_NPC_SCRIPTED) end
        end
    end
end
timer.Create("PropLooper", 0.03, 0, loopProps)

local IterP = 0
local function loopPlayer()
    IterP = IterP + 1
    if IterP > player.GetCount() then IterP = 1 end

    local ply = player.GetAll()[IterP]
    if not ply then return end
    if not ply:InVehicle() then return end

    local veh = ply:GetVehicle()
    if IsValid(veh:GetParent()) then return end

    local col = veh:GetCollisionGroup()
    if col == COLLISION_GROUP_WORLD then
        veh:SetCollisionGroup(COLLISION_GROUP_NONE)
        printClient(ply:UserID(), -2, "Alert# Illegal to Disable Collisions on Vehicles")
    end
end
timer.Create("VehicleLooper", 0.3, 0, loopPlayer)