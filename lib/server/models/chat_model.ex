defmodule Server.Models.ChatModel do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Query
  import Ecto.Changeset

  @required [:state]
  @optional [:name, :private]

  @states [:active, :inactive]
  @nanoid_prefix "cht"

  schema "chats" do
    field :state, Ecto.Enum, values: @states
    field :name, :string
    field :private, :boolean, default: true
    field :nanoid, :string

    # Associations
    has_many :chat_members, Server.Models.ChatMemberModel, foreign_key: :chat_id
    has_many :members, through: [:chat_members, :user]
    has_many :messages, Server.Models.MessageModel, foreign_key: :chat_id

    timestamps()
  end

  @doc """
  Base query for chats
  """
  def base_query do
    from(chats in __MODULE__, as: :chat)
  end

  @doc """
  Changeset for a chat
  """
  def changeset(%__MODULE__{} = chat, attrs) do
    chat
    |> cast(attrs, @required ++ @optional)
    |> validate_required(@required)
    |> validate_length(:name, max: 100)
    |> put_nanoid()
  end

  @doc """
  Changeset for creating a direct chat
  """
  def direct_chat_changeset(%__MODULE__{} = chat, attrs) do
    chat
    |> cast(attrs, @required)
    |> validate_required(@required)
    |> put_change(:private, true)
  end

  @doc """
  Changeset for creating a group chat
  """
  def group_chat_changeset(%__MODULE__{} = chat, attrs) do
    chat
    |> cast(attrs, @required ++ [:name, :private])
    |> validate_required(@required ++ [:name])
    |> validate_length(:name, min: 1, max: 100)
  end

  @doc """
  Check if a chat is a direct message (2 members)
  """
  def direct?(%__MODULE__{} = chat) do
    case Ecto.assoc_loaded?(chat.members) do
      true -> length(chat.members) == 2
      false -> false
    end
  end

  @doc """
  Get the other user in a direct chat
  """
  def other_user(%__MODULE__{} = chat, current_user_id) do
    case Ecto.assoc_loaded?(chat.members) do
      true ->
        chat.members
        |> Enum.reject(&(&1.id == current_user_id))
        |> List.first()

      false ->
        nil
    end
  end

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
