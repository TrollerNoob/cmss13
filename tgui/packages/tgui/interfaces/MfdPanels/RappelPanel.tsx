import { range } from 'common/collections';
import React from 'react';
import { useBackend } from 'tgui/backend';
import { Box, Icon, Stack } from 'tgui/components';

import type { DropshipEquipment } from '../DropshipWeaponsConsole';
import { MfdPanel, type MfdProps } from './MultifunctionDisplay';
import { mfdState, useEquipmentState } from './stateManagers';
import { lazeMapper, useTargetOffset } from './TargetAquisition';
import type { EquipmentContext } from './types';

const RappelPanel = (props: { readonly equipment: DropshipEquipment }) => {
  const { equipment } = props;
  const iconState = equipment.icon_state;

  let winchText: React.ReactNode = null;
  if (iconState === 'rappel_hatch_open') {
    winchText = <h3>Rappel winch lowered</h3>;
  } else if (iconState === 'rappel_hatch_closed') {
    winchText = <h3 style={{ color: '#cdae3e' }}>Rappel winch raised</h3>;
  } else {
    winchText = (
      <h3 style={{ color: 'red' }}>Unknown state: {String(iconState)}</h3>
    );
  }

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
              {equipment.data?.locked_target
                ? `Locked to ${equipment.data.locked_target.target_name || 'Unknown Target'}.`
                : 'No locked target found.'}
            </h3>
          </Stack.Item>
          <Stack.Item>{winchText}</Stack.Item>
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
  const { targetOffset, setTargetOffset } = useTargetOffset(props.panelStateId);
  const rappel = data.equipment_data.find(
    (x) => x.mount_point === equipmentState,
  );

  // Use the same targeting system as WeaponPanel
  const targets = range(targetOffset, targetOffset + 5).map((x) =>
    lazeMapper(x),
  );

  return (
    <MfdPanel
      panelStateId={props.panelStateId}
      topButtons={[
        { children: 'EQUIP', onClick: () => setPanelState('equipment') },
        {},
        {},
        {},
        {
          children: targetOffset > 0 ? <Icon name="arrow-up" /> : undefined,
          onClick: () => {
            if (targetOffset > 0) setTargetOffset(targetOffset - 1);
          },
        },
      ]}
      leftButtons={[
        {
          children: 'LOCK',
          onClick: () =>
            act('rappel-lock', {
              equipment_id: rappel?.mount_point,
            }),
        },
        {
          children: 'CANCEL',
          onClick: () =>
            act('rappel-cancel', {
              equipment_id: rappel?.mount_point,
            }),
        },
      ]}
      rightButtons={targets}
      bottomButtons={[
        {
          children: 'EXIT',
          onClick: () => setPanelState(''),
        },
        {},
        {},
        {},
        {
          children:
            targetOffset + 5 < (data.targets_data?.length || 0) ? (
              <Icon name="arrow-down" />
            ) : undefined,
          onClick: () => {
            if (targetOffset + 5 < (data.targets_data?.length || 0)) {
              setTargetOffset(targetOffset + 1);
            }
          },
        },
      ]}
    >
      <Box className="NavigationMenu">
        {rappel && <RappelPanel equipment={rappel} />}
      </Box>
    </MfdPanel>
  );
};
