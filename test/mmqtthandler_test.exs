defmodule MqttHandlerTest do
  use ExUnit.Case

  import ExUnit.CaptureLog
  require Logger

  setup do
    :verify_on_exit!

    start_supervised!(Eeyeore.Settings)
    :ok
  end

  alias Mqtt.Handler.State

  test "MQTT Server sends connection up" do
    # Start a GenServer as a Stub for Mqtt.Endpoint
    {:ok, endpoint_pid} = GenServer.start_link(ProcessGenServerCasts, [], name: Mqtt.Endpoint)

    {:ok, state} = Mqtt.Handler.init([0])

    {:ok, conn_up_state} = Mqtt.Handler.connection(:up, state)
    assert conn_up_state == %State{status: :up, device_id: 0}

    # Wait for the Mqtt.Endpoint GenServer to recieve a cast
    endpoint_received = :sys.get_state(endpoint_pid)
    assert endpoint_received == :connection_up
  end

  test "MQTT Server sends connection down" do
    # Start a GenServer as a Stub for Mqtt.Endpoint
    {:ok, endpoint_pid} = GenServer.start_link(ProcessGenServerCasts, [], name: Mqtt.Endpoint)

    {:ok, state} = Mqtt.Handler.init([0])

    {:ok, conn_down_state} = Mqtt.Handler.connection(:down, state)
    assert conn_down_state == %State{status: :down, device_id: 0}

    # Wait for the Mqtt.Endpoint GenServer to recieve a cast
    endpoint_received = :sys.get_state(endpoint_pid)
    assert endpoint_received == :connection_down
  end

  test "MQTT Server recieves subscription" do
    state = %State{status: :up, device_id: 0}
    test_topic = "test_topic"

    log_output =
      capture_log(fn ->
        {:ok, ret_state} = Mqtt.Handler.subscription(:up, test_topic, state)
        assert state == ret_state
      end)

    assert String.contains?(log_output, test_topic)
  end

  test "Handle color setting message" do
    # Start a GenServer as a Stub for Mqtt.Endpoint
    {:ok, endpoint_pid} = GenServer.start_link(ProcessGenServerCasts, [], name: Mqtt.Endpoint)

    state = %State{status: :up, device_id: 0}
    color_setting = "255,0,128"

    {:ok, ret_state} =
      Mqtt.Handler.handle_message(
        ["homie", state.device_id, "light", "color", "set"],
        color_setting,
        state
      )

    assert state == ret_state

    # Wait for the Mqtt.Endpoint GenServer to recieve a cast
    endpoint_received = :sys.get_state(endpoint_pid)
    assert endpoint_received == {:color_message, color_setting}
  end

  test "Handle brightness setting message" do
    # Start a GenServer as a Stub for Mqtt.Endpoint
    {:ok, endpoint_pid} = GenServer.start_link(ProcessGenServerCasts, [], name: Mqtt.Endpoint)

    state = %State{status: :up, device_id: 0}
    brightness_setting = "50"

    {:ok, ret_state} =
      Mqtt.Handler.handle_message(
        ["homie", state.device_id, "light", "brightness", "set"],
        brightness_setting,
        state
      )

    assert state == ret_state

    # Wait for the Mqtt.Endpoint GenServer to recieve a cast
    endpoint_received = :sys.get_state(endpoint_pid)
    assert endpoint_received == {:brightness_message, brightness_setting}
  end

  test "Handle quantity setting message" do
    # Start a GenServer as a Stub for Mqtt.Endpoint
    {:ok, endpoint_pid} = GenServer.start_link(ProcessGenServerCasts, [], name: Mqtt.Endpoint)

    state = %State{status: :up, device_id: 0}
    quantity_setting = "50"

    {:ok, ret_state} =
      Mqtt.Handler.handle_message(
        ["homie", state.device_id, "light", "quantity", "set"],
        quantity_setting,
        state
      )

    assert state == ret_state

    # Wait for the Mqtt.Endpoint GenServer to recieve a cast
    endpoint_received = :sys.get_state(endpoint_pid)
    assert endpoint_received == {:quantity_message, quantity_setting}
  end

  test "Handle trigger message" do
    # Start a GenServer as a Stub for Mqtt.Endpoint
    {:ok, endpoint_pid} = GenServer.start_link(ProcessGenServerCasts, [], name: Mqtt.Endpoint)

    state = %State{status: :up, device_id: 0}

    {:ok, ret_state} =
      Mqtt.Handler.handle_message(
        ["homie", state.device_id, "light", "trigger", "set"],
        nil,
        state
      )

    assert state == ret_state

    # Wait for the Mqtt.Endpoint GenServer to recieve a cast
    endpoint_received = :sys.get_state(endpoint_pid)
    assert endpoint_received == :trigger
  end

  test "Handle multi-trigger message" do
    # Start a GenServer as a Stub for Mqtt.Endpoint
    {:ok, endpoint_pid} = GenServer.start_link(ProcessGenServerCasts, [], name: Eeyeore.Render)

    state = %State{status: :up, device_id: 0}
    trigger_setting = 50

    {:ok, ret_state} =
      Mqtt.Handler.handle_message(
        ["homie", state.device_id, "light", "multi-trigger", "set"],
        "#{trigger_setting}",
        state
      )

    assert state == ret_state

    # Wait for the Mqtt.Endpoint GenServer to recieve a cast
    endpoint_received = :sys.get_state(endpoint_pid)
    assert endpoint_received == {:lightning, trigger_setting}
  end

  test "Handle unsupported MQTT Messages" do
    state = %State{status: :up, device_id: 0}
    unsupported_topic = "unsupported_topic"

    log_output =
      capture_log(fn ->
        {:ok, ret_state} =
          Mqtt.Handler.handle_message(
            ["homie", state.device_id, "light", unsupported_topic, "set"],
            nil,
            state
          )

        assert state == ret_state
      end)

    assert String.contains?(log_output, unsupported_topic)
    assert String.contains?(log_output, "Unsupported message")
  end
end
