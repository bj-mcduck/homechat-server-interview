import { createClient, fetchExchange, subscriptionExchange } from 'urql';
import { Socket as PhoenixSocket } from 'phoenix';
import { create, send, observe } from '@absinthe/socket';

const getAuthToken = () => {
  return localStorage.getItem('authToken');
};

// Create Phoenix Socket connection
const phoenixSocket = new PhoenixSocket('ws://localhost:4000/socket', {
  params: () => {
    const token = getAuthToken();
    return token ? { token } : {};
  },
});

// Create Absinthe Socket
const absintheSocket = create(phoenixSocket);

// Create subscription exchange using Absinthe Socket
const absintheSubscriptionExchange = subscriptionExchange({
  forwardSubscription: (operation) => {
    return {
      subscribe: (sink) => {
        console.log('Creating subscription for operation:', operation);
        
        // Send the subscription request
        const notifier = send(absintheSocket, {
          operation: operation.query,
          variables: operation.variables,
        });
        
        console.log('Created notifier:', notifier);
        
        // Observe the notifier
        const observedNotifier = observe(absintheSocket, notifier, {
          onAbort: (error) => {
            console.log('Subscription aborted:', error);
            sink.error(error);
          },
          onError: (error) => {
            console.error('Subscription error:', error);
            sink.error(error);
          },
          onStart: (notifier) => {
            console.log('Subscription started:', notifier);
          },
          onResult: (result) => {
            console.log('Subscription result:', result);
            sink.next(result);
          },
        });

        return {
          unsubscribe: () => {
            console.log('Unsubscribing from subscription');
            // The notifier will be automatically cleaned up by Absinthe
          },
        };
      },
    };
  },
});

export const client = createClient({
  url: 'http://localhost:4000/graphql',
  exchanges: [
    fetchExchange,
    absintheSubscriptionExchange,
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
