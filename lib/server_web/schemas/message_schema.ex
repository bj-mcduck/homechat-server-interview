defmodule ServerWeb.Schemas.MessageSchema do
  @moduledoc false

  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  import Absinthe.Resolution.Helpers, only: [dataloader: 1]

  alias Server.Messages
  alias ServerWeb.Middleware.{Authenticate, AuthorizeChatMember, Authorize}
  alias Server.Chats.Policy, as: ChatPolicy

  # Helper function to load chat for authorization
  defp load_chat_for_auth(resolution) do
    chat_nanoid = resolution.arguments[:chat_id]

    case Server.Chats.get_chat(chat_nanoid) do
      nil -> nil
      chat -> chat
    end
  end

  object :message do
    # Expose nanoid as the public ID, hide internal integer ID
    field :id, non_null(:string) do
      resolve(fn message, _, _ -> {:ok, message.nanoid} end)
    end

    field :content, non_null(:string)
    field :inserted_at, non_null(:string)
    field :updated_at, non_null(:string)
    field :user, non_null(:user), resolve: dataloader(Server.Accounts)
    field :chat, non_null(:chat), resolve: dataloader(Server.Chats)
  end

  object :message_queries do
    field :messages, list_of(:message) do
      arg(:chat_id, non_null(:string))
      arg(:page, :integer, default_value: 1)
      arg(:limit, :integer, default_value: 50)
      arg(:offset, :integer, default_value: 0)
      middleware(Authenticate)

      middleware(Authorize,
        policy: ChatPolicy,
        action: :view_chat,
        resource: &load_chat_for_auth/1
      )

      resolve(fn %{chat_id: chat_id, page: page, limit: limit, offset: offset}, _info ->
        # Use explicit offset if provided, otherwise calculate from page
        final_offset = if offset > 0, do: offset, else: (page - 1) * limit
        messages = Messages.list_messages(chat_id, limit: limit, offset: final_offset)
        {:ok, messages}
      end)
    end

    field :recent_messages, list_of(:message) do
      arg(:chat_id, non_null(:string))
      arg(:limit, :integer, default_value: 20)
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
      arg(:chat_id, non_null(:string))
      arg(:content, non_null(:string))
      middleware(Authenticate)

      middleware(Authorize,
        policy: ChatPolicy,
        action: :send_message,
        resource: &load_chat_for_auth/1
      )

      resolve(fn %{chat_id: chat_nanoid, content: content}, %{context: %{current_user: user}} ->
        # Authorization already checked by middleware
        case Messages.send_message(chat_nanoid, user.id, content) do
          {:ok, message} ->
            # Get chat members for user-scoped publishing
            case Server.Chats.get_chat_with_members(chat_nanoid) do
              nil ->
                {:error, "Chat not found"}

              chat ->
                # Publish to all chat members using user-scoped topics
                Enum.each(chat.members, fn member ->
                  event = %{chat_id: chat_nanoid, message: message}

                  Absinthe.Subscription.publish(ServerWeb.Endpoint, event,
                    user_messages: "user_messages:#{member.nanoid}"
                  )
                end)

                # Also publish to legacy chat topic for backward compatibility
                Absinthe.Subscription.publish(ServerWeb.Endpoint, message,
                  message_sent: "chat:#{chat_nanoid}"
                )

                {:ok, message}
            end

          {:error, :forbidden} ->
            {:error, "Access denied"}

          {:error, :not_found} ->
            {:error, "Chat not found"}

          {:error, changeset} ->
            {:error, "Failed to send message: #{inspect(changeset.errors)}"}
        end
      end)
    end
  end

  object :user_message_event do
    field :chat_id, non_null(:string)
    field :message, non_null(:message)
  end

  object :message_subscriptions do
    # @deprecated - Use user_messages instead for better scalability
    field :message_sent, :message do
      arg(:chat_id, non_null(:string))

      config(fn args, _info ->
        {:ok, topic: "chat:#{args.chat_id}"}
      end)
    end

    # New user-scoped subscription for better scalability
    field :user_messages, :user_message_event do
      arg(:user_id, non_null(:string))

      config(fn args, _info ->
        {:ok, topic: "user_messages:#{args.user_id}"}
      end)
    end
  end
end
