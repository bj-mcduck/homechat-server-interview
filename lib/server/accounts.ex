defmodule Server.Accounts do
  @moduledoc """
  The Accounts context for user management and authentication.
  """

  import Ecto.Query, warn: false
  alias Server.Repo
  alias Server.Models.UserModel
  alias Server.Guardian

  @doc """
  Returns the list of users.
  """
  def list_users do
    Repo.all(UserModel)
  end

  @doc """
  Gets a single user.
  """
  def get_user!(id), do: Repo.get!(UserModel, id)

  @doc """
  Gets a single user by id.
  """
  def get_user(id), do: Repo.get(UserModel, id)

  @doc """
  Gets a user by email.
  """
  def get_user_by_email(email) do
    Repo.get_by(UserModel, email: email)
  end

  @doc """
  Gets a user by username.
  """
  def get_user_by_username(username) do
    Repo.get_by(UserModel, username: username)
  end

  @doc """
  Creates a user.
  
  Defaults to :active state. The state field is used for account lifecycle:
  - :active - User can login and use the system
  - :inactive - Soft delete (account deactivated/suspended)
  """
  def create_user(attrs \\ %{}) do
    # Default new users to active state
    attrs = Map.put_new(attrs, :state, :active)
    
    %UserModel{}
    |> UserModel.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a user.
  """
  def update_user(%UserModel{} = user, attrs) do
    user
    |> UserModel.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a user.
  """
  def delete_user(%UserModel{} = user) do
    Repo.delete(user)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.
  """
  def change_user(%UserModel{} = user, attrs \\ %{}) do
    UserModel.changeset(user, attrs)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user registration changes.
  """
  def change_registration(%UserModel{} = user, attrs \\ %{}) do
    UserModel.registration_changeset(user, attrs)
  end

  @doc """
  Authenticates a user with email and password.
  """
  def authenticate_user(email, password) do
    user = get_user_by_email(email)

    case user do
      nil ->
        {:error, :invalid_credentials}

      user ->
        if Argon2.verify_pass(password, user.password_hash) do
          {:ok, user}
        else
          {:error, :invalid_credentials}
        end
    end
  end

  @doc """
  Authenticates a user and returns a JWT token.
  """
  def authenticate_user_with_token(email, password) do
    case authenticate_user(email, password) do
      {:ok, user} ->
        case Guardian.generate_token(user) do
          {:ok, token} -> {:ok, user, token}
          error -> error
        end

      error ->
        error
    end
  end

  @doc """
  Search users by username, first name, or last name.
  """
  def search_users(query, current_user_id \\ nil) do
    search_term = "%#{String.downcase(query)}%"

    base_query =
      from(u in UserModel,
        where: u.state == :active,
        where: ilike(u.username, ^search_term) or
               ilike(u.first_name, ^search_term) or
               ilike(u.last_name, ^search_term)
      )

    # Exclude current user from search results
    query = if current_user_id do
      from(u in base_query, where: u.id != ^current_user_id)
    else
      base_query
    end

    Repo.all(query)
  end
end
