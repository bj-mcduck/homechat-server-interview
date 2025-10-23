import { createClient, fetchExchange } from 'urql';

const getAuthToken = () => {
  return localStorage.getItem('authToken');
};

export const client = createClient({
  url: 'http://localhost:4000/graphql',
  exchanges: [fetchExchange],
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
