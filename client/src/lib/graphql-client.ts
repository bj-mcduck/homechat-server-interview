import { createClient, fetchExchange } from 'urql';

const getAuthToken = () => {
  return localStorage.getItem('authToken');
};

export const client = createClient({
  url: 'http://localhost:4000/graphql',
  exchanges: [fetchExchange],
  fetchOptions: () => {
    const token = getAuthToken();
    return {
      headers: {
        Authorization: token ? `Bearer ${token}` : '',
      },
    };
  },
});
