defmodule Registers do
  def run([path]) do
    solve(path, &find_max_register/1)
  end
  def run(["-s", path]) do
    solve(path, &find_max_seen/1)
  end
  def run(_args) do
    IO.puts "USAGE:  elixir #{Path.basename(__ENV__.file)} " <>
            "[-s] INPUT_FILE_PATH"
  end

  defp solve(path, finder) do
    path
    |> File.stream!
    |> Stream.map(fn line ->
      Regex.named_captures(
        ~r{
          \A  (?<register>\w+)
          \s+ (?<operator>dec|inc)
          \s+ (?<amount>-?\d+)
          \s+ if
          \s+ (?<test_register>\w+)
          \s+ (?<test>==|!=|<|<=|>|>=)
          \s+ (?<test_amount>-?\d+)
        }x,
        line
      )
    end)
    |> execute()
    |> finder.()
    |> IO.puts
  end

  defp execute(instructions) do
    Enum.reduce(
      instructions,
      {Map.new, 0},
      fn instruction, {registers, max} ->
        if test_passes?(instruction, registers) do
          new_registers = change_register(instruction, registers)
          new_max = Enum.max([max, max_value(new_registers)])
          {new_registers, new_max}
        else
          {registers, max}
        end
      end
    )
  end

  defp test_passes?(
    %{"test_register" => register, "test" => test, "test_amount" => amount},
    registers
  ) do
    value = Map.get(registers, register, 0)
    n = String.to_integer(amount)
    passes?(value, test, n)
  end

  defp passes?(value, "==", n), do: value == n
  defp passes?(value, "!=", n), do: value != n
  defp passes?(value, "<",  n), do: value <  n
  defp passes?(value, "<=", n), do: value <= n
  defp passes?(value, ">",  n), do: value >  n
  defp passes?(value, ">=", n), do: value >= n

  defp change_register(
    %{"register" => register, "operator" => operator, "amount" => amount},
    registers
  ) do
    operation = to_operation(operator)
    change = String.to_integer(amount)
    Map.update(
      registers,
      register,
      operation.(0, change),
      &operation.(&1, change)
    )
  end

  defp to_operation("inc"), do: fn l, r -> l + r end
  defp to_operation("dec"), do: fn l, r -> l - r end

  defp max_value(registers), do: registers |> Map.values |> Enum.max

  defp find_max_register({registers, _max}), do: max_value(registers)

  defp find_max_seen({_registers, max}), do: max
end

System.argv
|> Registers.run
