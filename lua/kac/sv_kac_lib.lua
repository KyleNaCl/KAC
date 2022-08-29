
print("[KAC] \tLoaded sv_kac_lib.lua")

-----Settings-----

KAC = {}

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
    },
    cpu = {
        update = 3,
        threshold = 5,
        requireTrace = false,
        isTool = false,
    },
    KACCol = Color(175,175,255),
    TextSep = Color(100,100,255),
    TextCol = Color(255,255,255)
}

KACTriggers = {
    aimbot = {
        name = "aimbot",
        threshold = 10,
        delta = 0.005,
        desc = "Aimbot",
        strict = true,
        time = "0",
        auto = true
    },
    bhop = {
        name = "bhop",
        threshold = 5,
        delta = 0.005,
        desc = "BHOP Scripts",
        strict = true,
        time = "0",
        auto = true
    },
    autoshoot = {
        name = "autoshoot",
        threshold = -1,
        delta = 1,
        desc = "Autoshoot",
        strict = false,
        time = "0",
        auto = false
    },
    propkill = {
        name = "propkill",
        threshold = 4,
        delta = 0.002,
        desc = "Propkill",
        strict = false,
        time = "3d",
        auto = true
    },
    pac = {
        name = "pac",
        threshold = 3,
        delta = 0.002,
        desc = "PAC Abuse",
        strict = false,
        time = "3d",
        auto = true
    },
    buildmode = {
        name = "buildmode",
        threshold = 3,
        delta = 0.002,
        desc = "Buildmode Abuse",
        strict = false,
        time = "3d",
        auto = true
    },
    fading = {
        name = "fading",
        threshold = 3,
        delta = 0.05,
        desc = "Fading Door Crash",
        strict = false,
        time = "1y",
        auto = true
    },
    simfphys = {
        name = "simfphys",
        threshold = 6,
        delta = 0.05,
        desc = "Simfphys Crash",
        strict = false,
        time = "1y",
        auto = true
    },
    prop_spam = {
        name = "prop_spam",
        threshold = 20,
        delta = 0.5,
        desc = "Prop Crash",
        strict = false,
        time = "1y",
        auto = true
    }
}

-----ULX Permissions-----

if ULib ~= nil then
    ULib.ucl.registerAccess("kac_notify", {"admin", "superadmin"}, "Allows users to see KAC notifications", "KAC")
    ULib.ucl.registerAccess("kac_approve", {"admin", "superadmin"}, "Enables collisions for player props", "KAC")
    ULib.ucl.registerAccess("kac_check_owner", {"operator", "admin", "superadmin"}, "Checks the owner of player's game", "KAC")
    ULib.ucl.registerAccess("kac_send", {"operator", "admin", "superadmin"}, "Allows user to go to last user to trigger a KAC message", "KAC")
    ULib.ucl.registerAccess("kac_sv_values", {"superadmin"}, "Edit KAC values", "KAC")
end

-----Net Strings-----

util.AddNetworkString("KAC_Settings")
util.AddNetworkString("KAC_Client")
util.AddNetworkString("KAC_Join")
util.AddNetworkString("KAC_Punishment")
util.AddNetworkString("KAC_Detection")
util.AddNetworkString("KAC_Spray")

-----Functions-----

if not file.Exists("kac_log.txt","DATA") then
    file.Write("kac_log.txt", "Log of all KAC prints\n\n")
end

function KAC.GetOwner(entity) -- Function Used From Wiremod Source --
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
    if CPPI then
        local ply = entity:CPPIGetOwner()
        if IsValid(ply) then
            return ply
        end
    end

    return nil
end

