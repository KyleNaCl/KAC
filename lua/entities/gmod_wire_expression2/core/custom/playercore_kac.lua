
E2Lib.RegisterExtension("playercore_kac", true)

local sbox_E2_PlyCore = CreateConVar("sbox_E2_PlyCore", "2", FCVAR_ARCHIVE)

local function ValidPly(ply)
	if not IsValid(ply) or not ply:IsPlayer() then
		return false
	end

	return true
end

local function hasAccessBypass(ply, target, command)
	local valid = hook.Call("PlyCoreCommand", GAMEMODE, ply, target, command)

	if valid ~= nil then
		return valid
	end

	if sbox_E2_PlyCore:GetInt() == 1 then
		return true
	elseif sbox_E2_PlyCore:GetInt() == 2 then
		if not target then return true end
		if target:IsBot() then return true end
		if ply == target then return true end
		if ply:IsAdmin() then return true end

		if CPPI then
			local friends = target:CPPIGetFriends()
			if istable(friends) then
				for k, v in pairs(friends)  do
					if v == ply then
						return true
					end
				end
			end
		end

		return false
	elseif sbox_E2_PlyCore:GetInt() == 3 then
		if not ply:IsAdmin() then return false end
		return true
	else
		return false
	end

end

local function hasAccess(ply, target, command)
	local access = hasAccessBypass(ply, target, command)
	if access then
	    KAC.UpdateData(ply, false)

		if GAS and GAS.Logging then
			if ply != target then
				hook.Run("KAC_Log_Wiremod","[PlyCore] {1} executed {2} on {3}",{GAS.Logging:FormatPlayer(ply),GAS.Logging:Highlight(command),GAS.Logging:FormatPlayer(target)})
			else
				hook.Run("KAC_Log_Wiremod","[PlyCore] {1} executed {2}",{GAS.Logging:FormatPlayer(ply),GAS.Logging:Highlight(command)})
			end
		end
	end
	return access
end

local function check(v)
	return	-math.huge < v[1] and v[1] < math.huge and
			-math.huge < v[2] and v[2] < math.huge and
			-math.huge < v[3] and v[3] < math.huge
end


-------------------------------------------------------------------------------------------------------------------------------
--Make applyForce on player

e2function void entity:plyApplyForce(vector force)
	if not ValidPly(this) then return nil end
	if not hasAccess(self.player, this, "applyforce") then return nil end

	if check(force) then
		this:SetVelocity(Vector(force[1],force[2],force[3]))
	end
end
--SetPosition

e2function void entity:plySetPos(vector pos)
	if not ValidPly(this) then return nil end
	if not hasAccess(self.player, this, "setpos") then return nil end

	this:SetPos(Vector(math.Clamp(pos[1],-16000,16000), math.Clamp(pos[2],-16000,16000), math.Clamp(pos[3],-16000,16000)))
end

--SetEyeAngles

e2function void entity:plySetAng(angle ang)
	if not ValidPly(this) then return nil end
	if not hasAccess(self.player, this, "setang") then return nil end

	local normalizedAng = Angle(ang[1], ang[2], ang[3])
	normalizedAng:Normalize()
	this:SetEyeAngles(normalizedAng)
end

--Noclip

e2function void entity:plyNoclip(number activate)
	if not ValidPly(this) then return nil end
	if not hasAccess(self.player, this, "noclip") then return nil end

	if activate > 0 then
		this:SetMoveType(MOVETYPE_NOCLIP)
	else
		this:SetMoveType(MOVETYPE_WALK)
	end
end

--Health

e2function void entity:plySetHealth(number health)
	if not ValidPly(this) then return nil end
	if not hasAccess(self.player, this, "sethealth") then return nil end

	this:SetHealth(math.Clamp(health, 0, 2^32/2-1))
end

-- Armor

e2function void entity:plySetArmor(number armor)
	if not ValidPly(this) then return nil end
	if not hasAccess(self.player, this, "setarmor") then return nil end

	this:SetArmor(math.Clamp(armor, 0, 2^32/2-1))
