defmodule Tortoise.Base do
  @moduledoc false

  # Defines the contract used with Tortoise, since they didn't define callbacks
  # we could be subject to changes in the API, hopefully they won't change it
  # without notice in the hex docs.

  @callback publish(client_id, topic) ::
              :ok | {:ok, reference()} | {:error, :unknown_connection}
  @callback publish(client_id, topic, payload) ::
              :ok | {:ok, reference()} | {:error, :unknown_connection}
  @callback publish(client_id, topic, payload, opt) ::
              :ok | {:ok, reference()} | {:error, :unknown_connection}

  @type client_id :: String.t()
  @type topic :: String.t()
  @type payload :: String.t()
  @type opt :: list(any())
end
