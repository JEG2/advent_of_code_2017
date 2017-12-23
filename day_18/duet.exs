defmodule Sounds do
  def snd(value, context) do
    Map.put(context, :frequency, value)
  end

  def rcv(
    _register,
    value,
    %{frequency: frequency, instruction: instruction} = context
  ) do
    if value != 0 do
      IO.puts frequency
      %{context | instruction: -1}
    else
      %{context | instruction: instruction + 1}
    end
  end
end

defmodule Messages do
  def snd(value, %{main: main, pid: pid} = context) do
    send(main, :send)
    send(pid, value)
    Map.update!(context, :sends, &(&1 + 1))
  end

  def rcv(
    register,
    _value,
    %{
      main: main,
      sends: sends,
      instruction: instruction,
      registers: registers
    } = context
  ) do
    send(main, :recieve)
    receive do
      :exit ->
        IO.puts sends
        send(main, :ok)
        %{context | instruction: -1}
      value ->
        %{
          context |
          instruction: instruction + 1,
          registers: Map.put(registers, register, value)
        }
    end
  end
end

defmodule Duet do
  def run([path]) do
    :ok =
      path
      |> parse_program
      |> execute_program(%{instruction: 0, registers: %{ }, code: Sounds})
  end
  def run(["-m", path]) do
    :ok =
      path
      |> parse_program
      |> execute_paired_programs
  end
  def run(_args) do
    IO.puts "USAGE:  elixir #{Path.basename(__ENV__.file)} " <>
            "[-m] INPUT_FILE_PATH"
  end

  defp parse_program(path) do
    path
    |> File.stream!
    |> Stream.map(fn line -> line |> String.trim |> String.split(~r{\s+}) end)
    |> Stream.map(&parse_instruction/1)
    |> Enum.to_list
    |> List.to_tuple
  end

  defp parse_instruction(["snd", x]),    do: {:snd, parse_value(x)}
  defp parse_instruction(["set", x, y]), do: {:set, x, parse_value(y)}
  defp parse_instruction(["add", x, y]), do: {:add, x, parse_value(y)}
  defp parse_instruction(["mul", x, y]), do: {:mul, x, parse_value(y)}
  defp parse_instruction(["mod", x, y]), do: {:mod, x, parse_value(y)}
  defp parse_instruction(["rcv", x]),    do: {:rcv, parse_value(x)}
  defp parse_instruction(["jgz", x, y]),
  do: {:jgz, parse_value(x), parse_value(y)}

  defp parse_value(v) do
    if String.match?(v, ~r{\A-?\d+\z}) do
      String.to_integer(v)
    else
      v
    end
  end

  defp execute_program(program, %{instruction: instruction})
  when instruction < 0 or instruction >= tuple_size(program),
  do: :ok
  defp execute_program(program, %{instruction: instruction} = context) do
    # IO.inspect({elem(program, instruction), context})
    # Process.sleep(1_000)
    new_context = execute_instruction(elem(program, instruction), context)
    execute_program(program, new_context)
  end

  defp execute_instruction(
    {:snd, x},
    %{registers: registers, code: code} = context
  ) do
    apply(code, :snd, [value(x, registers), context])
    |> Map.update!(:instruction, &(&1 + 1))
  end
  defp execute_instruction(
    {:set, x, y},
    %{instruction: instruction, registers: registers} = context
  ) do
    new_registers = Map.put(registers, x, value(y, registers))
    %{context | instruction: instruction + 1, registers: new_registers}
  end
  defp execute_instruction(
    {:add, x, y},
    %{instruction: instruction, registers: registers} = context
  ) do
    operand = value(y, registers)
    new_registers = Map.update(registers, x, 0 + operand, &(&1 + operand))
    %{context | instruction: instruction + 1, registers: new_registers}
  end
  defp execute_instruction(
    {:mul, x, y},
    %{instruction: instruction, registers: registers} = context
  ) do
    operand = value(y, registers)
    new_registers = Map.update(registers, x, 0, &(&1 * operand))
    %{context | instruction: instruction + 1, registers: new_registers}
  end
  defp execute_instruction(
    {:mod, x, y},
    %{instruction: instruction, registers: registers} = context
  ) do
    operand = value(y, registers)
    new_registers = Map.update(registers, x, 0, &rem(&1, operand))
    %{context | instruction: instruction + 1, registers: new_registers}
  end
  defp execute_instruction(
    {:rcv, x},
    %{registers: registers, code: code} = context
  ) do
    apply(code, :rcv, [x, value(x, registers), context])
  end
  defp execute_instruction(
    {:jgz, x, y},
    %{instruction: instruction, registers: registers} = context
  ) do
    if value(x, registers) > 0 do
      %{context | instruction: instruction + value(y, registers)}
    else
      %{context | instruction: instruction + 1}
    end
  end

  defp value(x, registers) when is_binary(x), do: Map.get(registers, x, 0)
  defp value(x, _registers) when is_integer(x), do: x

  defp execute_paired_programs(program) do
    zero = spawn(fn -> execute_paired_program(program, 0) end)
    one = spawn(fn -> execute_paired_program(program, 1) end)
    send(zero, {:pids, self(), one})
    send(one, {:pids, self(), zero})
    detect_deadlock(0, one)
  end

  defp execute_paired_program(program, program_id) do
    receive do
      {:pids, main, pid} ->
        :ok =
          execute_program(
            program,
            %{
              instruction: 0,
              registers: %{"p" => program_id},
              program_id: program_id,
              main: main,
              pid: pid,
              sends: 0,
              code: Messages
            }
          )
    end
  end

  defp detect_deadlock(-2, one) do
    send(one, :exit)
    receive do
      :ok -> :ok
    end
  end
  defp detect_deadlock(sends, one) do
    receive do
      :send -> detect_deadlock(sends + 1, one)
      :recieve -> detect_deadlock(sends - 1, one)
    end
  end
end

System.argv
|> Duet.run
