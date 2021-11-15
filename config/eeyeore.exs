# This file is responsible for configuring Eeyeore settings

use Mix.Config

config :eeyeore, target: Mix.target()

# Used for port to listen to HTTP POST request calls
config :eeyeore,
  webhook_port: 80

# Used for mqtt configuration
config :eeyeore,
  mqtt_broker_address: System.get_env("MQTT_SERVER_ADDRESS"),
  mqtt_user_name: System.get_env("MQTT_USERNAME"),
  mqtt_password: System.get_env("MQTT_PASSWORD"),
  # Prefixed with target.exs:node_name, for when you have multiple physical clouds
  mqtt_unique_id: "1"

# Use to configure strand of LEDs, where each row represents a bolt/section
config :eeyeore,
  arrangement: [
    %{length: 14, neighbors: [2]},
    %{length: 6, neighbors: [1, 3]},
    %{length: 12, neighbors: [2, 4]},
    %{length: 10, neighbors: [3, 5]},
    %{length: 6, neighbors: [4]},
    %{length: 12, neighbors: []},
    %{length: 10, neighbors: []},
    %{length: 13, neighbors: [9]},
    %{length: 6, neighbors: [8, 10]},
    %{length: 10, neighbors: [9, 11]},
    %{length: 6, neighbors: [7, 8]},
    %{length: 6, neighbors: [13]},
    %{length: 6, neighbors: [12]},
    %{length: 10, neighbors: []}
  ]
