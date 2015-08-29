defprotocol Joken.Claims do
  def to_claims(data)
end

defimpl Joken.Claims, for: Map do
  def to_claims(data) do
    data
  end
end