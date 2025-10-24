import { Text } from '@mantine/core';

interface TypingIndicatorProps {
  typingText: string | null;
}

export const TypingIndicator = ({ typingText }: TypingIndicatorProps) => {
  if (!typingText) {
    return null;
  }

  return (
    <div style={{ 
      padding: '0.5rem 1rem',
      borderTop: '1px solid #e9ecef',
      backgroundColor: '#f8f9fa',
      minHeight: '40px',
      display: 'flex',
      alignItems: 'center'
    }}>
      <Text size="sm" c="dimmed" fs="italic">
        {typingText}
      </Text>
    </div>
  );
};
