E2Lib.RegisterExtension("streamcore_kac", true)

CreateConVar("streamcore_antispam_seconds",5,FCVAR_SERVER_CAN_EXECUTE)
CreateConVar("streamcore_antispam_ignoreadmins",1,FCVAR_SERVER_CAN_EXECUTE)
CreateConVar("streamcore_adminonly",0,FCVAR_SERVER_CAN_EXECUTE)
CreateConVar("streamcore_maxradius",120,FCVAR_SERVER_CAN_EXECUTE)

util.AddNetworkString("XTS_SC_StreamStart")
util.AddNetworkString("XTS_SC_StreamStop")
util.AddNetworkString("XTS_SC_StreamVolume")
util.AddNetworkString("XTS_SC_StreamRadius")

-----GURL + Starfall URL Whitelist-----

URL_Whitelist = {}

local function isWhitelisted(url)
    for _,v in ipairs(URL_Whitelist) do
        if string.match(url,v) then
            return true
        end
    end
    return false
end

local function checkURL(url)
    if TypeID(url) != TYPE_STRING then return false end
    local protocol = string.match(url,"^(%w-)://")
    if not protocol then
        url = "http://"..url
    end

    local protocol,domain,path = string.match(url,"^(%w-)://([^/]*)/?(.*)")
    if not domain then return false end
    domain = domain.."/"..(data or "")
    return isWhitelisted(domain)
end

local function pattern(txt)
    table.insert(URL_Whitelist,"^"..txt.."$")
end

local function simple(txt)
    table.insert(URL_Whitelist,"^"..string.PatternSafe(txt).."/.*")
end

simple [[dl.dropboxusercontent.com]]
pattern [[%w+%.dl%.dropboxusercontent%.com/(.+)]]
simple [[www.dropbox.com]]
simple [[dl.dropbox.com]]
simple [[translate.google.com]]

simple [[onedrive.live.com/redir]]

simple [[raw.githubusercontent.com]]
simple [[gist.githubusercontent.com]]

simple [[steamcdn-a.akamaihd.net]]

pattern [[cdn[%w-_]*.discordapp%.com/(.+)]]

pattern [[(%w+)%.sndcdn%.com/(.+)]]

-----Stream Core-----

local streams = {}
local antispam = {}
local antispam_volume = {}
local antispam_radius = {}
local antispam_stop = {}

local function fixURL(str)
	local url = string.Trim(str)
	if string.len(url) < 5 then return end
	if string.sub(url, 1, 4) != "http" then
		url = "http://"..url
	end
	return url
end

local function streamCanStart(ply)
	local admin = ply:IsAdmin()
	local only = GetConVarNumber("streamcore_adminonly")
	local ignore = GetConVarNumber("streamcore_antispam_ignoreadmins")
	local access = ply.SC_Access_Override or false
	local nospam = ply.SC_Antispam_Ignore or false
	if (only > 0) and not (admin or access) then return false end
	if (ignore > 0) and (admin or nospam) then return true end
	local last = antispam[ply:EntIndex()] or 0
	if last > CurTime() then return false end
	return true
end

local function streamStart(from, ent, id, volume, str, no3d)
	if not IsValid(from) then return end
	if not IsValid(ent) then return end
	if not E2Lib.isOwner(from, ent) then return end
	
	local owner = E2Lib.getOwner(from, ent)
	if not streamCanStart(owner) then return end

	local secs = GetConVarNumber("streamcore_antispam_seconds")
	antispam[owner:EntIndex()] = CurTime() + secs
	antispam_radius[owner:EntIndex()] = CurTime() + 1
	antispam_volume[owner:EntIndex()] = CurTime() + 1
	antispam_stop[owner:EntIndex()] = CurTime() + 1
	
	local index = from:EntIndex().."-"..id
	local url = fixURL(str) or "nope"
	if url == "nope" then return end

	if not checkURL(url) then KAC.printClient(owner:UserID(), -1, "Info E2# \"" .. url .. "\" is not a whitelisted domain", true) return end

    local Ex = string.Explode("/", url)
    local short_url = Ex[#Ex]

	local radius = GetConVarNumber("streamcore_maxradius")

	volume = math.Clamp(volume, 0, 1)
	streams[index] = {url, volume, radius}

	if GAS and GAS.Logging then
		hook.Run("KAC_Log_Wiremod","[StreamCore] {1} playing {2} from {3} on {4}",{GAS.Logging:FormatPlayer(owner),GAS.Logging:Highlight(short_url),GAS.Logging:Highlight(from.name),GAS.Logging:Highlight(tostring(ent))})
	end

	net.Start("XTS_SC_StreamStart")
		net.WriteString(index)
		net.WriteFloat(volume)
		net.WriteString(url)
		net.WriteEntity(ent)
		net.WriteEntity(from)
		net.WriteEntity(owner)
		net.WriteBool(no3d)
		net.WriteFloat(radius)
	net.Broadcast()
end

__e2setcost(1)
e2function void streamDisable3D(disable)
	self.data = self.data or {}
	self.data.no3d = (disable != 0)
end

__e2setcost(2)

e2function number streamLimit()
	return GetConVarNumber("streamcore_antispam_seconds")
end

e2function number streamMaxRadius()
	return GetConVarNumber("streamcore_maxradius")
end

e2function number streamAdminOnly()
	return math.Clamp(GetConVarNumber("streamcore_adminonly"), 0, 1)
end

__e2setcost(50)
e2function void entity:streamStart(id, volume, string url)
	streamStart(self.entity, this, id, volume, url, self.data.no3d)
end

e2function void entity:streamStart(id, string url, volume)
	streamStart(self.entity, this, id, volume, url, self.data.no3d)
end

e2function void entity:streamStart(id, string url)
	streamStart(self.entity, this, id, 1, url, self.data.no3d)
end

__e2setcost(10)
e2function number streamCanStart()
	return streamCanStart(self.player) and 1 or 0
end

e2function void streamStop(id)
	local index = self.entity:EntIndex().."-"..id
	if streams[index] then
		if antispam_stop[self.player:EntIndex()] > CurTime() then return end
		antispam_stop[self.player:EntIndex()] = CurTime() + 0.5
		net.Start("XTS_SC_StreamStop")
			net.WriteString(index)
		net.Broadcast()
		streams[index] = nil
	end
end

__e2setcost(25)
e2function void streamVolume(id, volume)
	local index = self.entity:EntIndex().."-"..id
	volume = math.Clamp(volume, 0, 1)

	local streamtbl = streams[index]
	if not streamtbl then return end

	if volume != streamtbl[2] then
		if antispam_volume[self.player:EntIndex()] > CurTime() then return end
		antispam_volume[self.player:EntIndex()] = CurTime() + 0.5
		streams[index][2] = volume
		net.Start("XTS_SC_StreamVolume")
			net.WriteString(index)
			net.WriteFloat(volume)
		net.Broadcast()
	end
end

e2function void streamRadius(id, radius)
	local index = self.entity:EntIndex().."-"..id

	local maxradius = GetConVarNumber("streamcore_maxradius")
	radius = math.Clamp(radius, 0, maxradius)

	local streamtbl = streams[index]
	if not streamtbl then return end

	if radius != streamtbl[3] then
		if antispam_radius[self.player:EntIndex()] > CurTime() then return end
		antispam_radius[self.player:EntIndex()] = CurTime() + 0.5
		streams[index][3] = radius
		net.Start("XTS_SC_StreamRadius")
			net.WriteString(index)
			net.WriteFloat(radius)
		net.Broadcast()
	end
end



