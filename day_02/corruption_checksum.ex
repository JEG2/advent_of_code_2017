defmodule CorruptionChecksum do
  def run([path]) do
    process(path, &largest_difference/1)
  end
  def run(["-d", path]) do
    process(path, &even_division/1)
  end
  def run(_args) do
    IO.puts "USAGE:  elixir #{Path.basename(__ENV__.file)} " <>
            "[-d] INPUT_FILE_PATH"
  end

  defp process(path, checksum) do
    path
    |> File.stream!
    |> checksum.()
    |> IO.puts
  end

  defp largest_difference(input) do
    sum_rows(input, fn row ->
      {min, max} = Enum.min_max(row)
      max - min
    end)
  end

  defp even_division(input) do
    sum_rows(input, fn row ->
      0..(length(row) - 2)
      |> Stream.flat_map(fn i ->
        (i + 1)..(length(row) - 1)
        |> Enum.map(fn j -> Enum.sort([Enum.at(row, i), Enum.at(row, j)]) end)
      end)
      |> Stream.map(fn [low, high] -> high / low end)
      |> Enum.find(fn n -> n == round(n) end)
      |> round
    end)
  end

  defp sum_rows(input, calculation) do
    input
    |> Stream.map(fn row ->
      Regex.scan(~r{\d+}, row, capture: :first)
      |> Enum.map(fn [n] -> String.to_integer(n) end)
    end)
    |> Stream.map(calculation)
    |> Enum.sum
  end
end

System.argv
|> CorruptionChecksum.run
