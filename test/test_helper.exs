# Used as a mock GenServer to catch casts
defmodule ProcessGenServerCasts do
  def init(state) do
    {:ok, state}
  end

  def handle_cast(message, _) do
    {:noreply, message}
  end
end

ExUnit.start()

Mox.defmock(Tortoise.BaseMock, for: Tortoise.Base)

Application.put_env(:eeyeore, :mqtt_client, Tortoise.BaseMock)
