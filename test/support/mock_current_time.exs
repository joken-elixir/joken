defmodule Joken.CurrentTime.Mock do
  use Agent

  def start_link do
    Agent.start_link(
      fn ->
        %{is_frozen: false, frozen_value: nil}
      end,
      name: unique_name_per_process()
    )
  end

  def current_time do
    state = Agent.get(unique_name_per_process(), fn state -> state end)

    if state[:is_frozen] do
      state[:frozen_value]
    else
      :os.system_time(:second)
    end
  end

  def freeze do
    freeze(:os.system_time(:second))
  end

  def freeze(timestamp) do
    Agent.update(unique_name_per_process(), fn _state ->
      %{is_frozen: true, frozen_value: timestamp}
    end)
  end

  def unfreeze do
    if Process.whereis(unique_name_per_process()) do
      Agent.update(unique_name_per_process(), fn _state ->
        %{is_frozen: false, frozen_value: nil}
      end)
    end
  end

  def unique_name_per_process do
    binary_pid =
      self()
      |> :erlang.pid_to_list()
      |> :erlang.iolist_to_binary()

    "#{__MODULE__}_#{binary_pid}" |> String.to_atom()
  end
end
