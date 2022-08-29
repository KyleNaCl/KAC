  
/******************************************************************************\
KAC Core by Kyle
\******************************************************************************/

E2Lib.RegisterExtension("kac", true, "Custom Functions", "Made by: Kyle")

--------------------------------------------------------------------------------

__e2setcost(2)

e2function number entity:inBuildmode()
	if not IsValid(this) then return 0 end
	if not this:IsPlayer() then return 0 end
	if KAC.InBuild(this) then return 1 end
	return 0
end

e2function number entity:hasSpawnProtection()
	if not IsValid(this) then return 0 end
	if not this:IsPlayer() then return 0 end
	if this.rszIsProtected then
		if this:rszIsProtected() then return 1 end
	end
	return 0
end

e2function number entity:isUnbreakable()
	if not IsValid(this) then return 0 end
	return this:GetVar("Unbreakable")
end

e2function number entity:isPersistent()
	if not IsValid(this) then return 0 end
	if this:GetPersistent() then return 1 else return 0 end
end

e2function number entity:getAnimID()
	if not IsValid(this) then return 0 end
	return this:GetSequence()
end

__e2setcost(10)

e2function array entity:getAnimList()
	if not IsValid(this) then return {} end

	local animtable = this:GetSequenceList()
	local animarray = {}
	local i = 1
	for _,ent in pairs(animtable) do
		if ent ~= this then
			animarray[i] = ent
			i = i + 1
		end
	end

	self.prf = self.prf + i * 5

	return animarray
end