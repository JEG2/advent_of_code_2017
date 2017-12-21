defmodule CircularBuffer do
  defstruct cursor: 0, values: %{0 => 0}

  def new, do: %__MODULE__{ }

  def put(%__MODULE__{cursor: cursor, values: values}, value, cycle) do
    [steps] =
      cursor
      |> Stream.iterate(fn c -> values[c] end)
      |> Stream.drop(rem(cycle, map_size(values)))
      |> Enum.take(1)
    new_values =
      values
      |> Map.put(value, values[steps])
      |> Map.put(steps, value)
    %__MODULE__{cursor: value, values: new_values}
  end

  def short_circuit(
    %__MODULE__{cursor: cursor, values: values},
    previous \\ nil
  ) do
    Map.fetch!(values, previous || cursor)
  end
end

defmodule ZeroBuffer do
  defstruct cursor: 0, value: 0, size: 1

  def new, do: %__MODULE__{ }

  def put(
    %__MODULE__{cursor: cursor, value: old_value, size: size},
    value,
    cycle
  ) do
    new_size = size + 1
    new_cursor = rem(rem(cursor + cycle, size) + 1, new_size)
    new_value = if new_cursor == 1, do: value, else: old_value
    %__MODULE__{cursor: new_cursor, value: new_value, size: new_size}
  end

  def short_circuit(%__MODULE__{value: value}), do: value
end

defmodule Spinlock do
  def run([cycle]) do
    cycle = String.to_integer(cycle)
    Enum.reduce(1..2017, CircularBuffer.new, fn value, buffer ->
      CircularBuffer.put(buffer, value, cycle)
    end)
    |> CircularBuffer.short_circuit
    |> IO.puts
  end
  def run(["-a", cycle]) do
    cycle = String.to_integer(cycle)
    Enum.reduce(1..50_000_000, ZeroBuffer.new, fn value, buffer ->
      ZeroBuffer.put(buffer, value, cycle)
    end)
    |> ZeroBuffer.short_circuit
    |> IO.puts
  end
  def run(_args) do
    IO.puts "USAGE:  elixir #{Path.basename(__ENV__.file)} " <>
            "[-a] INPUT_FILE_PATH"
  end
end

System.argv
|> Spinlock.run
