defmodule Eeyeore.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    leds_off(target())

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Eeyeore.Supervisor]

    children =
      [
        # Children for all targets
        # Starts a worker by calling: Eeyeore.Render.start_link(arg)
      ] ++ children(target())

    Supervisor.start_link(children, opts)
  end

  # List all child processes to be supervised
  def children(:host) do
    [
      # Children that only run on the host
      # Starts a worker by calling: Eeyeore.Render.start_link(arg)
    ]
  end

  def children(_target) do
    [
      # Children for all targets except host
      # TODO: Add a scheduled call for Eeyeore.Weather

      Eeyeore.Settings,
      webhook_child_spec(),
      mqtt_endpoint_spec(),
      mqtt_connection_spec(),
      Eeyeore.Render
    ]
  end

  def leds_off(:host) do
    # Test infrastructure on host machine doesn't have RPi LEDs
  end

  def leds_off(_target) do
    # Default board LEDs to off
    Nerves.Leds.set(power: false)
    Nerves.Leds.set(activity: false)
  end

  def target() do
    Application.get_env(:eeyeore, :target)
  end

  defp webhook_child_spec() do
    # TODO: Add support for certs to have a secure connection to our HTTP port
    web_port = Application.get_env(:eeyeore, :webhook_port, 80)

    Plug.Cowboy.child_spec(
      scheme: :http,
      plug: Webhook.Endpoint,
      options: [port: web_port]
    )
  end

  defp mqtt_connection_spec() do
    device_id = get_mqtt_device_id()
    mqtt_host = Application.get_env(:eeyeore, :mqtt_broker_address)
    mqtt_port = Application.get_env(:eeyeore, :mqtt_port, 1883)
    mqtt_user_name = Application.get_env(:eeyeore, :mqtt_user_name)
    mqtt_password = Application.get_env(:eeyeore, :mqtt_password)

    # TODO: Add support for certs to have a secure connection to MQTT
    {Tortoise.Connection,
     [
       client_id: device_id,
       handler: {Mqtt.Handler, [device_id]},
       server: {Tortoise.Transport.Tcp, host: mqtt_host, port: mqtt_port},
       user_name: "#{mqtt_user_name}",
       password: "#{mqtt_password}",
       will: %Tortoise.Package.Publish{
         topic: "homie/#{device_id}/$state",
         payload: "lost",
         qos: 1,
         retain: true
       },
       subscriptions: [{"homie/#{device_id}/light/+/set", 1}]
     ]}
  end

  defp mqtt_endpoint_spec() do
    {Mqtt.Endpoint, [get_mqtt_device_id()]}
  end

  defp get_mqtt_device_id() do
    client_id = Application.get_env(:eeyeore, :mqtt_unique_id, 1)
    "eeyeore_#{client_id}"
  end
end
