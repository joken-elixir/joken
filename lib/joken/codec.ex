defmodule Joken.Codec do
  use Behaviour

  defcallback encode(Map.t | Keyword.t) :: String.t
  defcallback decode(String.t) :: Map.t | Keyword.t
end