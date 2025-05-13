import { useBackend } from 'tgui/backend';
import { Box, Stack } from 'tgui/components';

import type { DropshipEquipment } from '../DropshipWeaponsConsole';
import { MfdPanel, type MfdProps } from './MultifunctionDisplay';
import { mfdState, useEquipmentState } from './stateManagers';
import type { EquipmentContext } from './types';

const RappelPanel = (props: {
  readonly equipment: DropshipEquipment;
  readonly target: any;
}) => {
  const { equipment, target } = props;
  return (
    <Stack>
      <Stack.Item width="100px">
        <svg />
      </Stack.Item>
      <Stack.Item>
        <Stack vertical width="300px" align="center">
          <Stack.Item>
            <h3>{equipment.name}</h3>
          </Stack.Item>
          <Stack.Item>
            <h3>
              {target
                ? `Locked to ${target.name || target.signal || 'Unknown Target'}.`
                : 'No locked target found.'}
            </h3>
          </Stack.Item>
          <Stack.Item>
            <h3>
              {equipment.data?.locked
                ? 'Rappelling available.'
                : 'Rappelling not available.'}
            </h3>
          </Stack.Item>
        </Stack>
      </Stack.Item>
      <Stack.Item width="100px">
        <svg />
      </Stack.Item>
    </Stack>
  );
};

export const RappelMfdPanel = (props: MfdProps) => {
  const { act, data } = useBackend<EquipmentContext>();
  const { setPanelState } = mfdState(props.panelStateId);
  const { equipmentState } = useEquipmentState(props.panelStateId);
  const rappel = data.equipment_data.find(
    (x) => x.mount_point === equipmentState,
  );
  // Use the first target as the locked target, or null if none
  const target = data.targets_data?.[0] || null;
  const deployLabel = rappel?.data?.locked ? 'CLEAR' : 'LOCK';

  return (
    <MfdPanel
      panelStateId={props.panelStateId}
      topButtons={[
        { children: 'EQUIP', onClick: () => setPanelState('equipment') },
      ]}
      leftButtons={[
        {
          children: deployLabel,
          onClick: () =>
            act('rappel-lock', { equipment_id: rappel?.mount_point }),
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
        {rappel && <RappelPanel equipment={rappel} target={target} />}
      </Box>
    </MfdPanel>
  );
};
