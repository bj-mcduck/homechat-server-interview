import { useEffect, useRef, useState } from 'react';
import { useQuery, useSubscription } from 'urql';
import { MESSAGES_QUERY } from '../../lib/queries';
import { USER_MESSAGES_SUBSCRIPTION } from '../../lib/subscriptions';
import { MessageItem } from './MessageItem';
import { useAuth } from '../../hooks/useAuth';

interface Message {
  id: string;
  content: string;
  insertedAt: string;
  user: {
    id: string;
    username: string;
    firstName: string;
    lastName: string;
  };
}

interface MessageListProps {
  chatId: string;
}

export const MessageList = ({ chatId }: MessageListProps) => {
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const [allMessages, setAllMessages] = useState<Message[]>([]);
  const { user: currentUser } = useAuth();
  
  const [{ data, fetching, error }] = useQuery({
    query: MESSAGES_QUERY,
    variables: { chatId },
    requestPolicy: 'cache-and-network',
  });

  // Subscribe to new messages using user-scoped subscription
  const [{ data: subscriptionData }] = useSubscription({
    query: USER_MESSAGES_SUBSCRIPTION,
    variables: { userId: currentUser?.id },
    pause: !currentUser?.id || !chatId, // Pause if user not logged in or chatId not available
  });

  // Combine initial messages with subscription updates
  useEffect(() => {
    if (data?.messages) {
      setAllMessages(data.messages);
    }
  }, [data?.messages]);

  useEffect(() => {
    if (subscriptionData?.userMessages) {
      const event = subscriptionData.userMessages;
      // Only process messages for the current chat
      if (event.chatId === chatId) {
        const newMessage = event.message;
        setAllMessages(prev => {
          // Check if message already exists to avoid duplicates
          const exists = prev.some(msg => msg.id === newMessage.id);
          if (exists) return prev;
          return [...prev, newMessage];
        });
      }
    }
  }, [subscriptionData, chatId]);

  const messages = allMessages;

  // Auto-scroll to bottom when new messages arrive
  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  if (fetching && !data) {
    return (
      <div style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        <div style={{ color: '#666' }}>Loading messages...</div>
      </div>
    );
  }

  if (error) {
    return (
      <div style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        <div style={{ color: '#dc3545' }}>Error loading messages</div>
      </div>
    );
  }

  return (
    <div style={{ flex: 1, overflowY: 'auto', padding: '1rem' }}>
      {messages.length === 0 ? (
        <div style={{ 
          display: 'flex', 
          alignItems: 'center', 
          justifyContent: 'center', 
          height: '100%', 
          color: '#666' 
        }}>
          No messages yet. Start the conversation!
        </div>
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
          {messages.map((message) => (
            <MessageItem key={message.id} message={message} />
          ))}
        </div>
      )}
      <div ref={messagesEndRef} />
    </div>
  );
};
