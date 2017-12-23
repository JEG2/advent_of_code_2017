defmodule Tubes do
  def run([path]) do
    solve(path, fn result -> elem(result, 0) end)
  end
  def run(["-c", path]) do
    solve(path, fn result -> elem(result, 1) end)
  end
  def run(_args) do
    IO.puts "USAGE:  elixir #{Path.basename(__ENV__.file)} " <>
            "[-c] INPUT_FILE_PATH"
  end

  defp solve(path, result) do
    path
    |> File.read!
    |> parse_tubes
    |> walk_tubes
    |> result.()
    |> IO.puts
  end

  defp parse_tubes(input) do
    x = input |> String.graphemes |> Enum.find_index(&(&1 == "|"))
    tubes =
      input
      |> String.split("\n", trim: true)
      |> Enum.map(fn line -> line |> String.graphemes |> List.to_tuple end)
      |> List.to_tuple
    {{x, 0}, :down, tubes}
  end

  defp walk_tubes(context, path \\ [ ], steps \\ 0)
  defp walk_tubes({{x, y}, _direction, tubes}, path, steps)
  when x < 0 or y < 0
  or x >= (tubes |> elem(0) |> tuple_size) or y >= tuple_size(tubes)
  or not (tubes |> elem(y) |> elem(x)) in ~w[
    - | +
    A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
  ] do
    {path |> Enum.reverse |> Enum.join(""), steps}
  end
  defp walk_tubes({{x, y}, direction, tubes}, path, steps)
  when (tubes |> elem(y) |> elem(x)) == "+" and direction in ~w[up down]a do
    {new_xy, new_direction} =
    if x > 0 and (tubes |> elem(y) |> elem(x - 1)) in ~w[
      - A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
    ] do
        {{x - 1, y}, :left}
      else
        {{x + 1, y}, :right}
      end
    walk_tubes({new_xy, new_direction, tubes}, path, steps + 1)
  end
  defp walk_tubes({{x, y}, direction, tubes}, path, steps)
  when (tubes |> elem(y) |> elem(x)) == "+"
  and direction in ~w[left right]a do
    {new_xy, new_direction} =
    if y > 0 and (tubes |> elem(y - 1) |> elem(x)) in ~w[
      | A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
    ] do
        {{x, y - 1}, :up}
      else
        {{x, y + 1}, :down}
      end
    walk_tubes({new_xy, new_direction, tubes}, path, steps + 1)
  end
  defp walk_tubes({{x, y}, :up, tubes}, path, steps)
  when (tubes |> elem(y) |> elem(x)) != "+" do
    walk_tubes(
      {{x, y - 1}, :up, tubes},
      track_path(tubes |> elem(y) |> elem(x), path),
      steps + 1
    )
  end
  defp walk_tubes({{x, y}, :down, tubes}, path, steps)
  when (tubes |> elem(y) |> elem(x)) != "+" do
    walk_tubes(
      {{x, y + 1}, :down, tubes},
      track_path(tubes |> elem(y) |> elem(x), path),
      steps + 1
    )
  end
  defp walk_tubes({{x, y}, :left, tubes}, path, steps)
  when (tubes |> elem(y) |> elem(x)) != "+" do
    walk_tubes(
      {{x - 1, y}, :left, tubes},
      track_path(tubes |> elem(y) |> elem(x), path),
      steps + 1
    )
  end
  defp walk_tubes({{x, y}, :right, tubes}, path, steps)
  when (tubes |> elem(y) |> elem(x)) != "+" do
    walk_tubes(
      {{x + 1, y}, :right, tubes},
      track_path(tubes |> elem(y) |> elem(x), path),
      steps + 1
    )
  end

  defp track_path(tube, path) when not tube in ~w[- | +], do: [tube | path]
  defp track_path(_tube, path), do: path
end

System.argv
|> Tubes.run
