# Chat Messaging System

A full-stack real-time chat messaging system with a Phoenix/Elixir backend and React frontend. Features JWT authentication, direct messaging, group chats, real-time updates, and typing indicators.

## Features

- **JWT Authentication** - Secure user authentication with argon2 password hashing
- **Direct Messaging** - 1-on-1 private conversations between users
- **Group Chats** - Multi-user chat rooms with member management
- **Real-time Updates** - Live messaging via GraphQL subscriptions (WebSocket-based)
- **Typing Indicators** - Real-time typing status using Phoenix Channels
- **User Search** - Find users by username, first name, or last name
- **Public/Private Chats** - Discoverable public chat rooms and private groups
- **GraphQL API** - Complete GraphQL API with queries, mutations, and subscriptions
- **Type Safety** - Full type safety between frontend and backend via GraphQL schema
- **Modern UI** - React frontend with Mantine components and responsive design

## Architecture

This project follows enterprise-grade architectural patterns. See [ARCHITECTURE.md](ARCHITECTURE.md) for detailed design decisions and rationale.

**Key Architectural Decisions:**
- **GraphQL Subscriptions** for real-time messaging (API consistency, type safety)
- **Phoenix Channels** for typing indicators and presence tracking
- **JWT Authentication** for stateless, scalable authentication
- **NanoID** for public API identifiers (shorter, type-identifiable, secure)
- **Argon2** password hashing (OWASP recommended)
- **ChatMember join table** for flexible relationship management

## Tech Stack

### Backend
- **Phoenix 1.7** with Elixir 1.18
- **PostgreSQL** with Ecto
- **JWT Authentication** with Guardian
- **Argon2** password hashing (OWASP recommended)
- **GraphQL API** with Absinthe
- **Real-time**: GraphQL Subscriptions + Phoenix Channels
- **Testing**: ExUnit with ExMachina factories

### Frontend
- **React 18** with TypeScript
- **urql** GraphQL client with normalized caching
- **Mantine** UI component library
- **Phoenix Socket** for real-time typing indicators
- **React Router** for navigation
- **Vite** for build tooling

## Getting Started

### Prerequisites

- Elixir 1.18+ and Erlang/OTP 27+
- PostgreSQL 12+
- Node.js 18+ (for frontend)

