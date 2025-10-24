import { useState, useEffect } from 'react';
import { Link, useParams } from 'react-router-dom';
import { useQuery, useSubscription } from 'urql';
import { Button, Paper, Title, Stack, Text, ScrollArea, Group, Badge, Divider, Skeleton, ActionIcon } from '@mantine/core';
import { notifications } from '@mantine/notifications';
import { IconPlus, IconMessageCircle, IconUsers, IconLock } from '@tabler/icons-react';
import { DISCOVERABLE_CHATS_QUERY } from '../../lib/queries';
import { USER_CHAT_UPDATES_SUBSCRIPTION } from '../../lib/subscriptions';
import { useAuth } from '../../hooks/useAuth';
import { CreateGroupChatModal } from '../Chat/CreateGroupChatModal';
import { CreateDirectMessageModal } from '../Chat/CreateDirectMessageModal';

interface Chat {
  id: string;
  name: string | null;
  displayName: string;
  private: boolean;
  isDirect: boolean;
  state: string;
  members: Array<{
    id: string;
    username: string;
    firstName: string;
    lastName: string;
  }>;
}

export const Sidebar = () => {
  const { chatId } = useParams();
  const { user: currentUser } = useAuth();
  const [isGroupModalOpen, setIsGroupModalOpen] = useState(false);
  const [isDMModalOpen, setIsDMModalOpen] = useState(false);
  
  // Use cache-first for better performance, automatically invalidated by mutations
  const [{ data, fetching }] = useQuery({ 
    query: DISCOVERABLE_CHATS_QUERY,
    requestPolicy: 'cache-first' // Use cache, automatically invalidated by mutations
  });

  // Subscribe to user-scoped chat updates
  const [{ data: subscriptionData }] = useSubscription({
    query: USER_CHAT_UPDATES_SUBSCRIPTION,
    variables: { userId: currentUser?.id },
    pause: !currentUser?.id, // Pause subscription if user is not available
  });

  // Show notification when subscription data arrives
  useEffect(() => {
    if (subscriptionData?.userChatUpdates) {
      const chat = subscriptionData.userChatUpdates;
      
      // Show notification toast
      notifications.show({
        title: 'Added to Chat',
        message: `You've been added to "${chat.displayName || chat.name || 'a chat'}"`,
        color: 'blue',
        autoClose: 5000,
      });
      
      // Cache is automatically invalidated by urql, no manual refetch needed
    }
  }, [subscriptionData]);

  if (fetching) {
    return (
      <Paper shadow="sm" style={{ height: '100%', width: 300, padding: '1rem' }}>
        <Stack gap="md">
          <Skeleton height={24} width="60%" />
          <Skeleton height={16} width="80%" />
          <Skeleton height={16} width="70%" />
          <Skeleton height={16} width="90%" />
        </Stack>
      </Paper>
    );
  }

  const chats: Chat[] = data?.discoverableChats || [];
  const groupChats = chats.filter(chat => chat.name);
  const directMessages = chats.filter(chat => !chat.name);

  const getChatDisplayName = (chat: Chat) => {
    // Use server-computed display name
    return chat.displayName;
  };

  return (
    <>
      <Paper shadow="sm" style={{ height: '100%', width: 300, padding: '1rem' }}>
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
                      leftSection={
                        <Group gap="xs">
                          {chat.private && !chat.isDirect && <IconLock size={14} color="gray" />}
                          <IconUsers size={16} />
                        </Group>
                      }
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
                      leftSection={
                        <Group gap="xs">
                          {chat.private && !chat.isDirect && <IconLock size={14} color="gray" />}
                          <IconMessageCircle size={16} />
                        </Group>
                      }
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