end

-- Mass

e2function void entity:plySetMass(number mass)
	if not ValidPly(this) then return nil end
	if not hasAccess(self.player, this, "setmass") then return nil end

	this:GetPhysicsObject():SetMass(math.Clamp(mass, 1, 50000))
end

e2function number entity:plyGetMass()
	if not ValidPly(this) then return nil end

	return this:GetPhysicsObject():GetMass()
end

--	JumpPower

e2function void entity:plySetJumpPower(number jumpPower)
	if not ValidPly(this) then return nil end
	if not hasAccess(self.player, this, "setjumppower") then return nil end

	this:SetJumpPower(math.Clamp(jumpPower, 0, 2^32/2-1))
end

e2function number entity:plyGetJumpPower()
	if not ValidPly(this) then return nil end

	return this:GetJumpPower()
end

--	Gravity

e2function void entity:plySetGravity(number gravity)
	if not ValidPly(this) then return nil end
	if not hasAccess(self.player, this, "setgravity") then return nil end

	if gravity == 0 then gravity = 1/10^10 end
	this:SetGravity(gravity/600)
end

e2function number entity:plyGetGravity()
	if not ValidPly(this) then return nil end

	return this:GetGravity()*600
end

--	Speed

e2function void entity:plySetSpeed(number speed)
	if not ValidPly(this) then return nil end
	if not hasAccess(self.player, this, "setspeed") then return nil end


	this:SetWalkSpeed(math.Clamp(speed, 1, 10000))
	this:SetRunSpeed(math.Clamp(speed*2, 1, 10000))
end

e2function void entity:plySetRunSpeed(number speed)
	if not ValidPly(this) then return nil end
	if not hasAccess(self.player, this, "setrunspeed") then return nil end

	this:SetRunSpeed(math.Clamp(speed*2, 1, 10000))
end

e2function void entity:plySetWalkSpeed(number speed)
	if not ValidPly(this) then return nil end
	if not hasAccess(self.player, this, "setwalkspeed") then return nil end

	this:SetWalkSpeed(math.Clamp(speed, 1, 10000))
end

e2function number entity:plyGetSpeed()
	if not ValidPly(this) then return nil end

	return this:GetWalkSpeed()
end

e2function void entity:plyResetSettings()
	if not ValidPly(this) then return nil end
	if not hasAccess(self.player, this, "resetsettings") then return nil end

	this:Health(100)
	this:GetPhysicsObject():SetMass(85)
	this:SetJumpPower(200)
	this:SetGravity(1)
	this:SetWalkSpeed(200)
	this:SetRunSpeed(400)
	this:Armor(0)
end

e2function void entity:plyEnterVehicle(entity vehicle)
	if not ValidPly(this) then return nil end
	if not hasAccess(self.player, this, "entervehicle") then return nil end
	if not vehicle or not vehicle:IsValid() or not vehicle:IsVehicle() then return nil end


	if this:InVehicle() then this:ExitVehicle() end

	this:EnterVehicle(vehicle)
end

e2function void entity:plyExitVehicle()
	if not ValidPly(this) then return nil end
	if not hasAccess(self.player, this, "exitvehicle") then return nil end
	if not this:InVehicle() then return nil end

	this:ExitVehicle()
end

e2function void entity:plySpawn()
	if not ValidPly(this) then return nil end
	if not hasAccess(self.player, this, "spawn") then return nil end
	if not this.e2PcLastSpawn then this.e2PcLastSpawn = CurTime()-1 end
	if (CurTime() - this.e2PcLastSpawn) < 1 then return nil end
	this.e2PcLastSpawn = CurTime()

	this:Spawn()
end

-- Freeze

registerCallback("destruct",function(self)
	for _, ply in pairs(player.GetAll()) do
		if ply.plycore_freezeby == self then
			ply:Freeze(false)
		end

		if ply.plycore_noclipdiabledby == self then
			ply:SetNWBool("PlyCore_DisableNoclip", false)
		end
	end
end)

