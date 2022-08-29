E2Helper.Descriptions["plyApplyForce"] = "Sets the velocity of the player."
E2Helper.Descriptions["plySetPos"] = "Sets the position of the player."
E2Helper.Descriptions["plySetAng"] = "Sets the angle of the player."
E2Helper.Descriptions["plyNoclip"] = "Sets the player's noclip."
E2Helper.Descriptions["plySetHealth"] = "Sets the health of the player."
E2Helper.Descriptions["plySetArmor"] = "The amount that the player armor is going to be set to."
E2Helper.Descriptions["plySetMass"] = "Sets the mass of the player. - default 85"
E2Helper.Descriptions["plySetJumpPower"] = "Sets the jump power, eg. the velocity the player will applied to when he jumps. - default 200"
E2Helper.Descriptions["plySetGravity"] = "Sets the gravity multiplier of the player. default 600"
E2Helper.Descriptions["plySetSpeed"] = "Sets the speed of the player. - default 200"
E2Helper.Descriptions["plyResetSettings"] = "Reset all values of the player."
E2Helper.Descriptions["plyEnterVehicle"] = "Enters the player into specified vehicle."
E2Helper.Descriptions["plyExitVehicle"] = "Makes the player exit the vehicle if they're in one."
E2Helper.Descriptions["plySpawn"] = "Brings back the player."
E2Helper.Descriptions["plyGod"] = "It's to become invincible."

E2Helper.Descriptions["plyGetMass"] = "Returns the mass of the player."
E2Helper.Descriptions["plyGetJumpPower"] = "Returns the jump power of the player."
E2Helper.Descriptions["plyGetGravity"] = "Gets the gravity multiplier of the player."
E2Helper.Descriptions["plyGetSpeed"] = "Gets the speed of the player."

local plys = {}


net.Receive("wire_expression2_playercore_sendmessage", function( len, ply )
	local ply = net.ReadEntity()
	if ply and not plys[ply] then
		plys[ply] = true
		-- printColorDriver is used for the first time on us by this chip
		WireLib.AddNotify(msg1, NOTIFY_GENERIC, 7, NOTIFYSOUND_DRIP3)
		WireLib.AddNotify(msg2, NOTIFY_GENERIC, 7)
		chat.AddText(Color(255, 50, 50),"After this message, ", ply, " can send you a 100% realistically fake people talking, including admins.")
		chat.AddText(Color(255, 50, 50),"Look the console to see if the message is form an expression2")
	end

	LocalPlayer():PrintMessage(HUD_PRINTCONSOLE, "[E2] " .. ply:Name() .. ": ")
	chat.AddText(Color(255, 50, 50), "> ", Color(151, 211, 255), unpack(net.ReadTable()))
end)

hook.Add("PlayerNoClip", "PlyCore", function(ply, state)
	if not state then return end

	if ply:GetNWBool("PlyCore_DisableNoclip", false) then
		return false
	end
end)
