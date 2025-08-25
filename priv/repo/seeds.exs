# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Server.Repo.insert!(%Server.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Server.Repo
alias Server.Models.UserModel

[
  %{
    first_name: "User",
    last_name: "1",
    email: "user_1@test.com",
    state: :active
  },
  %{
    first_name: "User",
    last_name: "2",
    email: "user_2@test.com",
    state: :active
  },
  %{
    first_name: "User",
    last_name: "3",
    email: "user_3@test.com",
    state: :active
  }
]
|> Enum.each(fn attrs ->
  %UserModel{}
  |> UserModel.changeset(attrs)
  |> Repo.insert!(
    on_conflict: :replace_all,
    conflict_target: [:email]
  )
end)
