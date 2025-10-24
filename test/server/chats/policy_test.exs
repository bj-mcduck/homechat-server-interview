defmodule Server.Chats.PolicyTest do
  use Server.DataCase, async: true

  alias Server.Chats.Policy
  alias Server.Models.{UserModel, ChatModel}
  alias Server.Factory

  describe "authorize/3 for :create_chat" do
    test "allows active users to create chats" do
      alice = Factory.insert(:user, state: :active)
      chat = Factory.insert(:chat)

      assert :ok = Policy.authorize(:create_chat, alice, chat)
    end

    test "denies inactive users from creating chats" do
      inactive_user = Factory.insert(:user, state: :inactive)
      chat = Factory.insert(:chat)

      assert {:error, :unauthorized} = Policy.authorize(:create_chat, inactive_user, chat)
    end
  end

  describe "authorize/3 for :view_chat" do
    test "allows members to view chat" do
      alice = Factory.insert(:user)
      bob = Factory.insert(:user)
      {:ok, chat} = Server.Chats.create_direct_chat(alice.id, bob.id)

      assert :ok = Policy.authorize(:view_chat, alice, chat)
    end

    test "denies non-members from viewing chat" do
      alice = Factory.insert(:user)
      bob = Factory.insert(:user)
      charlie = Factory.insert(:user)
      {:ok, chat} = Server.Chats.create_direct_chat(alice.id, bob.id)

      assert {:error, :not_a_member} = Policy.authorize(:view_chat, charlie, chat)
    end
  end

  describe "authorize/3 for :send_message" do
    test "allows members to send messages to active chats" do
      alice = Factory.insert(:user)
      bob = Factory.insert(:user)
      {:ok, chat} = Server.Chats.create_direct_chat(alice.id, bob.id)

      assert :ok = Policy.authorize(:send_message, alice, chat)
    end

    test "denies sending messages when chat is inactive" do
      alice = Factory.insert(:user)
      bob = Factory.insert(:user)
      {:ok, chat} = Server.Chats.create_direct_chat(alice.id, bob.id)
      inactive_chat = %{chat | state: :inactive}

      assert {:error, :chat_inactive} = Policy.authorize(:send_message, alice, inactive_chat)
    end

    test "denies sending messages when user is not a member" do
      alice = Factory.insert(:user)
      bob = Factory.insert(:user)
      charlie = Factory.insert(:user)
      {:ok, chat} = Server.Chats.create_direct_chat(alice.id, bob.id)

      assert {:error, :not_a_member} = Policy.authorize(:send_message, charlie, chat)
    end
  end

  describe "authorize/3 for :add_member" do
    test "allows members to add other members" do
      alice = Factory.insert(:user)
      bob = Factory.insert(:user)
      {:ok, chat} = Server.Chats.create_direct_chat(alice.id, bob.id)

      assert :ok = Policy.authorize(:add_member, alice, chat)
    end

    test "denies non-members from adding members" do
      alice = Factory.insert(:user)
      bob = Factory.insert(:user)
      charlie = Factory.insert(:user)
      {:ok, chat} = Server.Chats.create_direct_chat(alice.id, bob.id)

      assert {:error, :not_a_member} = Policy.authorize(:add_member, charlie, chat)
    end
  end

  describe "authorize/3 for :leave_chat" do
    test "allows members to leave named chats" do
      alice = Factory.insert(:user)
      bob = Factory.insert(:user)
      {:ok, chat} = Server.Chats.create_group_chat(%{name: "Test Group", private: true, state: :active}, alice.id, [bob.id])

      assert :ok = Policy.authorize(:leave_chat, alice, chat)
    end

    test "denies leaving direct messages when chat is unnamed" do
      alice = Factory.insert(:user)
      bob = Factory.insert(:user)
      {:ok, chat} = Server.Chats.create_direct_chat(alice.id, bob.id)

      assert {:error, :cannot_leave_unnamed_chat} = Policy.authorize(:leave_chat, alice, chat)
    end

    test "denies leaving chat when user is not a member" do
      alice = Factory.insert(:user)
      bob = Factory.insert(:user)
      charlie = Factory.insert(:user)
      {:ok, chat} = Server.Chats.create_group_chat(%{name: "Test Group", private: true, state: :active}, alice.id, [bob.id])

      assert {:error, :not_a_member} = Policy.authorize(:leave_chat, charlie, chat)
    end
  end

  describe "authorize/3 for :update_chat" do
    test "allows owners to update chat" do
      alice = Factory.insert(:user)
      bob = Factory.insert(:user)
      {:ok, chat} = Server.Chats.create_group_chat(%{name: "Test Group", private: true, state: :active}, alice.id, [bob.id])

      assert :ok = Policy.authorize(:update_chat, alice, chat)
    end

    test "denies members from updating chat" do
      alice = Factory.insert(:user)
      bob = Factory.insert(:user)
      {:ok, chat} = Server.Chats.create_group_chat(%{name: "Test Group", private: true, state: :active}, alice.id, [bob.id])

      assert {:error, :not_owner} = Policy.authorize(:update_chat, bob, chat)
    end

    test "denies non-members from updating chat" do
      alice = Factory.insert(:user)
      bob = Factory.insert(:user)
      charlie = Factory.insert(:user)
      {:ok, chat} = Server.Chats.create_group_chat(%{name: "Test Group", private: true, state: :active}, alice.id, [bob.id])

      assert {:error, :not_a_member} = Policy.authorize(:update_chat, charlie, chat)
    end
  end

  describe "authorize/3 for :delete_chat" do
    test "allows owners to delete chat" do
      alice = Factory.insert(:user)
      bob = Factory.insert(:user)
      {:ok, chat} = Server.Chats.create_group_chat(%{name: "Test Group", private: true, state: :active}, alice.id, [bob.id])

      assert :ok = Policy.authorize(:delete_chat, alice, chat)
    end

    test "denies members from deleting chat" do
      alice = Factory.insert(:user)
      bob = Factory.insert(:user)
      {:ok, chat} = Server.Chats.create_group_chat(%{name: "Test Group", private: true, state: :active}, alice.id, [bob.id])

      assert {:error, :not_owner} = Policy.authorize(:delete_chat, bob, chat)
    end

    test "denies non-members from deleting chat" do
      alice = Factory.insert(:user)
      bob = Factory.insert(:user)
      charlie = Factory.insert(:user)
      {:ok, chat} = Server.Chats.create_group_chat(%{name: "Test Group", private: true, state: :active}, alice.id, [bob.id])

      assert {:error, :not_a_member} = Policy.authorize(:delete_chat, charlie, chat)
    end
  end

  describe "authorize/3 for :update_privacy" do
    test "allows owners to update privacy" do
      alice = Factory.insert(:user)
      bob = Factory.insert(:user)
      {:ok, chat} = Server.Chats.create_group_chat(%{name: "Test Group", private: true, state: :active}, alice.id, [bob.id])

      assert :ok = Policy.authorize(:update_privacy, alice, chat)
    end

    test "denies members from updating privacy" do
      alice = Factory.insert(:user)
      bob = Factory.insert(:user)
      {:ok, chat} = Server.Chats.create_group_chat(%{name: "Test Group", private: true, state: :active}, alice.id, [bob.id])

      assert {:error, :not_owner} = Policy.authorize(:update_privacy, bob, chat)
    end

    test "denies non-members from updating privacy" do
      alice = Factory.insert(:user)
      bob = Factory.insert(:user)
      charlie = Factory.insert(:user)
      {:ok, chat} = Server.Chats.create_group_chat(%{name: "Test Group", private: true, state: :active}, alice.id, [bob.id])

      assert {:error, :not_a_member} = Policy.authorize(:update_privacy, charlie, chat)
    end
  end

  describe "authorize/3 for unknown actions" do
    test "denies unknown actions" do
      alice = Factory.insert(:user)
      chat = Factory.insert(:chat)

      assert {:error, :unauthorized} = Policy.authorize(:unknown_action, alice, chat)
    end
  end
end
