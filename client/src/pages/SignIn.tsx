import { SignInForm } from '../components/Auth/SignInForm';

export const SignIn = () => {
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
      <div style={{ textAlign: 'center', marginBottom: '2rem' }}>
        <h1 style={{ 
          fontSize: '2rem', 
          fontWeight: 'bold', 
          color: '#1a1a1a',
          margin: 0
        }}>
          Sign in to your account
        </h1>
        <p style={{ 
          marginTop: '0.5rem', 
          fontSize: '0.875rem', 
          color: '#666' 
        }}>
          Welcome back!
        </p>
      </div>
      <SignInForm />
    </div>
  );
};
