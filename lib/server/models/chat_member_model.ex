defmodule Server.Models.ChatMemberModel do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Query
  import Ecto.Changeset

  @required [:chat_id, :user_id, :role]

  @roles [:owner, :admin, :member]
  @nanoid_prefix "mbr"

  schema "chat_members" do
    field :role, Ecto.Enum, values: @roles, default: :member
    field :nanoid, :string

    belongs_to :chat, Server.Models.ChatModel
    belongs_to :user, Server.Models.UserModel

    timestamps()
  end

  @doc """
  Base query for chat members
  """
  def base_query do
    from(chat_members in __MODULE__, as: :chat_member)
  end

  @doc """
  Changeset for a chat member
  """
  def changeset(%__MODULE__{} = chat_member, attrs) do
    chat_member
    |> cast(attrs, @required)
    |> validate_required(@required)
    |> unique_constraint([:chat_id, :user_id])
    |> put_nanoid()
  end

  @doc """
  Changeset for creating a chat member
  """
  def create_changeset(%__MODULE__{} = chat_member, attrs) do
    chat_member
    |> cast(attrs, @required)
    |> validate_required(@required)
    |> unique_constraint([:chat_id, :user_id])
  end

  @doc """
  Check if user is owner of the chat
  """
  def owner?(%__MODULE__{role: :owner}), do: true
  def owner?(_), do: false

  @doc """
  Check if user is admin or owner of the chat
  """
  def admin_or_owner?(%__MODULE__{role: role}) when role in [:admin, :owner], do: true
  def admin_or_owner?(_), do: false

  defp put_nanoid(changeset) do
    case get_field(changeset, :nanoid) do
      nil -> put_change(changeset, :nanoid, generate_nanoid())
      _ -> changeset
    end
  end

  defp generate_nanoid do
    "#{@nanoid_prefix}_#{Nanoid.generate(10)}"
  end
end
