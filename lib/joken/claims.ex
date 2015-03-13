defmodule Joken.Claims do
  alias Joken.Json, as: JSON
  alias Joken.Utils
  @moduledoc false

  def check_signature({:ok, data}, _supported_algs, _key) when length(data) == 2 do
    {:ok, Enum.fetch!(data, 1)}
  end

  def check_signature({:ok, data}, supported_algs, key) when length(data) == 3 do
    [ header, payload, jwt_signature ] = data

    header64 = header |> JSON.encode |> Utils.base64url_encode
    payload64 = payload |> JSON.encode |> Utils.base64url_encode

    alg = header[:alg] |> String.to_atom

    signature = :crypto.hmac(supported_algs[alg], key, "#{header64}.#{payload64}")

    if Utils.base64url_encode(signature) == jwt_signature do
        {:ok, payload}
    else
        {:error, "Invalid signature"}
    end

  end

  def check_signature({_status, _data}, _supported_algs, _key) do
    {:error, "Invalid JSON Web Token"}
  end

  def check_signature(error, _supported_algs, _key) do
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
    key_found? = Map.has_key?(payload, key)
    current_time = Timex.Time.now(:secs)

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
    key_found? = Map.has_key?(payload, key_to_check)

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
