import { createClient, fetchExchange, subscriptionExchange } from 'urql';
import { cacheExchange } from '@urql/exchange-graphcache';
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

// Add connection status logging
phoenixSocket.onOpen(() => console.log('✅ Phoenix Socket Connected'));
phoenixSocket.onError((error) => console.error('❌ Phoenix Socket Error:', error));
phoenixSocket.onClose(() => console.log('🔌 Phoenix Socket Closed'));

// Connect the socket
phoenixSocket.connect();

// Create Absinthe Socket
const absintheSocket = create(phoenixSocket);

// Create subscription exchange using Absinthe Socket
const absintheSubscriptionExchange = subscriptionExchange({
  forwardSubscription: (operation) => {
    return {
      subscribe: (sink) => {
        // Send the subscription request
        const notifier = send(absintheSocket, {
          operation: operation.query,
          variables: operation.variables,
        });
        
        // Observe the notifier
        const observedNotifier = observe(absintheSocket, notifier, {
          onAbort: (error) => sink.error(error),
          onError: (error) => sink.error(error),
          onStart: (_notifier) => {},
          onResult: (result) => sink.next(result),
        });

        return {
          unsubscribe: () => {},
        };
      },
    };
  },
});

export const client = createClient({
  url: 'http://localhost:4000/graphql',
  exchanges: [
    cacheExchange({
      updates: {
        Mutation: {
          leaveChat: (_result, _args, cache, _info) => {
            cache.invalidate('Query', 'discoverableChats');
          },
          createGroupChat: (_result, _args, cache, _info) => {
            cache.invalidate('Query', 'discoverableChats');
          },
          createDirectChat: (_result, _args, cache, _info) => {
            cache.invalidate('Query', 'discoverableChats');
          },
          createOrFindGroupChat: (_result, _args, cache, _info) => {
            cache.invalidate('Query', 'discoverableChats');
          },
          addChatMember: (_result, _args, cache, _info) => {
            cache.invalidate('Query', 'discoverableChats');
          },
          archiveChat: (_result, _args, cache, _info) => {
            cache.invalidate('Query', 'discoverableChats');
          },
          convertToGroup: (_result, _args, cache, _info) => {
            cache.invalidate('Query', 'discoverableChats');
          },
          updateChatPrivacy: (_result, _args, cache, _info) => {
            cache.invalidate('Query', 'discoverableChats');
          },
        },
      },
    }),
    fetchExchange,
    absintheSubscriptionExchange,
  ],
  fetchOptions: () => {
    const token = getAuthToken();
    return {
      headers: {
        'Content-Type': 'application/json',
        Authorization: token ? `Bearer ${token}` : '',
      },
    };
  },
});
