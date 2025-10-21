defmodule Server.Models.UserModel do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Query
  import Ecto.Changeset

  @required [:email, :username, :first_name, :last_name, :state]
  @optional [:password]

  @states [:active, :inactive]

  schema "users" do
    field :email, :string
    field :username, :string
    field :first_name, :string
    field :last_name, :string
    field :state, Ecto.Enum, values: @states
    field :password_hash, :string
    field :password, :string, virtual: true

    # Associations
    has_many :chat_members, Server.Models.ChatMemberModel, foreign_key: :user_id
    has_many :chats, through: [:chat_members, :chat]
    has_many :messages, Server.Models.MessageModel, foreign_key: :user_id

    timestamps()
  end

  @doc """
  Base query for users
  """
  def base_query do
    from(users in __MODULE__, as: :user)
  end

  @doc """
  Changeset for a user
  """
  def changeset(%__MODULE__{} = user, attrs) do
    user
    |> cast(attrs, @required)
    |> validate_required(@required)
    |> unique_constraint(:email)
    |> unique_constraint(:username)
  end

  @doc """
  Changeset for user registration with password hashing
  """
  def registration_changeset(%__MODULE__{} = user, attrs) do
    user
    |> cast(attrs, @required ++ @optional)
    |> validate_required(@required ++ @optional)
    |> validate_length(:password, min: 8, max: 100)
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+\.[^\s]+$/, message: "must be a valid email")
    |> validate_format(:username, ~r/^[a-zA-Z0-9_]+$/, message: "must contain only letters, numbers, and underscores")
    |> validate_length(:username, min: 3, max: 20)
    |> unique_constraint(:email)
    |> unique_constraint(:username)
    |> hash_password()
  end

  @doc """
  Changeset for password updates
  """
  def password_changeset(%__MODULE__{} = user, attrs) do
    user
    |> cast(attrs, [:password])
    |> validate_required([:password])
    |> validate_length(:password, min: 8, max: 100)
    |> hash_password()
  end

  defp hash_password(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: password}} ->
        put_change(changeset, :password_hash, Argon2.hash_pwd_salt(password))
      _ ->
        changeset
    end
  end
end
