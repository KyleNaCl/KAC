
print("[KAC] \tLoaded cl_kac.lua")

local White = Color(255,255,255)
local Settings = {
    KACCol = White,
    TextSep = Color(200,200,200),
    TextCol = White
}
local Hints = {}

local _IsValid = IsValid
local _TableRemove = table.remove
local _TableInsert = table.insert
local _TimerCreate = timer.Create
local _TimerStart = timer.Start
local _TimerPause = timer.Pause
local _HookAdd = hook.Add
local _unpack = unpack
local _NetReceive = net.Receive
local _Start = net.Start
local _ReadInt = net.ReadInt
local _ReadUInt = net.ReadUInt
local _ReadString = net.ReadString
local _ReadColor = net.ReadColor
local _WriteBool = net.WriteBool
local _WriteString = net.WriteString
local _WriteUInt = net.WriteUInt
local _SendToServer = net.SendToServer
local _LocalPlayer = LocalPlayer

_NetReceive("KAC_Settings",function()
    print("[KAC] \tRecieved Settings From Server")

    Settings.KACCol = _ReadColor()
    Settings.TextSep = _ReadColor()
    Settings.TextCol = _ReadColor()
end)

_NetReceive("KAC_Client",function()
    if _IsValid(_LocalPlayer()) then
        local name = _LocalPlayer():Name()
        local Text = { Settings.TextSep,"[",Settings.KACCol,"KAC",Settings.TextSep,"] "}
        for a = 1, _ReadUInt(4), 2 do
            _TableInsert(Text, _ReadColor())
            local te = _ReadString()
            if te == name then te = "You" end
            _TableInsert(Text, te)
        end
        chat.AddText(_unpack(Text))
    end
end)

_NetReceive("KAC_Join", function()
    if _IsValid(_LocalPlayer()) then
        local name = _ReadString()
        local steamid = _ReadString()
        local id = _ReadUInt(2)
        if id == 1 then
            chat.AddText(Color(255,255,75,255),"[JOIN] ",White,name .. " (",Color(0,161,255),steamid,White,")")
        elseif id == 2 then
            chat.AddText(Color(75,255,75,255),"[LOAD] ",White,name .. " (",Color(0,161,255),steamid,White,")")
        elseif id == 3 then
            local reason = _ReadString()
            chat.AddText(Color(255,75,75,255),"[LEFT] ",White,name .. " (",Color(0,161,255),steamid,White,") " .. reason)
        end
    end
end)

_NetReceive("KAC_Punishment",function()
    if _IsValid(_LocalPlayer()) then
        _TableInsert(Hints, {
            target = _ReadString(),
            color = _ReadColor(),
            alert = _ReadString(),
            count = _ReadInt(5),
            max = _ReadInt(5),
            cooldown = 25
        })
        _TimerStart("KAC_Timer")
    end
end)

_NetReceive("KAC_Spray",function()
    _Start("KAC_Spray")
        _WriteUInt(_ReadUInt(8),8)
        _WriteString(_LocalPlayer():GetPlayerInfo().customfiles[1])
    _SendToServer()
end)

_HookAdd("HUDPaint", "KAC_HUD", function()
    if _IsValid(_LocalPlayer()) then
        local scr_w, scr_h = ScrW(), ScrH()
        if #Hints > 0 then
            if Hints[1].cooldown > 0 then
                local Dim = {
                    x = scr_w * 0.7,
                    y = 35,
                    w = 300,
                    h = 80
                }
                surface.SetDrawColor(Color(0,0,0,175))
                surface.DrawRect(Dim.x, Dim.y, Dim.w, Dim.h)
                surface.SetDrawColor(Color(55,55,55,175))
                surface.DrawRect(Dim.x, Dim.y, Dim.w, Dim.h * 0.3)
                draw.SimpleText(Hints[1].target, "Trebuchet24", Dim.x + 10, Dim.y, Hints[1].color)
                surface.SetDrawColor(55,55,55,225)
                surface.DrawPoly({
                    { x = Dim.x + 5, y = Dim.y + Dim.h * 0.3 + 14},
                    { x = Dim.x + 10, y = Dim.y + Dim.h * 0.3 + 4},
                    { x = Dim.x + 30, y = Dim.y + Dim.h * 0.3 + 4},
                    { x = Dim.x + 35, y = Dim.y + Dim.h * 0.3 + 14},
                    { x = Dim.x + 30, y = Dim.y + Dim.h * 0.3 + 24},
                    { x = Dim.x + 10, y = Dim.y + Dim.h * 0.3 + 24},
                })
                draw.SimpleText(tostring(Hints[1].cooldown), "CenterPrintText", Dim.x + 20, Dim.y + Dim.h * 0.3 + 5,Color(255,255,255),TEXT_ALIGN_CENTER)
                draw.SimpleText("Intentional " .. Hints[1].alert .. "?", "Trebuchet24", Dim.x + 40, Dim.y + Dim.h * 0.3 + 2)
                draw.SimpleText("[F7] Yes   [F8] No ", "Trebuchet24", Dim.x + Dim.w - 4, Dim.y + Dim.h * 0.3 + 24, Color(255,255,255), TEXT_ALIGN_RIGHT)
                surface.SetDrawColor(255,20,20,175)
                surface.DrawPoly({
                    { x = Dim.x + Dim.w - 50, y = Dim.y + Dim.h * 0.15},
                    { x = Dim.x + Dim.w - 55, y = Dim.y},
                    { x = Dim.x + Dim.w, y = Dim.y},
                    { x = Dim.x + Dim.w, y = Dim.y + Dim.h * 0.3},
                    { x = Dim.x + Dim.w - 55, y = Dim.y + Dim.h * 0.3},
                })
                draw.SimpleText(Hints[1].count .. "/" .. Hints[1].max, "Trebuchet24", Dim.x + Dim.w - 5, Dim.y, Color(255,255,255), TEXT_ALIGN_RIGHT)
            end
        end
    end
end)

