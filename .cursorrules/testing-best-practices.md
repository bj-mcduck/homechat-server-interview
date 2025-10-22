# Chat Messaging API - Cursor Rules

This file defines best practices and conventions for this Phoenix/Elixir chat messaging project.

## Testing Best Practices

### ExUnit Framework
- Use ExUnit (Phoenix's built-in testing framework) for all tests
- Organize tests with `describe` blocks for logical grouping
- Use `setup` blocks for shared test data preparation
- Prefer `assert` over `refute` for positive assertions

### Test Naming Convention
**Avoid "when", "with", "without" in `test` blocks** - these words indicate shared setup that belongs in a `describe` block:

```elixir
# ❌ Bad - "when" indicates shared setup
test "returns error when user is not authenticated" do
  # test code
end

# ✅ Good - use nested describe for conditions
describe "when user is not authenticated" do
  test "returns error" do
    # test code
  end
end
```

### ExMachina Factory Guidelines
- **Location**: Place factories in `test/support/factory.ex`
- **Sequences**: Use `sequence` for unique values (emails, usernames)
- **Associations**: Handle associations with `build_assoc/2` or `insert_assoc/2`
- **Factory methods**:
  - `build/1` - Creates struct without database
  - `insert/1` - Creates and saves to database
  - `params_for/1` - Returns attributes map for forms
- **Time handling**: Use explicit timestamps instead of delays
  - **Bad**: `Process.sleep(1)` or `:timer.sleep(1)`
  - **Good**: Explicit `inserted_at`/`updated_at` with `NaiveDateTime.add/3`

```elixir
# Factory example
def user_factory do
  %{
    first_name: "Alice",
    last_name: "Smith",
    username: sequence(:username, &"user_#{&1}"),
    email: sequence(:email, &"user#{&1}@example.com"),
    password_hash: Argon2.hash_pwd_salt("password123")
  }
end
```

## Naming Conventions

### Semantic Names Over Numbered Variables
**Never use numbered variables** - they provide no context about what makes the variables different:

```elixir
# ❌ Bad - meaningless numbers
user1 = insert(:user)
user2 = insert(:user)
chat1 = insert(:chat)
chat2 = insert(:chat)

# ✅ Good - semantic names based on purpose
alice = insert(:user, %{username: "alice"})
bob = insert(:user, %{username: "bob"})
alice_bob_dm = insert(:chat, %{name: "Alice & Bob"})
texans_chat = insert(:chat, %{name: "Texans", private: false})
```

### Naming Guidelines
- **Direct messages**: `alice_bob_dm`, `admin_support_dm`
- **Group chats**: `texans_chat`, `engineering_team_chat`
- **Users**: `alice`, `bob`, `admin_user`, `guest_user`
- **Chats**: Name based on participants or purpose
- **Messages**: `welcome_message`, `error_message`, `system_announcement`

## Phoenix/Elixir Best Practices

### Context Pattern
- Organize business logic in context modules (e.g., `Server.Accounts`, `Server.Chats`)
- One context per business domain
- Keep contexts focused and cohesive

### Ecto Changesets
- Always use changesets for data validation
- Use `cast/3` for external data, `change/2` for internal changes
- Validate required fields and formats

```elixir
def changeset(user, attrs) do
  user
  |> cast(attrs, [:first_name, :last_name, :email, :username])
  |> validate_required([:first_name, :last_name, :email, :username])
  |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/)
  |> unique_constraint(:email)
  |> unique_constraint(:username)
end
```

### Pattern Matching
- Prefer pattern matching over conditional logic
- Use `case` statements for multiple conditions
- Handle error tuples explicitly

```elixir
# ✅ Good - explicit error handling
case Accounts.create_user(attrs) do
  {:ok, user} -> {:ok, user}
  {:error, changeset} -> {:error, "Validation failed: #{inspect(changeset.errors)}"}
end
```

### Module Documentation
- Use `@moduledoc` for module-level documentation
- Use `@doc` for function documentation
- Include examples in complex functions

```elixir
@moduledoc """
Context for user account management.
Handles user registration, authentication, and profile management.
"""

@doc """
Creates a new user account.
Returns {:ok, user} on success, {:error, changeset} on failure.
"""
```

## GraphQL/Absinthe Conventions

### Schema Organization
- Keep schemas in `lib/server_web/schemas/`
- One schema file per domain (user_schema.ex, chat_schema.ex)
- Use middleware for authentication and authorization

### Resolver Patterns
- Keep resolvers focused and simple
- Use context for business logic, not resolvers
- Handle errors gracefully with descriptive messages

### Type Safety
- Define all types explicitly
- Use non-null types (`non_null(:string)`) for required fields
- Document complex types with descriptions

## Code Organization

### File Structure
- **Models**: `lib/server/models/` - Ecto schemas
- **Contexts**: `lib/server/` - Business logic
- **Schemas**: `lib/server_web/schemas/` - GraphQL types
- **Controllers**: `lib/server_web/controllers/` - HTTP endpoints
- **Channels**: `lib/server_web/channels/` - WebSocket handlers

### Separation of Concerns
- **Models**: Data structure and validation
- **Contexts**: Business logic and data access
- **Schemas**: API interface and type definitions
- **Controllers**: HTTP request/response handling

## Testing Coverage Expectations

### Unit Tests
- Test all context functions
- Test model changesets and validations
- Test GraphQL resolvers
- Test middleware functions

### Integration Tests
- Test complete user flows
- Test GraphQL query/mutation chains
- Test WebSocket connections
- Test authentication flows

### Test Organization
```elixir
defmodule Server.ChatsTest do
  use Server.DataCase, async: true
  import Server.Factory

  describe "create_direct_chat/2" do
    test "creates a chat between two users" do
      alice = insert(:user, %{username: "alice"})
      bob = insert(:user, %{username: "bob"})
      
      assert {:ok, chat} = Chats.create_direct_chat(alice.id, bob.id)
      assert chat.name == "Alice & Bob"
    end

    describe "when users are the same" do
      test "returns error" do
        alice = insert(:user)
        
        assert {:error, _} = Chats.create_direct_chat(alice.id, alice.id)
      end
    end
  end
end
```

## Error Handling

### Error Tuples
- Use `{:ok, result}` for success
- Use `{:error, reason}` for failures
- Provide descriptive error messages
- Use atoms for error types (`:not_found`, `:forbidden`, `:validation_failed`)

### GraphQL Errors
- Return user-friendly error messages
- Use proper HTTP status codes
- Log detailed errors server-side only

## Performance Considerations

### Database Queries
- Use `Repo.preload/2` for associations
- Avoid N+1 queries in GraphQL resolvers
- Use `Ecto.Multi` for complex transactions

### Real-time Features
- Use Phoenix PubSub for broadcasting
- Implement proper subscription cleanup
- Handle connection drops gracefully

## Time and Date Testing

### Avoid Delays in Tests
- **Never use**: `Process.sleep/1`, `:timer.sleep/1`, or similar delays
- **Anti-pattern**: Adding delays to "ensure" ordering or timing
- **Better approach**: Use explicit timestamps or time stubbing

### Time Stubbing for Complex Scenarios
For tests requiring time manipulation (like testing time-based business logic):

```elixir
# Using ExUnit's built-in time stubbing (if available)
# Or use libraries like `timex` with `Timex.freeze/1`

# Example: Testing time-sensitive operations
defmodule MyTest do
  use ExUnit.Case
  
  test "processes events within time window" do
    # Freeze time at a specific moment
    Timex.freeze(~N[2023-01-01 12:00:00])
    
    # Run time-sensitive test logic
    # ...
    
    # Time automatically unfreezes after test
  end
end
```

### Explicit Timestamps for Ordering
When testing ordered data (messages, events, etc.):

```elixir
# ✅ Good - explicit timestamps
now = NaiveDateTime.utc_now()
first_message = insert(:message, inserted_at: now)
second_message = insert(:message, inserted_at: NaiveDateTime.add(now, 1, :second))

# ❌ Bad - relying on system timing
first_message = insert(:message)
Process.sleep(1)  # Never do this!
second_message = insert(:message)
```

---

This file serves as a guide for maintaining consistent, high-quality code throughout the project. Follow these conventions for better code readability, maintainability, and team collaboration.
