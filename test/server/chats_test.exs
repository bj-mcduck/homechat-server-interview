defmodule Server.ChatsTest do
  use Server.DataCase, async: true

  alias Server.Chats
  alias Server.Models.{ChatModel, ChatMemberModel}
  alias Server.Factory

  describe "create_direct_chat/2" do
    test "creates direct chat between two users" do
      user1 = Factory.insert(:user)
      user2 = Factory.insert(:user)

      assert {:ok, chat} = Chats.create_direct_chat(user1.id, user2.id)
      assert chat.private == true
      assert length(chat.members) == 2
      assert Enum.any?(chat.members, &(&1.id == user1.id))
      assert Enum.any?(chat.members, &(&1.id == user2.id))
    end

    test "returns existing direct chat if it already exists" do
      user1 = Factory.insert(:user)
      user2 = Factory.insert(:user)

      {:ok, chat1} = Chats.create_direct_chat(user1.id, user2.id)
      {:ok, chat2} = Chats.create_direct_chat(user1.id, user2.id)

      assert chat1.id == chat2.id
    end

    test "creates new direct chat if previous one was deleted" do
      user1 = Factory.insert(:user)
      user2 = Factory.insert(:user)

      {:ok, chat1} = Chats.create_direct_chat(user1.id, user2.id)
      Chats.delete_chat(chat1)

      {:ok, chat2} = Chats.create_direct_chat(user1.id, user2.id)
      assert chat1.id != chat2.id
    end
  end

  describe "create_group_chat/3" do
    test "creates group chat with members" do
      creator = Factory.insert(:user)
      members = Factory.insert_list(2, :user)
      attrs = %{name: "Test Group", private: true, state: :active}

      assert {:ok, chat} = Chats.create_group_chat(attrs, creator.id, Enum.map(members, & &1.id))
      assert chat.name == "Test Group"
      assert chat.private == true
      assert length(chat.members) == 3
      assert Enum.any?(chat.members, &(&1.id == creator.id))
    end

    test "returns error with invalid attributes" do
      creator = Factory.insert(:user)
      attrs = %{name: "", private: true, state: :active}

      assert {:error, %Ecto.Changeset{}} = Chats.create_group_chat(attrs, creator.id, [])
    end
  end

  describe "list_user_chats/1" do
    test "returns all chats for a user" do
      user = Factory.insert(:user)
      other_user = Factory.insert(:user)

      # Create direct chat
      {:ok, direct_chat} = Chats.create_direct_chat(user.id, other_user.id)

      # Create group chat
      members = Factory.insert_list(2, :user)
      {:ok, group_chat} = Chats.create_group_chat(%{name: "Group", private: true, state: :active}, user.id, Enum.map(members, & &1.id))

      chats = Chats.list_user_chats(user.id)
      assert length(chats) == 2
      assert Enum.any?(chats, &(&1.id == direct_chat.id))
      assert Enum.any?(chats, &(&1.id == group_chat.id))
    end

    test "returns empty list for user with no chats" do
      user = Factory.insert(:user)
      chats = Chats.list_user_chats(user.id)
      assert chats == []
    end
  end

  describe "list_public_chats/0" do
    test "returns only public chats" do
      Factory.insert(:chat, private: true)
      public_chat = Factory.insert(:chat, private: false)

      public_chats = Chats.list_public_chats()
      assert length(public_chats) == 1
      assert Enum.any?(public_chats, &(&1.id == public_chat.id))
    end
  end

  describe "list_discoverable_chats/1" do
    test "returns user's chats and public chats" do
      user = Factory.insert(:user)
      other_user = Factory.insert(:user)

      # User's direct chat
      {:ok, direct_chat} = Chats.create_direct_chat(user.id, other_user.id)

      # Public chat
      public_chat = Factory.insert(:chat, private: false)

      # Private chat user is not part of
      Factory.insert(:chat, private: true)

      discoverable_chats = Chats.list_discoverable_chats(user.id)
      assert length(discoverable_chats) == 2
      assert Enum.any?(discoverable_chats, &(&1.id == direct_chat.id))
      assert Enum.any?(discoverable_chats, &(&1.id == public_chat.id))
    end
  end

  describe "user_member_of_chat?/2" do
    test "returns true when user is member" do
      user = Factory.insert(:user)
      chat = Factory.insert(:chat)
      Factory.insert(:chat_member, user: user, chat: chat)

      assert Chats.user_member_of_chat?(user.id, chat.id)
    end

    test "returns false when user is not member" do
      user = Factory.insert(:user)
      chat = Factory.insert(:chat)

      refute Chats.user_member_of_chat?(user.id, chat.id)
    end
  end

  describe "add_chat_member/3" do
    test "adds member to chat" do
      user = Factory.insert(:user)
      chat = Factory.insert(:chat)

      assert {:ok, chat_member} = Chats.add_chat_member(chat.id, user.id)
      assert chat_member.user_id == user.id
      assert chat_member.chat_id == chat.id
      assert chat_member.role == :member
    end

    test "returns error when trying to add duplicate member" do
      user = Factory.insert(:user)
      chat = Factory.insert(:chat)
      Factory.insert(:chat_member, user: user, chat: chat)

      assert {:error, %Ecto.Changeset{}} = Chats.add_chat_member(chat.id, user.id)
    end
  end

  describe "remove_chat_member/2" do
    test "removes member from chat" do
      user = Factory.insert(:user)
      chat = Factory.insert(:chat)
      Factory.insert(:chat_member, user: user, chat: chat)

      assert :ok = Chats.remove_chat_member(chat.id, user.id)
      refute Chats.user_member_of_chat?(user.id, chat.id)
    end

    test "returns error when member not found" do
      user = Factory.insert(:user)
      chat = Factory.insert(:chat)

      assert {:error, :not_found} = Chats.remove_chat_member(chat.id, user.id)
    end
  end

  describe "update_chat_privacy/2" do
    test "updates chat privacy setting" do
      chat = Factory.insert(:chat, private: true)

      assert {:ok, updated_chat} = Chats.update_chat_privacy(chat, false)
      assert updated_chat.private == false
    end
  end
end
