defmodule Eeyeore.Config do
  @moduledoc """
  Represents the arrangement of multiple bolts, based on how the LEDs are wired.

  *`arrangement`: The configuration of bolts
  """
  alias Eeyeore.Config
  alias Eeyeore.Config.Bolt

  @typedoc @moduledoc
  @type t :: %__MODULE__{
          arrangement: [Bolt.t()]
        }

  defstruct arrangement: [:bolt]

  @doc """
  Build a `t:Eeyeore.Config.t/0` struct based on Application configuration.
  """
  @spec load(Keyword.t() | nil) :: Config.t()
  def load(nil) do
    :eeyeore
    |> Application.get_all_env()
    |> load()
  end

  def load(config) when is_list(config) do
    bolts =
      config
      |> Keyword.get(:arrangement)
      |> load_arrangement_config()

    %Config{
      arrangement: bolts
    }
  end

  # Private Helpers

  defp load_arrangement_config(config) when is_list(config) do
    config
    |> append_id()
    |> append_first()
    |> Enum.map(&Bolt.new/1)
    |> List.flatten()
  end

  defp load_arrangement_config(_arrangement) do
    raise "You must set the :arrangement of LED strips as a list of bolts"
  end

  defp append_id(list) do
    Enum.reduce(list, [], fn
      item, acc when acc == [] ->
        [Map.put(item, :id, 1)]

      item, acc ->
        [prev | _] = acc
        new_map = Map.put(item, :id, prev.id + 1)
        [new_map | acc]
    end)
    |> Enum.reverse()
  end

  defp append_first(list) do
    Enum.reduce(list, [], fn
      item, acc when acc == [] ->
        [Map.put(item, :first, 0)]

      item, acc ->
        [prev | _] = acc
        new_map = Map.put(item, :first, prev.length + prev.first)
        [new_map | acc]
    end)
    |> Enum.reverse()
  end
end
