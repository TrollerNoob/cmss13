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
interface HandheldStatus {
  linked: boolean;
  name?: string;
  repair_list?: Malfunction[];
  charge?: number;
  max_charge?: number;
}
interface DropshipMaintenanceData {
  handheld: HandheldStatus;
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

const HandheldStatusPanel = ({
  handheld,
}: {
  readonly handheld: HandheldStatus;
}) => (
  <Box className="HandheldStatusPanel">
    <Stack vertical>
      <Stack.Item>
        <b>{handheld.linked ? 'Handheld Linked' : 'No Handheld Linked'}</b>
      </Stack.Item>
      {handheld.linked && handheld.name && (
        <Stack.Item>
          <span>Device: {handheld.name}</span>
        </Stack.Item>
      )}
    </Stack>
  </Box>
);

export const DropshipMaintenanceUI = () => {
  const { data, act } = useBackend<
    DropshipMaintenanceData & { screen_state: number }
  >();
  const { handheld, screen_state } = data;

  return (
    <Window theme="crtgreen" width={600} height={500}>
      <Box className="DropshipMaintenance" style={{ height: '100%' }}>
        <Stack vertical>
          {screen_state === 0 && (
            <Stack.Item>
              <TimedCallback
                time={1.5}
                callback={() => act('screen-state', { state: 1 })}
              />
              <div className="TopPanelSlide" />
              <div className="BottomPanelSlide" />
            </Stack.Item>
          )}
          {screen_state === 1 && (
            <>
              <Stack.Item>
                <HandheldStatusPanel handheld={handheld} />
              </Stack.Item>
              <Stack.Item>
                {handheld.linked && handheld.repair_list ? (
                  <MalfunctionList repair_list={handheld.repair_list} />
                ) : (
                  <Box className="NoHandheldMessage">
                    Link a handheld device to view repair data.
                  </Box>
                )}
              </Stack.Item>
            </>
          )}
        </Stack>
      </Box>
    </Window>
  );
};
