import { createContext, useContext, useState, type ReactNode } from 'react';
import { type User, type AuthState, getStoredAuth, setStoredAuth, clearStoredAuth } from '../lib/auth';

interface AuthContextType extends AuthState {
  setAuth: (user: User, token: string) => void;
  signOut: () => void;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider = ({ children }: { children: ReactNode }) => {
  const [authState, setAuthState] = useState<AuthState>(getStoredAuth);

  const setAuth = (user: User, token: string) => {
    setStoredAuth(user, token);
    setAuthState({ user, token, isAuthenticated: true });
  };

  const signOut = () => {
    clearStoredAuth();
    setAuthState({ user: null, token: null, isAuthenticated: false });
  };

  return (
    <AuthContext.Provider value={{ ...authState, setAuth, signOut }}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};
