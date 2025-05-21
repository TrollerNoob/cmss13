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
	src.corrosion_stacks += list(list("expiry"=expiry, "applier"=applier, "stack_id"=rand(1,999999)))
	src.corrosion_block_reload = TRUE
	// Trigger shrapnel spew in the cockpit if present
	if(linked_console)
		src.spew_spall()
		// Play alarm sound with 2s cooldown
		if((now - src.last_corrosion_alarm) >= 20)
			playsound(linked_console, 'sound/mecha/internaldmgalarm.ogg', 50, 1)
			src.last_corrosion_alarm = now
	// Message to Boiler if applier is a Boiler xeno
	if(istype(applier, /mob/living/carbon/xenomorph/boiler))
		var/mob/boiler = applier
		if(boiler && !boiler.gc_destroyed && boiler.client)
			to_chat(boiler, SPAN_XENOHIGHDANGER("The metal bird veers off course! It has been injured!"))
	// Hive message with 5s cooldown
	if(istype(applier, /mob/living/carbon/xenomorph))
		var/mob/living/carbon/xenomorph/applier_xeno = applier
		var/mob/mob_xeno = applier_xeno
		if(applier_xeno && mob_xeno && !mob_xeno.gc_destroyed && applier_xeno.hivenumber && (now - src.last_hive_corrosion_announce) >= 50)
			xeno_message(SPAN_XENOANNOUNCE("The hivemind rumbles. The metal bird has been injured!"), 3, applier_xeno.hivenumber)
			src.last_hive_corrosion_announce = now
	// Register for processing if not already
	if(!src.processing_corrosion)
		src.processing_corrosion = TRUE
		START_PROCESSING(SSobj, src)
	// Generate repair_actions for this stack
	if(!islist(src.repair_actions))
		src.repair_actions = list()
	var/stack = src.corrosion_stacks[length(src.corrosion_stacks)]
	var/stack_id = stack["stack_id"]
	var/list/tools = list("welder", "screwdriver", "wrench", "crowbar", "wirecutters")
	var/list/actions = list()
	for(var/i in 1 to 3)
		actions += pick(tools)
	randomize_list(actions)
	src.repair_actions["[stack_id]"] = actions.Copy()

/obj/structure/dropship_equipment/weapon/process(delta_time)
	if(src.corrosion_destroyed)
		STOP_PROCESSING(SSobj, src)
		src.processing_corrosion = FALSE
		return PROCESS_KILL
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
		STOP_PROCESSING(SSobj, src)
		src.processing_corrosion = FALSE
		return PROCESS_KILL
	if(!src.is_corroded())
		src.corrosion_block_reload = FALSE
		STOP_PROCESSING(SSobj, src)
		src.processing_corrosion = FALSE
		return PROCESS_KILL
	return PROCESS_CONTINUE

/obj/structure/dropship_equipment/weapon/proc/clear_corrosion()
	src.corrosion_stacks.Cut()
	src.corrosion_block_reload = FALSE
	src.corrosion_repairing = FALSE
	STOP_PROCESSING(SSobj, src)
	src.processing_corrosion = FALSE

/obj/structure/dropship_equipment/weapon/proc/can_reload()
	if(src.corrosion_block_reload)
		return FALSE
	return TRUE
