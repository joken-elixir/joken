defprotocol Joken.Claims do
  def to_claims(data)
end

defimpl Joken.Claims, for: Map do

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
    data
  end
end
