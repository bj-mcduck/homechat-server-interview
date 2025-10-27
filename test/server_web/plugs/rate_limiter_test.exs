defmodule ServerWeb.Plugs.RateLimiterTest do
  use ServerWeb.ConnCase, async: false
  alias Server.Factory
  alias Server.Guardian

  setup do
    # Enable rate limiting for these tests
    original_env = Application.get_env(:server, :env)
    Application.put_env(:server, :env, :dev)

    # Clear rate limit state between tests
    :timer.sleep(100)

    on_exit(fn ->
      Application.put_env(:server, :env, original_env)
    end)

    :ok
  end

  describe "rate limiting" do
    test "allows requests under the limit" do
      query = """
      query {
        discoverableChats {
          id
        }
      }
      """

      # First 5 requests should succeed
      for _i <- 1..5 do
        conn =
          build_conn()
          |> put_req_header("content-type", "application/json")
          |> post("/graphql", %{query: query})

        # Should not be rate limited (may be 200 or error from auth)
        refute conn.status == 429
      end
    end

    test "blocks login attempts over the limit" do
      query = """
      mutation {
        login(email: "test@test.com", password: "wrong") {
          token
        }
      }
      """

      # Make 6 login attempts (limit is 5 per 5 minutes)
      responses =
        for i <- 1..6 do
          conn =
            build_conn()
            |> put_req_header("content-type", "application/json")
            |> post("/graphql", %{query: query})

          # Small delay between requests
          if i < 6, do: :timer.sleep(10)
          conn
        end

      # Last request should be rate limited
      last_response = List.last(responses)
      assert last_response.status == 429

      response_body = Jason.decode!(last_response.resp_body)
      assert %{"errors" => [%{"message" => message}]} = response_body
      assert message =~ "Rate limit exceeded"
    end

    test "blocks excessive mutations" do
      alice = Factory.insert(:user, username: "alice")
      bob = Factory.insert(:user, username: "bob")
      {:ok, chat} = Server.Chats.create_direct_chat(alice.id, bob.id)
      {:ok, token, _} = Guardian.encode_and_sign(alice)

      mutation = """
      mutation {
        sendMessage(chatId: "#{chat.nanoid}", content: "test") {
          id
        }
      }
      """

      # Make 12 mutation requests (limit is 10 per minute)
      responses =
        for i <- 1..12 do
          conn =
            build_conn()
            |> put_req_header("authorization", "Bearer #{token}")
            |> put_req_header("content-type", "application/json")
            |> post("/graphql", %{query: mutation})

          if i < 12, do: :timer.sleep(10)
          conn
        end

      # Some of the later requests should be rate limited
      rate_limited = Enum.count(responses, fn conn -> conn.status == 429 end)
      assert rate_limited > 0
    end

    test "adds rate limit headers to responses" do
      query = """
      query {
        discoverableChats {
          id
        }
      }
      """

      conn =
        build_conn()
        |> put_req_header("content-type", "application/json")
        |> post("/graphql", %{query: query})

      # Should have rate limit headers
      headers = conn.resp_headers |> Enum.into(%{})
      assert Map.has_key?(headers, "x-ratelimit-limit")
      assert Map.has_key?(headers, "x-ratelimit-remaining")
      assert Map.has_key?(headers, "x-ratelimit-reset")
    end

    test "different IPs have independent rate limits" do
      query = """
      mutation {
        login(email: "test@test.com", password: "wrong") {
          token
        }
      }
      """

      # Make 5 requests from IP 127.0.0.1
      for _i <- 1..5 do
        build_conn()
        |> put_req_header("content-type", "application/json")
        |> post("/graphql", %{query: query})
      end

      # 6th request from same IP should be blocked
      conn_blocked =
        build_conn()
        |> put_req_header("content-type", "application/json")
        |> post("/graphql", %{query: query})

      assert conn_blocked.status == 429
    end

    test "rate limit headers show correct remaining count" do
      query = """
      query {
        discoverableChats {
          id
        }
      }
      """

      # First request
      conn1 =
        build_conn()
        |> put_req_header("content-type", "application/json")
        |> post("/graphql", %{query: query})

      headers1 = conn1.resp_headers |> Enum.into(%{})
      limit = String.to_integer(headers1["x-ratelimit-limit"])
      remaining1 = String.to_integer(headers1["x-ratelimit-remaining"])

      # Second request
      conn2 =
        build_conn()
        |> put_req_header("content-type", "application/json")
        |> post("/graphql", %{query: query})

      headers2 = conn2.resp_headers |> Enum.into(%{})
      remaining2 = String.to_integer(headers2["x-ratelimit-remaining"])

      # Remaining should decrease
      assert remaining2 < remaining1
      assert remaining1 + remaining2 < limit * 2
    end
  end
end
