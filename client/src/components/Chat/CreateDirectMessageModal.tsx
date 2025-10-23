import { useState, useMemo } from 'react';
import { useMutation, useQuery } from 'urql';
import { useNavigate } from 'react-router-dom';
import { Modal, TextInput, Button, Stack, Text, ScrollArea, Group, Avatar, ActionIcon } from '@mantine/core';
import { IconPlus, IconUser } from '@tabler/icons-react';
import { notifications } from '@mantine/notifications';
import { CREATE_DIRECT_CHAT_MUTATION } from '../../lib/mutations';
import { USERS_QUERY } from '../../lib/queries';

interface CreateDirectMessageModalProps {
  opened: boolean;
  onClose: () => void;
}

export const CreateDirectMessageModal = ({ opened, onClose }: CreateDirectMessageModalProps) => {
  const [loading, setLoading] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');
  const navigate = useNavigate();
  
  const [, createDirectChat] = useMutation(CREATE_DIRECT_CHAT_MUTATION);
  const [{ data: usersData, fetching: usersFetching }] = useQuery({
    query: USERS_QUERY,
    variables: { excludeSelf: true },
  });

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

  const handleCreateDirectChat = async (userId: string, userName: string) => {
    setLoading(true);
    
    try {
      console.log('Creating direct chat with user:', userId);
      const result = await createDirectChat({ userId });
      
      console.log('Direct chat creation result:', result);
      
      if (result.error) {
        console.error('Direct chat creation error:', result.error);
        notifications.show({
          title: 'Failed to Create Direct Message',
          message: result.error.message,
          color: 'red',
        });
        return;
      }
      
      if (result.data?.createDirectChat) {
        console.log('Direct chat created successfully:', result.data.createDirectChat);
        notifications.show({
          title: 'Direct Message Created',
          message: `Started conversation with ${userName}`,
          color: 'green',
        });
        onClose();
        setSearchTerm('');
        navigate(`/chat/${result.data.createDirectChat.id}`);
      }
    } catch (err) {
      console.error('Direct chat creation error:', err);
      notifications.show({
        title: 'Failed to Create Direct Message',
        message: 'An unexpected error occurred',
        color: 'red',
      });
    } finally {
      setLoading(false);
    }
  };

  const handleClose = () => {
    setSearchTerm('');
    onClose();
  };

  return (
    <Modal
      opened={opened}
      onClose={handleClose}
      title="Start Direct Message"
      centered
      size="md"
    >
      <Stack>
        <Text size="sm" c="dimmed">
          Search for a user to start a direct message conversation.
        </Text>
        
        <TextInput
          placeholder="Search users by name or username..."
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
        />
        
        <ScrollArea style={{ height: 300 }}>
          <Stack gap="xs">
            {usersFetching ? (
              <Text size="sm" c="dimmed" ta="center" py="md">
                Loading users...
              </Text>
            ) : filteredUsers.length === 0 ? (
              <Text size="sm" c="dimmed" ta="center" py="md">
                {searchTerm ? 'No users found matching your search' : 'No users available'}
              </Text>
            ) : (
              filteredUsers.map(user => (
                <Group key={user.id} justify="space-between" p="sm" style={{ 
                  border: '1px solid #e9ecef', 
                  borderRadius: '8px',
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
                    loading={loading}
                    onClick={() => handleCreateDirectChat(user.id, `${user.firstName} ${user.lastName}`)}
                  >
                    <IconPlus size={16} />
                  </ActionIcon>
                </Group>
              ))
            )}
          </Stack>
        </ScrollArea>
        
        <Group justify="flex-end" mt="md">
          <Button variant="subtle" onClick={handleClose}>
            Cancel
          </Button>
        </Group>
      </Stack>
    </Modal>
  );
};
