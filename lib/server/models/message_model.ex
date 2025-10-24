defmodule Server.Models.MessageModel do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Query
  import Ecto.Changeset

  @required [:content, :chat_id, :user_id]

  @nanoid_prefix "msg"

  schema "messages" do
    field :content, :string
    field :nanoid, :string

    belongs_to :chat, Server.Models.ChatModel
    belongs_to :user, Server.Models.UserModel

    timestamps()
  end

  @doc """
  Base query for messages
  """
  def base_query do
    from(messages in __MODULE__, as: :message)
  end

  @doc """
  Changeset for a message
  """
  def changeset(%__MODULE__{} = message, attrs) do
    message
    |> cast(attrs, @required)
    |> validate_required(@required)
    |> validate_length(:content, min: 1, max: 2000)
    |> put_nanoid()
  end

  @doc """
  Query for messages in a chat ordered by insertion time
  """
  def for_chat(query \\ base_query(), chat_id) do
    from(m in query,
      where: m.chat_id == ^chat_id
    )
  end

  @doc """
  Query for messages with pagination
  """
  def paginated(query \\ base_query(), chat_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)
    offset = Keyword.get(opts, :offset, 0)

    query
    |> for_chat(chat_id)
    |> order_by([m], desc: m.inserted_at)
    |> limit(^limit)
    |> offset(^offset)
  end

  @doc """
  Query for recent messages in a chat
  """
  def recent(query \\ base_query(), chat_id, limit \\ 20) do
    from(m in query,
      where: m.chat_id == ^chat_id,
      order_by: [desc: :inserted_at],
      limit: ^limit
    )
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
