import { useState, useMemo, useEffect } from 'react';
import { useMutation, useQuery, useSubscription } from 'urql';
import { Paper, Title, Stack, Text, ScrollArea, Group, Avatar, ActionIcon, TextInput, Divider, Skeleton } from '@mantine/core';
import { IconPlus, IconUser } from '@tabler/icons-react';
import { notifications } from '@mantine/notifications';
import { ADD_CHAT_MEMBER_MUTATION } from '../../lib/mutations';
import { USERS_QUERY, CHAT_QUERY } from '../../lib/queries';
import { CHAT_UPDATED_SUBSCRIPTION } from '../../lib/subscriptions';

interface ChatMembersPanelProps {
  chatId: string;
}

export const ChatMembersPanel = ({ chatId }: ChatMembersPanelProps) => {
  const [searchTerm, setSearchTerm] = useState('');
  const [addingMember, setAddingMember] = useState<string | null>(null);
  
  const [, addChatMember] = useMutation(ADD_CHAT_MEMBER_MUTATION);
  const [{ data: usersData, fetching: usersFetching }] = useQuery({
    query: USERS_QUERY,
    variables: { excludeSelf: true },
  });
  const [{ data: chatData, fetching: chatFetching }] = useQuery({
    query: CHAT_QUERY,
    variables: { chatId },
    requestPolicy: 'cache-and-network',
  });

  // Subscribe to chat updates for real-time member changes
  const [{ data: subscriptionData }] = useSubscription({
    query: CHAT_UPDATED_SUBSCRIPTION,
    variables: { chatId },
  });

  // Use subscription data if available, otherwise fall back to query data
  const currentMembers = subscriptionData?.chatUpdated?.members || chatData?.chat?.members || [];
  const users = usersData?.users || [];

  // Debug logging to see what's happening
  useEffect(() => {
    console.log('ChatMembersPanel - Subscription data:', subscriptionData);
    console.log('ChatMembersPanel - Chat data:', chatData);
    console.log('ChatMembersPanel - Current members:', currentMembers);
  }, [subscriptionData, chatData, currentMembers]);

  const filteredUsers = useMemo(() => {
    if (!searchTerm.trim()) return users;
    
    const term = searchTerm.toLowerCase();
    return users.filter((user: any) => 
      user.firstName.toLowerCase().includes(term) ||
      user.lastName.toLowerCase().includes(term) ||
      user.username.toLowerCase().includes(term)
    );
  }, [users, searchTerm]);

  // Filter out users who are already members
  const availableUsers = useMemo(() => {
    const memberIds = new Set(currentMembers.map((member: any) => member.id));
    return filteredUsers.filter((user: any) => !memberIds.has(user.id));
  }, [filteredUsers, currentMembers]);

  const handleAddMember = async (userId: string, userName: string) => {
    setAddingMember(userId);
    
    try {
      console.log('Adding member to chat:', { chatId, userId });
      const result = await addChatMember({ chatId, userId });
      
      console.log('Add member result:', result);
      
      if (result.error) {
        console.error('Add member error:', result.error);
        notifications.show({
          title: 'Failed to Add Member',
          message: result.error.message,
          color: 'red',
        });
        return;
      }
      
      if (result.data?.addChatMember) {
        console.log('Member added successfully');
        notifications.show({
          title: 'Member Added',
          message: `${userName} has been added to the chat`,
          color: 'green',
        });
        setSearchTerm('');
      }
    } catch (err) {
      console.error('Add member error:', err);
      notifications.show({
        title: 'Failed to Add Member',
        message: 'An unexpected error occurred',
        color: 'red',
      });
    } finally {
      setAddingMember(null);
    }
  };

  if (chatFetching) {
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

  return (
    <Paper shadow="sm" style={{ height: '100%', width: 300, padding: '1rem' }}>
      <Stack gap="md" style={{ height: '100%' }}>
        <Title order={4}>Members ({currentMembers.length})</Title>
        
        {/* Current Members */}
        <div style={{ flex: 1 }}>
          <Text size="sm" fw={500} c="dimmed" mb="sm">
            Current Members
          </Text>
          
          <ScrollArea style={{ height: 200 }}>
            <Stack gap="xs">
              {currentMembers.length === 0 ? (
                <Text size="sm" c="dimmed" ta="center" py="md">
                  No members yet
                </Text>
              ) : (
                currentMembers.map((member: any) => (
                  <Group key={member.id} gap="sm" p="xs">
                    <Avatar size="sm" color="blue">
                      <IconUser size={16} />
                    </Avatar>
                    <div>
                      <Text size="sm" fw={500}>
                        {member.firstName} {member.lastName}
                      </Text>
                      <Text size="xs" c="dimmed">
                        @{member.username}
                      </Text>
                    </div>
                  </Group>
                ))
              )}
            </Stack>
          </ScrollArea>
        </div>

        <Divider />

        {/* Add Members */}
        <div style={{ flex: 1 }}>
          <Text size="sm" fw={500} c="dimmed" mb="sm">
            Add Members
          </Text>
          
          <TextInput
            placeholder="Search users..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            mb="sm"
          />
          
          <ScrollArea style={{ height: 200 }}>
            <Stack gap="xs">
              {usersFetching ? (
                <Skeleton height={40} />
              ) : availableUsers.length === 0 ? (
                <Text size="sm" c="dimmed" ta="center" py="md">
                  {searchTerm ? 'No users found' : 'Search for users to add'}
                </Text>
              ) : (
                availableUsers.map((user: any) => (
                  <Group key={user.id} justify="space-between" p="xs" style={{ 
                    border: '1px solid #e9ecef', 
                    borderRadius: '6px',
                    backgroundColor: '#f8f9fa'
                  }}>
                    <Group gap="sm">
                      <Avatar size="sm" color="blue">
                        <IconUser size={16} />
                      </Avatar>
                      <div>
                        <Text size="sm" fw={500}>
                          {user.firstName} {user.lastName}
                        </Text>
                        <Text size="xs" c="dimmed">
                          @{user.username}
                        </Text>
                      </div>
                    </Group>
                    
                    <ActionIcon
                      variant="filled"
                      color="blue"
                      size="sm"
                      loading={addingMember === user.id}
                      onClick={() => handleAddMember(user.id, `${user.firstName} ${user.lastName}`)}
                    >
                      <IconPlus size={14} />
                    </ActionIcon>
                  </Group>
                ))
              )}
            </Stack>
          </ScrollArea>
        </div>
      </Stack>
    </Paper>
  );
};
