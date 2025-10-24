defmodule ServerWeb.Schemas.Schema do
  @moduledoc false

  use Absinthe.Schema
  use Absinthe.Relay.Schema, :modern

  def subscription(config) do
    {:ok, Keyword.put(config, :pubsub, Server.PubSub)}
  end

  import_types(Absinthe.Type.Custom)
  import_types(ServerWeb.Schemas.ChatSchema)
  import_types(ServerWeb.Schemas.UserSchema)
  import_types(ServerWeb.Schemas.MessageSchema)

  query do
    import_fields(:chat_queries)
    import_fields(:user_queries)
    import_fields(:message_queries)
  end

  mutation do
    import_fields(:user_mutations)
    import_fields(:chat_mutations)
    import_fields(:message_mutations)
  end

  subscription do
    import_fields(:chat_subscriptions)
    import_fields(:message_subscriptions)
  end

  @impl Absinthe.Schema
  def context(ctx) do
    loader =
      Dataloader.new()
      |> Dataloader.add_source(Server.Accounts, Dataloader.Ecto.new(Server.Repo))
      |> Dataloader.add_source(Server.Chats, Dataloader.Ecto.new(Server.Repo))

    ctx = Map.put(ctx, :loader, loader)

    case Map.get(ctx, :current_user) do
      nil -> ctx
      user -> Map.put(ctx, :current_user, user)
    end
  end

  @impl Absinthe.Schema
  def middleware(middleware, _field, _object), do: middleware

  @impl Absinthe.Schema
  def plugins do
    [Absinthe.Middleware.Dataloader] ++ Absinthe.Plugin.defaults()
  end
end
