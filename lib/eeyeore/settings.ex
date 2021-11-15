defmodule Eeyeore.Settings do
  use GenServer
  require Logger

  @moduledoc """
  The main settings for Eeyeore

  These settings include things like, default LED Color,
  default number of bolts on a trigger, and maximum brightness. This module also
  broadcasts changes for network connections such as MQTT.
  """

  alias Blinkchain.Color

  @doc """
  State contains the color, maximum brightness of the bolt, and the number of
  random bolts on an unspecified trigger for Eeyeore settings. State also
  containes the subscribers to be notified when settings are changed.
  """
  defmodule State do
    defstruct [:color, :brightness, :quantity, :subs]
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_args) do
    state = %State{
      color: Color.parse("#A253FC"),
      brightness: 100,
      quantity: 10,
      subs: []
    }

    {:ok, state}
  end

  @doc """
  Subscribes a process to recieve casts of changed settings, mostly used by
  network endpoints. Casts recieved are in the format of
  {:<setting name>_changed, <setting value>}
  """
  def handle_cast({:subscribe, pid}, state) do
    {:noreply,
     %State{
       color: state.color,
       brightness: state.brightness,
       quantity: state.quantity,
       subs: [pid | state.subs]
     }}
  end

  @doc """
  Recieves a color setting in the format of Blinkchain.Color, if the color has
  changed it will broadcast the change to subscribers.
  """
  def handle_cast({:set_color, color = %Color{}}, state) do
    if color != state.color do
      Logger.info(
        "[Eeyeore.Settings] color changed from #{inspect(state.color)} to #{inspect(color)}"
      )

      broadcast_message({:color_changed, color}, state.subs)
    end

    {:noreply,
     %State{
       color: color,
       brightness: state.brightness,
       quantity: state.quantity,
       subs: state.subs
     }}
  end

  @doc """
  Recieves a brightness setting in the format of an integer between 0 and 100,
  if the brightness has changed it will broadcast the change to subscribers.
  """
  def handle_cast({:set_brightness, brightness}, state)
      when is_integer(brightness) and brightness >= 0 and brightness <= 100 do
    if brightness != state.brightness do
      broadcast_message({:brightness_changed, brightness}, state.subs)
    end

    {:noreply,
     %State{
       color: state.color,
       brightness: brightness,
       quantity: state.quantity,
       subs: state.subs
     }}
  end

  @doc """
  Recieves a quantity setting in the format of an integer >= 1, if the
  quantity has changed it will broadcast the change to subscribers.
  """
  def handle_cast({:set_quantity, quantity}, state) when is_integer(quantity) and quantity >= 1 do
    if quantity != state.quantity do
      broadcast_message({:quantity_changed, quantity}, state.subs)
    end

    {:noreply,
     %State{
       color: state.color,
       brightness: state.brightness,
       quantity: quantity,
       subs: state.subs
     }}
  end

  # TODO: Remove this when storage across reboot is implemented
  @doc """
  Handles unknown cast gracefully, this will be depricated when settings state
  is stored between reboots with something like PersistantStorage
  """
  def handle_cast(unhandled, state) do
    Logger.info("[Eeyeore.Settings] Unhandled cast: #{inspect(unhandled)}")
    {:noreply, state}
  end

  @doc """
  Gets the current color setting
  """
  def handle_call(:get_color, _from, state) do
    {:reply, state.color, state}
  end

  @doc """
  Gets the current brightness setting
  """
  def handle_call(:get_brightness, _from, state) do
    {:reply, state.brightness, state}
  end

  @doc """
  Gets the current quantity setting
  """
  def handle_call(:get_quantity, _from, state) do
    {:reply, state.quantity, state}
  end

  # TODO: Remove this when storage across reboot is implemented
  @doc """
  Handles unknown call gracefully, this will be depricated when settings state
  is stored between reboots with something like PersistantStorage
  """
  def handle_call(unhandled_call, _from, state) do
    Logger.info("[Eeyeore.Settings] Unhandled Call: #{inspect(unhandled_call)}")
    {:reply, "", state}
  end

  defp broadcast_message(message, subscribers) do
    Enum.each(subscribers, fn sub_pid ->
      GenServer.cast(sub_pid, message)
    end)
  end
end
