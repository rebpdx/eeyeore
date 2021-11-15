defmodule Mqtt.Handler do
  @moduledoc false
  use Tortoise.Handler

  require Logger

  # MQTT Handler recieves callbacks from Tortoise MQTT and is the client API for
  # MQTT Endpoint.
  #
  # This handler recieves callbacks for connection status, and subscribed
  # messages. This module pushes the data out of this handler as quickly as
  # possible because these are blocking calls in Tortoise. Most callbacks are
  # routed to MQTT.Endpoint for further processing but a few are directly pushed
  # to the Eeyeore.Render Module.
  #
  #
  # https://hexdocs.pm/tortoise/Tortoise.Handler.html#callbacks

  defmodule State do
    defstruct [:status, :device_id]
  end

  def init(opts) do
    Logger.debug("[MQTT Handler] Initializing MQTT Handler")
    [device_id | _tail] = opts
    state = %State{status: :down, device_id: device_id}

    {:ok, state}
  end

  # MQTT Broker Connection Status

  # `status` is either `:up` or `:down`
  def connection(:up, state) do
    Logger.info("[MQTT Handler] MQTT Connection to server has been established")
    GenServer.cast(Mqtt.Endpoint, :connection_up)
    {:ok, %State{status: :up, device_id: state.device_id}}
  end

  def connection(:down, state) do
    GenServer.cast(Mqtt.Endpoint, :connection_down)
    {:ok, %State{status: :down, device_id: state.device_id}}
  end

  def subscription(:up, topic, state) do
    Logger.info("[MQTT Handler] Subscribed to #{topic}")
    {:ok, state}
  end

  # MQTT Message handlers

  # homie/#{device_id}/light/color
  def handle_message(["homie", _device_id, "light", "color", "set"], payload, state) do
    # This is a blocking call, shipping to Mqtt.Endpoint to handle
    GenServer.cast(Mqtt.Endpoint, {:color_message, payload})

    {:ok, state}
  end

  # homie/#{device_id}/light/brightness
  def handle_message(["homie", _device_id, "light", "brightness", "set"], payload, state) do
    # This is a blocking call, shipping to Mqtt.Endpoint to handle
    GenServer.cast(Mqtt.Endpoint, {:brightness_message, payload})

    {:ok, state}
  end

  # homie/#{device_id}/light/quantity
  def handle_message(["homie", _device_id, "light", "quantity", "set"], payload, state) do
    # This is a blocking call, shipping to Mqtt.Endpoint to handle
    GenServer.cast(Mqtt.Endpoint, {:quantity_message, payload})

    {:ok, state}
  end

  # homie/#{device_id}/light/trigger
  def handle_message(["homie", _device_id, "light", "trigger", "set"], _payload, state) do
    Logger.info("[MQTT Handler] Recieved Trigger Message")
    # TODO: Point this to render after quantity get call is moved to render
    GenServer.cast(Mqtt.Endpoint, :trigger)

    {:ok, state}
  end

  # homie/#{device_id}/light/multi-trigger
  def handle_message(["homie", _device_id, "light", "multi-trigger", "set"], payload, state) do
    Logger.info("[MQTT Handler] Recieved Multi-Trigger Message")
    GenServer.cast(Eeyeore.Render, {:lightning, String.to_integer(payload)})

    {:ok, state}
  end

  # homie/#{device_id}/light/#
  # Handles any unsupported messages Tortoise might give us
  def handle_message(topic, payload, state) do
    Logger.info(
      "[MQTT Handler] Unsupported message: #{Enum.join(topic, "/")} #{inspect(payload)}"
    )

    {:ok, state}
  end
end
