defmodule ServerWeb.Middleware.AuthorizeChatMember do
  @moduledoc """
  Middleware to verify user is a member of a chat.
  """

  @behaviour Absinthe.Middleware

  alias Server.Chats

  def call(resolution, _config) do
    case resolution.context do
      %{current_user: %{id: user_id}} ->
        chat_id = get_chat_id_from_args(resolution.arguments)
        
        if chat_id && Chats.user_member_of_chat?(user_id, chat_id) do
          resolution
        else
          resolution
          |> Absinthe.Resolution.put_result({:error, "Access denied"})
        end

      _ ->
        resolution
        |> Absinthe.Resolution.put_result({:error, "Authentication required"})
    end
  end

  defp get_chat_id_from_args(args) when is_map(args) do
    args[:chat_id] || args["chat_id"]
  end

  defp get_chat_id_from_args(_), do: nil
end
