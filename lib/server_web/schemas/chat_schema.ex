defmodule ServerWeb.Schemas.ChatSchema do
  @moduledoc false

  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  import Absinthe.Resolution.Helpers, only: [dataloader: 1]

  alias Server.Chats
  alias ServerWeb.Middleware.{Authenticate, Authorize}
  alias Server.Chats.Policy, as: ChatPolicy

  # Helper function to load chat for authorization
  defp load_chat_for_auth(resolution) do
    chat_nanoid = resolution.arguments[:chat_id] || resolution.arguments[:id]

    case Chats.get_chat(chat_nanoid) do
      nil -> nil
      chat -> chat
    end
  end

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
    field :members, list_of(:user), resolve: dataloader(Server.Chats)
    field :last_message, :message

    field :is_direct, non_null(:boolean)

    field :display_name, non_null(:string) do
      resolve(fn chat, _args, resolution ->
        current_user = resolution.context[:current_user]

        cond do
          chat.name ->
            {:ok, chat.name}

          Enum.empty?(chat.member_names) ->
            {:ok, "Direct Message"}

          current_user ->
            current_user_name = "#{current_user.first_name} #{current_user.last_name}"
            names = Enum.reject(chat.member_names, &(&1 == current_user_name))
            {:ok, Enum.join(names, ", ")}

          true ->
            {:ok, Enum.join(chat.member_names, ", ")}
        end
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
      arg(:id, non_null(:string))
      middleware(Authenticate)

      middleware(Authorize,
        policy: ChatPolicy,
        action: :view_chat,
        resource: &load_chat_for_auth/1
      )

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
      arg(:user_id, non_null(:string))
      middleware(Authenticate)

      resolve(fn %{user_id: user_nanoid}, %{context: %{current_user: current_user}} ->
        case Server.Accounts.get_user_id(user_nanoid) do
          nil ->
            {:error, "User not found"}

          user_id ->
            case Chats.create_direct_chat(current_user.id, user_id) do
              {:ok, chat} ->
                # Publish to all members using user-scoped topics
                Enum.each(chat.members, fn member ->
                  Absinthe.Subscription.publish(ServerWeb.Endpoint, chat,
                    user_chat_updates: "user_chat_updates:#{member.nanoid}"
                  )
                end)

                {:ok, chat}

              {:error, changeset} ->
                {:error, "Failed to create chat: #{inspect(changeset.errors)}"}
            end
        end
      end)
    end

    field :create_group_chat, :chat do
      arg(:name, non_null(:string))
      arg(:participant_ids, list_of(:string))
      middleware(Authenticate)

      resolve(fn args, %{context: %{current_user: current_user}} ->
        name = args.name
        participant_nanoids = Map.get(args, :participant_ids)
        # Convert nanoids to IDs (handle nil case)
        participant_ids =
          case participant_nanoids do
            nil ->
              []

            nanoids ->
              nanoids
              |> Enum.map(&Server.Accounts.get_user_id/1)
              |> Enum.reject(&is_nil/1)
          end

        # Only validate participant count if participants were provided
        if participant_nanoids && length(participant_ids) != length(participant_nanoids) do
          {:error, "One or more users not found"}
        else
          attrs = %{name: name, private: true, state: :active}

          case Chats.create_group_chat(attrs, current_user.id, participant_ids) do
            {:ok, chat} ->
              # Publish to all members using user-scoped topics
              Enum.each(chat.members, fn member ->
                Absinthe.Subscription.publish(ServerWeb.Endpoint, chat,
                  user_chat_updates: "user_chat_updates:#{member.nanoid}"
                )
              end)

              {:ok, chat}

            {:error, :name_taken} ->
              {:error, "Chat name is already taken"}

            {:error, changeset} when is_struct(changeset) ->
              {:error, "Failed to create group chat: #{inspect(changeset.errors)}"}

            {:error, reason} ->
              {:error, "Failed to create group chat: #{inspect(reason)}"}
          end
        end
      end)
    end

    field :add_chat_member, :chat do
      arg(:chat_id, non_null(:string))
      arg(:user_id, non_null(:string))
      middleware(Authenticate)

      middleware(Authorize,
        policy: ChatPolicy,
        action: :add_member,
        resource: &load_chat_for_auth/1
      )

      resolve(fn %{chat_id: chat_nanoid, user_id: user_nanoid}, _info ->
        case {Chats.get_chat_id(chat_nanoid), Server.Accounts.get_user_id(user_nanoid)} do
          {nil, _} ->
            {:error, "Chat not found"}

          {_, nil} ->
            {:error, "User not found"}

          {chat_id, user_id} ->
            case Chats.add_chat_members(chat_id, [user_id]) do
              {:ok, _} ->
                case Chats.get_chat_with_members(chat_nanoid) do
                  nil ->
                    {:error, "Chat not found"}

                  chat ->
                    # Publish to all members using user-scoped topics
                    all_member_nanoids = [user_nanoid | Enum.map(chat.members, & &1.nanoid)]

                    Enum.each(Enum.uniq(all_member_nanoids), fn member_nanoid ->
                      Absinthe.Subscription.publish(ServerWeb.Endpoint, chat,
                        user_chat_updates: "user_chat_updates:#{member_nanoid}"
                      )
                    end)

                    # Also publish to legacy topics for backward compatibility
                    Absinthe.Subscription.publish(ServerWeb.Endpoint, chat,
                      chat_updated: "chat:#{chat_nanoid}"
                    )

                    Absinthe.Subscription.publish(ServerWeb.Endpoint, chat,
                      user_chats_updated: "user_chats:#{user_nanoid}"
                    )

                    {:ok, chat}
                end

              {:error, _} ->
                {:error, "Failed to add member"}
            end
        end
      end)
    end

    field :update_chat_privacy, :chat do
      arg(:chat_id, non_null(:string))
      arg(:private, non_null(:boolean))
      middleware(Authenticate)

      middleware(Authorize,
        policy: ChatPolicy,
        action: :update_privacy,
        resource: &load_chat_for_auth/1
      )

      resolve(fn %{chat_id: chat_nanoid, private: private}, _info ->
        case Chats.get_chat(chat_nanoid) do
          nil ->
            {:error, "Chat not found"}

          chat ->
            case Chats.update_chat_privacy(chat, private) do
              {:ok, _updated_chat} ->
                # Get chat with members for publishing
                case Chats.get_chat_with_members(chat_nanoid) do
                  nil ->
                    {:error, "Chat not found"}

                  chat_with_members ->
                    # Publish to all current members
                    Enum.each(chat_with_members.members, fn member ->
                      Absinthe.Subscription.publish(ServerWeb.Endpoint, chat_with_members,
                        user_chat_updates: "user_chat_updates:#{member.nanoid}"
                      )
                    end)

                    {:ok, chat_with_members}
                end

              {:error, changeset} ->
                {:error, "Failed to update privacy: #{inspect(changeset.errors)}"}
            end
        end
      end)
    end

    field :create_or_find_group_chat, :chat do
      arg(:participant_ids, non_null(list_of(non_null(:string))))
      middleware(Authenticate)

      resolve(fn %{participant_ids: participant_nanoids}, %{context: %{current_user: user}} ->
        # Convert nanoids to IDs and include current user
        participant_ids =
          participant_nanoids
          |> Enum.map(&Server.Accounts.get_user_id/1)
          |> Enum.reject(&is_nil/1)

        case Chats.create_or_find_group_chat(user.id, participant_ids) do
          {:ok, chat} ->
            # Publish to all members using user-scoped topics
            # Note: This publishes even if chat already exists, which is fine
            # as it ensures all members have latest data
            Enum.each(chat.members, fn member ->
              Absinthe.Subscription.publish(ServerWeb.Endpoint, chat,
                user_chat_updates: "user_chat_updates:#{member.nanoid}"
              )
            end)

            {:ok, chat}

          {:error, reason} ->
            {:error, "Failed: #{inspect(reason)}"}
        end
      end)
    end

    field :leave_chat, :chat do
      arg(:chat_id, non_null(:string))
      middleware(Authenticate)

      middleware(Authorize,
        policy: ChatPolicy,
        action: :leave_chat,
        resource: &load_chat_for_auth/1
      )

      resolve(fn %{chat_id: chat_nanoid}, %{context: %{current_user: user}} ->
        case Chats.leave_chat(chat_nanoid, user.id) do
          {:ok, chat} ->
            # Get updated chat with remaining members
            case Chats.get_chat_with_members(chat_nanoid) do
              # Chat might be deleted if no members left
              nil ->
                {:ok, chat}

              updated_chat ->
                # Publish to remaining members
                Enum.each(updated_chat.members, fn member ->
                  Absinthe.Subscription.publish(ServerWeb.Endpoint, updated_chat,
                    user_chat_updates: "user_chat_updates:#{member.nanoid}"
                  )
                end)

                {:ok, updated_chat}
            end

          {:error, reason} ->
            {:error, "Failed to leave chat: #{inspect(reason)}"}
        end
      end)
    end

    field :archive_chat, :chat do
      arg(:chat_id, non_null(:string))
      middleware(Authenticate)

      middleware(Authorize,
        policy: ChatPolicy,
        action: :update_chat,
        resource: &load_chat_for_auth/1
      )

      resolve(fn %{chat_id: chat_nanoid}, _info ->
        case Chats.get_chat(chat_nanoid) do
          nil ->
            {:error, "Chat not found"}

          chat ->
            case Chats.update_chat(chat, %{state: :inactive}) do
              {:ok, updated_chat} ->
                # Publish to all members using user-scoped topics
                case Chats.get_chat_with_members(chat_nanoid) do
                  nil ->
                    {:ok, updated_chat}

                  chat_with_members ->
                    Enum.each(chat_with_members.members, fn member ->
                      Absinthe.Subscription.publish(ServerWeb.Endpoint, updated_chat,
                        user_chat_updates: "user_chat_updates:#{member.nanoid}"
                      )
                    end)

                    {:ok, updated_chat}
                end

              {:error, _changeset} ->
                {:error, "Failed to archive chat"}
            end
        end
      end)
    end

    field :convert_to_group, :chat do
      arg(:chat_id, non_null(:string))
      arg(:name, non_null(:string))
      middleware(Authenticate)

      middleware(Authorize,
        policy: ChatPolicy,
        action: :update_chat,
        resource: &load_chat_for_auth/1
      )

      resolve(fn %{chat_id: chat_nanoid, name: name}, _info ->
        case Chats.get_chat(chat_nanoid) do
          nil ->
            {:error, "Chat not found"}

          chat ->
            if chat.is_direct do
              case Chats.update_chat(chat, %{name: name, is_direct: false}) do
                {:ok, updated_chat} ->
                  # Refresh member cache after conversion
                  Chats.refresh_chat_member_cache(updated_chat.id)

                  # Publish to all members using user-scoped topics
                  case Chats.get_chat_with_members(chat_nanoid) do
                    nil ->
                      {:ok, updated_chat}

                    chat_with_members ->
                      Enum.each(chat_with_members.members, fn member ->
                        Absinthe.Subscription.publish(ServerWeb.Endpoint, updated_chat,
                          user_chat_updates: "user_chat_updates:#{member.nanoid}"
                        )
                      end)

                      {:ok, updated_chat}
                  end

                {:error, _changeset} ->
                  {:error, "Failed to convert chat"}
              end
            else
              {:error, "Chat is already a named group"}
            end
        end
      end)
    end
  end

  object :chat_subscriptions do
    # @deprecated - Use user_chat_updates instead for better scalability
    field :chat_updated, :chat do
      arg(:chat_id, non_null(:string))

      config(fn args, _info ->
        {:ok, topic: "chat:#{args.chat_id}"}
      end)
    end

    # @deprecated - Use user_chat_updates instead for better scalability
    field :user_chats_updated, :chat do
      arg(:user_id, non_null(:string))

      config(fn args, _info ->
        {:ok, topic: "user_chats:#{args.user_id}"}
      end)
    end

    # New user-scoped subscription for better scalability
    field :user_chat_updates, :chat do
      arg(:user_id, non_null(:string))

      config(fn args, _info ->
        {:ok, topic: "user_chat_updates:#{args.user_id}"}
      end)
    end
  end
end
