defmodule Joken.CurrentTime.OS do
  def current_time() do
    {mega, secs, _} = :os.timestamp()
    mega * 1_000_000 + secs
  end
end