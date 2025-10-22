defmodule Server.Repo.Migrations.AddNanoidToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :nanoid, :string
    end

    create unique_index(:users, [:nanoid])
  end
end
