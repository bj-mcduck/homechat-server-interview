defmodule ServerWeb.Schemas.MessageSchema do
  @moduledoc false

  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  alias Server.Messages
  alias ServerWeb.Middleware.{Authenticate, AuthorizeChatMember}

  object :message do
    # Expose nanoid as the public ID, hide internal integer ID
    field :id, non_null(:string) do
      resolve(fn message, _, _ -> {:ok, message.nanoid} end)
    end
    field :content, non_null(:string)
    field :inserted_at, non_null(:string)
    field :updated_at, non_null(:string)
    field :user, non_null(:user)
    field :chat, non_null(:chat)
  end

  object :message_queries do
    field :messages, list_of(:message) do
      arg :chat_id, non_null(:string)
      arg :page, :integer, default_value: 1
      arg :limit, :integer, default_value: 50
      middleware(Authenticate)
      middleware(AuthorizeChatMember)
      resolve(fn %{chat_id: chat_id, page: page, limit: limit}, _info ->
        offset = (page - 1) * limit
        messages = Messages.list_messages(chat_id, limit: limit, offset: offset)
        {:ok, messages}
      end)
    end

    field :recent_messages, list_of(:message) do
      arg :chat_id, non_null(:string)
      arg :limit, :integer, default_value: 20
      middleware(Authenticate)
      middleware(AuthorizeChatMember)
      resolve(fn %{chat_id: chat_id, limit: limit}, _info ->
        messages = Messages.list_recent_messages(chat_id, limit)
        {:ok, messages}
      end)
    end
  end

  object :message_mutations do
    field :send_message, :message do
      arg :chat_id, non_null(:string)
      arg :content, non_null(:string)
      middleware(Authenticate)
      middleware(AuthorizeChatMember)
      resolve(fn %{chat_id: chat_nanoid, content: content}, %{context: %{current_user: user}} ->
        case Messages.send_message(chat_nanoid, user.id, content) do
          {:ok, message} ->
            # Broadcast to subscribers
            Absinthe.Subscription.publish(ServerWeb.Endpoint, message, message_sent: "chat:#{chat_nanoid}")
            {:ok, message}
          {:error, :forbidden} -> {:error, "Access denied"}
          {:error, :not_found} -> {:error, "Chat not found"}
          {:error, changeset} -> {:error, "Failed to send message: #{inspect(changeset.errors)}"}
        end
      end)
    end
  end

  object :message_subscriptions do
    field :message_sent, :message do
      arg :chat_id, non_null(:string)
      config(fn args, _info ->
        {:ok, topic: "chat:#{args.chat_id}"}
      end)
    end
  end
end
