
print("[KAC] \tLoaded sv_kac_ac.lua")

KACTriggers = {
    aimbot = {
        threshold = 10,
        delta = 0.005,
        desc = "Aimbot"
    },
    bhop = {
        threshold = 5,
        delta = 0.005,
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
        if KACTriggers == nil then return end
        if KACTriggers[type_] == nil then return end
        if KACTriggers[type_][steamC] == nil then return end
        if KACTriggers[type_][steamC] > 0 then 
            KACTriggers[type_][steamC] = KACTriggers[type_][steamC] - KACTriggers[type_]["delta"]
            if KACTriggers[type_][steamC] <= 0 then 
                KACTriggers[type_][steamC] = 0
                if KACTriggers[type_].threshold != -1 then
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
        if not FindMetaTable("Player").isBuild then
            weapon = ply:GetActiveWeapon()
            if IsValid(weapon) then

                local maxClip = weapon:GetMaxClip1()
                local primAmmoType = weapon:GetPrimaryAmmoType()

                if maxClip == -1 then
                    maxClip = 100
                end

                if maxClip <= 0 and primAmmoType ~= -1 then
                    maxClip = 1
                end

                if primAmmoType ~= -1 then
                    ply:SetAmmo( maxClip, primAmmoType, true)
                end
            end
        end
    end
end
timer.Create("KAC_TriggerDelta", 1, 0, loopDelta)

local function pushTrigger(ply, type_, amount)
    local steamC = KAC.checkData(ply)
    if steamC then
        if KACTriggers[type_][steamC] == nil then KACTriggers[type_][steamC] = 0 end
        if KACTriggers[type_].threshold == -1 then
            KACTriggers[type_][steamC] = amount
        else
            KACTriggers[type_][steamC] = KACTriggers[type_][steamC] + amount
            if KACTriggers[type_][steamC] >= KACTriggers[type_].threshold then
                KAC.print2("[KAC] Info: " .. ply:Name() .. "<" .. ply:SteamID() .. "> banning for " .. KACTriggers[type_].desc)
                KAC.printClient(ply:UserID(), -3, "Anti-Cheat# Banned For " .. KACTriggers[type_].desc)
                KACTriggers[type_][steamC] = 0
                if not ply:IsListenServerHost() then
                    ply:Lock()
                    timer.Simple(1, function() 
                        RunConsoleCommand("ulx", "ban", ply:Nick(), 0, KACTriggers[type_].desc .. " [Banned By: KAC]")
                    end)
                end
            else
                KAC.print2("[KAC] Info: " .. ply:Name() .. "<" .. ply:SteamID() .. "> " .. type_ .. " [" .. KACTriggers[type_][steamC] .. " / " .. KACTriggers[type_].threshold .. "]")
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

hook.Add("EntityFireBullets", "KAC_Bullet", function(ent, dataTab)
    local ply = dataTab["Attacker"]
    local steamC = KAC.checkData(ply)
    if KAC[steamC] and ply:Alive() then
        if KAC[steamC].button["attack"] == 0 and ply:GetActiveWeapon():GetClass() != "weapon_shotgun" then
            pushTrigger(ply, "autoshoot", 3)
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
                if KAC[steamC].button["attack"] == -1 and KACTriggers["autoshoot"][steamC] == 0 then
                    KAC.printClient(ply:UserID(), -1, "Anti-Cheat# Detected Autoshoot")
                    pushTrigger(ply, "aimbot", 1)
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
        local Ang = Dir:Angle()

        if Dist > 20 then
            local Range = math.Clamp(H / (Dist / 200),1.5,180)
            
            local BTrace = util.TraceLine({start = End + (Dir * -10), endpos = End + (Dir * 10), filter = ply, ignoreworld = true})

            KAC[steamC].hitshot = KAC[steamC].hitshot + 1
            if BTrace.HitGroup == HITGROUP_HEAD then
                KAC[steamC].headshot = KAC[steamC].headshot + 1
            end

            if P > Range or Y > Range then

                local Clamp = math.Clamp(math.floor((math.max(P,Y) + (Dist / 80)) / 25), 0, 4)
                local Text = "Low"
                if Clamp == 0 then Clamp = 1 end
                if Clamp == 2 then Text = "Medium" end
                if Clamp == 3 then Text = "High" end
                if Clamp == 4 then Text = "Severe" end

                timer.Simple(0,function()
                    local TimerPAng = ply:EyeAngles()
                    local PC = math.abs(subT(TimerPAng.p,Ang.p)) < 1.5
                    local YC = math.abs(subT(TimerPAng.y,Ang.y)) < 1.5

                    if PC and YC then
                        KAC.printClient(ply:UserID(), -1, "Anti-Cheat# Detected Snap Severity: " .. Text)
                        pushTrigger(ply, "aimbot", Clamp)
                    end
                end)
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

                --print("Range: " .. Range .. " | M: " .. math.max(P,Y) .. " | Div: " .. ((math.max(P,Y) + (Dist / 60)) / 30))
                --KAC.printClient(ply:UserID(), -1, "Anti-Cheat# Snap Detected d[" .. math.Round(Dist * 0.0625) .. "] p[" .. math.Round(P) .. "] y[" .. math.Round(Y) .. "]")
            end
        end
    end
end)
