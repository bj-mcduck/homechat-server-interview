import { gql } from 'urql';

// Legacy subscriptions (deprecated - use user-scoped versions below)
export const MESSAGE_SENT_SUBSCRIPTION = gql`
  subscription MessageSent($chatId: String!) {
    messageSent(chatId: $chatId) {
      id
      content
      insertedAt
      user {
        id
        username
        firstName
        lastName
      }
    }
  }
`;

export const CHAT_UPDATED_SUBSCRIPTION = gql`
  subscription ChatUpdated($chatId: String!) {
    chatUpdated(chatId: $chatId) {
      id
      name
      private
      members {
        id
        username
        firstName
        lastName
      }
    }
  }
`;

export const USER_CHATS_UPDATED_SUBSCRIPTION = gql`
  subscription UserChatsUpdated($userId: String!) {
    userChatsUpdated(userId: $userId) {
      id
      name
      private
      members {
        id
        username
        firstName
        lastName
      }
    }
  }
`;

// New user-scoped subscriptions for better scalability
export const USER_MESSAGES_SUBSCRIPTION = gql`
  subscription UserMessages($userId: String!) {
    userMessages(userId: $userId) {
      chatId
      message {
        id
        content
        insertedAt
        user {
          id
          username
          firstName
          lastName
        }
      }
    }
  }
`;

export const USER_CHAT_UPDATES_SUBSCRIPTION = gql`
  subscription UserChatUpdates($userId: String!) {
    userChatUpdates(userId: $userId) {
      id
      name
      displayName
      private
      members {
        id
        username
        firstName
        lastName
      }
    }
  }
`;

export const PRESENCE_UPDATES_SUBSCRIPTION = gql`
  subscription PresenceUpdates {
    presenceUpdates {
      onlineUsers {
        userId
        username
        fullName
        status
        lastSeen
        deviceType
      }
      timestamp
    }
  }
`;
