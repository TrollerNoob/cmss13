/obj/effect/firemission_guidance
	invisibility = 101
	var/list/mob/users
	var/camera_width = 11
	var/camera_height = 11
	var/view_range = 7

/obj/effect/firemission_guidance/New()
	..()
	users = list()

/obj/effect/firemission_guidance/Destroy(force)
	. = ..()
	users = null

/obj/effect/firemission_guidance/proc/can_use()
	return TRUE

/obj/effect/firemission_guidance/proc/isXRay()
	return FALSE

/obj/effect/firemission_guidance/proc/updateCameras(atom/target)
	SEND_SIGNAL(target, COMSIG_CAMERA_SET_TARGET, src, camera_width, camera_height)

/obj/effect/firemission_guidance/proc/clearCameras(atom/target)
	SEND_SIGNAL(target, COMSIG_CAMERA_CLEAR)

/datum/cas_fire_mission
	var/mission_length = 3 //can be 3,4,6 or 12
	var/list/datum/cas_fire_mission_record/records = list()
	var/obj/structure/dropship_equipment/weapon/error_weapon
	var/name = "Unnamed Firemission"
	var/corrosion_applied_this_firemission = FALSE // Track if corrosion was applied this firemission

/datum/cas_fire_mission/ui_data(mob/user)
	. = list()
	.["name"] = sanitize(copytext(name, 1, MAX_MESSAGE_LEN))
	.["mission_length"] = mission_length
	.["records"] = list()
	for(var/datum/cas_fire_mission_record/record as anything in records)
		.["records"] += list(record.ui_data(user))

/datum/cas_fire_mission/proc/build_new_record(obj/structure/dropship_equipment/weapon/weapon, fire_length)
	var/datum/cas_fire_mission_record/record = new()
	record.weapon = weapon
	record.offsets = new /list(fire_length)
	for(var/idx = 1; idx<=fire_length; idx++)
		record.offsets[idx] = "-"
	records += record

/datum/cas_fire_mission/proc/update_weapons(list/obj/structure/dropship_equipment/weapon/weapons, fire_length)
	var/list/datum/cas_fire_mission_record/bad_records = list()
	var/list/obj/structure/dropship_equipment/weapon/missing_weapons = list()
	for(var/datum/cas_fire_mission_record/record in records)
		// if weapon appears in weapons list but not in record
		// > add empty record for new weapon
		var/found = FALSE
		for(var/obj/structure/dropship_equipment/weapon/weapon in weapons)
			if(record.weapon == weapon)
				found=TRUE
				break
		if(!found)
			bad_records.Add(record)
	for(var/obj/structure/dropship_equipment/weapon/weapon in weapons)
		var/found = FALSE
		for(var/datum/cas_fire_mission_record/record in records)
			if(record.weapon == weapon)
				found=TRUE
				break
		if(!found)
			missing_weapons.Add(weapon)
	for(var/datum/cas_fire_mission_record/record in bad_records)
		records -= record
	for(var/obj/structure/dropship_equipment/weapon/weapon in missing_weapons)
		build_new_record(weapon, fire_length)

/datum/cas_fire_mission/proc/record_for_weapon(weapon_id)
	for(var/datum/cas_fire_mission_record/record as anything in records)
		if(record.weapon.ship_base.attach_id == weapon_id)
			return record
	return null

/datum/cas_fire_mission/proc/check(obj/structure/machinery/computer/dropship_weapons/linked_console)
	error_weapon = null
	if(length(records) == 0)
		return FIRE_MISSION_ALL_GOOD //I mean yes... but why?

	for(var/datum/cas_fire_mission_record/record in records)
		error_weapon = record.weapon
		if(!istype(record))
			return FIRE_MISSION_CODE_ERROR //What the fuck?
		if(!record.weapon.ship_base)
			return FIRE_MISSION_WEAPON_REMOVED //Someone disconnected it
		if(record.weapon.linked_console != linked_console)
			return FIRE_MISSION_WEAPON_REMOVED //Someone installed it on a different dropship

		var/limits = record.get_offsets()
		var/min
		var/max
		if(limits)
			min = limits["min"]
			max = limits["max"]
		var/cd = 0
		var/ammo_left = 0
		if(record.weapon.ammo_equipped)
			ammo_left = record.weapon.ammo_equipped.ammo_count
		var/i
		if(!record.offsets)
			continue
		for(i=1,i<=length(record.offsets),i++)
			if(cd > 0)
				cd--
			if(record.offsets[i] == null || record.offsets[i] == "-")
				continue
			if(record.offsets[i]<min || record.offsets[i]>max)
				return FIRE_MISSION_BAD_OFFSET
			if(cd > 0)
				return FIRE_MISSION_BAD_COOLDOWN
			if(!record.weapon.ammo_equipped)
				return FIRE_MISSION_WEAPON_OUT_OF_AMMO
			if(record.weapon.ammo_equipped.fire_mission_delay == 0)
				return FIRE_MISSION_WEAPON_UNUSABLE
			ammo_left -= record.weapon.ammo_equipped.ammo_used_per_firing
			if(ammo_left < 0)
				return FIRE_MISSION_WEAPON_OUT_OF_AMMO
			cd = record.weapon.ammo_equipped.fire_mission_delay
		error_weapon = null

	return FIRE_MISSION_ALL_GOOD//should be ok now

