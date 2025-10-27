import { useEffect, useRef, useState, useCallback } from 'react';
import { useQuery, useSubscription, useClient } from 'urql';
import { gql } from 'urql';
import { MESSAGES_QUERY } from '../../lib/queries';
import { USER_MESSAGES_SUBSCRIPTION } from '../../lib/subscriptions';
import { MessageItem } from './MessageItem';
import { LoadingIndicator } from './LoadingIndicator';
import { useAuth } from '../../hooks/useAuth';

interface Message {
  id: string;
  content: string;
  insertedAt: string;
  user: {
    id: string;
    username: string;
    firstName: string;
    lastName: string;
  };
}

interface MessageListProps {
  chatId: string;
}

export const MessageList = ({ chatId }: MessageListProps) => {
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const scrollContainerRef = useRef<HTMLDivElement>(null);
  const sentinelRef = useRef<HTMLDivElement>(null);
  const [allMessages, setAllMessages] = useState<Message[]>([]);
  const [isLoadingMore, setIsLoadingMore] = useState(false);
  const [hasMore, setHasMore] = useState(true);
  const [oldestCursor, setOldestCursor] = useState<string | null>(null);
  const [shouldAutoScroll, setShouldAutoScroll] = useState(true);
  const { user: currentUser } = useAuth();
  const client = useClient();
  
  // Initial load
  const [{ data, fetching, error }] = useQuery({
    query: MESSAGES_QUERY,
    variables: { 
      chatId,
      limit: 20
    },
    requestPolicy: 'cache-and-network',
  });

  // Subscribe to new messages
  const [{ data: subscriptionData }] = useSubscription({
    query: USER_MESSAGES_SUBSCRIPTION,
    variables: { userId: currentUser?.id },
    pause: !currentUser?.id || !chatId,
  });

  // Handle initial load
  useEffect(() => {
    if (data?.messages) {
      const messages = data.messages;
      setAllMessages(messages);
      
      // Set cursor to oldest message
      if (messages.length > 0) {
        const oldest = messages[0];
        setOldestCursor(oldest.insertedAt);
      }
      
      // Has more if we got exactly 20 messages
      setHasMore(messages.length === 20);
      
      // Auto-scroll to bottom on initial load
      setTimeout(() => {
        messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
      }, 100);
    }
  }, [data?.messages]);

  // Handle new messages from subscription
  useEffect(() => {
    if (subscriptionData?.userMessages) {
      const event = subscriptionData.userMessages;
      if (event.chatId === chatId) {
        const newMessage = event.message;
        setAllMessages(prev => {
          // Check if message already exists to avoid duplicates
          const exists = prev.some(msg => msg.id === newMessage.id);
          if (exists) return prev;
          return [...prev, newMessage];
        });
        
        // Only auto-scroll if user is near bottom
        setShouldAutoScroll(true);
      }
    }
  }, [subscriptionData, chatId]);

  // Auto-scroll for new messages only
  useEffect(() => {
    if (shouldAutoScroll && scrollContainerRef.current) {
      const container = scrollContainerRef.current;
      const distanceFromBottom = container.scrollHeight - container.scrollTop - container.clientHeight;
      
      // Only scroll if within 100px of bottom
      if (distanceFromBottom < 100) {
        messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
      }
      setShouldAutoScroll(false);
    }
  }, [allMessages.length, shouldAutoScroll]);

  // Load more messages when scrolling up
  const loadMoreMessages = useCallback(async () => {
    // Guard: don't load if already loading, no cursor, or no more content
    if (!oldestCursor || isLoadingMore || !hasMore) {
      return;
    }
    
    setIsLoadingMore(true);
    
    try {
      const result = await client.query(
        MESSAGES_QUERY,
        {
          chatId,
          before: oldestCursor,
          limit: 20
        }
      ).toPromise();
      
      if (result.data?.messages) {
        const olderMessages = result.data.messages;
        
        // Prepend older messages to list
        setAllMessages(prev => [...olderMessages, ...prev]);
        
        // Update cursor
        if (olderMessages.length > 0) {
          setOldestCursor(olderMessages[0].insertedAt);
        }
        
        // Has more if we got exactly 20 messages
        setHasMore(olderMessages.length === 20);
      }
    } catch (err) {
      console.error('Error loading more messages:', err);
    } finally {
      setIsLoadingMore(false);
    }
  }, [oldestCursor, isLoadingMore, hasMore, chatId, client]);

  // Track if we're currently loading to prevent re-trigger
  const isCurrentlyLoadingRef = useRef(false);

  // Set up observer - DON'T recreate on isLoadingMore changes
  useEffect(() => {
    if (!hasMore || !sentinelRef.current) {
      return; // Don't set up observer if there's no more content or no sentinel
    }

    const observer = new IntersectionObserver(
      (entries) => {
        // Check if intersecting and we should load more
        if (
          entries[0].isIntersecting && 
          hasMore && 
          !isLoadingMore && 
          !isCurrentlyLoadingRef.current
        ) {
          isCurrentlyLoadingRef.current = true;
          loadMoreMessages().finally(() => {
            // Reset loading ref after load completes (success or error)
            isCurrentlyLoadingRef.current = false;
          });
        }
      },
      { threshold: 0.01, rootMargin: '100px' } // Lower threshold, smaller margin
    );

    const sentinel = sentinelRef.current;
    observer.observe(sentinel);

    return () => {
      observer.unobserve(sentinel);
    };
  }, [hasMore, loadMoreMessages]); // Removed isLoadingMore from dependencies

  // Sort messages chronologically (oldest to newest)
  const sortedMessages = [...allMessages].sort((a, b) => 
    new Date(a.insertedAt).getTime() - new Date(b.insertedAt).getTime()
  );

  if (fetching && allMessages.length === 0) {
    return (
      <div style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        <div style={{ color: '#666' }}>Loading messages...</div>
      </div>
    );
  }

  if (error) {
    return (
      <div style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        <div style={{ color: '#dc3545' }}>Error loading messages</div>
      </div>
    );
  }

  return (
    <div 
      ref={scrollContainerRef}
      style={{ flex: 1, overflowY: 'auto', padding: '1rem' }}
    >
      {/* Loading indicator - stays in place */}
      <div style={{ minHeight: isLoadingMore ? '60px' : '0px', transition: 'min-height 0.2s' }}>
        {isLoadingMore && <LoadingIndicator />}
      </div>
      
      {/* Sentinel below loading indicator - only rendered when hasMore */}
      {hasMore && <div ref={sentinelRef} style={{ height: '1px', opacity: 0 }} />}
      
      {/* Start of conversation message */}
      {!hasMore && sortedMessages.length > 0 && (
        <div style={{
          textAlign: 'center',
          padding: '0.5rem',
          fontSize: '0.875rem',
          color: '#666'
        }}>
          Start of conversation
        </div>
      )}
      
      {/* Messages */}
      {sortedMessages.length === 0 ? (
        <div style={{ 
          display: 'flex', 
          alignItems: 'center', 
          justifyContent: 'center', 
          height: '100%', 
          color: '#666' 
        }}>
          No messages yet. Start the conversation!
        </div>
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
          {sortedMessages.map((message) => (
            <MessageItem key={message.id} message={message} />
          ))}
        </div>
      )}
      
      <div ref={messagesEndRef} />
    </div>
  );
};
