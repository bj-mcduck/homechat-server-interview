import { useState } from 'react';
import { useMutation } from 'urql';
import { useNavigate } from 'react-router-dom';
import { Modal, TextInput, Button, Stack, Text, Group } from '@mantine/core';
import { useForm } from '@mantine/form';
import { notifications } from '@mantine/notifications';
import { CREATE_GROUP_CHAT_MUTATION } from '../../lib/mutations';

interface CreateGroupChatModalProps {
  opened: boolean;
  onClose: () => void;
}

export const CreateGroupChatModal = ({ opened, onClose }: CreateGroupChatModalProps) => {
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();
  
  const [, createGroupChat] = useMutation(CREATE_GROUP_CHAT_MUTATION);

  const form = useForm({
    initialValues: {
      name: '',
    },
    validate: {
      name: (value) => (value.length < 1 ? 'Chat name is required' : null),
    },
  });

  const handleSubmit = async (values: typeof form.values) => {
    setLoading(true);
    
    try {
      console.log('Creating group chat with:', values);
      const result = await createGroupChat({ name: values.name });
      
      console.log('Group chat creation result:', result);
      
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
          message: `"${values.name}" has been created`,
          color: 'green',
        });
        onClose();
        form.reset();
        navigate(`/chat/${result.data.createGroupChat.id}`);
      }
    } catch (err) {
      console.error('Group chat creation error:', err);
      notifications.show({
        title: 'Failed to Create Group Chat',
        message: 'An unexpected error occurred',
        color: 'red',
      });
    } finally {
      setLoading(false);
    }
  };

  const handleClose = () => {
    form.reset();
    onClose();
  };

  return (
    <Modal
      opened={opened}
      onClose={handleClose}
      title="Create Group Chat"
      centered
    >
      <form onSubmit={form.onSubmit(handleSubmit)}>
        <Stack>
          <Text size="sm" c="dimmed">
            Create a new group chat. You can add members after creation.
          </Text>
          
          <TextInput
            label="Chat Name"
            placeholder="Enter group chat name"
            required
            {...form.getInputProps('name')}
          />
          
          <Group justify="flex-end" mt="md">
            <Button variant="subtle" onClick={handleClose}>
              Cancel
            </Button>
            <Button type="submit" loading={loading}>
              Create Chat
            </Button>
          </Group>
        </Stack>
      </form>
    </Modal>
  );
};
