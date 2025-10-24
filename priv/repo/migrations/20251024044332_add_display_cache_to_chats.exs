defmodule Server.Repo.Migrations.AddDisplayCacheToChats do
  use Ecto.Migration

  def change do
    alter table(:chats) do
      add :member_names, {:array, :string}, default: []
      add :is_direct, :boolean, default: false
    end

    create index(:chats, [:is_direct])
  end
end
