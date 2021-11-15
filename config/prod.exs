use Mix.Config

if Mix.target() != :host do
  import_config "target.exs"
end

import_config "eeyeore.exs"
