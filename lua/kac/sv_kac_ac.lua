
print("[KAC] \tLoaded sv_kac_ac.lua")

KAC.Triggers = {
    aimbot = {
        threshold = 10,
        delta = 0.05,
        desc = "Aimbot"
    },
    bhop = {
        threshold = 20,
        delta = 0.05,
        desc = "BHOP Scripts"
    },
    autoshoot = {
        threshold = -1,
        delta = 1,
        desc = "Autoshoot"
    }
}

local function checkType(ply, type_)
    local steamC = KAC.checkData(ply)
    if steamC then
        if not steamC then KAC.print2("[KAC] Error: steamC is null in checkType()") return end
        if not type_ then KAC.print2("[KAC] Error: type_ is null in checkType()") return end
        if KAC.Triggers[type_][steamC] == nil then return end
        if KAC.Triggers[type_][steamC] > 0 then 
            KAC.Triggers[type_][steamC] = KAC.Triggers[type_][steamC] - KAC.Triggers[type_]["delta"]
            if KAC.Triggers[type_][steamC] <= 0 then 
                KAC.Triggers[type_][steamC] = 0
                if KAC.Triggers[type_].threshold != -1 then
                    KAC.print2("[KAC] Info: " .. ply:Name() .. "<" .. ply:SteamID() .. "> " .. type_ .. " delta zero'd")
                end
            end
        end
    end
end

local function loopDelta()
    for k, ply in pairs(player.GetAll()) do
        local steamC = KAC.checkData(ply)
        if steamC then
            checkType(ply,"aimbot")
            checkType(ply,"bhop")
            checkType(ply,"autoshoot")
        end
    end
end
timer.Create("KAC_TriggerDelta", 1, 0, loopDelta)

local function pushTrigger(ply, type_, amount)
    local steamC = KAC.checkData(ply)
    if steamC then
        if KAC.Triggers[type_][steamC] == nil then KAC.Triggers[type_][steamC] = 0 end
        if KAC.Triggers[type_].threshold == -1 then
            KAC.Triggers[type_][steamC] = amount
        else
            KAC.Triggers[type_][steamC] = KAC.Triggers[type_][steamC] + amount
            if KAC.Triggers[type_][steamC] >= KAC.Triggers[type_].threshold then
                KAC.print2("[KAC] Info: " .. ply:Name() .. "<" .. ply:SteamID() .. "> banning for " .. KAC.Triggers[type_].desc)
                KAC.printClient(ply:UserID(), -3, "Anti-Cheat# Banned For " .. KAC.Triggers[type_].desc)
                KAC.Triggers[type_][steamC] = 0
                if not ply:IsListenServerHost() then
                    ply:Lock()
                    timer.Simple(1, function() 
                        RunConsoleCommand("ulx", "ban", ply:Nick(), 0, KAC.Triggers[type_].desc .. " [Banned By: KAC]")
                    end)
                end
            else
                KAC.print2("[KAC] Info: " .. ply:Name() .. "<" .. ply:SteamID() .. "> " .. type_ .. " [" .. KAC.Triggers[type_][steamC] .. " / " .. KAC.Triggers[type_].threshold .. "]")
            end
        end
    end
end

timer.Simple(5,function() -- Wait for WireLib to be mounted

    if WireLib then
        hook.Add("PlayerBindDown", "KAC_BindDown", function(ply, binding, button) -- Wiremod Hook
            if binding then
                local steamC = KAC.checkData(ply)
                if steamC then
                    KAC[steamC].button[binding] = 1
                    if binding == "attack" then
                        pushTrigger(ply, "autoshoot", 5)
                    end
                end
            end
        end)

        hook.Add("PlayerBindUp", "KAC_BindUp", function(ply, binding, button) -- Wiremod Hook
            if binding then
                local steamC = KAC.checkData(ply)
                if steamC then
                    KAC[steamC].button[binding] = -1
                end
            end
        end)
    end

end)

local function subT(A, B)
    Diff = ((A - B) + 180) % 360 - 180
    if Diff < 180 then return Diff end
    return Diff - 360
end

hook.Add("OnPlayerHitGround", "KAC_Ground", function(ply, inWater, onFloater, speed)
    local steamC = KAC.checkData(ply)
    if not ply or inWater or onFloater then return end
    if not ply:Alive() or ply:GetMoveType() == MOVETYPE_NOCLIP or ply:IsTimingOut() then return end

    local isJump = KAC[steamC].button.jump
    if isJump == 1 then
        timer.Simple(0, function()
            if ply:IsOnGround() or not ply:Alive() or ply:IsTimingOut() then return end
            if KAC[steamC].button.jump == -1 or ply:GetMoveType() == MOVETYPE_NOCLIP then return end

            local vel = ply:GetVelocity()
            if math.abs(math.Round(vel[1]) + math.Round(vel[2])) <= 300 or math.Round(vel[3]) < 50 then return end

            //KAC.print2("[KAC] Info: " .. ply:Name() .. "<" .. ply:SteamID() .. "> bhop detected [x " .. math.Round(vel[1]) .. ", y " .. math.Round(vel[2]) .."]")
            KAC.printClient(ply:UserID(), -1, "Anti-Cheat# Detected BHOP Scripts")
            pushTrigger(ply, "bhop", 1)
        end)
    end
end)

