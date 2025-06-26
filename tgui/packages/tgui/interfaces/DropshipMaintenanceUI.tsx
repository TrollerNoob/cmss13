import { useBackend } from 'tgui/backend';
import { Box, Stack } from 'tgui/components';
import { Window } from 'tgui/layouts';

import { TimedCallback } from './common/TimedCallback';

// Data types for dropship maintenance UI
type RepairStep = string;
interface Malfunction {
  id: string;
  steps: RepairStep[];
  mount_point?: number; // Added for equipment highlighting
}
interface DropshipMaintenanceData {
  repair_list: Malfunction[];
}

const MalfunctionList = ({
  repair_list,
}: {
  readonly repair_list: Malfunction[];
}) => (
  <Box className="MalfunctionList">
    <Stack vertical>
      {repair_list.length === 0 && (
        <Stack.Item>
          <span>No malfunctions detected.</span>
        </Stack.Item>
      )}
      {repair_list.map((malf) => (
        <Stack.Item key={malf.id}>
          <Box className="MalfunctionBox">
            <b>{malf.id}</b>
            <ul>
              {malf.steps.map((step, i) => (
                <li key={i}>{step}</li>
              ))}
            </ul>
          </Box>
        </Stack.Item>
      ))}
    </Stack>
  </Box>
);

const EmptyDisplay = () => {
  return (
    <Box className="EmptyDisplay">
      <Stack vertical>
        <Stack.Item>
          <span>No equipment detected.</span>
        </Stack.Item>
        <Stack.Item>
          <span>
            Connect the Aircraft Maintenance Tuner with the laptop to link the
            encryption data. Then scan the damaged equipment with the Aircraft
            Maintenance Tuner to continue.
          </span>
        </Stack.Item>
      </Stack>
    </Box>
  );
};

// --- Dropship SVG Drawing for Maintenance UI ---

const equipment_xs = [140, 160, 320, 340, 180, 300, 240, 240, 240, 140, 340];
const equipment_ys = [120, 100, 100, 120, 100, 100, 260, 300, 340, 320, 320];

const DrawEquipment = ({
  damagedMounts,
}: {
  readonly damagedMounts: number[];
}) => {
  return (
    <>
      {equipment_xs.map((x, i) => {
        const isDamaged = damagedMounts.includes(i + 1);
        return (
          <circle
            key={i}
            cx={x}
            cy={equipment_ys[i]}
            r={12}
            fill={isDamaged ? '#e90000' : '#00e94e'}
            stroke={isDamaged ? '#e90000' : '#00e94e'}
            strokeWidth={isDamaged ? 3 : 1}
          />
        );
      })}
    </>
  );
};

const DropshipDiagram = ({
  damagedMounts,
}: {
  readonly damagedMounts: number[];
}) => {
  return (
    <Box className="DropshipDiagram" style={{ margin: 'auto', width: '500px' }}>
      <svg height="400" width="500">
        {/* (Optional) Add dropship outline here if desired */}
        <DrawEquipment damagedMounts={damagedMounts} />
      </svg>
    </Box>
  );
};

export const DropshipMaintenanceUI = () => {
  const { data, act } = useBackend<
    DropshipMaintenanceData & { screen_state: number }
  >();
  const { repair_list, screen_state } = data;

  const hasRepairs = repair_list && repair_list.length > 0;

  // Collect damaged mount points from repair_list (if present)
  // Assumes each malfunction has a mount_point field (number)
  const damagedMounts = (repair_list || [])
    .map((malf) => malf.mount_point)
    .filter((x) => typeof x === 'number');

  return (
    <Window theme="crtgreen" width={600} height={500}>
      <Window.Content className="SentryGun" scrollable>
        <Stack vertical>
          <Stack.Item>
            {data.screen_state === 0 && (
              <div>
                <TimedCallback
                  time={1.5}
                  callback={() => act('screen-state', { state: 1 })}
                />
                <div className="TopPanelSlide" />
                <div className="BottomPanelSlide" />
              </div>
            )}
            {screen_state === 1 && (
              <>
                <DropshipDiagram damagedMounts={damagedMounts} />
                {!hasRepairs ? (
                  <EmptyDisplay />
                ) : (
                  <MalfunctionList repair_list={repair_list} />
                )}
              </>
            )}
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
