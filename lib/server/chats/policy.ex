defmodule Server.Chats.Policy do
  @moduledoc """
  Authorization policies for chat operations.
  Similar to Pundit/ActionPolicy in Rails.
  """

  alias Server.Models.{ChatModel, UserModel}
  alias Server.Chats

  # Anyone can create a chat
  def authorize(:create_chat, %UserModel{state: :active}, _params) do
    :ok
  end

  # Only members can view a chat
  def authorize(:view_chat, %UserModel{id: user_id}, %ChatModel{id: chat_id}) do
    if Chats.user_member_of_chat?(user_id, chat_id) do
      :ok
    else
      {:error, :not_a_member}
    end
  end

  # Only members can send messages, and chat must be active
  def authorize(:send_message, %UserModel{id: user_id}, %ChatModel{id: chat_id, state: state}) do
    cond do
      state != :active -> {:error, :chat_inactive}
      !Chats.user_member_of_chat?(user_id, chat_id) -> {:error, :not_a_member}
      true -> :ok
    end
  end

  # Only members can add other members
  def authorize(:add_member, %UserModel{id: user_id}, %ChatModel{id: chat_id}) do
    if Chats.user_member_of_chat?(user_id, chat_id) do
      :ok
    else
      {:error, :not_a_member}
    end
  end

  # Only members can leave, but not direct messages (unnamed chats)
  def authorize(:leave_chat, %UserModel{id: user_id}, %ChatModel{id: chat_id, name: name}) do
    cond do
      is_nil(name) -> {:error, :cannot_leave_unnamed_chat}
      !Chats.user_member_of_chat?(user_id, chat_id) -> {:error, :not_a_member}
      true -> :ok
    end
  end

  # Only owners can update chat settings
  def authorize(:update_chat, %UserModel{id: user_id}, %ChatModel{id: chat_id}) do
    case Chats.get_chat_member(user_id, chat_id) do
      nil -> {:error, :not_a_member}
      %{role: :owner} -> :ok
      _ -> {:error, :not_owner}
    end
  end

  # Only owners can delete a chat
  def authorize(:delete_chat, %UserModel{id: user_id}, %ChatModel{id: chat_id}) do
    case Chats.get_chat_member(user_id, chat_id) do
      nil -> {:error, :not_a_member}
      %{role: :owner} -> :ok
      _ -> {:error, :not_owner}
    end
  end

  # Only owners can update privacy settings
  def authorize(:update_privacy, %UserModel{id: user_id}, %ChatModel{id: chat_id}) do
    case Chats.get_chat_member(user_id, chat_id) do
      nil -> {:error, :not_a_member}
      %{role: :owner} -> :ok
      _ -> {:error, :not_owner}
    end
  end

  # Default deny - must explicitly authorize
  def authorize(_action, _user, _resource), do: {:error, :unauthorized}
end
