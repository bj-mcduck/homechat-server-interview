defmodule ServerWeb.Middleware.Authenticate do
  @moduledoc """
  Middleware to require authentication for GraphQL operations.
  """

  @behaviour Absinthe.Middleware

  def call(resolution, _config) do
    case resolution.context do
      %{current_user: %{}} ->
        resolution

      _ ->
        resolution
        |> Absinthe.Resolution.put_result({:error, "Authentication required"})
    end
  end
end
