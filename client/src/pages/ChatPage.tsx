import { useParams } from 'react-router-dom';
import { Text, Stack } from '@mantine/core';
import { MessageList } from '../components/Chat/MessageList';
import { MessageForm } from '../components/Chat/MessageForm';

export const ChatPage = () => {
  const { chatId } = useParams<{ chatId: string }>();

  if (!chatId) {
    return (
      <div style={{ 
        flex: 1, 
        display: 'flex', 
        alignItems: 'center', 
        justifyContent: 'center' 
      }}>
        <Text c="dimmed">No chat selected</Text>
      </div>
    );
  }

  return (
    <Stack gap={0} style={{ flex: 1, height: '100%' }}>
      <div style={{ flex: 1, overflow: 'hidden' }}>
        <MessageList chatId={chatId} />
      </div>
      <div style={{ flexShrink: 0 }}>
        <MessageForm chatId={chatId} />
      </div>
    </Stack>
  );
};
