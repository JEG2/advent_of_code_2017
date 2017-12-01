defmodule InverseCaptcha do
  def run(args) do
    with {:ok, mode, path} <- parse_args(args),
         {:ok, digits}     <- to_digits(path),
         offset            <- to_offset(mode, digits) do
      sum_duplicates(digits, offset)
      |> IO.puts
    else
      _error ->
        IO.puts "USAGE:  elixir #{Path.basename(__ENV__.file)} " <>
                "[-h] INPUT_FILE_PATH"
    end
  end

  defp parse_args(args) do
    OptionParser.parse(
      args,
      strict:  [half_mode: :boolean],
      aliases: [h:         :half_mode]
    )
    |> case do
      {parsed, [path], [ ]} -> {:ok, Keyword.get(parsed, :half_mode), path}
      _result               -> :error
    end
  end

  defp to_digits(path) do
    with {:ok, input} <- File.read(path) do
      {
        :ok,
        input |> String.replace(~r{\D}, "") |> String.graphemes
      }
    end
  end

  defp to_offset(true, digits),  do: div(length(digits), 2) - 1
  defp to_offset(nil,  _digits), do: 0

  defp sum_duplicates(digits, offset, i \\ 0, sum \\ 0)
  defp sum_duplicates(digits, offset, i, sum) when i < length(digits) do
    first    = Enum.at(digits, i)
    other    =
      digits
      |> Enum.drop(i + 1)
      |> Kernel.++(digits)
      |> Enum.at(offset)
    addition =
      if first == other do
        String.to_integer(first)
      else
        0
      end
    sum_duplicates(digits, offset, i + 1, sum + addition)
  end
  defp sum_duplicates(_digits, _offset, _i, sum), do: sum
end

System.argv
|> InverseCaptcha.run
