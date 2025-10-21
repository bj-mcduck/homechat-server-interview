defmodule ServerWeb.ChatChannel do
  @moduledoc """
  Channel for real-time chat communication.
  """

  use Phoenix.Channel
  alias Server.{Chats, Messages}

  @impl true
  def join("chat:" <> chat_id, _payload, socket) do
    user = socket.assigns.current_user

    case Chats.user_member_of_chat?(user.id, chat_id) do
      true ->
        {:ok, socket}

      false ->
        {:error, %{reason: "unauthorized"}}
    end
  end

  @impl true
  def handle_in("new_message", %{"content" => content}, socket) do
    user = socket.assigns.current_user
    chat_id = get_chat_id_from_topic(socket.topic)

    case Messages.send_message(chat_id, user.id, content) do
      {:ok, message} ->
        # Broadcast to all subscribers of this chat
        broadcast(socket, "new_message", %{
          id: message.id,
          content: message.content,
          user_id: message.user_id,
          inserted_at: message.inserted_at
        })

        # Also broadcast to Absinthe subscriptions
        Absinthe.Subscription.publish(ServerWeb.Endpoint, message, message_sent: "chat:#{chat_id}")

        {:noreply, socket}

      {:error, :forbidden} ->
        {:reply, {:error, %{reason: "unauthorized"}}, socket}

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
