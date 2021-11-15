defmodule EeyeoreSettingsTest do
  use ExUnit.Case
  doctest Eeyeore.Settings

  alias Blinkchain.Color
  alias Eeyeore.Settings
  alias Eeyeore.Settings.State

  test "Subscribe to broadcast_messages" do
    # Create a genserver that can recieve messages as a settings subscriber
    {:ok, subscriber_pid} =
      GenServer.start_link(ProcessGenServerCasts, [], name: ProcessSubscriber)

    # Some initial state for Settings without any subscribers
    state = %State{
      color: Color.parse("#A253FC"),
      brightness: 100,
      quantity: 10,
      subs: []
    }

    response = Settings.handle_cast({:subscribe, subscriber_pid}, state)

    # Validate the state includes our new subscriber
    assert response ==
             {:noreply,
              %State{
                color: state.color,
                brightness: state.brightness,
                quantity: state.quantity,
                subs: [subscriber_pid]
              }}

    {:noreply, registered_state} = response

    # Send a brightness change to validate our registered subscriber recieved the message
    new_brightness = 50
    Settings.handle_cast({:set_brightness, new_brightness}, registered_state)

    # Wait for the GenServer to recieve a cast
    subscriber_received = :sys.get_state(subscriber_pid)
    assert subscriber_received == {:brightness_changed, new_brightness}
  end

  test "No broadcast on no color change" do
    {:ok, subscriber_pid} =
      GenServer.start_link(ProcessGenServerCasts, [], name: ProcessSubscriber)

    state = %State{
      color: Color.parse("#A253FC"),
      brightness: 100,
      quantity: 10,
      subs: [subscriber_pid]
    }

    response = Settings.handle_cast({:set_color, state.color}, state)

    assert response == {:noreply, state}

    # Should have timed out waiting for a GenServer Cast
    assert [] == :sys.get_state(subscriber_pid)
  end

  test "Broadcast recieved on color change" do
    {:ok, subscriber_pid} =
      GenServer.start_link(ProcessGenServerCasts, [], name: ProcessSubscriber)

    state = %State{
      color: Color.parse("#A253FC"),
      brightness: 100,
      quantity: 10,
      subs: [subscriber_pid]
    }

    new_color = Color.parse("#A551FD")

    response = Settings.handle_cast({:set_color, new_color}, state)

    # State should include the new color but no other changes
    assert response ==
             {:noreply,
              %State{
                color: new_color,
                brightness: state.brightness,
                quantity: state.quantity,
                subs: state.subs
              }}

    # Wait for the GenServer to recieve a cast
    subscriber_received = :sys.get_state(subscriber_pid)
    assert subscriber_received == {:color_changed, new_color}
  end

  test "No broadcast on no brightness change" do
    {:ok, subscriber_pid} =
      GenServer.start_link(ProcessGenServerCasts, [], name: ProcessSubscriber)

    state = %State{
      color: Color.parse("#A253FC"),
      brightness: 100,
      quantity: 10,
      subs: [subscriber_pid]
    }

    response = Settings.handle_cast({:set_brightness, state.brightness}, state)

    assert response == {:noreply, state}

    # Should have timed out waiting for a GenServer Cast
    assert [] = :sys.get_state(subscriber_pid)
  end

  test "Broadcast recieved on brightness change" do
    {:ok, subscriber_pid} =
      GenServer.start_link(ProcessGenServerCasts, [], name: ProcessSubscriber)

    state = %State{
      color: Color.parse("#A253FC"),
      brightness: 100,
      quantity: 10,
      subs: [subscriber_pid]
    }

    new_brightness = 50

    response = Settings.handle_cast({:set_brightness, new_brightness}, state)

    # GenServer's State should include the new brightness but no other changes
    assert response ==
             {:noreply,
              %State{
                color: state.color,
                brightness: new_brightness,
                quantity: state.quantity,
                subs: state.subs
              }}

    # Wait for the GenServer to recieve a cast
    subscriber_received = :sys.get_state(subscriber_pid)
    assert subscriber_received == {:brightness_changed, new_brightness}
  end

  test "No changes on out of bounds brightness setting" do
    {:ok, subscriber_pid} =
      GenServer.start_link(ProcessGenServerCasts, [], name: ProcessSubscriber)

    state = %State{
      color: Color.parse("#A253FC"),
      brightness: 100,
      quantity: 10,
      subs: [subscriber_pid]
    }

    # Try sending something above bounds
    new_brightness = 500
    response = Settings.handle_cast({:set_brightness, new_brightness}, state)

    # GenServer's State should have not changed
    assert response == {:noreply, state}

    # Should have timed out waiting for a GenServer Cast
    assert [] = :sys.get_state(subscriber_pid)

    # Try sending something blow bounds
    new_brightness = -20
    response = Settings.handle_cast({:set_brightness, new_brightness}, state)

    # GenServer's State should have not changed
    assert response == {:noreply, state}

    # Should have timed out waiting for a GenServer Cast
    assert [] = :sys.get_state(subscriber_pid)
  end

  test "Broadcast recieved on quantity change" do
    {:ok, subscriber_pid} =
      GenServer.start_link(ProcessGenServerCasts, [], name: ProcessSubscriber)

    state = %State{
      color: Color.parse("#A253FC"),
      brightness: 100,
      quantity: 10,
      subs: [subscriber_pid]
    }

    new_quantity = 50

    response = Settings.handle_cast({:set_quantity, new_quantity}, state)

    # GenServer's State should include the new brightness but no other changes
    assert response ==
             {:noreply,
              %State{
                color: state.color,
                brightness: state.brightness,
                quantity: new_quantity,
                subs: state.subs
              }}

    # Wait for the GenServer to recieve a cast
    subscriber_received = :sys.get_state(subscriber_pid)
    assert subscriber_received == {:quantity_changed, new_quantity}
  end

  test "No changes on quantity not an integer" do
    {:ok, subscriber_pid} =
      GenServer.start_link(ProcessGenServerCasts, [], name: ProcessSubscriber)

    state = %State{
      color: Color.parse("#A253FC"),
      brightness: 100,
      quantity: 10,
      subs: [subscriber_pid]
    }

    # Try sending a negative number
    response = Settings.handle_cast({:set_quantity, -20}, state)

    # GenServer's State should have not changed
    assert response == {:noreply, state}

    # Should have timed out waiting for a GenServer Cast
    assert [] = :sys.get_state(subscriber_pid)

    # Try sending a string
    response = Settings.handle_cast({:set_quantity, "bob"}, state)

    # GenServer's State should have not changed
    assert response == {:noreply, state}

    # Should have timed out waiting for a GenServer Cast
    assert [] = :sys.get_state(subscriber_pid)
  end

  test "Get current Color setting" do
    # Some initial state for Settings
    {:ok, state} = Settings.init([])

    {reply, response, _} = Settings.handle_call(:get_color, nil, state)

    assert {reply, response} == {:reply, state.color}
  end

  test "Get current Brightness setting" do
    # Some initial state for Settings
    {:ok, state} = Settings.init([])

    {reply, response, _} = Settings.handle_call(:get_brightness, nil, state)

    assert {reply, response} == {:reply, state.brightness}
  end

  test "Get current Quantity setting" do
    # Some initial state for Settings
    {:ok, state} = Settings.init([])

    {reply, response, _} = Settings.handle_call(:get_quantity, nil, state)

    assert {reply, response} == {:reply, state.quantity}
  end
end
