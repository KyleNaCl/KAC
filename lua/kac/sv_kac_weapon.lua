
print("[KAC] \tLoaded sv_kac_weapon.lua")

timer.Simple(5,function()

	local m79 = weapons.GetStored("tfa_cso2_m79")
	if m79 then
		m79.Primary.ProjectileVelocity = 1750 * 16 / 12

		local m203 = weapons.GetStored("tfa_cso2_m16m203")
		m203.Secondary.ProjectileVelocity = 1750 * 16 / 12

		local chi = weapons.GetStored("tfa_cso2_chinalake")
		chi.Primary.ProjectileVelocity = 1750 * 16 / 12

		local paw = weapons.GetStored("tfa_cso2_paw20")
		paw.Primary.ProjectileVelocity = 2250 * 16 / 12

		local rpg7 = weapons.GetStored("tfa_cso2_rpg7")
		rpg7.Primary.ProjectileVelocity = 2500 * 16 / 12
	end

	local bo1_chi = weapons.GetStored("robotnik_bo1_cl")
	if bo1_chi then
		bo1_chi.ProjectileVelocity = 1750 * 16 / 12

		local bo1_law = weapons.GetStored("robotnik_bo1_law")
		bo1_law.ProjectileVelocity = 2200 * 16 / 12

		local bo1_rpg = weapons.GetStored("robotnik_bo1_rpg")
		--bo1_rpg.ProjectileVelocity = 500 * 16 / 12
		--bo1_rpg.ProjectileEntity = "tfa_exp_rocket"
		bo1_rpg.ProjectileVelocity = 2500 * 16 / 12
		bo1_rpg.ProjectileEntity = "tfa_exp_contact"

		local bo1_202 = weapons.GetStored("robotnik_bo1_202")
		--bo1_202.ProjectileVelocity = 500 * 16 / 12
		--bo1_202.ProjectileEntity = "tfa_exp_rocket"
		bo1_202.ProjectileVelocity = 2500 * 16 / 12
		bo1_202.ProjectileEntity = "tfa_exp_contact"
	end

	local mw2_m79 = weapons.GetStored("robotnik_mw2_m79")
	if mw2_m79 then
		mw2_m79.ProjectileVelocity = 1750 * 16 / 12

		local mw2_at4 = weapons.GetStored("robotnik_mw2_at4")
		mw2_at4.ProjectileVelocity = 2200 * 16 / 12

		local mw2_rpg = weapons.GetStored("robotnik_mw2_rpg")
		--mw2_rpg.ProjectileVelocity = 500 * 16 / 12
		--mw2_rpg.ProjectileEntity = "tfa_exp_rocket"
		mw2_rpg.ProjectileVelocity = 2500 * 16 / 12
		mw2_rpg.ProjectileEntity = "tfa_exp_contact"
	end

	if m79 then
		local rocket = scripted_ents.GetStored("tfa_exp_rocket")
		rocket.t.BaseSpeed = 100
		rocket.t.MaxSpeed = 2000
		rocket.t.AccelerationTime = 0.1

		local base = scripted_ents.GetStored("tfa_exp_base")
		base.t.Delay = 10
	end

	KAC.debug("[KAC] Loaded Custom Weapon Tables")

end)