e2function void entity:plyFreeze(number freeze)
	if not ValidPly(this) then return nil end
	if not hasAccess(self.player, this, "freeze") then return nil end

	this.plycore_freezeby = self
	this:Freeze(freeze == 1)
end

e2function number entity:plyIsFrozen()
	if not ValidPly(this) then return nil end

	return this:IsFlagSet(FL_FROZEN)
end

-- DisableNoclip

e2function void entity:plyDisableNoclip(number act)
	if not ValidPly(this) then return nil end
	if not hasAccess(self.player, this, "disablenoclip") then return nil end

	this.plycore_noclipdiabledby = self
	this:SetNWBool("PlyCore_DisableNoclip", act == 1)
end

hook.Add("PlayerNoClip", "PlyCore", function(ply, state)
	if not state then return end

	if ply:GetNWBool("PlyCore_DisableNoclip", false) then
		return false
	end
end)

-- God

e2function void entity:plyGod(number active)
	if not ValidPly(this) then return nil end
	if not hasAccess(self.player, this, "god") then return nil end
	if not active == 1 then active = 0 end

	if active == 1 then
		this:GodEnable()
	else
		this:GodDisable()
	end
end

e2function number entity:plyHasGod()
	if not ValidPly(this) then return nil end

	return this:HasGodMode() and 1 or 0
end

e2function void entity:plyIgnite(time)
	if not ValidPly(this) then return nil end
	if not hasAccess(self.player, this, "ignite") then return nil end

	this:Ignite(math.Clamp(time, 1, 3600))
end

e2function void entity:plyIgnite()
	if not ValidPly(this) then return nil end
	if not hasAccess(self.player, this, "ignite") then return nil end

	this:Ignite(60)
end

e2function void entity:plyExtinguish()
	if not ValidPly(this) then return nil end
	if not hasAccess(self.player, this, "extinguish") then return nil end

	this:Extinguish()
end

e2function string entity:ip()
	if not ValidPly(this) or this:IsBot() then return "" end
	local valid = hook.Call("PlyCoreCommand", GAMEMODE, self.player, nil, "getip")

	if valid == nil then
		valid = self.player:IsAdmin()
	end

	if valid then
		return this:IPAddress()
	end

	return ""
end

-- Message

e2function void sendMessage(string text)
	if not hasAccess(self.player, nil, "globalmessage") then return nil end

	PrintMessage(HUD_PRINTCONSOLE, self.player:Name() .. " send you the next message by an expression 2.")
	PrintMessage(HUD_PRINTTALK, text)
end

e2function void sendMessageCenter(string text)
	if not hasAccess(self.player, nil, "globalmessagecenter") then return nil end

	PrintMessage(HUD_PRINTCONSOLE, text)
	PrintMessage(HUD_PRINTCENTER, text)
end

--

e2function void entity:sendMessage(string text)
	if not ValidPly(this) then return nil end
	if not hasAccess(self.player, this, "message") then return nil end

	this:PrintMessage(HUD_PRINTCONSOLE, self.player:Name() .. " send you the next message by an expression 2.")
	this:PrintMessage(HUD_PRINTTALK, text)
end

e2function void entity:sendMessageCenter(string text)
	if not ValidPly(this) then return nil end
	if not hasAccess(self.player, this, "messagecenter") then return nil end

	this:PrintMessage(HUD_PRINTCONSOLE, self.player:Name() .. " send you the next message by an expression 2.")
	this:PrintMessage(HUD_PRINTCENTER, text)
end

--

e2function void array:sendMessage(string text)
	for _, ply in pairs(this) do
		if not ValidPly(ply) then return nil end
		if not hasAccess(self.player, ply, "message") then return nil end

		ply:PrintMessage(HUD_PRINTCONSOLE, self.player:Name() .. " send you the next message by an expression 2.")
		ply:PrintMessage(HUD_PRINTTALK, text)
	end
end

