defmodule Server.Chats do
  @moduledoc """
  The Chats context for managing chat rooms and memberships.
  """

  import Ecto.Query, warn: false
  alias Server.Repo
  alias Server.Models.{ChatModel, ChatMemberModel}

  @doc """
  Returns the list of active chats for a user.
  """
  def list_user_chats(user_id) do
    from(c in ChatModel,
      join: cm in ChatMemberModel, on: c.id == cm.chat_id,
      where: cm.user_id == ^user_id and c.state == :active,
      order_by: [desc: c.updated_at],
      preload: [:members, :messages]
    )
    |> Repo.all()
  end

  @doc """
  Returns the list of public chats.
  """
  def list_public_chats do
    from(c in ChatModel,
      where: c.private == false and c.state == :active,
      order_by: [desc: c.updated_at],
      preload: [:members]
    )
    |> Repo.all()
  end

  @doc """
  Returns the list of discoverable chats for a user (their chats + public chats).
  """
  def list_discoverable_chats(user_id) do
    user_chats = list_user_chats(user_id)
    public_chats = list_public_chats()

    # Remove duplicates (in case user is in a public chat)
    all_chats = user_chats ++ public_chats
    Enum.uniq_by(all_chats, & &1.id)
  end

  @doc """
  Gets a single chat by nanoid.
  """
  def get_chat!(nanoid), do: Repo.get_by!(ChatModel, nanoid: nanoid)

  @doc """
  Gets a single chat by nanoid.
  """
  def get_chat(nanoid), do: Repo.get_by(ChatModel, nanoid: nanoid)

  @doc """
  Gets a chat with members preloaded by nanoid.
  """
  def get_chat_with_members(nanoid) do
    from(c in ChatModel,
      where: c.nanoid == ^nanoid,
      preload: [:members, :messages]
    )
    |> Repo.one()
  end

  @doc """
  Gets a chat's internal ID by nanoid.
  """
  def get_chat_id(nanoid) do
    case get_chat(nanoid) do
      nil -> nil
      chat -> chat.id
    end
  end

  @doc """
  Checks if a user is a member of a chat (internal function using integer IDs).
  """
  def user_member_of_chat?(user_id, chat_id) do
    from(cm in ChatMemberModel,
      where: cm.user_id == ^user_id and cm.chat_id == ^chat_id
    )
    |> Repo.exists?()
  end

  @doc """
  Gets a chat member record.
  """
  def get_chat_member(user_id, chat_id) do
    from(cm in ChatMemberModel,
      where: cm.user_id == ^user_id and cm.chat_id == ^chat_id
    )
    |> Repo.one()
  end

  @doc """
  Creates a chat with the given attributes, creator, and participants.
  Handles both named and unnamed chats with appropriate deduplication logic.
  """
  def create_chat(attrs, creator_id, participant_ids \\ []) do
    case attrs[:name] do
      nil ->
        # Unnamed chat - check for existing chat with same participants
        case get_existing_chat_by_participants(creator_id, participant_ids) do
          nil ->
            # Create new unnamed chat
            create_new_chat(attrs, creator_id, participant_ids)
          existing_chat ->
            {:ok, existing_chat}
        end

      name ->
        # Named chat - check if name is taken
        case get_chat_by_name(name) do
          nil ->
            # Name is available, create new named chat with participants
            create_new_chat(attrs, creator_id, participant_ids)
          _existing_chat ->
            {:error, :name_taken}
        end
    end
  end

  @doc """
  Creates a direct chat between two users.
  """
  def create_direct_chat(creator_id, participant_id) do
    attrs = %{state: :active}
    create_chat(attrs, creator_id, [participant_id])
  end

  @doc """
  Creates a group chat.
  """
  def create_group_chat(attrs, creator_id, member_ids) do
    create_chat(attrs, creator_id, member_ids)
  end

  @doc """
  Creates or finds an unnamed group chat with the given participants.
  If a chat already exists with these exact participants, returns it.
  Otherwise creates a new unnamed group chat.
  """
  def create_or_find_group_chat(creator_id, participant_ids) do
    # Create unnamed group with these participants
    # If it already exists, get_existing_chat_by_participants will find it
    create_chat(%{state: :active}, creator_id, participant_ids)
  end

  @doc """
  Creates a chat record.
  """
  def create_chat_record(attrs \\ %{}) do
    %ChatModel{}
    |> ChatModel.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a chat.
  """
  def update_chat(%ChatModel{} = chat, attrs) do
    chat
    |> ChatModel.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Updates chat privacy setting.
  """
  def update_chat_privacy(%ChatModel{} = chat, private) do
    update_chat(chat, %{private: private})
  end

  @doc """
  Deletes a chat.
  """
  def delete_chat(%ChatModel{} = chat) do
    Repo.delete(chat)
  end


  @doc """
  Adds multiple members to a chat.
  """
  def add_chat_members(chat_id, user_ids, role \\ :member) do
    chat_members = Enum.map(user_ids, fn user_id ->
      %{
        chat_id: chat_id,
        user_id: user_id,
        role: role,
        nanoid: "mbr_#{Nanoid.generate(10)}",
        inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
        updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
      }
    end)

    case Repo.insert_all(ChatMemberModel, chat_members) do
      {count, _} when count > 0 -> {:ok, chat_members}
      {0, _} -> {:error, :no_members_added}
    end
  rescue
    Ecto.ConstraintError -> {:error, :duplicate_member}
    Postgrex.Error -> {:error, :duplicate_member}
  end

  @doc """
  Removes a member from a chat.
  """
  def remove_chat_member(chat_id, user_id) do
    from(cm in ChatMemberModel,
      where: cm.chat_id == ^chat_id and cm.user_id == ^user_id
    )
    |> Repo.delete_all()
    |> case do
      {1, _} -> :ok
      {0, _} -> {:error, :not_found}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking chat changes.
  """
  def change_chat(%ChatModel{} = chat, attrs \\ %{}) do
    ChatModel.changeset(chat, attrs)
  end

  # Private functions

  defp get_existing_chat_by_participants(creator_id, participant_ids) do
    all_user_ids = [creator_id | participant_ids]
    user_count = length(all_user_ids)

    from(chat in ChatModel,
      where: chat.state == :active and is_nil(chat.name),
      where: fragment("? = (SELECT COUNT(*) FROM chat_members WHERE chat_id = ? AND user_id = ANY(?))",
                     ^user_count, chat.id, ^all_user_ids),
      preload: [:members]
    )
    |> Repo.one()
  end

  defp get_chat_by_name(name) do
    from(c in ChatModel,
      where: c.name == ^name and c.state == :active
    )
    |> Repo.one()
  end

  defp create_new_chat(attrs, creator_id, participant_ids) do
    Repo.transaction(fn ->
      with {:ok, chat} <- create_chat_record(attrs),
           {:ok, _} <- add_chat_members(chat.id, [creator_id], :owner),
           {:ok, _} <- add_participants_if_any(chat.id, participant_ids) do
        get_chat_with_members(chat.nanoid)
      else
        {:error, changeset} -> Repo.rollback(changeset)
      end
    end)
  end

  defp add_participants_if_any(_chat_id, []) do
    {:ok, []}
  end

  defp add_participants_if_any(chat_id, participant_ids) do
    add_chat_members(chat_id, participant_ids, :member)
  end
end
