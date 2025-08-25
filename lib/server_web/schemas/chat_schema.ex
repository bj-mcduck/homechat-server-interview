defmodule ServerWeb.Schemas.ChatSchema do
  @moduledoc false

  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  object :chat do
    field :id, non_null(:id)
  end

  object :chat_queries do
    field :chat, non_null(:chat) do
      resolve(fn _args, _info ->
        {:ok,
         %{
           id: "1"
         }}
      end)
    end
  end
end
