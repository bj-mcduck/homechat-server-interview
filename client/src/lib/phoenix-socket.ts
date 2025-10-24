import { Socket } from 'phoenix';

let socket: Socket | null = null;
let isConnecting = false;
let reconnectAttempts = 0;
const MAX_RECONNECT_ATTEMPTS = 5;
const RECONNECT_DELAY = 1000; // Start with 1 second

export const getPhoenixSocket = (): Socket | null => {
  const token = localStorage.getItem('authToken');
  
  if (!token) return null;
  
  if (!socket && !isConnecting) {
    isConnecting = true;
    
    socket = new Socket('ws://localhost:4000/socket', {
      params: { token }
    });
    
    socket.onOpen(() => {
      isConnecting = false;
    });
    
    socket.onError((error) => {
      console.error('Phoenix socket error:', error);
      isConnecting = false;
      attemptReconnect();
    });
    
    socket.onClose(() => {
      console.log('Phoenix socket closed');
      isConnecting = false;
      attemptReconnect();
    });
    
    socket.connect();
  } else if (!socket) {
    return null;
  }
  
  return socket;
};

export const disconnectPhoenixSocket = () => {
  if (socket) {
    socket.disconnect();
    socket = null;
  }
  reconnectAttempts = 0;
};

// Reconnection logic with exponential backoff
const attemptReconnect = () => {
  if (reconnectAttempts >= MAX_RECONNECT_ATTEMPTS) {
    console.log('Max reconnection attempts reached');
    return;
  }

  const delay = RECONNECT_DELAY * Math.pow(2, reconnectAttempts);
  console.log(`Attempting to reconnect in ${delay}ms (attempt ${reconnectAttempts + 1})`);
  
  setTimeout(() => {
    reconnectAttempts++;
    const token = localStorage.getItem('authToken');
    if (token) {
      socket = null; // Reset socket to force reconnection
      getPhoenixSocket();
    }
  }, delay);
};

// Listen for online/offline events
if (typeof window !== 'undefined') {
  window.addEventListener('online', () => {
    console.log('Network back online, attempting to reconnect...');
    reconnectAttempts = 0;
    const token = localStorage.getItem('authToken');
    if (token && !socket) {
      getPhoenixSocket();
    }
  });

  window.addEventListener('offline', () => {
    console.log('Network offline');
    if (socket) {
      socket.disconnect();
    }
  });
}
