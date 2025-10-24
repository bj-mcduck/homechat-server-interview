import { useState, useMemo, useEffect } from 'react';
import { useMutation, useQuery, useSubscription } from 'urql';
import { useNavigate } from 'react-router-dom';
import { Paper, Title, Stack, Text, ScrollArea, Group, Avatar, ActionIcon, TextInput, Divider, Skeleton } from '@mantine/core';
import { IconPlus, IconUser, IconX } from '@tabler/icons-react';
import { notifications } from '@mantine/notifications';
import { ADD_CHAT_MEMBER_MUTATION, CREATE_OR_FIND_GROUP_CHAT_MUTATION, LEAVE_CHAT_MUTATION } from '../../lib/mutations';
import { USERS_QUERY } from '../../lib/queries';
import { USER_CHAT_UPDATES_SUBSCRIPTION } from '../../lib/subscriptions';
import { useAuth } from '../../hooks/useAuth';

interface Chat {
  id: string;
  name: string | null;
  displayName: string;
  private: boolean;
  members: Array<{
    id: string;
    username: string;
    firstName: string;
    lastName: string;
  }>;
}

interface ChatMembersPanelProps {
  chat: Chat | null;
}

export const ChatMembersPanel = ({ chat }: ChatMembersPanelProps) => {
  const { user: currentUser } = useAuth();
  
  if (!chat) {
    return (
      <Paper shadow="sm" style={{ height: '100%', width: 300, padding: '1rem' }}>
        <Skeleton height={24} />
        <Skeleton height={200} mt="md" />
      </Paper>
    );
  }

  const [searchTerm, setSearchTerm] = useState('');
  const [addingMember, setAddingMember] = useState<string | null>(null);
  const navigate = useNavigate();
  
  const [, addChatMember] = useMutation(ADD_CHAT_MEMBER_MUTATION);
  const [, createOrFindGroupChat] = useMutation(CREATE_OR_FIND_GROUP_CHAT_MUTATION);
  const [, leaveChat] = useMutation(LEAVE_CHAT_MUTATION);
  const [{ data: usersData, fetching: usersFetching }] = useQuery({
    query: USERS_QUERY,
    variables: { excludeSelf: true },
  });

  // Subscribe to chat updates using user-scoped subscription
  const [{ data: subscriptionData }] = useSubscription({
    query: USER_CHAT_UPDATES_SUBSCRIPTION,
    variables: { userId: currentUser?.id },
    pause: !currentUser?.id,
  });

  // Use chat prop as primary source, update with subscription data
  // Filter subscription data for current chat
  const currentMembers = useMemo(() => {
    if (subscriptionData?.userChatUpdates) {
      const updatedChat = subscriptionData.userChatUpdates;
      if (updatedChat.id === chat.id) {
        return updatedChat.members;
      }
    }
    return chat.members;
  }, [subscriptionData, chat]);
  const users = usersData?.users || [];

  // Debug logging to see what's happening
  useEffect(() => {
    console.log('ChatMembersPanel - Subscription data:', subscriptionData);
    console.log('ChatMembersPanel - Chat prop:', chat);
    console.log('ChatMembersPanel - Current members:', currentMembers);
  }, [subscriptionData, chat, currentMembers]);

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
      // Check if this is a direct message (no name, 2 members)
      const isDirectMessage = !chat.name && chat.members.length === 2;
      
      if (isDirectMessage) {
        // Converting DM to group - get all member IDs + new user
        const allMemberIds = chat.members.map(m => m.id);
        const participantIds = [...allMemberIds, userId];
        
        console.log('Converting DM to group with participants:', participantIds);
        const result = await createOrFindGroupChat({ participantIds });
        
        if (result.error) {
          console.error('Group chat creation error:', result.error);
          notifications.show({
            title: 'Failed to Create Group Chat',
            message: result.error.message,
            color: 'red',
          });
          return;
        }
        
        if (result.data?.createOrFindGroupChat) {
          console.log('Group chat created/found successfully:', result.data.createOrFindGroupChat);
          notifications.show({
            title: 'Group Chat Created',
            message: 'Created group chat with selected members',
            color: 'green',
          });
          navigate(`/chat/${result.data.createOrFindGroupChat.id}`);
        }
      } else {
        // Regular group - just add member
        console.log('Adding member to chat:', { chatId: chat.id, userId });
        const result = await addChatMember({ chatId: chat.id, userId });
        
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

  const handleLeaveChat = async () => {
    if (!window.confirm('Are you sure you want to leave this chat?')) {
      return;
    }
    
    const result = await leaveChat({ chatId: chat.id });
    
    if (result.error) {
      notifications.show({
        title: 'Error',
        message: result.error.message,
        color: 'red',
      });
    } else {
      notifications.show({
        title: 'Left Chat',
        message: `You've left "${chat.name}"`,
        color: 'blue',
      });
      // Navigate away from the chat
      navigate('/chat');
    }
  };

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
                  <Group key={member.id} justify="space-between" p="xs">
                    <Group gap="sm">
                      <Avatar size="sm" color="blue">
                        <IconUser size={16} />
                      </Avatar>
                      <div>
                        <Text size="sm" fw={500}>
                          {member.firstName} {member.lastName}
                          {member.id === currentUser?.id && ' (You)'}
                        </Text>
                        <Text size="xs" c="dimmed">
                          @{member.username}
                        </Text>
                      </div>
                    </Group>
                    {member.id === currentUser?.id && chat.name && (
                      <ActionIcon
                        color="red"
                        variant="subtle"
                        onClick={handleLeaveChat}
                        title="Leave chat"
                      >
                        <IconX size={16} />
                      </ActionIcon>
                    )}
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
