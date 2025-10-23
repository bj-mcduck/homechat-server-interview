import { useQuery } from 'urql';
import { Paper, Text, Skeleton } from '@mantine/core';
import { CHAT_QUERY } from '../../lib/queries';
import { useAuth } from '../../hooks/useAuth';

interface ChatHeaderProps {
  chatId: string;
}

export const ChatHeader = ({ chatId }: ChatHeaderProps) => {
  const { user: currentUser } = useAuth();
  const [{ data, fetching }] = useQuery({ 
    query: CHAT_QUERY, 
    variables: { chatId } 
  });

  if (fetching) {
    return (
      <Paper shadow="sm" style={{ padding: '1rem', borderBottom: '1px solid #e9ecef' }}>
        <Skeleton height={24} width="60%" />
      </Paper>
    );
  }

  const chat = data?.chat;
  if (!chat) {
    return (
      <Paper shadow="sm" style={{ padding: '1rem', borderBottom: '1px solid #e9ecef' }}>
        <Text size="lg" fw={500} c="dimmed">
          Chat not found
        </Text>
      </Paper>
    );
  }

  const getChatTitle = () => {
    if (chat.name) {
      return chat.name;
    }
    
    // For direct messages, show the other participants
    const otherMembers = chat.members.filter(member => member.id !== currentUser?.id);
    if (otherMembers.length === 1) {
      return `${otherMembers[0].firstName} ${otherMembers[0].lastName}`;
    } else if (otherMembers.length > 1) {
      return otherMembers.map(member => `${member.firstName} ${member.lastName}`).join(', ');
    }
    
    return 'Direct Message';
  };

  return (
    <Paper shadow="sm" style={{ padding: '1rem', borderBottom: '1px solid #e9ecef' }}>
      <Text size="lg" fw={500}>
        {getChatTitle()}
      </Text>
    </Paper>
  );
};
