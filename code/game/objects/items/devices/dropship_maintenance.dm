// dropship maintenance //

// Tools for Dropship Maintenance //

/obj/item/device/dropship_handheld
	name = "Aircraft Maintenance Tuner"
	desc = "A small handheld used by technicians and pilots when repairing dropships. It can scan for both external and internal damage, allowing the data to be transferred to a maintenance computer for further analysis."
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
		if(!length(W.antiair_effects))
			to_chat(user, SPAN_NOTICE("[W] does not appear to be damaged."))
			return
		var found = FALSE
		for(var/datum/dropship_antiair/effect in W.antiair_effects)
			if(effect && length(effect.repair_steps))
				found = TRUE
		if(!found)
			to_chat(user, SPAN_NOTICE("No repairable malfunctions detected."))
			return
		if(!do_after(user, 10, INTERRUPT_NO_NEEDHAND | BEHAVIOR_IMMOBILE, BUSY_ICON_BUILD))
			return
		src.last_scanned_weapon = W
		playsound(src, 'sound/mecha/lowpower.ogg', 50, 1)
		to_chat(user, SPAN_NOTICE("Repair scan complete. Use the maintenance computer to continue repairs."))
		return
	if(istype(target, /obj/item/device/dropship_computer))
		var/obj/item/device/dropship_computer/comp = target
		if(!in_range(user, comp, 1))
			to_chat(user, SPAN_WARNING("You must be next to the maintenance computer to transfer the data."))
			return
		if(!src.last_scanned_weapon || !length(src.last_scanned_weapon.antiair_effects))
			to_chat(user, SPAN_WARNING("No repair scan data found on the handheld device."))
			return
		playsound(src, 'sound/machines/terminal_success.ogg', 50, 1)
		to_chat(user, SPAN_NOTICE("Repair steps required for each malfunction:"))
		for(var/datum/dropship_antiair/effect in src.last_scanned_weapon.antiair_effects)
			if(effect && length(effect.repair_steps))
				var/effect_name = effect.name ? effect.name : "Unknown Effect"
				to_chat(user, SPAN_NOTICE("[effect_name]: [islist(effect.repair_steps) ? effect.repair_steps.Join(", ") : "No steps"]."))
		return

/obj/item/device/dropship_computer
	name = "dropship maintenance computer"
	desc = "A dropship maintenance computer that technicians and pilots use to find out what's wrong with a dropship. It has various outlets for different systems."
	icon_state = "dropshipcomp_cl"
	icon = 'icons/obj/structures/props/dropshipcomp.dmi'
	w_class = SIZE_LARGE
	has_special_table_placement = TRUE
	var/open = FALSE
	var/on = FALSE
	var/obj/item/cell/cell
	var/cell_type = /obj/item/cell/super
	var/obj/item/device/dropship_handheld/linked_handheld = null
	var/screen_state = 0
	var/is_linked = FALSE // True if a handheld is linked, False otherwise

/obj/item/device/dropship_computer/Initialize(mapload)
	. = ..()
	if(cell_type)
		cell = new cell_type()
		cell.charge = cell.maxcharge

/obj/item/device/dropship_computer/Destroy()
	. = ..()
	QDEL_NULL(cell)

/obj/item/device/dropship_computer/Move(NewLoc, direct)
	..()
	if(table_setup || open || on)
		teardown()

/obj/item/device/dropship_computer/attack_hand(mob/user)
	if(!table_setup)
		return ..()
	if(!on)
		icon_state = "dropshipcomp_on"
		on = TRUE
		START_PROCESSING(SSobj, src)
		playsound(src, 'sound/machines/terminal_on.ogg', 25, FALSE)
	else
		tgui_interact(user)

/obj/item/device/dropship_computer/attackby(obj/item/object, mob/user)
	if(istype(object, /obj/item/device/dropship_handheld))
		var/obj/item/device/dropship_handheld/handheld = object
		if(linked_handheld == handheld)
			to_chat(user, SPAN_NOTICE("Handheld already linked."))
			return
		linked_handheld = handheld
		is_linked = TRUE
		to_chat(user, SPAN_NOTICE("Handheld device linked to maintenance computer."))
		playsound(src, 'sound/machines/terminal_success.ogg', 50, 1)
	else
		..()

