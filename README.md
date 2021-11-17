# Eeyeore

Firmware for a cloud that flashes like lightning.

[![Demo Lightning Cloud](docs/images/LightningCloud.gif)](https://vimeo.com/646318158)


I saw a few examples of people making these clouds out of paper and polyester,
but wanted something a little more interactive. This project does so by adding a
network of addressable LED strips in such a layout that it's a web of
permutations providing different angles and lengths allowing the cloud to flash
at random places.

[![works with MQTT Homie](https://homieiot.github.io/img/works-with-homie.svg)](https://homieiot.github.io/)

Homie v4.0.0


## Getting Started

This project uses Elixir Nerves to build and deploy onto your embedded target.
Set your target `export MIX_TARGET=my_target`, [see the Nerves Target
documentation about what targets are available.](https://hexdocs.pm/nerves/targets.html#content)

If you want to pass MQTT messages, you'll need to supply a server address and
credentials to the configuration. `MQTT_SERVER_ADDRESS`, `MQTT_USERNAME`, `MQTT_PASSWORD`


1. Set required and optional environment variables:
  ```
  export MIX_TARGET=rpi3
  export NERVES_TIME_SERVERS=\"1.pool.ntp.org\",\"2.pool.ntp.org\"
  export MQTT_SERVER_ADDRESS=mqtt_server.local
  export MQTT_USERNAME=guest
  export MQTT_PASSWORD=guest
  ```
2. Install dependencies
  ```
  mix deps.get
  ```
3. Compile the code and burn it to an SD card
  ```
  mix firmware
  mix firmware.burn
  ```
