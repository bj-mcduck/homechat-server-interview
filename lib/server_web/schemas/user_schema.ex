defmodule ServerWeb.Schemas.UserSchema do
  @moduledoc false

  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  object :user do
    field :id, non_null(:id)
    field :first_name, non_null(:string)
    field :last_name, non_null(:string)
  end

  object :user_queries do
    field :user, non_null(:user) do
      resolve(fn _args, _info ->
        {:ok,
         %{
           id: "1",
           first_name: "Hello",
           last_name: "World"
         }}
      end)
    end
  end
end
