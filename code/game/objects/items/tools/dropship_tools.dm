// Tools for Dropship Maintenance //

/obj/item/tool/dropship_handheld
	name = "small handheld"
	desc = "A small piece of electronic doodads"
	icon_state = "handheld1"
	w_class = SIZE_SMALL
	var/list/repair_actions = null

/obj/item/tool/dropship_handheld/afterattack(atom/target, mob/user, proximity)
	if(!proximity || !istype(target, /obj/structure/dropship_equipment/weapon))
		return
	var/obj/structure/dropship_equipment/weapon/W = target
	if(!W.is_corroded())
		to_chat(user, SPAN_NOTICE("[W] does not appear to be corroded."))
		return
	// Generate repair actions (3 per stack, random order)
	var/stack_count = length(W.corrosion_stacks)
	if(!stack_count)
		to_chat(user, SPAN_NOTICE("No corrosion detected."))
		return
	var/list/tools = list("welder", "screwdriver", "multitool", "wrench", "crowbar", "wirecutters")
	var/list/actions = list()
	for(var/i in 1 to stack_count * 3)
		actions += pick(tools)
	randomize_list(actions)
	repair_actions = actions.Copy()
	to_chat(user, SPAN_NOTICE("Repair scan complete. Use the maintenance computer to continue repairs."))

/obj/item/tool/dropship_comp_closed
	name = "dropship maintenance computer"
	desc = "A closed dropship maintenance computer that technicians and pilots use to find out what's wrong with a dropship. It has various outlets for different systems."
	icon_state = "hangar_comp"
	w_class = SIZE_LARGE

/obj/item/tool/dropship_comp_closed/attack_self(mob/user)
	var/obj/item/tool/dropship_comp_open/opened = new /obj/item/tool/dropship_comp_open(get_turf(src))
	user.put_in_hands(opened)
	qdel(src)
	to_chat(user, SPAN_NOTICE("You open the dropship maintenance computer."))

/obj/item/tool/dropship_comp_open
	name = "dropship maintenance computer"
	desc = "An opened dropship maintenance computer, it seems to be off however. It's used by technicians and pilots to find damaged or broken systems on a dropship. It has various outlets for different systems."
	icon_state = "hangar_comp_open"
	w_class = SIZE_LARGE

/obj/item/tool/dropship_comp_open/afterattack(atom/target, mob/user, proximity)
	if(!proximity || !istype(target, /obj/item/tool/dropship_handheld))
		return
	var/obj/item/tool/dropship_handheld/handheld = target
	if(!islist(handheld.repair_actions) || !handheld.repair_actions.len)
		to_chat(user, SPAN_WARNING("No repair scan data found on the handheld device."))
		return
	// Display the repair steps to the user
	to_chat(user, SPAN_NOTICE("Repair steps required:"))
	for(var/i in 1 to handheld.repair_actions.len)
		to_chat(user, SPAN_NOTICE("Step [i]: [handheld.repair_actions[i]]"))

// Utility: Fisher-Yates shuffle for lists
/proc/randomize_list(list/L)
	if(!islist(L) || L.len < 2)
		return
	for(var/i = L.len, i > 1, i--)
		var/j = rand(1, i)
		if(i != j)
			var/temp = L[i]
			L[i] = L[j]
			L[j] = temp

