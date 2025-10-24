import React, { createContext, useContext, useEffect, useState, useCallback, type ReactNode, useRef } from 'react';
import { getPhoenixSocket } from '../lib/phoenix-socket';
import { Channel } from 'phoenix';

interface UserPresence {
  userId: string;
  username: string;
  fullName: string;
  status: 'online' | 'away' | 'offline';
  lastSeen: string;
  deviceType: string;
}

interface PresenceState {
  onlineUsers: Map<string, UserPresence>;
  isUserOnline: (userId: string) => boolean;
  getUserStatus: (userId: string) => UserPresence | null;
  getOnlineUsers: () => UserPresence[];
  isConnected: boolean;
}

const PresenceContext = createContext<PresenceState | null>(null);

interface PresenceProviderProps {
  children: ReactNode;
}

export const PresenceProvider: React.FC<PresenceProviderProps> = ({ children }) => {
  const [onlineUsers, setOnlineUsers] = useState<Map<string, UserPresence>>(new Map());
  const [isConnected, setIsConnected] = useState(false);
  const debounceTimeoutRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const channelRef = useRef<Channel | null>(null);


  // Join Phoenix presence channel for real-time tracking
  useEffect(() => {
    const socket = getPhoenixSocket();
    if (!socket) return;

    const channel = socket.channel('presence:global', {});
    
    // Listen for presence state changes
    channel.on('presence_state', (payload: any) => {
      console.log('Presence state received:', payload);
      updatePresenceFromPhoenix(payload);
    });

    channel.on('presence_diff', (payload: any) => {
      console.log('Presence diff received:', payload);
      updatePresenceFromPhoenix(payload);
    });

    channel.join()
      .receive('ok', () => {
        console.log('Joined presence channel');
        setIsConnected(true);
      })
      .receive('error', (err: any) => {
        console.error('Failed to join presence channel:', err);
        setIsConnected(false);
      });

    channelRef.current = channel;

    return () => {
      channel.leave();
      channelRef.current = null;
    };
  }, []);

  // Helper function to update presence from Phoenix events
  const updatePresenceFromPhoenix = useCallback((payload: any) => {
    if (debounceTimeoutRef.current) {
      clearTimeout(debounceTimeoutRef.current);
    }

    debounceTimeoutRef.current = setTimeout(() => {
      setOnlineUsers(currentUsers => {
        const userMap = new Map(currentUsers);
        
        // Handle presence_diff format (has joins/leaves)
        if (payload.joins || payload.leaves) {
          // Add joined users
          if (payload.joins) {
            Object.entries(payload.joins).forEach(([userId, presenceData]: [string, any]) => {
              if (presenceData.metas && presenceData.metas.length > 0) {
                const meta = presenceData.metas[0];
                userMap.set(meta.user_id, {  // Use nanoid as key
                  userId: meta.user_id,      // Store nanoid as userId
                  username: meta.username,
                  fullName: meta.full_name,
                  status: meta.status as 'online' | 'away' | 'offline',
                  lastSeen: meta.last_seen,
                  deviceType: meta.device_type
                });
              }
            });
          }
          
          // Remove left users
          if (payload.leaves) {
            Object.entries(payload.leaves).forEach(([userId, presenceData]: [string, any]) => {
              if (presenceData.metas && presenceData.metas.length > 0) {
                const meta = presenceData.metas[0];
                userMap.delete(meta.user_id);  // Use nanoid to delete
              }
            });
          }
        } else {
          // Handle presence_state format (flat object)
          userMap.clear();
          Object.entries(payload).forEach(([userId, presenceData]: [string, any]) => {
            if (presenceData.metas && presenceData.metas.length > 0) {
              const meta = presenceData.metas[0];
              userMap.set(meta.user_id, {  // Use nanoid as key
                userId: meta.user_id,      // Store nanoid as userId
                username: meta.username,
                fullName: meta.full_name,
                status: meta.status as 'online' | 'away' | 'offline',
                lastSeen: meta.last_seen,
                deviceType: meta.device_type
              });
            }
          });
        }
        
        return userMap;
      });
    }, 100);
  }, []);


  // Helper functions
  const isUserOnline = useCallback((userId: string): boolean => {
    const user = onlineUsers.get(userId);
    return user?.status === 'online';
  }, [onlineUsers]);

  const getUserStatus = useCallback((userId: string): UserPresence | null => {
    return onlineUsers.get(userId) || null;
  }, [onlineUsers]);

  const getOnlineUsers = useCallback((): UserPresence[] => {
    return Array.from(onlineUsers.values()).filter(user => user.status === 'online');
  }, [onlineUsers]);

  const contextValue: PresenceState = {
    onlineUsers,
    isUserOnline,
    getUserStatus,
    getOnlineUsers,
    isConnected,
  };

  return (
    <PresenceContext.Provider value={contextValue}>
      {children}
    </PresenceContext.Provider>
  );
};

export const usePresence = (): PresenceState => {
  const context = useContext(PresenceContext);
  if (!context) {
    throw new Error('usePresence must be used within a PresenceProvider');
  }
  return context;
};
