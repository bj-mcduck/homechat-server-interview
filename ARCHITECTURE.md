# Architecture Decisions

This document records the key architectural decisions made for the Chat Messaging API project, including the rationale behind each choice and the consequences of these decisions.

## Authentication Strategy

### Context
We need to implement user authentication for a chat messaging system that will be consumed by a React frontend. The system needs to be stateless and scalable for enterprise use.

### Decision
We chose **JWT (JSON Web Tokens) with Guardian** over session-based authentication, and **Argon2** for password hashing.

### Rationale
- **JWT Benefits**:
  - Stateless authentication (no server-side session storage)
  - Scalable across multiple servers/instances
  - Self-contained tokens with expiration
  - Industry standard for API authentication
  - Works well with React frontend and mobile apps

- **Argon2 Benefits**:
  - OWASP recommended password hashing algorithm
  - Winner of Password Hashing Competition (2015)
  - Resistant to GPU/ASIC attacks
  - Configurable memory and time parameters
  - More secure than bcrypt for new applications

### Consequences
- **Positive**: Stateless, scalable, industry standard
- **Negative**: Tokens cannot be revoked before expiration (requires token blacklisting for immediate revocation)
- **Mitigation**: Short token expiration times (1 hour) with refresh token pattern

## API Layer Architecture

### Context
We need to choose between REST API, GraphQL, or Phoenix LiveView for the API layer. The frontend is built with React and requires real-time capabilities.

### Decision
We chose **GraphQL with Absinthe** as the primary API layer.

### Rationale
- **GraphQL Benefits**:
  - Single endpoint for all operations (queries, mutations, subscriptions)
  - Strongly typed schema with introspection
  - Client can request exactly the data needed
  - Built-in real-time subscriptions
  - Excellent tooling (GraphiQL, Apollo Client, etc.)
  - Type safety between frontend and backend

- **Why not LiveView**:
  - Frontend is React-based, not server-rendered
  - LiveView is for server-side rendered applications
  - Would require complete frontend rewrite

- **Why not REST**:
  - Multiple endpoints for different operations
  - Over-fetching or under-fetching data
  - No built-in real-time capabilities
  - More complex client-side state management

### Consequences
- **Positive**: Type safety, single endpoint, excellent developer experience
- **Negative**: Learning curve for team unfamiliar with GraphQL
- **Mitigation**: Good documentation and tooling support

## Real-time Communication Strategy

### Context
We need real-time messaging capabilities for the chat system. Phoenix provides both Channels and GraphQL Subscriptions via Absinthe.

### Decision
We chose **GraphQL Subscriptions** as the primary real-time communication method, with **Phoenix Channels** reserved for presence tracking and typing indicators.

### Rationale
- **GraphQL Subscriptions Benefits**:
  - API consistency (same schema for queries, mutations, subscriptions)
  - Type safety for real-time data
  - Standard GraphQL clients handle subscriptions automatically
  - Single WebSocket connection for all subscriptions
  - Schema evolution through GraphQL introspection

