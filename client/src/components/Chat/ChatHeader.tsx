import { useState } from 'react';
import { useMutation } from 'urql';
import { Paper, Text, Skeleton, Group, Menu, ActionIcon } from '@mantine/core';
import { IconDots, IconLock, IconArchive, IconWorld, IconUsers } from '@tabler/icons-react';
import { notifications } from '@mantine/notifications';
import { ARCHIVE_CHAT_MUTATION, UPDATE_CHAT_PRIVACY_MUTATION } from '../../lib/mutations';
import { ConvertToGroupModal } from './ConvertToGroupModal';

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

interface ChatHeaderProps {
  chat: Chat | null;
}

export const ChatHeader = ({ chat }: ChatHeaderProps) => {
  const [isConvertModalOpen, setIsConvertModalOpen] = useState(false);
  
  const [, archiveChat] = useMutation(ARCHIVE_CHAT_MUTATION);
  const [, updateChatPrivacy] = useMutation(UPDATE_CHAT_PRIVACY_MUTATION);

  const handleArchive = async () => {
    if (!chat) return;

    try {
      const result = await archiveChat({ chatId: chat.id });
      
      if (result.error) {
        notifications.show({
          title: 'Error',
          message: result.error.message,
          color: 'red',
        });
      } else {
        notifications.show({
          title: 'Success',
          message: 'Chat archived successfully',
          color: 'green',
        });
      }
    } catch (error) {
      notifications.show({
        title: 'Error',
        message: 'Failed to archive chat',
        color: 'red',
      });
    }
  };

  const handleTogglePrivacy = async () => {
    if (!chat) return;

    try {
      const result = await updateChatPrivacy({ 
        chatId: chat.id, 
        private: !chat.private 
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
          message: `Chat is now ${!chat.private ? 'private' : 'public'}`,
          color: 'green',
        });
      }
    } catch (error) {
      notifications.show({
        title: 'Error',
        message: 'Failed to update chat privacy',
        color: 'red',
      });
    }
  };

  const handleConvertToGroup = () => {
    setIsConvertModalOpen(true);
  };

  const handleConvertSuccess = () => {
    notifications.show({
      title: 'Success',
      message: 'Chat converted to group successfully',
      color: 'green',
    });
  };

  if (!chat) {
    return (
      <Paper shadow="sm" style={{ padding: '1rem', borderBottom: '1px solid #e9ecef' }}>
        <Skeleton height={24} width="60%" />
      </Paper>
    );
  }

  return (
    <>
      <Paper shadow="sm" style={{ padding: '1rem', borderBottom: '1px solid #e9ecef' }}>
        <Group justify="space-between" align="center">
          <Group gap="xs">
            {chat.private && !chat.isDirect && <IconLock size={16} color="gray" />}
            <Text size="lg" fw={500}>
              {chat.displayName}
            </Text>
          </Group>
          
          <Menu shadow="md" width={200}>
            <Menu.Target>
              <ActionIcon variant="subtle" color="gray">
                <IconDots size={16} />
              </ActionIcon>
            </Menu.Target>

            <Menu.Dropdown>
              {!chat.isDirect ? (
                // Named group chat options
                <>
                  <Menu.Item
                    leftSection={<IconArchive size={14} />}
                    onClick={handleArchive}
                    color="red"
                  >
                    Archive Channel
                  </Menu.Item>
                  
                  <Menu.Item
                    leftSection={chat.private ? <IconWorld size={14} /> : <IconLock size={14} />}
                    onClick={handleTogglePrivacy}
                  >
                    {chat.private ? 'Make Public' : 'Make Private'}
                  </Menu.Item>
                </>
              ) : (
                // Direct message options
                <Menu.Item
                  leftSection={<IconUsers size={14} />}
                  onClick={handleConvertToGroup}
                >
                  Convert to Group
                </Menu.Item>
              )}
            </Menu.Dropdown>
          </Menu>
        </Group>
      </Paper>

      <ConvertToGroupModal
        isOpen={isConvertModalOpen}
        onClose={() => setIsConvertModalOpen(false)}
        chatId={chat.id}
        onSuccess={handleConvertSuccess}
      />
    </>
  );
};
