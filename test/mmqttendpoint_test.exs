defmodule MqttEndpointTest do
  use ExUnit.Case

  import Mox
  import ExUnit.CaptureLog
  require Logger

  setup do
    :verify_on_exit!

    :ok
  end

  alias Blinkchain.Color
  alias Mqtt.Endpoint.State

  test "Start up an MQTT Endpoint GenServer and validate we can change settings" do
    {status, _} = Mqtt.Endpoint.start_link([0])
    assert status == :ok

    expect(
      Tortoise.BaseMock,
      :publish,
      fn 0, "homie/0/light/color", "255,0,128", _ ->
        {:ok, 123}
      end
    )

    GenServer.cast(Mqtt.Endpoint, {:color_message, "255,0,128"})
  end

  # This test is pretty long because it's validating the homie api which
  # requries a lot of mqtt messages at connection_up. It might be better to
  # do a stub_with and describe the properties of the homie api in there rather
  # then validate the individual mqtt messages.
  test "Handle cast :connection_up" do
    state = %State{
      status: :down,
      device_id: 0
    }

    # Validate we output homie init state
    expect(
      Tortoise.BaseMock,
      :publish,
      fn 0, "homie/0/$state", "init", _ ->
        {:ok, 123}
      end
    )

    # Validate we supply a homie version
    expect(
      Tortoise.BaseMock,
      :publish,
      fn 0, "homie/0/$homie", _, _ ->
        {:ok, 123}
      end
    )

    # Validate we supply homie device name
    expect(
      Tortoise.BaseMock,
      :publish,
      fn 0, "homie/0/$name", "Eeyeore", _ ->
        {:ok, 123}
      end
    )

    # Validate we supply homie nodes as a device of type light
    expect(
      Tortoise.BaseMock,
      :publish,
      fn 0, "homie/0/$nodes", "light", _ ->
        {:ok, 123}
      end
    )

    # Validate we supply homie implementation
    expect(
      Tortoise.BaseMock,
      :publish,
      fn 0, "homie/0/$implementation", "nerves", _ ->
        {:ok, 123}
      end
    )

    # Validate we supply homie device node name
    expect(
      Tortoise.BaseMock,
      :publish,
      fn 0, "homie/0/light/$name", "Lightning", _ ->
        {:ok, 123}
      end
    )

    # Validate we supply homie device type information
    expect(
      Tortoise.BaseMock,
      :publish,
      fn 0, "homie/0/light/$type", _, _ ->
        {:ok, 123}
      end
    )

    # Validate we supply homie device properties
    expect(
      Tortoise.BaseMock,
      :publish,
      fn 0, "homie/0/light/$properties", "color,brightness,quantity,trigger,multi-trigger", _ ->
        {:ok, 123}
      end
    )

    # Validate we supply homie color properties
    expect(
      Tortoise.BaseMock,
      :publish,
      fn 0, "homie/0/light/color/$name", _, _ ->
        {:ok, 123}
      end
    )

    expect(
      Tortoise.BaseMock,
      :publish,
      fn 0, "homie/0/light/color/$datatype", "color", _ ->
        {:ok, 123}
      end
    )

    expect(
      Tortoise.BaseMock,
      :publish,
      fn 0, "homie/0/light/color/$format", "rgb", _ ->
        {:ok, 123}
      end
    )

    expect(
      Tortoise.BaseMock,
      :publish,
      fn 0, "homie/0/light/color/$retained", "true", _ ->
        {:ok, 123}
      end
    )

    expect(
      Tortoise.BaseMock,
      :publish,
      fn 0, "homie/0/light/color/$settable", "true", _ ->
        {:ok, 123}
      end
    )

    expect(
      Tortoise.BaseMock,
      :publish,
      fn 0, "homie/0/light/color", _, _ ->
        {:ok, 123}
      end
    )

    # Validate we supply homie brightness properties
    expect(
      Tortoise.BaseMock,
      :publish,
      fn 0, "homie/0/light/brightness/$name", _, _ ->
        {:ok, 123}
      end
    )

    expect(
      Tortoise.BaseMock,
      :publish,
      fn 0, "homie/0/light/brightness/$datatype", "integer", _ ->
        {:ok, 123}
      end
    )

    expect(
      Tortoise.BaseMock,
      :publish,
      fn 0, "homie/0/light/brightness/$unit", "%", _ ->
        {:ok, 123}
      end
    )

    expect(
      Tortoise.BaseMock,
      :publish,
      fn 0, "homie/0/light/brightness/$format", "1:100", _ ->
        {:ok, 123}
      end
    )

    expect(
      Tortoise.BaseMock,
      :publish,
      fn 0, "homie/0/light/brightness/$retained", "true", _ ->
        {:ok, 123}
      end
    )

    expect(
      Tortoise.BaseMock,
      :publish,
      fn 0, "homie/0/light/brightness/$settable", "true", _ ->
        {:ok, 123}
      end
    )

    expect(
      Tortoise.BaseMock,
      :publish,
      fn 0, "homie/0/light/brightness", _, _ ->
        {:ok, 123}
      end
    )

    # Validate we supply homie quantity properties
    expect(
      Tortoise.BaseMock,
      :publish,
      fn 0, "homie/0/light/quantity/$name", _, _ ->
        {:ok, 123}
      end
    )

    expect(
      Tortoise.BaseMock,
      :publish,
      fn 0, "homie/0/light/quantity/$datatype", "integer", _ ->
        {:ok, 123}
      end
    )

    expect(
      Tortoise.BaseMock,
      :publish,
      fn 0, "homie/0/light/quantity/$unit", "#", _ ->
        {:ok, 123}
      end
    )

    expect(
      Tortoise.BaseMock,
      :publish,
      fn 0, "homie/0/light/quantity/$format", "1:100", _ ->
        {:ok, 123}
      end
    )

    expect(
      Tortoise.BaseMock,
      :publish,
      fn 0, "homie/0/light/quantity/$retained", "true", _ ->
        {:ok, 123}
      end
    )

    expect(
      Tortoise.BaseMock,
      :publish,
      fn 0, "homie/0/light/quantity/$settable", "true", _ ->
        {:ok, 123}
      end
    )

    expect(
      Tortoise.BaseMock,
      :publish,
      fn 0, "homie/0/light/quantity", _, _ ->
        {:ok, 123}
      end
    )

    # Validate we supply homie trigger properties
    expect(
      Tortoise.BaseMock,
      :publish,
      fn 0, "homie/0/light/trigger/$name", _, _ ->
        {:ok, 123}
      end
    )

    expect(
      Tortoise.BaseMock,
      :publish,
      fn 0, "homie/0/light/trigger/$datatype", "enum", _ ->
        {:ok, 123}
      end
    )

    expect(
      Tortoise.BaseMock,
      :publish,
      fn 0, "homie/0/light/trigger/$format", "PRESSED,RELEASED", _ ->
        {:ok, 123}
      end
    )

    expect(
      Tortoise.BaseMock,
      :publish,
      fn 0, "homie/0/light/trigger/$retained", "false", _ ->
        {:ok, 123}
      end
    )

    expect(
      Tortoise.BaseMock,
      :publish,
      fn 0, "homie/0/light/trigger/$settable", "true", _ ->
        {:ok, 123}
      end
    )

    # Validate we supply homie multi-trigger properties
    expect(
      Tortoise.BaseMock,
      :publish,
      fn 0, "homie/0/light/multi-trigger/$name", _, _ ->
        {:ok, 123}
      end
    )

    expect(
      Tortoise.BaseMock,
      :publish,
      fn 0, "homie/0/light/multi-trigger/$datatype", "integer", _ ->
        {:ok, 123}
      end
    )

    expect(
      Tortoise.BaseMock,
      :publish,
      fn 0, "homie/0/light/multi-trigger/$unit", "#", _ ->
        {:ok, 123}
      end
    )

    expect(
      Tortoise.BaseMock,
      :publish,
      fn 0, "homie/0/light/multi-trigger/$format", "1:100", _ ->
        {:ok, 123}
      end
    )

    expect(
      Tortoise.BaseMock,
      :publish,
      fn 0, "homie/0/light/multi-trigger/$retained", "false", _ ->
        {:ok, 123}
      end
    )

    expect(
      Tortoise.BaseMock,
      :publish,
      fn 0, "homie/0/light/multi-trigger/$settable", "true", _ ->
        {:ok, 123}
      end
    )

    # Validate init complete and up state published
    expect(
      Tortoise.BaseMock,
      :publish,
      fn 0, "homie/0/$state", "ready", _ ->
        {:ok, 123}
      end
    )

    # Validate the endpoint's state also is set to up/connected
    start_supervised!(Eeyeore.Settings)
    response = Mqtt.Endpoint.handle_cast(:connection_up, state)
    assert response == {:noreply, %State{status: :up, device_id: state.device_id}}
  end

  test "Handle cast :connection_down" do
    state = %State{
      status: :down,
      device_id: 0
    }

    # Validate that we publish the service is disconnected
    expect(
      Tortoise.BaseMock,
      :publish,
      fn 0, "homie/0/$state", "disconnected", [qos: 1, retain: true] ->
        {:ok, 123}
      end
    )

    # Validate the endpoint's state also is set to down/disconnected
    response = Mqtt.Endpoint.handle_cast(:connection_down, state)
    assert response == {:noreply, %State{status: :down, device_id: state.device_id}}
  end

  test "Handle cast :color_changed" do
    state = %State{
      status: :up,
      device_id: 0
    }

    expect(
      Tortoise.BaseMock,
      :publish,
      fn 0, "homie/0/light/color", _, _ ->
        {:ok, 123}
      end
    )

    # Validate the endpoint's state doesn't change
    response = Mqtt.Endpoint.handle_cast({:color_changed, Color.parse("#A253FC")}, state)
    assert response == {:noreply, state}
  end

  test "Handle cast for valid :color_message" do
    state = %State{
      status: :up,
      device_id: 0
    }

    # Mock Settings GenServer
    {:ok, subscriber_pid} =
      GenServer.start_link(ProcessGenServerCasts, [], name: Eeyeore.Settings)

    response = Mqtt.Endpoint.handle_cast({:color_message, "255,0,128"}, state)
    assert response == {:noreply, state}

    # Wait for the GenServer to recieve a cast
    subscriber_received = :sys.get_state(subscriber_pid)
    set_color = %Color{r: 255, g: 0, b: 128}
    assert subscriber_received == {:set_color, set_color}
  end

  test "Handle cast for invalid :color_message" do
    state = %State{
      status: :up,
      device_id: 0
    }

    # Mock Settings GenServer
    {:ok, subscriber_pid} =
      GenServer.start_link(ProcessGenServerCasts, [], name: Eeyeore.Settings)

    garbage_color_input = "garbagecolor,data"

    log_output =
      capture_log(fn ->
        response = Mqtt.Endpoint.handle_cast({:color_message, garbage_color_input}, state)
        assert response == {:noreply, state}
      end)

    assert String.contains?(log_output, garbage_color_input)
    assert String.contains?(log_output, "Could not parse")

    # Check to see if we timed out waiting for a message to Eyeore.Settings
    assert [] == :sys.get_state(subscriber_pid)
  end

  test "Handle cast for valid :brightness_message" do
    state = %State{
      status: :up,
      device_id: 0
    }

    # Mock Settings GenServer
    {:ok, subscriber_pid} =
      GenServer.start_link(ProcessGenServerCasts, [], name: Eeyeore.Settings)

    new_brightness = 30

    response = Mqtt.Endpoint.handle_cast({:brightness_message, "#{new_brightness}"}, state)
    assert response == {:noreply, state}

    # Wait for the GenServer to recieve a cast
    subscriber_received = :sys.get_state(subscriber_pid)
    assert subscriber_received == {:set_brightness, new_brightness}
  end

  test "Handle cast for invalid :brightness_message" do
    state = %State{
      status: :up,
      device_id: 0
    }

    # Mock Settings GenServer
    {:ok, subscriber_pid} =
      GenServer.start_link(ProcessGenServerCasts, [], name: Eeyeore.Settings)

    garbage_brightness = 500

    log_output =
      capture_log(fn ->
        response =
          Mqtt.Endpoint.handle_cast({:brightness_message, "#{garbage_brightness}"}, state)

        assert response == {:noreply, state}
      end)

    assert String.contains?(log_output, "#{garbage_brightness}")
    assert String.contains?(log_output, "Could not parse")

    # Check to see if we timed out waiting for a message to Eyeore.Settings
    assert [] == :sys.get_state(subscriber_pid)
  end

  test "Handle cast for valid :quantity_message" do
    state = %State{
      status: :up,
      device_id: 0
    }

    # Mock Settings GenServer
    {:ok, subscriber_pid} =
      GenServer.start_link(ProcessGenServerCasts, [], name: Eeyeore.Settings)

    new_quantity = 15

    response = Mqtt.Endpoint.handle_cast({:quantity_message, "#{new_quantity}"}, state)
    assert response == {:noreply, state}

    # Wait for the GenServer to recieve a cast
    subscriber_received = :sys.get_state(subscriber_pid)
    assert subscriber_received == {:set_quantity, new_quantity}
  end

  test "Handle cast for invalid :quantity_message" do
    state = %State{
      status: :up,
      device_id: 0
    }

    # Mock Settings GenServer
    {:ok, subscriber_pid} =
      GenServer.start_link(ProcessGenServerCasts, [], name: Eeyeore.Settings)

    garbage_quantity = -3

    log_output =
      capture_log(fn ->
        response = Mqtt.Endpoint.handle_cast({:quantity_message, "#{garbage_quantity}"}, state)
        assert response == {:noreply, state}
      end)

    assert String.contains?(log_output, "#{garbage_quantity}")
    assert String.contains?(log_output, "Could not parse")

    # Check to see if we timed out waiting for a message to Eyeore.Settings
    assert [] == :sys.get_state(subscriber_pid)
  end

  test " Handle cast for lightning :trigger" do
    # Create a genserver that can recieve messages as a settings subscriber
    {:ok, eeyore_render_pid} =
      GenServer.start_link(ProcessGenServerCasts, [], name: Eeyeore.Render)

    start_supervised!(Eeyeore.Settings)

    state = %State{
      status: :up,
      device_id: 0
    }

    response = Mqtt.Endpoint.handle_cast(:trigger, state)
    assert response == {:noreply, state}

    # Wait for the Render GenServer to recieve a cast
    render_message_received = :sys.get_state(eeyore_render_pid)
    quantity = GenServer.call(Eeyeore.Settings, :get_quantity)
    assert render_message_received == {:lightning, quantity}
  end

  test "handle unknown cast" do
    state = %State{
      status: :up,
      device_id: 0
    }

    response = Mqtt.Endpoint.handle_cast({:random_payload, "Unplanned message"}, state)
    assert response == {:noreply, state}
  end

  test "Handle info from Tortoise OK" do
    state = %State{
      status: :up,
      device_id: 0
    }

    response = Mqtt.Endpoint.handle_info({{Tortoise, state.device_id}, 123, :ok}, state)
    assert response == {:noreply, state}
  end

  test "Handle info from Tortoise publish status" do
    state = %State{
      status: :up,
      device_id: 0
    }

    response =
      Mqtt.Endpoint.handle_info(
        {{Tortoise, state.device_id}, 123, {:error, :unknown_connection}},
        state
      )

    assert response == {:noreply, state}
  end

  test "Handle info misc" do
    state = %State{
      status: :up,
      device_id: 0
    }

    response = Mqtt.Endpoint.handle_info({:some_new_info, "with a message"}, state)
    assert response == {:noreply, state}
  end
end
