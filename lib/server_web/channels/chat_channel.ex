defmodule ServerWeb.ChatChannel do
  @moduledoc """
  Phoenix Channel for real-time chat features.

  This channel handles:
  - Presence tracking (who's online)
  - Typing indicators
  - Legacy message handling (deprecated in favor of GraphQL subscriptions)

  Note: Primary real-time messaging is handled via GraphQL subscriptions
  for API consistency and type safety.
  """

  use Phoenix.Channel
  alias Server.{Chats, Messages}

  @impl true
  def join("chat:" <> chat_nanoid, _payload, socket) do
    user = socket.assigns.current_user

    case Chats.get_chat_id(chat_nanoid) do
      nil ->
        {:error, %{reason: "chat_not_found"}}
      chat_id ->
        case Chats.user_member_of_chat?(user.id, chat_id) do
          true -> {:ok, socket}
          false -> {:error, %{reason: "unauthorized"}}
        end
    end
  end

  @impl true
  def handle_in("new_message", %{"content" => content}, socket) do
    # DEPRECATED: Use GraphQL sendMessage mutation instead
    # This is kept for backward compatibility only
    user = socket.assigns.current_user
    chat_nanoid = get_chat_id_from_topic(socket.topic)

    case Messages.send_message(chat_nanoid, user.id, content) do
      {:ok, message} ->
        # Broadcast to all subscribers of this chat
        broadcast(socket, "new_message", %{
          id: message.nanoid,
          content: message.content,
          user_id: user.nanoid,
          inserted_at: message.inserted_at
        })

        {:noreply, socket}

      {:error, :forbidden} ->
        {:reply, {:error, %{reason: "unauthorized"}}, socket}

      {:error, :not_found} ->
        {:reply, {:error, %{reason: "chat_not_found"}}, socket}

      {:error, changeset} ->
        {:reply, {:error, %{reason: "validation_failed", errors: changeset.errors}}, socket}
    end
  end

  @impl true
  def handle_in("typing", %{"typing" => typing}, socket) do
    user = socket.assigns.current_user

    broadcast_from(socket, "user_typing", %{
      user_id: user.id,
      username: user.username,
      typing: typing
    })

    {:noreply, socket}
  end

  @impl true
  def handle_in("stop_typing", _payload, socket) do
    user = socket.assigns.current_user

    broadcast_from(socket, "user_stopped_typing", %{
      user_id: user.id,
      username: user.username
    })

    {:noreply, socket}
  end

  # Private functions

  defp get_chat_id_from_topic("chat:" <> chat_id), do: chat_id
  defp get_chat_id_from_topic(_), do: nil
end
