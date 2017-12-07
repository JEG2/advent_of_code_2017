defmodule RecursiveCircus do
  def run([path]) do
    solve(path, &find_bottom/1)
  end
  def run(["-b", path]) do
    solve(path, &find_balance/1)
  end
  def run(_args) do
    IO.puts "USAGE:  elixir #{Path.basename(__ENV__.file)} " <>
            "[-b] INPUT_FILE_PATH"
  end

  defp solve(path, finder) do
    path
    |> File.stream!
    |> Enum.reduce(Map.new, fn line, by_name ->
      %{"name" => name, "weight" => weight, "supported" => supported} =
        Regex.named_captures(
          ~r{
            \A (?<name>\w+)
            \s+ \((?<weight>\d+)\)
            ( \s+ -> \s+ (?<supported>\w[\w,\s]+\w) )?
          }x,
          line
        )
      Map.put(
        by_name,
        name,
        {String.to_integer(weight), String.split(supported, ", ", trim: true)}
      )
    end)
    |> finder.()
    |> IO.inspect
  end

  defp find_bottom(programs) do
    {full_list, one_short} =
      Enum.reduce(
        programs,
        {MapSet.new, MapSet.new},
        fn {name, {_weight, supported}}, {all, non_bottom} ->
          {
            MapSet.put(all, name),
            MapSet.union(non_bottom, MapSet.new(supported))
          }
        end
      )
    [bottom] =
      full_list
      |> MapSet.difference(one_short)
      |> MapSet.to_list
    bottom
  end

  defp find_balance(programs) do
    programs
    |> find_bottom
    |> find_imbalance(programs)
  end

  defp find_imbalance(bottom, programs) do
    weights = calculate_weights(programs)
    find_imbalance_root(bottom, programs, weights)
    |> balance(programs, weights)
  end

  defp calculate_weights(programs) do
    programs
    |> Stream.cycle
    |> Enum.reduce_while(Map.new, fn {name, {weight, supported}}, weights ->
      if map_size(programs) == map_size(weights) do
        {:halt, weights}
      else
        needs_weight = not Map.has_key?(weights, name)
        can_weigh = Enum.all?(supported, fn sub_tower ->
          Map.has_key?(weights, sub_tower)
        end)
        if needs_weight and can_weigh do
          {
            :cont,
            Map.put(
              weights,
              name,
              weight + (
                supported
                |> Enum.map(fn sub_tower ->
                  Map.fetch!(weights, sub_tower)
                end)
                |> Enum.sum
              )
            )
          }
        else
          {:cont, weights}
        end
      end
    end)
  end

  defp find_imbalance_root(bottom, programs, weights) do
    supported_weights =
      programs
      |> Map.fetch!(bottom)
      |> elem(1)
      |> Enum.map(fn name -> {name, Map.fetch!(weights, name)} end)
    unique_weights =
      supported_weights
      |> Enum.map(fn {_name, weight} -> weight end)
      |> Enum.uniq
      |> length()
    if unique_weights == 1 do
      Enum.find(programs, fn {_name, {_weight, supported}} ->
        bottom in supported
      end)
      |> elem(1)
      |> elem(1)
    else
      supported_weights
      |> Enum.group_by(fn {_name, weight} -> weight end)
      |> Enum.find(fn {weight, [{_name, weight}]} -> true; _pair -> false end)
      |> elem(1)
      |> hd()
      |> elem(0)
      |> find_imbalance_root(programs, weights)
    end
  end

  def balance(disc, programs, weights) do
    {[{imbalanced_weight, [imbalanced_name]}], [{target_weight, _names}]} =
      disc
      |> Enum.map(fn name -> {name, Map.fetch!(weights, name)} end)
      |> Enum.group_by(
        fn {_name, weight} -> weight end,
        fn {name, _weight} -> name end
      )
      |> Enum.split_with(fn {_weight, [_name]} -> true; _pair -> false end)
    {current_weight, _supported} = Map.fetch!(programs, imbalanced_name)
    current_weight + target_weight - imbalanced_weight
  end
end

System.argv
|> RecursiveCircus.run
