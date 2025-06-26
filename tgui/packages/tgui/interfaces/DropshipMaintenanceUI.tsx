import { useBackend } from 'tgui/backend';
import { Box, Stack } from 'tgui/components';
import { Window } from 'tgui/layouts';

import { TimedCallback } from './common/TimedCallback';

// Data types for dropship maintenance UI
type RepairStep = string;
interface Malfunction {
  id: string;
  steps: RepairStep[];
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

export const DropshipMaintenanceUI = () => {
  const { data, act } = useBackend<
    DropshipMaintenanceData & { screen_state: number }
  >();
  const { repair_list, screen_state } = data;

  const hasRepairs = repair_list && repair_list.length > 0;

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
            {screen_state === 1 &&
              (!hasRepairs ? (
                <EmptyDisplay />
              ) : (
                <MalfunctionList repair_list={repair_list} />
              ))}
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
