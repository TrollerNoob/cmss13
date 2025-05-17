/obj/structure/dropship_equipment/weapon/proc/apply_corrosion_stack(applier)
	if(src.corrosion_destroyed)
		return
	var/now = world.time
	var/expiry = now + src.corrosion_stack_duration
	src.corrosion_stacks += list(list("expiry"=expiry, "applier"=applier, "stack_id"=rand(1,999999)))
	src.corrosion_block_reload = TRUE
	src.process_corrosion()
	src.update_icon()

/obj/structure/dropship_equipment/weapon/proc/is_corroded()
	return length(src.corrosion_stacks) > 0 && !src.corrosion_destroyed

/obj/structure/dropship_equipment/weapon/proc/process_corrosion()
	if(src.corrosion_destroyed)
		return
	var/now = world.time
	var/expired = FALSE
	for(var/i=length(src.corrosion_stacks); i>=1; i--)
		var/stack = src.corrosion_stacks[i]
		if(stack["expiry"] <= now)
			expired = TRUE
			src.corrosion_stacks.Cut(i,i+1)
	if(expired && !src.corrosion_repairing)
		src.corrosion_destroyed = TRUE
		src.corrosion_block_reload = TRUE
		visible_message(SPAN_DANGER("[src] is destroyed by corrosive acid!"))
		if(src.ammo_equipped)
			qdel(src.ammo_equipped)
		qdel(src)
		return
	if(!src.is_corroded())
		src.corrosion_block_reload = FALSE
	src.update_icon()

/obj/structure/dropship_equipment/weapon/proc/clear_corrosion()
	src.corrosion_stacks.Cut()
	src.corrosion_block_reload = FALSE
	src.corrosion_repairing = FALSE
	src.update_icon()

/obj/structure/dropship_equipment/weapon/proc/can_reload()
	if(src.corrosion_block_reload)
		return FALSE
	return TRUE
