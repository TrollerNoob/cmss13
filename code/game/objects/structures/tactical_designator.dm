// Tripod-mounted CAS designator. Shares the Vulture tripod's rotation and operator positioning.
/obj/item/device/vulture_spotter_tripod/tactical
	name = "tactical laser designator"
	desc = "A tripod-mounted laser designator. Use in hand to deploy it, then drag the tripod onto yourself to use its optics."

/obj/item/device/vulture_spotter_tripod/tactical/attack_self(mob/user)
	if(!ishuman(user) || user.is_mob_incapacitated() || !isturf(user.loc))
		return
	if(!do_after(user, 1.5 SECONDS, target = user))
		return
	var/obj/structure/vulture_spotter_tripod/tactical/tripod = new(get_turf(user))
	tripod.setDir(user.dir)
	qdel(src)

/obj/structure/vulture_spotter_tripod/tactical
	name = "tactical laser designator"
	desc = "A stabilized CAS designator. Drag it onto yourself to look ahead. Ctrl-click a living target to track it for direct fire, or a turf to lase normally. Ctrl-click the tripod to stop lasing. Alt-click to rotate; use a screwdriver to pack it up."
	skillless = TRUE
	scope_attached = TRUE
	flags_atom = FPRINT|CONDUCT|RELAY_CLICK
	/// Forward offset of the optics, in tiles.
	var/view_offset = 10
	/// Faster than the standard handheld designator.
	var/acquisition_delay = 2 SECONDS
	var/tracking_id
	var/acquiring = FALSE
	/// Invalidates pending acquisition when the operator cancels or disengages.
	var/acquisition_serial = 0
	var/obj/effect/overlay/temp/laser_target/tactical/laser

/obj/structure/vulture_spotter_tripod/tactical/Initialize(mapload)
	. = ..()
	desc = initial(desc)
	tracking_id = ++GLOB.cas_tracking_id_increment

/obj/structure/vulture_spotter_tripod/tactical/Destroy()
	QDEL_NULL(laser)
	return ..()

/obj/structure/vulture_spotter_tripod/tactical/deconstruct(disassembled)
	new /obj/item/device/vulture_spotter_tripod/tactical(get_turf(src))

/obj/structure/vulture_spotter_tripod/tactical/get_examine_text(mob/user)
	. = ..()
	. += SPAN_NOTICE("CAS tracking ID: [tracking_id].")

/obj/structure/vulture_spotter_tripod/tactical/attackby(obj/item/thing, mob/user)
	if(HAS_TRAIT(thing, TRAIT_TOOL_SCREWDRIVER))
		if(scope_using)
			to_chat(user, SPAN_WARNING("Stop using the optics before packing up the designator."))
			return
		if(!do_after(user, 1.5 SECONDS, target = src))
			return
		if(scope_using)
			return
		var/obj/item/device/vulture_spotter_tripod/tactical/folded = new(get_turf(src))
		user.put_in_hands(folded)
		qdel(src)
		return

/obj/structure/vulture_spotter_tripod/tactical/MouseDrop(over_object, src_location, over_location)
	if(over_object == usr && ishuman(usr) && Adjacent(usr))
		try_scope(usr)

/obj/structure/vulture_spotter_tripod/tactical/try_scope(mob/living/carbon/human/user)
	if(scope_using || !user.client || !Adjacent(user) || user.is_mob_incapacitated() || user.body_position != STANDING_UP)
		return
	if(user.l_hand || user.r_hand)
		to_chat(user, SPAN_WARNING("Your hands must be free to use the optics."))
		return
	user.set_interaction(src)

