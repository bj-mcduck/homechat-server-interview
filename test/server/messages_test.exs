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

      assert {:ok, message} = Messages.send_message(chat.id, user.id, "Hello!")
      assert message.content == "Hello!"
      assert message.user_id == user.id
      assert message.chat_id == chat.id
    end

    test "returns error when user is not member of chat" do
      user = Factory.insert(:user)
      chat = Factory.insert(:chat)

      assert {:error, :forbidden} = Messages.send_message(chat.id, user.id, "Hello!")
    end
  end

  describe "list_messages/2" do
    test "lists messages for a chat with pagination" do
      user = Factory.insert(:user)
      other_user = Factory.insert(:user)
      {:ok, chat} = Chats.create_direct_chat(user.id, other_user.id)

      # Create some messages
      Factory.insert_list(5, :message, chat: chat, user: user)

      messages = Messages.list_messages(chat.id, limit: 3, offset: 0)
      assert length(messages) == 3
    end

    test "returns empty list for chat with no messages" do
      user = Factory.insert(:user)
      other_user = Factory.insert(:user)
      {:ok, chat} = Chats.create_direct_chat(user.id, other_user.id)

      messages = Messages.list_messages(chat.id)
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

      messages = Messages.list_recent_messages(chat.id, 3)
      assert length(messages) == 3
    end
  end

  describe "get_last_message/1" do
    test "returns last message for a chat" do
      user = Factory.insert(:user)
      other_user = Factory.insert(:user)
      {:ok, chat} = Chats.create_direct_chat(user.id, other_user.id)

      # Create messages
      Factory.insert(:message, chat: chat, user: user, content: "First message")
      last_message = Factory.insert(:message, chat: chat, user: user, content: "Last message")

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
