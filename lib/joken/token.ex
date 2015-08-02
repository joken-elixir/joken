defmodule Joken.Token do
  alias Joken.Utils

  @claims [:exp, :nbf, :iat, :aud, :iss, :sub, :jti]
  @supported_algorithms %{ HS256: :sha256 , HS384: :sha384, HS512: :sha512 }

  @moduledoc """
  Module that handles encoding and decoding of tokens. For most cases, it's recommended to use the Joken module, but
  if you need to use this module directly, you can.
  """

  @spec encode(module, Joken.payload) :: {Joken.status, binary}
  def encode(joken_config, payload) do
    headerJSON = joken_config.encode(%{ alg: to_string(joken_config.algorithm), typ: :JWT })

    claims = Enum.reduce(@claims, %{}, fn(claim, current_claims) ->
      result = joken_config.claim(claim, payload)

      if result != nil do
        Map.put(current_claims, claim, result)
      else
        current_claims
      end
    end)

    {status, payloadJSON} = get_payload_json(payload, claims, joken_config)

    case Dict.has_key?(@supported_algorithms, joken_config.algorithm) do
      false ->
        {:error, "Unsupported algorithm"}
      _ ->
        case status do
          :error ->
            {:error, "Error encoding to JSON"}
          :ok ->
            header64 = Utils.base64url_encode(headerJSON)
            payload64 = Utils.base64url_encode(payloadJSON)

            signature = :crypto.hmac(@supported_algorithms[joken_config.algorithm], joken_config.secret_key, "#{header64}.#{payload64}")
            signature64 = Utils.base64url_encode(signature)

            {:ok, "#{header64}.#{payload64}.#{signature64}"}
        end
    end
  end

  defp get_payload_json(%{__struct__: _mod} = payload, claims, json_module) do
    get_payload_json(Map.from_struct(payload), claims, json_module)
  end
  
  defp get_payload_json(payload, claims, json_module) do
    try do
      { :ok, Dict.merge(payload, claims) |> json_module.encode }
    rescue
      _ ->
        {:error, nil}
    end
  end

  @spec decode(module, String.t, [Keyword.t]) :: {Joken.status, map | String.t}
  def decode(joken_config, token, options \\ []) do

    {skip_options, options} = Dict.pop options, :skip, []
    
    claims = @claims -- skip_options

    {status, result} = verify_signature(token, joken_config.secret_key, joken_config.algorithm)

    case status do
      :error ->
        { status, result }
      _ ->
        {:ok, data} = get_data(token, joken_config)

        results = claims ++ Dict.keys(options)
        |> Enum.uniq
        |> Enum.map(fn(claim) ->
           joken_config.validate_claim(claim, data, options)
        end)
        |> Enum.filter(fn(result) ->
          case result do
            {:error, _message} ->
              true
            _ ->
              false
          end
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
      [ _header64, _payload64 ] -> { :error, "Missing signature" }
      [ header64, payload64, jwt_signature ] ->
        signature = :crypto.hmac(@supported_algorithms[algorithm], key, "#{header64}.#{payload64}")

        if Utils.base64url_encode(signature) == jwt_signature do
            { :ok, token }
        else
            {:error, "Invalid signature"}
        end
      _ ->
        {:error, "Invalid JSON Web Token"}
    end

  end

  defp get_data(jwt, joken_config) do
    [_, payload64 | _tail] = String.split(jwt, ".")

    data = Utils.base64url_decode(payload64)
    {:ok, joken_config.decode(data) }
  end

  defp to_map(%{__struct__: _mod} = struct), do: struct

  defp to_map(keywords) do
    keywords |> Enum.into(%{})
  end

end
