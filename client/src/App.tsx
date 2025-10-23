import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import { Provider } from 'urql';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { client } from './lib/graphql-client';
import { AuthProvider } from './hooks/useAuth';
import { AuthGuard } from './components/Auth/AuthGuard';
import { ChatLayout } from './components/Layout/ChatLayout';
import { HomePage } from './pages/HomePage';
import { Register } from './pages/Register';
import { SignIn } from './pages/SignIn';
import { ChatPage } from './pages/ChatPage';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 1000 * 60 * 5, // 5 minutes
      refetchOnWindowFocus: false,
    },
  },
});

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <Provider value={client}>
        <AuthProvider>
          <Router>
            <Routes>
              <Route path="/" element={<HomePage />} />
              <Route path="/register" element={<Register />} />
              <Route path="/signin" element={<SignIn />} />
              <Route
                path="/chat"
                element={
                  <AuthGuard>
                    <ChatLayout>
                      <div className="flex-1 flex items-center justify-center">
                        <div className="text-gray-500">Select a chat to start messaging</div>
                      </div>
                    </ChatLayout>
                  </AuthGuard>
                }
              />
              <Route
                path="/chat/:chatId"
                element={
                  <AuthGuard>
                    <ChatLayout>
                      <ChatPage />
                    </ChatLayout>
                  </AuthGuard>
                }
              />
            </Routes>
          </Router>
        </AuthProvider>
      </Provider>
    </QueryClientProvider>
  );
}

export default App;