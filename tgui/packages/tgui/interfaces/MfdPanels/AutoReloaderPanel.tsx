import { useBackend } from 'tgui/backend';
import { Box, Button, Flex, Section } from 'tgui/components';
import { Table, TableCell, TableRow } from 'tgui/components/Table';

import { MfdPanel, type MfdProps } from './MultifunctionDisplay';
import type { AutoreloaderSpec } from './types';

export const AutoReloaderPanel = (props: MfdProps) => {
  const { data, act } = useBackend<{
    stored_ammo: Array<{ name: string; count: number; max_count: number }>;
    cooldown: number;
    equipment_data: Array<AutoreloaderSpec>;
  }>();

  const { stored_ammo, cooldown, equipment_data } = data;

  const weapons = equipment_data
    .filter((x) => x.uses_ammo && !x.ammo_equipped)
    .sort((a, b) => a.mount_point - b.mount_point);

  return (
    <MfdPanel
      panelStateId={props.panelStateId}
      bottomButtons={[
        {
          children: 'EXIT',
          onClick: () => act('exit'),
        },
      ]}
    >
      <Section title="Stored Ammo">
        <Table>
          <TableRow header>
            <TableCell>Ammo Name</TableCell>
            <TableCell>Count</TableCell>
          </TableRow>
          {stored_ammo.map((ammo, index) => (
            <TableRow key={index}>
              <TableCell>{ammo.name}</TableCell>
              <TableCell>
                {ammo.count}/{ammo.max_count}
              </TableCell>
            </TableRow>
          ))}
        </Table>
      </Section>

      <Section title="Reload Weapon">
        {cooldown > 0 ? (
          <Box color="yellow" mb={1}>
            Reloading... {cooldown} seconds remaining.
          </Box>
        ) : (
          <Box color="green" mb={1}>
            Ready to reload.
          </Box>
        )}
        <Flex direction="column" gap={1}>
          {weapons.map((weapon) => (
            <Button
              key={weapon.mount_point}
              onClick={() =>
                act('reload_weapon', { mount_point: weapon.mount_point })
              }
              disabled={cooldown > 0}
            >
              Reload {weapon.name} (Mount Point: {weapon.mount_point})
            </Button>
          ))}
        </Flex>
      </Section>
    </MfdPanel>
  );
};
