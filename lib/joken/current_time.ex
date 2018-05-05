defmodule Joken.CurrentTime.OS do
  @moduledoc """
  Time source for default time based claims. Can be overriden in tests.
  """

  @doc "Returns current time in seconds."
  def current_time(), do: DateTime.utc_now() |> DateTime.to_unix()
end
