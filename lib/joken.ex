defmodule Joken do
  alias Joken.Json, as: JSON
  alias Joken.Utils
  alias Joken.Claims

  @type alg :: :HS256 | :HS384 | :HS512
  @type status :: :ok | :error

  @supported_algs %{ HS256: :sha256 , HS384: :sha384, HS512: :sha512 }
  @moduledoc """
    Encodes and decodes JSON Web Tokens.

    iex(1)> Joken.encode(%{username: "johndoe"}, "secret")
    {:ok,
     "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VybmFtZSI6ImpvaG5kb2UifQ.OFY_3SbHl2YaM7Y4Lj24eVMtcDaGEZU7KRzYCV4cqog"}
    iex(2)> Joken.decode("eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VybmFtZSI6ImpvaG5kb2UifQ.OFY_3SbHl2YaM7Y4Lj24eVMtcDaGEZU7KRzYCV4cqog", "secret")
    {:ok, %{username: "johndoe"}}

    iex(3)> Joken.encode(%{username: "johndoe"}, "secret", :HS384, %{ iss: "self"})                                                                                                                  {:ok,
     "eyJhbGciOiJIUzM4NCIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzZWxmIiwidXNlcm5hbWUiOiJqb2huZG9lIn0.wG_LAQ7Z3uRl7B0TEuxvfHdqikU3boPorm5ldS6dutJ9r076i-LRCuascaxoNDw1"}
    iex(4)> Joken.decode("eyJhbGciOiJIUzM4NCIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzZWxmIiwidXNlcm5hbWUiOiJqb2huZG9lIn0.wG_LAQ7Z3uRl7B0TEuxvfHdqikU3boPorm5ldS6dutJ9r076i-LRCuascaxoNDw1", "secret", %{ iss: "not:self"})
    {:error, "Invalid issuer"}
  """

  @doc """
    Encodes the payload into a JSON Web Token using the specified key and alg.
    Adds the specified claims to the payload as well

    alg must be either :HS256, :HS384, or :HS512
    
    default alg is :HS256

    default claims is an empty map

  """
  @spec encode(map, binary, alg, map) :: { status, binary }
  def encode(payload, key, alg \\ :HS256, claims \\ %{}) do
    cond do
      !Map.has_key?(@supported_algs, alg) ->
        {:error, "Unsupported algorithm"}
      true ->
        headerJSON = JSON.encode(%{ alg: to_string(alg), typ: :JWT })
        {status, payloadJSON} = try do {:ok, Map.merge(payload, claims) |> JSON.encode} rescue _ -> {:error, nil} end

        case status do
          :error ->
            {:error, "Error encoding Map to JSON"}
          :ok ->
            header64 = Utils.base64url_encode(headerJSON)
            payload64 = Utils.base64url_encode(payloadJSON)

            signature = :crypto.hmac(@supported_algs[alg], key, "#{header64}.#{payload64}")
            signature64 = Utils.base64url_encode(signature)

            {:ok, "#{header64}.#{payload64}.#{signature64}"}
        end
    end
  end

  @doc """
    Decodes the given jwt using the given key.
    Also checks against aud, iss, and sub if given in the claims map.
    claims defaults to an empty map.

  """
  @spec decode(binary, binary, map) :: { status, map | binary }
  def decode(jwt, key, claims \\ %{}) when
    is_nil(jwt) == false and 
    byte_size(jwt) > 0 and
    is_nil(key) == false and 
    byte_size(key) > 0 and
    is_map(claims)
  do
    jwt
    |> Utils.get_data
    |> Claims.check_signature(@supported_algs, key)
    |> Claims.check_exp
    |> Claims.check_nbf
    |> Claims.check_aud(Map.get(claims, :aud, nil))
    |> Claims.check_iss(Map.get(claims, :iss, nil))
    |> Claims.check_sub(Map.get(claims, :sub, nil))
    |> Utils.to_map
  end

end
