import { Loader } from './common/Loader';
import { InputButtons } from './common/InputButtons';
import { useBackend, useLocalState } from '../backend';
import { KEY_ENTER, KEY_ESCAPE } from '../../common/keycodes';
import { Box, Section, Stack, TextArea } from '../components';
import { Window } from '../layouts';

type TextInputData = {
  large_buttons: boolean;
  max_length: number;
  message: string;
  multiline: boolean;
  placeholder: string;
  timeout: number;
  title: string;
};

export const SanitizeMultiline = (toSanitize: string) => {
  const tooManySkiplinesFinder = RegExp('(\r\n\r\n\r\n|\n\n\n|\r\r\r)+');
  while (toSanitize.search(tooManySkiplinesFinder) !== -1) {
    toSanitize = toSanitize.replace(tooManySkiplinesFinder, '\n\n');
  }
  return toSanitize;
};

export const RemoveAllSkiplines = (toSanitize: string) => {
  const skiplinesFinder = RegExp('(\n|\r)+');
  while (toSanitize.search(skiplinesFinder) !== -1) {
    toSanitize = toSanitize.replace(skiplinesFinder, '');
  }
  return toSanitize;
};

export const TextInputModal = (props, context) => {
  const { act, data } = useBackend<TextInputData>(context);
  const {
    large_buttons,
    max_length,
    message = '',
    multiline,
    placeholder,
    timeout,
    title,
  } = data;
  const [input, setInput] = useLocalState<string>(
    context,
    'input',
    placeholder || ''
  );
  const onType = (value: string) => {
    if (value === input) {
      return;
    }
    const sanitizedInput = multiline
      ? SanitizeMultiline(value)
      : RemoveAllSkiplines(value);
    setInput(sanitizedInput);
  };

  const visualMultiline = multiline || input.length >= 30;
  // Dynamically changes the window height based on the message.
  const windowHeight =
    135 +
    (message.length > 30 ? Math.ceil(message.length / 4) : 0) +
    (visualMultiline ? 75 : 0) +
    (message.length && large_buttons ? 5 : 0);

  return (
    <Window title={title} width={325} height={windowHeight}>
      {timeout && <Loader value={timeout} />}
      <Window.Content
        onKeyDown={(event) => {
          const keyCode = window.event ? event.which : event.keyCode;
          if (keyCode === KEY_ENTER && (!visualMultiline || !event.shiftKey)) {
            act('submit', { entry: input });
          }
          if (keyCode === KEY_ESCAPE) {
            act('cancel');
          }
        }}>
        <Section fill>
          <Stack fill vertical>
            <Stack.Item>
              <Box color="label">{message}</Box>
            </Stack.Item>
            <Stack.Item grow>
              <InputArea input={input} onType={onType} />
            </Stack.Item>
            <Stack.Item>
              <InputButtons
                input={input}
                message={`${input.length}/${max_length}`}
              />
            </Stack.Item>
          </Stack>
        </Section>
      </Window.Content>
    </Window>
  );
};

/** Gets the user input and invalidates if there's a constraint. */
const InputArea = (props, context) => {
  const { act, data } = useBackend<TextInputData>(context);
  const { max_length, multiline } = data;
  const { input, onType } = props;

  const visualMultiline = multiline || input.length >= 30;

  return (
    <TextArea
      autoFocus
      autoSelect
      height={multiline || input.length >= 30 ? '100%' : '1.8rem'}
      maxLength={max_length}
      onEscape={() => act('cancel')}
      onEnter={(event) => {
        if (visualMultiline && event.shiftKey) {
          return;
        }
        event.preventDefault();
        act('submit', { entry: input });
      }}
      onInput={(_, value) => onType(value)}
      placeholder="Type something..."
      value={input}
    />
  );
};
