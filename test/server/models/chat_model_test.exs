defmodule Server.Models.ChatModelTest do
  use Server.DataCase, async: true

  alias Server.Models.ChatModel
  alias Server.Factory

  describe "changeset/2" do
    test "valid changeset" do
      attrs = %{
        state: :active,
        name: "Test Chat",
        private: true
      }

      changeset = ChatModel.changeset(%ChatModel{}, attrs)
      assert changeset.valid?
    end

    test "requires state" do
      changeset = ChatModel.changeset(%ChatModel{}, %{})
      refute changeset.valid?
      assert %{state: ["can't be blank"]} = errors_on(changeset)
    end

    test "validates name length" do
      attrs = %{
        state: :active,
        name: String.duplicate("a", 101)
      }

      changeset = ChatModel.changeset(%ChatModel{}, attrs)
      refute changeset.valid?
      assert %{name: ["should be at most 100 character(s)"]} = errors_on(changeset)
    end
  end

  describe "direct_chat_changeset/2" do
    test "valid direct chat changeset" do
      attrs = %{state: :active}

      changeset = ChatModel.direct_chat_changeset(%ChatModel{}, attrs)
      assert changeset.valid?
      assert changeset.changes.private == true
    end
  end

  describe "group_chat_changeset/2" do
    test "valid group chat changeset" do
      attrs = %{
        state: :active,
        name: "Group Chat",
        private: true
      }

      changeset = ChatModel.group_chat_changeset(%ChatModel{}, attrs)
      assert changeset.valid?
    end

    test "requires name for group chat" do
      attrs = %{state: :active}

      changeset = ChatModel.group_chat_changeset(%ChatModel{}, attrs)
      refute changeset.valid?
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end

    test "validates name length for group chat" do
      attrs = %{
        state: :active,
        name: String.duplicate("a", 101)
      }

      changeset = ChatModel.group_chat_changeset(%ChatModel{}, attrs)
      refute changeset.valid?
      assert %{name: ["should be at most 100 character(s)"]} = errors_on(changeset)
    end
  end

  describe "direct?/1" do
    test "returns true for direct chat" do
      user1 = Factory.insert(:user)
      user2 = Factory.insert(:user)
      chat = Factory.create_direct_chat_with_members(user1, user2)

      # Preload members
      chat = Repo.preload(chat, :members)
      assert ChatModel.direct?(chat)
    end

    test "returns false for group chat" do
      creator = Factory.insert(:user)
      members = Factory.insert_list(2, :user)
      chat = Factory.create_group_chat_with_members(creator, members)

      # Preload members
      chat = Repo.preload(chat, :members)
      refute ChatModel.direct?(chat)
    end

    test "returns false when members not loaded" do
      chat = Factory.insert(:chat)
      refute ChatModel.direct?(chat)
    end
  end

  describe "other_user/2" do
    test "returns other user in direct chat" do
      user1 = Factory.insert(:user)
      user2 = Factory.insert(:user)
      chat = Factory.create_direct_chat_with_members(user1, user2)

      # Preload members
      chat = Repo.preload(chat, :members)
      other_user = ChatModel.other_user(chat, user1.id)
      assert other_user.id == user2.id
    end

    test "returns nil when members not loaded" do
      chat = Factory.insert(:chat)
      assert ChatModel.other_user(chat, 1) == nil
    end
  end
end
