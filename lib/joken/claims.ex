defmodule Joken.Claims do
  alias Joken.Utils
  @moduledoc false

  def check_signature({:ok, data},  _key, _algorithm, _token) when length(data) == 2 do
    {:ok, Enum.fetch!(data, 1)}
  end

  def check_signature({:ok, data}, key, algorithm, token) when length(data) == 3 do
    [ _, payload, jwt_signature ] = data
    [ header64, payload64, _ ] = String.split(token, ".")

    signature = :crypto.hmac(Utils.supported_algorithms[algorithm], key, "#{header64}.#{payload64}")

    if Utils.base64url_encode(signature) == jwt_signature do
        {:ok, payload}
    else
        {:error, "Invalid signature"}
    end

  end

  def check_signature({_status, _data}, _key, _algorithm, _token) do
    {:error, "Invalid JSON Web Token"}
  end

  def check_signature(error, _key, _algorithm, _token) do
    error
  end

  def check_exp({:ok, payload}) do
    check_time_claim({:ok, payload}, :exp, "Token expired", fn(expires_at, now) -> expires_at > now end)
  end

  def check_exp(error) do
    error
  end

  def check_nbf({:ok, payload}) do
    check_time_claim({:ok, payload}, :nbf, "Token not valid yet", fn(not_before, now) -> not_before < now end) 
  end

  def check_nbf(error) do
    error
  end

  def check_time_claim({:ok, payload}, key, error_msg, validate_time_fun) do
    key_found? = case payload do
      p when is_map(p) ->
        Map.has_key?(payload, key)
      _ ->
        Keyword.has_key?(payload, key)
    end

    current_time = Utils.get_current_time()

    cond do
      key_found? and validate_time_fun.(payload[key], current_time) ->
        {:ok, payload}
      key_found? and !validate_time_fun.(payload[key], current_time) ->
        {:error, error_msg}
      true ->
        {:ok, payload}        
    end
  end

  def check_aud({:ok, payload}, aud) do
    check_claim({:ok, payload}, :aud, aud, "audience")
  end

  def check_aud(error, _) do
    error
  end

  def check_iss({:ok, payload}, iss) do
    check_claim({:ok, payload}, :iss, iss, "issuer")
  end

  def check_iss(error, _) do
    error
  end

  def check_sub({:ok, payload}, sub) do
    check_claim({:ok, payload}, :sub, sub, "subject")
  end

  def check_sub(error, _) do
    error
  end

  def check_claim({:ok, payload}, key_to_check, value, full_name) do
    key_found? = case payload do
      p when is_map(p) ->
        Map.has_key?(payload, key_to_check)
      _ ->
        Keyword.has_key?(payload, key_to_check)
    end

    cond do
      value == nil ->
        {:ok, payload}        
      key_found? and payload[key_to_check] == value ->
        {:ok, payload}
      key_found? and payload[key_to_check] != value ->
        {:error, "Invalid #{full_name}"}
      !key_found? ->
        {:error, "Missing #{full_name}"}
      true ->
        {:ok, payload}        
    end
  end

end
