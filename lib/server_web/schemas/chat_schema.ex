defmodule ServerWeb.Schemas.ChatSchema do
  @moduledoc false

  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  alias Server.Chats
  alias ServerWeb.Middleware.{Authenticate, AuthorizeChatMember}

  object :chat do
    # Expose nanoid as the public ID, hide internal integer ID
    field :id, non_null(:string) do
      resolve(fn chat, _, _ -> {:ok, chat.nanoid} end)
    end
    field :name, :string
    field :private, non_null(:boolean)
    field :state, non_null(:string)
    field :inserted_at, non_null(:string)
    field :updated_at, non_null(:string)
    field :members, list_of(:user)
    field :last_message, :message
    field :is_direct, non_null(:boolean) do
      resolve(fn chat, _args, _info ->
        {:ok, Server.Models.ChatModel.direct?(chat)}
      end)
    end
  end

  object :chat_queries do
    field :chats, list_of(:chat) do
      middleware(Authenticate)
      resolve(fn _args, %{context: %{current_user: user}} ->
        chats = Chats.list_user_chats(user.id)
        {:ok, chats}
      end)
    end

    field :discoverable_chats, list_of(:chat) do
      middleware(Authenticate)
      resolve(fn _args, %{context: %{current_user: user}} ->
        chats = Chats.list_discoverable_chats(user.id)
        {:ok, chats}
      end)
    end

    field :chat, :chat do
      arg :id, non_null(:id)
      middleware(Authenticate)
      middleware(AuthorizeChatMember)
      resolve(fn %{id: id}, _info ->
        case Chats.get_chat_with_members(id) do
          nil -> {:error, "Chat not found"}
          chat -> {:ok, chat}
        end
      end)
    end
  end

  object :chat_mutations do
    field :create_direct_chat, :chat do
      arg :user_id, non_null(:string)
      middleware(Authenticate)
      resolve(fn %{user_id: user_nanoid}, %{context: %{current_user: current_user}} ->
        case Server.Accounts.get_user_id(user_nanoid) do
          nil -> {:error, "User not found"}
          user_id ->
            case Chats.create_direct_chat(current_user.id, user_id) do
              {:ok, chat} -> {:ok, chat}
              {:error, changeset} -> {:error, "Failed to create chat: #{inspect(changeset.errors)}"}
            end
        end
      end)
    end

    field :create_group_chat, :chat do
      arg :name, non_null(:string)
      arg :participant_ids, non_null(list_of(:string))
      middleware(Authenticate)
      resolve(fn %{name: name, participant_ids: participant_nanoids}, %{context: %{current_user: current_user}} ->
        # Convert nanoids to IDs
        participant_ids =
          participant_nanoids
          |> Enum.map(&Server.Accounts.get_user_id/1)
          |> Enum.reject(&is_nil/1)

        if length(participant_ids) != length(participant_nanoids) do
          {:error, "One or more users not found"}
        else
          attrs = %{name: name, private: true, state: :active}
          case Chats.create_group_chat(attrs, current_user.id, participant_ids) do
            {:ok, chat} -> {:ok, chat}
            {:error, changeset} -> {:error, "Failed to create group chat: #{inspect(changeset.errors)}"}
          end
        end
      end)
    end

    field :add_chat_member, :chat do
      arg :chat_id, non_null(:string)
      arg :user_id, non_null(:string)
      middleware(Authenticate)
      middleware(AuthorizeChatMember)
      resolve(fn %{chat_id: chat_nanoid, user_id: user_nanoid}, _info ->
        case {Chats.get_chat_id(chat_nanoid), Server.Accounts.get_user_id(user_nanoid)} do
          {nil, _} -> {:error, "Chat not found"}
          {_, nil} -> {:error, "User not found"}
          {chat_id, user_id} ->
            case Chats.add_chat_member(chat_id, user_id) do
              {:ok, _} ->
                case Chats.get_chat_with_members(chat_nanoid) do
                  nil -> {:error, "Chat not found"}
                  chat -> {:ok, chat}
                end
              {:error, changeset} -> {:error, "Failed to add member: #{inspect(changeset.errors)}"}
            end
        end
      end)
    end

    field :update_chat_privacy, :chat do
      arg :chat_id, non_null(:string)
      arg :private, non_null(:boolean)
      middleware(Authenticate)
      middleware(AuthorizeChatMember)
      resolve(fn %{chat_id: chat_nanoid, private: private}, _info ->
        case Chats.get_chat(chat_nanoid) do
          nil -> {:error, "Chat not found"}
          chat ->
            case Chats.update_chat_privacy(chat, private) do
              {:ok, updated_chat} -> {:ok, updated_chat}
              {:error, changeset} -> {:error, "Failed to update privacy: #{inspect(changeset.errors)}"}
            end
        end
      end)
    end
  end

  object :chat_subscriptions do
    field :chat_updated, :chat do
      arg :chat_id, non_null(:string)
      config(fn args, _info ->
        {:ok, topic: "chat:#{args.chat_id}"}
      end)
    end
  end
end
