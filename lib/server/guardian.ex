defmodule Server.Guardian do
  @moduledoc """
  Guardian implementation for JWT authentication
  """

  use Guardian, otp_app: :server

  alias Server.Models.UserModel
  alias Server.Repo

  def subject_for_token(%UserModel{} = user, _claims) do
    {:ok, to_string(user.id)}
  end

  def subject_for_token(_, _) do
    {:error, :invalid_resource}
  end

  def resource_from_claims(%{"sub" => id}) do
    case Repo.get(UserModel, id) do
      nil -> {:error, :resource_not_found}
      user -> {:ok, user}
    end
  end

  def resource_from_claims(_claims) do
    {:error, :invalid_claims}
  end

  @doc """
  Generate a token for a user
  """
  def generate_token(user) do
    {:ok, token, _claims} = encode_and_sign(user)
    {:ok, token}
  end

  @doc """
  Verify a token and return the user
  """
  def verify_token(token) do
    case resource_from_token(token) do
      {:ok, user, _claims} -> {:ok, user}
      error -> error
    end
  end
end
