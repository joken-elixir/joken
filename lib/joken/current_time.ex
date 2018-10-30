defmodule Joken.CurrentTime do
  @moduledoc "Behaviour for fetching current time"

  @doc """
  Returns the current time in seconds

  This is used for applications that want to control time for testing.
  """
  @callback current_time() :: pos_integer
end

defmodule Joken.CurrentTime.OS do
  @moduledoc """
  Time source for default time based claims. Can be overriden in tests.
  """

  @behaviour Joken.CurrentTime

  @doc """
  Returns current time in seconds

  Uses DateTime.utc_now/0.
  """
  @spec current_time() :: pos_integer
  def current_time, do: DateTime.utc_now() |> DateTime.to_unix()
end