e2function void array:sendMessageCenter(string text)
	for _, ply in pairs(this) do
		if not ValidPly(ply) then return nil end
		if not hasAccess(self.player, ply, "messagecenter") then return nil end

		ply:PrintMessage(HUD_PRINTCONSOLE, self.player:Name() .. " send you the next message by an expression 2.")
		ply:PrintMessage(HUD_PRINTCENTER, text)
	end
end


util.AddNetworkString("wire_expression2_playercore_sendmessage")

local printColor_typeids = {
	n = tostring,
	s = tostring,
	v = function(v) return Color(v[1],v[2],v[3]) end,
	xv4 = function(v) return Color(v[1],v[2],v[3],v[4]) end,
	e = function(e) return IsValid(e) and e:IsPlayer() and e or "" end,
}

local function printColorVarArg(ply, target, typeids, ...)
	local send_array = { ... }

	for i,tp in ipairs(typeids) do
		if printColor_typeids[tp] then
			send_array[i] = printColor_typeids[tp](send_array[i])
		else
			send_array[i] = ""
		end
	end

	target = isentity(target) and {target} or target
	target = target or player.GetAll()

	local plys = {}
	for _, ply in pairs(target) do
		if ValidPly(ply) then
			table.insert(plys, ply)
		end
	end

	net.Start("wire_expression2_playercore_sendmessage")
		net.WriteEntity(ply)
		net.WriteTable(send_array)
	net.Send(plys)
end

local printColor_types = {
	number = tostring,
	string = tostring,
	Vector = function(v) return Color(v[1],v[2],v[3]) end,
	table = function(tbl)
		for i,v in pairs(tbl) do
			if !isnumber(i) then return "" end
			if !isnumber(v) then return "" end
			if i < 1 or i > 4 then return "" end
		end
		return Color(tbl[1] or 0, tbl[2] or 0,tbl[3] or 0,tbl[4])
	end,
	Player = function(e) return IsValid(e) and e:IsPlayer() and e or "" end,
}

local function printColorArray(ply, target, arr)
	local send_array = {}

	for i,tp in ipairs_map(arr,type) do
		if printColor_types[tp] then
			send_array[i] = printColor_types[tp](arr[i])
		else
			send_array[i] = ""
		end
	end

	target = isentity(target) and {target} or target
	target = target or player.GetAll()

	local plys = {}
	for _, ply in pairs(target) do
		if ValidPly(ply) then
			table.insert(plys, ply)
		end
	end

	net.Start("wire_expression2_playercore_sendmessage")
		net.WriteEntity(ply)
		net.WriteTable(send_array)
	net.Send(plys)
end

e2function void sendMessageColor(array arr)
	-- if not ValidPly(this) then return end
	if not hasAccess(self.player, nil, "globalmessagecolor") then return nil end

	printColorArray(self.player, player.GetAll(), arr)
end

e2function void sendMessageColor(...)
	-- if not ValidPly(this) then return end
	if not hasAccess(self.player, nil, "globalmessagecolor") then return nil end

	printColorVarArg(self.player, player.GetAll(), typeids, ...)
end

e2function void entity:sendMessageColor(array arr)
	if not ValidPly(this) then return end
	if not hasAccess(self.player, this, "messagecolor") then return nil end

	printColorArray(self.player, this, arr)
end

e2function void entity:sendMessageColor(...)
	if not ValidPly(this) then return end
	if not hasAccess(self.player, this, "messagecolor") then return nil end

	printColorVarArg(self.player, this, typeids, ...)
end

e2function void array:sendMessageColor(array arr)
	local plys = {}

	for _, ply in pairs(this) do
		if not ValidPly(ply) then continue end
		if not hasAccess(self.player, ply, "messagecolor") then continue end

		table.insert(plys, ply)
	end

	printColorArray(self.player, plys, arr)
end

e2function void array:sendMessageColor(...)
	local plys = {}

	for _, ply in pairs(this) do
		if not ValidPly(ply) then continue end
		if not hasAccess(self.player, ply, "messagecolor") then continue end

		table.insert(plys, ply)
	end

	printColorVarArg(self.player, plys, typeids, ...)
