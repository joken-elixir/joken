defmodule Joken.Codec do
  use Behaviour

  @moduledoc """
  Behaviour used by Joken to encode and decode data.
  """

  @doc """
  encode can take either a map or a keyword list or both and return a string.   
  """
  defcallback encode(Joken.payload) :: String.t
  
  @doc """
  decode can take a string and return a map or a keyword list. 
  """
  defcallback decode(String.t) :: Joken.payload
end