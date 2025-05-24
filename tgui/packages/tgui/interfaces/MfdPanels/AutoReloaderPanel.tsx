import { useState } from 'react';
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

  // Local state for which weapon is being selected for ammo
  const [pendingWeapon, setPendingWeapon] = useState<number | undefined>(
    undefined,
  );

  // Use selected_weapon from backend if present
  const selectedWeapon = weapons?.find(
    (w) => w.eqp_tag === data.selected_weapon,
  );

  // Handler for weapon button click
  const handleWeaponClick = (eqp_tag: number) => {
    setPendingWeapon(eqp_tag);
  };

  // Handler for ammo button click
  const handleAmmoClick = (ammoRef: string) => {
    if (pendingWeapon !== undefined) {
      act('select-ammo', { eqp_tag: pendingWeapon, ammo_ref: ammoRef });
      setPendingWeapon(undefined);
    }
  };

  // Handler to cancel ammo selection
  const handleCancel = () => {
    setPendingWeapon(undefined);
  };

  // Build left buttons: weapon selection or ammo selection
  const leftButtons =
    pendingWeapon === undefined
      ? weapons?.map((weap) => ({
          children: weap.name,
          onClick: () => handleWeaponClick(weap.eqp_tag),
        }))
      : [
          ...(autoreloader?.stored_ammo?.map((ammo, idx) => ({
            children: `${ammo.name} (${ammo.ammo_count ?? 0}/${ammo.max_ammo_count ?? 0})`,
            onClick: () => handleAmmoClick(ammo.ref),
          })) || []),
          { children: 'CANCEL', onClick: handleCancel },
        ];

  return (
    <MfdPanel
      panelStateId={props.panelStateId}
      leftButtons={leftButtons}
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
            {/* Left: SVG label and line */}
            <Stack.Item>
              <svg height="501" width="300" style={{ display: 'block' }}>
                <text
                  stroke="#00e94e"
                  x={60}
                  y={230}
                  textAnchor="start"
                  fontSize="1.2em"
                >
                  {pendingWeapon === undefined ? 'SELECT WPN' : 'SELECT AMMO'}
                </text>
                <path
                  fillOpacity="0"
                  stroke="#00e94e"
                  d="M 80 210 l -20 0 l -20 -180 l -40 0"
                />
              </svg>
            </Stack.Item>
            {/* Center: Main content */}
            <Stack.Item grow>
              <Box
                width="100%"
                style={{
                  display: 'flex',
                  flexDirection: 'column',
                  alignItems: 'center',
                  justifyContent: 'center',
                  textIndent: '-300px',
                }}
              >
                <h3 style={{ textAlign: 'center', margin: 0 }}>
                  {autoreloader.name}
                </h3>
                <h4
                  style={{
                    fontSize: '1.25em',
                    textAlign: 'center',
                    margin: '0.5em 0 0.25em 0',
                  }}
                >
                  Stored Ammo
                </h4>
                {Array.isArray(autoreloader.stored_ammo) &&
                autoreloader.stored_ammo.length > 0 ? (
                  <div
                    style={{
                      fontSize: '1.15em',
                      textAlign: 'center',
                      marginBottom: '0.5em',
                    }}
                  >
                    {autoreloader.stored_ammo.map((ammo, idx) => (
                      <div key={ammo.ref || idx}>
                        {ammo.name} ({ammo.ammo_count ?? 0}/
                        {ammo.max_ammo_count ?? 0})
                      </div>
                    ))}
                  </div>
                ) : (
                  <div
                    style={{
                      fontSize: '1.15em',
                      textAlign: 'center',
                      marginBottom: '0.5em',
                    }}
                  >
                    Empty
                  </div>
                )}
                {pendingWeapon !== undefined && (
                  <>
                    <h4
                      style={{
                        textAlign: 'center',
                        margin: '0.5em 0 0.25em 0',
                        fontSize: '1.25em',
                      }}
                    >
                      Select Ammo for Weapon
                    </h4>
                    <div
                      style={{
                        textAlign: 'center',
                        marginBottom: '0.5em',
                      }}
                    >
                      {autoreloader.stored_ammo?.length ? (
                        <span style={{ fontSize: '1.25em' }}>
                          Choose an ammo type from the left or cancel.
                        </span>
                      ) : (
                        <span style={{ fontSize: '1.25em' }}>
                          No ammo available.
                        </span>
                      )}
                    </div>
                  </>
                )}
                {selectedWeapon && (
                  <>
                    <h4
                      style={{
                        textAlign: 'center',
                        margin: '0.5em 0 0.25em 0',
                      }}
                    >
                      Selected Weapon
                    </h4>
                    <div>{selectedWeapon.name}</div>
                  </>
                )}
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
