defmodule Joken.Json do
  use Behaviour

  defcallback encode(Map.t) :: String.t
  defcallback decode(String.t) :: Map.t
end