_TimerCreate("KAC_Timer", 1, 0, function()
    if #Hints > 0 then
        if Hints[1].cooldown > 0 then
            Hints[1].cooldown = Hints[1].cooldown - 1
            if Hints[1].cooldown <= 0 then
                _Start("KAC_Punishment")
                    _WriteBool(false)
                _SendToServer()
                _TableRemove(Hints,1)
            end
        end
    else
        _TimerPause("KAC_Timer")
    end
end)

_HookAdd("PlayerButtonDown", "KAC_Button", function(ply, button)
    if ply == _LocalPlayer() then
        if #Hints > 0 then 
            if button == 98 then
                _Start("KAC_Punishment")
                    _WriteBool(true)
                _SendToServer()
                _TableRemove(Hints,1)
            elseif button == 99 then
                _Start("KAC_Punishment")
                    _WriteBool(false)
                _SendToServer()
                _TableRemove(Hints,1)
            end
        end
    end
end)

_HookAdd("OnContextMenuClose", "KAC_CC", function()
    _LocalPlayer():SetNWBool("KAC_ContextMenu", false)
end)

_HookAdd("OnContextMenuOpen", "KAC_CO", function()
    _LocalPlayer():SetNWBool("KAC_ContextMenu", true)
end)

local function kac_print(...)
    MsgC(Settings.TextSep,"[",Settings.KACCol,"KAC",Settings.TextSep,"] ")
    MsgC(...)
    MsgC(White,"\n")
end

local function getDomain(url)
    local protocol = string.match(url,"^(%w-)://")
    if not protocol then
        url = "http://"..url
    end

    local protocol,domain,path = string.match(url,"^(%w-)://([^/]*)/?(.*)")
    if not domain then return false end
    return domain
end

KAC_HTTP = KAC_HTTP or HTTP
function HTTP(tab)
    local domain = getDomain(tab.url)
    local _file = string.GetFileFromFilename(tab.url)
    kac_print(Color(255,255,50),"HTTP",White,"() Requested[",Color(255,150,0),tab.method,White,"] ",Color(50,255,50),domain,White," | ",Color(255,255,50),_file)
    return KAC_HTTP(tab)
end

KAC_Fetch = KAC_Fetch or http.Fetch
function http.Fetch(url, onSuccess, onFailure, headers)
    local domain = getDomain(url)
    local _file = string.GetFileFromFilename(url)
    kac_print(Color(255,255,50),"http.Fetch",White,"() ",Color(50,255,50),domain,White," | ",Color(255,255,50),_file)
    return KAC_Fetch(url, onSuccess, onFailure, headers)
end

KAC_Post = KAC_Post or http.Post
function http.Post(url, parameters, onSuccess, onFailure, headers)
    local domain = getDomain(url)
    kac_print(Color(255,255,50),"http.Post",White,"() size[",Color(50,255,50),tostring(table.Count(parameters)),White,"] ",Color(50,255,50),domain)
    return KAC_Post(url, parameters, onSuccess, onFailure, headers)
end

KAC_Sound = KAC_Sound or sound.PlayURL
function sound.PlayURL(url, flags, callback)
    local domain = getDomain(url)
    local _file = string.GetFileFromFilename(url)
    kac_print(Color(255,255,50),"sound.PlayURL",White,"() ",Color(50,255,50),domain,White," | ",Color(255,255,50),_file)
    return KAC_Sound(url, flags, callback)
end

local _ply = FindMetaTable("Player")
function _ply.GetObserverTarget()
    --kac_print(Color(255,255,50),"Player:GetObserverTarget",White,"() | ",Color(255,255,50),debug.traceback())
    return nil
end

KAC_FilterText = KAC_FilterText or util.FilterText
function util.FilterText(str, context, ply)
    if context == nil or context == TEXT_FILTER_CHAT then
        context = TEXT_FILTER_GAME_CONTENT
    end
    return KAC_FilterText(str, context, ply)
end
