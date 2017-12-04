defmodule HighEntropyPassphrases do
  def run([path]) do
    solve(path, &identity/1)
  end
  def run(["-a", path]) do
    solve(path, &anagram/1)
  end
  def run(_args) do
    IO.puts "USAGE:  elixir #{Path.basename(__ENV__.file)} " <>
            "[-a] INPUT_FILE_PATH"
  end

  defp solve(path, signature) do
    path
    |> File.stream!
    |> Stream.map(&String.trim/1)
    |> Stream.map(fn passphrase -> String.split(passphrase, " ") end)
    |> count_valid_passphrases(signature)
    |> IO.puts
  end

  defp count_valid_passphrases(passphrases, signature) do
    Enum.reduce(passphrases, 0, fn passphrase, sum ->
      sum + (if no_dupes?(passphrase, signature), do: 1, else: 0)
    end)
  end

  defp no_dupes?(words, signature) do
    words
    |> Enum.reduce_while({true, MapSet.new}, fn word, {result, dupes} ->
      sig = signature.(word)
      if MapSet.member?(dupes, sig) do
        {:halt, {false, dupes}}
      else
        {:cont, {result, MapSet.put(dupes, sig)}}
      end
    end)
    |> elem(0)
  end

  defp identity(word), do: word

  defp anagram(word), do: word |> String.split("") |> Enum.sort
end

System.argv
|> HighEntropyPassphrases.run