/datum/cas_fire_mission/proc/error_message(code_id)
	if(code_id == FIRE_MISSION_ALL_GOOD)
		return "All checks passed."
	if(code_id == FIRE_MISSION_CODE_ERROR)
		return "System error. Call Tech Support or create Fire Mission from scratch."
	if(!istype(error_weapon))
		return "Error or Fire Mission is outdated. Create Fire Mission from scratch if Error persists."
	var/weapon_string = "[error_weapon.name] "
	if(error_weapon.ammo_equipped)
		weapon_string += "([error_weapon.ammo_equipped.ammo_count]/[error_weapon.ammo_equipped.max_ammo_count]) "
	if(error_weapon.ship_base)
		weapon_string += "mounted on [error_weapon.ship_base.name] "

	if(code_id == FIRE_MISSION_BAD_COOLDOWN)
		return "Weapon [weapon_string] requires interval of [error_weapon.ammo_equipped.fire_mission_delay] time units per shot."
	if(code_id == FIRE_MISSION_BAD_OFFSET)
		// Change this to using weapon's when it is implemented
		var/obj/effect/attach_point/weapon/AW = error_weapon.ship_base
		if(!istype(AW))
			. = "Internal error: [weapon_string] hardpoint invalid"
			CRASH("CASFM-CHECK-01: Weapon attached to invalid hardpoint")
		var/list/allowed_offsets = AW.get_offsets()
		if(!allowed_offsets)
			. = "Internal error: [weapon_string] offsets invalid"
			CRASH("CASFM-CHECK-02: Weapon reported offsets invalid")
		return "Weapon hardpoint of [weapon_string] only allows gimbal offset between [allowed_offsets["min"]] and [allowed_offsets["max"]]."
	if(code_id == FIRE_MISSION_WEAPON_REMOVED)
		return "Weapon [weapon_string] is no longer located on this dropship"
	if(code_id == FIRE_MISSION_WEAPON_UNUSABLE)
		return "Weapon [weapon_string] is loaded with ammunition too dangerous to be used in Fire Mission"
	if(code_id == FIRE_MISSION_WEAPON_OUT_OF_AMMO)
		return "Weapon [weapon_string] has not enough ammunition to complete this Fire Mission"
	return "Unknown Error"

/// Returns a list of all turfs that will be targeted by this firemission, before any shots are fired
/datum/cas_fire_mission/proc/get_all_target_turfs(initial_turf, direction, steps)
	if(!initial_turf || !steps || !length(records))
		return list()

	var/list/target_turfs = list()
	var/turf/current_turf = initial_turf
	var/tally_step = steps / mission_length
	var/next_step = tally_step
	var/sx = 0
	var/sy = 0

	switch(direction)
		if(NORTH)
			sx = 1
			sy = 0
		if(SOUTH)
			sx = -1
			sy = 0
		if(EAST)
			sx = 0
			sy = -1
		if(WEST)
			sx = 0
			sy = 1

	for(var/step = 1; step <= steps; step++)
		if(step > next_step)
			current_turf = get_step(current_turf, direction)
			next_step += tally_step
		for(var/datum/cas_fire_mission_record/record in records)
			if(length(record.offsets) < step || record.offsets[step] == null || record.offsets[step] == "-")
				continue
			var/offset = record.offsets[step]
			var/turf/shootloc = locate(current_turf.x + sx*offset, current_turf.y + sy*offset, current_turf.z)
			if(shootloc && !(shootloc in target_turfs))
				target_turfs += shootloc
	return target_turfs