local function format_printClient(Message, TargetID, VictimID)
    TargetID = TargetID or 0 
    VictimID = VictimID or 0
    if TargetID > 0 then 
        local ply = Player(TargetID)
        if IsValid(ply) then
            local name = string.format("%s<%s>", ply:Name(), ply:SteamID())
            if VictimID > 0 then 
                local vic = Player(VictimID)
                if IsValid(vic) then
                    local vicname = string.format("%s<%s>", vic:Name(), vic:SteamID())
                    if not string.find(Message, "#") then Message = Message .. "#" end
                    local StrS = string.Explode("#",Message)
                    return string.format("%s %s %s %s",name,StrS[1],vicname,StrS[2])
                end
            else 
                if string.find(Message, "##") then
                    local A = string.Explode("##", Message)
                    return string.format("%s %s%s",name,A[1],A[2])
                elseif string.find(Message, "#") then
                    local A = string.Explode("#", Message)
                    return string.format("%s %s%s",name,A[1],A[2])
                else
                    return string.format("%s %s",name,Message)
                end
            end
        else
            return "Player Offline: " .. Message
        end
    else
        if VictimID > 0 then 
            local vic = Player(VictimID)
            if vic then
                local vicname = string.format("%s<%s>", vic:Name(), vic:SteamID())
                local StrS = string.Explode("#",Message)
                return string.format("Unknown Player %s %s %s",StrS[1],vicname,StrS[2])
            end
        else
            return Message
        end
    end
end

KACLog = {}

local function pushTimer(name, time_, message)
    if KACLog[name] == nil then KACLog[name] = {iter = 0, time = time_, send = message} end
    KACLog[name].iter = KACLog[name].iter + 1
    if KACLog[name].iter > 5 then
        local add = ""
        if KACLog[name].iter > 1 then add = " (x" .. KACLog[name].iter  .. ")" end
        file.Append("kac_log.txt", KACLog[name].time .. KACLog[name].send .. add .. "\n")
        KACLog[name].iter = KACLog[name].iter - 5
        KACLog[name].time = time_
    end
    timer.Create(name, 2, 1, function()
        local add = ""
        if KACLog[name] and KACLog[name].iter > 1 then add = " (x" .. KACLog[name].iter  .. ")" end
        file.Append("kac_log.txt", KACLog[name].time .. KACLog[name].send .. add .. "\n")
        KACLog[name] = nil
    end)
end

local function logToFile(data, TargetID, VictimID)
    if string.sub(data,1,6) == "[KAC] " then
        data = string.sub(data, 7)
    end
    if string.sub(data,1,6) == "Info: " then
        data = string.sub(data, 7)
    end

    local time_ = tonumber(os.date("%Y%j"))
    local filetime_ = tonumber(os.date("%Y%j",file.Time("kac_log.txt", "DATA")))

    if filetime_ < time_ then
        file.Append("kac_log.txt", "// " .. os.date("%m/%d/%Y") .. "...\n")
    end

    if timer.TimeLeft(data) then timer.Remove(data) end
    timer.Simple(0,function() pushTimer(data, os.date("%I:%M:%S%p"), " = " .. format_printClient(data, TargetID, VictimID)) end)
end

function KAC.print2(text, nolog)
    KAC.debug("[KAC] Error: Legacy Call: " .. debug.traceback(), true)
    KAC.debug(text,nolog)
end

function KAC.debug(text, nolog)
    if player.GetCount() > 0 then
        for k, ply in pairs(player.GetHumans()) do
            local Print = false
            if ULib then Print = ULib.ucl.query(ply, "kac_notify")
            else Print = ply:IsAdmin() end
            if Print and not ply:IsListenServerHost() then
                ply:PrintMessage(HUD_PRINTCONSOLE, text)
            end
        end
    end
    print(text)
    if not nolog then
        logToFile(text)
    end
end

local function difference(A, B)
    if not A or not B then return 0 end
    if math.max(A,B) == B then
        return B - A
    else
        return A - B
    end
end

