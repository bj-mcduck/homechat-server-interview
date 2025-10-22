defmodule Server.Repo.Migrations.AddNanoidToChats do
  use Ecto.Migration

  def change do
    alter table(:chats) do
      add :nanoid, :string
    end

    create unique_index(:chats, [:nanoid])
  end
end
