defmodule Joken.Claim do
  @moduledoc """
  Structure for a dynamic claim. It is used for holding functions that generate 
  and validate claims.
  """

  @type t :: %__MODULE__{
          generate: fun() | nil,
          validate: fun() | nil,
          options: list()
        }

  # We have options here for customizing error messages and other possible extras
  defstruct generate: nil,
            validate: nil,
            options: []

  @doc false
  def __generate_claim__({key, %__MODULE__{generate: gen_fun}}, acc)
      when is_binary(key) and is_map(acc) do
    case Map.has_key?(acc, key) or not is_function(gen_fun, 0) do
      true ->
        acc

      _ ->
        Map.put(acc, key, gen_fun.())
    end
  end

  def __generate_claim__(_, acc), do: acc
end
