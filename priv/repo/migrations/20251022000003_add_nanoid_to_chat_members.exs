defmodule Server.Repo.Migrations.AddNanoidToChatMembers do
  use Ecto.Migration

  def change do
    alter table(:chat_members) do
      add :nanoid, :string
    end

    create unique_index(:chat_members, [:nanoid])
  end
end
