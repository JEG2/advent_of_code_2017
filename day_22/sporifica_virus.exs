defmodule SporificaVirus do
  defstruct grid: Map.new,
            location: {0, 0},
            direction: :north,
            infecting_bursts: 0

  def run([path]) do
    solve(path, 10_000, &burst/1)
  end
  def run(["-e", path]) do
    solve(path, 10_000_000, &evolved_burst/1)
  end
  def run(_args) do
    IO.puts "USAGE:  elixir #{Path.basename(__ENV__.file)} " <>
            "[-e] INPUT_FILE_PATH"
  end

  defp solve(path, bursts, logic) do
    path
    |> File.stream!
    |> Stream.map(&String.trim(&1))
    |> Enum.to_list
    |> build_cluster
    |> work(logic, bursts)
    |> Map.fetch!(:infecting_bursts)
    |> IO.puts
  end

  defp build_cluster(input) do
    height = length(input)
    width = input |> hd |> String.length
    x_offset = -div(width, 2)
    y_offset = div(height, 2)
    grid =
      input
      |> Enum.with_index
      |> Enum.reduce(Map.new, fn {row, y}, grid ->
        row
        |> String.graphemes
        |> Enum.with_index
        |> Enum.reduce(grid, fn
          {"#", x}, nodes -> Map.put(nodes, {x + x_offset, y_offset - y}, "#")
          {".", _x}, nodes -> nodes
        end)
      end)
    %__MODULE__{grid: grid}
  end

  defp work(cluster, logic, bursts) when bursts > 0 do
    cluster
    |> logic.()
    |> work(logic, bursts - 1)
  end
  defp work(cluster, _logic, 0), do: cluster

  defp burst(
    %__MODULE__{
      grid: grid,
      location: location,
      direction: direction,
      infecting_bursts: infecting_bursts
    }
  ) do
    infected? = Map.get(grid, location) == "#"
    {new_grid, new_infecting_bursts} =
      if infected? do
        {Map.delete(grid, location), infecting_bursts}
      else
        {Map.put(grid, location, "#"), infecting_bursts + 1}
      end
    {new_location, new_direction} =
      turn_and_move(location, direction, infected?)
    %__MODULE__{
      grid: new_grid,
      location: new_location,
      direction: new_direction,
      infecting_bursts: new_infecting_bursts
    }
  end

  defp turn_and_move({x, y}, :north, true), do: {{x + 1, y}, :east}
  defp turn_and_move({x, y}, :north, false), do: {{x - 1, y}, :west}
  defp turn_and_move({x, y}, :east, true), do: {{x, y - 1}, :south}
  defp turn_and_move({x, y}, :east, false), do: {{x, y + 1}, :north}
  defp turn_and_move({x, y}, :south, true), do: {{x - 1, y}, :west}
  defp turn_and_move({x, y}, :south, false), do: {{x + 1, y}, :east}
  defp turn_and_move({x, y}, :west, true), do: {{x, y + 1}, :north}
  defp turn_and_move({x, y}, :west, false), do: {{x, y - 1}, :south}

  defp evolved_burst(
    %__MODULE__{
      grid: grid,
      location: location,
      direction: direction,
      infecting_bursts: infecting_bursts
    }
  ) do
    node = Map.get(grid, location, ".")
    {new_grid, new_infecting_bursts} =
      case node do
        "." -> {Map.put(grid, location, "W"), infecting_bursts}
        "W" -> {Map.put(grid, location, "#"), infecting_bursts + 1}
        "#" -> {Map.put(grid, location, "F"), infecting_bursts}
        "F" -> {Map.delete(grid, location), infecting_bursts}
      end
    {new_location, new_direction} =
      evolved_turn_and_move(location, direction, node)
    %__MODULE__{
      grid: new_grid,
      location: new_location,
      direction: new_direction,
      infecting_bursts: new_infecting_bursts
    }
  end

  defp evolved_turn_and_move({x, y}, :north, "."), do: {{x - 1, y}, :west}
  defp evolved_turn_and_move({x, y}, :north, "W"), do: {{x, y + 1}, :north}
  defp evolved_turn_and_move({x, y}, :north, "#"), do: {{x + 1, y}, :east}
  defp evolved_turn_and_move({x, y}, :north, "F"), do: {{x, y - 1}, :south}
  defp evolved_turn_and_move({x, y}, :east, "."), do: {{x, y + 1}, :north}
  defp evolved_turn_and_move({x, y}, :east, "W"), do: {{x + 1, y}, :east}
  defp evolved_turn_and_move({x, y}, :east, "#"), do: {{x, y - 1}, :south}
  defp evolved_turn_and_move({x, y}, :east, "F"), do: {{x - 1, y}, :west}
  defp evolved_turn_and_move({x, y}, :south, "."), do: {{x + 1, y}, :east}
  defp evolved_turn_and_move({x, y}, :south, "W"), do: {{x, y - 1}, :south}
  defp evolved_turn_and_move({x, y}, :south, "#"), do: {{x - 1, y}, :west}
  defp evolved_turn_and_move({x, y}, :south, "F"), do: {{x, y + 1}, :north}
  defp evolved_turn_and_move({x, y}, :west, "."), do: {{x, y - 1}, :south}
  defp evolved_turn_and_move({x, y}, :west, "W"), do: {{x - 1, y}, :west}
  defp evolved_turn_and_move({x, y}, :west, "#"), do: {{x, y + 1}, :north}
  defp evolved_turn_and_move({x, y}, :west, "F"), do: {{x + 1, y}, :east}
end

System.argv
|> SporificaVirus.run
