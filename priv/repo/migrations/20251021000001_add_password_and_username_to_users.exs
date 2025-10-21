defmodule Server.Repo.Migrations.AddPasswordAndUsernameToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :password_hash, :string, null: false
      add :username, :string, null: false
    end

    create unique_index(:users, [:username])
  end
end
