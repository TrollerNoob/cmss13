// dropship maintenance //

// Tools for Dropship Maintenance //

/obj/item/device/dropship_handheld
	name = "small handheld"
	desc = "A small piece of electronic doodads"
	icon_state = "geiger_on"
	item_state = "geiger_on"
	pickup_sound = 'sound/handling/wrench_pickup.ogg'
	drop_sound = 'sound/handling/wrench_drop.ogg'
	flags_atom = FPRINT|CONDUCT
	flags_equip_slot = SLOT_WAIST
	w_class = SIZE_SMALL
	var/list/repair_actions = null
	var/current_repair_step = null
	var/obj/structure/dropship_equipment/weapon/last_scanned_weapon = null

/obj/item/device/dropship_handheld/afterattack(atom/target, mob/user, proximity)
	if(istype(target, /obj/structure/dropship_equipment/weapon))
		var/obj/structure/dropship_equipment/weapon/W = target
		if(!W.is_corroded())
			to_chat(user, SPAN_NOTICE("[W] does not appear to be corroded."))
			return
		if(!length(W.corrosion_stacks))
			to_chat(user, SPAN_NOTICE("No corrosion detected."))
			return
		if(!islist(W.repair_actions) || !length(W.repair_actions))
			to_chat(user, SPAN_WARNING("No repair data found. Try damaging the weapon again."))
			return
		// Store a reference to the weapon for later use with the comp
		src.last_scanned_weapon = W
		to_chat(user, SPAN_NOTICE("Repair scan complete. Use the maintenance computer to continue repairs."))
		return
	if(istype(target, /obj/item/device/dropship_comp))
		var/obj/item/device/dropship_comp/comp = target
		if(!comp.activated)
			to_chat(user, SPAN_WARNING("The maintenance computer is powered off."))
			return
		if(!src.last_scanned_weapon || !islist(src.last_scanned_weapon.repair_actions) || !length(src.last_scanned_weapon.repair_actions))
			to_chat(user, SPAN_WARNING("No repair scan data found on the handheld device."))
			return
		to_chat(user, SPAN_NOTICE("Repair steps required for each corrosion stack:"))
		for(var/stack in src.last_scanned_weapon.corrosion_stacks)
			var/stack_id = stack["stack_id"]
			var/list/actions = src.last_scanned_weapon.repair_actions["[stack_id]"]
			if(actions && length(actions))
				to_chat(user, SPAN_NOTICE("Malfunction #[stack_id]: [actions.Join(", ")]."))
		return

/obj/item/device/dropship_comp
	name = "dropship maintenance computer"
	desc = "A dropship maintenance computer that technicians and pilots use to find out what's wrong with a dropship. It has various outlets for different systems."
	icon_state = "hangar_comp"
	icon = 'icons/obj/structures/props/almayer/almayer_props.dmi'
	w_class = SIZE_LARGE
	var/activated = FALSE

/obj/item/device/dropship_comp/attack_self(mob/user)
	if(!activated)
		activated = TRUE
		icon_state = "hangar_comp_open"
		to_chat(user, SPAN_NOTICE("You power on the dropship maintenance computer."))
	else
		activated = FALSE
		icon_state = "hangar_comp"
		to_chat(user, SPAN_NOTICE("You power off the dropship maintenance computer."))

/obj/item/device/dropship_comp/afterattack(atom/target, mob/user, proximity)
	if(!activated)
		to_chat(user, SPAN_WARNING("The maintenance computer is powered off."))
		return
	if(!proximity || !istype(target, /obj/item/device/dropship_handheld))
		return
	var/obj/item/device/dropship_handheld/handheld = target
	if(!islist(handheld.repair_actions) || !handheld.repair_actions.len)
		to_chat(user, SPAN_WARNING("No repair scan data found on the handheld device."))
		return
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

// Tool mapping for dropship repairs
var/global/list/dropship_repair_tool_types = list(
	"welder" = /obj/item/tool/weldingtool,
	"screwdriver" = /obj/item/tool/screwdriver,
	"wrench" = /obj/item/tool/wrench,
	"wirecutters" = /obj/item/tool/wirecutters,
	"crowbar" = /obj/item/tool/crowbar
)

/proc/get_dropship_repair_tool_type(action)
	return dropship_repair_tool_types[action]
