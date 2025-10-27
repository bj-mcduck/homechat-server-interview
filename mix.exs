defmodule Server.MixProject do
  use Mix.Project

  def project do
    [
      app: :server,
      version: "0.1.0",
      elixir: ">= 1.18.0",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Server.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.7.21"},
      {:phoenix_ecto, "~> 4.5"},
      {:ecto_sql, "~> 3.10"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_live_dashboard, "~> 0.8.3"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      {:jason, "~> 1.2"},
      {:dns_cluster, "~> 0.2.0"},
      {:bandit, "~> 1.5"},
      {:dotenvy, "~> 1.1.0"},
      {:decorator, "~> 1.4"},
      {:absinthe, "~> 1.7"},
      {:html_sanitize_ex, "~> 1.4"},
      {:nebulex, "~> 2.6"},
      {:shards, "~> 1.1"},
      {:phoenix_pubsub, "~> 2.0"},
      {:absinthe_phoenix, "~> 2.0"},
      {:absinthe_plug, "~> 1.5"},
      {:absinthe_relay, "~> 1.5.2"},
      {:absinthe_graphql_ws, "~> 0.3"},
      {:dataloader, "~> 2.0"},
      {:hackney, "~> 1.23"},
      {:httpoison, "~> 2.2"},
      {:req, "~> 0.5.15"},
      {:igniter, "~> 0.5", only: [:dev, :test]},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:credo_naming, "~> 2.0", only: [:dev, :test], runtime: false},
      {:sobelow, "~> 0.13", only: [:dev, :test], runtime: false},
      {:cors_plug, "~> 3.0"},
      {:hammer, "~> 6.2"},
      # Authentication and password hashing
      {:argon2_elixir, "~> 4.0"},
      {:joken, "~> 2.6"},
      {:guardian, "~> 2.3"},
      # NanoID for public IDs
      {:nanoid, "~> 2.1"},
      # Authorization
      {:bodyguard, "~> 2.4"},
      # Testing
      {:ex_machina, "~> 2.8", only: :test}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end
end
