import { useBackend } from 'tgui/backend';
import { Box, Stack } from 'tgui/components';

import type { DropshipEquipment } from '../DropshipWeaponsConsole';
import { MfdPanel, type MfdProps } from './MultifunctionDisplay';
import { mfdState, useWeaponState } from './stateManagers';
import type { AutoreloaderSpec } from './types';

const EmptyAutoReloaderPanel = () => {
  return <div>Nothing Listed</div>;
};

const AutoReloaderPanel = (props: {
  readonly equipment: DropshipEquipment & Partial<AutoreloaderSpec>;
}) => {
  const { equipment } = props;
  return (
    <Stack>
      <Stack.Item>
        <Box width="300px">
          <Stack vertical className="WeaponsDesc">
            <Stack.Item>
              <h3>{equipment.name}</h3>
            </Stack.Item>
            <Stack.Item>
              <h4>Stored Ammo 1</h4>
              <div>
                {equipment.stored_ammo_1_name
                  ? `${equipment.stored_ammo_1_name} (${equipment.stored_ammo_1_count ?? 0}/${equipment.stored_ammo_1_max ?? 0})`
                  : 'Empty'}
              </div>
            </Stack.Item>
            <Stack.Item>
              <h4>Stored Ammo 2</h4>
              <div>
                {equipment.stored_ammo_2_name
                  ? `${equipment.stored_ammo_2_name} (${equipment.stored_ammo_2_count ?? 0}/${equipment.stored_ammo_2_max ?? 0})`
                  : 'Empty'}
              </div>
            </Stack.Item>
          </Stack>
        </Box>
      </Stack.Item>
    </Stack>
  );
};

export const AutoReloaderMfdPanel = (props: MfdProps) => {
  const { setPanelState } = mfdState(props.panelStateId);
  const { data } = useBackend<{
    equipment_data: Array<DropshipEquipment & Partial<AutoreloaderSpec>>;
  }>();
  const autoreloader = data.equipment_data?.find(
    (eq) => eq.shorthand === 'RMT',
  );

  const { weaponState, setWeaponState } = useWeaponState(props.panelStateId);

  return (
    <MfdPanel
      panelStateId={props.panelStateId}
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
          <AutoReloaderPanel equipment={autoreloader} />
        ) : (
          <EmptyAutoReloaderPanel />
        )}
      </Box>
    </MfdPanel>
  );
};
