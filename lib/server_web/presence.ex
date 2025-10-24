defmodule ServerWeb.Presence do
  @moduledoc """
  Phoenix Presence module for tracking user online status across the application.

  This module provides distributed presence tracking using Phoenix.Presence's
  CRDT (Conflict-free Replicated Data Type) for handling presence across
  multiple nodes in a distributed system.
  """

  use Phoenix.Presence,
    otp_app: :server,
    pubsub_server: Server.PubSub
end
