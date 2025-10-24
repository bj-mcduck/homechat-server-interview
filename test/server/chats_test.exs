defmodule Server.ChatsTest do
  use Server.DataCase, async: true

  alias Server.Chats
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
      alice = Factory.insert(:user)
      bob = Factory.insert(:user)

      {:ok, first_chat} = Chats.create_direct_chat(alice.id, bob.id)
      {:ok, second_chat} = Chats.create_direct_chat(alice.id, bob.id)

      assert first_chat.id == second_chat.id
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
      attrs = %{name: "Valid Name", private: true}  # Missing required :state field

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

  describe "add_chat_members/3" do
    test "adds member to chat" do
      user = Factory.insert(:user)
      chat = Factory.insert(:chat)

      assert {:ok, chat_members} = Chats.add_chat_members(chat.id, [user.id])
      assert length(chat_members) == 1
      [chat_member] = chat_members
      assert chat_member.user_id == user.id
      assert chat_member.chat_id == chat.id
      assert chat_member.role == :member
    end

    test "returns error when trying to add duplicate member" do
      user = Factory.insert(:user)
      chat = Factory.insert(:chat)
      Factory.insert(:chat_member, user: user, chat: chat)

      assert {:error, _} = Chats.add_chat_members(chat.id, [user.id])
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

  describe "leave_chat/2" do
    test "removes member from named chat" do
      alice = Factory.insert(:user, username: "alice")
      bob = Factory.insert(:user, username: "bob")
      {:ok, chat} = Chats.create_group_chat(
        %{name: "Test Group", private: true, state: :active},
        alice.id,
        [bob.id]
      )

      assert {:ok, updated_chat} = Chats.leave_chat(chat.nanoid, alice.id)
      assert updated_chat.id == chat.id
      refute Chats.user_member_of_chat?(alice.id, chat.id)
    end

    test "returns chat after successful leave" do
      alice = Factory.insert(:user, username: "alice")
      bob = Factory.insert(:user, username: "bob")
      {:ok, chat} = Chats.create_group_chat(
        %{name: "Test Group", private: true, state: :active},
        alice.id,
        [bob.id]
      )

      assert {:ok, result_chat} = Chats.leave_chat(chat.nanoid, alice.id)
      assert result_chat.id == chat.id
    end

    test "returns error when chat is unnamed" do
      alice = Factory.insert(:user, username: "alice")
      bob = Factory.insert(:user, username: "bob")
      {:ok, chat} = Chats.create_direct_chat(alice.id, bob.id)

      assert {:error, :cannot_leave_unnamed_chat} = Chats.leave_chat(chat.nanoid, alice.id)
    end

    test "returns not found error when chat does not exist" do
      alice = Factory.insert(:user, username: "alice")

      assert {:error, :not_found} = Chats.leave_chat("nonexistent_nanoid", alice.id)
    end

    test "returns not found error when user is not a member" do
      alice = Factory.insert(:user, username: "alice")
      bob = Factory.insert(:user, username: "bob")
      charlie = Factory.insert(:user, username: "charlie")
      {:ok, chat} = Chats.create_group_chat(
        %{name: "Test Group", private: true, state: :active},
        alice.id,
        [bob.id]
      )

      assert {:error, :not_found} = Chats.leave_chat(chat.nanoid, charlie.id)
    end
  end

  describe "create_or_find_group_chat/2" do
    test "creates new unnamed group with participants" do
      alice = Factory.insert(:user, username: "alice")
      bob = Factory.insert(:user, username: "bob")
      charlie = Factory.insert(:user, username: "charlie")

      assert {:ok, chat} = Chats.create_or_find_group_chat(alice.id, [bob.id, charlie.id])
      assert chat.name == nil
      assert chat.private == true
      assert length(chat.members) == 3
      assert Enum.any?(chat.members, &(&1.id == alice.id))
      assert Enum.any?(chat.members, &(&1.id == bob.id))
      assert Enum.any?(chat.members, &(&1.id == charlie.id))
    end

    test "returns existing unnamed group with same participants" do
      alice = Factory.insert(:user, username: "alice")
      bob = Factory.insert(:user, username: "bob")
      charlie = Factory.insert(:user, username: "charlie")

      # Create first group
      {:ok, first_chat} = Chats.create_or_find_group_chat(alice.id, [bob.id, charlie.id])

      # Try to create same group again
      {:ok, second_chat} = Chats.create_or_find_group_chat(alice.id, [bob.id, charlie.id])

      assert first_chat.id == second_chat.id
    end

    test "creates new group if participant set differs" do
      alice = Factory.insert(:user, username: "alice")
      bob = Factory.insert(:user, username: "bob")
      charlie = Factory.insert(:user, username: "charlie")
      dave = Factory.insert(:user, username: "dave")

      # Create first group
      {:ok, first_chat} = Chats.create_or_find_group_chat(alice.id, [bob.id, charlie.id])

      # Create group with different participants
      {:ok, second_chat} = Chats.create_or_find_group_chat(alice.id, [bob.id, dave.id])

      assert first_chat.id != second_chat.id
    end

    test "creates new group when existing group was deleted" do
      alice = Factory.insert(:user, username: "alice")
      bob = Factory.insert(:user, username: "bob")
      charlie = Factory.insert(:user, username: "charlie")

      # Create and delete group
      {:ok, first_chat} = Chats.create_or_find_group_chat(alice.id, [bob.id, charlie.id])
      Chats.delete_chat(first_chat)

      # Create new group with same participants
      {:ok, second_chat} = Chats.create_or_find_group_chat(alice.id, [bob.id, charlie.id])

      assert first_chat.id != second_chat.id
    end
  end

  describe "when chat becomes inactive" do
    test "excludes from discoverable chats" do
      alice = Factory.insert(:user, username: "alice")
      bob = Factory.insert(:user, username: "bob")
      {:ok, chat} = Chats.create_direct_chat(alice.id, bob.id)

      # Initially chat is discoverable
      discoverable_chats = Chats.list_discoverable_chats(alice.id)
      assert Enum.any?(discoverable_chats, &(&1.id == chat.id))

      # Make chat inactive
      Chats.update_chat(chat, %{state: :inactive})

      # Chat should no longer be discoverable
      discoverable_chats = Chats.list_discoverable_chats(alice.id)
      refute Enum.any?(discoverable_chats, &(&1.id == chat.id))
    end

    test "prevents sending messages" do
      alice = Factory.insert(:user, username: "alice")
      bob = Factory.insert(:user, username: "bob")
      {:ok, chat} = Chats.create_direct_chat(alice.id, bob.id)

      # Make chat inactive
      Chats.update_chat(chat, %{state: :inactive})

      # Should not be able to send messages
      assert {:error, :chat_inactive} = Server.Messages.send_message(chat.nanoid, alice.id, "Hello!")
    end

    test "still allows viewing by members" do
      alice = Factory.insert(:user, username: "alice")
      bob = Factory.insert(:user, username: "bob")
      {:ok, chat} = Chats.create_direct_chat(alice.id, bob.id)

      # Make chat inactive
      Chats.update_chat(chat, %{state: :inactive})

      # Members should still be able to view the chat
      assert Chats.user_member_of_chat?(alice.id, chat.id)
      assert Chats.user_member_of_chat?(bob.id, chat.id)
    end
  end

  describe "chat member roles" do
    test "owner can update chat settings" do
      alice = Factory.insert(:user, username: "alice")
      bob = Factory.insert(:user, username: "bob")
      {:ok, chat} = Chats.create_group_chat(
        %{name: "Test Group", private: true, state: :active},
        alice.id,
        [bob.id]
      )

      # Alice (owner) should be able to update
      assert :ok = Server.Chats.Policy.authorize(:update_chat, alice, chat)
    end

    test "owner can delete chat" do
      alice = Factory.insert(:user, username: "alice")
      bob = Factory.insert(:user, username: "bob")
      {:ok, chat} = Chats.create_group_chat(
        %{name: "Test Group", private: true, state: :active},
        alice.id,
        [bob.id]
      )

      # Alice (owner) should be able to delete
      assert :ok = Server.Chats.Policy.authorize(:delete_chat, alice, chat)
    end

    test "member cannot update chat settings" do
      alice = Factory.insert(:user, username: "alice")
      bob = Factory.insert(:user, username: "bob")
      {:ok, chat} = Chats.create_group_chat(
        %{name: "Test Group", private: true, state: :active},
        alice.id,
        [bob.id]
      )

      # Bob (member) should not be able to update
      assert {:error, :not_owner} = Server.Chats.Policy.authorize(:update_chat, bob, chat)
    end

    test "member cannot delete chat" do
      alice = Factory.insert(:user, username: "alice")
      bob = Factory.insert(:user, username: "bob")
      {:ok, chat} = Chats.create_group_chat(
        %{name: "Test Group", private: true, state: :active},
        alice.id,
        [bob.id]
      )

      # Bob (member) should not be able to delete
      assert {:error, :not_owner} = Server.Chats.Policy.authorize(:delete_chat, bob, chat)
    end
  end

  describe "create_chat with duplicate name" do
    test "returns error when name is taken" do
      alice = Factory.insert(:user, username: "alice")
      bob = Factory.insert(:user, username: "bob")
      charlie = Factory.insert(:user, username: "charlie")

      # Create first chat with name
      {:ok, _first_chat} = Chats.create_group_chat(
        %{name: "Unique Name", private: true, state: :active},
        alice.id,
        [bob.id]
      )

      # Try to create another chat with same name
      assert {:error, :name_taken} = Chats.create_group_chat(
        %{name: "Unique Name", private: true, state: :active},
        charlie.id,
        [alice.id]
      )
    end

    test "allows same name after original is deleted" do
      alice = Factory.insert(:user, username: "alice")
      bob = Factory.insert(:user, username: "bob")
      charlie = Factory.insert(:user, username: "charlie")

      # Create and delete chat
      {:ok, first_chat} = Chats.create_group_chat(
        %{name: "Reusable Name", private: true, state: :active},
        alice.id,
        [bob.id]
      )
      Chats.delete_chat(first_chat)

      # Should be able to create new chat with same name
      assert {:ok, _second_chat} = Chats.create_group_chat(
        %{name: "Reusable Name", private: true, state: :active},
        charlie.id,
        [alice.id]
      )
    end
  end
end
