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
      topButtons={[
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
                    <h4>Stored Ammo</h4>
                    {Array.isArray(autoreloader.stored_ammo) &&
                    autoreloader.stored_ammo.length > 0 ? (
                      <>
                        {autoreloader.stored_ammo.map((ammo, idx) => (
                          <div key={ammo.ref || idx}>
                            {ammo.name} ({ammo.ammo_count ?? 0}/
                            {ammo.max_ammo_count ?? 0})
                          </div>
                        ))}
                      </>
                    ) : (
                      <div>Empty</div>
                    )}
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
