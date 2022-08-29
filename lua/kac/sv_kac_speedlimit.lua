
print("[KAC] \tLoaded sv_kac_speedlimit.lua")

if SERVER then 

	function kac_speedlimit()
		KAC.debug("[KAC] Loaded SetPerformanceSettings")

		local tbl = physenv.GetPerformanceSettings() 
		tbl.MaxAngularVelocity = 10000 
		tbl.MaxVelocity = 10000
		tbl.LookAheadTimeObjectsVsObject = 0.1
		tbl.LookAheadTimeObjectsVsWorld = 0.25
		tbl.MaxCollisionsPerObjectPerTimestep = 2
		physenv.SetPerformanceSettings(tbl) 
	end

	timer.Simple( 30, function() kac_speedlimit() end )
	timer.Simple( 15, kac_speedlimit, "yes!" )

end

--[[ default
LookAheadTimeObjectsVsObject	=	0.5
Maximum amount of seconds to precalculate collisions with objects.

LookAheadTimeObjectsVsWorld	=	1
Maximum amount of seconds to precalculate collisions with world.

MaxAngularVelocity	=	3636.3637695313
Maximum rotation velocity.

MaxCollisionChecksPerTimestep	=	250
Maximum collision checks per tick.

MaxCollisionsPerObjectPerTimestep	=	6
Maximum collision per object per tick.

MaxFrictionMass	=	2500
Maximum mass of an object to be affected by friction.

MaxVelocity	=	2000
Maximum speed of an object.

MinFrictionMass	=	10
Minimum mass of an object to be affected by friction.
]]
