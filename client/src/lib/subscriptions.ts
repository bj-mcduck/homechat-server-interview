import { gql } from 'urql';

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
