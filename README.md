# Chat Messaging API

A real-time chat messaging system built with Phoenix, Elixir, and GraphQL. Features JWT authentication, direct messaging, group chats, and real-time updates via WebSockets.

## Features

- **JWT Authentication** - Secure user authentication with argon2 password hashing
- **Direct Messaging** - 1-on-1 private conversations between users
- **Group Chats** - Multi-user chat rooms with member management
- **Real-time Updates** - Live messaging via Phoenix Channels and GraphQL subscriptions
- **User Search** - Find users by username, first name, or last name
- **Public/Private Chats** - Discoverable public chat rooms and private groups
- **GraphQL API** - Complete GraphQL API with queries, mutations, and subscriptions

## Tech Stack

- **Backend**: Phoenix 1.7, Elixir 1.18
- **Database**: PostgreSQL with Ecto
- **Authentication**: JWT with Guardian
- **Password Hashing**: Argon2 (OWASP recommended)
- **API**: GraphQL with Absinthe
- **Real-time**: Phoenix Channels + Absinthe Subscriptions
- **Testing**: ExUnit with ExMachina factories

## Getting Started

### Prerequisites

- Elixir 1.18+ and Erlang/OTP 27+
- PostgreSQL 12+
- Node.js (for development tools)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd server-interview
   ```

2. **Install dependencies**
   ```bash
   mix deps.get
   ```

3. **Setup database**
   ```bash
   mix ecto.create
   mix ecto.migrate
   mix run priv/repo/seeds.exs
   ```

4. **Start the server**
   ```bash
   mix phx.server
   ```

5. **Access the application**
   - GraphQL Playground: http://localhost:4000/graphiql
   - Phoenix Dashboard: http://localhost:4000/dev/dashboard

## API Documentation

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
  searchUsers(query: "john") {
    id
    username
    firstName
    lastName
  }
}
```

#### Chat Management

**List user's chats:**
```graphql
query {
  chats {
    id
    name
    private
    isDirect
    members {
      id
      username
      firstName
      lastName
    }
    lastMessage {
      id
      content
      insertedAt
    }
  }
}
```

**List discoverable chats (user's chats + public chats):**
```graphql
query {
  discoverableChats {
    id
    name
    private
    members {
      id
      username
    }
  }
}
```

**Get specific chat:**
```graphql
query {
  chat(id: "1") {
    id
    name
    private
    members {
      id
      username
    }
  }
}
```

**Create direct chat:**
```graphql
mutation {
  createDirectChat(userId: "2") {
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
    participantIds: ["2", "3", "4"]
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
  updateChatPrivacy(chatId: "1", private: false) {
    id
    private
  }
}
```

#### Messaging

**List messages in a chat:**
```graphql
query {
  messages(chatId: "1", page: 1, limit: 50) {
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

**Send a message:**
```graphql
mutation {
  sendMessage(chatId: "1", content: "Hello everyone!") {
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
  messageSent(chatId: "1") {
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

**Subscribe to chat updates:**
```graphql
subscription {
  chatUpdated(chatId: "1") {
    id
    name
    private
    members {
      id
      username
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

const channel = socket.channel("chat:1", {});
channel.join()
  .receive("ok", resp => console.log("Joined chat", resp))
  .receive("error", resp => console.log("Unable to join", resp));

// Listen for new messages
channel.on("new_message", payload => {
  console.log("New message:", payload);
});

// Send a message
channel.push("new_message", { content: "Hello!" });
```

## Database Schema

### Users
- `id` - Primary key
- `email` - Unique email address
- `username` - Unique username (3-20 chars, alphanumeric + underscore)
- `first_name` - User's first name
- `last_name` - User's last name
- `password_hash` - Argon2 hashed password
- `state` - User state (active/inactive)

### Chats
- `id` - Primary key
- `name` - Chat name (nullable for direct chats)
- `private` - Whether chat is discoverable (default: true)
- `state` - Chat state (active/inactive)

### Chat Members
- `id` - Primary key
- `chat_id` - Foreign key to chats
- `user_id` - Foreign key to users
- `role` - Member role (owner/admin/member)

### Messages
- `id` - Primary key
- `chat_id` - Foreign key to chats
- `user_id` - Foreign key to users
- `content` - Message content (1-2000 chars)

## Testing

Run the test suite:

```bash
# Run all tests
mix test

# Run tests with coverage
mix test --cover

# Run specific test file
mix test test/server/accounts_test.exs
```

## Development

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

## Architecture

### Contexts
- **Accounts** - User management and authentication
- **Chats** - Chat room management and member operations
- **Messages** - Message creation and retrieval

### Models
- **UserModel** - User data and password hashing
- **ChatModel** - Chat room data and relationships
- **ChatMemberModel** - Chat membership and roles
- **MessageModel** - Message data and associations

### GraphQL Schema
- **UserSchema** - User queries and mutations
- **ChatSchema** - Chat queries, mutations, and subscriptions
- **MessageSchema** - Message queries, mutations, and subscriptions

### Real-time
- **Phoenix Channels** - WebSocket communication for live messaging
- **Absinthe Subscriptions** - GraphQL subscriptions for real-time updates

## Security Features

- **JWT Authentication** - Stateless authentication with configurable expiration
- **Argon2 Password Hashing** - Industry-standard password hashing
- **Authorization Middleware** - Role-based access control
- **Input Validation** - Comprehensive validation on all inputs
- **SQL Injection Protection** - Ecto query builder prevents SQL injection
- **XSS Protection** - Phoenix's built-in XSS protection

## Performance Considerations

- **Database Indexes** - Optimized queries with proper indexing
- **Ecto Associations** - Efficient data loading with preloading
- **Connection Pooling** - Database connection pooling for scalability
- **Real-time Optimization** - Efficient WebSocket message broadcasting

## Learn More

- [Phoenix Framework](https://www.phoenixframework.org/)
- [Elixir Language](https://elixir-lang.org/)
- [GraphQL with Absinthe](https://hexdocs.pm/absinthe/)
- [Ecto Database Library](https://hexdocs.pm/ecto/)
- [Guardian Authentication](https://hexdocs.pm/guardian/)
