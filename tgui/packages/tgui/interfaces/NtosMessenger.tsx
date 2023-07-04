import { useBackend, useLocalState } from '../backend';
import { createSearch } from 'common/string';
import { Box, Button, Dimmer, Icon, Section, Stack, Input, TextArea } from '../components';
import { NtosWindow } from '../layouts';
import { Component, createRef, RefObject, SFC } from 'inferno';
import { sanitizeText } from '../sanitize';
import { BooleanLike } from 'common/react';

import '../styles/interfaces/NtosMessenger.scss';

type NtMessage = {
  name: string;
  job: string;
  contents: string;
  outgoing: BooleanLike;
  sender: string;
  automated: BooleanLike;
  photo_path: string;
  photo: string;
  everyone: BooleanLike;
  targets: string[];
  target_details: string[];
};

type NtMessenger = {
  name: string;
  job: string;
  ref: string;
};

type NtChat = {
  recipient_name: string;
  messages: NtMessage[];
  visible: BooleanLike;
  owner_deleted: BooleanLike;
};

type NtMessengers = Record<string, NtMessenger>;

type NtosMessengerData = {
  owner: string;
  sort_by_job: BooleanLike;
  is_silicon: BooleanLike;
  ringer_status: BooleanLike;
  can_spam: BooleanLike;
  on_spam_cooldown: BooleanLike;
  virus_attach: BooleanLike;
  sending_virus: BooleanLike;
  sending_and_receiving: BooleanLike;
  viewing_messages_of: NtMessenger;
  photo: string;
  messages: NtMessage[];
  messengers: NtMessengers;
};

const NoIDDimmer = () => {
  return (
    <Dimmer>
      <Stack align="baseline" vertical>
        <Stack.Item>
          <Stack ml={-2}>
            <Stack.Item>
              <Icon color="red" name="address-card" size={10} />
            </Stack.Item>
          </Stack>
        </Stack.Item>
        <Stack.Item fontSize="18px">
          Please imprint an ID to continue.
        </Stack.Item>
      </Stack>
    </Dimmer>
  );
};

export const NtosMessenger = (_props: any, context: any) => {
  const { act, data } = useBackend<NtosMessengerData>(context);
  const { messages, viewing_messages_of } = data;

  let content: JSX.Element;
  if (viewing_messages_of !== null) {
    let filteredMsgs = messages.filter((msg) =>
      msg.outgoing
        ? msg.targets.includes(viewing_messages_of.ref)
        : viewing_messages_of.ref === msg.sender
    );
    content = (
      <ChatScreen
        msgs={filteredMsgs}
        recp={viewing_messages_of}
        onReturn={() => act('PDA_viewMessages', { ref: null })}
      />
    );
  } else {
    content = <ContactsScreen />;
  }

  return (
    <NtosWindow width={600} height={800}>
      <NtosWindow.Content>{content}</NtosWindow.Content>
    </NtosWindow>
  );
};

