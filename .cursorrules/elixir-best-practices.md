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

---

This file serves as a guide for maintaining consistent, semantic naming throughout the Elixir codebase. Follow these conventions for better code readability, maintainability, and team collaboration.
