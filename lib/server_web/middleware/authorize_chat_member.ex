defmodule ServerWeb.Middleware.AuthorizeChatMember do
  @moduledoc """
  Middleware to verify user is a member of a chat.
  """

  @behaviour Absinthe.Middleware

  alias Server.Chats

  def call(resolution, _config) do
    with {:ok, user_id} <- get_user_id(resolution.context),
         {:ok, chat_id} <- get_chat_id(resolution.arguments),
         :ok <- validate_membership(user_id, chat_id) do
      resolution
    else
      {:error, message} ->
        resolution
        |> Absinthe.Resolution.put_result({:error, message})
    end
  end

  defp get_user_id(%{current_user: %{id: user_id}}), do: {:ok, user_id}
  defp get_user_id(_), do: {:error, "Authentication required"}

  defp get_chat_id(args) do
    chat_nanoid = get_chat_id_from_args(args)
    case chat_nanoid && Chats.get_chat_id(chat_nanoid) do
      nil -> {:error, "Chat not found"}
      chat_id -> {:ok, chat_id}
    end
  end

  defp validate_membership(user_id, chat_id) do
    if Chats.user_member_of_chat?(user_id, chat_id) do
      :ok
    else
      {:error, "Access denied"}
    end
  end

  defp get_chat_id_from_args(args) when is_map(args) do
    # Check for both :id and :chat_id to support different query field names
    args[:id] || args["id"] || args[:chat_id] || args["chat_id"]
  end

  defp get_chat_id_from_args(_), do: nil
end