function KAC.returnData(player_)
    if not player_ then KAC.debug("[KAC] Error: Unknown Player in KAC.returnData()") return nil end
    if player_:IsBot() then return nil end
    if not player_:IsPlayer() then KAC.debug("[KAC] Error: KAC.returnData(" .. tostring(player_) .. ")") return nil end
    local steamC = player_:AccountID()

    if not steamC or steamC == "" then KAC.debug("[KAC] Error: steamID format retuned nil in KAC.returnData() for " .. player_:Name()) return nil end
    if not KAC[steamC] then
        KAC[steamC] = { 
            button = { jump = -1 },   -- bind tracker
            posData = Vector(),       -- position tracker
            groundCheck = 1,          -- bhop check
            moveCheck = 0,            -- movetype tracker
            mouseCheck = false,       -- mouse input tracker
            eyea = Angle(),           -- eyeAngle tracker
            shotCooldown = SysTime(), -- last shot SysTime
            lockData = Vector(),      -- last aim snap tracker
            deltaData = Vector(),     -- eyeAngle change per ucmd
            spreadData = Vector(), -- weapon spread tracker
            weaponData = {            -- weapon swap table tracker
                deathTime = -1
            },
            IsSkeleton = false,       -- player is skeleton model
            jumpData = Vector(),      -- sidehop data tracker
            syncedCurtime = -1,       -- synced CurTime per UpdateData
            syncedBuildmode = -1,     -- synced Buildmode CurTimer per UpdateData 
            contextopen = false,      -- the player's context menu is open
            xboxcontroller = -1,      -- player is using controller
            punishment = {            -- punishment table tracker
                wait = false,
                wait_target = 0,
                wait_reason = ""
            }
        }
        for _, trigger in pairs(KACTriggers) do
            KAC[steamC].punishment[trigger.name] = {
                returning = false
            }
        end
    end
    return steamC
end

function KAC.InBuild(ply)
    if not IsValid(ply) then return false end
    if not ply:IsPlayer() then return false end
    local co = KAC.GetOwner(ply)
    if IsValid(co) and co:IsPlayer() then ply = co end
    if ply.isBuild then return ply:isBuild() end
    return false
end

function KAC.isDesynced(ply) 
    if not ply then KAC.debug("[KAC] Error: Unknown Player in KAC.isDesynced()") return true end

    local steamC = KAC.returnData(ply)
    if KAC[steamC] then
        if KAC[steamC].syncedCurtime == -1 then return true end
        if ply:IsTimingOut() or ply:PacketLoss() > 0 then return true end
        return SysTime() > KAC[steamC].syncedCurtime + 0.2
    end
    return true
end

function KAC.UpdateData(ply, force, hold)
    if not ply then KAC.debug("[KAC] Error: Unknown Player in KAC.UpdateData()") return 0 end
    if not ply:IsPlayer() then KAC.debug("[KAC] Error: KAC.UpdateData(" .. tostring(ply) .. ")") return 0 end

    local steamC = KAC.returnData(ply)
    local Systime = SysTime()
    if KAC[steamC] then
        local IsInBuild = KAC.InBuild(ply)
        if IsInBuild then
            KAC[steamC].syncedBuildmode = CurTime()
        end
        if not ply:Alive() then
            KAC[steamC].weaponData = { deathTime = CurTime() }
        end
        local Pos = ply:GetPos()
        local Run = ply:Alive() and IsValid(ply:GetActiveWeapon()) and 
                    not ply:IsTimingOut() and not ply:InVehicle() and
                    not IsInBuild and not ply:HasGodMode() and
                    ply:GetMoveType() != MOVETYPE_NOCLIP and ply:PacketLoss() == 0 and
                    difference(KAC[steamC].posData[1],Pos[1]) < 250 and 
                    difference(KAC[steamC].posData[2],Pos[2]) < 250 and 
                    difference(KAC[steamC].posData[3],Pos[3]) < 250
        if Run then
            Run = ply:GetActiveWeapon():Clip1() > -1
        end
        if not ply:IsTimingOut() and ply:PacketLoss() == 0 then
            KAC[steamC].syncedCurtime = Systime
        end
        if IsValid(force) then
            Run = force
        end
        if not Run then
            hold = hold or 0.5
            KAC[steamC].groundCheck = Systime + hold
            KAC[steamC].lockData = Vector()
            KAC[steamC].deltaData = Vector()
            KAC[steamC].jumpData = Vector()
            KAC[steamC].spreadData = Vector()
            KAC[steamC].eyea = ply:EyeAngles()
        end
        KAC[steamC].posData = Pos
        return Run
    end
    return 0
end

