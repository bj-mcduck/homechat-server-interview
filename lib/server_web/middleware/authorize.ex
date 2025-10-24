defmodule ServerWeb.Middleware.Authorize do
  @moduledoc """
  Absinthe middleware for authorization using Bodyguard policies.

  Usage in schema:
    middleware(Authorize, policy: Server.Chats.Policy, action: :send_message)
  """

  @behaviour Absinthe.Middleware

  def call(resolution, config) do
    action = Keyword.fetch!(config, :action)
    policy = Keyword.fetch!(config, :policy)

    with %{current_user: user} <- resolution.context,
         resource <- get_resource(resolution, config),
         :ok <- policy.authorize(action, user, resource) do
      resolution
    else
      {:error, reason} when is_atom(reason) ->
        resolution
        |> Absinthe.Resolution.put_result({:error, format_error(reason)})

      {:error, message} when is_binary(message) ->
        resolution
        |> Absinthe.Resolution.put_result({:error, message})

      _ ->
        resolution
        |> Absinthe.Resolution.put_result({:error, "Authentication required"})
    end
  end

  # Get the resource from resolution
  # Can be from parent (for nested fields) or from a loaded resource
  defp get_resource(resolution, config) do
    case Keyword.get(config, :resource) do
      nil -> resolution.source
      key when is_atom(key) -> Map.get(resolution.source, key)
      fun when is_function(fun, 1) -> fun.(resolution)
    end
  end

  # Format error atoms into user-friendly messages
  defp format_error(:not_a_member), do: "You are not a member of this chat"
  defp format_error(:not_owner), do: "Only chat owners can perform this action"
  defp format_error(:cannot_leave_unnamed_chat), do: "Cannot leave direct message chats"
  defp format_error(:chat_inactive), do: "This chat is no longer active"
  defp format_error(reason), do: "Authorization failed: #{reason}"
end
