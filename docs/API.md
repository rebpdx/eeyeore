### HTTP JSON calls

### MQTT Homie calls

This follows the [Homie Convention](https://homieiot.github.io/#) which is
compatible with other Homie IoT devices including the OpenHAB MQTT Homie Binding.

```
homie/eeyeore-1/$homie -> "4.0.0"
homie/eeyeore-1/$name -> "Eeyeore"
homie/eeyeore-1/$nodes -> "light"
homie/eeyeore-1/$implementation -> "nerves"
homie/eeyeore-1/light/$name -> "Lightning"
homie/eeyeore-1/light/$type -> "Controls settings and triggers lightning"
homie/eeyeore-1/light/$properties -> "color,brightness,quantity,trigger,multi-trigger"
homie/eeyeore-1/light/color/$name -> "Lightning Color"
homie/eeyeore-1/light/color/$datatype -> "color"
homie/eeyeore-1/light/color/$format -> "rgb"
homie/eeyeore-1/light/color/$settable -> "true"
homie/eeyeore-1/light/color -> "162,83,252"
homie/eeyeore-1/light/brightness/$name -> "Lightning brightness"
homie/eeyeore-1/light/brightness/$datatype -> "integer"
homie/eeyeore-1/light/brightness/$format -> "0:100"
homie/eeyeore-1/light/brightness/$unit -> "%"
homie/eeyeore-1/light/brightness/$settable -> "true"
homie/eeyeore-1/light/brightness -> "100"
homie/eeyeore-1/light/quantity/$name -> "Bolts per trigger"
homie/eeyeore-1/light/quantity/$datatype -> "integer"
homie/eeyeore-1/light/quantity/$unit -> "#"
homie/eeyeore-1/light/quantity/$format -> "1:100"
homie/eeyeore-1/light/quantity/$settable -> "true"
homie/eeyeore-1/light/quantity -> "15"
homie/eeyeore-1/light/trigger/$name -> "Trigger lighting"
homie/eeyeore-1/light/trigger/$datatype -> "enum"
homie/eeyeore-1/light/trigger/$format -> "PRESSED,RELEASED"
homie/eeyeore-1/light/trigger/$retained -> "false"
homie/eeyeore-1/light/trigger/$settable -> "true"
homie/eeyeore-1/light/multi-trigger/$name -> "Trigger lighting"
homie/eeyeore-1/light/multi-trigger/$datatype -> "integer"
homie/eeyeore-1/light/multi-trigger/$unit -> "#"
homie/eeyeore-1/light/multi-trigger/$format -> "1:100"
homie/eeyeore-1/light/multi-trigger/$retained -> "false"
homie/eeyeore-1/light/multi-trigger/$settable -> "true"
homie/eeyeore-1/$state -> "ready"
```
