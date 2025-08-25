defmodule Server.Repo.Migrations.CreateChats do
  use Ecto.Migration

  def change do
    execute "CREATE TYPE chat_state AS ENUM ('active', 'inactive')"

    create table(:chats) do
      add :state, :chat_state, null: false

      timestamps()
    end
  end
end
