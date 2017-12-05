defmodule TwistyTrampolines do
  def run([path]) do
    solve(path, &increment/1)
  end
  def run(["-s", path]) do
    solve(path, &strange/1)
  end
  def run(_args) do
    IO.puts "USAGE:  elixir #{Path.basename(__ENV__.file)} " <>
            "[-s] INPUT_FILE_PATH"
  end

  defp solve(path, next_jump) do
    path
    |> File.stream!
    |> Stream.map(&String.trim/1)
    |> Stream.map(&String.to_integer/1)
    |> Stream.with_index
    |> Enum.into(Map.new, fn {jump, i} -> {i, jump} end)
    |> count_jumps(next_jump)
    |> IO.puts
  end

  defp count_jumps(instructions, next_jump, i \\ 0, count \\ 0) do
    if Map.has_key?(instructions, i) do
      {offset, new_instructions} =
        Map.get_and_update!(
          instructions,
          i,
          fn jump -> {jump, next_jump.(jump)} end
        )
      count_jumps(new_instructions, next_jump, i + offset, count + 1)
    else
      count
    end
  end

  defp increment(n), do: n + 1

  defp strange(n) when n >= 3, do: n - 1
  defp strange(n),             do: n + 1
end

System.argv
|> TwistyTrampolines.run
