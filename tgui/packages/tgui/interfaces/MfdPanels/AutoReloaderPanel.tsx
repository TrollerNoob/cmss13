import { useBackend } from 'tgui/backend';
import { Box, Flex, Stack } from 'tgui/components';

import { MfdPanel, type MfdProps } from './MultifunctionDisplay';
import { mfdState, useEquipmentState } from './stateManagers';
import type { AutoreloaderSpec } from './types';

export const AutoReloaderPanel = (props: MfdProps) => {
  const { act, data } = useBackend<{
    stored_ammo: Array<{ name: string; count: number; max_count: number }>;
    cooldown: number;
    equipment_data: Array<AutoreloaderSpec>;
  }>();

  const { setPanelState } = mfdState(props.panelStateId);
  const { equipmentState } = useEquipmentState(props.panelStateId);

  // Find the autoreloader in the equipment data
  const autoreloader = data.equipment_data.find(
    (x) => x.mount_point === equipmentState,
  );

  // Handle case where autoreloader is not found
  if (!autoreloader) {
    return (
      <MfdPanel
        panelStateId={props.panelStateId}
        bottomButtons={[
          {
            children: 'EXIT',
            onClick: () => setPanelState(''),
          },
        ]}
      >
        <Box color="red" textAlign="center">
          <h3>Autoreloader not found!</h3>
          <p>Please ensure the equipment is properly installed.</p>
        </Box>
      </MfdPanel>
    );
  }

  const { stored_ammo = [], cooldown = 0 } = data;

  // Filter weapons that use ammo and are not already loaded
  const weapons = data.equipment_data
    .filter((x) => x.uses_ammo && !x.ammo_equipped)
    .sort((a, b) => a.mount_point - b.mount_point);

  return (
    <MfdPanel
      panelStateId={props.panelStateId}
      topButtons={[
        { children: 'EQUIP', onClick: () => setPanelState('equipment') },
      ]}
      bottomButtons={[
        {
          children: 'EXIT',
          onClick: () => setPanelState(''),
        },
      ]}
    >
      <Box className="NavigationMenu">
        <Flex justify="space-between">
          {/* Left Section: Stored Ammo */}
          <Flex.Item>
            <Stack vertical align="center">
              <Stack.Item>
                <h3>Stored Ammo</h3>
              </Stack.Item>
              {stored_ammo.length > 0 ? (
                stored_ammo.map((ammo, index) => (
                  <Stack.Item key={index}>
                    <Box>
                      {ammo.name}: {ammo.count}/{ammo.max_count}
                    </Box>
                  </Stack.Item>
                ))
              ) : (
                <Stack.Item>
                  <Box>No ammo stored</Box>
                </Stack.Item>
              )}
            </Stack>
          </Flex.Item>

          {/* Center Section: Cooldown */}
          <Flex.Item>
            <Stack vertical align="center">
              <Stack.Item>
                <h3>Status</h3>
              </Stack.Item>
              <Stack.Item>
                {cooldown > 0 ? (
                  <Box color="yellow">Reloading... {cooldown} seconds</Box>
                ) : (
                  <Box color="green">Ready to reload</Box>
                )}
              </Stack.Item>
            </Stack>
          </Flex.Item>

          {/* Right Section: Weapons */}
          <Flex.Item>
            <Stack vertical align="center">
              <Stack.Item>
                <h3>Weapons</h3>
              </Stack.Item>
              {weapons.length > 0 ? (
                weapons.map((weapon) => (
                  <Stack.Item key={weapon.mount_point}>
                    <Box>
                      <button
                        onClick={() =>
                          act('reload_weapon', {
                            mount_point: weapon.mount_point,
                          })
                        }
                        disabled={cooldown > 0}
                      >
                        Reload {weapon.name} (Mount Point: {weapon.mount_point})
                      </button>
                    </Box>
                  </Stack.Item>
                ))
              ) : (
                <Stack.Item>
                  <Box>No weapons available</Box>
                </Stack.Item>
              )}
            </Stack>
          </Flex.Item>
        </Flex>
      </Box>
    </MfdPanel>
  );
};