/datum/cas_fire_mission/proc/execute_firemission(obj/structure/machinery/computer/dropship_weapons/linked_console, turf/initial_turf, direction = NORTH, steps = 12, step_delay = 3, datum/cas_fire_envelope/envelope = null)
	if(initial_turf == null || check(linked_console) != FIRE_MISSION_ALL_GOOD)
		return FIRE_MISSION_NOT_EXECUTABLE

	// Check for vertical exhaust nozzle for live firemission speed boost
	var/obj/docking_port/mobile/marine_dropship/dropship = SSshuttle.getShuttle(linked_console.shuttle_tag)
	var/has_nozzle = FALSE
	if(istype(dropship))
		for(var/obj/structure/dropship_equipment/electronics/vertical_exhaust_nozzle/nozzle in dropship.equipments)
			has_nozzle = TRUE
			break
	if(has_nozzle)
		step_delay = step_delay - 1 // 33% faster

	// Firemission reticle overlay. Spawns on ALL shootlocs at the start of the firemission
	var/list/all_firemission_reticles = list()
	var/list/all_target_turfs = get_all_target_turfs(initial_turf, direction, steps)
	for(var/turf/impact_turf in all_target_turfs)
		if(impact_turf)
			var/obj/effect/overlay/temp/firemission_reticle/firemission_reticle = new /obj/effect/overlay/temp/firemission_reticle(impact_turf)
			all_firemission_reticles += firemission_reticle

	var/turf/current_turf = initial_turf
	var/tally_step = steps / mission_length //how much shots we need before moving to next turf
	var/next_step = tally_step //when we move to next turf
	var/sx = 0
	var/sy = 0 //perpendicular multiplication

	switch(direction)
		if(NORTH) //default direction
			sx = 1
			sy = 0
		if(SOUTH)
			sx = -1
			sy = 0
		if(EAST)
			sx = 0
			sy = -1
		if(WEST)
			sx = 0
			sy = 1
	var/step = 1
	var/list/corroded_this_execution = list() // Track which weapons have been corroded this execution only
	for(step = 1; step<=steps; step++)
		if(step > next_step)
			current_turf = get_step(current_turf, direction)
			next_step += tally_step
			if(envelope)
				envelope.change_current_loc(current_turf)
		var/datum/cas_fire_mission_record/item
		var/list/just_corroded = list() // Track weapons corroded this step
		for(item in records)
			if(length(item.offsets) < step || item.offsets[step] == null || item.offsets[step]=="-")
				continue
			var/offset = item.offsets[step]
			if (current_turf == null)
				return -1
			var/turf/shootloc = locate(current_turf.x + sx*offset, current_turf.y + sy*offset, current_turf.z)
			var/area/area = get_area(shootloc)
			if(shootloc && (shootloc.turf_protection_flags & TURF_PROTECTION_ANTIAIR))
				// Gather all eligible weapons (not destroyed, not already corroded this execution)
				var/list/eligible_weapons = list()
				for(var/datum/cas_fire_mission_record/rec in records)
					if(rec && istype(rec.weapon, /obj/structure/dropship_equipment/weapon) && !rec.weapon.corrosion_destroyed)
						if(!(rec.weapon in corroded_this_execution))
							eligible_weapons += rec.weapon
				// Randomly select 1 or 2 weapons to corrode
				var/num_to_corrode = min(rand(1,2), eligible_weapons.len)
				if(num_to_corrode > 0)
					eligible_weapons = shuffle(eligible_weapons)
					var/list/selected = list()
					for(var/i = 1, i <= num_to_corrode, i++)
						selected += eligible_weapons[i]
					for(var/obj/structure/dropship_equipment/weapon/w in selected)
						var/applier = null
						if(shootloc.skyspit_applier)
							applier = shootloc.skyspit_applier
						w.apply_corrosion_stack(applier)
						corroded_this_execution += w
						just_corroded += w
			if(shootloc && !CEILING_IS_PROTECTED(area?.ceiling, CEILING_PROTECTION_TIER_3) && !protected_by_pylon(TURF_PROTECTION_CAS, shootloc))
				if(item && item.weapon)
					item.weapon.open_fire_firemission(shootloc)
			// Audible warning for nearby humans
			if(envelope && istype(envelope, /datum/cas_fire_envelope) && shootloc && (shootloc.turf_protection_flags & TURF_PROTECTION_ANTIAIR))
				envelope.show_corrosion_audible(current_turf, 10)
			// Planetside effects: sparks and sound (spam-protected)
			if(just_corroded.len && !envelope?.corrosion_fx_played)
				envelope.corrosion_fx_played = TRUE
			// Shake the shuttle (only once per firemission, and only if a shot hit anti-air turf)
			if(linked_console.shuttle_tag && envelope && !envelope.shuttle_shake_played && shootloc && (shootloc.turf_protection_flags & TURF_PROTECTION_ANTIAIR))
				envelope.shuttle_shake_played = TRUE
				var/obj/docking_port/mobile/marine_dropship/shuttle = SSshuttle.getShuttle(linked_console.shuttle_tag)
				if(shuttle && shuttle.shuttle_areas)
					var/list/all_turfs = list()
					for(var/area/internal_area in shuttle.shuttle_areas)
						for(var/turf/internal_turf in internal_area)
							all_turfs += internal_turf
							for(var/mob/M in internal_turf)
								to_chat(M, SPAN_DANGER("The ship jostles violently as something rocks the vessel!"))
								to_chat(M, SPAN_DANGER("You feel the ship turning sharply as it adjusts its course!"))
								if(istype(M, /mob/living))
									shake_camera(M, 20, 1)
						playsound_area(internal_area, 'sound/effects/Explosion1.ogg')
					// Spawn sparks on up to 9 unique random turfs in the shuttle interior
					if(all_turfs.len)
						var/list/used = list()
						var/max_sparks = min(17, all_turfs.len)
						for(var/i = 1, i <= max_sparks, i++)
							var/turf/random_turf = pick(all_turfs - used)
							if(random_turf)
								new /obj/effect/particle_effect/sparks(random_turf)
								used += random_turf
		sleep(step_delay)
	if(envelope)
		envelope.change_current_loc(null)
		envelope.corrosion_fx_played = FALSE
		envelope.shuttle_shake_played = FALSE

	// --- Impact reticle overlay: delete all at the end of the firemission ---
	for(var/obj/effect/overlay/temp/firemission_reticle/ret in all_firemission_reticles)
		if(ret)
			qdel(ret)


