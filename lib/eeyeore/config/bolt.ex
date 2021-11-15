defmodule Eeyeore.Config.Bolt do
  require Logger

  @moduledoc """
  Represents a single bolt, as a strip of LEDs in blinkchain.

  *`id`: The number in the array of bolts
  *`length`: The number of LEDs in the bolt
  *`start`: The first LED in the strip
  *`end`: The last LED in the strip
  *`neighbors`: Any neighboring strips that may be connected

  ## Example

  If we have a few strips of LEDs that look like this
  ```
          \      *
           \    / \
    \       \  /  3
     1       \/   |
      \      /\   |
       \    /  \  |
        \  2    4 |
         \/      \|
         *        *
  ```
  The `*` represents a wired connection to the next array of LEDs, and the
  number represents each bolt of lightning. From here we can count the number of
  LEDs in each bolt and start modeling the structure in eeyeore.exs declaring the
  size and provide info if the bolt is a neighbor. The neighbor is used to light
  multiple bolts at once simulating the longer bolts that sometimes occur in
  clouds.

  For now until the config module is updated to do the math for you there are
  two additional values that need to be declared in eeyeore.exs, `id` and
  `first`. `id` is just a counter to give each bolt a unique number as shown in
  the diagram above. `first` is the sum of LEDs before the current bolt in the
  WS2812 address space.

  ```
  config :eeyeore,
    arrangement: [
      %{ id: 1, length: 6, first: 0,  neighbors: [2]    },
      %{ id: 2, length: 7, first: 6,  neighbors: [1, 3] },
      %{ id: 3, length: 7, first: 13, neighbors: [2, 4] },
      %{ id: 4, length: 8, first: 20, neighbors: [2, 3] },
    ]
  ```
  """

  alias __MODULE__

  @typedoc @moduledoc
  @type t :: %__MODULE__{
          id: non_neg_integer(),
          length: non_neg_integer(),
          first: non_neg_integer(),
          last: non_neg_integer,
          neighbors: [non_neg_integer()]
        }

  defstruct id: 1,
            length: 6,
            first: 0,
            last: 6,
            neighbors: nil

  def new(config) do
    {:ok, id} =
      config
      |> Map.fetch(:id)

    {:ok, length} =
      config
      |> Map.fetch(:length)

    {:ok, first} =
      config
      |> Map.fetch(:first)

    {:ok, neighbors} =
      config
      |> Map.fetch(:neighbors)

    %Bolt{
      id: id,
      length: length,
      first: first,
      last: set_last(first, length),
      neighbors: neighbors
    }
  end

  def set_last(first, length) do
    first + length - 1
  end
end
