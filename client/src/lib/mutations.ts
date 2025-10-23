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
  mutation CreateGroupChat($name: String!, $participantIds: [String!]!) {
    createGroupChat(name: $name, participantIds: $participantIds) {
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
