import { useEffect, useRef, useState, useMemo, useCallback } from 'react';
import { Socket, Channel } from 'phoenix';

interface TypingUser {
  userId: string;
  userName: string;
  timestamp: number;
}

const TYPING_TIMEOUT = 3000; // 3 seconds

export const useTypingIndicator = (chatId: string | undefined, socket: Socket | null) => {
  const [typingUsers, setTypingUsers] = useState<Map<string, TypingUser>>(new Map());
  const channelRef = useRef<Channel | null>(null);
  const typingTimeoutRef = useRef<NodeJS.Timeout | null>(null);
  const cleanupIntervalRef = useRef<NodeJS.Timeout | null>(null);

  // Stabilize socket reference to prevent useEffect from running on every render
  const stableSocket = useMemo(() => socket, [socket?.state]);

  // Join typing channel when chat changes
  // NOTE: Previously, both MessageForm and useTypingIndicator were creating separate channels
  // to the same 'typing:chatId' topic. This caused multiple channel joins per user (4+ joins visible
  // in server logs), channel conflicts, and event listeners not receiving events properly.
  // The fix was to consolidate channel usage - only useTypingIndicator creates the channel,
  // and MessageForm receives the startTyping/stopTyping functions as props.
  useEffect(() => {
    if (!chatId || !stableSocket) return;

    const channel = stableSocket.channel(`typing:${chatId}`, {});
    
    channel.on('user_typing', (payload: { user_id: string; user_name: string }) => {
      setTypingUsers(prev => {
        const next = new Map(prev);
        next.set(payload.user_id, {
          userId: payload.user_id,
          userName: payload.user_name,
          timestamp: Date.now()
        });
        return next;
      });
    });

    channel.on('user_stopped_typing', (payload: { user_id: string }) => {
      setTypingUsers(prev => {
        const next = new Map(prev);
        next.delete(payload.user_id);
        return next;
      });
    });

    channel.join();

    channelRef.current = channel;

    // Cleanup old typing indicators every second
    cleanupIntervalRef.current = setInterval(() => {
      const now = Date.now();
      setTypingUsers(prev => {
        const next = new Map(prev);
        let changed = false;
        
        for (const [userId, user] of next.entries()) {
          if (now - user.timestamp > TYPING_TIMEOUT) {
            next.delete(userId);
            changed = true;
          }
        }
        
        return changed ? next : prev;
      });
    }, 1000);

    return () => {
      channel.leave();
      if (cleanupIntervalRef.current) {
        clearInterval(cleanupIntervalRef.current);
      }
    };
  }, [chatId, stableSocket]);

  // Send typing stop event
  const stopTyping = useCallback(() => {
    if (channelRef.current) {
      channelRef.current.push('typing_stop', {});
    }
    
    if (typingTimeoutRef.current) {
      clearTimeout(typingTimeoutRef.current);
      typingTimeoutRef.current = null;
    }
  }, []);

  // Send typing start event
  const startTyping = useCallback(() => {
    if (channelRef.current) {
      channelRef.current.push('typing_start', {});
      
      // Clear existing timeout
      if (typingTimeoutRef.current) {
        clearTimeout(typingTimeoutRef.current);
      }
      
      // Auto-stop after timeout
      typingTimeoutRef.current = setTimeout(() => {
        stopTyping();
      }, TYPING_TIMEOUT);
    }
  }, [stopTyping]);

  // Format typing indicator text
  const getTypingText = (): string | null => {
    const users = Array.from(typingUsers.values());
    
    if (users.length === 0) return null;
    if (users.length === 1) return `${users[0].userName} is typing...`;
    if (users.length === 2) return `${users[0].userName} and ${users[1].userName} are typing...`;
    return 'Multiple people are typing...';
  };

  return {
    typingUsers: Array.from(typingUsers.values()),
    typingText: getTypingText(),
    startTyping,
    stopTyping
  };
};