function KAC.PrintJoin(type, name, steamid, reason)
    reason = reason or "a"
    net.Start("KAC_Join")
        net.WriteString(name)
        net.WriteString(steamid)
        net.WriteUInt(type, 2)
        net.WriteString(reason)
    net.Broadcast()
end

local function createMessage(TargetID, VictimID, Message)
    TargetID = TargetID or 0
    VictimID = VictimID or 0
    if TargetID > 0 then 
        local ply = Player(TargetID)
        if IsValid(ply) then
            if VictimID > 0 then 
                local vic = Player(VictimID)
                if IsValid(vic) then
                    if not string.find(Message, "#") then Message = Message .. "#" end
                    local StrS = string.Explode("#",Message)
                    if GAS and GAS.Logging then
                        hook.Run("KAC_Log","{1} " .. StrS[1] .. " {2} " .. StrS[2],{GAS.Logging:FormatPlayer(ply),GAS.Logging:FormatPlayer(vic)})
                    end
                    return {team.GetColor(ply:Team()),ply:Name(),KACSettings.TextCol," " .. StrS[1] .. " ",team.GetColor(vic:Team()),vic:Name(),KACSettings.TextCol," " .. StrS[2]}
                end
            else 
                if string.find(Message, "##") then
                    local StrS = string.Explode("##", Message)
                    if GAS and GAS.Logging then
                        hook.Run("KAC_Log","{1}" .. StrS[2],{GAS.Logging:FormatPlayer(ply)})
                    end
                    return {team.GetColor(ply:Team()),ply:Name(),KACSettings.TextCol," ",Color(100,100,255),StrS[1],KACSettings.TextCol,StrS[2]}
                elseif string.find(Message, "#") then
                    local StrS = string.Explode("#", Message)
                    if GAS and GAS.Logging then
                        hook.Run("KAC_Log","{1}" .. StrS[2],{GAS.Logging:FormatPlayer(ply)})
                    end
                    return {team.GetColor(ply:Team()),ply:Name(),KACSettings.TextCol," ",Color(255,100,100),StrS[1],KACSettings.TextCol,StrS[2]}
                else
                    if GAS and GAS.Logging then
                        hook.Run("KAC_Log","{1} " .. Message,{GAS.Logging:FormatPlayer(ply)})
                    end
                    return {team.GetColor(ply:Team()),ply:Name(),KACSettings.TextCol," " .. Message}
                end
            end
        end
    else
        if VictimID > 0 then 
            local vic = Player(VictimID)
            if IsValid(vic) then
                local StrS = string.Explode("#",Message)
                if GAS and GAS.Logging then
                    hook.Run("KAC_Log","Unknown Player " .. StrS[1] .. " {1} " .. StrS[2],{GAS.Logging:FormatPlayer(vic)})
                end
                return {KACSettings.TextCol,"Unknown Player " .. StrS[1] .. " ",team.GetColor(vic:Team()),vic:Name(),KACSettings.TextCol," " .. StrS[2]}
            end
        else
            hook.Run("KAC_Log",Message)
            return {KACSettings.TextCol,Message}
        end
    end
end

