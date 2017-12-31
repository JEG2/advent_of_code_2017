defmodule CoprocessorConflagration do
  def run([path]) do
    solve(path, %{ }, &Map.fetch!(&1, :muls))
  end
  def run(["-d", _path]) do
    0..1000
    |> Stream.map(&(107_900 + &1 * 17))
    |> Stream.reject(&prime?/1)
    |> Enum.count
    |> IO.puts
  end
  def run(_args) do
    IO.puts "USAGE:  elixir #{Path.basename(__ENV__.file)} " <>
            "[-d] INPUT_FILE_PATH"
  end

  defp solve(path, registers, result) do
    path
    |> parse_program
    |> execute_program(%{instruction: 0, registers: registers, muls: 0})
    |> result.()
    |> IO.puts
  end

  defp parse_program(path) do
    path
    |> File.stream!
    |> Stream.map(fn line -> line |> String.trim |> String.split(~r{\s+}) end)
    |> Stream.map(&parse_instruction/1)
    |> Enum.to_list
    |> List.to_tuple
  end

  defp parse_instruction(["set", x, y]), do: {:set, x, parse_value(y)}
  defp parse_instruction(["sub", x, y]), do: {:sub, x, parse_value(y)}
  defp parse_instruction(["mul", x, y]), do: {:mul, x, parse_value(y)}
  defp parse_instruction(["jnz", x, y]),
  do: {:jnz, parse_value(x), parse_value(y)}

  defp parse_value(v) do
    if String.match?(v, ~r{\A-?\d+\z}) do
      String.to_integer(v)
    else
      v
    end
  end

  defp execute_program(program, %{instruction: instruction} = context)
  when instruction < 0 or instruction >= tuple_size(program),
  do: context
  defp execute_program(program, %{instruction: instruction} = context) do
    new_context = execute_instruction(elem(program, instruction), context)
    execute_program(program, new_context)
  end

  defp execute_instruction(
    {:set, x, y},
    %{instruction: instruction, registers: registers} = context
  ) do
    new_registers = Map.put(registers, x, value(y, registers))
    %{context | instruction: instruction + 1, registers: new_registers}
  end
  defp execute_instruction(
    {:sub, x, y},
    %{instruction: instruction, registers: registers} = context
  ) do
    operand = value(y, registers)
    new_registers = Map.update(registers, x, 0 - operand, &(&1 - operand))
    %{context | instruction: instruction + 1, registers: new_registers}
  end
  defp execute_instruction(
    {:mul, x, y},
    %{instruction: instruction, registers: registers, muls: muls} = context
  ) do
    operand = value(y, registers)
    new_registers = Map.update(registers, x, 0, &(&1 * operand))
    %{
      context |
      instruction: instruction + 1,
      registers: new_registers,
      muls: muls + 1
    }
  end
  defp execute_instruction(
    {:jnz, x, y},
    %{instruction: instruction, registers: registers} = context
  ) do
    if value(x, registers) != 0 do
      %{context | instruction: instruction + value(y, registers)}
    else
      %{context | instruction: instruction + 1}
    end
  end

  defp value(x, registers) when is_binary(x), do: Map.get(registers, x, 0)
  defp value(x, _registers) when is_integer(x), do: x

  defp prime?(2), do: true
  defp prime?(n) do
    not Enum.any?(2..trunc(Float.ceil(:math.sqrt(n))), &rem(n, &1) == 0)
  end
end

System.argv
|> CoprocessorConflagration.run
