import { useState, useMemo } from 'react';
import { useMutation, useQuery } from 'urql';
import { Paper, Title, Stack, Text, ScrollArea, Group, Avatar, ActionIcon, TextInput, Divider, Skeleton } from '@mantine/core';
import { IconPlus, IconUser } from '@tabler/icons-react';
import { notifications } from '@mantine/notifications';
import { ADD_CHAT_MEMBER_MUTATION } from '../../lib/mutations';
import { USERS_QUERY } from '../../lib/queries';

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

  // For now, we'll need to get chat data to show current members
  // This would ideally come from a chat query, but for now we'll show a placeholder
  const currentMembers: any[] = []; // TODO: Get from chat query
  const users = usersData?.users || [];

  const filteredUsers = useMemo(() => {
    if (!searchTerm.trim()) return users;
    
    const term = searchTerm.toLowerCase();
    return users.filter(user => 
      user.firstName.toLowerCase().includes(term) ||
      user.lastName.toLowerCase().includes(term) ||
      user.username.toLowerCase().includes(term)
    );
  }, [users, searchTerm]);

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

  return (
    <Paper shadow="sm" style={{ height: '100vh', width: 300, padding: '1rem' }}>
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
                currentMembers.map(member => (
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
              ) : filteredUsers.length === 0 ? (
                <Text size="sm" c="dimmed" ta="center" py="md">
                  {searchTerm ? 'No users found' : 'Search for users to add'}
                </Text>
              ) : (
                filteredUsers.map(user => (
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
