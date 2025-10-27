defmodule ServerWeb.Router do
  use ServerWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :graphql do
    plug :accepts, ["json"]
    plug ServerWeb.Plugs.RateLimiter
    plug ServerWeb.AuthContext
  end

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :protect_from_forgery
  end

  scope "/api", ServerWeb.Controllers do
    pipe_through :api
  end

  scope "/graphql" do
    pipe_through([:graphql])

    forward(
      "/",
      Absinthe.Plug,
      analyze_complexity: true,
      schema: ServerWeb.Schemas.Schema,
      socket: ServerWeb.Socket,
      json_codec: Jason
    )
  end

  # Enable LiveDashboard in development
  if Application.compile_env(:server, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/graphiql" do
      forward(
        "/",
        Absinthe.Plug.GraphiQL,
        interface: :advanced,
        schema: ServerWeb.Schemas.Schema,
        socket: ServerWeb.Socket,
        json_codec: Jason
      )
    end

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      live_dashboard "/dashboard", metrics: ServerWeb.Telemetry
    end
  end
end
