import { type ReactNode } from 'react';
import { Navbar } from './Navbar';
import { Sidebar } from './Sidebar';

interface ChatLayoutProps {
  children: ReactNode;
}

export const ChatLayout = ({ children }: ChatLayoutProps) => {
  return (
    <div style={{ height: '100vh', display: 'flex', flexDirection: 'column' }}>
      <Navbar />
      <div style={{ flex: 1, display: 'flex', overflow: 'hidden' }}>
        <Sidebar />
        <main style={{ flex: 1, overflow: 'hidden' }}>
          {children}
        </main>
      </div>
    </div>
  );
};
