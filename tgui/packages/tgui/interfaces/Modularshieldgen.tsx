import { useBackend } from '../backend';
import { Window } from '../layouts';
import { Stack, Section, ProgressBar, Button, NumberInput } from '../components';

type Modularshieldgendata = {
  max_strength: number;
  current_strength: number;
  max_regeneration: number;
  current_regeneration: number;
  max_radius: number;
  current_radius: number;
  active: Boolean;
  recovering: Boolean;
};

export const Modularshieldgen = (props, context) => {
  const { topLevel } = props;
  const { act, data } = useBackend<Modularshieldgendata>(context);
  const {
    max_strength,
    max_regeneration,
    current_regeneration,
    max_radius,
    current_radius,
    current_strength,
    active,
  } = data;

  return (
    <Window title="Modular Shield Generator" width={600} height={400}>
      <Window.Content scrollable>
        <Stack vertical fill>
          <Stack.Item>
            <Section title={'Shield Strength'}>
              <ProgressBar
                title="Shield Strength"
                value={current_strength}
                minValue={0}
                maxValue={max_strength}
                height={'30px'}
                ranges={{
                  'good': [max_strength * 0.75, max_strength],
                  'average': [max_strength * 0.25, max_strength * 0.75],
                  'bad': [0, max_strength * 0.25],
                }}>
                {current_strength}/{max_strength}
              </ProgressBar>
            </Section>
            <Section
              horizontal
              fill
              height={'95px'}
              title={'Regeneration and Radius'}>
              <Section height={'20px'}>
                <ProgressBar
                  height={'20px'}
                  title="Regeneration rate"
                  value={current_regeneration}
                  minValue={0}
                  maxValue={max_regeneration}
                  ranges={{
                    'good': [max_regeneration * 0.75, max_regeneration],
                    'average': [
                      max_regeneration * 0.25,
                      max_regeneration * 0.75,
                    ],
                    'bad': [0, max_regeneration * 0.25],
                  }}>
                  Regeneration {current_regeneration}/{max_regeneration}
                </ProgressBar>
              </Section>
              <Section>
                <ProgressBar
                  height={'20px'}
                  title="Shield radius"
                  value={current_radius}
                  minValue={0}
                  maxValue={max_radius}
                  ranges={{
                    'good': [max_radius * 0.75, max_radius],
                    'average': [max_radius * 0.25, max_radius * 0.75],
                    'bad': [0, max_radius * 0.25],
                  }}>
                  Radius {current_radius}/{max_radius}
                </ProgressBar>
              </Section>
              <Section horizontal fill title={'Settings'}>
                Set Radius
                <Section vertical>
                  <NumberInput
                    title={'Set Radius'}
                    value={current_radius}
                    minValue={3}
                    maxValue={max_radius}
                    stepPixelSize={10}
                    lineHeight="30px"
                    fontSize="26px"
                    width="90px"
                    height="30px"
                    onChange={(e, value) =>
                      act('set_radius', {
                        new_radius: value,
                      })
                    }
                  />
                </Section>
                <Button
                  onClick={() => act('activate')}
                  content="Toggle Shields"
                />
              </Section>
            </Section>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
