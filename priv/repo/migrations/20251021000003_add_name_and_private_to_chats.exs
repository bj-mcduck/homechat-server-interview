defmodule Server.Repo.Migrations.AddNameAndPrivateToChats do
  use Ecto.Migration

  def change do
    alter table(:chats) do
      add :name, :string, null: true
      add :private, :boolean, null: false, default: true
    end
  end
end
