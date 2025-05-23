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
	flags_item = NOBLUDGEON

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
		if(!do_after(user, 10, INTERRUPT_NO_NEEDHAND | BEHAVIOR_IMMOBILE, BUSY_ICON_BUILD))
			return
		src.last_scanned_weapon = W
		playsound(src, 'sound/mecha/lowpower.ogg', 50, 1)
		to_chat(user, SPAN_NOTICE("Repair scan complete. Use the maintenance computer to continue repairs."))
		return
	if(istype(target, /obj/item/device/dropship_comp))
		var/obj/item/device/dropship_comp/comp = target
		if(!in_range(user, comp, 1))
			to_chat(user, SPAN_WARNING("You must be next to the maintenance computer to transfer the data."))
			return
		if(!comp.activated)
			to_chat(user, SPAN_WARNING("The maintenance computer is powered off."))
			return
		if(!src.last_scanned_weapon || !islist(src.last_scanned_weapon.repair_actions) || !length(src.last_scanned_weapon.repair_actions))
			to_chat(user, SPAN_WARNING("No repair scan data found on the handheld device."))
			return
		playsound(src, 'sound/machines/terminal_success.ogg', 50, 1)
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
