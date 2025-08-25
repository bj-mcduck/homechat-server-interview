defmodule Server.Models.UserModel do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Query
  import Ecto.Changeset

  @required [:email, :first_name, :last_name, :state]

  @states [:active, :inactive]

  schema "users" do
    field :email, :string
    field :first_name, :string
    field :last_name, :string
    field :state, Ecto.Enum, values: @states

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
  end
end
