
print("[KAC] \tLoaded cl_kac.lua")

net.Receive("KAC_Client",function()

    local Str = string.Explode("^", net.ReadString())
    local TargetID = tonumber(Str[1])
    local VictimID = tonumber(Str[2])
    local Message = Str[3]

    local KACCol = Color(100,100,255)
    local TextSep = Color(200,200,200)
    local TextCol = Color(255,255,255)

    if TargetID > 0 then 
        local ply = Player(TargetID)
        if ply then
            local name = ply:Name()
            if ply == LocalPlayer() then name = "You" end
            if VictimID > 0 then 
                local vic = Player(VictimID)
                if vic then
                    local vicname = vic:Name()
                    if vic == LocalPlayer() then vicname = "You" end
                    if not string.find(Message, "#") then Message = Message .. "#" end
                    local StrS = string.Explode("#",Message)
                    chat.AddText(TextSep,"[",KACCol,"KAC",TextSep,"]",TextCol," ",team.GetColor(ply:Team()),name,TextCol," " .. StrS[1] .. " ",team.GetColor(vic:Team()),vicname,TextCol," " .. StrS[2])

                end
            else 
                if string.find(Message, "#") then
                    local A = string.Explode("#", Message)
                    chat.AddText(TextSep,"[",KACCol,"KAC",TextSep,"]",TextCol," ",team.GetColor(ply:Team()),name,TextCol," ",Color(255,100,100),A[1],TextCol,A[2])
                else
                    chat.AddText(TextSep,"[",KACCol,"KAC",TextSep,"]",TextCol," ",team.GetColor(ply:Team()),name,TextCol," " .. Message)
                end
            end
        end
    else
        if VictimID > 0 then 
            local vic = Player(VictimID)
            if vic then
                local vicname = vic:Name()
                if vic == LocalPlayer() then vicname = "You" end
                local StrS = string.Explode("#",Message)
                chat.AddText(TextSep,"[",KACCol,"KAC",TextSep,"] ",TextCol,"Unknown Player " .. StrS[1] .. " ",team.GetColor(vic:Team()),vicname,TextCol," " .. StrS[2])
            end
        else
            chat.AddText(TextSep,"[",KACCol,"KAC",TextSep,"] ",TextCol,Message)
        end
    end
end)

local Display = {}

net.Receive("KAC_Debug_Print",function()
    table.insert(Display, 1, {time = 50, vector = net.ReadVector()})
end)

hook.Add("PostDrawTranslucentRenderables", "KAC_Debug", function(ply)
    if Display != nil then
        for k, tab in pairs(Display) do
            if tab.time > 0 then
                if k % 2 == 0 then
                    render.DrawWireframeBox(tab.vector, Angle(), Vector(-5,-5,-5), Vector(5,5,5), {color = Color(50,255,50)})
                else
                    render.DrawWireframeBox(tab.vector, Angle(), Vector(-2,-2,-2), Vector(2,2,2), {color = Color(50,255,50)})
                end
                tab.time = tab.time - engine.TickInterval()
            else
                table.remove(Display, k)
            end
        end
    end
end)
