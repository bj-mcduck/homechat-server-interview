defmodule ServerWeb.Integration.ChatFlowTest do
  use ServerWeb.ConnCase, async: true

  alias Server.Factory
  alias Server.Guardian

  describe "complete chat lifecycle" do
    test "user creates group, adds members, sends messages, leaves chat" do
      alice = Factory.insert(:user, username: "alice", first_name: "Alice", last_name: "Smith")
      bob = Factory.insert(:user, username: "bob", first_name: "Bob", last_name: "Johnson")
      charlie = Factory.insert(:user, username: "charlie", first_name: "Charlie", last_name: "Brown")

      # Step 1: Alice creates a group chat
      {:ok, token, _} = Guardian.encode_and_sign(alice)

      create_mutation = """
      mutation CreateGroupChat($name: String!, $participantIds: [String!]!) {
        createGroupChat(name: $name, participantIds: $participantIds) {
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
      |> post("/graphql", %{
        query: create_mutation,
        variables: %{
          name: "Engineering Team",
          participantIds: [bob.nanoid]
        }
      })

      assert %{"data" => %{"createGroupChat" => chat}} = json_response(response, 200)
      assert chat["name"] == "Engineering Team"
      assert chat["private"] == true
      assert length(chat["members"]) == 2
      assert Enum.any?(chat["members"], &(&1["username"] == "alice"))
      assert Enum.any?(chat["members"], &(&1["username"] == "bob"))

      # Step 2: Alice adds Charlie to the chat
      add_member_mutation = """
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
        query: add_member_mutation,
        variables: %{
          chatId: chat["id"],
          userId: charlie.nanoid
        }
      })

      assert %{"data" => %{"addChatMember" => updated_chat}} = json_response(response, 200)
      assert length(updated_chat["members"]) == 3
      assert Enum.any?(updated_chat["members"], &(&1["username"] == "charlie"))

      # Step 3: Alice sends a message
      send_message_mutation = """
      mutation SendMessage($chatId: String!, $content: String!) {
        sendMessage(chatId: $chatId, content: $content) {
          id
          content
          user {
            id
            username
            firstName
            lastName
          }
          chat {
            id
            name
          }
          insertedAt
        }
      }
      """

      response = build_conn()
      |> put_req_header("authorization", "Bearer #{token}")
      |> post("/graphql", %{
        query: send_message_mutation,
        variables: %{
          chatId: chat["id"],
          content: "Welcome to the Engineering Team chat!"
        }
      })

      assert %{"data" => %{"sendMessage" => message}} = json_response(response, 200)
      assert message["content"] == "Welcome to the Engineering Team chat!"
      assert message["user"]["username"] == "alice"

      # Step 4: Bob sends a message
      {:ok, bob_token, _} = Guardian.encode_and_sign(bob)

      response = build_conn()
      |> put_req_header("authorization", "Bearer #{bob_token}")
      |> post("/graphql", %{
        query: send_message_mutation,
        variables: %{
          chatId: chat["id"],
          content: "Thanks Alice! Excited to be here."
        }
      })

      assert %{"data" => %{"sendMessage" => bob_message}} = json_response(response, 200)
      assert bob_message["content"] == "Thanks Alice! Excited to be here."
      assert bob_message["user"]["username"] == "bob"

      # Step 5: Alice leaves the chat
      leave_mutation = """
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
      |> post("/graphql", %{
        query: leave_mutation,
        variables: %{chatId: chat["id"]}
      })

      assert %{"data" => %{"leaveChat" => final_chat}} = json_response(response, 200)
      assert length(final_chat["members"]) == 2
      refute Enum.any?(final_chat["members"], &(&1["username"] == "alice"))
      assert Enum.any?(final_chat["members"], &(&1["username"] == "bob"))
      assert Enum.any?(final_chat["members"], &(&1["username"] == "charlie"))
    end

    test "user creates DM, sends messages, cannot leave" do
      alice = Factory.insert(:user, username: "alice", first_name: "Alice", last_name: "Smith")
      bob = Factory.insert(:user, username: "bob", first_name: "Bob", last_name: "Johnson")

      # Step 1: Alice creates a direct message with Bob
      {:ok, token, _} = Guardian.encode_and_sign(alice)

      create_dm_mutation = """
      mutation CreateDirectChat($userId: String!) {
        createDirectChat(userId: $userId) {
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
      |> post("/graphql", %{
        query: create_dm_mutation,
        variables: %{userId: bob.nanoid}
      })

      assert %{"data" => %{"createDirectChat" => chat}} = json_response(response, 200)
      assert chat["name"] == nil  # Direct messages are unnamed
      assert chat["private"] == true
      assert length(chat["members"]) == 2

      # Step 2: Alice sends a message
      send_message_mutation = """
      mutation SendMessage($chatId: String!, $content: String!) {
        sendMessage(chatId: $chatId, content: $content) {
          id
          content
          user {
            id
            username
          }
        }
      }
      """

      response = build_conn()
      |> put_req_header("authorization", "Bearer #{token}")
      |> post("/graphql", %{
        query: send_message_mutation,
        variables: %{
          chatId: chat["id"],
          content: "Hi Bob! How are you?"
        }
      })

      assert %{"data" => %{"sendMessage" => message}} = json_response(response, 200)
      assert message["content"] == "Hi Bob! How are you?"

      # Step 3: Bob responds
      {:ok, bob_token, _} = Guardian.encode_and_sign(bob)

      response = build_conn()
      |> put_req_header("authorization", "Bearer #{bob_token}")
      |> post("/graphql", %{
        query: send_message_mutation,
        variables: %{
          chatId: chat["id"],
          content: "Hi Alice! I'm doing great, thanks for asking."
        }
      })

      assert %{"data" => %{"sendMessage" => bob_message}} = json_response(response, 200)
      assert bob_message["content"] == "Hi Alice! I'm doing great, thanks for asking."

      # Step 4: Alice tries to leave the direct message (should fail)
      leave_mutation = """
      mutation LeaveChat($chatId: String!) {
        leaveChat(chatId: $chatId) {
          id
        }
      }
      """

      response = build_conn()
      |> put_req_header("authorization", "Bearer #{token}")
      |> post("/graphql", %{
        query: leave_mutation,
        variables: %{chatId: chat["id"]}
      })

      assert %{"errors" => [%{"message" => "Cannot leave direct message chats"}]} = json_response(response, 200)
    end

    test "owner updates privacy, deletes chat" do
      alice = Factory.insert(:user, username: "alice", first_name: "Alice", last_name: "Smith")
      bob = Factory.insert(:user, username: "bob", first_name: "Bob", last_name: "Johnson")

      # Step 1: Alice creates a private group chat
      {:ok, token, _} = Guardian.encode_and_sign(alice)

      create_mutation = """
      mutation CreateGroupChat($name: String!, $participantIds: [String!]!) {
        createGroupChat(name: $name, participantIds: $participantIds) {
          id
          name
          private
        }
      }
      """

      response = build_conn()
      |> put_req_header("authorization", "Bearer #{token}")
      |> post("/graphql", %{
        query: create_mutation,
        variables: %{
          name: "Private Team Chat",
          participantIds: [bob.nanoid]
        }
      })

      assert %{"data" => %{"createGroupChat" => chat}} = json_response(response, 200)
      assert chat["private"] == true

      # Step 2: Alice updates privacy to make it public
      update_privacy_mutation = """
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
        query: update_privacy_mutation,
        variables: %{
          chatId: chat["id"],
          private: false
        }
      })

      assert %{"data" => %{"updateChatPrivacy" => updated_chat}} = json_response(response, 200)
      assert updated_chat["private"] == false

      # Step 3: Bob tries to update privacy (should fail - not owner)
      {:ok, bob_token, _} = Guardian.encode_and_sign(bob)

      response = build_conn()
      |> put_req_header("authorization", "Bearer #{bob_token}")
      |> post("/graphql", %{
        query: update_privacy_mutation,
        variables: %{
          chatId: chat["id"],
          private: true
        }
      })

      assert %{"errors" => [%{"message" => "Only chat owners can perform this action"}]} = json_response(response, 200)
    end
  end

  describe "authorization flow" do
    test "non-member cannot view or send messages" do
      alice = Factory.insert(:user, username: "alice")
      bob = Factory.insert(:user, username: "bob")
      charlie = Factory.insert(:user, username: "charlie")
      {:ok, chat} = Server.Chats.create_direct_chat(alice.id, bob.id)

      # Charlie tries to view the chat
      {:ok, charlie_token, _} = Guardian.encode_and_sign(charlie)

      view_chat_query = """
      query GetChat($id: String!) {
        chat(id: $id) {
          id
          name
        }
      }
      """

      response = build_conn()
      |> put_req_header("authorization", "Bearer #{charlie_token}")
      |> post("/graphql", %{
        query: view_chat_query,
        variables: %{id: chat.nanoid}
      })

      assert %{"errors" => [%{"message" => "You are not a member of this chat"}]} = json_response(response, 200)

      # Charlie tries to send a message
      send_message_mutation = """
      mutation SendMessage($chatId: String!, $content: String!) {
        sendMessage(chatId: $chatId, content: $content) {
          id
          content
        }
      }
      """

      response = build_conn()
      |> put_req_header("authorization", "Bearer #{charlie_token}")
      |> post("/graphql", %{
        query: send_message_mutation,
        variables: %{
          chatId: chat.nanoid,
          content: "Hello!"
        }
      })

      assert %{"errors" => [%{"message" => "You are not a member of this chat"}]} = json_response(response, 200)
    end

    test "member can view and send but not update" do
      alice = Factory.insert(:user, username: "alice")
      bob = Factory.insert(:user, username: "bob")
      {:ok, chat} = Server.Chats.create_group_chat(
        %{name: "Test Group", private: true, state: :active},
        alice.id,
        [bob.id]
      )

      # Bob (member) can view the chat
      {:ok, bob_token, _} = Guardian.encode_and_sign(bob)

      view_chat_query = """
      query GetChat($id: String!) {
        chat(id: $id) {
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
      |> put_req_header("authorization", "Bearer #{bob_token}")
      |> post("/graphql", %{
        query: view_chat_query,
        variables: %{id: chat.nanoid}
      })

      assert %{"data" => %{"chat" => chat_data}} = json_response(response, 200)
      assert chat_data["name"] == "Test Group"

      # Bob can send messages
      send_message_mutation = """
      mutation SendMessage($chatId: String!, $content: String!) {
        sendMessage(chatId: $chatId, content: $content) {
          id
          content
        }
      }
      """

      response = build_conn()
      |> put_req_header("authorization", "Bearer #{bob_token}")
      |> post("/graphql", %{
        query: send_message_mutation,
        variables: %{
          chatId: chat.nanoid,
          content: "Hello from Bob!"
        }
      })

      assert %{"data" => %{"sendMessage" => message}} = json_response(response, 200)
      assert message["content"] == "Hello from Bob!"

      # Bob cannot update chat settings
      update_privacy_mutation = """
      mutation UpdateChatPrivacy($chatId: String!, $private: Boolean!) {
        updateChatPrivacy(chatId: $chatId, private: $private) {
          id
        }
      }
      """

      response = build_conn()
      |> put_req_header("authorization", "Bearer #{bob_token}")
      |> post("/graphql", %{
        query: update_privacy_mutation,
        variables: %{
          chatId: chat.nanoid,
          private: false
        }
      })

      assert %{"errors" => [%{"message" => "Only chat owners can perform this action"}]} = json_response(response, 200)
    end

    test "owner has full permissions" do
      alice = Factory.insert(:user, username: "alice")
      bob = Factory.insert(:user, username: "bob")
      charlie = Factory.insert(:user, username: "charlie")
      {:ok, chat} = Server.Chats.create_group_chat(
        %{name: "Test Group", private: true, state: :active},
        alice.id,
        [bob.id]
      )

      {:ok, token, _} = Guardian.encode_and_sign(alice)

      # Alice can view the chat
      view_chat_query = """
      query GetChat($id: String!) {
        chat(id: $id) {
          id
          name
        }
      }
      """

      response = build_conn()
      |> put_req_header("authorization", "Bearer #{token}")
      |> post("/graphql", %{
        query: view_chat_query,
        variables: %{id: chat.nanoid}
      })

      assert %{"data" => %{"chat" => chat_data}} = json_response(response, 200)

      # Alice can send messages
      send_message_mutation = """
      mutation SendMessage($chatId: String!, $content: String!) {
        sendMessage(chatId: $chatId, content: $content) {
          id
          content
        }
      }
      """

      response = build_conn()
      |> put_req_header("authorization", "Bearer #{token}")
      |> post("/graphql", %{
        query: send_message_mutation,
        variables: %{
          chatId: chat.nanoid,
          content: "Hello from Alice!"
        }
      })

      assert %{"data" => %{"sendMessage" => message}} = json_response(response, 200)

      # Alice can add members
      add_member_mutation = """
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
        query: add_member_mutation,
        variables: %{
          chatId: chat.nanoid,
          userId: charlie.nanoid
        }
      })

      assert %{"data" => %{"addChatMember" => updated_chat}} = json_response(response, 200)
      assert length(updated_chat["members"]) == 3

      # Alice can update privacy
      update_privacy_mutation = """
      mutation UpdateChatPrivacy($chatId: String!, $private: Boolean!) {
        updateChatPrivacy(chatId: $chatId, private: $private) {
          id
          private
        }
      }
      """

      response = build_conn()
      |> put_req_header("authorization", "Bearer #{token}")
      |> post("/graphql", %{
        query: update_privacy_mutation,
        variables: %{
          chatId: chat.nanoid,
          private: false
        }
      })

      assert %{"data" => %{"updateChatPrivacy" => updated_chat}} = json_response(response, 200)
      assert updated_chat["private"] == false

      # Alice can leave the chat
      leave_mutation = """
      mutation LeaveChat($chatId: String!) {
        leaveChat(chatId: $chatId) {
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
        query: leave_mutation,
        variables: %{chatId: chat.nanoid}
      })

      assert %{"data" => %{"leaveChat" => final_chat}} = json_response(response, 200)
      refute Enum.any?(final_chat["members"], &(&1["username"] == "alice"))
    end
  end
end
