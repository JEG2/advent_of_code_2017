defmodule DigitalPlumber do
  def run([path]) do
    solve(path, &count_reachable/1)
  end
  def run(["-c", path]) do
    solve(path, &count_groups/1)
  end
  def run(_args) do
    IO.puts "USAGE:  elixir #{Path.basename(__ENV__.file)} " <>
            "[-c] INPUT_FILE_PATH"
  end

  defp solve(path, counter) do
    path
    |> File.stream!
    |> build_graph()
    |> counter.()
    |> IO.puts
  end

  defp build_graph(input) do
    Enum.reduce(input, :digraph.new, fn line, graph ->
      connections =
        Regex.named_captures(
          ~r{\A(?<program>\d+)\s<->\s(?<pipes>\d(?:[\d,\s]*\d)?)},
          line
        )
        |> Map.update!("program", &String.to_integer/1)
        |> Map.update!("pipes", fn raw ->
          raw |> String.split(", ") |> Enum.map(&String.to_integer/1)
        end)
      :digraph.add_vertex(graph, connections["program"])
      connections
      |> Map.fetch!("pipes")
      |> Enum.each(fn pipe ->
        :digraph.add_vertex(graph, pipe)
        :digraph.add_edge(graph, connections["program"], pipe)
      end)
      graph
    end)
  end

  defp count_reachable(graph, program \\ 0) do
    [program]
    |> :digraph_utils.reachable(graph)
    |> length()
  end

  def count_groups(graph) do
    graph
    |> :digraph_utils.components
    |> length()
  end
end

System.argv
|> DigitalPlumber.run
