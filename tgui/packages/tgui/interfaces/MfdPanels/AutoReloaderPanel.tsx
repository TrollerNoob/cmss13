import { useBackend } from 'tgui/backend';
import { Box, Stack } from 'tgui/components';

import type { DropshipEquipment } from '../DropshipWeaponsConsole';
import { MfdPanel, type MfdProps } from './MultifunctionDisplay';
import { mfdState } from './stateManagers';
import type { AutoreloaderSpec } from './types';

export const AutoReloaderMfdPanel = (props: MfdProps) => {
  const { setPanelState } = mfdState(props.panelStateId);
  const { data, act } = useBackend<{
    equipment_data: Array<DropshipEquipment & Partial<AutoreloaderSpec>>;
    selected_weapon?: number | string;
  }>();
  const autoreloader = data.equipment_data?.find(
    (eq) => eq.shorthand === 'RMT',
  );
  const weapons = data.equipment_data?.filter((eq) => eq.is_weapon);

  // Use selected_weapon from backend if present
  const selectedWeapon = weapons?.find(
    (w) => w.eqp_tag === data.selected_weapon,
  );

  return (
    <MfdPanel
      panelStateId={props.panelStateId}
      leftButtons={weapons?.map((weap) => ({
        children: weap.name,
        onClick: () => act('select-ammo', { eqp_tag: weap.eqp_tag }),
      }))}
      rightButtons={[
        {
          children: 'EQUIP',
          onClick: () => setPanelState('equipment'),
        },
      ]}
      bottomButtons={[
        {
          children: 'EXIT',
          onClick: () => setPanelState(''),
        },
      ]}
    >
      <Box className="NavigationMenu">
        {autoreloader ? (
          <Stack>
            <Stack.Item>
              <Box width="300px">
                <Stack vertical className="WeaponsDesc">
                  <Stack.Item>
                    <h3>{autoreloader.name}</h3>
                  </Stack.Item>
                  <Stack.Item>
                    <h4>Stored Ammo 1</h4>
                    <div>
                      {autoreloader.stored_ammo_1_name
                        ? `${autoreloader.stored_ammo_1_name} (${autoreloader.stored_ammo_1_count ?? 0}/${autoreloader.stored_ammo_1_max ?? 0})`
                        : 'Empty'}
                    </div>
                  </Stack.Item>
                  <Stack.Item>
                    <h4>Stored Ammo 2</h4>
                    <div>
                      {autoreloader.stored_ammo_2_name
                        ? `${autoreloader.stored_ammo_2_name} (${autoreloader.stored_ammo_2_count ?? 0}/${autoreloader.stored_ammo_2_max ?? 0})`
                        : 'Empty'}
                    </div>
                  </Stack.Item>
                  {selectedWeapon && (
                    <Stack.Item>
                      <h4>Selected Weapon</h4>
                      <div>{selectedWeapon.name}</div>
                    </Stack.Item>
                  )}
                </Stack>
              </Box>
            </Stack.Item>
          </Stack>
        ) : (
          <div>Nothing Listed</div>
        )}
      </Box>
    </MfdPanel>
  );
};
