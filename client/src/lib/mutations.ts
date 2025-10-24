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

export const LEAVE_CHAT_MUTATION = gql`
  mutation LeaveChat($chatId: String!) {
    leaveChat(chatId: $chatId) {
      id
      name
      displayName
    }
  }
`;

export const ARCHIVE_CHAT_MUTATION = gql`
  mutation ArchiveChat($chatId: String!) {
    archiveChat(chatId: $chatId) {
      id
      state
    }
  }
`;

export const CONVERT_TO_GROUP_MUTATION = gql`
  mutation ConvertToGroup($chatId: String!, $name: String!) {
    convertToGroup(chatId: $chatId, name: $name) {
      id
      name
      displayName
      isDirect
    }
  }
`;

export const UPDATE_CHAT_PRIVACY_MUTATION = gql`
  mutation UpdateChatPrivacy($chatId: String!, $private: Boolean!) {
    updateChatPrivacy(chatId: $chatId, private: $private) {
      id
      private
    }
  }
`;
