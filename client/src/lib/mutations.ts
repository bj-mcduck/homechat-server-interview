import { gql } from 'urql';

export const REGISTER_MUTATION = gql`
  mutation Register($email: String!, $password: String!, $username: String!, $firstName: String!, $lastName: String!) {
    register(email: $email, password: $password, username: $username, firstName: $firstName, lastName: $lastName) {
      token
      user {
        id
        username
        email
        firstName
        lastName
      }
    }
  }
`;

export const SIGN_IN_MUTATION = gql`
  mutation SignIn($email: String!, $password: String!) {
    signIn(email: $email, password: $password) {
      token
      user {
        id
        username
        email
        firstName
        lastName
      }
    }
  }
`;

export const CREATE_DIRECT_CHAT_MUTATION = gql`
  mutation CreateDirectChat($userId: String!) {
    createDirectChat(userId: $userId) {
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

export const CREATE_GROUP_CHAT_MUTATION = gql`
  mutation CreateGroupChat($name: String!) {
    createGroupChat(name: $name) {
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

export const ADD_CHAT_MEMBER_MUTATION = gql`
  mutation AddChatMember($chatId: String!, $userId: String!) {
    addChatMember(chatId: $chatId, userId: $userId) {
      id
      members {
        id
        username
        firstName
        lastName
      }
    }
  }
`;

export const SEND_MESSAGE_MUTATION = gql`
  mutation SendMessage($chatId: String!, $content: String!) {
    sendMessage(chatId: $chatId, content: $content) {
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

export const CREATE_OR_FIND_GROUP_CHAT_MUTATION = gql`
  mutation CreateOrFindGroupChat($participantIds: [String!]!) {
    createOrFindGroupChat(participantIds: $participantIds) {
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
