defmodule ServerWeb.Plugs.RateLimiter do
  @moduledoc """
  Rate limiting plug using Hammer to prevent abuse.

  Rate limits:
  - General GraphQL queries: 60 requests per minute per IP
  - GraphQL mutations: 10 requests per minute per IP
  - Login attempts: 5 attempts per 5 minutes per IP
  """

  import Plug.Conn
  import Phoenix.Controller, only: [json: 2]

  def init(opts), do: opts

  def call(conn, _opts) do
    # Skip rate limiting in test environment
    if Application.get_env(:server, :env) == :test do
      conn
    else
      apply_rate_limiting(conn)
    end
  end

  defp apply_rate_limiting(conn) do
    ip_address = get_ip_address(conn)

    cond do
      login_mutation?(conn) ->
        check_rate_limit(conn, "login:#{ip_address}", 5, :timer.minutes(5))

      mutation?(conn) ->
        check_rate_limit(conn, "mutation:#{ip_address}", 10, :timer.minutes(1))

      conn.path_info == ["graphql"] ->
        check_rate_limit(conn, "graphql:#{ip_address}", 60, :timer.minutes(1))

      true ->
        conn
    end
  end

  defp check_rate_limit(conn, key, limit, scale_ms) do
    case Hammer.check_rate(key, scale_ms, limit) do
      {:allow, count} ->
        conn
        |> put_resp_header("x-ratelimit-limit", to_string(limit))
        |> put_resp_header("x-ratelimit-remaining", to_string(limit - count))
        |> put_resp_header(
          "x-ratelimit-reset",
          to_string(System.system_time(:second) + div(scale_ms, 1000))
        )

      {:deny, _limit} ->
        conn
        |> put_status(:too_many_requests)
        |> put_resp_header("x-ratelimit-limit", to_string(limit))
        |> put_resp_header("x-ratelimit-remaining", "0")
        |> put_resp_header(
          "x-ratelimit-reset",
          to_string(System.system_time(:second) + div(scale_ms, 1000))
        )
        |> json(%{
          errors: [
            %{
              message: "Rate limit exceeded. Please try again later.",
              extensions: %{
                code: "RATE_LIMIT_EXCEEDED",
                retry_after_seconds: div(scale_ms, 1000)
              }
            }
          ]
        })
        |> halt()
    end
  end

  defp get_ip_address(conn) do
    conn.remote_ip
    |> :inet_parse.ntoa()
    |> to_string()
  end

  defp mutation?(conn) do
    case conn.body_params do
      %{"query" => query} when is_binary(query) ->
        String.contains?(query, "mutation")

      _ ->
        false
    end
  end

  defp login_mutation?(conn) do
    case conn.body_params do
      %{"query" => query} when is_binary(query) ->
        String.contains?(query, "mutation") and
          (String.contains?(query, "login") or String.contains?(query, "Login"))

      _ ->
        false
    end
  end
end
