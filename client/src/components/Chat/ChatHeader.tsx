import { Paper, Text, Skeleton } from '@mantine/core';

interface Chat {
  id: string;
  name: string | null;
  displayName: string;
  private: boolean;
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
  if (!chat) {
    return (
      <Paper shadow="sm" style={{ padding: '1rem', borderBottom: '1px solid #e9ecef' }}>
        <Skeleton height={24} width="60%" />
      </Paper>
    );
  }

  return (
    <Paper shadow="sm" style={{ padding: '1rem', borderBottom: '1px solid #e9ecef' }}>
      <Text size="lg" fw={500}>
        {chat.displayName}
      </Text>
    </Paper>
  );
};