/obj/item/device/dropship_computer/get_examine_text()
	. = ..()
	if(cell)
		. += "A [cell.name] is loaded. It has [cell.charge]/[cell.maxcharge] charge remaining."
	else
		. += "It has no battery inserted."

	if(table_setup)
		. += "The computer can be dragged towards you to pick it up."
	else
		. += "The computer must be placed on a table to be used."

/obj/item/device/dropship_computer/proc/unlink_handheld()
	linked_handheld = null
	is_linked = FALSE

/obj/item/device/dropship_computer/teardown()
	. = ..()
	open = FALSE
	on = FALSE
	icon_state = "dropshipcomp_cl"
	playsound(src, 'sound/machines/terminal_off.ogg', 25, FALSE)
	STOP_PROCESSING(SSobj, src)
	unlink_handheld()

/obj/item/device/dropship_computer/proc/power_on()
	if(open && !on)
		on = TRUE
		icon_state = "dropshipcomp_on"
		playsound(src, 'sound/machines/terminal_on.ogg', 25, FALSE)

/obj/item/device/dropship_computer/afterattack(atom/target, mob/user, proximity)
	if(!on)
		to_chat(user, SPAN_WARNING("The maintenance computer is powered off."))
		return
	if(!proximity || !istype(target, /obj/item/device/dropship_handheld))
		return
	// Only allow linking, not repair transfer here

/obj/item/device/dropship_handheld/proc/get_repair_data()
	if(!src.last_scanned_weapon || !islist(src.last_scanned_weapon.antiair_effects) || !length(src.last_scanned_weapon.antiair_effects))
		return null
	var/list/repair_info = list()
	var/mount_point = src.last_scanned_weapon.ship_base?.attach_id
	for(var/datum/dropship_antiair/effect as anything in src.last_scanned_weapon.antiair_effects)
		if(!islist(effect.repair_steps) || !length(effect.repair_steps))
			continue
		// Use a unique id for each effect instance (should be set on the datum)
		var/effect_id = effect.effect_id ? effect.effect_id : "[effect.type]-[effect.creation_time ? effect.creation_time : world.time]"
		var/effect_name = effect.name ? effect.name : "Unknown Effect"
		repair_info += list(list("id" = "[effect_name] #[effect_id]", "steps" = effect.repair_steps, "mount_point" = mount_point))
	return repair_info

/obj/item/device/dropship_computer/tgui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "DropshipMaintenanceUI", name)
		ui.open()

/obj/item/device/dropship_computer/ui_data(mob/user)
	. = list()
	var/obj/item/device/dropship_handheld/handheld = linked_handheld
	var/list/repair_list = handheld ? handheld.get_repair_data() : list()
	. ["repair_list"] = is_linked ? repair_list : list()
	. ["screen_state"] = screen_state

/obj/item/device/dropship_computer/ui_static_data(mob/user)
	. = list()
	. ["screen_state"] = screen_state

/obj/item/device/dropship_computer/ui_status(mob/user, datum/ui_state/state)
	. = ..()
	if(!on)
		return UI_CLOSE
	if(!skillcheck(user, SKILL_PILOT, SKILL_PILOT_TRAINED))
		return UI_UPDATE

/obj/item/device/dropship_computer/ui_close(mob/user)
	SEND_SIGNAL(src, COMSIG_CAMERA_UNREGISTER_UI, user)

/obj/item/device/dropship_computer/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	switch(action)
		if("screen-state")
			screen_state = params["state"]
			return FALSE

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
	"crowbar" = /obj/item/tool/crowbar,
	"multitool" = /obj/item/device/multitool,
	"cable coil" = /obj/item/stack/cable_coil,
)

/proc/get_dropship_repair_tool_type(action)
	return dropship_repair_tool_types[action]
