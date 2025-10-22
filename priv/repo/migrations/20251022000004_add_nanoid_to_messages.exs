defmodule Server.Repo.Migrations.AddNanoidToMessages do
  use Ecto.Migration

  def change do
    alter table(:messages) do
      add :nanoid, :string
    end

    create unique_index(:messages, [:nanoid])
  end
end
