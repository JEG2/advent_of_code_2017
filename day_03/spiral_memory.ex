defmodule SpiralMemory do
  def run([location]) do
    solve(location, &find_by_counting/1)
  end
  def run(["-s", location]) do
    solve(location, &find_by_squares/1)
  end
  def run(_args) do
    IO.puts "USAGE:  elixir #{Path.basename(__ENV__.file)} " <>
            "[-s] LOCATION_NUMBER"
  end

  defp solve(location, finder) do
    location
    |> String.to_integer
    |> finder.()
    |> IO.puts
  end

  defp find_by_counting(location) do
    location
    |> find_ring()
    |> find_in_ring()
    |> to_distance()
  end

  defp find_ring(location) do
    {{0, 0}, 3, 1, location}
    |> Stream.iterate(fn {{x, y}, size, total, l} ->
      {{x + 1, y - 1}, size + 2, total + (size * 4 - 4), l}
    end)
    |> Enum.find(fn {_xy, _size, total, l} -> total >= l end)
  end

  defp find_in_ring({{x, y}, size, total, location})
  when total - (size - 3) <= location do
    {x - (total - location), y}
  end
  defp find_in_ring({{x, y}, size, total, location})
  when total - (size - 3) * 2 <= location do
    {x - (size - 3), y + (total - (size - 3) - location)}
  end
  defp find_in_ring({{x, y}, size, total, location})
  when total - (size - 3) * 3 <= location do
    {x - (size - 3) + (total - (size - 3) * 2 - location), y + (size - 3)}
  end
  defp find_in_ring({{x, y}, size, total, location}) do
    {x, y + (size - 3) - (total - (size - 3) * 3 - location)}
  end

  defp to_distance({x, y}), do: abs(x) + abs(y)

  defp find_by_squares(location) do
    {{0, 0}, 1, 0, 0, 1, %{{0, 0} => 1}}
    |> Stream.iterate(fn
      {{x, y}, size, 0, 0, _value, squares} ->
        new_xy = {x + 1, y}
        new_size = size + 2
        {new_value, new_squares} = sum_squares(new_xy, squares)
        {new_xy, new_size, new_size - 2, 3, new_value, new_squares}
      {{x, y}, size, count, 0, _value, squares} ->
        new_xy = {x + 1, y}
        {new_value, new_squares} = sum_squares(new_xy, squares)
        {new_xy, size, count - 1, 0, new_value, new_squares}
      {{x, y}, size, 0, 3, _value, squares} ->
        new_xy = {x - 1, y}
        {new_value, new_squares} = sum_squares(new_xy, squares)
        {new_xy, size, size - 2, 2, new_value, new_squares}
      {{x, y}, size, count, 3, _value, squares} ->
        new_xy = {x, y + 1}
        {new_value, new_squares} = sum_squares(new_xy, squares)
        {new_xy, size, count - 1, 3, new_value, new_squares}
      {{x, y}, size, 0, 2, _value, squares} ->
        new_xy = {x, y - 1}
        {new_value, new_squares} = sum_squares(new_xy, squares)
        {new_xy, size, size - 2, 1, new_value, new_squares}
      {{x, y}, size, count, 2, _value, squares} ->
        new_xy = {x - 1, y}
        {new_value, new_squares} = sum_squares(new_xy, squares)
        {new_xy, size, count - 1, 2, new_value, new_squares}
      {{x, y}, size, 0, 1, _value, squares} ->
        new_xy = {x + 1, y}
        {new_value, new_squares} = sum_squares(new_xy, squares)
        {new_xy, size, size - 2, 0, new_value, new_squares}
      {{x, y}, size, count, 1, _value, squares} ->
        new_xy = {x, y - 1}
        {new_value, new_squares} = sum_squares(new_xy, squares)
        {new_xy, size, count - 1, 1, new_value, new_squares}
    end)
    |> Enum.find(fn {_xy, _size, _count, _turns, value, _squares} ->
      value >= location
    end)
    |> elem(4)
  end

  defp sum_squares({x, y}, squares) do
    value =
      [ {-1,  1}, {0,  1}, {1,  1},
        {-1,  0},          {1,  0},
        {-1, -1}, {0, -1}, {1, -1} ]
      |> Enum.map(fn {x_offset, y_offset} ->
        squares[{x + x_offset, y + y_offset}] || 0
      end)
      |> Enum.sum
    {value, Map.put(squares, {x, y}, value)}
  end
end

System.argv
|> SpiralMemory.run
