import { useQuery } from 'urql';
import { Paper, Text, Skeleton } from '@mantine/core';
import { CHAT_QUERY } from '../../lib/queries';

interface ChatHeaderProps {
  chatId: string;
}

export const ChatHeader = ({ chatId }: ChatHeaderProps) => {
  const [{ data, fetching }] = useQuery({ 
    query: CHAT_QUERY, 
    variables: { chatId } 
  });

  if (fetching) {
    return (
      <Paper style={{ padding: '1rem', borderBottom: '2px solid rgb(218, 133, 255)' }}>
        <Skeleton height={24} width="60%" />
      </Paper>
    );
  }

  const chat = data?.chat;
  if (!chat) {
    return (
      <Paper style={{ padding: '1rem', borderBottom: '2px solid rgb(218, 133, 255)' }}>
        <Text size="lg" fw={500} c="dimmed">
          Chat not found
        </Text>
      </Paper>
    );
  }

  const getChatTitle = () => {
    // Use server-computed display name
    return chat.displayName;
  };

  return (
    <Paper shadow="sm" style={{ padding: '1rem', borderBottom: '1px solid #e9ecef' }}>
      <Text size="lg" fw={500}>
        {getChatTitle()}
      </Text>
    </Paper>
  );
};
