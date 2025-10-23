import { useState, useMemo } from 'react';
import { useMutation, useQuery } from 'urql';
import { useNavigate } from 'react-router-dom';
import { Modal, TextInput, Button, Stack, Text, ScrollArea, Group, Avatar, ActionIcon, Checkbox } from '@mantine/core';
import { IconPlus, IconUser, IconCheck } from '@tabler/icons-react';
import { notifications } from '@mantine/notifications';
import { CREATE_DIRECT_CHAT_MUTATION, CREATE_GROUP_CHAT_MUTATION } from '../../lib/mutations';
import { USERS_QUERY } from '../../lib/queries';

interface CreateDirectMessageModalProps {
  opened: boolean;
  onClose: () => void;
}

export const CreateDirectMessageModal = ({ opened, onClose }: CreateDirectMessageModalProps) => {
  const [loading, setLoading] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedUserIds, setSelectedUserIds] = useState<Set<string>>(new Set());
  const navigate = useNavigate();
  
  const [, createDirectChat] = useMutation(CREATE_DIRECT_CHAT_MUTATION);
  const [, createGroupChat] = useMutation(CREATE_GROUP_CHAT_MUTATION);
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

  const toggleUserSelection = (userId: string) => {
    setSelectedUserIds(prev => {
      const newSet = new Set(prev);
      if (newSet.has(userId)) {
        newSet.delete(userId);
      } else {
        newSet.add(userId);
      }
      return newSet;
    });
  };

  const handleCreateChat = async () => {
    if (selectedUserIds.size === 0) return;
    
    setLoading(true);
    
    try {
      const userIds = Array.from(selectedUserIds);
      
      if (userIds.length === 1) {
        // Create direct chat
        console.log('Creating direct chat with user:', userIds[0]);
        const result = await createDirectChat({ userId: userIds[0] });
        
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
            message: 'Started conversation',
            color: 'green',
          });
          onClose();
          setSearchTerm('');
          setSelectedUserIds(new Set());
          navigate(`/chat/${result.data.createDirectChat.id}`);
        }
      } else {
        // Create group chat
        console.log('Creating group chat with users:', userIds);
        const result = await createGroupChat({ 
          name: `Group Chat`, 
          participantIds: userIds 
        });
        
        if (result.error) {
          console.error('Group chat creation error:', result.error);
          notifications.show({
            title: 'Failed to Create Group Chat',
            message: result.error.message,
            color: 'red',
          });
          return;
        }
        
        if (result.data?.createGroupChat) {
          console.log('Group chat created successfully:', result.data.createGroupChat);
          notifications.show({
            title: 'Group Chat Created',
            message: `Created group with ${userIds.length} members`,
            color: 'green',
          });
          onClose();
          setSearchTerm('');
          setSelectedUserIds(new Set());
          navigate(`/chat/${result.data.createGroupChat.id}`);
        }
      }
    } catch (err) {
      console.error('Chat creation error:', err);
      notifications.show({
        title: 'Failed to Create Chat',
        message: 'An unexpected error occurred',
        color: 'red',
      });
    } finally {
      setLoading(false);
    }
  };

  const handleClose = () => {
    setSearchTerm('');
    setSelectedUserIds(new Set());
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
          Select users to create a chat. Choose one for direct message, or multiple for group chat.
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
                    variant={selectedUserIds.has(user.id) ? "filled" : "outline"}
                    color={selectedUserIds.has(user.id) ? "green" : "blue"}
                    size="sm"
                    onClick={() => toggleUserSelection(user.id)}
                  >
                    {selectedUserIds.has(user.id) ? <IconCheck size={16} /> : <IconPlus size={16} />}
                  </ActionIcon>
                </Group>
              ))
            )}
          </Stack>
        </ScrollArea>
        
        <Group justify="space-between" mt="md">
          <Text size="sm" c="dimmed">
            {selectedUserIds.size > 0 ? `${selectedUserIds.size} user${selectedUserIds.size === 1 ? '' : 's'} selected` : 'No users selected'}
          </Text>
          <Group>
            <Button variant="subtle" onClick={handleClose}>
              Cancel
            </Button>
            <Button 
              onClick={handleCreateChat}
              loading={loading}
              disabled={selectedUserIds.size === 0}
            >
              {selectedUserIds.size === 1 ? 'Create Direct Message' : 'Create Group Chat'}
            </Button>
          </Group>
        </Group>
      </Stack>
    </Modal>
  );
};
