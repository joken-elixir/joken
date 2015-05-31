defmodule Joken.Token do
  alias Joken.Utils

  @moduledoc """
  Module that handles encoding and decoding of tokens. For most cases, it's recommended to use the Joken module, but
  if you need to use this module directly, you can.
  """

  @spec encode(String.t, module, Joken.payload, Joken.algorithm) :: {Joken.status, binary}
  def encode(secret_key, claims_behaviour, payload, algorithm \\ :HS256) do
    headerJSON = claims_behaviour.encode(%{ alg: to_string(algorithm), typ: :JWT })

    claims_fun = [
      exp: &claims_behaviour.exp/1, 
      nbf: &claims_behaviour.nbf/1, 
      iat: &claims_behaviour.iat/1,
      aud: &claims_behaviour.aud/1,
      iss: &claims_behaviour.iss/1,
      sub: &claims_behaviour.sub/1,
      jti: &claims_behaviour.jti/1,
    ]

    claims = Enum.reduce(claims_fun, %{}, fn({key, func}, current_claims) ->
      result = func.(payload)

      if result != nil do
        Map.put(current_claims, key, result)
      else
        current_claims
      end
    end)


    {status, payloadJSON} = get_payload_json(payload, claims, claims_behaviour)

    case Map.has_key?(Utils.supported_algorithms, algorithm) do
      false ->
        {:error, "Unsupported algorithm"} 
      _ ->
        case status do
          :error ->
            {:error, "Error encoding to JSON"}
          :ok ->
            header64 = Utils.base64url_encode(headerJSON)
            payload64 = Utils.base64url_encode(payloadJSON)

            signature = :crypto.hmac(Utils.supported_algorithms[algorithm], secret_key, "#{header64}.#{payload64}")
            signature64 = Utils.base64url_encode(signature)

            {:ok, "#{header64}.#{payload64}.#{signature64}"}
        end              
    end
  end

  defp get_payload_json(payload, claims, json_module) do
    try do 
      case payload do
        p when is_map(payload) ->
          {:ok, Map.merge(payload, claims) |> json_module.encode}
        _ ->
          claims = if is_map(claims), do: Map.to_list(claims), else: claims
          {:ok, Keyword.merge(payload, claims) |> json_module.encode}
      end          
    rescue 
      _ -> 
        {:error, nil} 
    end
  end

  @spec decode(String.t, module, String.t, Joken.algorithm, Joken.payload) :: {Joken.status, map | String.t}
  def decode(secret_key, claims_behaviour, token, algorithm \\ :HS256, skip \\ []) do

    validations = [
      exp: &claims_behaviour.validate_exp/1, 
      nbf: &claims_behaviour.validate_nbf/1, 
      iat: &claims_behaviour.validate_iat/1,
      aud: &claims_behaviour.validate_aud/1,
      iss: &claims_behaviour.validate_iss/1,
      sub: &claims_behaviour.validate_sub/1,
      jti: &claims_behaviour.validate_jti/1,
    ]


    {status, result} = verify_signature(token, secret_key, algorithm)

    case status do
      :error ->
        { status, result }
      _ ->
        {:ok, data} = get_data(token, claims_behaviour)

        results = Enum.reduce(skip, validations, fn(key, current_validations) ->
          Keyword.delete(current_validations, key)
        end)
        |> Enum.map(fn({key, func}) ->
          func.(data)
        end)
        |> Enum.filter(fn({key, value}) -> 
          key == :error
        end)
        |> Enum.map(fn(x) -> elem(x, 1) end)

        if Enum.empty?(results) do
          { :ok, to_map(data) }
        else
          { :error, hd(results) }
        end
    end

  end

  defp verify_signature(token, key, algorithm) do
    case String.split(token, ".") do
      [ _header64, _payload64 ] ->
        { :ok, token }
      [ header64, payload64, jwt_signature ] ->
        signature = :crypto.hmac(Utils.supported_algorithms[algorithm], key, "#{header64}.#{payload64}")

        if Utils.base64url_encode(signature) == jwt_signature do
            { :ok, token }
        else
            {:error, "Invalid signature"}
        end
      _ ->
        {:error, "Invalid JSON Web Token"}        
    end

  end

  defp get_data(jwt, claims_behaviour) do
    [_, payload64 | _tail] = String.split(jwt, ".")

    data = Utils.base64url_decode(payload64)
    {:ok, claims_behaviour.decode(data) }
  end

  defp to_map(keywords) do
    keywords |> Enum.into(%{})
  end

end
