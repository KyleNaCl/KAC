local function WireHologramsShowOwners()
	local Cache = {}
	local CacheE2 = {}
	for _,ent in pairs( ents.FindByClass( "gmod_wire_hologram" ) ) do
		local id = ent:GetNWInt( "ownerid" )

		local ply = Player(id)
		if IsValid(ply) then
			local e2id = ent:GetNWInt( "selfid" )
			local e2 = Entity(e2id)
			local e2name = ""
			if e2id > 0 and IsValid(e2) and Cache[e2id] == nil then
				e2name = e2:GetNWString("name") .. "\n"
				Cache[e2id] = e2:GetPos():ToScreen()
			end

			local vec = ent:GetPos():ToScreen()
			local color = team.GetColor(ply:Team() or 1001)

			if vec.x == 0 or vec.y == 0 then continue end 

			if vec.visible then
				draw.DrawText("ﬗ\n" .. ply:Name(), "DermaDefault", vec.x, vec.y - 6, color, 1)
			end

			if Cache[e2id] != nil and Cache[e2id].visible then
				if vec.visible then
					surface.SetDrawColor(color.r, color.g, color.b, 5)
					surface.DrawLine( vec.x, vec.y, Cache[e2id].x, Cache[e2id].y )
				end
				if CacheE2[e2id] == nil then
					draw.DrawText(e2name .. "E2 [" .. e2id .. "]\n" .. ply:Name(), "DermaDefault", Cache[e2id].x, Cache[e2id].y, color, 1)
					CacheE2[e2id] = true
				end
			end
		end
	end
end

local display_owners = false
concommand.Add("wire_holograms_display_owners", function()
	display_owners = !display_owners
	if display_owners then
		hook.Add("HUDPaint", "wire_holograms_showowners", WireHologramsShowOwners)
	else
		hook.Remove("HUDPaint", "wire_holograms_showowners")
	end
end )
