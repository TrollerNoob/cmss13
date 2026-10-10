/datum/unit_test/tactical_designator_signals/Run()
	var/obj/marker = allocate(/obj, run_loc_floor_bottom_left)
	var/datum/cas_signal/signal = allocate(/datum/cas_signal, marker)
	var/area/target_area = get_area(marker)
	var/original_ceiling = target_area.ceiling
	target_area.ceiling = CEILING_DEEP_UNDERGROUND_METAL
	var/ordinary_valid = signal.valid_signal()
	signal.penetrates_roof = TRUE
	var/tactical_valid = signal.valid_signal()
	var/tactical_obstructed = signal.obstructed_signal()
	target_area.ceiling = original_ceiling
	TEST_ASSERT(!ordinary_valid, "Ordinary signals should still be blocked by deep roofs")
	TEST_ASSERT(tactical_valid && !tactical_obstructed, "Tactical signals should pass through roofs")
	var/obj/container = allocate(/obj, run_loc_floor_bottom_left)
	marker.forceMove(container)
	TEST_ASSERT(!signal.valid_signal(), "Roof penetration must not allow signals inside containers")
	marker.forceMove(run_loc_floor_bottom_left)
	var/datum/cas_fire_envelope/envelope = allocate(/datum/cas_fire_envelope)
	signal.direct_fire_only = TRUE
	TEST_ASSERT(!envelope.change_target_loc(signal), "Moving marks must not be accepted as fire mission targets")
	TEST_ASSERT_NULL(envelope.recorded_loc, "Rejected marks must not replace the fire mission target")
	TEST_ASSERT_EQUAL(envelope.execute_firemission(signal, run_loc_floor_bottom_left, NORTH, null), FIRE_MISSION_NOT_EXECUTABLE, "Moving marks must be rejected at execution too")
	signal.direct_fire_only = FALSE
	TEST_ASSERT(envelope.change_target_loc(signal), "Stationary tactical lasers must support fire missions")
	TEST_ASSERT_EQUAL(envelope.recorded_loc, signal, "Stationary signals must be recorded")
