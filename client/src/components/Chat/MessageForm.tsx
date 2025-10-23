import { useState } from 'react';
import { useMutation } from 'urql';
import { Paper, Group, Textarea, ActionIcon } from '@mantine/core';
import { IconSend } from '@tabler/icons-react';
import { SEND_MESSAGE_MUTATION } from '../../lib/mutations';

interface MessageFormProps {
  chatId: string;
}

export const MessageForm = ({ chatId }: MessageFormProps) => {
  const [content, setContent] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  
  const [, sendMessage] = useMutation(SEND_MESSAGE_MUTATION);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!content.trim() || isSubmitting) return;
    
    setIsSubmitting(true);
    
    try {
      await sendMessage({ chatId, content: content.trim() });
      setContent('');
    } catch (error) {
      console.error('Error sending message:', error);
      alert('Failed to send message. Please try again.');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleKeyPress = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSubmit(e);
    }
  };

  return (
    <Paper 
      shadow="sm" 
      style={{ 
        padding: '1rem',
        borderTop: '1px solid #e9ecef',
        backgroundColor: 'white'
      }}
    >
      <form onSubmit={handleSubmit}>
        <Group gap="sm" align="flex-start">
          <Textarea
            value={content}
            onChange={(e) => setContent(e.target.value)}
            onKeyDown={handleKeyPress}
            placeholder="Type your message..."
            autosize
            minRows={1}
            maxRows={4}
            style={{ flex: 1 }}
            styles={{
              input: {
                resize: 'none'
              }
            }}
          />
          <ActionIcon
            type="submit"
            disabled={!content.trim() || isSubmitting}
            loading={isSubmitting}
            size="lg"
            variant="filled"
            color="blue"
            style={{ 
              alignSelf: 'flex-start',
              marginTop: '2px'
            }}
          >
            <IconSend size={16} />
          </ActionIcon>
        </Group>
      </form>
    </Paper>
  );
};