- **Phoenix Channels for**:
  - Presence tracking (who's online)
  - Typing indicators (temporary, non-persistent data)
  - System-level notifications

- **Why not Phoenix Channels for messaging**:
  - Would create API inconsistency
  - Requires separate client handling
  - No type safety for message payloads
  - Multiple WebSocket connections needed

### Consequences
- **Positive**: Consistent API, type safety, single connection
- **Negative**: Slightly more complex than pure Phoenix Channels
- **Mitigation**: Clear separation of concerns documented

## Database ID Strategy

### Context
We need to choose how to expose database identifiers in the API. Options include using internal integer IDs, UUIDs, or custom string IDs.

### Decision
We chose **NanoID with prefixes** for public API exposure while keeping **integer IDs** for internal database relationships.

### Rationale
- **NanoID Benefits**:
  - Shorter than UUIDs (10 characters vs 36)
  - URL-safe characters only
  - Collision-resistant
  - Type identification via prefixes (usr_, cht_, msg_, mbr_)
  - Security through obscurity (harder to enumerate)

- **Prefix Strategy**:
  - `usr_` for users
  - `cht_` for chats  
  - `msg_` for messages
  - `mbr_` for chat members

- **Keep Integer IDs**:
  - Efficient for foreign key relationships
  - Smaller storage footprint
  - Better database performance
  - Standard practice for internal relations

### Consequences
- **Positive**: Shorter URLs, type safety, security, performance
- **Negative**: Additional complexity in ID conversion
- **Mitigation**: Helper functions for ID conversion, clear documentation

## Data Modeling for Chat Relationships

### Context
We need to model the many-to-many relationship between Users and Chats. Options include a join table or embedding relationship data.

### Decision
We chose **ChatMember join table** over embedded relationship fields.

### Rationale
- **ChatMember Benefits**:
  - Flexible relationship management
  - Audit trail (when user joined, left)
  - Role management (admin, member, moderator)
  - Easy to query membership
  - Standard relational database pattern

- **Why not embedded fields**:
  - Less flexible for future features
  - Harder to query and manage
  - No audit trail
  - Difficult to add metadata to relationships

### Consequences
- **Positive**: Flexible, auditable, extensible
- **Negative**: Additional table and complexity
- **Mitigation**: Clear naming conventions and documentation

## Testing Strategy

### Context
We need a testing strategy that provides good test data generation and follows Elixir/Phoenix best practices.

### Decision
We chose **ExUnit with ExMachina** for testing, similar to RSpec with factory_bot in Rails.

### Rationale
- **ExUnit Benefits**:
  - Built into Elixir standard library
  - Fast and lightweight
  - Good integration with Phoenix
  - Familiar pattern for Elixir developers

- **ExMachina Benefits**:
  - Factory pattern for test data generation
  - Similar to factory_bot (familiar to Rails developers)
  - Good integration with Ecto
  - Supports associations and sequences

- **Why not alternatives**:
  - Manual test data creation is error-prone
  - Faker alone doesn't handle associations well
  - ExMachina provides the right level of abstraction

### Consequences
- **Positive**: Familiar patterns, good data generation, maintainable tests
- **Negative**: Additional dependency
- **Mitigation**: Well-documented factory patterns

## Authorization Strategy

### Context
We need to implement authorization policies for chat operations. The system needs to control who can view, create, modify, and delete chats and messages.

### Decision
We chose **Bodyguard** for authorization policies, following Rails-like policy patterns.

### Rationale
- **Bodyguard Benefits**:
  - Rails-like policy pattern familiar to many developers
  - Separation of concerns (policies separate from business logic)
  - Reusable authorization logic across contexts
  - Clear, readable policy definitions
  - Easy to test authorization rules

- **Why not inline authorization**:
  - Would scatter authorization logic throughout the codebase
  - Harder to maintain and test
  - No centralized policy management

- **Why not role-based access control libraries**:
  - More complex than needed for current requirements
  - Bodyguard provides the right level of abstraction

### Consequences
- **Positive**: Clean separation, testable, maintainable
- **Negative**: Additional dependency and learning curve
- **Mitigation**: Clear policy documentation and examples

## N+1 Query Prevention

### Context
GraphQL queries can easily trigger N+1 database queries when resolving associations. We need to prevent this for performance.

### Decision
We chose **Dataloader** for batching and caching database queries in GraphQL resolvers.

### Rationale
- **Dataloader Benefits**:
  - Automatic batching of database queries
  - Built-in caching to prevent duplicate queries
  - Standard Absinthe practice
  - Transparent to resolver logic
  - Handles complex association loading

- **Implementation**:
  - Removed eager loading from context layer
  - Deferred loading to GraphQL layer
  - Single source of truth for data loading

### Consequences
- **Positive**: Prevents N+1 queries, improves performance
- **Negative**: Additional complexity in resolver setup
- **Mitigation**: Clear documentation and examples

## Frontend State Management

### Context
We need a GraphQL client for the React frontend that handles caching, real-time subscriptions, and state management.

### Decision
We chose **urql with normalized caching** over Apollo Client or React Query.

### Rationale
- **urql Benefits**:
  - Lighter weight than Apollo Client
  - Excellent TypeScript support
  - Built-in normalized caching
  - Great developer experience
  - Automatic cache invalidation strategies

- **Why not Apollo Client**:
  - Heavier bundle size
  - More complexity than needed
  - urql provides the right feature set

- **Why not React Query**:
  - GraphQL-specific features needed
  - Real-time subscriptions required

### Consequences
- **Positive**: Lightweight, type-safe, great caching
- **Negative**: Smaller ecosystem than Apollo
- **Mitigation**: urql has excellent documentation and community

## UI Component Library

### Context
We need a modern, accessible UI component library for the React frontend that provides good TypeScript support.

### Decision
We chose **Mantine** over Tailwind CSS + Semantic UI combination.

### Rationale
- **Mantine Benefits**:
  - Modern, comprehensive component library
  - Excellent accessibility support
  - TypeScript-first design
  - Consistent design system
  - Great developer experience

- **Why not Tailwind + Semantic UI**:
  - Tailwind requires more setup and configuration
  - Semantic UI has limited TypeScript support
  - Mantine provides better consistency

### Consequences
- **Positive**: Modern, accessible, type-safe components
- **Negative**: Learning curve for new component library
- **Mitigation**: Excellent documentation and examples

## Real-time Typing Indicators

### Context
We need to implement typing indicators that show when users are typing in a chat. This requires real-time communication with low latency.

### Decision
We chose **Phoenix Channels for typing indicators** with **consolidated channel usage** to avoid conflicts.

### Rationale
- **Phoenix Channels Benefits**:
  - Low latency for temporary, ephemeral data
  - Perfect for presence tracking and typing indicators
  - Built-in authentication and authorization
  - Efficient broadcasting to channel members

- **Critical Pattern - Consolidated Channel Usage**:
  - Only one component should join the typing channel per chat
  - Pass typing functions down to child components
  - Avoid duplicate channel subscriptions (causes indicators to fail)
  - Single channel connection per user per chat

### Consequences
- **Positive**: Low latency, efficient, reliable
- **Negative**: Requires careful channel management
- **Mitigation**: Clear patterns documented, consolidated usage enforced

## Code Organization

### Context
We need to organize business logic following Phoenix best practices with clear boundaries and separation of concerns.

### Decision
We chose **strict Phoenix Context boundaries** (Accounts, Chats, Messages) with clear ownership of data models.

### Rationale
- **Context Benefits**:
  - Clear separation of concerns
  - Each context owns its data models
  - Public API functions expose business logic
  - Easy to test and maintain
  - Follows Phoenix conventions

- **Pattern**:
  - Contexts own their data models
  - Expose public API functions
  - No cross-context dependencies
  - Clear boundaries between contexts

### Consequences
- **Positive**: Maintainable, testable, clear boundaries
- **Negative**: Requires discipline to maintain boundaries
- **Mitigation**: Clear documentation and code reviews

## Semantic Naming Conventions

### Context
We need consistent, readable variable and function names that make the code self-documenting and reduce cognitive load.

### Decision
We chose **semantic naming** over numbered variables (creator_id vs user1_id) throughout the codebase.

### Rationale
- **Semantic Naming Benefits**:
  - Self-documenting code
  - Reduces cognitive load
  - Easier to understand and maintain
  - Clear intent and purpose
  - Better for code reviews

- **Examples**:
  - `creator_id` instead of `user1_id`
  - `participant_id` instead of `user2_id`
  - `existing_chat` instead of `chat1`

### Consequences
- **Positive**: More readable, maintainable code
- **Negative**: Slightly longer variable names
- **Mitigation**: Clear naming guidelines documented

## Chat State Management

### Context
We need to handle chat states (active/inactive) efficiently while providing good performance for chat lists and member management.

### Decision
We chose **explicit state column with cached denormalization** using `member_names` array and `is_direct` flag.

### Rationale
- **State Management Benefits**:
  - Explicit state transitions (active/inactive)
  - Soft deletes for audit trails
  - Clear state semantics

- **Cached Denormalization Benefits**:
  - `member_names` array for fast chat list rendering
  - `is_direct` flag for direct message identification
  - Reduced database queries for common operations
  - Better performance for chat lists

- **Trade-offs**:
  - Cache invalidation complexity
  - Additional storage for cached data
  - Better query performance

### Consequences
- **Positive**: Better performance, explicit state management
- **Negative**: Cache invalidation complexity
- **Mitigation**: Clear invalidation patterns, helper functions

## Direct Message vs Named Chat Strategy

### Context
We need to handle both direct messages (1-on-1) and named group chats in a unified way that allows conversion between types.

### Decision
We chose **unified chat model with optional name and `is_direct` flag** over separate tables.

### Rationale
- **Unified Model Benefits**:
  - Simpler than separate tables
  - Allows conversion from DM to group chat
  - Single codebase for both types
  - Easier to query and manage

- **Pattern**:
  - Name uniqueness for named chats
  - Participant uniqueness for unnamed chats
  - `is_direct` flag for identification
  - Optional name field

### Consequences
- **Positive**: Simpler model, flexible conversion
- **Negative**: More complex business logic
- **Mitigation**: Clear patterns and helper functions

## Testing Best Practices

### Context
We need comprehensive testing guidelines that ensure code quality and maintainability across the entire system.

### Decision
We chose **documented comprehensive testing guidelines** with specific patterns for different types of tests.

### Rationale
- **Testing Guidelines Benefits**:
  - Consistency across the codebase
  - Clear patterns for different test types
  - Quality assurance
  - Maintainable test suite

- **Patterns**:
  - Flat describe blocks (no nesting)
  - Semantic factory names
  - Comprehensive coverage
  - Clear test organization

### Consequences
- **Positive**: Consistent, maintainable tests
- **Negative**: Requires discipline to follow guidelines
- **Mitigation**: Clear documentation and code reviews

## Summary

These architectural decisions create a modern, scalable, and maintainable chat messaging system that:

1. **Scales horizontally** with stateless JWT authentication
2. **Provides excellent developer experience** with GraphQL and type safety
3. **Handles real-time communication** efficiently with WebSocket subscriptions
4. **Maintains security** with Argon2 password hashing and obfuscated IDs
5. **Supports enterprise features** like audit trails and role management
6. **Follows Elixir/Phoenix best practices** for testing and data modeling
7. **Prevents performance issues** with proper query optimization
8. **Ensures code quality** with comprehensive testing and semantic naming

The architecture is designed to be both simple enough for the current requirements while being extensible for future enterprise features.
