defmodule KnotHash do
  use Bitwise, skip_operators: false

  def run([ ]) do
    IO.puts "USAGE:  elixir #{Path.basename(__ENV__.file)} " <>
            "[-s SIZE | -f] INPUT_FILE_PATH"
  end
  def run(args) do
    {size, lengths, full_hash_mode} = parse_args(args)
    if full_hash_mode do
      solve(lengths, size, &full_hash/5)
    else
      solve(lengths, size, &one_pass_hash/5)
    end
  end

  defp solve(lengths, size, hash_builder) do
    string =
      0
      |> Stream.iterate(&(&1 + 1))
      |> Enum.take(size)
      |> List.to_tuple
    lengths
    |> hash_builder.(string, 0, 0, size)
    |> IO.puts
  end

  defp parse_args(args) do
    {parsed, [path]} =
      OptionParser.parse!(
        args,
        switches: [size: :integer, full: :boolean],
        aliases: [s: :size, f: :full]
      )
    {
      Keyword.get(parsed, :size, 256),
      path |> File.read! |> String.trim,
      Keyword.get(parsed, :full, false)
    }
  end

  defp one_pass_hash(lengths, string, cursor, skip, size) do
    lengths
    |> String.split(",")
    |> Enum.map(&String.to_integer/1)
    |> tie_knots(string, cursor, skip, size)
    |> elem(0)
    |> check
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

  defp check(string), do: elem(string, 0) * elem(string, 1)

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
end

System.argv
|> KnotHash.run
