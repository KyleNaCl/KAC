language.Add("Undone_e2_spawned_prop", "Undone E2 Spawned Prop")
language.Add("Undone_e2_spawned_seat", "Undone E2 Spawned Seat")
E2Helper.Descriptions["propManipulate(e:vannn)"] = "Allows to do any single prop core function in one term (position, rotation, freeze, gravity, notsolid)"
E2Helper.Descriptions["propSpawn(sn)"] = "Use the model string or a template entity to spawn a prop. You can set the position and/or the rotation as well. The last number indicates frozen/unfrozen."
E2Helper.Descriptions["propSpawn(en)"] = "Entity template, Frozen Spawns a prop with the model of the template entity. If frozen is 0, then it will spawn unfrozen."
E2Helper.Descriptions["propSpawn(svn)"] = "Model path, Position, Frozen Spawns a prop with the model denoted by the string filepath at the position denoted by the vector. If frozen is 0, then it will spawn unfrozen."
E2Helper.Descriptions["propSpawn(evn)"] = "Entity template, Position, Frozen Spawns a prop with the model of the template entity at the position denoted by the vector. If frozen is 0, then it will spawn unfrozen."
E2Helper.Descriptions["propSpawn(san)"] = "Model path, Rotation, Frozen Spawns a prop with the model denoted by the string filepath and rotated to the angle given. If frozen is 0, then it will spawn unfrozen."
E2Helper.Descriptions["propSpawn(ean)"] = "Rotation, Frozen Spawns a prop with the model of the template entity and rotated to the angle given. If frozen is 0, then it will spawn unfrozen."
E2Helper.Descriptions["propSpawn(svan)"] = "Model path, Position, Rotation, Frozen Spawns a prop with the model denoted by the string file path, at the position denoted by the vector, and rotated to the angle given. If frozen is 0, then it will spawn unfrozen."
E2Helper.Descriptions["propSpawn(evan)"] = "Position, Rotation, Frozen Spawns a prop with the model of the template entity, at the position denoted by the vector, and rotated to the angle given. If frozen is 0, then it will spawn unfrozen."
E2Helper.Descriptions["seatSpawn(sn)"] = "Model path, Frozen Spawns a prop with the model denoted by the string filepath. If frozen is 0, then it will spawn unfrozen."
E2Helper.Descriptions["seatSpawn(svan)"] = E2Helper.Descriptions["seatSpawn(sn)"]
E2Helper.Descriptions["propSpawnEffect(n)"] = "Set to 1 to enable prop spawn effect, 0 to disable."
E2Helper.Descriptions["propDelete(e:)"] = "Deletes the specified prop."
E2Helper.Descriptions["propDelete(t:)"] = "Deletes all the props in the given table, returns the amount of props deleted."
E2Helper.Descriptions["propDelete(r:)"] = "Deletes all the props in the given array, returns the amount of props deleted."
E2Helper.Descriptions["propFreeze(e:n)"] = "Passing 0 unfreezes the entity, everything else freezes it."
E2Helper.Descriptions["propNotSolid(e:n)"] = "Passing 0 makes the entity solid, everything else makes it non-solid."
E2Helper.Descriptions["propGravity(e:n)"] = "Passing 0 makes the entity weightless, everything else makes it weighty."
E2Helper.Descriptions["propMakePersistent(e:n)"] = "Setting to 1 will make the prop persistent."
E2Helper.Descriptions["propPhysicalMaterial(e:s)"] = "Changes the surface material of a prop (eg. wood, metal, ... See Material_surface_properties )."
E2Helper.Descriptions["propPhysicalMaterial(e:)"] = "Returns the surface material of a prop."
E2Helper.Descriptions["setPos(e:v)"] = "Sets the position of an entity."
E2Helper.Descriptions["reposition(e:v)"] = "Deprecated. Kept for backwards-compatibility."
E2Helper.Descriptions["setAng(e:a)"] = "Set the rotation of an entity."
E2Helper.Descriptions["rerotate(e:a)"] = "Deprecated. Kept for backwards-compatibility."
E2Helper.Descriptions["parentTo(e:e)"] = "Parents one entity to another."
E2Helper.Descriptions["parentTo(e:)"] = E2Helper.Descriptions["parentTo(e:e)"]
E2Helper.Descriptions["deparent(e:)"] = "Unparents an entity, so it moves freely again."
E2Helper.Descriptions["propBreak(e:)"] = "Breaks/Explodes breakable/explodable props (Useful for Mines)."
E2Helper.Descriptions["propCanCreate()"] = "Returns 1 when propSpawn() will successfully spawn a prop until the limit is reached."
E2Helper.Descriptions["propDrag(e:n)"] = "Passing 0 makes the entity not be affected by drag"
E2Helper.Descriptions["propInertia(e:n)"] = "Sets the directional inertia"
E2Helper.Descriptions["propInertia(e:v)"] = E2Helper.Descriptions["propInertia(e:n)"]
E2Helper.Descriptions["propDraw(e:n)"] = "Passing 0 disables rendering for the entity (makes it really invisible)"
E2Helper.Descriptions["propShadow(e:n)"] = "Passing 0 disables rendering for the entity's shadow"
E2Helper.Descriptions["propSetBuoyancy(e:n)"] = "Sets the prop's buoyancy ratio from 0 to 1"
E2Helper.Descriptions["propSetFriction(e:n)"] = "Sets prop's friction coefficient (default is 1)"
E2Helper.Descriptions["propGetFriction(e:)"] = "Gets prop's friction coefficient"
E2Helper.Descriptions["propSetElasticity(e:n)"] = "Sets prop's elasticity coefficient (default is 1)"
E2Helper.Descriptions["propGetElasticity(e:)"] = "Gets prop's elasticity coefficient"
E2Helper.Descriptions["propSpawnUndo(n)"] = "Set to 0 to force prop removal on E2 shutdown, and suppress Undo entries for props."
E2Helper.Descriptions["propDeleteAll()"] = "Removes all entities spawned by this E2"
E2Helper.Descriptions["propStatic(e:n)"] = "Sets to 1 to make the entity static (disables movement, physgun, unfreeze, drive...) or 0 to cancel."
E2Helper.Descriptions["propSetVelocity(e:v)"] = "Sets the velocity of the prop for the next iteration"
E2Helper.Descriptions["propSetVelocityInstant(e:v)"] = "Sets the initial velocity of the prop"
E2Helper.Descriptions["use(e:)"] = "Simulates a player pressing their use key on the entity."
