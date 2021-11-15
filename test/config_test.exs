defmodule EeyeoreConfigTest do
  use ExUnit.Case
  doctest Eeyeore.Config

  alias Eeyeore.Config
  alias Eeyeore.Config.Bolt

  test "Validate config loading" do
    # Sample Config to work with
    config = [
      {:arrangement,
       [
         %{length: 14, neighbors: [2]},
         %{length: 6, neighbors: [1, 3]},
         %{length: 12, neighbors: [2, 4]},
         %{length: 10, neighbors: [3, 5]},
         %{length: 6, neighbors: [4]}
       ]}
    ]

    response = Eeyeore.Config.load(config)

    # Validate our configuration is now addressable as an array of individual
    # maps with the Eeyeore Bolt struct and contains, ids, first and last
    assert response == %Config{
             :arrangement => [
               Bolt.new(%{id: 1, length: 14, first: 0, last: 13, neighbors: [2]}),
               Bolt.new(%{id: 2, length: 6, first: 14, last: 19, neighbors: [1, 3]}),
               Bolt.new(%{id: 3, length: 12, first: 20, last: 31, neighbors: [2, 4]}),
               Bolt.new(%{id: 4, length: 10, first: 32, last: 41, neighbors: [3, 5]}),
               Bolt.new(%{id: 5, length: 6, first: 42, last: 47, neighbors: [4]})
             ]
           }
  end

  test "Validate Config environment load" do
    # Set the environment variable to something we know in this test,
    # user may update the config/eeyeore.exs value
    Application.put_env(:eeyeore, :arrangement, [
      %{length: 14, neighbors: [2]},
      %{length: 6, neighbors: [1, 3]}
    ])

    response = Eeyeore.Config.load(nil)

    # Validate our input environment is output in the individual bolt structs
    assert response == %Config{
             :arrangement => [
               %Bolt{id: 1, length: 14, first: 0, last: 13, neighbors: [2]},
               %Bolt{id: 2, length: 6, first: 14, last: 19, neighbors: [1, 3]}
             ]
           }
  end

  test "Validate missing arrangement throws error" do
    assert_raise RuntimeError, fn ->
      # Pass in an empty configuration
      Eeyeore.Config.load([])
    end
  end
end
