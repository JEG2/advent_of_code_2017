defmodule ParticalSwarm do
  def run([path]) do
    solve(path, &closest_to_origin/1)
  end
  def run(["-c", path]) do
    solve(path, &collisions/1)
  end
  def run(_args) do
    IO.puts "USAGE:  elixir #{Path.basename(__ENV__.file)} " <>
            "[-c] INPUT_FILE_PATH"
  end

  defp solve(path, simulator) do
    path
    |> File.stream!
    |> Enum.map(&parse_particle/1)
    |> simulator.()
    |> IO.puts
  end

  defp parse_particle(line) do
    Regex.scan(~r{<[^>]+>}, line)
    |> Enum.map(fn [xyz] ->
      xyz
      |> String.slice(1..-2)
      |> String.split(",")
      |> Enum.map(&String.trim/1)
      |> Enum.map(&String.to_integer/1)
    end)
  end

  defp tick(particles) do
    Enum.map(particles, &update_particle/1)
  end

  defp update_particle([p, v, a]) do
    new_v = v |> Enum.zip(a) |> Enum.map(fn {vxyz, axyz} -> vxyz + axyz end)
    new_p =
      p |> Enum.zip(new_v) |> Enum.map(fn {pxyz, vxyz} -> pxyz + vxyz end)
    [new_p, new_v, a]
  end

  defp find_closest_to_origin(particles) do
    particles
    |> Enum.with_index
    |> Enum.min_by(fn {[p, _v, _a], _i} ->
      p |> Enum.map(&abs/1) |> Enum.sum
    end)
    |> elem(1)
  end

  defp closest_to_origin(particles) do
    particles
    |> Stream.iterate(&tick/1)
    |> Stream.drop(1_000)
    |> Enum.take(1)
    |> hd
    |> find_closest_to_origin
  end

  defp collisions(particles) do
    particles
    |> Stream.iterate(&tick_with_collisions/1)
    |> Stream.drop(1_000)
    |> Enum.take(1)
    |> hd
    |> length
  end

  defp tick_with_collisions(particles) do
    updated_particles = tick(particles)
    collisions =
      updated_particles
      |> Enum.group_by(fn [p, _v, _a] -> p end)
      |> Enum.filter(fn {_p, collision} -> length(collision) >= 2 end)
      |> Enum.map(&elem(&1, 0))
    Enum.reject(updated_particles, fn [p, _v, _a] -> p in collisions end)
  end
end

System.argv
|> ParticalSwarm.run
