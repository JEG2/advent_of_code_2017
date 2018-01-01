defmodule ElectromagneticMoat do
  def run([path]) do
    solve(path, &score_only/1)
  end
  def run(["-l", path]) do
    solve(path, &length_and_score/1)
  end
  def run(_args) do
    IO.puts "USAGE:  elixir #{Path.basename(__ENV__.file)} " <>
            "[-l] INPUT_FILE_PATH"
  end

  defp solve(path, evaluator) do
    path
    |> parse_components
    |> build_bridges(0, [ ], evaluator)
    |> elem(0)
    |> IO.puts
  end

  defp parse_components(path) do
    path
    |> File.stream!
    |> Enum.map(fn component ->
      component
      |> String.trim
      |> String.split("/")
      |> Enum.map(&String.to_integer/1)
      |> List.to_tuple
    end)
  end

  defp build_bridges(components, port, bridge, evaluator) do
    case Enum.filter(components, fn {l, r} -> l == port or r == port end) do
      [ ] ->
        {score(bridge), bridge}
      choices ->
        choices
        |> Enum.map(fn choice ->
          build_bridges(
            List.delete(components, choice),
            elem(choice, (if elem(choice, 0) == port, do: 1, else: 0)),
            [choice | bridge],
            evaluator
          )
        end)
        |> evaluator.()
    end
  end

  defp score(bridge) do
    Enum.reduce(bridge, 0, fn {l, r}, sum -> sum + l + r end)
  end

  defp score_only(bridges) do
    Enum.max_by(bridges, fn {score, _bridge} -> score end)
  end

  defp length_and_score(bridges) do
    by_length =
      Enum.group_by(bridges, fn {_score, bridge} -> length(bridge) end)
    longest =
      by_length
      |> Map.keys
      |> Enum.max
    by_length
    |> Map.fetch!(longest)
    |> score_only
  end
end

System.argv
|> ElectromagneticMoat.run
