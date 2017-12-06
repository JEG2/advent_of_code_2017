defmodule MemoryReallocation do
  def run([path]) do
    solve(path, &count_reallocations/2)
  end
  def run(["-l", path]) do
    solve(path, &count_loop/2)
  end
  def run(_args) do
    IO.puts "USAGE:  elixir #{Path.basename(__ENV__.file)} " <>
            "[-l] INPUT_FILE_PATH"
  end

  defp solve(path, counter) do
    banks = parse(path)
    banks
    |> reallocate(counter, MapSet.new([banks]))
    |> IO.puts
  end

  defp parse(path) do
    raw = File.read!(path)
    Regex.scan(~r{\d+}, raw, capture: :first)
    |> Enum.map(fn [blocks] -> String.to_integer(blocks) end)
  end

  defp reallocate(banks, counter, seen) do
    {distribution, replacement} =
      banks
      |> Enum.with_index
      |> Enum.sort(fn {blocks_a, i_a}, {blocks_b, i_b} ->
        if blocks_a == blocks_b, do: i_a <= i_b, else: blocks_a >= blocks_b
      end)
      |> hd()
    divisions = length(banks)
    split = div(distribution, divisions)
    extra = rem(distribution, divisions)
    reallocation =
      banks
      |> Enum.with_index
      |> Enum.map(fn
        {_blocks, i} when i == replacement ->
          split + extra_portion(replacement, divisions, extra, i)
        {blocks, i} ->
          blocks + split + extra_portion(replacement, divisions, extra, i)
      end)
    if MapSet.member?(seen, reallocation) do
      counter.(seen, reallocation)
    else
      reallocate(reallocation, counter, MapSet.put(seen, reallocation))
    end
  end

  defp extra_portion(replacement, divisions, extra, i)
  when (i > replacement and i <= replacement + extra)
  or   i < extra - (divisions - (replacement + 1)) do
    1
  end
  defp extra_portion(_replacement, _divisions, _extra, _i), do: 0

  defp count_reallocations(seen, _reallocation), do: MapSet.size(seen)

  defp count_loop(_seen, reallocation) do
    reallocate(
      reallocation,
      &count_reallocations/2,
      MapSet.new([reallocation])
    )
  end
end

System.argv
|> MemoryReallocation.run
