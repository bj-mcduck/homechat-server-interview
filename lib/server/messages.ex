defmodule Server.Messages do
  @moduledoc """
  The Messages context for managing chat messages.
  """

  import Ecto.Query, warn: false
  alias Server.Repo
  alias Server.Models.MessageModel
  alias Server.Chats

  @doc """
  Returns the list of messages for a chat with cursor-based pagination.
  Messages are returned in DESC order (newest first) and should be reversed for display.
  """
  def list_messages(chat_nanoid, opts \\ []) do
    case Chats.get_chat_id(chat_nanoid) do
      nil ->
        []

      chat_id ->
        MessageModel.cursor_paginated(MessageModel.base_query(), chat_id, opts)
        |> Repo.all()
        |> Enum.reverse()  # Reverse to ASC (oldest first) for display
    end
  end

  @doc """
  Returns recent messages for a chat by nanoid.
  """
  def list_recent_messages(chat_nanoid, limit \\ 20) do
    case Chats.get_chat_id(chat_nanoid) do
      nil ->
        []

      chat_id ->
        MessageModel.recent(MessageModel.base_query(), chat_id, limit)
        |> Repo.all()
    end
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
  Sends a message to a chat by nanoid (with permission check).
  """
  def send_message(chat_nanoid, user_id, content) do
    with {:ok, chat} <- get_chat_or_error(chat_nanoid),
         :ok <- validate_chat_active(chat),
         :ok <- validate_user_membership(user_id, chat.id),
         {:ok, message} <- create_message(%{chat_id: chat.id, user_id: user_id, content: content}) do
      {:ok, Repo.preload(message, [:user, :chat])}
    end
  end

  defp get_chat_or_error(chat_nanoid) do
    case Chats.get_chat(chat_nanoid) do
      nil -> {:error, :not_found}
      chat -> {:ok, chat}
    end
  end

  defp validate_chat_active(%{state: :active}), do: :ok
  defp validate_chat_active(_chat), do: {:error, :chat_inactive}

  defp validate_user_membership(user_id, chat_id) do
    if Chats.user_member_of_chat?(user_id, chat_id) do
      :ok
    else
      {:error, :forbidden}
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
