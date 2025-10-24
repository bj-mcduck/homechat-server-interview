defmodule ServerWeb.Schemas.PresenceSchema do
  @moduledoc false

  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  alias ServerWeb.Middleware.Authenticate

  object :user_presence do
    field :user_id, non_null(:string)
    field :username, non_null(:string)
    field :full_name, non_null(:string)
    field :status, non_null(:string)
    field :last_seen, non_null(:string)
    field :device_type, non_null(:string)
  end

  object :presence_state do
    field :online_users, non_null(list_of(non_null(:user_presence)))
    field :timestamp, non_null(:string)
  end

  object :presence_queries do
    field :online_users, list_of(:user_presence) do
      middleware(Authenticate)

      resolve(fn _args, _info ->
        # Get current presence state from Phoenix.Presence
        # This is a simplified version - in production you'd want to
        # get this from the presence system
        {:ok, []}
      end)
    end
  end

  object :presence_subscriptions do
    field :presence_updates, :presence_state do
      middleware(Authenticate)

      config(fn _args, _info ->
        {:ok, topic: "presence:global"}
      end)
    end
  end
end
