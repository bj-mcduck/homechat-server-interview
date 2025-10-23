import { Link } from 'react-router-dom';
import { Group, Text, Button, Title, Paper } from '@mantine/core';
import { useAuth } from '../../hooks/useAuth';

export const Navbar = () => {
  const { user, isAuthenticated, signOut } = useAuth();

  return (
    <Paper 
      shadow="sm" 
      style={{ 
        backgroundColor: 'white', 
        borderBottom: '1px solid #e9ecef',
        boxShadow: '0 1px 3px rgba(0, 0, 0, 0.1)',
        height: '64px',
        display: 'flex',
        alignItems: 'center',
        padding: '0 1rem'
      }}
    >
      <Group justify="space-between" style={{ width: '100%' }}>
        <Title order={3} component={Link} to="/" style={{ textDecoration: 'none', color: 'inherit' }}>
          Chat App
        </Title>
        
        <Group gap="md">
          {isAuthenticated ? (
            <>
              <Text size="sm" c="dimmed">
                Welcome, {user?.firstName} {user?.lastName}
              </Text>
              <Button
                variant="subtle"
                size="sm"
                onClick={signOut}
              >
                Sign Out
              </Button>
            </>
          ) : (
            <>
              <Button
                variant="subtle"
                size="sm"
                component={Link}
                to="/register"
              >
                Register
              </Button>
              <Button
                variant="subtle"
                size="sm"
                component={Link}
                to="/signin"
              >
                Sign In
              </Button>
            </>
          )}
        </Group>
      </Group>
    </Paper>
  );
};
