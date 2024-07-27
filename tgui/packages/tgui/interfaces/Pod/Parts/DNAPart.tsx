import { useBackend } from '../../../backend';
import { Box, Stack, Button, Icon } from '../../../components';
type Data = {
  dnaSet: string;
  ref: string;
};

export default function DNAPart(props: { partData: Data }): JSX.Element {
  const { act } = useBackend<{
    ourData: Data;
  }>();
  const ourData = props.partData as Data;
  return (
    <Stack vertical>
      <Stack.Item>
        <Box
          textAlign="center"
          fontSize="18px"
          mb={1}
          className="NuclearBomb__displayBox"
        >
          {ourData.dnaSet}
        </Box>
      </Stack.Item>
      <Stack.Item>
        <Button
          ml="25%"
          height="48px"
          width="128px"
          onClick={() => act('setprint', { partRef: ourData.ref })}
        >
          <Icon name="fingerprint" size={3} mt="0.5rem" ml="2.8rem" />
        </Button>
      </Stack.Item>
    </Stack>
  );
}
