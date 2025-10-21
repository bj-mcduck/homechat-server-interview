defmodule Server.Repo.Migrations.CreateMessages do
  use Ecto.Migration

  def change do
    create table(:messages) do
      add :content, :text, null: false
      add :chat_id, references(:chats, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:messages, [:chat_id])
    create index(:messages, [:user_id])
    create index(:messages, [:inserted_at])
  end
end
