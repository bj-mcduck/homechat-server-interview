defmodule Server.AccountsTest do
  use Server.DataCase, async: true

  alias Server.Accounts
  alias Server.Models.UserModel
  alias Server.Factory

  describe "create_user/1" do
    test "creates user with valid attributes" do
      attrs = %{
        email: "test@example.com",
        username: "testuser",
        password: "password123",
        first_name: "Test",
        last_name: "User",
        state: :active
      }

      assert {:ok, %UserModel{} = user} = Accounts.create_user(attrs)
      assert user.email == "test@example.com"
      assert user.username == "testuser"
      assert user.first_name == "Test"
      assert user.last_name == "User"
      assert user.state == :active
      assert user.password_hash
    end

    test "returns error with invalid attributes" do
      attrs = %{email: "invalid-email"}
      assert {:error, %Ecto.Changeset{}} = Accounts.create_user(attrs)
    end
  end

  describe "get_user/1" do
    test "returns user when id exists" do
      user = Factory.insert(:user)
      assert Accounts.get_user(user.id) == user
    end

    test "returns nil when id does not exist" do
      assert Accounts.get_user(999) == nil
    end
  end

  describe "get_user_by_email/1" do
    test "returns user when email exists" do
      user = Factory.insert(:user)
      assert Accounts.get_user_by_email(user.email) == user
    end

    test "returns nil when email does not exist" do
      assert Accounts.get_user_by_email("nonexistent@example.com") == nil
    end
  end

  describe "get_user_by_username/1" do
    test "returns user when username exists" do
      user = Factory.insert(:user)
      assert Accounts.get_user_by_username(user.username) == user
    end

    test "returns nil when username does not exist" do
      assert Accounts.get_user_by_username("nonexistent") == nil
    end
  end

  describe "authenticate_user/2" do
    test "returns user with valid credentials" do
      user = Factory.insert(:user, password_hash: Argon2.hash_pwd_salt("password123"))
      assert {:ok, ^user} = Accounts.authenticate_user(user.email, "password123")
    end

    test "returns error with invalid email" do
      assert {:error, :invalid_credentials} = Accounts.authenticate_user("nonexistent@example.com", "password123")
    end

    test "returns error with invalid password" do
      user = Factory.insert(:user, password_hash: Argon2.hash_pwd_salt("password123"))
      assert {:error, :invalid_credentials} = Accounts.authenticate_user(user.email, "wrongpassword")
    end
  end

  describe "authenticate_user_with_token/2" do
    test "returns user and token with valid credentials" do
      user = Factory.insert(:user, password_hash: Argon2.hash_pwd_salt("password123"))
      assert {:ok, ^user, token} = Accounts.authenticate_user_with_token(user.email, "password123")
      assert is_binary(token)
    end

    test "returns error with invalid credentials" do
      assert {:error, :invalid_credentials} = Accounts.authenticate_user_with_token("nonexistent@example.com", "password123")
    end
  end

  describe "search_users/2" do
    test "searches users by username" do
      user1 = Factory.insert(:user, username: "john_doe")
      user2 = Factory.insert(:user, username: "jane_smith")
      user3 = Factory.insert(:user, username: "bob_wilson")

      results = Accounts.search_users("john")
      assert length(results) == 1
      assert Enum.any?(results, &(&1.id == user1.id))
    end

    test "searches users by first name" do
      user1 = Factory.insert(:user, first_name: "John")
      user2 = Factory.insert(:user, first_name: "Jane")
      user3 = Factory.insert(:user, first_name: "Bob")

      results = Accounts.search_users("john")
      assert length(results) == 1
      assert Enum.any?(results, &(&1.id == user1.id))
    end

    test "searches users by last name" do
      user1 = Factory.insert(:user, last_name: "Doe")
      user2 = Factory.insert(:user, last_name: "Smith")
      user3 = Factory.insert(:user, last_name: "Wilson")

      results = Accounts.search_users("doe")
      assert length(results) == 1
      assert Enum.any?(results, &(&1.id == user1.id))
    end

    test "excludes current user from search results" do
      current_user = Factory.insert(:user, username: "current_user")
      other_user = Factory.insert(:user, username: "other_user")

      results = Accounts.search_users("user", current_user.id)
      assert length(results) == 1
      assert Enum.any?(results, &(&1.id == other_user.id))
      refute Enum.any?(results, &(&1.id == current_user.id))
    end

    test "returns empty list when no matches" do
      Factory.insert(:user, username: "john_doe")
      results = Accounts.search_users("nonexistent")
      assert results == []
    end
  end
end
