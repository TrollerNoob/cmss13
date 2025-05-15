/obj/effect/rappel_rope
	name = "rope"
	icon = 'icons/obj/structures/props/dropship/dropship_equipment.dmi'
	icon_state = "rope"
	layer = ABOVE_LYING_MOB_LAYER
	mouse_opacity = MOUSE_OPACITY_ICON
	anchored = TRUE
	unacidable = TRUE
	var/obj/structure/dropship_equipment/rappel_system/linked_rappel = null
	var/is_hatch_rope = FALSE // true if this is the hatch rope


/obj/effect/rappel_rope/Initialize(mapload, ...)
	. = ..()

/obj/effect/rappel_rope/proc/handle_animation()
	if(is_hatch_rope)
		icon_state = "hatch_rope"
	else
		flick("rope_deploy", src)
		// After 2 seconds (animation length), set icon_state to "rope"
		addtimer(CALLBACK(src, PROC_REF(set_icon_state), "rope"), 2 SECONDS)

/obj/effect/rappel_rope/proc/handle_animation_end()
	icon_state = "rope"

/obj/effect/rappel_rope/attack_hand(mob/living/carbon/human/user)
	if(in_use)
		to_chat(user, SPAN_WARNING("The rope is currently in use!"))
		return
	if(!linked_rappel)
		return

	// Only allow humans
	if(!istype(user, /mob/living/carbon/human))
		to_chat(user, SPAN_WARNING("You can't figure out how to use the rope."))
		return

	if(!linked_rappel.can_use_rappel(user))
		return
	var/turf/user_turf = get_turf(user)
	if(!user_turf || get_dist(user_turf, src.loc) > 1)
		to_chat(user, SPAN_WARNING("You must be next to the rope to use it."))
		return

	in_use = TRUE
	icon_state = is_hatch_rope ? "hatch_rope" : "rope_inuse"
	if(is_hatch_rope && linked_rappel.ground_ropes && length(linked_rappel.ground_ropes))
		for(var/obj/effect/rappel_rope/ground_rope in linked_rappel.ground_ropes)
			ground_rope.icon_state = "rope_inuse"
	to_chat(user, SPAN_NOTICE("You begin climbing the rope..."))

	var/do_after_time = 40

	var/success = do_after(user, do_after_time, INTERRUPT_ALL | BEHAVIOR_IMMOBILE, BUSY_ICON_GENERIC, target = src)
	if(success)
		if(is_hatch_rope)
			if(linked_rappel.ground_ropes && length(linked_rappel.ground_ropes))
				var/obj/effect/rappel_rope/target_rope = pick(linked_rappel.ground_ropes)
				if(target_rope && target_rope.loc)
					user.forceMove(target_rope.loc)
					user.visible_message(SPAN_NOTICE("[user] rappels down the rope!"))
			else
				if(linked_rappel.hatch_rope && linked_rappel.hatch_rope.loc)
					user.forceMove(linked_rappel.hatch_rope.loc)
					user.visible_message(SPAN_NOTICE("[user] tried to climb down, but there was no rope!"))
		else
			if(linked_rappel.hatch_rope && linked_rappel.hatch_rope.loc)
				user.forceMove(linked_rappel.hatch_rope.loc)
				user.visible_message(SPAN_NOTICE("[user] climbs up the rope!"))
	else
		to_chat(user, SPAN_WARNING("You were interrupted and let go of the rope!"))

	in_use = FALSE
	icon_state = is_hatch_rope ? "hatch_rope" : "rope"
	if(is_hatch_rope && linked_rappel.ground_ropes && length(linked_rappel.ground_ropes))
		for(var/obj/effect/rappel_rope/ground_rope in linked_rappel.ground_ropes)
			ground_rope.icon_state = "rope"

/obj/effect/rappel_rope/proc/set_icon_state(state)
	icon_state = state

/obj/effect/rappel_rope/proc/release_rope()
	in_use = FALSE
	icon_state = is_hatch_rope ? "hatch_rope" : "rope"

/obj/effect/rappel_rope/Destroy()
	flick("rope_up", src)
	spawn(5)
		..()
	return QDEL_HINT_IWILLGC

/obj/effect/rappel_rope/New(loc, is_hatch = FALSE)
	is_hatch_rope = is_hatch
	..()
	if(is_hatch_rope)
		icon_state = "hatch_rope"
	else
		icon_state = "rope"
		flick("rope_deploy", src)
		spawn(20)
			icon_state = "rope"

/obj/effect/rappel_rope/attack_alien(mob/living/carbon/xenomorph/user)
	if(in_use)
		to_chat(user, SPAN_WARNING("The rope is currently in use!"))
		return XENO_NO_DELAY_ACTION
	if(!linked_rappel)
		return XENO_NO_DELAY_ACTION

	if(!user.can_ventcrawl())
		to_chat(user, SPAN_WARNING("You're too large to pull yourself up the rope!"))
		return XENO_NO_DELAY_ACTION

	var/turf/user_turf = get_turf(user)
	if(!user_turf || get_dist(user_turf, src.loc) > 1)
		to_chat(user, SPAN_WARNING("You must be next to the rope to use it."))
		return XENO_NO_DELAY_ACTION

	in_use = TRUE
	icon_state = is_hatch_rope ? "hatch_rope" : "rope_inuse"
	if(is_hatch_rope && linked_rappel.ground_ropes && length(linked_rappel.ground_ropes))
		for(var/obj/effect/rappel_rope/ground_rope in linked_rappel.ground_ropes)
			ground_rope.icon_state = "rope_inuse"
	to_chat(user, SPAN_NOTICE("You begin climbing the rope..."))

	var/do_after_time = 30 // 3 seconds for xenos

	var/success = do_after(user, do_after_time, INTERRUPT_ALL | BEHAVIOR_IMMOBILE, BUSY_ICON_GENERIC, target = src)
	if(success)
		if(is_hatch_rope)
			if(linked_rappel.ground_ropes && length(linked_rappel.ground_ropes))
				var/obj/effect/rappel_rope/target_rope = pick(linked_rappel.ground_ropes)
				if(target_rope && target_rope.loc)
					user.forceMove(target_rope.loc)
					user.visible_message(SPAN_NOTICE("[user] swiftly scales down the rope!"))
			else
				if(linked_rappel.hatch_rope && linked_rappel.hatch_rope.loc)
					user.forceMove(linked_rappel.hatch_rope.loc)
					user.visible_message(SPAN_NOTICE("[user] tried to crawl down, but there was no rope!"))
		else
			if(linked_rappel.hatch_rope && linked_rappel.hatch_rope.loc)
				user.forceMove(linked_rappel.hatch_rope.loc)
				user.visible_message(SPAN_NOTICE("[user] climbs up the rope!"))
	else
		to_chat(user, SPAN_WARNING("You were interrupted and let go of the rope!"))

	in_use = FALSE
	icon_state = is_hatch_rope ? "hatch_rope" : "rope"
	if(is_hatch_rope && linked_rappel.ground_ropes && length(linked_rappel.ground_ropes))
		for(var/obj/effect/rappel_rope/ground_rope in linked_rappel.ground_ropes)
			ground_rope.icon_state = "rope"

	return XENO_NONCOMBAT_ACTION
