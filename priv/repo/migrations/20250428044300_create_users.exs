defmodule Server.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    execute "CREATE TYPE user_state AS ENUM ('active', 'inactive')"

    create table(:users) do
      add :first_name, :string, null: false
      add :last_name, :string, null: false
      add :email, :string, null: false
      add :state, :user_state, null: false

      timestamps()
    end

    create unique_index(:users, [:email])
  end
end
