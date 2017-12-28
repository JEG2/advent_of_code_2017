defmodule FractalArt do
  def run([path]) do
    solve(path, 5)
  end
  def run(["-l", path]) do
    solve(path, 18)
  end
  def run(_args) do
    IO.puts "USAGE:  elixir #{Path.basename(__ENV__.file)} " <>
            "[-l] INPUT_FILE_PATH"
  end

  defp solve(path, iterations) do
    rules =
      path
      |> File.stream!
      |> Stream.map(fn line ->
        line
        |> String.trim
        |> String.split(" => ")
        |> Enum.map(&String.split(&1, "/"))
      end)
      |> build_rules
    [".#.", "..#", "###"]
    |> Stream.iterate(&expand(&1, rules))
    |> Stream.drop(iterations)
    |> Enum.take(1)
    |> hd
    |> Enum.reduce(0, fn row, sum ->
      sum + (row |> String.graphemes |> Enum.count(&(&1 == "#")))
    end)
    |> IO.puts
  end

  defp build_rules(input) do
    Enum.reduce(input, Map.new, fn [rule, output], rules ->
      flipped = flip(rule)
      add_variations(
        [rule, flipped] ++ rotations(rule) ++ rotations(flipped),
        output,
        rules
      )
    end)
  end

  defp flip([<<nw::utf8, ne::utf8>>, <<sw::utf8, se::utf8>>]) do
    [<<ne, nw>>, <<se, sw>>]
  end
  defp flip([ <<nw::utf8, n::utf8, ne::utf8>>,
              <<w::utf8, c::utf8, e::utf8>>,
              <<sw::utf8, s::utf8, se::utf8>> ]) do
    [<<ne, n, nw>>, <<e, c, w>>, <<se, s, sw>>]
  end

  defp rotations(rule, turns \\ [ ])
  defp rotations(_rule, turns) when length(turns) >= 3, do: turns
  defp rotations([<<nw::utf8, ne::utf8>>, <<sw::utf8, se::utf8>>], turns) do
    turned = [<<sw, nw>>, <<se, ne>>]
    rotations(turned, [turned | turns])
  end
  defp rotations([ <<nw::utf8, n::utf8, ne::utf8>>,
                   <<w::utf8, c::utf8, e::utf8>>,
                   <<sw::utf8, s::utf8, se::utf8>> ], turns) do
    turned = [<<sw, w, nw>>, <<s, c, n>>, <<se, e, ne>>]
    rotations(turned, [turned | turns])
  end

  defp add_variations(variations, output, rules) do
    Enum.reduce(variations, rules, &Map.put_new(&2, &1, output))
  end

  defp expand(grid, rules) do
    grid
    |> divide
    |> Enum.map(fn row -> Enum.map(row, &Map.fetch!(rules, &1)) end)
    |> rejoin
  end

  defp divide(grid) do
    size = length(grid)
    {square_size, square_count} =
      cond do
        rem(size, 2) == 0 -> {2, div(size, 2)}
        rem(size, 3) == 0 -> {3, div(size, 3)}
        true -> raise "Unexpected size"
      end
    grid
    |> Enum.chunk_every(square_size)
    |> Enum.map(fn divided_rows ->
      Stream.unfold(0, fn
        i when i < square_count ->
          {
            Enum.map(divided_rows, fn row ->
              String.slice(row, i * square_size, square_size)
            end),
            i + 1
          }
        _i ->
          nil
      end)
      |> Enum.take(square_count)
    end)
  end

  defp rejoin(divided) do
    Enum.flat_map(divided, fn chunk ->
      chunk
      |> Enum.zip
      |> Enum.map(&(&1 |> Tuple.to_list |> Enum.join("")))
    end)
  end
end

System.argv
|> FractalArt.run
