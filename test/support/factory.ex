defmodule Server.Factory do
  @moduledoc """
  Factory for creating test data using ExMachina.
  """

  use ExMachina.Ecto, repo: Server.Repo

  alias Server.Models.{UserModel, ChatModel, ChatMemberModel, MessageModel}

  def user_factory do
    %UserModel{
      email: sequence(:email, &"user#{&1}@example.com"),
      username: sequence(:username, &"user#{&1}"),
      first_name: "John",
      last_name: "Doe",
      password_hash: Argon2.hash_pwd_salt("password123"),
      state: :active
    }
  end

  def chat_factory do
    %ChatModel{
      name: sequence(:name, &"Chat #{&1}"),
      private: true,
      state: :active
    }
  end

  def chat_member_factory do
    %ChatMemberModel{
      role: :member
    }
  end

  def message_factory do
    %MessageModel{
      content: sequence(:content, &"Message content #{&1}")
    }
  end

  def direct_chat_factory do
    %ChatModel{
      name: nil,
      private: true,
      state: :active
    }
  end

  def group_chat_factory do
    %ChatModel{
      name: sequence(:name, &"Group Chat #{&1}"),
      private: true,
      state: :active
    }
  end

  def public_chat_factory do
    %ChatModel{
      name: sequence(:name, &"Public Chat #{&1}"),
      private: false,
      state: :active
    }
  end

  # Helper functions for creating related data

  def create_direct_chat_with_members(user1, user2) do
    chat = insert(:direct_chat)
    insert(:chat_member, chat: chat, user: user1, role: :owner)
    insert(:chat_member, chat: chat, user: user2, role: :member)
    chat
  end

  def create_group_chat_with_members(creator, members) do
    chat = insert(:group_chat)
    insert(:chat_member, chat: chat, user: creator, role: :owner)
    
    Enum.each(members, fn member ->
      insert(:chat_member, chat: chat, user: member, role: :member)
    end)
    
    chat
  end

  def create_message_in_chat(chat, user, content \\ nil) do
    content = content || sequence(:content, &"Message #{&1}")
    insert(:message, chat: chat, user: user, content: content)
  end
end
