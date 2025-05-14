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
	if(!linked_rappel.can_use_rappel(user))
		return
	var/turf/user_turf = get_turf(user)
	if(!user_turf || get_dist(user_turf, src.loc) > 1)
		to_chat(user, SPAN_WARNING("You must be next to the rope to use it."))
		return

	in_use = TRUE
	icon_state = is_hatch_rope ? "hatch_rope" : "rope_inuse"
	to_chat(user, SPAN_NOTICE("You begin climbing the rope..."))

    // Interruptible delay
	if(do_after(user, 40, INTERRUPT_ALL | BEHAVIOR_IMMOBILE, BUSY_ICON_GENERIC, target = src))
		// Move user to the other rope's location (on top of the rope)
		if(is_hatch_rope)
			if(linked_rappel.ground_rope && linked_rappel.ground_rope.loc)
				user.forceMove(linked_rappel.ground_rope.loc)
				user.visible_message(SPAN_NOTICE("[user] rappels down the rope!"))
		else
			if(linked_rappel.hatch_rope && linked_rappel.hatch_rope.loc)
				user.forceMove(linked_rappel.hatch_rope.loc)
				user.visible_message(SPAN_NOTICE("[user] climbs up the rope!"))
	else
		to_chat(user, SPAN_WARNING("You were interrupted and let go of the rope!"))

	in_use = FALSE
	icon_state = is_hatch_rope ? "hatch_rope" : "rope"

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
