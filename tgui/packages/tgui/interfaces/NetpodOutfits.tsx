import { useBackend, useLocalState } from '../backend';
import { Section, Button, Stack, Tabs, Divider } from '../components';
import { Window } from '../layouts';

type Data = {
  netsuit: string;
  collections: Collection[];
  types: string[];
};

type Collection = {
  name: string;
  outfits: Outfit[];
};

type Outfit = {
  path: string;
  name: string;
  type: string;
};

export const NetpodOutfits = (props, context) => {
  const { act, data } = useBackend<Data>(context);
  const { netsuit, collections = [] } = data;
  const [selectedType, setSelectedType] = useLocalState<Collection>(
    context,
    'selectedType',
    collections[0]
  );

  return (
    <Window title="NetChair" height={300} width={400}>
      <Window.Content>
        <Stack fill vertical>
          <Stack.Item grow>
            <Section fill title="Select an outfit">
              <Stack fill>
                <Stack.Item grow>
                  <Tabs vertical>
                    {collections.map((collection, index) => (
                      <>
                        <Tabs.Tab
                          key={collection.name}
                          onClick={() => setSelectedType(collection)}
                          selected={selectedType === collection}>
                          {collection.name}
                        </Tabs.Tab>
                        {index > 0 && <Divider />}
                      </>
                    ))}
                  </Tabs>
                </Stack.Item>
                <Stack.Divider />
                <Stack.Item grow={5}>
                  <Section fill scrollable>
                    {selectedType?.outfits
                      ?.sort((a, b) => (a.name > b.name ? 1 : 0))
                      .map(({ path, name }, index) => (
                        <Stack.Item className="candystripe" key={index}>
                          <Button
                            selected={netsuit === path}
                            color="transparent"
                            onClick={() =>
                              act('select_outfit', { outfit: path })
                            }>
                            {name}
                          </Button>
                        </Stack.Item>
                      ))}
                  </Section>
                </Stack.Item>
              </Stack>
            </Section>
          </Stack.Item>
          <Stack.Item>
            <Section>
              {`Current: ${
                selectedType.outfits?.find((outfit) => outfit.path === netsuit)
                  ?.name
              }`}
            </Section>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
