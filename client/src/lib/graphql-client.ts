import { createClient, fetchExchange, subscriptionExchange } from 'urql';
import { createClient as createWSClient } from 'graphql-ws';

const getAuthToken = () => {
  return localStorage.getItem('authToken');
};

const wsClient = createWSClient({
  url: 'ws://localhost:4000/absinthe-socket',
  connectionParams: () => {
    const token = getAuthToken();
    return token ? { token } : {};
  },
});

export const client = createClient({
  url: 'http://localhost:4000/graphql',
  exchanges: [
    fetchExchange,
    subscriptionExchange({
      forwardSubscription: (operation) => ({
        subscribe: (sink) => ({
          unsubscribe: wsClient.subscribe(operation, sink),
        }),
      }),
    }),
  ],
  fetchOptions: () => {
    const token = getAuthToken();
    console.log('GraphQL client fetchOptions called, token:', token ? 'present' : 'none');
    return {
      headers: {
        'Content-Type': 'application/json',
        Authorization: token ? `Bearer ${token}` : '',
      },
    };
  },
});
