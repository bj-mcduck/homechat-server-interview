import { useState } from 'react';
import { useMutation } from 'urql';
import { Modal, TextInput, Button, Stack, Text } from '@mantine/core';
import { notifications } from '@mantine/notifications';
import { CONVERT_TO_GROUP_MUTATION } from '../../lib/mutations';

interface ConvertToGroupModalProps {
  isOpen: boolean;
  onClose: () => void;
  chatId: string;
  onSuccess: () => void;
}

export const ConvertToGroupModal = ({ isOpen, onClose, chatId, onSuccess }: ConvertToGroupModalProps) => {
  const [name, setName] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);

  const [, convertToGroup] = useMutation(CONVERT_TO_GROUP_MUTATION);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!name.trim()) {
      notifications.show({
        title: 'Error',
        message: 'Please enter a group name',
        color: 'red',
      });
      return;
    }

    setIsSubmitting(true);

    try {
      const result = await convertToGroup({
        chatId,
        name: name.trim(),
      });

      if (result.error) {
        notifications.show({
          title: 'Error',
          message: result.error.message,
          color: 'red',
        });
      } else {
        notifications.show({
          title: 'Success',
          message: 'Chat converted to group successfully',
          color: 'green',
        });
        
        setName('');
        onSuccess();
        onClose();
      }
    } catch (error) {
      notifications.show({
        title: 'Error',
        message: 'Failed to convert chat to group',
        color: 'red',
      });
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleClose = () => {
    setName('');
    onClose();
  };

  return (
    <Modal
      opened={isOpen}
      onClose={handleClose}
      title="Convert to Group Chat"
      size="sm"
    >
      <form onSubmit={handleSubmit}>
        <Stack gap="md">
          <Text size="sm" c="dimmed">
            Give this direct message a name to convert it to a group chat.
          </Text>
          
          <TextInput
            label="Group Name"
            placeholder="Enter group name"
            value={name}
            onChange={(e) => setName(e.target.value)}
            required
            disabled={isSubmitting}
            autoFocus
          />

          <div style={{ display: 'flex', gap: '0.5rem', justifyContent: 'flex-end' }}>
            <Button
              variant="outline"
              onClick={handleClose}
              disabled={isSubmitting}
            >
              Cancel
            </Button>
            <Button
              type="submit"
              loading={isSubmitting}
              disabled={!name.trim()}
            >
              Convert to Group
            </Button>
          </div>
        </Stack>
      </form>
    </Modal>
  );
};
