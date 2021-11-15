defmodule Mqtt.Endpoint do
  @moduledoc false
  use GenServer
  require Logger

  alias Blinkchain.Color

  defmodule State do
    defstruct [:status, :device_id]
  end

  defmodule Attributes do
    defstruct name: "",
              datatype: "",
              unit: "",
              format: "",
              retained: true,
              settable: true
  end

  def start_link(opts) do
    Logger.debug("[MQTT Endpoint] Starting GenServer")
    status = GenServer.start_link(__MODULE__, opts, name: __MODULE__)

    case status do
      # Register ourselves with the eeyeore Message Broker
      {:ok, pid} ->
        GenServer.cast(Eeyeore.Settings, {:subscribe, pid})
        {:ok, pid}

      _ ->
        status
    end
  end

  def init(opts) do
    Logger.debug("[MQTT Endpoint] Initializing MQTT Endpoint")
    [device_id | _tail] = opts

    state = %State{
      status: :down,
      device_id: device_id
    }

    {:ok, state}
  end

  # Casts from Tortoise about MQTT broker connection status

  # Handles a cast from Tortoise about the connection status being up, all Homie
  # messages related to setup are published here
  def handle_cast(:connection_up, state) do
    publish(state.device_id, "homie/#{state.device_id}/$state", "init")
    Logger.debug("[MQTT Endpoint] Publishing intial setup messages")
    setup_topic_info(state.device_id)
    setup_color(state.device_id)
    setup_brightness(state.device_id)
    setup_quantity(state.device_id)
    setup_trigger(state.device_id)
    setup_multi_trigger(state.device_id)

    # We wait until everything else is sent before notifiying ready notice
    publish(state.device_id, "homie/#{state.device_id}/$state", "ready")
    {:noreply, %State{status: :up, device_id: state.device_id}}
  end

  # Handles a cast about graceful shutdown of the MQTT connection, per Homie
  # convention shipping a MQTT message about disconnecting from the broker
  def handle_cast(:connection_down, state) do
    publish(state.device_id, "homie/#{state.device_id}/$state", "disconnected")
    {:noreply, %State{status: :down, device_id: state.device_id}}
  end

  # Casts from Eeyeore.Settings

  # Handles a cast from Eeyeore.Settings that the color has been changed where we
  # publish an MQTT message to report the new color setting
  # TODO: Should we only publish when connection is up? On connection up does
  #       check for the current setting so skipping on down won't loose data
  def handle_cast({:color_changed, color}, state) do
    # The settings reported we changed colors, we better ship the info out on MQTT
    base_topic = "homie/#{state.device_id}/light/color"
    Logger.debug("[MQTT Endpoint] Broadcasting color change event")
    publish(state.device_id, "#{base_topic}", "#{color.r},#{color.g},#{color.b}")

    {:noreply, state}
  end

  # Casts from MQTT.Handler containing MQTT messages and their payloads

  # Handles a cast from MQTT.Handler about a request to change the color setting
  def handle_cast({:color_message, payload}, state) do
    # We got a color setting message over MQTT, parse and ship to Eeyeore.Settings
    colors = payload |> String.split(",") |> Enum.map(&str_to_int/1)

    if Enum.all?(colors, fn x -> is_integer(x) end) do
      [red, green, blue] = colors

      new_color = %Color{
        r: red,
        g: green,
        b: blue
      }

      GenServer.cast(Eeyeore.Settings, {:set_color, new_color})
    else
      Logger.warn("[MQTT Endpoint] Could not parse new color: #{payload}")
    end

    {:noreply, state}
  end

  def handle_cast({:brightness_message, payload}, state) do
    # We got a brightness setting message over MQTT, parse and ship to Eeyore.Settings
    brightness = payload |> str_to_int

    if is_integer(brightness) and brightness >= 0 and brightness <= 100 do
      GenServer.cast(Eeyeore.Settings, {:set_brightness, brightness})
    else
      Logger.warn(
        "[MQTT Endpoint] Could not parse new brightness, it must be an integer " <>
          "from 0 to 100: #{payload}"
      )
    end

    {:noreply, state}
  end

  def handle_cast({:quantity_message, payload}, state) do
    # We got a quantity setting message over MQTT, parse and ship to Eeyore.Settings
    quantity = payload |> str_to_int

    if is_integer(quantity) and quantity >= 1 do
      GenServer.cast(Eeyeore.Settings, {:set_quantity, quantity})
    else
      Logger.warn(
        "[MQTT Endpoint] Could not parse new brightness, it must be an integer " <>
          "from 0 to 100: #{payload}"
      )
    end

    {:noreply, state}
  end

  # Handles a cast from MQTT.Handler about a request to trigger the preset quantity
  # of lightning bolts
  def handle_cast(:trigger, state) do
    # TODO: Move the quantity get call to the renderer
    quantity = GenServer.call(Eeyeore.Settings, :get_quantity)
    GenServer.cast(Eeyeore.Render, {:lightning, quantity})
    {:noreply, state}
  end

  # Fallback Cast handler for messages we're not prepared to recieve
  def handle_cast(other, state) do
    Logger.warn("[MQTT Endpoint] Unhandled cast #{inspect(other)}")
    {:noreply, state}
  end

  # Info about status on publishing to MQTT
  def handle_info({{Tortoise, _device_id}, _ref, :ok}, state) do
    # Do nothing because all is good...
    {:noreply, state}
  end

  def handle_info({{Tortoise, _device_id}, ref, result}, state) do
    Logger.warn(
      "[MQTT Endpoint] Publish message returned #{inspect(result)} for ref: #{inspect(ref)}"
    )

    {:noreply, state}
  end

  def handle_info(info, state) do
    Logger.debug("[MQTT Endpoint] Missed handle #{inspect(info)}")
    {:noreply, state}
  end

  defp setup_topic_info(device_id) do
    base_topic = "homie/#{device_id}"

    # Publish device and node attributes here. Since we only have one node we'll
    # skip abstracting that to another function like the property attributes

    publish(device_id, "#{base_topic}/$homie", "4.0.0")
    publish(device_id, "#{base_topic}/$name", "Eeyeore")
    publish(device_id, "#{base_topic}/$nodes", "light")
    publish(device_id, "#{base_topic}/$implementation", "nerves")
    publish(device_id, "#{base_topic}/light/$name", "Lightning")

    publish(
      device_id,
      "#{base_topic}/light/$type",
      "Controls settings and triggers lightning"
    )

    publish(
      device_id,
      "#{base_topic}/light/$properties",
      "color,brightness,quantity,trigger,multi-trigger"
    )
  end

  defp setup_color(device_id) do
    base_topic = "homie/#{device_id}/light/color"

    publish_property_attribute(
      device_id,
      base_topic,
      %Attributes{
        name: "Lightning color",
        datatype: "color",
        format: "rgb"
      }
    )

    color = GenServer.call(Eeyeore.Settings, :get_color)
    publish(device_id, "#{base_topic}", "#{color.r},#{color.g},#{color.b}")
  end

  defp setup_brightness(device_id) do
    base_topic = "homie/#{device_id}/light/brightness"

    publish_property_attribute(
      device_id,
      base_topic,
      %Attributes{
        name: "Lightning brightness",
        datatype: "integer",
        unit: "%",
        format: "1:100"
      }
    )

    brightness = GenServer.call(Eeyeore.Settings, :get_brightness)
    publish(device_id, "#{base_topic}", "#{brightness}")
  end

  defp setup_quantity(device_id) do
    base_topic = "homie/#{device_id}/light/quantity"

    publish_property_attribute(
      device_id,
      base_topic,
      %Attributes{
        name: "Bolts per trigger",
        datatype: "integer",
        unit: "#",
        format: "1:100"
      }
    )

    quantity = GenServer.call(Eeyeore.Settings, :get_quantity)
    publish(device_id, base_topic, "#{quantity}")
  end

  defp setup_trigger(device_id) do
    base_topic = "homie/#{device_id}/light/trigger"

    publish_property_attribute(
      device_id,
      base_topic,
      %Attributes{
        name: "Trigger lighting",
        datatype: "enum",
        format: "PRESSED,RELEASED",
        retained: false
      }
    )
  end

  defp setup_multi_trigger(device_id) do
    base_topic = "homie/#{device_id}/light/multi-trigger"

    publish_property_attribute(
      device_id,
      base_topic,
      %Attributes{
        name: "Trigger lighting",
        datatype: "integer",
        unit: "#",
        format: "1:100",
        retained: false
      }
    )
  end

  defp publish_property_attribute(
         device_id,
         base_topic,
         %Attributes{name: name, datatype: datatype} = attributes
       )
       when name != "" and datatype != "" and base_topic != "" do
    # Publishes the messages required to define the properties of an attribute
    # https://homieiot.github.io/specification/#property-attributes

    publish(device_id, "#{base_topic}/$name", attributes.name)
    publish(device_id, "#{base_topic}/$datatype", attributes.datatype)

    if attributes.unit != "" do
      publish(device_id, "#{base_topic}/$unit", attributes.unit)
    end

    if attributes.format != "" do
      publish(device_id, "#{base_topic}/$format", attributes.format)
    end

    publish(device_id, "#{base_topic}/$retained", to_string(attributes.retained))
    publish(device_id, "#{base_topic}/$settable", to_string(attributes.settable))
  end

  defp publish(device_id, topic, payload) do
    # Most messages are QOS 1 and Retained for Homie Convention
    # https://homieiot.github.io/specification/#qos-and-retained-messages
    {:ok, _ref} = mqtt_client().publish(device_id, topic, payload, qos: 1, retain: true)
    Logger.info("[MQTT Endpoint] publishing #{payload} to #{topic}")

    # Tortoise ships info related to ref back to us in handle_info which we'll
    # use for logger reporting otherwise we'll trust Tortoise has this handled
  end

  defp mqtt_client() do
    Application.get_env(:eeyeore, :mqtt_client)
  end

  defp str_to_int(string) do
    case string |> String.trim() |> Integer.parse() do
      {int, ""} -> int
      _ -> :error
    end
  end
end
