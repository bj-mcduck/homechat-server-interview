import { useState } from 'react';
import { useMutation } from 'urql';
import { Button, TextInput, Paper, Title, Stack, Alert } from '@mantine/core';
import { useForm } from '@mantine/form';
import { notifications } from '@mantine/notifications';
import { REGISTER_MUTATION } from '../../lib/mutations';
import { useAuth } from '../../hooks/useAuth';

export const RegisterForm = () => {
  const [error, setError] = useState<string | null>(null);
  
  const [, register] = useMutation(REGISTER_MUTATION);
  const { setAuth } = useAuth();

  const form = useForm({
    initialValues: {
      email: '',
      password: '',
      username: '',
      firstName: '',
      lastName: '',
    },
    validate: {
      email: (value) => (/^\S+@\S+$/.test(value) ? null : 'Invalid email'),
      password: (value) => (value.length < 6 ? 'Password must be at least 6 characters' : null),
      username: (value) => (value.length < 3 ? 'Username must be at least 3 characters' : null),
      firstName: (value) => (value.length < 1 ? 'First name is required' : null),
      lastName: (value) => (value.length < 1 ? 'Last name is required' : null),
    },
  });

  const handleSubmit = async (values: typeof form.values) => {
    setError(null);
    
    try {
      console.log('Submitting registration with:', values);
      const result = await register(values);
      
      console.log('Registration result:', result);
      
      if (result.error) {
        console.error('Registration error:', result.error);
        setError(result.error.message);
        notifications.show({
          title: 'Registration Failed',
          message: result.error.message,
          color: 'red',
        });
        return;
      }
      
      if (result.data?.register) {
        console.log('Registration successful:', result.data.register);
        setAuth(result.data.register.user, result.data.register.token);
        notifications.show({
          title: 'Registration Successful',
          message: 'Welcome to Chat App!',
          color: 'green',
        });
      }
    } catch (err) {
      console.error('Registration error:', err);
      setError('Registration failed. Please try again.');
      notifications.show({
        title: 'Registration Failed',
        message: 'Registration failed. Please try again.',
        color: 'red',
      });
    }
  };

  return (
    <Paper shadow="sm" p="xl" style={{ maxWidth: 400, margin: '0 auto' }}>
      <Title order={2} ta="center" mb="md">
        Register
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
          
          <TextInput
            label="Username"
            placeholder="your_username"
            required
            {...form.getInputProps('username')}
          />
          
          <TextInput
            label="First Name"
            placeholder="John"
            required
            {...form.getInputProps('firstName')}
          />
          
          <TextInput
            label="Last Name"
            placeholder="Doe"
            required
            {...form.getInputProps('lastName')}
          />
          
          <Button type="submit" fullWidth>
            Register
          </Button>
        </Stack>
      </form>
      
      <div style={{ textAlign: 'center', marginTop: '1rem' }}>
        Already have an account?{' '}
        <a href="/signin" style={{ color: '#228be6' }}>
          Sign in
        </a>
      </div>
    </Paper>
  );
};
