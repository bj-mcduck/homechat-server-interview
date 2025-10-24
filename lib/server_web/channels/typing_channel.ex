defmodule ServerWeb.TypingChannel do
  use Phoenix.Channel

  # Join a chat's typing channel
  # Topic format: "typing:chat_nanoid"
  def join("typing:" <> chat_nanoid, _payload, socket) do
    user = socket.assigns.current_user

    # Verify user is a member of this chat
    case Server.Chats.get_chat_id(chat_nanoid) do
      nil ->
        {:error, %{reason: "Chat not found"}}
      chat_id ->
        if Server.Chats.user_member_of_chat?(user.id, chat_id) do
          {:ok, socket}
        else
          {:error, %{reason: "Not a member"}}
        end
    end
  end

  # Handle typing start event
  def handle_in("typing_start", _payload, socket) do
    user = socket.assigns.current_user

    # Broadcast to everyone else in the channel
    broadcast_from!(socket, "user_typing", %{
      user_id: user.nanoid,
      user_name: "#{user.first_name} #{user.last_name}"
    })

    {:noreply, socket}
  end

  # Handle typing stop event
  def handle_in("typing_stop", _payload, socket) do
    user = socket.assigns.current_user

    broadcast_from!(socket, "user_stopped_typing", %{
      user_id: user.nanoid
    })

    {:noreply, socket}
  end
end
