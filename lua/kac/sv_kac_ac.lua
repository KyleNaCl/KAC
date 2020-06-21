
print("[KAC] \tLoaded sv_kac_ac.lua")

local BHopMaxCVAR = CreateConVar("sv_kac_bhop_max", 10, 128, "max amount of triggers until autoban for bhop scripts", 1 , 30)
local BHopNotifyIntervalCVAR = CreateConVar("sv_kac_bhop_notify_interval", 3, 128, "amount of triggers until staff get a notify", 1 , 10)
local SilentIntervalCVAR = CreateConVar("sv_kac_silent_interval", 4, 128, "amount of engine ticks to consider silent aim", 0 , 10)

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

local function subT(Num1, Num2)
    if Num1 < Num2 then
        if Num1 + 180 < Num2 then
            return (Num1 + 180) + ((Num2 - 180) * -1)
        end
    else
        if Num2 + 180 < Num1 then
            return (Num2 + 180) + ((Num1 - 180) * -1)
        end
    end
    return Num1 - Num2
end

hook.Add("OnPlayerHitGround", "KAC_Ground", function(ply, inWater, onFloater, speed)
    local steamC = KAC.checkData(ply)
    if not ply or not ply:Alive() or inWater or onFloater then return end

    local isJump = KAC[steamC].button.jump
    if isJump == 1 then
        timer.Simple(0, function() 
            local vel = ply:GetVelocity()
            if vel[3] <= 0 or KAC[steamC].button.jump == -1 then return end

            KAC.print2("[KAC] Info: " .. ply:Name() .. "<" .. ply:SteamID() .. "> bhop detected [x " .. math.Round(vel[1]) .. ", y " .. math.Round(vel[2]) .."]")
            KAC[steamC].bhop = KAC[steamC].bhop + 1

            if KAC[steamC].bhop >= BHopMaxCVAR:GetInt() then
                KAC.print2("[KAC] Info: " .. ply:Name() .. "<" .. ply:SteamID() .. "> banning for bhop scripts [" .. KAC[steamC].bhop .. "]")
                KAC.printClient(ply:UserID(), -3, "Anti-Cheat# BHOP Scripts")
                ply:Lock()
                KAC[steamC].bhop = 0
                timer.Simple(1, function() 
                    RunConsoleCommand("ulx", "ban", ply:Nick(), 0, "BHOP Scripts [Banned By: KAC]")
                end)
            else
                if KAC[steamC].bhop % BHopNotifyIntervalCVAR:GetInt() == 0 then
                    KAC.printClient(ply:UserID(), -1, "Anti-Cheat# Detected BHop Scripts")
                end
            end
        end)
    end
end)

hook.Add("Tick","KAC_Tick",function()
    for k, ply in pairs(player.GetAll()) do
        local steamC = KAC.checkData(ply)
        if steamC then
            KAC[steamC].eyea = ply:EyeAngles()
            if KAC[steamC].button["attack"] == 1 then
                KAC[steamC].button["attackpre"] = CurTime()
            end
        end
    end
end)

hook.Add("EntityTakeDamage", "KAC_Damage", function(ent, dmg)
    local ply = dmg:GetAttacker()

    if ply:Health() > 0 and ply:IsPlayer() and dmg:IsBulletDamage() then
        local steamC = KAC.checkData(ply)

        if steamC then
            local infl = dmg:GetInflictor()
            if infl:IsPlayer() then
                infl = infl:GetActiveWeapon()
                if infl:IsWeapon() then
                    if KAC[steamC].button["attack"] == -1 and CurTime() - KAC[steamC].button["attackpre"] > engine.TickInterval() * 10 then
                        KAC.printClient(ply:UserID(), -1, "Anti-Cheat# Auto Shoot Detected")
                    end
                end
            end

            local PAng = KAC[steamC].eyea

            local P = math.abs(math.Round(subT(ply:EyeAngles().p,PAng.p),2))
            local Y = math.abs(math.Round(subT(ply:EyeAngles().y,PAng.y),2))

            local Range = 5000 / (dmg:GetDamagePosition():Distance(ply:GetShootPos()))

            if P > Range or Y > Range then
                timer.Simple(engine.TickInterval() * SilentIntervalCVAR:GetInt(),function()
                    local P2 = math.abs(math.Round(subT(ply:EyeAngles().p,PAng.p),2))
                    local Y2 = math.abs(math.Round(subT(ply:EyeAngles().y,PAng.y),2))

                    if P2 < 1 and Y2 < 1 then
                        KAC.print2("[KAC] Info: Silent Aim Detected")
                        KAC.printClient(ply:UserID(), -1, "Anti-Cheat# Silent Aim Detected")
                    end
                end)
                KAC.printClient(ply:UserID(), -1, "Anti-Cheat# Snap Detected p[" .. P .. "] y[" .. Y .. "]")
            end
        end
    end
end)
