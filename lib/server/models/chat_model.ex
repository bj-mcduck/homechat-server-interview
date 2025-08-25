defmodule Server.Models.ChatModel do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Query
  import Ecto.Changeset

  @required [:state]

  @states [:active, :inactive]

  schema "chats" do
    field :state, Ecto.Enum, values: @states

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
    |> cast(attrs, @required)
    |> validate_required(@required)
  end
end
