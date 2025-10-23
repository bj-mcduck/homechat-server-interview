import { useEffect, useRef, useState } from 'react';
import { useQuery, useSubscription } from 'urql';
import { MESSAGES_QUERY } from '../../lib/queries';
import { MESSAGE_SENT_SUBSCRIPTION } from '../../lib/subscriptions';
import { MessageItem } from './MessageItem';

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
  
  const [{ data, fetching, error }] = useQuery({
    query: MESSAGES_QUERY,
    variables: { chatId },
    requestPolicy: 'cache-and-network',
  });

  // Subscribe to new messages
  const [{ data: subscriptionData }] = useSubscription({
    query: MESSAGE_SENT_SUBSCRIPTION,
    variables: { chatId },
  });

  // Combine initial messages with subscription updates
  useEffect(() => {
    if (data?.messages) {
      setAllMessages(data.messages);
    }
  }, [data?.messages]);

  useEffect(() => {
    if (subscriptionData?.messageSent) {
      const newMessage = subscriptionData.messageSent;
      setAllMessages(prev => {
        // Check if message already exists to avoid duplicates
        const exists = prev.some(msg => msg.id === newMessage.id);
        if (exists) return prev;
        return [...prev, newMessage];
      });
    }
  }, [subscriptionData]);

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
