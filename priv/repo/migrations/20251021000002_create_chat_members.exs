defmodule Server.Repo.Migrations.CreateChatMembers do
  use Ecto.Migration

  def change do
    execute "CREATE TYPE chat_member_role AS ENUM ('owner', 'admin', 'member')"

    create table(:chat_members) do
      add :chat_id, references(:chats, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :role, :chat_member_role, null: false, default: "member"

      timestamps()
    end

    create unique_index(:chat_members, [:chat_id, :user_id])
    create index(:chat_members, [:user_id])
    create index(:chat_members, [:chat_id])
  end
end
