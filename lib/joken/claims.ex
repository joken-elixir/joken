defprotocol Joken.Claims do

  @moduledoc """
  Handles turning data into claims when using the `with_claims` function in the
  `Joken` module.

  There is a default implementation for maps.

  Implementing `to_claims` expects a map to be returned.

  Structs can derive from `Joken.Claims` to be used as claims

      defmodule FullDerive do
        @derive Joken.Claims
        defstruct [:a, :b, :c]
      end

  derive supports using the `only` or `exclude` option as well
  """

  @spec to_claims(any) :: map
  def to_claims(data)
end

defimpl Joken.Claims, for: Any do

  defmacro __deriving__(module, struct, options) do
    deriving(module, struct, options)
  end

  def deriving(module, _struct, options) do

    extractor = cond do
      options[:only] && options[:exclude] ->
        raise ArgumentError, message: "Cannot use both :only and :exclude"
      only = options[:only] ->
        quote(do: Map.take(data, unquote(only)))
      exclude = options[:exclude] ->
        quote(do: Map.drop(data, [:__struct__ | unquote(exclude)]))
      true ->
        quote(do: :maps.remove(:__struct__, data))
    end

    quote do
      defimpl Joken.Claims, for: unquote(module) do
        def to_claims(data) do
          Joken.Claims.Map.to_claims(unquote(extractor))
        end
      end
    end
  end

  def to_claims(data) do
    raise Protocol.UndefinedError, value: data
  end

end

defimpl Joken.Claims, for: Map do

  defmacro __deriving__(module, struct, options) do
    Joken.Claims.Any.deriving(module, struct, options)
  end

  def to_claims(data) do
    Enum.reduce data, %{}, fn({key, value}, acc) ->
      case key do
        key when is_atom(key) ->
          Map.put(acc, Atom.to_string(key), value)
        key when is_binary(key) ->
          Map.put(acc, key, value)
        _ ->
          raise "Claim keys must be binaries"
      end
    end
  end
end
