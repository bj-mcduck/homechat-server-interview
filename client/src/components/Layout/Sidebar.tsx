import { useState } from 'react';
import { Link, useParams } from 'react-router-dom';
import { useQuery } from 'urql';
import { Button, Paper, Title, Stack, Text, ScrollArea, Group, Badge, Divider, Skeleton, ActionIcon } from '@mantine/core';
import { IconPlus, IconMessageCircle, IconUsers } from '@tabler/icons-react';
import { USER_CHATS_QUERY } from '../../lib/queries';
import { CreateGroupChatModal } from '../Chat/CreateGroupChatModal';
import { CreateDirectMessageModal } from '../Chat/CreateDirectMessageModal';

interface Chat {
  id: string;
  name: string | null;
  private: boolean;
  members: Array<{
    id: string;
    username: string;
    firstName: string;
    lastName: string;
  }>;
}

export const Sidebar = () => {
  const { chatId } = useParams();
  const [isGroupModalOpen, setIsGroupModalOpen] = useState(false);
  const [isDMModalOpen, setIsDMModalOpen] = useState(false);
  
  const [{ data, fetching }] = useQuery({ query: USER_CHATS_QUERY });

  if (fetching) {
    return (
      <Paper shadow="sm" style={{ height: '100vh', width: 300, padding: '1rem' }}>
        <Stack gap="md">
          <Skeleton height={24} width="60%" />
          <Skeleton height={16} width="80%" />
          <Skeleton height={16} width="70%" />
          <Skeleton height={16} width="90%" />
        </Stack>
      </Paper>
    );
  }

  const chats: Chat[] = data?.userChats || [];
  const groupChats = chats.filter(chat => chat.name);
  const directMessages = chats.filter(chat => !chat.name);

  const getChatDisplayName = (chat: Chat) => {
    if (chat.name) return chat.name;
    
    // For direct messages, show the other participant's name
    const otherMembers = chat.members.filter(member => member.id !== data?.me?.id);
    if (otherMembers.length === 1) {
      return `${otherMembers[0].firstName} ${otherMembers[0].lastName}`;
    }
    
    return `Direct Message (${chat.members.length} people)`;
  };

  return (
    <>
      <Paper shadow="sm" style={{ height: '100vh', width: 300, padding: '1rem' }}>
        <Stack gap="md" style={{ height: '100%' }}>
          <Title order={3}>Chats</Title>
          
          {/* Group Chats Section */}
          <div style={{ flex: 1 }}>
            <Group justify="space-between" mb="sm">
              <Text size="sm" fw={500} c="dimmed">
                Group Chats
              </Text>
              <Group gap="xs">
                <Badge size="sm" variant="light">
                  {groupChats.length}
                </Badge>
                <ActionIcon
                  size="sm"
                  variant="subtle"
                  color="blue"
                  onClick={() => setIsGroupModalOpen(true)}
                >
                  <IconPlus size={14} />
                </ActionIcon>
              </Group>
            </Group>
            
            <ScrollArea style={{ height: 200 }}>
              <Stack gap="xs">
                {groupChats.length === 0 ? (
                  <Text size="sm" c="dimmed" ta="center" py="md">
                    No group chats yet
                  </Text>
                ) : (
                  groupChats.map(chat => (
                    <Button
                      key={chat.id}
                      component={Link}
                      to={`/chat/${chat.id}`}
                      variant={chatId === chat.id ? "filled" : "subtle"}
                      justify="flex-start"
                      leftSection={<IconUsers size={16} />}
                      style={{ justifyContent: 'flex-start' }}
                    >
                      {getChatDisplayName(chat)}
                    </Button>
                  ))
                )}
              </Stack>
            </ScrollArea>
          </div>

          <Divider />

          {/* Direct Messages Section */}
          <div style={{ flex: 1 }}>
            <Group justify="space-between" mb="sm">
              <Text size="sm" fw={500} c="dimmed">
                Direct Messages
              </Text>
              <Group gap="xs">
                <Badge size="sm" variant="light">
                  {directMessages.length}
                </Badge>
                <ActionIcon
                  size="sm"
                  variant="subtle"
                  color="blue"
                  onClick={() => setIsDMModalOpen(true)}
                >
                  <IconPlus size={14} />
                </ActionIcon>
              </Group>
            </Group>
            
            <ScrollArea style={{ height: 200 }}>
              <Stack gap="xs">
                {directMessages.length === 0 ? (
                  <Text size="sm" c="dimmed" ta="center" py="md">
                    No direct messages yet
                  </Text>
                ) : (
                  directMessages.map(chat => (
                    <Button
                      key={chat.id}
                      component={Link}
                      to={`/chat/${chat.id}`}
                      variant={chatId === chat.id ? "filled" : "subtle"}
                      justify="flex-start"
                      leftSection={<IconMessageCircle size={16} />}
                      style={{ justifyContent: 'flex-start' }}
                    >
                      {getChatDisplayName(chat)}
                    </Button>
                  ))
                )}
              </Stack>
            </ScrollArea>
          </div>

        </Stack>
      </Paper>

      <CreateGroupChatModal
        opened={isGroupModalOpen}
        onClose={() => setIsGroupModalOpen(false)}
      />
      
      <CreateDirectMessageModal
        opened={isDMModalOpen}
        onClose={() => setIsDMModalOpen(false)}
      />
    </>
  );
};
