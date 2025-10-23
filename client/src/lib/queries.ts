import { gql } from 'urql';

export const ME_QUERY = gql`
  query Me {
    me {
      id
      username
      email
      firstName
      lastName
    }
  }
`;

export const USER_CHATS_QUERY = gql`
  query UserChats {
    userChats {
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

export const PUBLIC_CHATS_QUERY = gql`
  query PublicChats {
    publicChats {
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

export const MESSAGES_QUERY = gql`
  query Messages($chatId: String!) {
    messages(chatId: $chatId) {
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

export const USERS_QUERY = gql`
  query Users($excludeSelf: Boolean) {
    users(excludeSelf: $excludeSelf) {
      id
      username
      email
      firstName
      lastName
    }
  }
`;