hook.Add("Tick","KAC_Tick",function()
    for k, ply in pairs(player.GetAll()) do
        local steamC = KAC.checkData(ply)
        if KAC[steamC] then
            KAC[steamC].eyea = ply:EyeAngles()
        end
    end
end)

hook.Add("EntityTakeDamage", "KAC_Damage", function(ent, dmg)

    if not dmg:IsBulletDamage() then return end
    local ply = dmg:GetAttacker()
    if not IsValid(ply) or not IsValid(ent) then return end
    if not ply:IsPlayer() or not ent:IsPlayer() then return end
    if not ply:Alive() or not ent:Alive() then return end
    if ply:IsTimingOut() or ent:IsTimingOut() then return end
    if ply:InVehicle() or ent:InVehicle() then return end
    if ply:HasGodMode() or ent:HasGodMode() then return end
    if KAC.InBuild(ply) or KAC.InBuild(ent) then return end
    
    local steamC = KAC.checkData(ply)

    if steamC then

        if KAC[steamC].antispam == CurTime() then return end

        KAC[steamC].antispam = CurTime()

        local Min, Max = ent:GetCollisionBounds()
        local H = Max[3] - Min[3]
        local infl = dmg:GetInflictor()
        if infl:IsPlayer() then
            infl = infl:GetActiveWeapon()
            if infl:IsWeapon() then
                if KAC[steamC].button["attack"] == -1 and KAC.Triggers["autoshoot"][steamC] == 0 then
                    KAC.printClient(ply:UserID(), -1, "Anti-Cheat# Detected Autoshoot")
                    //pushTrigger(ply, "aimbot", 1)
                end
            end
        end

        local PAng = KAC[steamC].eyea
        local NewPAng = ply:EyeAngles()

        local P = math.abs(math.Round(subT(PAng.p,NewPAng.p),2))
        local Y = math.abs(math.Round(subT(PAng.y,NewPAng.y),2))

        local Start = ply:GetShootPos()
        local End = dmg:GetDamagePosition()
        local Dist = Start:Distance(End)
        local Dir = (End - Start):GetNormalized()

        if Dist > 150 then
            local Range = math.Clamp(H / (Dist / 200),1.5,180)
            
            local Trace = ply:GetEyeTrace()
            local BTrace = util.TraceLine({start = End + (Dir * -10), endpos = End + (Dir * 10), filter = ply, ignoreworld = true})
            --local WTrace = util.TraceLine({start = Start, endpos = End + (Dir * 10), filter = ply})

            --PrintTable(WTrace)

            --paint(ply, BTrace.HitPos)
            --paint(ply, WTrace.HitPos)

            --if WTrace.HitWorld then
                --ply:ChatPrint("Wallbang World")
            --elseif IsValid(WTrace.Entity) and WTrace.Entity != ent then
                --ply:ChatPrint("Wallbang Prop")
            --end

            KAC[steamC].hitshot = KAC[steamC].hitshot + 1
            if BTrace.HitGroup == HITGROUP_HEAD then
                KAC[steamC].headshot = KAC[steamC].headshot + 1
            end

            if P > Range or Y > Range then

                timer.Simple(engine.TickInterval() * 4,function()
                    local TimerPAng = ply:EyeAngles()

                    local PC = math.abs(math.Round(subT(TimerPAng.p,PAng.p))) < (P / 10)
                    local YC = math.abs(math.Round(subT(TimerPAng.y,PAng.y))) < (Y / 10)

                    if PC and YC then
                        KAC.print2("[KAC] Info: Detected Silent Aim")
                        KAC.printClient(ply:UserID(), -1, "Anti-Cheat# Detected Silent Aim")
                        pushTrigger(ply, "aimbot", 3)
                    end
                end)
                local Clamp = math.Clamp(math.floor((math.max(P,Y) + (Dist / 80)) / 25), 0, 4)
                local Text = "Low"
                if Clamp == 2 then Text = "Medium" end
                if Clamp == 3 then Text = "High" end
                if Clamp == 4 then Text = "Severe" end
                //print("Range: " .. Range .. " | M: " .. math.max(P,Y) .. " | Div: " .. ((math.max(P,Y) + (Dist / 60)) / 30))
                //KAC.printClient(ply:UserID(), -1, "Anti-Cheat# Snap Detected d[" .. math.Round(Dist * 0.0625) .. "] p[" .. math.Round(P) .. "] y[" .. math.Round(Y) .. "]")
                KAC.printClient(ply:UserID(), -1, "Anti-Cheat# Detected Snap Severity: " .. Text)
                pushTrigger(ply, "aimbot", Clamp)
            end
        end
    end
end)