/**
 * Used only in the simulation room, proper tracking is done in the add_user_to_tracking envelop.
 * This shouldn't be used in any other procs.
 */
/datum/cas_fire_mission/proc/add_user_to_sim_tracking(mob/living/user, obj/effect/firemission_guidance/guidance)

	var/mob/tracked_user = user
	if(!tracked_user.client || !guidance)
		return

	tracked_user.reset_view(guidance)
	if(!(user in guidance.users))
		guidance.users += tracked_user

// Used only in the simulator room for testing firemissions. Seemed better to just to copy here.
/datum/cas_fire_mission/proc/simulate_execute_firemission(obj/structure/machinery/computer/dropship_weapons/linked_console, turf/initial_turf, mob/living/user, direction = NORTH, steps = 12, step_delay = 3)
	if(!initial_turf)
		return FIRE_MISSION_NOT_EXECUTABLE

	var/obj/effect/firemission_guidance/guidance = new()

	guidance.forceMove(locate(initial_turf.x,initial_turf.y, initial_turf.z))

	add_user_to_sim_tracking(user, guidance)
	var/turf/current_turf = initial_turf
	var/tally_step = steps / mission_length //how much shots we need before moving to next turf
	var/next_step = tally_step //when we move to next turf
	var/sx = 0
	var/sy = 0 //perpendicular multiplication

	switch(direction)
		if(NORTH) //default direction
			sx = 1
			sy = 0
		if(SOUTH)
			sx = -1
			sy = 0
		if(EAST)
			sx = 0
			sy = -1
		if(WEST)
			sx = 0
			sy = 1
	for(var/step in 1 to steps)
		if(step > next_step)
			current_turf = get_step(current_turf,direction)
			next_step += tally_step
		var/datum/cas_fire_mission_record/item
		for(item in records)
			if(length(item.offsets) < step || item.offsets[step] == null || item.offsets[step] == "-")
				continue
			var/offset = item.offsets[step]
			var/turf/shootloc = locate(current_turf.x + sx*offset, current_turf.y + sy*offset, current_turf.z)
			item.weapon.open_simulated_fire_firemission(shootloc)
			guidance.forceMove(locate(initial_turf.x,initial_turf.y + step, initial_turf.z))
		sleep(step_delay)
