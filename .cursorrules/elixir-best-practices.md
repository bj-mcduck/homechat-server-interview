# Elixir Best Practices

This file defines best practices and conventions for Elixir/Phoenix development in this project.

## Semantic Naming Over Numbered Variables

### Never Use Numbered Variables
**Never use numbered variables** - they provide no context about what makes the variables different:

```elixir
# ❌ Bad - meaningless numbers
def create_direct_chat(user1_id, user2_id) do
  # Which user is the creator? Which is the participant?
end

def add_chat_members(chat_id, user_ids) do
  # What's the relationship between these users?
end

# ✅ Good - semantic names based on role/purpose
def create_direct_chat(creator_id, participant_id) do
  # Clear: creator initiates, participant joins
end

def add_chat_members(chat_id, member_ids) do
  # Clear: these are the members being added
end
```

### Role-Based Parameter Naming
Use names that indicate the role or relationship:

```elixir
# ✅ Good - role-based naming
def create_chat(attrs, creator_id, participant_ids)
def get_existing_direct_chat(owner_id, participant_id)
def add_chat_members(chat_id, member_ids, role)

# ✅ Good - purpose-based naming  
def authenticate_user(email, password)
def send_message(chat_id, sender_id, content)
def list_user_chats(user_id)
```

### Common Semantic Patterns
- **Ownership**: `owner_id`, `creator_id`, `initiator_id`
- **Participation**: `participant_id`, `member_id`, `user_id`
- **Relationships**: `sender_id`, `recipient_id`, `author_id`
- **Context**: `current_user`, `target_user`, `admin_user`

## Method Consolidation Patterns

### Single Method with Convenience Wrappers
When you have similar methods, prefer one main implementation with convenience wrappers:

```elixir
# ✅ Good - main method with convenience wrapper
def create_chat(attrs, creator_id, participant_ids) do
  # Main implementation
end

def create_direct_chat(creator_id, participant_id) do
  attrs = %{state: :active}
  create_chat(attrs, creator_id, [participant_id])
end

# ❌ Bad - duplicate logic
def create_direct_chat(creator_id, participant_id) do
  # Duplicate implementation
end

def create_group_chat(attrs, creator_id, member_ids) do
  # Similar but different implementation
end
```

### Prefer Single Methods
Only create multiple methods when there's significant setup that will always be needed:

```elixir
# ✅ Good - different enough to warrant separate methods
def create_user(attrs) do
  # Basic user creation
end

def register_user(attrs) do
  # User creation + email verification + welcome email
  # Significant additional setup
end
```

## Function Parameter Guidelines

### Parameter Order
Order parameters by importance and frequency of use:

```elixir
# ✅ Good - most important first, optional last
def create_chat(attrs, creator_id, participant_ids, opts \\ [])

# ✅ Good - context first, action second
def send_message(chat_id, sender_id, content)
def authenticate_user(email, password)
```

### Avoid Generic Names
Use specific names that indicate purpose:

```elixir
# ❌ Bad - too generic
def process_data(data, user, options)

# ✅ Good - specific purpose
def send_notification(message, recipient, delivery_options)
```

## Variable Naming in Tests

### Test Data Naming
Use semantic names that describe the test scenario:

```elixir
# ❌ Bad - meaningless numbers
user1 = insert(:user)
user2 = insert(:user)
chat1 = insert(:chat)

# ✅ Good - semantic names based on purpose
alice = insert(:user, %{username: "alice"})
bob = insert(:user, %{username: "bob"})
alice_bob_dm = insert(:chat, %{name: "Alice & Bob"})
texans_chat = insert(:chat, %{name: "Texans", private: false})
```

### Test Scenario Naming
Name variables based on their role in the test:

```elixir
# ✅ Good - clear roles
admin_user = insert(:user, %{role: :admin})
regular_user = insert(:user, %{role: :member})
public_chat = insert(:chat, %{private: false})
private_chat = insert(:chat, %{private: true})
```

## Query and Database Naming

### Query Variable Names
Use descriptive names for query variables:

```elixir
# ❌ Bad - generic abbreviations
from(c in ChatModel,
  join: cm1 in ChatMemberModel, on: c.id == cm1.chat_id,
  join: cm2 in ChatMemberModel, on: c.id == cm2.chat_id,
  where: cm1.user_id == ^user1_id and cm2.user_id == ^user2_id
)

# ✅ Good - descriptive names
from(chat in ChatModel,
  join: creator_member in ChatMemberModel, on: chat.id == creator_member.chat_id,
  join: participant_member in ChatMemberModel, on: chat.id == participant_member.chat_id,
  where: creator_member.user_id == ^creator_id and participant_member.user_id == ^participant_id
)
```

