defmodule TuringMachine do
  defstruct current_state: nil,
            steps: nil,
            states: Map.new,
            tape_ones: MapSet.new,
            cursor: 0

  defmodule Instruction do
    defstruct ~w[write move next_state]a

    def execute(
      %TuringMachine.Instruction{ } = instruction,
      %TuringMachine{ } = turing_machine
    ) do
      turing_machine
      |> write(instruction.write)
      |> move(instruction.move)
      |> transition(instruction.next_state)
      |> step
    end

    defp write(%TuringMachine{ } = turing_machine, 0) do
      %TuringMachine{
        turing_machine |
        tape_ones:
          MapSet.delete(turing_machine.tape_ones, turing_machine.cursor)
      }
    end
    defp write(%TuringMachine{ } = turing_machine, 1) do
      %TuringMachine{
        turing_machine |
        tape_ones: MapSet.put(turing_machine.tape_ones, turing_machine.cursor)
      }
    end

    defp move(%TuringMachine{ } = turing_machine, offset) do
      %TuringMachine{turing_machine | cursor: turing_machine.cursor + offset}
    end

    defp transition(%TuringMachine{ } = turing_machine, next_state) do
      %TuringMachine{turing_machine | current_state: next_state}
    end

    defp step(%TuringMachine{ } = turing_machine) do
      %TuringMachine{turing_machine | steps: turing_machine.steps - 1}
    end
  end

  def current_instruction(%TuringMachine{ } = turing_machine) do
    turing_machine.states
    |> Map.fetch!(turing_machine.current_state)
    |> Map.fetch!(current_value(turing_machine))
  end

  defp current_value(%TuringMachine{ } = turing_machine) do
    if MapSet.member?(turing_machine.tape_ones, turing_machine.cursor) do
      1
    else
      0
    end
  end
end

defmodule TheHaltingProblem do
  def run([path]) do
    path
    |> parse_blueprints
    |> execute_instructions
    |> count_ones
    |> IO.puts
  end
  def run(_args) do
    IO.puts "USAGE:  elixir #{Path.basename(__ENV__.file)} " <>
            "[-l] INPUT_FILE_PATH"
  end

  defp parse_blueprints(path) do
    File.open!(path, ~w[binary read]a, &parse_turing_machine/1)
  end

  defp parse_turing_machine(input) do
    current_state = parse_current_state(input)
    steps = parse_steps(input)
    states = parse_states(input)
    %TuringMachine{current_state: current_state, steps: steps, states: states}
  end

  defp parse_current_state(input) do
    parse_line(input, ~r{\ABegin in state (?<current_state>\w+)})
  end

  defp parse_steps(input) do
    parse_line(input, ~r{\APerform a diagnostic checksum after (?<steps>\d+)})
    |> String.to_integer
  end

  defp parse_states(input, states \\ Map.new) do
    parse_line(input, ~r{\AIn state (?<state_name>\w+)}, fn _e -> nil end)
    |> case do
         nil ->
           states
         state_name ->
           zero = parse_current_value(input, 0)
           one = parse_current_value(input, 1)
           parse_states(
             input,
             Map.put(states, state_name, %{0 => zero, 1 => one})
           )
       end
  end

  defp parse_current_value(input, value) do
    ^value =
      parse_line(input, ~r{\AIf the current value is (?<value>\d+)})
      |> String.to_integer
    write = parse_write(input)
    move = parse_move(input)
    next_state = parse_next_state(input)
    %TuringMachine.Instruction{
      write: write,
      move: move,
      next_state: next_state
    }
  end

  defp parse_write(input) do
    parse_line(input, ~r{\A- Write the value (?<write>\d+)})
    |> String.to_integer
  end

  defp parse_move(input) do
    parse_line(input, ~r{\A- Move one slot to the (?<direction>left|right)})
    |> case do
         "left" -> -1
         "right" -> 1
         error -> raise "Unexpected direction:  #{inspect(error)}"
       end
  end

  defp parse_next_state(input) do
    parse_line(input, ~r{\A- Continue with state (?<next_state>\w+)})
  end

  defp parse_line(
    input,
    regex,
    error_handler \\ fn e -> raise "Unexpected input:  #{inspect(e)}" end
  ) do
    case IO.read(input, :line) do
      "\n" ->
        parse_line(input, regex)
      line when is_binary(line) ->
        [name] = Regex.names(regex)
        Regex.named_captures(regex, String.trim(line))
        |> Map.fetch!(name)
      error ->
        error_handler.(error)
    end
  end

  defp execute_instructions(%TuringMachine{steps: 0} = turing_machine) do
    turing_machine
  end
  defp execute_instructions(%TuringMachine{ } = turing_machine) do
    turing_machine
    |> TuringMachine.current_instruction
    |> TuringMachine.Instruction.execute(turing_machine)
    |> execute_instructions
  end

  defp count_ones(%TuringMachine{ } = turing_machine) do
    MapSet.size(turing_machine.tape_ones)
  end
end

System.argv
|> TheHaltingProblem.run
