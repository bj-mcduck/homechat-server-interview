import { useState } from 'react';
import { useMutation } from 'urql';
import { Button, TextInput, Paper, Title, Stack, Alert } from '@mantine/core';
import { useForm } from '@mantine/form';
import { notifications } from '@mantine/notifications';
import { SIGN_IN_MUTATION } from '../../lib/mutations';
import { useAuth } from '../../hooks/useAuth';

export const SignInForm = () => {
  const [error, setError] = useState<string | null>(null);
  
  const [, signIn] = useMutation(SIGN_IN_MUTATION);
  const { setAuth } = useAuth();

  const form = useForm({
    initialValues: {
      email: '',
      password: '',
    },
    validate: {
      email: (value) => (/^\S+@\S+$/.test(value) ? null : 'Invalid email'),
      password: (value) => (value.length < 1 ? 'Password is required' : null),
    },
  });

  const handleSubmit = async (values: typeof form.values) => {
    setError(null);
    
    try {
      console.log('Submitting sign in with:', values);
      const result = await signIn(values);
      
      console.log('Sign in result:', result);
      
      if (result.error) {
        console.error('Sign in error:', result.error);
        setError(result.error.message);
        notifications.show({
          title: 'Sign In Failed',
          message: result.error.message,
          color: 'red',
        });
        return;
      }
      
      if (result.data?.signIn) {
        console.log('Sign in successful:', result.data.signIn);
        setAuth(result.data.signIn.user, result.data.signIn.token);
        notifications.show({
          title: 'Welcome Back!',
          message: 'Successfully signed in',
          color: 'green',
        });
      }
    } catch (err) {
      console.error('Sign in error:', err);
      setError('Sign in failed. Please try again.');
      notifications.show({
        title: 'Sign In Failed',
        message: 'Sign in failed. Please try again.',
        color: 'red',
      });
    }
  };

  return (
    <Paper shadow="sm" p="xl" style={{ maxWidth: 400, margin: '0 auto' }}>
      <Title order={2} ta="center" mb="md">
        Sign In
      </Title>
      
      {error && (
        <Alert color="red" mb="md">
          {error}
        </Alert>
      )}
      
      <form onSubmit={form.onSubmit(handleSubmit)}>
        <Stack>
          <TextInput
            label="Email"
            placeholder="your@email.com"
            required
            {...form.getInputProps('email')}
          />
          
          <TextInput
            label="Password"
            type="password"
            placeholder="Your password"
            required
            {...form.getInputProps('password')}
          />
          
          <Button type="submit" fullWidth>
            Sign In
          </Button>
        </Stack>
      </form>
      
      <div style={{ textAlign: 'center', marginTop: '1rem' }}>
        Don't have an account?{' '}
        <a href="/register" style={{ color: '#228be6' }}>
          Register
        </a>
      </div>
    </Paper>
  );
};
