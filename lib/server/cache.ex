defmodule Server.Cache do
  use Nebulex.Cache,
    otp_app: :server,
    adapter: Nebulex.Adapters.Local
end