/obj/structure/vulture_spotter_tripod/tactical/on_set_interaction(mob/living/user)
	scope_user = WEAKREF(user)
	scope_using = TRUE
	user.forceMove(loc)
	user.setDir(dir)
	user.client.change_view(scope_zoom, src)
	user.client.pixel_x = (dir == EAST ? view_offset : (dir == WEST ? -view_offset : 0)) * world.icon_size
	user.client.pixel_y = (dir == NORTH ? view_offset : (dir == SOUTH ? -view_offset : 0)) * world.icon_size
	RegisterSignal(user.client, COMSIG_PARENT_QDELETING, PROC_REF(do_unscope))
	RegisterSignal(user, list(COMSIG_MOB_PICKUP_ITEM, COMSIG_MOB_RESISTED, COMSIG_MOB_DEATH, COMSIG_LIVING_SET_BODY_POSITION, COMSIG_MOVABLE_MOVED, COMSIG_PARENT_QDELETING), PROC_REF(do_unscope))
	ADD_TRAIT(user, TRAIT_IMMOBILIZED, TRAIT_SOURCE_ABILITY("Tactical designator"))
	user.status_flags |= IMMOBILE_ACTION
	update_pixels(TRUE)
	give_action(user, /datum/action/vulture_tripod_unscope, null, null, src)
	to_chat(user, SPAN_NOTICE("Ctrl-click a living target to mark it for direct CAS fire, or a turf for a standard laser signal."))

/obj/structure/vulture_spotter_tripod/tactical/on_unset_interaction(mob/living/user)
	acquisition_serial++
	QDEL_NULL(laser)
	UnregisterSignal(user, list(COMSIG_MOB_PICKUP_ITEM, COMSIG_MOB_RESISTED, COMSIG_MOB_DEATH, COMSIG_LIVING_SET_BODY_POSITION, COMSIG_MOVABLE_MOVED, COMSIG_PARENT_QDELETING))
	if(user.client)
		UnregisterSignal(user.client, COMSIG_PARENT_QDELETING)
		user.client.change_view(GLOB.world_view_size, src)
		user.client.pixel_x = 0
		user.client.pixel_y = 0
	REMOVE_TRAIT(user, TRAIT_IMMOBILIZED, TRAIT_SOURCE_ABILITY("Tactical designator"))
	user.status_flags &= ~IMMOBILE_ACTION
	user.reset_view(null)
	update_pixels(FALSE)
	remove_action(user, /datum/action/vulture_tripod_unscope)
	scope_user = null
	scope_using = FALSE

/obj/structure/vulture_spotter_tripod/tactical/clicked(mob/user, list/mods)
	if(mods[CTRL_CLICK] && scope_user?.resolve() == user)
		acquisition_serial++
		QDEL_NULL(laser)
		return TRUE
	return ..()

/// Restrict marks to the forward optic view and an unobstructed laser path.
/obj/structure/vulture_spotter_tripod/tactical/proc/can_designate(atom/target)
	var/mob/living/user = scope_user?.resolve()
	if(!user || user.interactee != src || user.is_mob_incapacitated() || !user.client || get_turf(user) != loc)
		return FALSE
	if(QDELETED(target) || target.z != z || !is_ground_level(z) || (!isturf(target) && !isturf(target.loc)))
		return FALSE
	var/center_x = x + (dir == EAST ? view_offset : (dir == WEST ? -view_offset : 0))
	var/center_y = y + (dir == NORTH ? view_offset : (dir == SOUTH ? -view_offset : 0))
	if(abs(target.x - center_x) > scope_zoom || abs(target.y - center_y) > scope_zoom || target.invisibility > user.see_invisible)
		return FALSE
	var/turf/target_turf = get_turf(target)
	if(protected_by_pylon(TURF_PROTECTION_CAS, target_turf))
		return FALSE
	if(isliving(target))
		var/mob/living/living_target = target
		if(living_target == user || living_target.stat == DEAD || HAS_TRAIT(living_target, TRAIT_ABILITY_BURROWED) || living_target.is_ventcrawling)
			return FALSE
	for(var/turf/path_turf in get_line(src, target, include_start_atom = FALSE))
		if(path_turf.opacity)
			return FALSE
		for(var/atom/blocker in path_turf)
			if(blocker.opacity)
				return FALSE
	return TRUE

