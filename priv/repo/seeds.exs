# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Server.Repo.insert!(%Server.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Server.{Accounts, Chats, Messages}
alias Server.Models.{UserModel, ChatModel, ChatMemberModel, MessageModel}

# Create sample users
users = [
  %{
    email: "alice@example.com",
    username: "alice",
    password: "password123",
    first_name: "Alice",
    last_name: "Johnson",
    state: :active
  },
  %{
    email: "bob@example.com",
    username: "bob",
    password: "password123",
    first_name: "Bob",
    last_name: "Smith",
    state: :active
  },
  %{
    email: "charlie@example.com",
    username: "charlie",
    password: "password123",
    first_name: "Charlie",
    last_name: "Brown",
    state: :active
  },
  %{
    email: "diana@example.com",
    username: "diana",
    password: "password123",
    first_name: "Diana",
    last_name: "Wilson",
    state: :active
  }
]

created_users = Enum.map(users, fn user_attrs ->
  case Accounts.create_user(user_attrs) do
    {:ok, user} -> user
    {:error, changeset} -> 
      IO.puts("Failed to create user #{user_attrs.email}: #{inspect(changeset.errors)}")
      nil
  end
end) |> Enum.filter(& &1)

IO.puts("Created #{length(created_users)} users")

# Create direct chats
[alice, bob, charlie, diana] = created_users

# Alice and Bob direct chat
{:ok, alice_bob_chat} = Chats.create_direct_chat(alice.id, bob.id)

# Charlie and Diana direct chat
{:ok, charlie_diana_chat} = Chats.create_direct_chat(charlie.id, diana.id)

IO.puts("Created 2 direct chats")

# Create group chats
{:ok, group_chat} = Chats.create_group_chat(
  %{name: "General Discussion", private: true, state: :active},
  alice.id,
  [bob.id, charlie.id, diana.id]
)

{:ok, public_chat} = Chats.create_group_chat(
  %{name: "Public Chat", private: false, state: :active},
  alice.id,
  [bob.id, charlie.id]
)

IO.puts("Created 2 group chats")

# Create some sample messages
sample_messages = [
  {alice_bob_chat.id, alice.id, "Hey Bob! How are you?"},
  {alice_bob_chat.id, bob.id, "Hi Alice! I'm doing great, thanks for asking."},
  {alice_bob_chat.id, alice.id, "Want to grab coffee later?"},
  {charlie_diana_chat.id, charlie.id, "Diana, did you see the latest news?"},
  {charlie_diana_chat.id, diana.id, "Yes! It's quite interesting."},
  {group_chat.id, alice.id, "Welcome everyone to our group chat!"},
  {group_chat.id, bob.id, "Thanks for creating this, Alice!"},
  {group_chat.id, charlie.id, "Great to be here!"},
  {group_chat.id, diana.id, "Looking forward to our discussions!"},
  {public_chat.id, alice.id, "This is a public chat room"},
  {public_chat.id, bob.id, "Anyone can join this chat"},
  {public_chat.id, charlie.id, "Cool! I can see this from outside"}
]

Enum.each(sample_messages, fn {chat_id, user_id, content} ->
  case Messages.send_message(chat_id, user_id, content) do
    {:ok, _message} -> :ok
    {:error, reason} -> 
      IO.puts("Failed to create message: #{inspect(reason)}")
  end
end)

IO.puts("Created #{length(sample_messages)} sample messages")

IO.puts("Seeding completed successfully!")

alias Server.Repo
alias Server.Models.UserModel

[
  %{
    first_name: "User",
    last_name: "1",
    email: "user_1@test.com",
    state: :active
  },
  %{
    first_name: "User",
    last_name: "2",
    email: "user_2@test.com",
    state: :active
  },
  %{
    first_name: "User",
    last_name: "3",
    email: "user_3@test.com",
    state: :active
  }
]
|> Enum.each(fn attrs ->
  %UserModel{}
  |> UserModel.changeset(attrs)
  |> Repo.insert!(
    on_conflict: :replace_all,
    conflict_target: [:email]
  )
end)