const ContactsScreen = (_props: any, context: any) => {
  const { act, data } = useBackend<NtosMessengerData>(context);
  const {
    owner,
    ringer_status,
    sending_and_receiving,
    messengers,
    sort_by_job,
    can_spam,
    is_silicon,
    photo,
    virus_attach,
    sending_virus,
  } = data;

  const messengerArray = Object.entries(messengers).map(([k, v]) => {
    v.ref = k;
    return v;
  });

  const [searchUser, setSearchUser] = useLocalState<string>(
    context,
    'searchUser',
    ''
  );

  const search = createSearch(
    searchUser,
    (messengers: NtMessenger) => messengers.name + messengers.job
  );

  let users =
    searchUser.length > 0 ? messengerArray.filter(search) : messengerArray;

  const noId = !owner && !is_silicon;

  return (
    <Stack fill vertical>
      <Section>
        <Stack vertical textAlign="center">
          <Box bold>
            <Icon name="address-card" mr={1} />
            SpaceMessenger V6.5.1
          </Box>
          <Box italic opacity={0.3} mt={1}>
            Bringing you spy-proof communications since 2467.
          </Box>
          <Box mt={2}>
            <Button
              icon="bell"
              content={ringer_status ? 'Ringer: On' : 'Ringer: Off'}
              onClick={() => act('PDA_ringer_status')}
            />
            <Button
              icon="address-card"
              content={
                sending_and_receiving
                  ? 'Send / Receive: On'
                  : 'Send / Receive: Off'
              }
              onClick={() => act('PDA_sAndR')}
            />
            <Button
              icon="bell"
              content="Set Ringtone"
              onClick={() => act('PDA_ringSet')}
            />
            <Button
              icon="sort"
              content={`Sort by: ${sort_by_job ? 'Job' : 'Name'}`}
              onClick={() => act('PDA_changeSortStyle')}
            />
            {!!is_silicon && (
              <Button
                icon="camera"
                content="Attach Photo"
                onClick={() => act('PDA_selectPhoto')}
              />
            )}
            {!!virus_attach && (
              <Button
                icon="bug"
                color="bad"
                content={`Attach Virus: ${sending_virus ? 'Yes' : 'No'}`}
                onClick={() => act('PDA_toggleVirus')}
              />
            )}
          </Box>
        </Stack>
      </Section>
      {!!photo && (
        <Stack vertical>
          <Section fill textAlign="center">
            <Icon name="camera" mr={1} />
            Current Photo
          </Section>
          <Section align="center" mb={1}>
            <Button onClick={() => act('PDA_clearPhoto')}>
              <Box mt={1} as="img" src={photo} />
            </Button>
          </Section>
        </Stack>
      )}
      <Stack vertical>
        <Section fill textAlign="center">
          <Icon name="address-card" mr={1} />
          Detected Messengers
          <Input
            width="220px"
            placeholder="Search by name or job..."
            value={searchUser}
            onInput={(_e: any, value: string) => setSearchUser(value)}
            mx={1}
            ml={27}
          />
        </Section>
      </Stack>
      <Stack vertical fill mt={1}>
        <Section fill scrollable>
          <Stack vertical pb={1}>
            {users.length === 0 && 'No users found'}
            {users.map((messenger) => (
              <Button
                key={messenger.ref}
                fluid
                onClick={() => {
                  act('PDA_viewMessages', { ref: messenger.ref });
                }}>
                {messenger.name} ({messenger.job})
              </Button>
            ))}
          </Stack>
        </Section>
        {!!can_spam && <SendToAllModal />}
      </Stack>
      {noId && <NoIDDimmer />}
    </Stack>
  );
};

type ChatMessageProps = {
  isSelf: BooleanLike;
  msg: string;
  everyone?: BooleanLike;
  photoPath?: string;
};

const ChatMessage: SFC<ChatMessageProps> = (props: ChatMessageProps) => {
  const { msg, everyone, isSelf, photoPath } = props;
  const text = {
    __html: sanitizeText(msg),
  };

  return (
    <Box className={`NtosMessenger__ChatMessage${isSelf ? '__outgoing' : ''}`}>
      <Box
        className="NtosMessenger__ChatMessage__content"
        dangerouslySetInnerHTML={text}
      />
      {photoPath !== null && <Box as="img" src={photoPath} />}
      {everyone && (
        <Box className="NtosMessenger__ChatMessage__everyone">
          Sent to everyone
        </Box>
      )}
    </Box>
  );
};

type ChatScreenProps = {
  onReturn: () => void;
  recp: NtMessenger;
  msgs: NtMessage[];
};

type ChatScreenState = {
  msg: string;
  canSend: BooleanLike;
};

class ChatScreen extends Component<ChatScreenProps, ChatScreenState> {
  scrollRef: RefObject<HTMLDivElement>;
  state: ChatScreenState = {
    msg: '',
    canSend: true,
  };

  constructor(props: ChatScreenProps) {
    super(props);

    this.scrollRef = createRef();

    this.scrollToBottom = this.scrollToBottom.bind(this);
    this.handleMessageInput = this.handleMessageInput.bind(this);
    this.handleSendMessage = this.handleSendMessage.bind(this);
  }

  componentDidMount() {
    this.scrollToBottom();
  }

  componentDidUpdate(
    prevProps: ChatScreenProps,
    _prevState: ChatScreenState,
    _snapshot: any
  ) {
    if (prevProps.msgs.length !== this.props.msgs.length) {
      this.scrollToBottom();
    }
  }

