defmodule PacketScanner do
  def run([path]) do
    solve(path, &calculate_severity/1)
  end
  def run(["-d", path]) do
    solve(path, &calculate_delay/1)
  end
  def run(_args) do
    IO.puts "USAGE:  elixir #{Path.basename(__ENV__.file)} " <>
            "[-d] INPUT_FILE_PATH"
  end

  defp solve(path, analyze) do
    path
    |> File.stream!
    |> parse_firewall()
    |> analyze.()
    |> IO.puts
  end

  defp parse_firewall(lines) do
    Enum.reduce(lines, Map.new, fn line, firewall ->
      layer =
        Regex.named_captures(~r{\A(?<depth>\d+):\s+(?<range>\d+)}, line)
        |> Map.update!("depth", &String.to_integer/1)
        |> Map.update!("range", &String.to_integer/1)
      Map.put(
        firewall,
        Map.fetch!(layer, "depth"),
        Map.fetch!(layer, "range")
      )
    end)
  end

  defp calculate_severity(firewall) do
    Enum.reduce(firewall, 0, fn {picosecond, range}, severity ->
      severity +
        if caught?(picosecond, range) do
          picosecond * range
        else
          0
        end
    end)
  end

  defp caught?(picosecond, range) do
    rem(picosecond, (range - 1) * 2) == 0
  end

  defp calculate_delay(firewall) do
    sorted_firewall =
      firewall
      |> Enum.sort_by(fn {_depth, range} -> range end)
    0
    |> Stream.iterate(&(&1 + 1))
    |> Enum.find(fn delay ->
      Enum.any?(sorted_firewall, fn {picosecond, range} ->
        caught?(picosecond + delay, range)
      end)
      |> Kernel.not
    end)
  end
end

System.argv
|> PacketScanner.run
