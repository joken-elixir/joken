defmodule Joken.CurrentTime.OS do
  @moduledoc """
  Time source for default time based claims. Can be overriden in tests.
  """

  @doc """
  Returns current time in seconds.
  """
  def current_time() do
    {mega, secs, _} = :os.timestamp()
    mega * 1_000_000 + secs
  end
end
