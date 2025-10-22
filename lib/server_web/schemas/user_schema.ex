defmodule ServerWeb.Schemas.UserSchema do
  @moduledoc false

  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  alias Server.{Accounts, Guardian}
  alias ServerWeb.Middleware.Authenticate

  object :user do
    # Expose nanoid as the public ID, hide internal integer ID
    field :id, non_null(:string) do
      resolve(fn user, _, _ -> {:ok, user.nanoid} end)
    end
    field :email, non_null(:string)
    field :username, non_null(:string)
    field :first_name, non_null(:string)
    field :last_name, non_null(:string)
    field :state, non_null(:string)
    field :inserted_at, non_null(:string)
    field :updated_at, non_null(:string)
  end

  object :auth_payload do
    field :token, non_null(:string)
    field :user, non_null(:user)
  end

  object :user_queries do
    field :me, :user do
      middleware(Authenticate)
      resolve(fn _args, %{context: %{current_user: user}} ->
        {:ok, user}
      end)
    end

    field :users, list_of(:user) do
      arg :limit, :integer, default_value: 10
      arg :offset, :integer, default_value: 0
      arg :exclude_self, :boolean, default_value: false
      middleware(Authenticate)
      resolve(fn args, %{context: %{current_user: current_user}} ->
        users = Accounts.list_users()

        # Filter out current user if requested
        users = if args.exclude_self do
          Enum.reject(users, &(&1.id == current_user.id))
        else
          users
        end

        # Apply pagination
        users = users
        |> Enum.drop(args.offset)
        |> Enum.take(args.limit)

        {:ok, users}
      end)
    end

    field :search_users, list_of(:user) do
      arg :query, non_null(:string)
      middleware(Authenticate)
      resolve(fn %{query: query}, %{context: %{current_user: user}} ->
        users = Accounts.search_users(query, user.id)
        {:ok, users}
      end)
    end
  end

  object :user_mutations do
    field :register, :auth_payload do
      arg :email, non_null(:string)
      arg :username, non_null(:string)
      arg :password, non_null(:string)
      arg :first_name, non_null(:string)
      arg :last_name, non_null(:string)

      resolve(fn args, _info ->
        case Accounts.create_user(args) do
          {:ok, user} ->
            case Guardian.generate_token(user) do
              {:ok, token} -> {:ok, %{token: token, user: user}}
              error -> error
            end

          {:error, changeset} ->
            {:error, "Registration failed: #{inspect(changeset.errors)}"}
        end
      end)
    end

    field :login, :auth_payload do
      arg :email, non_null(:string)
      arg :password, non_null(:string)

      resolve(fn %{email: email, password: password}, _info ->
        case Accounts.authenticate_user_with_token(email, password) do
          {:ok, user, token} -> {:ok, %{token: token, user: user}}
          {:error, :invalid_credentials} -> {:error, "Invalid credentials"}
          error -> error
        end
      end)
    end
  end
end
