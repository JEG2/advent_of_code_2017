defmodule HexEd do
  def run([path]) do
    solve(path, &count_moves/2)
  end
  def run(["-f", path]) do
    solve(path, &count_furthest/2)
  end
  def run(_args) do
    IO.puts "USAGE:  elixir #{Path.basename(__ENV__.file)} " <>
            "[-f] INPUT_FILE_PATH"
  end

  defp solve(path, counter) do
    path
    |> File.read!
    |> String.trim
    |> String.split(",")
    |> counter.({0, 0, 0})
    |> IO.puts
  end

  defp count_moves(directions, location) do
    directions
    |> Enum.reduce(location, &move/2)
    |> calculate_distance()
  end

  defp move("n",  {x, y, z}), do: {x, y + 1, z - 1}
  defp move("ne", {x, y, z}), do: {x + 1, y, z - 1}
  defp move("se", {x, y, z}), do: {x + 1, y - 1, z}
  defp move("s",  {x, y, z}), do: {x, y - 1, z + 1}
  defp move("sw", {x, y, z}), do: {x - 1, y, z + 1}
  defp move("nw", {x, y, z}), do: {x - 1, y + 1, z}

  defp calculate_distance({x, y, z}) do
    (abs(x) + abs(y) + abs(z)) / 2
    |> round
  end

  defp count_furthest(directions, location) do
    directions
    |> Enum.reduce({location, 0}, fn direction, {xyz, furthest} ->
      new_xyz = move(direction, xyz)
      {new_xyz, Enum.max([furthest, calculate_distance(new_xyz)])}
    end)
    |> elem(1)
  end
end

System.argv
|> HexEd.run
