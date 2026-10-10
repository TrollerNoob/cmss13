# Tactical laser designator

Based on PR #9293 (FOB Defense Rework). Reuses Vulture tripod sprites,
rotation, operator positioning, and exit action, plus the missile sentry's
`lockon_sensor` incoming-warning sprite.

Spawn `/obj/item/device/vulture_spotter_tripod/tactical` for testing.
Vendor/loadout distribution has not been assigned.

1. Use in hand to deploy. Alt-click to rotate.
2. With empty hands, drag the tripod onto yourself to look ahead.
3. Ctrl-click a living target to create a moving CAS signal labeled
   "direct fire only". Fire missions reject this signal.
4. Direct-fire Widowmaker, Banshee, Keeper, Harpoon, or Napalm ammunition at
   the mark. These have `laser_guided = TRUE`. The target receives a sound,
   chat warning, and tracking overlay during transit.
5. Break line of sight, leave the optic's field of view, enter a container,
   die, burrow, or disengage the tripod to lose the mark. Airborne missiles
   scatter around the last known position and cannot reacquire a new mark.
6. Ctrl-click the tripod to clear a signal. Ctrl-click a turf for a stationary
   standard CAS signal, acquired in two seconds. Both modes work beneath any
   roof; ground-level and pylon restrictions still apply. Existing fire-mission
   damage restrictions remain in effect.
7. Use the stop-scope action or resist to disengage. Use a screwdriver to pack
   up an unoccupied tripod.

Manual checks: all four facings; walls and closed doors; moving targets during
transit; interrupted acquisition; tripod/target deletion; operator disconnect;
simultaneous missiles and warning cleanup; unguided cannon/minirocket/thermobaric
behavior; stationary lasers beneath opaque roofs.

Regression test `/datum/unit_test/tactical_designator_signals` covers roof
penetration, container rejection, and fire-mission restrictions.