end


--[[############################################]]

local registered_e2s_spawn = {}
local lastspawnedplayer = NULL
local respawnrun = 0

registerCallback("destruct",function(self)
		registered_e2s_spawn[self.entity] = nil
end)

hook.Add("PlayerSpawn","Expresion2_PlayerSpawn", function(ply)
	local ents = {}

	for entity,_ in pairs(registered_e2s_spawn) do
		if entity:IsValid() then table.insert(ents, entity) end
	end

	respawnrun = 1
	lastspawnedplayer = ply
	for _,entity in ipairs(ents) do
		entity:Execute()
	end
	respawnrun = 0
end)

e2function void runOnSpawn(activate)
	if activate ~= 0 then
		registered_e2s_spawn[self.entity] = true
	else
		registered_e2s_spawn[self.entity] = nil
	end
end

e2function number spawnClk()
	return respawnrun
end

e2function entity lastSpawnedPlayer()
	return lastspawnedplayer
end

--[[############################################]]

local registered_e2s_death = {}
local playerdeathinfo = {[1]=NULL, [2]=NULL, [3]=NULL}
local deathrun = 0

registerCallback("destruct",function(self)
		registered_e2s_death[self.entity] = nil
end)

hook.Add("PlayerDeath","Expresion2_PlayerDeath", function(victim, inflictor, attacker)
	local ents = {}

	for entity,_ in pairs(registered_e2s_death) do
		if entity:IsValid() then table.insert(ents, entity) end
	end

	deathrun = 1
	playerdeathinfo = { victim, inflictor, attacker}
	for _,entity in ipairs(ents) do
		entity:Execute()
	end
	deathrun = 0
end)

e2function void runOnDeath(activate)
	if activate ~= 0 then
		registered_e2s_death[self.entity] = true
	else
		registered_e2s_death[self.entity] = nil
	end
end

e2function number deathClk()
	return deathrun
end

e2function entity lastDeath()
	return playerdeathinfo[1]
end

e2function entity lastDeathInflictor()
	return playerdeathinfo[2]
end

e2function entity lastDeathAttacker()
	return playerdeathinfo[3]
end

--[[############################################]]

local registered_e2s_connect = {}
local lastconnectedplayer = NULL
local connectrun = 0

registerCallback("destruct",function(self)
		registered_e2s_connect[self.entity] = nil
end)

hook.Add("PlayerInitialSpawn","Expresion2_PlayerInitialSpawn", function(ply)
	connectrun = 1
	lastconnectedplayer = ply

	for entity,_ in pairs(registered_e2s_connect) do
		if entity:IsValid() then
			entity:Execute()
		end
	end

	connectrun = 0
end)

e2function void runOnConnect(activate)
	if activate ~= 0 then
		registered_e2s_connect[self.entity] = true
	else
		registered_e2s_connect[self.entity] = nil
	end
end

e2function number connectClk()
	return connectrun
end

e2function entity lastConnectedPlayer()
	return lastconnectedplayer
end

--[[############################################]]

local registered_e2s_disconnect = {}
local lastdisconnectedplayer = NULL
local disconnectrun = 0

registerCallback("destruct",function(self)
		registered_e2s_disconnect[self.entity] = nil
end)

hook.Add("PlayerDisconnected","Expresion2_PlayerDisconnected", function(ply)
	disconnectrun = 1
	lastdisconnectedplayer = ply

	for entity,_ in pairs(registered_e2s_disconnect) do
		if entity:IsValid() then
			entity:Execute()
		end
	end

	disconnectrun = 0
end)

e2function void runOnDisconnect(activate)
	if activate ~= 0 then
		registered_e2s_disconnect[self.entity] = true
	else
		registered_e2s_disconnect[self.entity] = nil
	end
end

e2function number disconnectClk()
	return disconnectrun
end

e2function entity lastDisconnectedPlayer()
	return lastdisconnectedplayer
end
