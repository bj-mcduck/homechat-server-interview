defmodule ServerWeb.PresenceChannel do
  @moduledoc """
  Phoenix Channel for tracking global user presence.

  This channel handles:
  - Global presence tracking (who's online across the entire app)
  - Rich presence metadata (status, device type, last seen)
  - Automatic presence state broadcasts via Phoenix.Presence
  """

  use Phoenix.Channel
  alias ServerWeb.Presence

  @impl true
  def join("presence:global", _payload, socket) do
    user = socket.assigns.current_user

    if user do
      # Track user presence by database ID with nanoid in metadata
      {:ok, _} = Presence.track(socket, to_string(user.id), %{
        user_id: user.nanoid,  # Add nanoid as user_id
        username: user.username,
        full_name: "#{user.first_name} #{user.last_name}",
        status: "online",
        last_seen: NaiveDateTime.utc_now(),
        device_type: "web"
      })

      # Send message to self to push presence state after join completes
      send(self(), :after_join)

      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  @impl true
  def handle_info(:after_join, socket) do
    # Send current presence state to the newly joined client
    push(socket, "presence_state", Presence.list("presence:global"))
    {:noreply, socket}
  end

end
