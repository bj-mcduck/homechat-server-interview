import { useParams } from 'react-router-dom';
import { useQuery } from 'urql';
import { Text, Stack, Skeleton } from '@mantine/core';
import { MessageList } from '../components/Chat/MessageList';
import { MessageForm } from '../components/Chat/MessageForm';
import { ChatHeader } from '../components/Chat/ChatHeader';
import { ChatMembersPanel } from '../components/Chat/ChatMembersPanel';
import { TypingIndicator } from '../components/Chat/TypingIndicator';
import { useTypingIndicator } from '../hooks/useTypingIndicator';
import { getPhoenixSocket } from '../lib/phoenix-socket';
import { CHAT_QUERY } from '../lib/queries';

export const ChatPage = () => {
  const { chatId } = useParams<{ chatId: string }>();

  const [{ data: chatData, fetching: chatFetching, error }] = useQuery({
    query: CHAT_QUERY,
    variables: { chatId },
    requestPolicy: 'cache-and-network',
  });

  const socket = getPhoenixSocket();
  const { typingText, startTyping, stopTyping } = useTypingIndicator(chatId, socket);

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

  // Show loading only on initial load (no data yet)
  if (chatFetching && !chatData?.chat) {
    return (
      <div style={{ 
        flex: 1, 
        display: 'flex', 
        alignItems: 'center', 
        justifyContent: 'center' 
      }}>
        <Skeleton height={24} width="60%" />
      </div>
    );
  }

  // Show error only if we have an error or explicitly no chat after loading
  if (error || (!chatFetching && chatData && !chatData.chat)) {
    return (
      <div style={{ 
        flex: 1, 
        display: 'flex', 
        alignItems: 'center', 
        justifyContent: 'center' 
      }}>
        <Text c="dimmed">Chat not found</Text>
      </div>
    );
  }

  const chat = chatData?.chat;

  return (
    <Stack gap={0} style={{ flex: 1, height: '100%' }}>
      <ChatHeader chat={chat || null} />
      <div style={{ flex: 1, overflow: 'hidden', display: 'flex' }}>
        <div style={{ flex: 1, overflow: 'hidden' }}>
          <MessageList chatId={chatId} />
        </div>
        <div style={{ width: 300, borderLeft: '1px solid #e9ecef' }}>
          <ChatMembersPanel chat={chat || null} />
        </div>
      </div>
            <div style={{ flexShrink: 0 }}>
              <MessageForm 
                chatId={chatId} 
                isArchived={chat?.state === 'inactive'} 
                startTyping={startTyping}
                stopTyping={stopTyping}
              />
              <TypingIndicator typingText={typingText} />
            </div>
    </Stack>
  );
};
