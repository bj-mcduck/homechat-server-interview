defmodule ServerWeb.Socket do
  @moduledoc false

  use Phoenix.Socket
  use Absinthe.Phoenix.Socket, schema: ServerWeb.Schemas.Schema

  ## Channels
  channel "chat:*", ServerWeb.ChatChannel
  channel "typing:*", ServerWeb.TypingChannel
  channel "presence:global", ServerWeb.PresenceChannel

  # Socket params are passed from the client and can
  # be used to verify and authenticate a user. After
  # verification, you can put default assigns into
  # the socket that will be set for all channels, ie
  #
  #     {:ok, assign(socket, :user_id, verified_user_id)}
  #
  # To deny connection, return `:error`.
  #
  # See `Phoenix.Token` documentation for examples in
  # performing token verification on connect.
  @impl Phoenix.Socket
  def connect(params, socket, _connect_info) do
    case authenticate_socket(params) do
      {:ok, user} ->
        {:ok, assign(socket, :current_user, user)}

      {:error, _reason} ->
        :error
    end
  end

  # Socket id's are topics that allow you to identify all sockets for a given user:
  #
  #     def id(socket), do: "user_socket:#{socket.assigns.user_id}"
  #
  # Would allow you to broadcast a "disconnect" event and terminate
  # all active sockets and channels for a given user:
  #
  #     HiiveWeb.Endpoint.broadcast("user_socket:#{user.id}", "disconnect", %{})
  #
  # Returning `nil` makes this socket anonymous.
  @impl Phoenix.Socket
  def id(socket) do
    case socket.assigns do
      %{current_user: %{id: user_id}} -> "user_socket:#{user_id}"
      _ -> nil
    end
  end

  # CRITICAL: This function provides Absinthe context for subscriptions
  # Without this, subscriptions can't access the current_user context
  def absinthe_config(_args, socket) do
    case socket.assigns do
      %{current_user: user} ->
        Absinthe.Phoenix.Socket.put_options(socket, context: %{current_user: user})

      _ ->
        socket
    end
  end

  # Private functions

  defp authenticate_socket(params) do
    case params do
      %{"token" => token} ->
        case Server.Guardian.verify_token(token) do
          {:ok, user} -> {:ok, user}
          {:error, _reason} -> {:error, :invalid_token}
        end

      _ ->
        {:error, :missing_token}
    end
  end
end
