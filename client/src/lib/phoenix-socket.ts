import { Socket } from 'phoenix';

let socket: Socket | null = null;
let isConnecting = false;

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
      isConnecting = false;
    });
    
    socket.onClose(() => {
      isConnecting = false;
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
};
