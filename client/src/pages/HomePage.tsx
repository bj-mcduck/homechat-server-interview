import { Navigate } from 'react-router-dom';
import { Button, Paper, Title, Stack, Text } from '@mantine/core';
import { useAuth } from '../hooks/useAuth';

export const HomePage = () => {
  const { user } = useAuth();

  if (user) {
    return <Navigate to="/chat" replace />;
  }

  return (
    <div style={{ 
      minHeight: '100vh', 
      backgroundColor: '#f8f9fa', 
      display: 'flex', 
      flexDirection: 'column', 
      alignItems: 'center', 
      justifyContent: 'center',
      padding: '3rem 1rem'
    }}>
      <Paper shadow="sm" p="xl" style={{ maxWidth: 500, textAlign: 'center' }}>
        <Title order={1} mb="md">
          Welcome to Chat App
        </Title>
        <Text size="lg" c="dimmed" mb="xl">
          Connect with your team and friends through real-time messaging
        </Text>
        
        <Stack gap="md">
          <Button 
            size="lg" 
            fullWidth
            component="a"
            href="/register"
          >
            Get Started
          </Button>
          <Button 
            variant="outline" 
            size="lg" 
            fullWidth
            component="a"
            href="/signin"
          >
            Sign In
          </Button>
        </Stack>
      </Paper>
    </div>
  );
};
