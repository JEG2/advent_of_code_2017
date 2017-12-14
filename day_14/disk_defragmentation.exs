defmodule KnotHash do
  use Bitwise, skip_operators: false

  def hash(input, size \\ 256) do
    string =
      0
      |> Stream.iterate(&(&1 + 1))
      |> Enum.take(size)
      |> List.to_tuple
    full_hash(input, string, 0, 0, size)
  end

  defp full_hash(input, string, cursor, skip, size) do
    lengths =
      input
      |> String.to_charlist
      |> Kernel.++([17, 31, 73, 47, 23])
    {string, cursor, skip}
    |> Stream.iterate(fn {str, cur, skp} ->
      tie_knots(lengths, str, cur, skp, size)
    end)
    |> Enum.take(65)
    |> List.last
    |> elem(0)
    |> Tuple.to_list
    |> Enum.chunk_every(16)
    |> Enum.map(fn chunk -> Enum.reduce(chunk, &bxor/2) end)
    |> Enum.map(fn char ->
      char
      |> Integer.to_string(16)
      |> String.pad_leading(2, "0")
    end)
    |> Enum.join("")
    |> String.downcase
  end

  defp tie_knots([length | lengths], string, cursor, skip, size) do
    indices =
      cursor
      |> Stream.iterate(&rem(&1 + 1, size))
      |> Enum.take(length)
    reversed_marks =
      indices
      |> Enum.map(&elem(string, &1))
      |> Enum.reverse
    replacements =
      indices
      |> Enum.zip(reversed_marks)
      |> Enum.into(Map.new)
    new_string =
      0..(size - 1)
      |> Enum.map(&Map.get_lazy(replacements, &1, fn -> elem(string, &1) end))
      |> List.to_tuple
    tie_knots(
      lengths,
      new_string,
      rem(cursor + length + skip, size),
      skip + 1,
      size
    )
  end
  defp tie_knots([ ], string, cursor, skip, _size), do: {string, cursor, skip}
end

defmodule DiskDefragmentation do
  def run([key]) do
    solve(key, &count_used/1)
  end
  def run(["-r", path]) do
    solve(path, &count_regions/1)
  end
  def run(_args) do
    IO.puts "USAGE:  elixir #{Path.basename(__ENV__.file)} " <>
            "[-r] INPUT_FILE_PATH"
  end

  defp solve(key, counter) do
    0..127
    |> Enum.map(fn row -> build_squares(key, row) end)
    |> counter.()
    |> IO.inspect
  end

  defp build_squares(key, row) do
    "#{key}-#{row}"
    |> KnotHash.hash
    |> String.graphemes
    |> Enum.chunk_every(2)
    |> Enum.map(fn [l, r] -> String.to_integer("#{l}#{r}", 16) end)
    |> Enum.map(fn n ->
      Integer.to_string(n, 2)
      |> String.pad_leading(8, "0")
    end)
    |> Enum.join("")
  end

  defp count_used(rows) do
    Enum.reduce(rows, 0, fn row, used ->
      row
      |> String.graphemes
      |> Enum.count(fn square -> square == "1" end)
      |> Kernel.+(used)
    end)
  end

  defp count_regions(rows) do
    rows
    |> build_coordinates()
    |> find_regions()
    |> length()
  end

  defp build_coordinates(rows) do
    rows
    |> Enum.with_index
    |> Enum.reduce(Map.new, fn {row, y}, coordinates ->
      row
      |> String.graphemes
      |> Enum.with_index
      |> Enum.reduce(coordinates, fn {square, x}, row_coordinates ->
        if square == "1" do
          Map.put(row_coordinates, {x, y}, square)
        else
          row_coordinates
        end
      end)
      |> Map.merge(coordinates)
    end)
  end

  defp find_regions(coordinates, regions \\ [ ]) do
    case Enum.find(coordinates, fn {_xy, square} -> square == "1" end) do
      {xy, _square} ->
        region = find_region(coordinates, [xy], MapSet.new([xy]))
        coordinates
        |> clear_region(region)
        |> find_regions([region | regions])
      nil ->
        regions
    end
  end

  defp find_region(coordinates, [{x, y} | expansions], region) do
    new_expansions =
      [           { 0,  1},
        {-1,  0},           { 1,  0},
                  { 0, -1} ]
      |> Enum.map(fn {x_offset, y_offset} -> {x + x_offset, y + y_offset} end)
      |> Enum.filter(fn xy -> Map.get(coordinates, xy) == "1" end)
      |> MapSet.new
      |> MapSet.difference(region)
    find_region(
      coordinates,
      expansions ++ MapSet.to_list(new_expansions),
      MapSet.union(region, new_expansions)
    )
  end
  defp find_region(_coordinates, [ ], region), do: MapSet.to_list(region)

  defp clear_region(coordinates, region), do: Map.drop(coordinates, region)
end

System.argv
|> DiskDefragmentation.run