--[[
    victimID = -1, sends to admins
    victimID = -2, sends to admins + targetID
    victimID = -3, sends to all players
    victimID = -4, sends to only target
]]--
function KAC.printClient(targetID, victimID, message, showVictim)
    showVictim = showVictim or false
    if targetID == 0 or victimID == 0 then KAC.debug("[KAC] Error: printClient() called TargetID[" .. targetID .. "] VictimID[" .. victimID .. "] " .. message) return end
    
    logToFile(message, targetID, victimID)
    
    if victimID == -4 then
        local Message = createMessage(targetID, victimID, message)
        net.Start("KAC_Client")
            net.WriteUInt(#Message, 4)
            for a = 1, #Message, 2 do
                net.WriteColor(Message[a])
                net.WriteString(Message[a + 1])
            end
        net.Send(Player(targetID))
    else
        KAC.LastTrigger = targetID
        local Filter = RecipientFilter()
        for k, ply in pairs(player.GetAll()) do
            if ply:IsBot() then continue end
            local Print = false
            if ULib then Print = ULib.ucl.query(ply, "kac_notify")
            else Print = ply:IsAdmin() end
            if Print or (ply:UserID() == victimID and showVictim) or (targetID == ply:UserID() and victimID  == -2) or victimID == -3 then 
                Filter:AddPlayer(ply)
            end
        end
        if Filter:GetCount() > 0 then
            local Message = createMessage(targetID, victimID, message)
            net.Start("KAC_Client")
                net.WriteUInt(#Message, 4)
                for a = 1, #Message, 2 do
                    net.WriteColor(Message[a])
                    net.WriteString(Message[a + 1])
                end
            net.Send(Filter)
        end
    end
end

local Buttons = {
    ["114"] = true,
    ["115"] = true,
    ["116"] = true,
    ["117"] = true,
    ["118"] = true,
    ["119"] = true,
    ["120"] = true,
    ["121"] = true,
    ["122"] = true,
    ["123"] = true,

    ["146"] = true,
    ["147"] = true,
    ["148"] = true,
    ["149"] = true,
    ["150"] = true,
    ["151"] = true,
    ["152"] = true,
    ["153"] = true,
    ["154"] = true,
    ["155"] = true,
    ["156"] = true,
    ["157"] = true,
    ["158"] = true,
    ["159"] = true
}

local AC_Whitelist = {
    ["912179120"] = true --Katelyn.N<STEAM_0:0:456089560>
}

timer.Simple(3,function() -- Wait for WireLib to be mounted

    if WireLib then
        hook.Add("PlayerBindDown", "KAC_BindDown", function(ply, binding, button) -- Wiremod Hook
            if binding then
                local steamC = KAC.returnData(ply)
                if KAC[steamC] then
                    KAC[steamC].button[binding] = 1
                    if tostring(binding) == "jump" and KAC[steamC].groundCheck < 5 then KAC[steamC].groundCheck = 0 end
                end
            else
                if Buttons[tostring(button)] or AC_Whitelist[steamC] then
                    local steamC = KAC.returnData(ply)
                    if KAC[steamC] then
                        KAC[steamC].xboxcontroller = SysTime() + 60
                    end
                end
            end
        end)

        hook.Add("PlayerBindUp", "KAC_BindUp", function(ply, binding, button) -- Wiremod Hook
            if binding then
                local steamC = KAC.returnData(ply)
                if KAC[steamC] then
                    KAC[steamC].button[binding] = -1
                    if tostring(binding) == "jump" and KAC[steamC].groundCheck < 5 then KAC[steamC].groundCheck = 0 end
                end
            end
        end)

        --[[
        if ACF then
            function ACF_GetPhysicalParent( obj )
                if not IsValid(obj) then return nil end

                --check for fresh cached parent
                if IsValid(obj.acfphysparent) and ACF.CurTime < obj.acfphysstale then
                    return obj.acfphysparent
                end

                local Parent = obj

                while Parent:GetParent():IsValid() do
                    Parent = Parent:GetParent()
                end

                --update cached parent
                obj.acfphysparent = Parent
                obj.acfphysstale = ACF.CurTime + 10 --when cached parent is considered stale and needs updating

                return Parent
            end
        end
        ]]
    end

    local function loopDelta()
        if player.GetCount() == 0 then return end
        if KACTriggers == nil then return end
        for k, ply in pairs(player.GetHumans()) do
            local steamC = KAC.returnData(ply)
            if KAC[steamC] then
                for _, trigger in pairs(KACTriggers) do
                    local type_ = trigger.name
                    if KACTriggers[type_] == nil then continue end
                    if KACTriggers[type_][steamC] == nil then continue end
                    if KACTriggers[type_][steamC] > 0 then 
                        KACTriggers[type_][steamC] = KACTriggers[type_][steamC] - KACTriggers[type_].delta
                        if KACTriggers[type_][steamC] <= 0 then 
                            KACTriggers[type_][steamC] = 0
                            if KACTriggers[type_].threshold != -1 then
                                KAC.debug("[KAC] " .. ply:Name() .. "<" .. ply:SteamID() .. "> " .. type_ .. " delta zero'd")
                            end
                        end
                    end
                end
            end
        end
    end
    timer.Create("KAC_TriggerDelta", 1, 0, loopDelta)

    -- Tinnitus Remover
    hook.Add("OnDamagedByExplosion", "DisableExplosiveTinnitus", function()
        return true
    end)

    -- Auto Decal Cleanup
    if timer.Exists("DecalCleanupTimer") then
        timer.Remove("DecalCleanupTimer")
    end
    timer.Create("DecalCleanupTimer", 120, 0, function()
        BroadcastLua("RunConsoleCommand('r_cleardecals')")
    end)

    -- Remove all NPC Overwrite Weapons
    local T = list.GetForEdit("NPCUsableWeapons")
    T = {}

    -- ACF 2 Modifier
    --[[
    local A = list.GetForEdit("ACFClasses")
    A.GunClass.RAC.rofmod = 0.09
    A.GunClass.RAC.spread = 0.5

    A.GunClass.RAC.ammoBlacklist = { "HE", "APHE" }
    A.GunClass.MG.ammoBlacklist = { "HE", "APHE" }
    ]]

    -- Seat Optimizer
    hook.Add("OnEntityCreated", "GS_PodFix", function(pEntity)
        if (pEntity:GetClass() == "prop_vehicle_prisoner_pod") then
            pEntity:AddEFlags(EFL_NO_THINK_FUNCTION)
        end
    end)

    hook.Add("PlayerEnteredVehicle", "GS_PodFix", function(_, pVehicle)
        if (pVehicle:GetClass() == "prop_vehicle_prisoner_pod") then
            pVehicle:RemoveEFlags(EFL_NO_THINK_FUNCTION)
        end
    end)

    hook.Add("PlayerLeaveVehicle", "GS_PodFix", function(_, pVehicle)
        if (pVehicle:GetClass() == "prop_vehicle_prisoner_pod") then
            local sName = "GS_PodFix_" .. pVehicle:EntIndex()

            hook.Add("Think", sName, function()
                if (pVehicle:IsValid()) then
                    local fGetInternalVariable = pVehicle.GetInternalVariable
                    
                    -- If set manually
                    if (fGetInternalVariable(pVehicle, "m_bEnterAnimOn") == true) then
                        hook.Remove("Think", sName)
                    elseif (fGetInternalVariable(pVehicle, "m_bExitAnimOn") == false) then
                        pVehicle:AddEFlags(EFL_NO_THINK_FUNCTION)

                        hook.Remove("Think", sName)
                    end
                else
                    hook.Remove("Think", sName)
                end
            end)
        end
    end)

    -- Anti-Model Cache Crash
    local mpcache = {}
    local totalCache = 0

    local function checkPC(model, ply)
        if mpcache[model] == nil then
            if totalCache < 4096 - 512 then
                mpcache[model] = true
                totalCache = totalCache + 1
            else
                ply:SendLua("notification.AddLegacy('Model Cache Limit Reached',NOTIFY_ERROR,5)")
                return false
            end
        end
        return true
    end

    hook.Add("InitPostEntity", "MPCW_IPEntity", function() -- try to approximate number of map models
        local newCache = 0
        for i,ent in ipairs(ents.GetAll()) do
            if IsValid(ent) then
                if ent:GetModel() ~= nil then
                    local model = ent:GetModel()
                    if mpcache[model] == nil then
                        mpcache[model] = true
                        newCache = newCache + 1
                    end
                    
                end
            end
        end
        totalCache = newCache + totalCache -- # of map props + 128 since the system may miss some during map spawn
    end)

    hook.Add("OnEntityCreated", "MPCW_OnEntityCreate", function(ent) -- handle map entities when they are created
        timer.Simple(0,function()
            if IsValid(ent) then
                if ent:GetModel() ~= nil then
                    local model = ent:GetModel()
                    if mpcache[model] == nil then
                        mpcache[model] = true
                        totalCache = totalCache + 1
                    end
                end
            end
        end)
    end)

    hook.Add("PlayerSpawnObject", "MPCW_PSpawnObject", function(ply, model, skin) -- covers Effects, Props, and ragdolls 
        if not checkPC(model, ply) then return false end
    end)

    hook.Add("PlayerSpawnVehicle", "MPCW_PSpawnVehicle", function(ply, model, name, vTable) -- vehicles
        if not checkPC(model, ply) then return false end
    end)
end)

-- Widget Disabler
hook.Add("PreGamemodeLoaded", "widgets_disabler_cpu", function()
    function widgets.PlayerTick()
        -- empty
    end
    hook.Remove("PlayerTick", "TickWidgets")
end)

function KAC.pushTrigger(ply, type_, amount)
    amount = amount or 1
    if not ply then KAC.debug("[KAC] Error: Unknown Player in KAC.pushTrigger()") return end
    if not type_ then KAC.debug("[KAC] Error: " .. ply:Name() .. ": type_ is nil in KAC.pushTrigger()") return end
    if not KACTriggers[type_] then KAC.debug("[KAC] Error: " .. ply:Name() .. ": type_ is " .. type_ .. " in KAC.pushTrigger()") return end
    local steamC = KAC.returnData(ply)
    if not KAC[steamC] then KAC.debug("[KAC] Error: " .. ply:Name() .. ": steamC is nil in KAC.pushTrigger()") return
    else
        if KACTriggers[type_][steamC] == nil then KACTriggers[type_][steamC] = 0 end
        if KACTriggers[type_].threshold == -1 then
            KACTriggers[type_][steamC] = amount
        else
            KACTriggers[type_][steamC] = KACTriggers[type_][steamC] + amount + (KACTriggers[type_].delta * 10)
            if KACTriggers[type_][steamC] >= KACTriggers[type_].threshold then
                if KACTriggers[type_].auto then 
                    KACTriggers[type_][steamC] = 0
                    local t_strict = "Kick"
                    local is_strict = KACTriggers[type_].strict or (not KACTriggers[type_].strict and KAC[steamC].punishment[type_].returning)
                    if is_strict then t_strict = "Ban" end
                    if not ply:IsListenServerHost() then
                        if is_strict then
                            KAC[steamC].punishment[type_].returning = false
                            RunConsoleCommand("ulx", "banid", ply:SteamID(), KACTriggers[type_].time, KACTriggers[type_].desc .. " [By: KAC]")
                            game.KickID(ply:UserID(),"Banned: " .. KACTriggers[type_].desc .. " [By: KAC]")
                        else
                            KAC[steamC].punishment[type_].returning = true
                            game.KickID(ply:UserID(),"Kicked: " .. KACTriggers[type_].desc .. " [By: KAC]")
                        end
                    end
                    KAC.debug("[KAC] " .. ply:Name() .. "<" .. ply:SteamID() .. "> " .. t_strict .." for " .. KACTriggers[type_].desc)
                    KAC.printClient(ply:UserID(), -3, "Auto-Mod# " .. t_strict .. " for " .. KACTriggers[type_].desc)
                    return true
                end
            else
                KAC.debug("[KAC] " .. ply:Name() .. "<" .. ply:SteamID() .. "> " .. type_ .. " [" .. KACTriggers[type_][steamC] .. " / " .. KACTriggers[type_].threshold .. "]")
            end
        end
    end
    return false
end

function KAC.SendPunishment(ply, type_, victim, inflictor)
    if not ply then KAC.debug("[KAC] Error: Unknown Player in KAC.SendPunishment()") return end
    if not victim then KAC.debug("[KAC] Error: victim is nil in KAC.SendPunishment()") return end
    if not type_ then KAC.debug("[KAC] Error: " .. ply:Name() .. ": type_ is nil in KAC.SendPunishment()") return end
    if not KACTriggers[type_] then KAC.debug("[KAC] Error: " .. ply:Name() .. ": type_ is " .. tostring(type_) .. " in KAC.SendPunishment()") return end
    --victim = ply
    if victim:IsBot() then return end
    local steamC = KAC.returnData(ply)
    if not KAC[steamC] then KAC.debug("[KAC] Error: " .. ply:Name() .. ": steamC is nil in KAC.SendPunishment()") return end
    local steamCV = KAC.returnData(victim)
    if not KAC[steamCV] then KAC.debug("[KAC] Error: " .. victim:Name() .. ": steamCV is nil in KAC.SendPunishment()") return end
    if KAC[steamC] and KAC[steamCV] then
        if KAC[steamC].punishment and KAC[steamCV].punishment then
            if not KAC[steamCV].punishment.wait then
                net.Start("KAC_Punishment")
                    net.WriteString(ply:Name())
                    net.WriteColor(team.GetColor(ply:Team()))
                    net.WriteString(type_)
                    net.WriteInt(math.floor(KACTriggers[type_][steamC] or 0),5)
                    net.WriteInt(KACTriggers[type_].threshold,5)
                net.Send(victim)
                KAC[steamCV].punishment.wait = true
                KAC[steamCV].punishment.wait_target = ply:UserID()
                KAC[steamCV].punishment.wait_reason = type_
                KAC.debug("[KAC] " .. ply:Name() .. "<" .. ply:SteamID() .. "> " .. type_ .. " sent validation to " .. victim:Name())
                timer.Simple(30,function()
                    if KAC[steamCV].punishment.wait then
                        KAC[steamCV].punishment.wait = false
                        KAC[steamCV].punishment.wait_target = 0
                        KAC.debug("[KAC] " .. ply:Name() .. "<" .. ply:SteamID() .. "> never received " .. type_ .. " validation from " .. victim:Name())
                    end
                end)
            else
                KAC.debug("[KAC] Error: " .. ply:Name() .. ": currently waiting on response from " .. victim:Name())
            end
        end
    end
end

net.Receive("KAC_Punishment",function(len, ply)
    local steamCV = KAC.returnData(ply)
    if not KAC[steamCV] then KAC.debug("[KAC] Error: " .. tostring(ply) .. ": steamCV is nil in KAC_Punishment NetMSG") return end
    if KAC[steamCV] then
        if KAC[steamCV].punishment then
            local type_ = KAC[steamCV].punishment.wait_reason
            local bool = net.ReadBool() or false
            local attacker = Player(KAC[steamCV].punishment.wait_target)
            local steamC = KAC.returnData(attacker)
            if not steamC then KAC.debug("[KAC] Error: " .. tostring(attacker) .. ": steamC is nil in KAC_Punishment NetMSG") return end
            if KAC[steamC] then
                if KAC[steamC].punishment then
                    if bool then
                        if not KAC.pushTrigger(attacker, type_, 1.1) then
                            KAC.printClient(attacker:UserID(), ply:UserID(), type_ .. "[" .. math.floor(KACTriggers[type_][steamC]) .. "/" .. KACTriggers[type_].threshold .. "] validated by#")
                        end
                    end
                end
            end
            KAC.debug("[KAC] " .. ply:Name() .. "<" .. ply:SteamID() .. "> received validation for " .. type_ .. "[" .. tostring(bool) .. "] from " .. attacker:Name() .. " ")
            KAC[steamCV].punishment.wait = false
            KAC[steamCV].punishment.wait_target = 0
        else
            KAC.debug("[KAC] " .. ply:Name() .. "<" .. ply:SteamID() .. "> received illegal validation [" .. len .. "," .. tostring(net.ReadBool()) .. "]")
        end
    end
end)

net.Receive("KAC_Detection", function(len, ply)
    local steamC = KAC.returnData(ply)
    if not KAC[steamC] then KAC.debug("[KAC] Error: " .. tostring(ply) .. ": steamC is nil in KAC_Detection NetMSG") return end
    local alert = net.ReadString()
end)

hook.Add( "PlayerInitialSpawn", "IsPlayerFullyLoaded", function( spawnedPly )
    spawnedPly:SetNWBool("IsPlayerFullyLoaded", false)
    hook.Add( "SetupMove", spawnedPly, function( self, ply, _, cmd )
        if self ~= ply then return end
        ply:SetNWBool("IsPlayerFullyLoaded", not cmd:IsForced())
        if cmd:IsForced() then return end
        hook.Remove( "SetupMove", self )
        hook.Run( "PlayerFullyLoaded", self )
    end )
end )