### Quick Start

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd server-interview
   ```

2. **Setup Backend**
   ```bash
   # Install dependencies
   mix deps.get
   
   # Setup database
   mix ecto.create
   mix ecto.migrate
   mix run priv/repo/seeds.exs
   
   # Start Phoenix server
   mix phx.server
   ```

3. **Setup Frontend**
   ```bash
   # Navigate to client directory
   cd client
   
   # Install dependencies
   npm install
   
   # Start development server
   npm run dev
   ```

4. **Access the application**
   - **Frontend**: http://localhost:5173
   - **GraphQL Playground**: http://localhost:4000/graphiql
   - **Phoenix Dashboard**: http://localhost:4000/dev/dashboard

## Frontend Application

The React frontend provides a complete chat interface with modern UI components and real-time functionality.

### Features

- **User Authentication** - Register, login, and logout with JWT tokens
- **Chat Interface** - Clean, responsive chat layout with sidebar navigation
- **Real-time Messaging** - Instant message delivery via GraphQL subscriptions
- **Typing Indicators** - See when other users are typing in real-time
- **User Search** - Find and add users to chats
- **Chat Management** - Create direct messages and group chats
- **Member Management** - Add/remove users from group chats
- **Responsive Design** - Works on desktop and mobile devices

### UI Components

- **Sidebar** - Chat list with direct messages and group chats
- **Chat Header** - Chat name, member count, and management options
- **Message List** - Scrollable message history with user avatars
- **Message Form** - Text input with send button and typing detection
- **Member Panel** - Current chat members and add user functionality
- **Typing Indicator** - Shows who is currently typing

### Development

The frontend is built with modern React patterns:

- **TypeScript** for type safety
- **urql** for GraphQL client with normalized caching
- **Mantine** for consistent, accessible UI components
- **Phoenix Socket** for real-time typing indicators
- **React Router** for client-side navigation
- **Vite** for fast development and building

<details>
<summary><strong>API Documentation</strong></summary>

### Authentication

All protected endpoints require a JWT token in the Authorization header:
```
Authorization: Bearer <your-jwt-token>
```

### GraphQL Queries

#### User Management

**Register a new user:**
```graphql
mutation {
  register(
    email: "user@example.com"
    username: "username"
    password: "password123"
    firstName: "John"
    lastName: "Doe"
  ) {
    token
    user {
      id
      email
      username
      firstName
      lastName
    }
  }
}
```

**Login:**
```graphql
mutation {
  login(email: "user@example.com", password: "password123") {
    token
    user {
      id
      email
      username
    }
  }
}
```

**Get current user:**
```graphql
query {
  me {
    id
    email
    username
    firstName
    lastName
  }
}
```

**Search users:**
```graphql
query {
  users(excludeSelf: true) {
    id
    username
    firstName
    lastName
  }
}
```

#### Chat Management

**List discoverable chats (user's chats + public chats):**
```graphql
query {
  discoverableChats {
    id
    name
    displayName
    private
    isDirect
    members {
      id
      username
      firstName
      lastName
    }
  }
}
```

**Get specific chat:**
```graphql
query {
  chat(id: "cht_abc123") {
    id
    name
    displayName
    private
    isDirect
    members {
      id
      username
      firstName
      lastName
    }
  }
}
```

**Create direct chat:**
```graphql
mutation {
  createDirectChat(userId: "usr_xyz789") {
    id
    isDirect
    members {
      id
      username
    }
  }
}
```

**Create group chat:**
```graphql
mutation {
  createGroupChat(
    name: "My Group"
    participantIds: ["usr_xyz789", "usr_def456"]
  ) {
    id
    name
    members {
      id
      username
    }
  }
}
```

**Update chat privacy:**
```graphql
mutation {
  updateChatPrivacy(chatId: "cht_abc123", private: false) {
    id
    private
  }
}
```

#### Messaging

**List messages in a chat:**
```graphql
query {
  messages(chatId: "cht_abc123", offset: 0) {
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
```

**Send a message:**
```graphql
mutation {
  sendMessage(chatId: "cht_abc123", content: "Hello everyone!") {
    id
    content
    insertedAt
    user {
      id
      username
    }
  }
}
```

### Real-time Subscriptions

**Subscribe to new messages:**
```graphql
subscription {
  userMessages(userId: "usr_abc123") {
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
```

**Subscribe to chat updates:**
```graphql
subscription {
  userChatUpdates(userId: "usr_abc123") {
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
```

### WebSocket Connection

For real-time features, connect to the WebSocket:

```javascript
const socket = new Phoenix.Socket("/socket", {
  params: { token: "your-jwt-token" }
});

socket.connect();

const channel = socket.channel("typing:cht_abc123", {});
channel.join()
  .receive("ok", resp => console.log("Joined typing channel", resp))
  .receive("error", resp => console.log("Unable to join", resp));

// Listen for typing events
channel.on("user_typing", payload => {
  console.log("User typing:", payload);
});

// Send typing events
channel.push("typing_start", {});
channel.push("typing_stop", {});
```

</details>

<details>
<summary><strong>Database Schema</strong></summary>

### Users
- `id` - Primary key (integer)
- `nanoid` - Public identifier (usr_xxx)
- `email` - Unique email address
- `username` - Unique username (3-20 chars, alphanumeric + underscore)
- `first_name` - User's first name
- `last_name` - User's last name
- `password_hash` - Argon2 hashed password
- `state` - User state (active/inactive)

### Chats
- `id` - Primary key (integer)
- `nanoid` - Public identifier (cht_xxx)
- `name` - Chat name (nullable for direct chats)
- `private` - Whether chat is discoverable (default: true)
- `state` - Chat state (active/inactive)
- `member_names` - Cached array of member names for performance
- `is_direct` - Whether this is a direct message chat

### Chat Members
- `id` - Primary key (integer)
- `nanoid` - Public identifier (mbr_xxx)
- `chat_id` - Foreign key to chats
- `user_id` - Foreign key to users
- `role` - Member role (owner/admin/member)

### Messages
- `id` - Primary key (integer)
- `nanoid` - Public identifier (msg_xxx)
- `chat_id` - Foreign key to chats
- `user_id` - Foreign key to users
- `content` - Message content (1-2000 chars)

</details>

<details>
<summary><strong>Testing</strong></summary>

Run the test suite:

```bash
# Run all tests
mix test

# Run tests with coverage
mix test --cover

# Run specific test file
mix test test/server/accounts_test.exs

# Run frontend tests
cd client
npm test
```

### Test Coverage

The project includes comprehensive test coverage:

- **Unit Tests** - Individual function and module testing
- **Integration Tests** - End-to-end workflow testing
- **GraphQL Tests** - API operation testing
- **Authorization Tests** - Policy and permission testing
- **Real-time Tests** - WebSocket and subscription testing

### Test Data Generation

Uses ExMachina factories for consistent test data:

```elixir
# Create test users
user = insert(:user, email: "test@example.com")

# Create test chats with members
chat = insert(:chat, name: "Test Chat")
insert(:chat_member, chat: chat, user: user, role: :owner)
```

</details>

<details>
<summary><strong>Development</strong></summary>

### Code Quality

The project uses several tools for code quality:

- **Credo** - Static code analysis
- **Dialyxir** - Type checking with Dialyzer
- **Sobelow** - Security-focused static analysis

```bash
# Run code quality checks
mix credo
mix dialyzer
mix sobelow

# Frontend linting
cd client
npm run lint
```

### Database Management

```bash
# Create database
mix ecto.create

# Run migrations
mix ecto.migrate

# Rollback migration
mix ecto.rollback

# Reset database
mix ecto.reset

# Seed database
mix run priv/repo/seeds.exs
```

### Development Scripts

```bash
# Start both backend and frontend
npm run dev:all

# Backend only
mix phx.server

# Frontend only
cd client && npm run dev

# Run tests
mix test
cd client && npm test
```

</details>

<details>
<summary><strong>Architecture</strong></summary>

### Backend Architecture

#### Contexts
- **Accounts** - User management and authentication
- **Chats** - Chat room management and member operations
- **Messages** - Message creation and retrieval

#### Models
- **UserModel** - User data and password hashing
- **ChatModel** - Chat room data and relationships
- **ChatMemberModel** - Chat membership and roles
- **MessageModel** - Message data and associations

#### GraphQL Schema
- **UserSchema** - User queries and mutations
- **ChatSchema** - Chat queries, mutations, and subscriptions
- **MessageSchema** - Message queries, mutations, and subscriptions

#### Real-time
- **Phoenix Channels** - WebSocket communication for typing indicators
- **Absinthe Subscriptions** - GraphQL subscriptions for real-time updates

### Frontend Architecture

#### Components
- **Layout** - Main application layout with sidebar
- **Chat** - Chat interface components
- **Auth** - Authentication components
- **Shared** - Reusable UI components

#### Hooks
- **useAuth** - Authentication state management
- **useTypingIndicator** - Real-time typing status
- **useChat** - Chat state management

#### Services
- **GraphQL Client** - urql with normalized caching
- **Phoenix Socket** - WebSocket connection for typing
- **Auth Service** - JWT token management

</details>

<details>
<summary><strong>Security Features</strong></summary>

- **JWT Authentication** - Stateless authentication with configurable expiration
- **Argon2 Password Hashing** - Industry-standard password hashing
- **Authorization Policies** - Bodyguard-based authorization with Rails-like policies
- **Input Validation** - Comprehensive validation on all inputs
- **SQL Injection Protection** - Ecto query builder prevents SQL injection
- **XSS Protection** - Phoenix's built-in XSS protection
- **CORS Configuration** - Proper cross-origin resource sharing setup
- **NanoID Security** - Obfuscated public identifiers prevent enumeration

</details>

<details>
<summary><strong>Performance Considerations</strong></summary>

- **Database Indexes** - Optimized queries with proper indexing
- **Dataloader** - N+1 query prevention in GraphQL resolvers
- **Connection Pooling** - Database connection pooling for scalability
- **Real-time Optimization** - Efficient WebSocket message broadcasting
- **Cached Denormalization** - Member names cached for chat lists
- **Normalized Caching** - urql normalized cache for frontend state
- **Lazy Loading** - Deferred data loading in GraphQL resolvers

</details>

<details>
<summary><strong>Learn More</strong></summary>

### Backend Resources
- [Phoenix Framework](https://www.phoenixframework.org/)
- [Elixir Language](https://elixir-lang.org/)
- [GraphQL with Absinthe](https://hexdocs.pm/absinthe/)
- [Ecto Database Library](https://hexdocs.pm/ecto/)
- [Guardian Authentication](https://hexdocs.pm/guardian/)
- [Bodyguard Authorization](https://hexdocs.pm/bodyguard/)

### Frontend Resources
- [React](https://reactjs.org/)
- [TypeScript](https://www.typescriptlang.org/)
- [urql GraphQL Client](https://formidable.com/open-source/urql/)
- [Mantine UI Components](https://mantine.dev/)
- [Phoenix Socket Client](https://hexdocs.pm/phoenix/js/)

### Architecture Documentation
- [ARCHITECTURE.md](ARCHITECTURE.md) - Detailed architectural decisions
- [.cursorrules/](.cursorrules/) - Development guidelines and best practices

</details>
