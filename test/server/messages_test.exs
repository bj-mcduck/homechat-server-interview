defmodule Server.MessagesTest do
  use Server.DataCase, async: true

  alias Server.{Messages, Chats}
  alias Server.Models.MessageModel
  alias Server.Factory

  describe "send_message/3" do
    test "sends message when user is member of chat" do
      user = Factory.insert(:user)
      other_user = Factory.insert(:user)
      {:ok, chat} = Chats.create_direct_chat(user.id, other_user.id)

      assert {:ok, message} = Messages.send_message(chat.nanoid, user.id, "Hello!")
      assert message.content == "Hello!"
      assert message.user_id == user.id
      assert message.chat_id == chat.id
    end

    test "returns error when user is not member of chat" do
      user = Factory.insert(:user)
      chat = Factory.insert(:chat)

      assert {:error, :forbidden} = Messages.send_message(chat.nanoid, user.id, "Hello!")
    end
  end

  describe "list_messages/2" do
    test "lists messages for a chat with cursor-based pagination" do
      user = Factory.insert(:user)
      other_user = Factory.insert(:user)
      {:ok, chat} = Chats.create_direct_chat(user.id, other_user.id)

      # Create messages with explicit timestamps for testing
      now = NaiveDateTime.utc_now()

      Factory.insert(:message, chat: chat, user: user, content: "Message 1",
        inserted_at: NaiveDateTime.add(now, -4, :second))
      Factory.insert(:message, chat: chat, user: user, content: "Message 2",
        inserted_at: NaiveDateTime.add(now, -3, :second))
      Factory.insert(:message, chat: chat, user: user, content: "Message 3",
        inserted_at: NaiveDateTime.add(now, -2, :second))
      Factory.insert(:message, chat: chat, user: user, content: "Message 4",
        inserted_at: NaiveDateTime.add(now, -1, :second))
      Factory.insert(:message, chat: chat, user: user, content: "Message 5",
        inserted_at: now)

      # Initial load: should return most recent messages (limited by limit)
      result = Messages.list_messages(chat.nanoid, limit: 3)
      assert length(result) == 3

      # Should be in ascending order (oldest first)
      assert hd(result).content == "Message 3"
      assert List.last(result).content == "Message 5"
    end

    test "cursor pagination loads older messages" do
      user = Factory.insert(:user)
      other_user = Factory.insert(:user)
      {:ok, chat} = Chats.create_direct_chat(user.id, other_user.id)

      now = NaiveDateTime.utc_now()

      # Create 5 messages (in ascending time order)
      Factory.insert(:message, chat: chat, user: user, content: "Oldest",
        inserted_at: NaiveDateTime.add(now, -200, :second))
      Factory.insert(:message, chat: chat, user: user, content: "Old",
        inserted_at: NaiveDateTime.add(now, -100, :second))
      Factory.insert(:message, chat: chat, user: user, content: "Middle",
        inserted_at: NaiveDateTime.add(now, -50, :second))
      Factory.insert(:message, chat: chat, user: user, content: "Recent",
        inserted_at: NaiveDateTime.add(now, -10, :second))
      Factory.insert(:message, chat: chat, user: user, content: "Latest",
        inserted_at: now)

      # Initial load (most recent 2 messages, returned in ascending order)
      first_page = Messages.list_messages(chat.nanoid, limit: 2)
      assert length(first_page) == 2
      assert hd(first_page).content == "Recent"
      assert List.last(first_page).content == "Latest"

      # Get cursor from oldest message in first page (to get messages older than this)
      oldest_in_page = hd(first_page)
      cursor = oldest_in_page.inserted_at |> NaiveDateTime.to_iso8601()

      # Load older messages (should get messages older than "Recent")
      second_page = Messages.list_messages(chat.nanoid, limit: 2, before: cursor)
      assert length(second_page) == 2
      # Should get messages older than "Recent" (in ascending order for display)
      assert hd(second_page).content == "Old"
      assert List.last(second_page).content == "Middle"
    end

    test "handles invalid cursor gracefully" do
      user = Factory.insert(:user)
      other_user = Factory.insert(:user)
      {:ok, chat} = Chats.create_direct_chat(user.id, other_user.id)

      Factory.insert_list(3, :message, chat: chat, user: user)

      # Invalid cursor should return empty list, not crash
      result = Messages.list_messages(chat.nanoid, limit: 10, before: "invalid-date")
      assert result == []
    end

    test "returns empty list for chat with no messages" do
      user = Factory.insert(:user)
      other_user = Factory.insert(:user)
      {:ok, chat} = Chats.create_direct_chat(user.id, other_user.id)

      messages = Messages.list_messages(chat.nanoid)
      assert messages == []
    end
  end

  describe "list_recent_messages/2" do
    test "lists recent messages for a chat" do
      user = Factory.insert(:user)
      other_user = Factory.insert(:user)
      {:ok, chat} = Chats.create_direct_chat(user.id, other_user.id)

      # Create some messages
      Factory.insert_list(5, :message, chat: chat, user: user)

      messages = Messages.list_recent_messages(chat.nanoid, 3)
      assert length(messages) == 3
    end
  end

  describe "get_last_message/1" do
    test "returns last message for a chat" do
      user = Factory.insert(:user)
      other_user = Factory.insert(:user)
      {:ok, chat} = Chats.create_direct_chat(user.id, other_user.id)

      # Create messages with explicit timestamps to ensure ordering
      now = NaiveDateTime.utc_now()

      Factory.insert(:message,
        chat: chat,
        user: user,
        content: "First message",
        inserted_at: now,
        updated_at: now
      )

      last_message =
        Factory.insert(:message,
          chat: chat,
          user: user,
          content: "Last message",
          inserted_at: NaiveDateTime.add(now, 1, :second),
          updated_at: NaiveDateTime.add(now, 1, :second)
        )

      result = Messages.get_last_message(chat.id)
      assert result.id == last_message.id
      assert result.content == "Last message"
    end

    test "returns nil for chat with no messages" do
      user = Factory.insert(:user)
      other_user = Factory.insert(:user)
      {:ok, chat} = Chats.create_direct_chat(user.id, other_user.id)

      assert Messages.get_last_message(chat.id) == nil
    end
  end

  describe "get_message_count/1" do
    test "returns message count for a chat" do
      user = Factory.insert(:user)
      other_user = Factory.insert(:user)
      {:ok, chat} = Chats.create_direct_chat(user.id, other_user.id)

      # Create messages
      Factory.insert_list(3, :message, chat: chat, user: user)

      count = Messages.get_message_count(chat.id)
      assert count == 3
    end

    test "returns 0 for chat with no messages" do
      user = Factory.insert(:user)
      other_user = Factory.insert(:user)
      {:ok, chat} = Chats.create_direct_chat(user.id, other_user.id)

      count = Messages.get_message_count(chat.id)
      assert count == 0
    end
  end

  describe "create_message/1" do
    test "creates message with valid attributes" do
      user = Factory.insert(:user)
      chat = Factory.insert(:chat)
      Factory.insert(:chat_member, user: user, chat: chat)

      attrs = %{
        content: "Test message",
        chat_id: chat.id,
        user_id: user.id
      }

      assert {:ok, %MessageModel{} = message} = Messages.create_message(attrs)
      assert message.content == "Test message"
      assert message.chat_id == chat.id
      assert message.user_id == user.id
    end

    test "returns error with invalid attributes" do
      attrs = %{content: ""}

      assert {:error, %Ecto.Changeset{}} = Messages.create_message(attrs)
    end
  end
end
