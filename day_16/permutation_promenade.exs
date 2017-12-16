defmodule PermutationPromenade do
  def run([initial_positions, path]) do
    solve(initial_positions, path, &dance/2)
  end
  def run(["-f", initial_positions, path]) do
    solve(initial_positions, path, &full_dance/2)
  end
  def run(_args) do
    IO.puts "USAGE:  elixir #{Path.basename(__ENV__.file)} " <>
            "[-f] INPUT_FILE_PATH"
  end

  defp solve(initial_positions, path, mover) do
    dancers = String.graphemes(initial_positions)
    size = length(dancers)
    path
    |> File.read!
    |> String.trim
    |> String.split(",")
    |> Enum.map(fn
      "s" <> x ->
        {:spin, size - String.to_integer(x)}
      "x" <> ab ->
        [a, b] = ab |> String.split("/") |> Enum.map(&String.to_integer/1)
        {:exchange, a, b}
      <<"p", a::utf8, "/", b::utf8>> ->
        {:partner, <<a>>, <<b>>}
    end)
    |> mover.(dancers)
    |> Enum.join("")
    |> IO.puts
  end

  defp dance([{:spin, leading} | moves], dancers) do
    new_dancers = Enum.drop(dancers, leading) ++ Enum.take(dancers, leading)
    dance(moves, new_dancers)
  end
  defp dance([{:exchange, a, b} | moves], dancers) do
    new_dancers =
      dancers
      |> List.replace_at(a, Enum.at(dancers, b))
      |> List.replace_at(b, Enum.at(dancers, a))
    dance(moves, new_dancers)
  end
  defp dance([{:partner, a, b} | moves], dancers) do
    new_dancers =
      dancers
      |> List.replace_at(Enum.find_index(dancers, &(&1 == a)), b)
      |> List.replace_at(Enum.find_index(dancers, &(&1 == b)), a)
    dance(moves, new_dancers)
  end
  defp dance([ ], dancers), do: dancers

  defp full_dance(moves, dancers) do
    repeat = find_repeat(moves, dancers, dancers, 1)
    dancers
    |> Stream.iterate(&dance(moves, &1))
    |> Stream.drop(rem(1_000_000_000, repeat))
    |> Enum.take(1)
    |> hd()
  end

  defp find_repeat(moves, dancers, start, count) do
    new_dancers = dance(moves, dancers)
    if new_dancers == start do
      count
    else
      find_repeat(moves, new_dancers, start, count + 1)
    end
  end
end

System.argv
|> PermutationPromenade.run
