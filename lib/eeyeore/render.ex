defmodule Eeyeore.Render do
  use GenServer
  require Logger

  @moduledoc """
  Render module receives calls to render lightning strikes on blinkchain devices.

  The render utilizes send_after messages to simulate random lightning strikes,
  if a handle_cast is received before the messages are complete it will append
  them to the existing queue.
  """

  alias Blinkchain.Point
  alias Blinkchain.Color

  @doc """
  State contains, LED configuration, next bolt to flash, and a reference to the
  last send_after message for a single lightning strike render
  """
  defmodule State do
    # TODO: Do we need bolt location in the state? Or can we just call the
    #       random function at render time
    defstruct [:config, :bolt, :timer]
  end

  def start_link(opts) do
    config =
      opts
      |> Keyword.get(:config)
      |> Eeyeore.Config.load()

    GenServer.start_link(__MODULE__, config, name: __MODULE__)
  end

  @doc """
  Initializes the renderer which simulates lightning bolts. Will fire a single
  bolt shortly after initialization is complete.
  """
  def init(config) do
    # Application.get_all_env(:eeyeore)
    Logger.debug("Starting Eeyeore GenServer #{inspect(self())}")
    # Logger.debug "Initial Config: #{inspect config}"
    # port = Application.get_env(:webhook, :port)

    # Send an initial strike at 1 seconds after startup
    # RPi could be still booting, so give it some time
    Process.send_after(self(), :strike, 10000)

    state = %State{
      config: config,
      bolt: random_bolt(config),
      # Carries a reference to the last send_after message
      timer: nil
    }

    Logger.debug("Initial State: #{inspect(state)}")

    {:ok, state}
  end

  @doc """
  Handles a cast to simulates 1-10 intermittent lightning strikes.
  """
  def handle_cast(:lightning, state) do
    num_bolts = :rand.uniform(10)
    Logger.info("Initializing random #{num_bolts} intermittent lightning strikes")
    timer_ref = init_strike_messages(num_bolts, state.timer)

    # Audio support is in RPi3 and RPi4
    # https://github.com/nerves-project/nerves_system_rpi4#audio
    # :os.cmd('aplay -q /tmp/out.wav')

    {:noreply, %State{config: state.config, bolt: state.bolt, timer: timer_ref}}
  end

  @doc """
  Handles a cast to simulate x number of intermittent lightning strikes.
  """
  def handle_cast({:lightning, quantity}, state) do
    Logger.info("Initializing given quantity of #{quantity} intermittent lightning strikes")

    timer_ref = init_strike_messages(quantity, state.timer)

    {:noreply, %State{config: state.config, bolt: state.bolt, timer: timer_ref}}
  end

  @doc """
  Handles a single strike which begins immediately
  """
  def handle_cast(:strike, state) do
    Logger.debug("One full bolt immediately")
    Logger.info("Rendering single lightning strike")

    {first, last} = get_leds(state.bolt, state.config)

    color = GenServer.call(Eeyeore.Settings, :get_color)
    single_strike(first, last, color)

    {:noreply, %State{config: state.config, bolt: random_bolt(state.config), timer: state.timer}}
  end

  @doc """
  Handles lighting up a static strip mostly used for testing the LEDs
  """
  def handle_cast({:strip, quantity, start}, state) do
    Logger.info("Rendering a strip of #{quantity} leds, starting at LED #{start}")

    color = GenServer.call(Eeyeore.Settings, :get_color)
    render_strip(quantity, start, color)

    {:noreply, state}
  end

  @doc """
  Handles a single strike beginning immediately
  """
  def handle_info(:strike, state) do
    Logger.debug("One full bolt from timer message")
    Logger.info("Rendering single lightning strike")

    {first, last} = get_leds(state.bolt, state.config)

    color = GenServer.call(Eeyeore.Settings, :get_color)
    single_strike(first, last, color)

    {:noreply, %State{config: state.config, bolt: random_bolt(state.config), timer: state.timer}}
  end

  defp init_strike_messages(n, timer_ref) when is_nil(timer_ref) do
    assemble_strike_messages(n, 0)
  end

  defp init_strike_messages(n, timer_ref) do
    # Append to the existing messages if there are any in the queue
    time_remaining = Process.read_timer(timer_ref)

    case time_remaining do
      false -> assemble_strike_messages(n, 0)
      _ -> assemble_strike_messages(n, time_remaining)
    end
  end

  defp random_bolt(%{arrangement: config}) do
    count = Enum.count(config)
    :rand.uniform(count) - 1
  end

  defp assemble_strike_messages(n, time) when n <= 1 do
    Logger.debug("Setting up last send_after at #{time}ms")
    Process.send_after(self(), :strike, time)
  end

  defp assemble_strike_messages(n, time) do
    Logger.debug("Setting up message #{n} for send_after at #{time}ms")
    Process.send_after(self(), :strike, time)
    new_time = time + :rand.uniform(10) * 1000
    assemble_strike_messages(n - 1, new_time)
  end

  defp render_strip(number, start, color) do
    clear_leds()
    build_strip(number, start, color)
  end

  defp single_strike(first, last, color) do
    # Initial Strike
    render_bolt(first, last, color, 50, 60)
    # Main Strike
    render_bolt(first, last, color, 100, 30)
    # After Strike
    render_bolt(first, last, color, 50, 150)
    # Clear Everything
    clear_leds()
  end

  defp render_bolt(first, last, color, brightness, delay) do
    set_bolt_pixels(first, last, color, brightness)

    # Hold the render
    :timer.sleep(delay)
  end

  defp set_bolt_pixels(first, last, color, brightness) do
    clear_canvas()

    # Set canvas brightness
    Blinkchain.set_brightness(0, round(255 * (brightness / 100)))

    # Set canvas and render
    build_strip(first + last, first, color)
  end

  defp get_leds(bolt, %{arrangement: config}) do
    bolt_config = Enum.at(config, bolt)

    {:ok, first} =
      bolt_config
      |> Map.fetch(:first)

    {:ok, last} =
      bolt_config
      |> Map.fetch(:last)

    {first, last}
  end

  defp build_strip(number, start, color) when number <= 1 do
    Blinkchain.set_pixel(%Point{x: number + start - 1, y: 0}, color)
    Blinkchain.render()
  end

  defp build_strip(number, start, color) do
    Blinkchain.set_pixel(%Point{x: number + start - 1, y: 0}, color)
    build_strip(number - 1, start, color)
  end

  defp clear_leds() do
    clear_canvas()
    Blinkchain.render()
  end

  defp clear_canvas() do
    {fillx, filly} = Application.get_env(:blinkchain, :canvas)
    Blinkchain.fill(%Point{x: 0, y: 0}, fillx, filly, Color.parse("#000000"))
  end
end