## Error Handling Patterns

### Error Tuple Naming
Use descriptive error atoms:

```elixir
# ✅ Good - descriptive error types
{:error, :user_not_found}
{:error, :chat_not_accessible}
{:error, :insufficient_permissions}

# ❌ Bad - generic errors
{:error, :not_found}
{:error, :forbidden}
```

## Documentation Standards

### Function Documentation
Document the purpose and parameter roles:

```elixir
@doc """
Creates a direct chat between two users.

- `creator_id` - The user initiating the chat (becomes owner)
- `participant_id` - The other user in the direct chat

Returns `{:ok, chat}` on success, `{:error, reason}` on failure.
"""
def create_direct_chat(creator_id, participant_id)
```

## Performance Considerations

### Avoid N+1 Queries
Use preloading for associations:

```elixir
# ✅ Good - preload associations
def list_user_chats(user_id) do
  from(c in ChatModel,
    join: cm in ChatMemberModel, on: c.id == cm.chat_id,
    where: cm.user_id == ^user_id,
    preload: [:members, :messages]
  )
  |> Repo.all()
end
```

### Use Appropriate Data Types
Choose the right data structure for the use case:

```elixir
# ✅ Good - list for ordered data
def list_recent_messages(chat_id, limit \\ 20)

# ✅ Good - map for key-value lookups
def get_user_by_email(email)
```

## Reducing Cyclomatic Complexity

Cyclomatic complexity measures the number of linearly independent paths through code. High complexity makes code harder to understand, test, and maintain.

### Use Pattern Matching Over Nested Conditionals

**❌ Bad - Deeply nested conditionals:**
```elixir
def process_user(user) do
  if user != nil do
    if user.active do
      if user.email_verified do
        send_email(user)
      else
        {:error, :email_not_verified}
      end
    else
      {:error, :inactive_user}
    end
  else
    {:error, :user_not_found}
  end
end
```

**✅ Good - Pattern matching with guard clauses:**
```elixir
def process_user(nil), do: {:error, :user_not_found}
def process_user(%{active: false}), do: {:error, :inactive_user}
def process_user(%{email_verified: false}), do: {:error, :email_not_verified}
def process_user(user), do: send_email(user)
```

### Use `with` for Complex Flows

**❌ Bad - Nested case statements:**
```elixir
def send_message(chat_nanoid, user_id, content) do
  case Chats.get_chat(chat_nanoid) do
    nil -> {:error, :not_found}
    chat ->
      case Chats.user_member_of_chat?(user_id, chat.id) do
        false -> {:error, :forbidden}
        true ->
          case create_message(%{chat_id: chat.id, user_id: user_id, content: content}) do
            {:ok, message} -> {:ok, Repo.preload(message, :user)}
            error -> error
          end
      end
  end
end
```

**✅ Good - Railway-oriented programming with `with`:**
```elixir
def send_message(chat_nanoid, user_id, content) do
  with {:ok, chat} <- get_chat_or_error(chat_nanoid),
       :ok <- authorize_user(user_id, chat.id),
       {:ok, message} <- create_message(%{chat_id: chat.id, user_id: user_id, content: content}) do
    {:ok, Repo.preload(message, :user)}
  end
end

defp get_chat_or_error(chat_nanoid) do
  case Chats.get_chat(chat_nanoid) do
    nil -> {:error, :not_found}
    chat -> {:ok, chat}
  end
end

defp authorize_user(user_id, chat_id) do
  if Chats.user_member_of_chat?(user_id, chat_id), do: :ok, else: {:error, :forbidden}
end
```

### Extract Logic to Helper Functions

**❌ Bad - Large function with multiple concerns:**
```elixir
def create_chat(attrs, creator_id, participant_ids) do
  Repo.transaction(fn ->
    chat_attrs = Map.put(attrs, :state, :active)
    changeset = ChatModel.changeset(%ChatModel{}, chat_attrs)
    
    case Repo.insert(changeset) do
      {:ok, chat} ->
        creator_member = %{chat_id: chat.id, user_id: creator_id, role: :owner, ...}
        case Repo.insert(ChatMemberModel.changeset(%ChatMemberModel{}, creator_member)) do
          {:ok, _} ->
            Enum.each(participant_ids, fn pid ->
              member = %{chat_id: chat.id, user_id: pid, role: :member, ...}
              Repo.insert!(ChatMemberModel.changeset(%ChatMemberModel{}, member))
            end)
            Chats.get_chat_with_members(chat.nanoid)
          error -> Repo.rollback(error)
        end
      error -> Repo.rollback(error)
    end
  end)
end
```

