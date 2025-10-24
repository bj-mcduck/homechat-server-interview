defmodule ServerWeb.Schemas.ChatSchemaTest do
  use ServerWeb.ConnCase, async: true

  alias Server.Factory
  alias Server.Guardian

  describe "discoverableChats query" do
    test "returns user's chats and public chats when authenticated" do
      alice = Factory.insert(:user, username: "alice")
      bob = Factory.insert(:user, username: "bob")

      # Alice's direct chat with Bob
      {:ok, alice_bob_dm} = Server.Chats.create_direct_chat(alice.id, bob.id)

      # Alice's group chat
      {:ok, alice_group} = Server.Chats.create_group_chat(
        %{name: "Alice's Group", private: true, state: :active},
        alice.id,
        [bob.id]
      )

      # Public chat (Alice is not a member)
      public_chat = Factory.insert(:chat, name: "Public Chat", private: false, state: :active)

      # Private chat Alice is not in
      Factory.insert(:chat, name: "Private Chat", private: true, state: :active)

      # Create JWT token for Alice
      {:ok, token, _} = Guardian.encode_and_sign(alice)

      query = """
      query {
        discoverableChats {
          id
          name
          displayName
          private
          members {
            id
            username
            firstName
            lastName
          }
        }
      }
      """

      response = build_conn()
      |> put_req_header("authorization", "Bearer #{token}")
      |> post("/graphql", %{query: query})

      assert %{"data" => %{"discoverableChats" => chats}} = json_response(response, 200)
      assert length(chats) == 3

      # Should include Alice's direct chat
      assert Enum.any?(chats, &(&1["id"] == alice_bob_dm.nanoid))

      # Should include Alice's group chat
      assert Enum.any?(chats, &(&1["id"] == alice_group.nanoid))

      # Should include public chat
      assert Enum.any?(chats, &(&1["id"] == public_chat.nanoid))

      # Should not include private chat Alice is not in
      refute Enum.any?(chats, &(&1["name"] == "Private Chat"))
    end

    test "requires authentication" do
      query = """
      query {
        discoverableChats {
          id
          name
        }
      }
      """

      response = build_conn()
      |> post("/graphql", %{query: query})

      assert %{"errors" => [%{"message" => "Authentication required"}]} = json_response(response, 200)
    end
  end

  describe "chat query" do
    test "returns chat with members when user is a member" do
      alice = Factory.insert(:user, username: "alice")
      bob = Factory.insert(:user, username: "bob")
      {:ok, chat} = Server.Chats.create_direct_chat(alice.id, bob.id)

      {:ok, token, _} = Guardian.encode_and_sign(alice)

      query = """
      query GetChat($id: String!) {
        chat(id: $id) {
          id
          name
          displayName
          private
          members {
            id
            username
            firstName
            lastName
          }
        }
      }
      """

      response = build_conn()
      |> put_req_header("authorization", "Bearer #{token}")
      |> post("/graphql", %{query: query, variables: %{id: chat.nanoid}})

      assert %{"data" => %{"chat" => chat_data}} = json_response(response, 200)
      assert chat_data["id"] == chat.nanoid
      assert length(chat_data["members"]) == 2
    end

    test "returns authorization error when user is not a member" do
      alice = Factory.insert(:user, username: "alice")
      bob = Factory.insert(:user, username: "bob")
      charlie = Factory.insert(:user, username: "charlie")
      {:ok, chat} = Server.Chats.create_direct_chat(alice.id, bob.id)

      {:ok, token, _} = Guardian.encode_and_sign(charlie)

      query = """
      query GetChat($id: String!) {
        chat(id: $id) {
          id
          name
        }
      }
      """

      response = build_conn()
      |> put_req_header("authorization", "Bearer #{token}")
      |> post("/graphql", %{query: query, variables: %{id: chat.nanoid}})

      assert %{"errors" => [%{"message" => "You are not a member of this chat"}]} = json_response(response, 200)
    end
  end

  describe "createDirectChat mutation" do
    test "creates direct chat between two users" do
      alice = Factory.insert(:user, username: "alice")
      bob = Factory.insert(:user, username: "bob")

      {:ok, token, _} = Guardian.encode_and_sign(alice)

      mutation = """
      mutation CreateDirectChat($userId: String!) {
        createDirectChat(userId: $userId) {
          id
          name
          displayName
          private
          members {
            id
            username
          }
        }
      }
      """

      response = build_conn()
      |> put_req_header("authorization", "Bearer #{token}")
      |> post("/graphql", %{query: mutation, variables: %{userId: bob.nanoid}})

      assert %{"data" => %{"createDirectChat" => chat}} = json_response(response, 200)
      assert chat["private"] == true
      assert length(chat["members"]) == 2
    end

    test "returns existing direct chat if it already exists" do
      alice = Factory.insert(:user, username: "alice")
      bob = Factory.insert(:user, username: "bob")
      {:ok, existing_chat} = Server.Chats.create_direct_chat(alice.id, bob.id)

      {:ok, token, _} = Guardian.encode_and_sign(alice)

      mutation = """
      mutation CreateDirectChat($userId: String!) {
        createDirectChat(userId: $userId) {
          id
        }
      }
      """

      response = build_conn()
      |> put_req_header("authorization", "Bearer #{token}")
      |> post("/graphql", %{query: mutation, variables: %{userId: bob.nanoid}})

      assert %{"data" => %{"createDirectChat" => chat}} = json_response(response, 200)
      assert chat["id"] == existing_chat.nanoid
    end
  end

  describe "createGroupChat mutation" do
    test "creates group chat with members" do
      alice = Factory.insert(:user, username: "alice")
      bob = Factory.insert(:user, username: "bob")
      charlie = Factory.insert(:user, username: "charlie")

      {:ok, token, _} = Guardian.encode_and_sign(alice)

      mutation = """
      mutation CreateGroupChat($name: String!, $participantIds: [String!]!) {
        createGroupChat(name: $name, participantIds: $participantIds) {
          id
          name
          displayName
          private
          members {
            id
            username
          }
        }
      }
      """

      response = build_conn()
      |> put_req_header("authorization", "Bearer #{token}")
      |> post("/graphql", %{
        query: mutation,
        variables: %{
          name: "Test Group",
          participantIds: [bob.nanoid, charlie.nanoid]
        }
      })

      assert %{"data" => %{"createGroupChat" => chat}} = json_response(response, 200)
      assert chat["name"] == "Test Group"
      assert chat["private"] == true
      assert length(chat["members"]) == 3
    end

    test "returns error when name is already taken" do
      alice = Factory.insert(:user, username: "alice")
      bob = Factory.insert(:user, username: "bob")
      charlie = Factory.insert(:user, username: "charlie")

      # Create existing chat with same name
      Server.Chats.create_group_chat(
        %{name: "Test Group", private: true, state: :active},
        alice.id,
        [bob.id]
      )

      {:ok, token, _} = Guardian.encode_and_sign(charlie)

      mutation = """
      mutation CreateGroupChat($name: String!, $participantIds: [String!]!) {
        createGroupChat(name: $name, participantIds: $participantIds) {
          id
          name
        }
      }
      """

      response = build_conn()
      |> put_req_header("authorization", "Bearer #{token}")
      |> post("/graphql", %{
        query: mutation,
        variables: %{
          name: "Test Group",
          participantIds: [alice.nanoid]
        }
      })

      assert %{"errors" => [%{"message" => message}]} = json_response(response, 200)
      assert message =~ "Chat name is already taken"
    end
  end

  describe "createOrFindGroupChat mutation" do
    test "creates new unnamed group with participants" do
      alice = Factory.insert(:user, username: "alice")
      bob = Factory.insert(:user, username: "bob")
      charlie = Factory.insert(:user, username: "charlie")

      {:ok, token, _} = Guardian.encode_and_sign(alice)

      mutation = """
      mutation CreateOrFindGroupChat($participantIds: [String!]!) {
        createOrFindGroupChat(participantIds: $participantIds) {
          id
          name
          displayName
          private
          members {
            id
            username
          }
        }
      }
      """

      response = build_conn()
      |> put_req_header("authorization", "Bearer #{token}")
      |> post("/graphql", %{
        query: mutation,
        variables: %{participantIds: [bob.nanoid, charlie.nanoid]}
      })

      assert %{"data" => %{"createOrFindGroupChat" => chat}} = json_response(response, 200)
      assert chat["name"] == nil
      assert chat["private"] == true
      assert length(chat["members"]) == 3
    end

    test "returns existing unnamed group with same participants" do
      alice = Factory.insert(:user, username: "alice")
      bob = Factory.insert(:user, username: "bob")
      charlie = Factory.insert(:user, username: "charlie")

      # Create existing unnamed group
      {:ok, existing_chat} = Server.Chats.create_or_find_group_chat(alice.id, [bob.id, charlie.id])

      {:ok, token, _} = Guardian.encode_and_sign(alice)

      mutation = """
      mutation CreateOrFindGroupChat($participantIds: [String!]!) {
        createOrFindGroupChat(participantIds: $participantIds) {
          id
        }
      }
      """

      response = build_conn()
      |> put_req_header("authorization", "Bearer #{token}")
      |> post("/graphql", %{
        query: mutation,
        variables: %{participantIds: [bob.nanoid, charlie.nanoid]}
      })

      assert %{"data" => %{"createOrFindGroupChat" => chat}} = json_response(response, 200)
      assert chat["id"] == existing_chat.nanoid
    end
  end

  describe "addChatMember mutation" do
    test "adds member to chat when user is a member" do
      alice = Factory.insert(:user, username: "alice")
      bob = Factory.insert(:user, username: "bob")
      charlie = Factory.insert(:user, username: "charlie")
      {:ok, chat} = Server.Chats.create_group_chat(
        %{name: "Test Group", private: true, state: :active},
        alice.id,
        [bob.id]
      )

      {:ok, token, _} = Guardian.encode_and_sign(alice)

      mutation = """
      mutation AddChatMember($chatId: String!, $userId: String!) {
        addChatMember(chatId: $chatId, userId: $userId) {
          id
          members {
            id
            username
          }
        }
      }
      """

      response = build_conn()
      |> put_req_header("authorization", "Bearer #{token}")
      |> post("/graphql", %{
        query: mutation,
        variables: %{chatId: chat.nanoid, userId: charlie.nanoid}
      })

      assert %{"data" => %{"addChatMember" => updated_chat}} = json_response(response, 200)
      assert length(updated_chat["members"]) == 3
      assert Enum.any?(updated_chat["members"], &(&1["username"] == "charlie"))
    end

    test "returns authorization error when user is not a member" do
      alice = Factory.insert(:user, username: "alice")
      bob = Factory.insert(:user, username: "bob")
      charlie = Factory.insert(:user, username: "charlie")
      dave = Factory.insert(:user, username: "dave")
      {:ok, chat} = Server.Chats.create_group_chat(
        %{name: "Test Group", private: true, state: :active},
        alice.id,
        [bob.id]
      )

      {:ok, token, _} = Guardian.encode_and_sign(charlie)

      mutation = """
      mutation AddChatMember($chatId: String!, $userId: String!) {
        addChatMember(chatId: $chatId, userId: $userId) {
          id
        }
      }
      """

      response = build_conn()
      |> put_req_header("authorization", "Bearer #{token}")
      |> post("/graphql", %{
        query: mutation,
        variables: %{chatId: chat.nanoid, userId: dave.nanoid}
      })

      assert %{"errors" => [%{"message" => "You are not a member of this chat"}]} = json_response(response, 200)
    end
  end

  describe "leaveChat mutation" do
    test "allows member to leave named chat" do
      alice = Factory.insert(:user, username: "alice")
      bob = Factory.insert(:user, username: "bob")
      {:ok, chat} = Server.Chats.create_group_chat(
        %{name: "Test Group", private: true, state: :active},
        alice.id,
        [bob.id]
      )

      {:ok, token, _} = Guardian.encode_and_sign(alice)

      mutation = """
      mutation LeaveChat($chatId: String!) {
        leaveChat(chatId: $chatId) {
          id
          name
          members {
            id
            username
          }
        }
      }
      """

      response = build_conn()
      |> put_req_header("authorization", "Bearer #{token}")
      |> post("/graphql", %{query: mutation, variables: %{chatId: chat.nanoid}})

      assert %{"data" => %{"leaveChat" => updated_chat}} = json_response(response, 200)
      assert length(updated_chat["members"]) == 1
      refute Enum.any?(updated_chat["members"], &(&1["username"] == "alice"))
    end

    test "returns error when trying to leave unnamed chat" do
      alice = Factory.insert(:user, username: "alice")
      bob = Factory.insert(:user, username: "bob")
      {:ok, chat} = Server.Chats.create_direct_chat(alice.id, bob.id)

      {:ok, token, _} = Guardian.encode_and_sign(alice)

      mutation = """
      mutation LeaveChat($chatId: String!) {
        leaveChat(chatId: $chatId) {
          id
        }
      }
      """

      response = build_conn()
      |> put_req_header("authorization", "Bearer #{token}")
      |> post("/graphql", %{query: mutation, variables: %{chatId: chat.nanoid}})

      assert %{"errors" => [%{"message" => "Cannot leave direct message chats"}]} = json_response(response, 200)
    end

    test "returns authorization error when user is not a member" do
      alice = Factory.insert(:user, username: "alice")
      bob = Factory.insert(:user, username: "bob")
      charlie = Factory.insert(:user, username: "charlie")
      {:ok, chat} = Server.Chats.create_group_chat(
        %{name: "Test Group", private: true, state: :active},
        alice.id,
        [bob.id]
      )

      {:ok, token, _} = Guardian.encode_and_sign(charlie)

      mutation = """
      mutation LeaveChat($chatId: String!) {
        leaveChat(chatId: $chatId) {
          id
        }
      }
      """

      response = build_conn()
      |> put_req_header("authorization", "Bearer #{token}")
      |> post("/graphql", %{query: mutation, variables: %{chatId: chat.nanoid}})

      assert %{"errors" => [%{"message" => "You are not a member of this chat"}]} = json_response(response, 200)
    end
  end

  describe "updateChatPrivacy mutation" do
    test "allows owner to update privacy setting" do
      alice = Factory.insert(:user, username: "alice")
      bob = Factory.insert(:user, username: "bob")
      {:ok, chat} = Server.Chats.create_group_chat(
        %{name: "Test Group", private: true, state: :active},
        alice.id,
        [bob.id]
      )

      {:ok, token, _} = Guardian.encode_and_sign(alice)

      mutation = """
      mutation UpdateChatPrivacy($chatId: String!, $private: Boolean!) {
        updateChatPrivacy(chatId: $chatId, private: $private) {
          id
          name
          private
        }
      }
      """

      response = build_conn()
      |> put_req_header("authorization", "Bearer #{token}")
      |> post("/graphql", %{
        query: mutation,
        variables: %{chatId: chat.nanoid, private: false}
      })

      assert %{"data" => %{"updateChatPrivacy" => updated_chat}} = json_response(response, 200)
      assert updated_chat["private"] == false
    end

    test "denies member from updating privacy" do
      alice = Factory.insert(:user, username: "alice")
      bob = Factory.insert(:user, username: "bob")
      {:ok, chat} = Server.Chats.create_group_chat(
        %{name: "Test Group", private: true, state: :active},
        alice.id,
        [bob.id]
      )

      {:ok, token, _} = Guardian.encode_and_sign(bob)

      mutation = """
      mutation UpdateChatPrivacy($chatId: String!, $private: Boolean!) {
        updateChatPrivacy(chatId: $chatId, private: $private) {
          id
        }
      }
      """

      response = build_conn()
      |> put_req_header("authorization", "Bearer #{token}")
      |> post("/graphql", %{
        query: mutation,
        variables: %{chatId: chat.nanoid, private: false}
      })

      assert %{"errors" => [%{"message" => "Only chat owners can perform this action"}]} = json_response(response, 200)
    end
  end
end
