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

  @spec decode(String.t, module, String.t, Joken.payload) :: {Joken.status, map | String.t}
  def decode(secret_key, json_module, token, claims \\ %{}) do
    token
    |> get_data(json_module)
    |> Claims.check_signature(secret_key, json_module)
    |> Claims.check_exp
    |> Claims.check_nbf
    |> Claims.check_aud(Map.get(claims, :aud, nil))
    |> Claims.check_iss(Map.get(claims, :iss, nil))
    |> Claims.check_sub(Map.get(claims, :sub, nil))
    |> to_map
  end

  defp get_data(jwt, json_module) do
    values = String.split(jwt, ".")
    split_count = Enum.count(values)

    if split_count < 2 or split_count > 3 do
      {:error, "Invalid JSON Web Token"}
    else
      decoded_data = Enum.map_reduce(values, 0, fn(x, acc) ->
        if acc < 2 do
            data = Utils.base64url_decode(x)
            map = json_module.decode(data)

            { map , acc + 1}  
        else
            {x, acc + 1}
        end                  
      end)
      {decoded, _} = decoded_data
      {:ok, decoded}
    end
  end

  defp to_map({:ok, keywords}), do: {:ok, keywords |> Enum.into(%{})}
  defp to_map(error), do: error

end