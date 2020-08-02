
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

timer.Simple(2,function() -- Wait for WireLib to be mounted

    if not FindMetaTable("Player").isBuild then

        local Killfeed = {}

        local function push(Str,Team1,Team2)
            local S = string.Explode("%KAC%", Str)
            table.insert(Killfeed,table.Count(Killfeed) + 1,{
                A = S[1],
                T1 = Team1,
                W = "[" .. S[2] .. "]",
                B = S[3],
                T2 = Team2,
                State = 1,
                Life = 60,
                X = 0
            })
        end
        local function remove()
            table.remove(Killfeed,1)
        end

        net.Receive("KAC_Killfeed",function()
            local Str = net.ReadString()
            local E1 = net.ReadEntity()
            local E2 = net.ReadEntity()
            local T1 = 1001
            local T2 = 1001
            if E1:IsPlayer() then T1 = E1:Team() end
            if E2:IsPlayer() then T2 = E2:Team() end
            push(Str,T1,T2)
        end)

        hook.Add("DrawDeathNotice", "KAC_HideOldKillfeed", function(x,y)
            return false
        end)

        local FHeight = draw.GetFontHeight("ChatFont")
        local FWidth = FHeight * 0.55
        local StartY = ScrH() - 200

        local function gWidth(str)
            return string.len(str) * FWidth
        end

        hook.Add("HUDPaint", "KAC_Killfeed_Draw", function()
            if Killfeed then
                for k, tab in pairs(Killfeed) do
                    if tab != nil then
                        local Offset = (string.len(tab["B"]) * FWidth) + 50
                        draw.SimpleTextOutlined(tab["A"], "ChatFont", ScrW() + 250 - (tab["X"] + 20 + gWidth(tab["W"]) + gWidth(tab["B"])), StartY - FHeight * k, team.GetColor(tab["T1"]), TEXT_ALIGN_RIGHT, TEXT_ALIGN_RIGHT, 0.75, Color(0,0,0,150))
                        draw.SimpleTextOutlined(tab["W"], "ChatFont", ScrW() + 250 - (tab["X"] + 10 + gWidth(tab["B"])), StartY - FHeight * k, Color(240,240,240,255), TEXT_ALIGN_RIGHT, TEXT_ALIGN_RIGHT, 0.75, Color(0,0,0,150))
                        draw.SimpleTextOutlined(tab["B"], "ChatFont", ScrW() + 250 - (tab["X"]), StartY - FHeight * k, team.GetColor(tab["T2"]), TEXT_ALIGN_RIGHT, TEXT_ALIGN_RIGHT, 0.75, Color(0,0,0,150))
                        if tab["State"] == 1 then
                            if tab["X"] < 300 then tab["X"] = tab["X"] + 20 end
                            if tab["X"] >= 300 then tab["X"] = 300 tab["State"] = 2 end
                        elseif tab["State"] == 2 then
                            tab["Life"] = tab["Life"] - 0.1
                            if tab["Life"] <= 1 then tab["Life"] = 1 tab["State"] = 3 end
                        elseif tab["State"] == 3 then
                            tab["X"] = tab["X"] - 15
                            if tab["X"] <= -400 then tab["State"] = 4 remove() end
                        end
                    end
                end
            end
        end)
    end

end
