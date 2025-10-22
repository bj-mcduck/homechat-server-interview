defmodule ServerWeb.AuthContext do
  @moduledoc """
  Builds authentication context from the connection.

  Can be used for both GraphQL and REST API authentication.
  Extracts JWT token from Authorization header and loads the current user.
  """

  @behaviour Plug

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    context = build_context(conn)
    Absinthe.Plug.put_options(conn, context: context)
  end

  defp build_context(conn) do
    with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
         {:ok, user} <- Server.Guardian.verify_token(token) do
      %{current_user: user}
    else
      _ -> %{}
    end
  end
end