/obj/structure/vulture_spotter_tripod/tactical/handle_click(mob/living/carbon/human/user, atom/targeted_atom, list/mods)
	if(!mods[CTRL_CLICK] || mods[CLICK_CATCHER] || scope_user?.resolve() != user)
		return FALSE
	if(targeted_atom == src)
		acquisition_serial++
		QDEL_NULL(laser)
		return TRUE
	if(!isliving(targeted_atom) && !isturf(targeted_atom))
		return TRUE
	if(acquiring || laser || !can_designate(targeted_atom))
		return TRUE
	acquire_target(targeted_atom, user)
	return TRUE

/obj/structure/vulture_spotter_tripod/tactical/proc/acquire_target(atom/target, mob/living/carbon/human/user)
	set waitfor = FALSE
	acquiring = TRUE
	var/current_acquisition = ++acquisition_serial
	playsound(src, 'sound/effects/nightvision.ogg', 35)
	var/acquired = do_after(user, acquisition_delay, INTERRUPT_ALL, BUSY_ICON_GENERIC, src)
	acquiring = FALSE
	if(!acquired || current_acquisition != acquisition_serial || laser || scope_user?.resolve() != user || !can_designate(target))
		return
	var/laser_name = "[user.assigned_squad ? user.assigned_squad.name : "X"]-[tracking_id]"
	laser = new(get_turf(target), laser_name, user, tracking_id, src, isliving(target) ? target : null)
	playsound(src, 'sound/effects/binoctarget.ogg', 35)
	log_game("Tactical laser [laser_name] designated by [key_name(user)] at ([target.x], [target.y], [target.z]).")
	to_chat(user, SPAN_NOTICE("Target acquired. Keep the target in sight to maintain designation."))

/// The marker stays on turf so the CAS camera and existing signal consumers can use it.
/obj/effect/overlay/temp/laser_target/tactical
	var/obj/structure/vulture_spotter_tripod/tactical/designator
	var/mob/living/marked_target
	var/image/mark_overlay

/obj/effect/overlay/temp/laser_target/tactical/New(loc, squad_name, mob/living/carbon/human/user, tracking_id, obj/structure/vulture_spotter_tripod/tactical/source, mob/living/target)
	..(loc, squad_name, user, tracking_id)
	designator = source
	marked_target = target
	if(signal)
		signal.penetrates_roof = TRUE
		signal.direct_fire_only = !!target
		if(target)
			signal.name += " (direct fire only)"
	if(target)
		mark_overlay = image('icons/effects/Targeted.dmi', icon_state = "spotter_lockon")
		mark_overlay.pixel_x = -target.pixel_x + target.base_pixel_x
		mark_overlay.pixel_y = (target.icon_size - world.icon_size) * 0.5 - target.pixel_y + target.base_pixel_y
		target.overlays += mark_overlay
		RegisterSignal(target, COMSIG_MOVABLE_MOVED, PROC_REF(update_target))
		RegisterSignal(target, list(COMSIG_PARENT_QDELETING, COMSIG_MOB_DEATH), PROC_REF(target_lost))
	START_PROCESSING(SSobj, src)

/obj/effect/overlay/temp/laser_target/tactical/Destroy()
	STOP_PROCESSING(SSobj, src)
	if(marked_target)
		marked_target.overlays -= mark_overlay
		UnregisterSignal(marked_target, list(COMSIG_MOVABLE_MOVED, COMSIG_PARENT_QDELETING, COMSIG_MOB_DEATH))
	marked_target = null
	mark_overlay = null
	if(designator?.laser == src)
		designator.laser = null
	designator = null
	return ..()

/obj/effect/overlay/temp/laser_target/tactical/process()
	update_target()

/obj/effect/overlay/temp/laser_target/tactical/proc/target_lost()
	SIGNAL_HANDLER
	qdel(src)

/obj/effect/overlay/temp/laser_target/tactical/proc/update_target()
	SIGNAL_HANDLER
	if(!designator?.can_designate(marked_target ? marked_target : get_turf(src)))
		qdel(src)
		return
	if(marked_target)
		forceMove(get_turf(marked_target))
		signal?.linked_cam?.forceMove(loc)
