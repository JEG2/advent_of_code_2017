defmodule StreamProcessing do
  @garbage_re ~r{<(?:!.|[^>])*>}

  def run([path]) do
    solve(path, &score_groups_without_garbage/1)
  end
  def run(["-g", path]) do
    solve(path, &score_all_garbage/1)
  end
  def run(_args) do
    IO.puts "USAGE:  elixir #{Path.basename(__ENV__.file)} " <>
            "[-g] INPUT_FILE_PATH"
  end

  defp solve(path, counter) do
    path
    |> File.read!
    |> counter.()
    |> IO.puts
  end

  defp score_groups_without_garbage(input) do
    input
    |> String.replace(~r{<(?:!.|[^>])*>}, "", global: true)
    |> score_groups
  end

  defp score_groups(groups, score \\ 0, total \\ 0)
  defp score_groups("", _score, total), do: total
  defp score_groups("{" <> rest, score, total) do
    score_groups(rest, score + 1, total + (score + 1))
  end
  defp score_groups("}" <> rest, score, total) do
    score_groups(rest, score - 1, total)
  end
  defp score_groups(groups, score, total) do
    score_groups(groups |> String.next_grapheme |> elem(1), score, total)
  end

  defp score_all_garbage(input) do
    Regex.scan(@garbage_re, input)
    |> Enum.map(fn [garbage] -> score_garbage(garbage) end)
    |> Enum.sum
  end

  defp score_garbage(garbage) do
    garbage
    |> String.slice(1..-2)
    |> String.replace(~r{!.}, "", global: true)
    |> String.length
  end
end

System.argv
|> StreamProcessing.run
