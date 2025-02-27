// Look up levels[z].traits[trait]
/datum/controller/subsystem/mapping/proc/level_trait(z, trait)
	if (!isnum(z) || z < 1)
		return null
	if (z_list)
		if (z > length(z_list))
			stack_trace("Unmanaged z-level [z]! maxz = [world.maxz], length(z_list) = [length(z_list)]")
			return list()
		var/datum/space_level/S = get_level(z)
		return S.traits[trait]
	else
		var/list/default = DEFAULT_MAP_TRAITS
		if (z > length(default))
			stack_trace("Unmanaged z-level [z]! maxz = [world.maxz], length(default) = [length(default)]")
			return list()
		return default[z][DL_TRAITS][trait]

// Check if levels[z] has any of the specified traits
/datum/controller/subsystem/mapping/proc/level_has_any_trait(z, list/traits)
	for (var/I in traits)
		if (level_trait(z, I))
			return TRUE
	return FALSE

// Check if levels[z] has all of the specified traits
/datum/controller/subsystem/mapping/proc/level_has_all_traits(z, list/traits)
	for (var/I in traits)
		if (!level_trait(z, I))
			return FALSE
	return TRUE

// Get a list of all z which have the specified trait
/datum/controller/subsystem/mapping/proc/levels_by_trait(trait)
	. = list()
	var/list/_z_list = z_list
	for(var/A in _z_list)
		var/datum/space_level/S = A
		if (S.traits[trait])
			. += S.z_value

// Get a list of all z which have any of the specified traits
/datum/controller/subsystem/mapping/proc/levels_by_any_trait(list/traits)
	. = list()
	var/list/_z_list = z_list
	for(var/A in _z_list)
		var/datum/space_level/S = A
		for (var/trait in traits)
			if (S.traits[trait])
				. += S.z_value
				break

// Attempt to get the turf below the provided one according to Z traits
/datum/controller/subsystem/mapping/proc/get_turf_below(turf/T)
	if (!T)
		return
	var/offset = level_trait(T.z, ZTRAIT_DOWN)
	if (!offset)
		return
	return locate(T.x, T.y, T.z + offset)

// Attempt to get the turf above the provided one according to Z traits
/datum/controller/subsystem/mapping/proc/get_turf_above(turf/T)
	if (!T)
		return
	var/offset = level_trait(T.z, ZTRAIT_UP)
	if (!offset)
		return
	return locate(T.x, T.y, T.z + offset)

// Prefer not to use this one too often
/datum/controller/subsystem/mapping/proc/get_station_center()
	var/station_z = levels_by_trait(ZTRAIT_STATION)[1]
	return locate(round(world.maxx * 0.5, 1), round(world.maxy * 0.5, 1), station_z)

// Prefer not to use this one too often
/datum/controller/subsystem/mapping/proc/get_mainship_center()
	var/mainship_z = levels_by_trait(ZTRAIT_MARINE_MAIN_SHIP)[1]
	return locate(round(world.maxx * 0.5, 1), round(world.maxy * 0.5, 1), mainship_z)

// Prefer not to use this one too often
/datum/controller/subsystem/mapping/proc/get_ground_center()
	var/ground_z = levels_by_trait(ZTRAIT_GROUND)[1]
	return locate(round(world.maxx * 0.5, 1), round(world.maxy * 0.5, 1), ground_z)

// Returns true if they are on the same map if the map is multiz
/datum/controller/subsystem/mapping/proc/same_z_map(z1, z2)
	if(z1 == z2)
		return TRUE
	
	var/diff = z2 - z1
	var/direction = diff > 0 ? ZTRAIT_UP : ZTRAIT_DOWN  

	for(var/step in 1 to abs(diff))
		if(!level_trait(z1, direction))
			return FALSE

		z1 += diff > 0 ? 1 : -1

		if(z1 == z2)
			return TRUE

	return FALSE 
		
