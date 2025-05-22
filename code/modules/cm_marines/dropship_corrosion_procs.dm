#define PROCESS_CONTINUE 0

/obj/structure/dropship_equipment/weapon
	var/processing_corrosion = FALSE
	/// Corrosion stacks: list of corrosion info (each is a list with [expiry_time, applier, stack_id])
	var/list/corrosion_stacks = list()
	/// If true, corrosion is being repaired (blocks further repair attempts)
	var/corrosion_repairing = FALSE
	/// If true, corrosion is currently blocking reload
	var/corrosion_block_reload = FALSE
	/// Time (in deciseconds) for a corrosion stack to expire (default 300s)
	var/corrosion_stack_duration = 1800
	/// If true, weapon is destroyed by corrosion
	var/corrosion_destroyed = FALSE
	/// Last time a hive message was sent (for cooldown)
	var/last_hive_corrosion_announce = 0
	/// Last time the alarm sound was played (for cooldown)
	var/last_corrosion_alarm = 0

/obj/structure/dropship_equipment/weapon/proc/spew_spall()
	if(!linked_console) return
	var/turf/cockpit = get_turf(linked_console)
	if(!cockpit) return
	// Offset: 1 tile south, 1 tile west
	var/turf/center = locate(cockpit.x - 1, cockpit.y - 1, cockpit.z)
	if(!center) return
	// 180-degree arc: SOUTH, SOUTHEAST, SOUTHWEST
	// Use shrapnel_direction = SOUTH (5), shrapnel_spread = 90 for 180-degree arc
	create_shrapnel(center, 12, SOUTH, 180, /datum/ammo/bullet/shrapnel/spall)

/obj/structure/dropship_equipment/weapon/proc/apply_corrosion_stack(applier)
	if(src.corrosion_destroyed)
		return
	var/now = world.time
	var/expiry = now + src.corrosion_stack_duration
	var/stack_id = rand(1,999999)
	src.corrosion_stacks += list(list("expiry"=expiry, "applier"=applier, "stack_id"=stack_id))
	src.corrosion_block_reload = TRUE
	// Trigger shrapnel spew in the cockpit if present
	if(linked_console)
		src.spew_spall()
		// Play alarm sound with 2s cooldown
		if((now - src.last_corrosion_alarm) >= 20)
			playsound(linked_console, 'sound/mecha/internaldmgalarm.ogg', 50, 1)
			src.last_corrosion_alarm = now
	// Message to applier if applier is a xeno with a client, and hive message with 5s cooldown
	if(istype(applier, /mob/living/carbon/xenomorph))
		var/mob/living/carbon/xenomorph/user = applier
		if(user && !QDELETED(user) && user.client)
			to_chat(user, SPAN_XENOHIGHDANGER("The metal bird veers off course! It has been injured!"))
		if(user && user.hivenumber && (now - src.last_hive_corrosion_announce) >= 50)
			xeno_message(SPAN_XENOANNOUNCE("The hivemind rumbles. The metal bird has been injured!"), 3, user.hivenumber)
			src.last_hive_corrosion_announce = now
	// Generate repair_actions for this stack
	if(!islist(src.repair_actions))
		src.repair_actions = list()
	var/list/tools = list("welder", "screwdriver", "wrench", "crowbar", "wirecutters")
	var/list/actions = list()
	for(var/i in 1 to 3)
		actions += pick(tools)
	randomize_list(actions)
	src.repair_actions["[stack_id]"] = actions.Copy()
	// Start timer for this stack
	spawn(src.corrosion_stack_duration)
		src.handle_corrosion_stack_expiry(stack_id)

/obj/structure/dropship_equipment/weapon/proc/handle_corrosion_stack_expiry(stack_id)
	if(src.corrosion_destroyed)
		return
	// Find and remove the expired stack
	for(var/i=length(src.corrosion_stacks); i>=1; i--)
		var/stack = src.corrosion_stacks[i]
		if(stack["stack_id"] == stack_id)
			src.corrosion_stacks.Cut(i,i+1)
			break
	// Destroy the weapon and its ammo immediately when any stack expires
	src.corrosion_destroyed = TRUE
	src.corrosion_block_reload = TRUE
	visible_message(SPAN_DANGER("[src] is destroyed by corrosive acid!"))
	if(src.ammo_equipped)
		qdel(src.ammo_equipped)
	playsound(src, 'sound/bullets/acid_impact1.ogg', 50, 1)
	qdel(src)

/obj/structure/dropship_equipment/weapon/proc/clear_corrosion()
	src.corrosion_stacks.Cut()
	src.corrosion_block_reload = FALSE
	src.corrosion_repairing = FALSE

/obj/structure/dropship_equipment/weapon/proc/can_reload()
	if(src.corrosion_block_reload)
		return FALSE
	return TRUE
