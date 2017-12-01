defmodule InverseCaptcha do
  def run(args) do
    with {:ok, mode, path} <- parse_args(args),
         {:ok, digits}     <- to_digits(path),
         offset            <- to_offset(mode, digits) do
      comparisons =
        digits
        |> Enum.drop(offset)
        |> Kernel.++(digits)
      sum_duplicates(digits, comparisons)
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

  defp to_offset(true, digits),  do: div(length(digits), 2)
  defp to_offset(nil,  _digits), do: 1

  defp sum_duplicates(digits, comparisons, sum \\ 0)
  defp sum_duplicates([match | digits], [match | comparisons], sum) do
    sum_duplicates(digits, comparisons, sum + String.to_integer(match))
  end
  defp sum_duplicates([_digit | digits], [_comparison | comparisons], sum) do
    sum_duplicates(digits, comparisons, sum)
  end
  defp sum_duplicates([ ], _comparison, sum), do: sum
end

System.argv
|> InverseCaptcha.run