**✅ Good - Extracted helper functions:**
```elixir
def create_chat(attrs, creator_id, participant_ids) do
  Repo.transaction(fn ->
    with {:ok, chat} <- create_chat_record(attrs),
         {:ok, _} <- add_chat_members(chat.id, [creator_id], :owner),
         {:ok, _} <- add_participants(chat.id, participant_ids) do
      get_chat_with_members(chat.nanoid)
    else
      {:error, changeset} -> Repo.rollback(changeset)
    end
  end)
end

defp create_chat_record(attrs) do
  attrs = Map.put(attrs, :state, :active)
  %ChatModel{}
  |> ChatModel.changeset(attrs)
  |> Repo.insert()
end

defp add_participants(_chat_id, []), do: {:ok, []}
defp add_participants(chat_id, participant_ids) do
  add_chat_members(chat_id, participant_ids, :member)
end
```

### Use Credo for Complexity Analysis

Add Credo to your project and configure complexity checks:

```elixir
# .credo.exs
%{
  configs: [
    %{
      checks: [
        {Credo.Check.Refactor.CyclomaticComplexity, [max_complexity: 9]},
        {Credo.Check.Refactor.Nesting, [max_nesting: 3]},
        {Credo.Check.Refactor.FunctionArity, [max_arity: 5]}
      ]
    }
  ]
}
```

