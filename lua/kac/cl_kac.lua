
print("[KAC] \tLoaded cl_kac.lua")

local Settings = {
    KACCol = Color(255,255,255),
    TextSep = Color(200,200,200),
    TextCol = Color(255,255,255)
}

net.Receive("KAC_Settings",function()
    print("[KAC] \tRecieved Settings From Server")

    Settings.KACCol = net.ReadColor()
    Settings.TextSep = net.ReadColor()
    Settings.TextCol = net.ReadColor()

end)

net.Receive("KAC_Client",function()

    if IsValid(LocalPlayer()) then
        local Str = string.Explode("^", net.ReadString())
        local TargetID = tonumber(Str[1])
        local VictimID = tonumber(Str[2])
        local Message = Str[3]

        if TargetID > 0 then 
            local ply = Player(TargetID)
            if IsValid(ply) then
                local name = ply:Name()
                if ply == LocalPlayer() then name = "You" end
                if VictimID > 0 then 
                    local vic = Player(VictimID)
                    if IsValid(vic) then
                        local vicname = vic:Name()
                        if vic == LocalPlayer() then vicname = "You" end
                        if not string.find(Message, "#") then Message = Message .. "#" end
                        local StrS = string.Explode("#",Message)
                        chat.AddText(Settings.TextSep,"[",Settings.KACCol,"KAC",Settings.TextSep,"]",Settings.TextCol," ",team.GetColor(ply:Team()),name,Settings.TextCol," " .. StrS[1] .. " ",team.GetColor(vic:Team()),vicname,Settings.TextCol," " .. StrS[2])
                    end
                else 
                    if string.find(Message, "##") then
                        local A = string.Explode("##", Message)
                        chat.AddText(Settings.TextSep,"[",Settings.KACCol,"KAC",Settings.TextSep,"]",Settings.TextCol," ",team.GetColor(ply:Team()),name,Settings.TextCol," ",Color(100,100,255),A[1],Settings.TextCol,A[2])
                    elseif string.find(Message, "#") then
                        local A = string.Explode("#", Message)
                        chat.AddText(Settings.TextSep,"[",Settings.KACCol,"KAC",Settings.TextSep,"]",Settings.TextCol," ",team.GetColor(ply:Team()),name,Settings.TextCol," ",Color(255,100,100),A[1],Settings.TextCol,A[2])
                    else
                        chat.AddText(Settings.TextSep,"[",Settings.KACCol,"KAC",Settings.TextSep,"]",Settings.TextCol," ",team.GetColor(ply:Team()),name,Settings.TextCol," " .. Message)
                    end
                end
            else
                LocalPlayer():PrintMessage(HUD_PRINTCONSOLE, "[KAC] Error: ply not found: " .. Message)
            end
        else
            if VictimID > 0 then 
                local vic = Player(VictimID)
                if vic then
                    local vicname = vic:Name()
                    if vic == LocalPlayer() then vicname = "You" end
                    local StrS = string.Explode("#",Message)
                    chat.AddText(Settings.TextSep,"[",Settings.KACCol,"KAC",Settings.TextSep,"] ",Settings.TextCol,"Unknown Player " .. StrS[1] .. " ",team.GetColor(vic:Team()),vicname,Settings.TextCol," " .. StrS[2])
                end
            else
                chat.AddText(Settings.TextSep,"[",Settings.KACCol,"KAC",Settings.TextSep,"] ",Settings.TextCol,Message)
            end
        end
    end
end)