  scrollToBottom() {
    const scroll = this.scrollRef.current;
    if (scroll !== null) {
      scroll.scrollTop = scroll.scrollHeight;
    }
  }

  handleSendMessage() {
    if (this.state.msg === '') return;
    const { act } = useBackend<NtosMessengerData>(this.context);
    act('PDA_sendMessage', {
      ref: this.props.recp.ref,
      name: this.props.recp.name,
      job: this.props.recp.job,
      msg: this.state.msg,
    });
    this.setState({ msg: '', canSend: false });
    setTimeout(() => this.setState({ canSend: true }), 1000);
  }

  handleMessageInput(_: any, val: string) {
    this.setState({ msg: val });
  }

  render() {
    const { act } = useBackend<NtosMessengerData>(this.context);
    const { recp, onReturn, msgs } = this.props;
    const { msg, canSend } = this.state;

    let lastMsgRef = '';
    let filteredMessages: JSX.Element[] = [];

    for (let index = 0; index < msgs.length; index++) {
      let message = msgs[index];

      const isSwitch = lastMsgRef !== message.sender;
      lastMsgRef = message.sender;

      filteredMessages.push(
        <Stack.Item key={index} mt={isSwitch ? 2 : 0.5}>
          <ChatMessage
            isSelf={message.outgoing}
            msg={message.contents}
            everyone={!!message.everyone}
            photoPath={message.photo_path}
          />
        </Stack.Item>
      );
    }

    return (
      <Stack vertical fill>
        <Stack.Item>
          <Section fill>
            <Button icon="arrow-left" content="Back" onClick={onReturn} />
            <Button.Confirm
              icon="trash-can"
              content="Delete chat"
              onClick={() => act('PDA_clearMessages', { ref: recp.ref })}
            />
          </Section>
        </Stack.Item>

        <Stack.Item>
          <Section
            scrollable
            fill
            fitted
            title={`${recp.name} (${recp.job})`}
            scrollableRef={this.scrollRef}>
            <Stack vertical fill className="NtosMessenger__ChatLog">
              <Stack.Item textAlign="center" fontSize={1}>
                This is the beginning of your chat with {recp.name}.
              </Stack.Item>
              <Stack.Divider />
              {filteredMessages}
            </Stack>
          </Section>
        </Stack.Item>

        <Stack.Item>
          <Section>
            <Stack fill>
              <Stack.Item>
                <Input
                  placeholder={`Send message to ${recp.name}...`}
                  fluid
                  autofocus
                  justify
                  id="input"
                  value={msg}
                  maxLength={1024}
                  onInput={this.handleMessageInput}
                  onEnter={this.handleSendMessage}
                />
              </Stack.Item>
              <Stack.Item>
                <Button
                  icon="arrow-right"
                  onClick={this.handleSendMessage}
                  disabled={!canSend}
                />
              </Stack.Item>
            </Stack>
          </Section>
        </Stack.Item>
      </Stack>
    );
  }
}

const SendToAllModal = (_: any, context: any) => {
  const { data, act } = useBackend<NtosMessengerData>(context);
  const { on_spam_cooldown } = data;

  const [msg, setMsg] = useLocalState(context, 'everyoneMessage', '');

  return (
    <>
      <Section>
        <Stack justify="space-between">
          <Stack.Item align="center">
            <Icon name="satellite-dish" mr={1} />
            Send To All
          </Stack.Item>
          <Stack.Item>
            <Button
              icon="arrow-right"
              disabled={on_spam_cooldown || msg === ''}
              tooltip={
                on_spam_cooldown
                  ? 'Wait before sending more messages!'
                  : undefined
              }
              tooltipPosition="auto-start"
              onClick={() => {
                act('PDA_sendEveryone', { msg: msg });
                setMsg('');
              }}>
              Send
            </Button>
          </Stack.Item>
        </Stack>
      </Section>
      <Section>
        <TextArea
          height={5}
          value={msg}
          placeholder="Send message to everyone..."
          onInput={(_: any, v: string) => setMsg(v)}
        />
      </Section>
    </>
  );
};
