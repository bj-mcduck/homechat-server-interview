import { format } from 'date-fns';
import { Badge, Text } from '@mantine/core';

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

interface MessageItemProps {
  message: Message;
}

export const MessageItem = ({ message }: MessageItemProps) => {
  const formatTime = (dateString: string) => {
    try {
      return format(new Date(dateString), 'HH:mm');
    } catch {
      return 'Invalid time';
    }
  };

  return (
    <div style={{ 
      display: 'flex', 
      flexDirection: 'column',
      gap: '0.25rem',
      marginBottom: '0.75rem'
    }}>
      {/* Header with name and time */}
      <div style={{ 
        display: 'flex', 
        alignItems: 'center',
        justifyContent: 'space-between',
        gap: '0.5rem'
      }}>
        <Badge 
          color="blue" 
          variant="filled"
          style={{ fontWeight: 500 }}
        >
          {message.user.firstName} {message.user.lastName}
        </Badge>
        <Text size="xs" c="dimmed" style={{ color: '#868e96' }}>
          {formatTime(message.insertedAt)}
        </Text>
      </div>
      
      {/* Message content bubble */}
      <div style={{
        backgroundColor: '#f1f3f5',
        padding: '0.75rem 1rem',
        borderRadius: '12px',
        maxWidth: '80%',
        wordWrap: 'break-word'
      }}>
        <Text size="sm">{message.content}</Text>
      </div>
    </div>
  );
};
