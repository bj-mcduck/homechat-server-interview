defmodule Server.Messages do
  @moduledoc """
  The Messages context for managing chat messages.
  """

  import Ecto.Query, warn: false
  alias Server.Repo
  alias Server.Models.MessageModel
  alias Server.Chats

  @doc """
  Returns the list of messages for a chat.
  """
  def list_messages(chat_id, opts \\ []) do
    MessageModel.paginated(chat_id, opts)
    |> Repo.all()
    |> Repo.preload(:user)
  end

  @doc """
  Returns recent messages for a chat.
  """
  def list_recent_messages(chat_id, limit \\ 20) do
    MessageModel.recent(chat_id, limit)
    |> Repo.all()
    |> Repo.preload(:user)
  end

  @doc """
  Gets a single message.
  """
  def get_message!(id), do: Repo.get!(MessageModel, id)

  @doc """
  Gets a single message by id.
  """
  def get_message(id), do: Repo.get(MessageModel, id)

  @doc """
  Creates a message.
  """
  def create_message(attrs \\ %{}) do
    %MessageModel{}
    |> MessageModel.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Sends a message to a chat (with permission check).
  """
  def send_message(chat_id, user_id, content) do
    # Check if user is a member of the chat
    unless Chats.user_member_of_chat?(user_id, chat_id) do
      {:error, :forbidden}
    else
      create_message(%{
        chat_id: chat_id,
        user_id: user_id,
        content: content
      })
    end
  end

  @doc """
  Updates a message.
  """
  def update_message(%MessageModel{} = message, attrs) do
    message
    |> MessageModel.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a message.
  """
  def delete_message(%MessageModel{} = message) do
    Repo.delete(message)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking message changes.
  """
  def change_message(%MessageModel{} = message, attrs \\ %{}) do
    MessageModel.changeset(message, attrs)
  end

  @doc """
  Gets the last message for a chat.
  """
  def get_last_message(chat_id) do
    from(m in MessageModel,
      where: m.chat_id == ^chat_id,
      order_by: [desc: :inserted_at],
      limit: 1,
      preload: :user
    )
    |> Repo.one()
  end

  @doc """
  Gets message count for a chat.
  """
  def get_message_count(chat_id) do
    from(m in MessageModel,
      where: m.chat_id == ^chat_id,
      select: count(m.id)
    )
    |> Repo.one()
  end
end
