defmodule Joken.Token do
  alias Joken.Utils

  @claims [:exp, :nbf, :iat, :aud, :iss, :sub, :jti]

  @type json_module :: module
  @type claims      :: %{atom => any}
  @type validations :: %{atom => function}
  @type error       :: binary
  @type token       :: binary
  @type signer      :: Joken.Signer.t

  @type t :: %__MODULE__{
    json_module: module,
    claims: claims,
    validations: validations,
    error: error,
    token: token,
    signer: signer
  }
  
  defstruct [json_module: nil,
             claims: %{},
             validations: %{},
             error: nil,
             token: nil,
             signer: nil]

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

    case status do
      :error ->
        {:error, "Error encoding to JSON"}
      :ok ->
        {status, jws} = try do
          {:ok, JOSE.JWS.from_binary(headerJSON)}
        catch
          :error, reason ->
            {:error, reason}
        end
        
        case status do
          :error ->
            {:error, "Unsupported algorithm"}
          :ok ->
            jwk = get_secret_key(joken_config)
            {:ok, :erlang.element(2, JOSE.JWS.compact(JOSE.JWK.sign(payloadJSON, jws, jwk)))}
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

    {skip_verify, _} = Dict.pop options, :skip_verify, false
    {status, result} = verify_signature(token, get_secret_key(joken_config), joken_config.algorithm, skip_verify)

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

  defp verify_signature(token, _, _, true), do: {:ok, token}

  defp verify_signature(token, jwk, algorithm, _) do
    try do
      case JOSE.JWK.verify(token, jwk) do
        {true, _payload, jws} ->
          jws = :erlang.element(2, JOSE.JWS.to_map(jws))
          algorithm_string = algorithm |> to_string
          case jws["alg"] do
            ^algorithm_string ->
              {:ok, token}
            _ ->
              {:error, "Invalid signature algorithm"}
          end
        _ ->
          {:error, "Invalid signature"}
      end
    catch
      :error, _ ->
        {:error, "Missing signature"}
    end
  end

  defp get_data(jwt, joken_config) do
    [_, payload64 | _tail] = String.split(jwt, ".")

    data = Utils.base64url_decode(payload64)
    {:ok, joken_config.decode(data) }
  end

  defp get_secret_key(joken_config) do
    case joken_config.secret_key do
      iodata when is_binary(iodata) or is_list(iodata) ->
        JOSE.JWK.from_map(%{
          "kty" => "oct",
          "k" => :base64url.encode(:erlang.iolist_to_binary(iodata))
        })
      secret_key ->
        secret_key
    end
  end

  defp to_map(%{__struct__: _mod} = struct), do: struct

  defp to_map(keywords) do
    keywords |> Enum.into(%{})
  end

end
