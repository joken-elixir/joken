defmodule Joken.Token do
  alias Joken.Claims
  alias Joken.Utils

  @moduledoc """
  Module that handles encoding and decoding of tokens. For most cases, it's recommended to use the Joken module, but
  if you need to use this module directly, you can.
  """

  @spec encode(String.t, module, Joken.payload, Joken.algorithm, Joken.payload) :: {Joken.status, binary}
  def encode(secret_key, json_module, payload, algorithm \\ :HS256, claims \\ %{}) do
    headerJSON = json_module.encode(%{ alg: to_string(algorithm), typ: :JWT })

    {status, payloadJSON} = get_payload_json(payload, claims, json_module)

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
  def decode(secret_key, json_module, token, algorithm \\ :HS256, claims \\ %{}) do
    token
    |> verify_signature(secret_key, algorithm)
    |> get_data(json_module)
    |> Claims.check_exp
    |> Claims.check_nbf
    |> Claims.check_iat
    |> Claims.check_aud(Map.get(claims, :aud, nil))
    |> Claims.check_iss(Map.get(claims, :iss, nil))
    |> Claims.check_sub(Map.get(claims, :sub, nil))
    |> to_map
  end

  defp verify_signature(token, key, algorithm) do
    case String.split(token, ".") do
      [ _header64, _payload64 ] -> { :error, "Missing signature" }
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

  defp get_data({ :ok, jwt }, json_module) do
    [_, payload64 | _tail] = String.split(jwt, ".")

    data = Utils.base64url_decode(payload64)
    {:ok, json_module.decode(data) }
  end

  defp get_data(error, _json_module) do
    error
  end

  defp to_map({ :ok, keywords }), do: {:ok, keywords |> Enum.into(%{})}
  defp to_map(error), do: error

end
