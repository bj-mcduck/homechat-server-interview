defmodule Server.Models.UserModelTest do
  use Server.DataCase, async: true

  alias Server.Models.UserModel
  alias Server.Factory

  describe "changeset/2" do
    test "valid changeset" do
      attrs = %{
        email: "test@example.com",
        username: "testuser",
        first_name: "Test",
        last_name: "User",
        state: :active
      }

      changeset = UserModel.changeset(%UserModel{}, attrs)
      assert changeset.valid?
    end

    test "requires all fields" do
      changeset = UserModel.changeset(%UserModel{}, %{})
      refute changeset.valid?

      assert %{
        email: ["can't be blank"],
        username: ["can't be blank"],
        first_name: ["can't be blank"],
        last_name: ["can't be blank"],
        state: ["can't be blank"]
      } = errors_on(changeset)
    end

    test "validates unique email" do
      user = Factory.insert(:user)
      attrs = %{
        email: user.email,
        username: "differentuser",
        first_name: "Test",
        last_name: "User",
        state: :active,
        password: "password123"
      }

      changeset = UserModel.registration_changeset(%UserModel{}, attrs)
      assert {:error, changeset} = Repo.insert(changeset)
      assert %{email: ["has already been taken"]} = errors_on(changeset)
    end

    test "validates unique username" do
      user = Factory.insert(:user)
      attrs = %{
        email: "different@example.com",
        username: user.username,
        first_name: "Test",
        last_name: "User",
        state: :active,
        password: "password123"
      }

      changeset = UserModel.registration_changeset(%UserModel{}, attrs)
      assert {:error, changeset} = Repo.insert(changeset)
      assert %{username: ["has already been taken"]} = errors_on(changeset)
    end
  end

  describe "registration_changeset/2" do
    test "valid registration changeset" do
      attrs = %{
        email: "test@example.com",
        username: "testuser",
        password: "password123",
        first_name: "Test",
        last_name: "User",
        state: :active
      }

      changeset = UserModel.registration_changeset(%UserModel{}, attrs)
      assert changeset.valid?
      assert changeset.changes.password_hash
    end

    test "validates password length" do
      attrs = %{
        email: "test@example.com",
        username: "testuser",
        password: "short",
        first_name: "Test",
        last_name: "User",
        state: :active
      }

      changeset = UserModel.registration_changeset(%UserModel{}, attrs)
      refute changeset.valid?
      assert %{password: ["should be at least 8 character(s)"]} = errors_on(changeset)
    end

    test "validates email format" do
      attrs = %{
        email: "invalid-email",
        username: "testuser",
        password: "password123",
        first_name: "Test",
        last_name: "User",
        state: :active
      }

      changeset = UserModel.registration_changeset(%UserModel{}, attrs)
      refute changeset.valid?
      assert %{email: ["must be a valid email"]} = errors_on(changeset)
    end

    test "validates username format" do
      attrs = %{
        email: "test@example.com",
        username: "invalid username!",
        password: "password123",
        first_name: "Test",
        last_name: "User",
        state: :active
      }

      changeset = UserModel.registration_changeset(%UserModel{}, attrs)
      refute changeset.valid?
      assert %{username: ["must contain only letters, numbers, and underscores"]} = errors_on(changeset)
    end

    test "validates username length" do
      attrs = %{
        email: "test@example.com",
        username: "ab",
        password: "password123",
        first_name: "Test",
        last_name: "User",
        state: :active
      }

      changeset = UserModel.registration_changeset(%UserModel{}, attrs)
      refute changeset.valid?
      assert %{username: ["should be at least 3 character(s)"]} = errors_on(changeset)
    end
  end

  describe "password_changeset/2" do
    test "valid password changeset" do
      user = Factory.insert(:user)
      attrs = %{password: "newpassword123"}

      changeset = UserModel.password_changeset(user, attrs)
      assert changeset.valid?
      assert changeset.changes.password_hash
    end

    test "validates password length" do
      user = Factory.insert(:user)
      attrs = %{password: "short"}

      changeset = UserModel.password_changeset(user, attrs)
      refute changeset.valid?
      assert %{password: ["should be at least 8 character(s)"]} = errors_on(changeset)
    end
  end
end
