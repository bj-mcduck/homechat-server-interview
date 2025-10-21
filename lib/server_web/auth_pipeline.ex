defmodule ServerWeb.AuthPipeline do
  @moduledoc """
  Guardian pipeline for GraphQL authentication
  """

  use Guardian.Plug.Pipeline

  plug Guardian.Plug.VerifyHeader, scheme: "Bearer"
  plug Guardian.Plug.EnsureAuthenticated
  plug Guardian.Plug.LoadResource, allow_blank: true
end
