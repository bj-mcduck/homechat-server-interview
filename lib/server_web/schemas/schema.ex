defmodule ServerWeb.Schemas.Schema do
  @moduledoc false

  use Absinthe.Schema
  use Absinthe.Relay.Schema, :modern

  import_types(Absinthe.Type.Custom)
  import_types(ServerWeb.Schemas.ChatSchema)
  import_types(ServerWeb.Schemas.UserSchema)

  query do
    import_fields(:chat_queries)
    import_fields(:user_queries)
  end

  @impl Absinthe.Schema
  def context(ctx), do: ctx

  @impl Absinthe.Schema
  def middleware(middleware, _field, _object), do: middleware

  @impl Absinthe.Schema
  def plugins, do: [Absinthe.Middleware.Dataloader] ++ Absinthe.Plugin.defaults()
end