**Community Resources:**
- [Credo CyclomaticComplexity](https://hexdocs.pm/credo/Credo.Check.Refactor.CyclomaticComplexity.html)
- [Elixir Library Guidelines](https://hexdocs.pm/elixir/library-guidelines.html)
- [Railway-Oriented Programming](https://medium.com/dive-into-elixir/5-productivity-tips-for-elixir-programming-636c390259a6)

## Real-time Subscriptions at Scale

### ❌ Anti-Pattern: Per-Resource Subscriptions

**Problem:** Creating one subscription per chat/resource doesn't scale.

```elixir
# Bad - Per-chat subscriptions
field :message_sent, :message do
  arg :chat_id, non_null(:string)
  config(fn args, _info ->
    {:ok, topic: "chat:#{args.chat_id}"}
  end)
end
```

**Consequence:** User in 100 chats = 100+ active subscriptions. Not enterprise-ready.

### ✅ Best Practice: User-Scoped Subscriptions

**Solution:** Publish events to user-specific topics, not resource-specific topics.

```elixir
# Good - User-scoped subscriptions
field :user_messages, :user_message_event do
  arg :user_id, non_null(:string)
  config(fn args, _info ->
    {:ok, topic: "user_messages:#{args.user_id}"}
  end)
end

object :user_message_event do
  field :chat_id, non_null(:string)
  field :message, non_null(:message)
end
```

**Publishing:**
```elixir
# Publish to all chat members
chat = Chats.get_chat_with_members(chat_nanoid)
Enum.each(chat.members, fn member ->
  event = %{chat_id: chat_nanoid, message: message}
  Absinthe.Subscription.publish(ServerWeb.Endpoint, event,
    user_messages: "user_messages:#{member.nanoid}")
end)
```

**Benefits:**
- ✅ 2-3 subscriptions per user regardless of chat count
- ✅ Scales to 100s of chats
- ✅ Single WebSocket connection for all data
- ✅ Enterprise-ready architecture

**Reference:** See `ARCHITECTURE.md` - "Single WebSocket connection for all subscriptions"

## Database Query Optimization

### ❌ Anti-Pattern: N+1 Queries

**Problem:** Loading associations in loops causes N+1 queries.

```elixir
# Bad - N+1 queries (1 + N queries for N messages)
def list_messages(chat_id) do
  messages = Repo.all(from m in Message, where: m.chat_id == ^chat_id)
  # GraphQL resolver will make N queries for users
  Enum.map(messages, &{&1, Repo.get(User, &1.user_id)})
end
```

### ✅ Best Practice: Use Dataloader

**Solution:** Batch association loading with Dataloader.

```elixir
# Good - Configure Dataloader
def context(ctx) do
  loader =
    Dataloader.new()
    |> Dataloader.add_source(Server.Accounts, Dataloader.Ecto.new(Repo))
    |> Dataloader.add_source(Server.Chats, Dataloader.Ecto.new(Repo))

  Map.put(ctx, :loader, loader)
end

# In schema
import Absinthe.Resolution.Helpers, only: [dataloader: 1]

field :user, non_null(:user), resolve: dataloader(Server.Accounts)
field :chat, non_null(:chat), resolve: dataloader(Server.Chats)
```

**Benefits:**
- ✅ Batches N queries into 2 queries
- ✅ Caches results within request
- ✅ GraphQL best practice
- ✅ Massive performance improvement

### ❌ Anti-Pattern: In-Memory Pagination

**Problem:** Loading all records into memory then paginating.

```elixir
# Bad - Loads all users into memory
def list_users(limit, offset) do
  Repo.all(User)
  |> Enum.drop(offset)
  |> Enum.take(limit)
end
```

### ✅ Best Practice: Database-Level Pagination

**Solution:** Let the database handle pagination.

```elixir
# Good - Database pagination
def list_users(opts \\ []) do
  limit = Keyword.get(opts, :limit, 100)
  offset = Keyword.get(opts, :offset, 0)

  from(u in User,
    where: u.state == :active,
    limit: ^limit,
    offset: ^offset
  )
  |> Repo.all()
end
```

**Benefits:**
- ✅ Memory efficient
- ✅ Fast queries with proper indexes
- ✅ Scales to millions of records

### ❌ Anti-Pattern: Eager Loading Everything

**Problem:** Always preloading associations, even when not needed.

```elixir
# Bad - Always loads members and messages
def get_chat(nanoid) do
  from(c in Chat,
    where: c.nanoid == ^nanoid,
    preload: [:members, :messages]  # Always loads
  )
  |> Repo.one()
end
```

### ✅ Best Practice: Lazy Loading with Dataloader

**Solution:** Let GraphQL schema load only requested associations.

```elixir
# Good - No preload, Dataloader handles it
def get_chat(nanoid) do
  Repo.get_by(Chat, nanoid: nanoid)
end

# In schema - Dataloader loads only if requested
field :members, list_of(:user), resolve: dataloader(Server.Chats)
```

**Benefits:**
- ✅ Only loads requested data
- ✅ Reduces bandwidth
- ✅ GraphQL philosophy: "Load what you need"

## Code Formatting Standards

### No Double Blank Lines

**❌ Bad - Multiple blank lines:**
```elixir
def function_one do
  :ok
end


def function_two do
  :ok
end
```

**✅ Good - Single blank line between functions:**
```elixir
def function_one do
  :ok
end

def function_two do
  :ok
end
```

**Enforcement:** Configure in `.formatter.exs`:
```elixir
[
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  line_length: 120
]
```

Run `mix format --check-formatted` in CI to enforce.

### Maximum Nesting Depth

**Guideline:** Limit nesting to 3 levels maximum.

**❌ Bad - 4+ levels of nesting:**
```elixir
def process(data) do
  if valid?(data) do
    case parse(data) do
      {:ok, parsed} ->
        if authorized?(parsed) do
          case save(parsed) do
            {:ok, saved} -> {:ok, saved}
            error -> error
          end
        end
      error -> error
    end
  end
end
```

**✅ Good - Use `with` to flatten:**
```elixir
def process(data) do
  with :ok <- validate(data),
       {:ok, parsed} <- parse(data),
       :ok <- authorize(parsed),
       {:ok, saved} <- save(parsed) do
    {:ok, saved}
  end
end
```

### Function Length

**Guideline:** Keep functions under 20 lines. Extract logic if longer.

**Tool:** Use Credo's `Credo.Check.Refactor.LongQuoteBlocks` and `Credo.Check.Refactor.FunctionArity`.

---

This file serves as a guide for maintaining consistent, semantic naming throughout the Elixir codebase. Follow these conventions for better code readability, maintainability, and team collaboration.

## References

- [Credo Cyclomatic Complexity](https://hexdocs.pm/credo/Credo.Check.Refactor.CyclomaticComplexity.html)
- [Elixir Library Guidelines](https://hexdocs.pm/elixir/library-guidelines.html)
- [Elixir Code Anti-Patterns](https://hexdocs.pm/elixir/code-anti-patterns.html)
- [Railway-Oriented Programming in Elixir](https://medium.com/dive-into-elixir/5-productivity-tips-for-elixir-programming-636c390259a6)
- [Improving Cohesion in Elixir](https://soonernotfaster.com/posts/step-by-step-guide-to-improving-cohesion-in-elixir/)
