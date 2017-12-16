defmodule DuelingGenerators do
  use Bitwise

  def run([pairs, path]) do
    solve(pairs, path, &build_generator/3)
  end
  def run(["-p", pairs, path]) do
    solve(pairs, path, &build_picky_generator/3)
  end
  def run(_args) do
    IO.puts "USAGE:  elixir #{Path.basename(__ENV__.file)} " <>
            "[-r] INPUT_FILE_PATH"
  end

  defp solve(pairs, path, builder) do
    input = File.read!(path)
    Regex.scan(~r{\d+}, input, capture: :first)
    |> Enum.zip([16807, 48271])
    |> Stream.with_index
    |> Enum.map(fn {{[start], factor}, i} -> builder.(start, factor, i) end)
    |> Stream.zip
    |> Stream.transform(0, fn {a, b}, sum ->
      new_sum = sum + if compare(a) == compare(b) do 1 else 0 end
      {[new_sum], new_sum}
    end)
    |> Stream.drop(String.to_integer(pairs) - 1)
    |> Enum.take(1)
    |> hd()
    |> IO.puts
  end

  defp build_generator(start, factor, _i) do
    start
    |> String.to_integer
    |> Stream.iterate(fn current ->
      rem(current * factor, 2147483647)
    end)
    |> Stream.drop(1)
  end

  defp build_picky_generator(start, factor, i) do
    check = (i + 1) * 4
    build_generator(start, factor, i)
    |> Stream.filter(fn n -> rem(n, check) == 0 end)
  end

  defp compare(n), do: n &&& 0xFFFF
end

System.argv
|> DuelingGenerators.run
