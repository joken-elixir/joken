defmodule Joken.Signer do
  @moduledoc """
  Interface between Joken and JOSE for signing and verifying tokens.
  """
  alias Joken.Signer
  alias JOSE.JWS
  alias JOSE.JWT
  alias JOSE.JWK

  @hs_algorithms ["HS256", "HS384", "HS512"]
  @rs_algorithms ["RS256", "RS384", "RS512"]
  @es_algorithms ["ES256", "ES384", "ES512"]
  @ps_algorithms ["PS256", "PS384", "PS512"]
  @eddsa_algorithms ["Ed25519", "Ed25519ph", "Ed448", "Ed448ph"]

  @map_key_algorithms @rs_algorithms ++ @es_algorithms ++ @ps_algorithms ++ @eddsa_algorithms

  @algorithms @hs_algorithms ++ @map_key_algorithms

  @type jwk :: %JWK{}
  @type jws :: %JWS{}

  @type t :: %__MODULE__{
          jwk: jwk,
          jws: jws,
          alg: binary()
        }

  defstruct [:jwk, :jws, :alg]

  @doc """
  All supported algorithms.
  """
  def algorithms, do: @algorithms

  @doc """
  Creates a new Joken.Signer struct. Can accept either a binary for HS*** algorithms
  or a map with arguments for the other kinds of keys.

  ## Example:

      iex> Joken.Signer.create("HS256", "s3cret")
      %Joken.Signer{
        alg: "HS256",
        jwk: %JOSE.JWK{
          fields: %{},
          keys: :undefined,
          kty: {:jose_jwk_kty_oct, "s3cret"}
        },
        jws: %JOSE.JWS{
          alg: {:jose_jws_alg_hmac, :HS256},
          b64: :undefined,
          fields: %{"typ" => "JWT"}
        }
      }
      
  """
  def create(alg, secret) when is_binary(secret) and alg in @hs_algorithms do
    %Signer{
      jws: JOSE.JWS.from_map(%{"alg" => alg, "typ" => "JWT"}),
      jwk: JOSE.JWK.from_oct(secret),
      alg: alg
    }
  end

  def create(alg, key) when is_map(key) and alg in @map_key_algorithms do
    %Signer{
      jws: JOSE.JWS.from_map(%{"alg" => alg, "typ" => "JWT"}),
      jwk: JOSE.JWK.from_map(key),
      alg: alg
    }
  end

  @doc """
  Signs a map of claims with the given Joken.Signer.

  ## Example

      iex> Joken.Signer.sign(%{"name" => "John Doe"}, Joken.Signer.create("HS256", "secret"))
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.xuEv8qrfXu424LZk8bVgr9MQJUIrp1rHcPyZw_KSsds"

      iex> Joken.Signer.sign(%{"name" => "John Doe"}, Joken.Signer.parse_config(:rs256))
      "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.e3hyn_oaaA2lxMlqH1UPo8STN-a_sszl8B2_s6tY9aT_YBAmfd7BXJOPsOMl7x2wXeKMQaNBVjna2tA0UiO_m3SpwiYgoTcU65D6OgkzugmLD_DhjDK1YCOKlm7So1uhbkb_QCuo4Ij5scsQqwv7hkxo4IximGBeH9LAvPhPTaGmYJMI7_tWIld2TlY6tNUQP4n0qctXsI3hjvGzdvuQW-tRnzAQCC4TYe-mJgFa033NSHeiX-sZB-SuYlWi7DJqDTiwlb_beVdqWpxxtFDA005Iw6FZTpH9Rs1LVwJU5t3RN5iWB-z4ZI-kKsGUGLNrAZ7btV6Ow2FMAdj9TXmNpQ"

  """
  def sign(claims, %Signer{jwk: jwk, jws: jws}) when is_map(claims) do
    {_, compacted_token} = JWT.sign(jwk, jws, claims) |> JWS.compact()
    compacted_token
  end

  def verify(token, %Signer{alg: alg, jwk: jwk}) when is_binary(token) do
    {true, %JWT{fields: claims}, _} = JWT.verify_strict(jwk, [alg], token)
    claims
  end

  @doc """
  Generates a Joken.Signer from Joken's application configuration.

  A Joken.Signer has an algorithm (one of #{inspect(@algorithms)}) and a key. 

  There are several types of keys used by JWTs algorithms: 
    - RSA
    - Elliptic Curve
    - Octet (binary) 
    - So on...

  Also, they can be encoded in several ways:
    - Raw (map of parameters)
    - PEM (Privacy Enhanced Mail format)
    - Open SSH encoding
    - So on...

  To ease configuring these types of keys used by JWTs algorithms, Joken accepts a few
  parameters in its configuration:
    - **signer_alg** : one of #{inspect(@algorithms)}
    - **signer_pem** : a binary containing a key in PEM encoding format 
    - **signer_ssh** : a binary containing a key in Open SSH encoding format
    - **signer_map** : a map with the raw parameters
    - **signer_secret** : a binary used as the password for HS algorithms only

  """
  def parse_config(key \\ :default_key) do
    case Application.get_env(:joken, key) do
      key_config when is_binary(key_config) ->
        create("HS256", key_config)

      key_config when is_list(key_config) ->
        parse_list_config(key_config)

      _ ->
        nil
    end
  end

  defp parse_list_config(config) do
    key_alg = Keyword.get(config, :key_alg, "HS256")
    key_pem = Keyword.get(config, :key_pem)
    key_map = Keyword.get(config, :key_map)
    key_secret = Keyword.get(config, :key_secret)

    cond do
      key_alg in @hs_algorithms ->
        parse_signer_with_secret(key_alg, key_secret)

      key_alg in @map_key_algorithms ->
        parse_signer_with_pem_or_map(key_alg, key_pem, key_map)

      true ->
        raise(Joken.Error, :unrecognized_algorithm)
    end
  end

  defp parse_signer_with_secret(key_alg, nil),
    do: raise(Joken.Error, [:hs_no_secret, [key_alg: key_alg]])

  defp parse_signer_with_secret(key_alg, secret) when is_binary(secret),
    do: %Signer{
      jwk: JOSE.JWK.from_oct(secret),
      jws: JOSE.JWS.from_map(%{"alg" => key_alg, "typ" => "JWT"}),
      alg: key_alg
    }

  defp parse_signer_with_pem_or_map(key_alg, nil, nil),
    do: raise(Joken.Error, [:no_map_or_pem, [key_alg: key_alg]])

  defp parse_signer_with_pem_or_map(key_alg, key_pem, key_map)
       when not is_nil(key_pem) and not is_nil(key_map),
       do: raise(Joken.Error, [:provided_pem_and_map, [key_alg: key_alg]])

  defp parse_signer_with_pem_or_map(key_alg, key_pem, nil),
    do: %Signer{
      jwk: JOSE.JWK.from_pem(key_pem),
      jws: JOSE.JWS.from_map(%{"alg" => key_alg, "typ" => "JWT"}),
      alg: key_alg
    }

  defp parse_signer_with_pem_or_map(key_alg, nil, key_map) when is_map(key_map),
    do: %Signer{
      jwk: JOSE.JWK.from_map(key_map),
      jws: JOSE.JWS.from_map(%{"alg" => key_alg, "typ" => "JWT"}),
      alg: key_alg
    }
end