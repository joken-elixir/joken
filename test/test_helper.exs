ExUnit.start()

defmodule Joken.TestPoison do
  @behaviour Joken.Config

  def secret_key() do
    "test"
  end

  def algorithm() do
    :HS256
  end

  def encode(map) do
    Poison.encode!(map)
  end

  def decode(binary) do
    Poison.decode!(binary, keys: :atoms!)
  end

  def claim(_, _) do
    nil
  end

  def validate_claim(:exp, payload, _) do
    Joken.Config.validate_time_claim(payload, :exp, "Token expired", fn(expires_at, now) -> expires_at > now end)
  end

  def validate_claim(:nbf, payload, _) do
    Joken.Config.validate_time_claim(payload, :nbf, "Token not valid yet", fn(not_before, now) -> not_before < now end) 
  end

  def validate_claim(:iat, payload, _) do
    Joken.Config.validate_time_claim(payload, :iat, "Token not valid yet", fn(not_before, now) -> not_before < now end) 
  end

  def validate_claim(_, _, _) do
    :ok
  end
end

defmodule Joken.TestJsx do
  @behaviour Joken.Config

  def secret_key() do
    "test"
  end

  def algorithm() do
    :HS256
  end

  def encode(map) do
    :jsx.encode(map)
  end

  def decode(binary) do
    :jsx.decode(binary)
    |> Enum.map(fn({key, value})-> {String.to_atom(key), value} end)
  end

  def claim(_, _) do
    nil
  end

  def validate_claim(:exp, payload, _) do
    Joken.Config.validate_time_claim(payload, :exp, "Token expired", fn(expires_at, now) -> expires_at > now end)
  end

  def validate_claim(:nbf, payload, _) do
    Joken.Config.validate_time_claim(payload, :nbf, "Token not valid yet", fn(not_before, now) -> not_before < now end) 
  end

  def validate_claim(:iat, payload, _) do
    Joken.Config.validate_time_claim(payload, :iat, "Token not valid yet", fn(not_before, now) -> not_before < now end) 
  end

  def validate_claim(_, _, _) do
    :ok
  end
end
