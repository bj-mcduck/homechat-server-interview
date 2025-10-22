defmodule Server.Chats do
  @moduledoc """
  The Chats context for managing chat rooms and memberships.
  """

  import Ecto.Query, warn: false
  alias Server.Repo
  alias Server.Models.{ChatModel, ChatMemberModel}

  @doc """
  Returns the list of chats for a user.
  """
  def list_user_chats(user_id) do
    from(c in ChatModel,
      join: cm in ChatMemberModel, on: c.id == cm.chat_id,
      where: cm.user_id == ^user_id,
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
  Creates a direct chat between two users.
  """
  def create_direct_chat(user1_id, user2_id) do
    # Check if direct chat already exists
    existing_chat = get_existing_direct_chat(user1_id, user2_id)
    if existing_chat, do: {:ok, existing_chat}

    # Create new direct chat
    Repo.transaction(fn ->
      with {:ok, chat} <- create_chat(%{state: :active}),
           {:ok, _} <- add_chat_member(chat.id, user1_id, :owner),
           {:ok, _} <- add_chat_member(chat.id, user2_id, :member) do
        get_chat_with_members(chat.nanoid)
      else
        {:error, changeset} -> Repo.rollback(changeset)
      end
    end)
  end

  @doc """
  Creates a group chat.
  """
  def create_group_chat(attrs, creator_id, member_ids) do
    Repo.transaction(fn ->
      with {:ok, chat} <- create_chat(attrs),
           {:ok, _} <- add_chat_member(chat.id, creator_id, :owner),
           {:ok, _} <- add_chat_members(chat.id, member_ids, :member) do
        get_chat_with_members(chat.nanoid)
      else
        {:error, changeset} -> Repo.rollback(changeset)
      end
    end)
  end

  @doc """
  Creates a chat.
  """
  def create_chat(attrs \\ %{}) do
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
  Adds a member to a chat.
  """
  def add_chat_member(chat_id, user_id, role \\ :member) do
    %ChatMemberModel{}
    |> ChatMemberModel.create_changeset(%{
      chat_id: chat_id,
      user_id: user_id,
      role: role
    })
    |> Repo.insert()
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
        inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
        updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
      }
    end)

    Repo.insert_all(ChatMemberModel, chat_members)
    {:ok, chat_members}
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

  defp get_existing_direct_chat(user1_id, user2_id) do
    from(c in ChatModel,
      join: cm1 in ChatMemberModel, on: c.id == cm1.chat_id,
      join: cm2 in ChatMemberModel, on: c.id == cm2.chat_id,
      where: cm1.user_id == ^user1_id and cm2.user_id == ^user2_id,
      where: c.private == true,
      preload: [:members]
    )
    |> Repo.one()
  end
end
