defmodule Joken.Signer do
  @moduledoc """
  Interface between Joken and JOSE for signing and verifying tokens.

  In the future we plan to keep this interface but make it pluggable for other crypto
  implementations like using only standard `:crypto` and `:public_key` modules. So,
  **avoid** depending on the inner structure of this module.
  """
  alias JOSE.{JWK, JWS, JWT}

  @hs_algorithms ["HS256", "HS384", "HS512"]
  @rs_algorithms ["RS256", "RS384", "RS512"]
  @es_algorithms ["ES256", "ES384", "ES512"]
  @ps_algorithms ["PS256", "PS384", "PS512"]
  @eddsa_algorithms ["Ed25519", "Ed25519ph", "Ed448", "Ed448ph"]

  @map_key_algorithms @rs_algorithms ++ @es_algorithms ++ @ps_algorithms ++ @eddsa_algorithms

  @algorithms @hs_algorithms ++ @map_key_algorithms

  @typedoc "A key may be an octet or a map with parameters according to JWK (JSON Web Key)"
  @type key :: binary() | map()

  @typedoc """
  A `Joken.Signer` instance is a JWS (JSON Web Signature) and JWK (JSON Web Key) struct.

  It also contains an `alg` field for performance reasons.
  """
  @type t :: %__MODULE__{
          jwk: JWK.t() | nil,
          jws: JWS.t() | nil,
          alg: binary() | nil
        }

  defstruct jwk: nil, jws: nil, alg: nil

  @doc """
  All supported algorithms.
  """
  @spec algorithms() :: [binary()]
  def algorithms, do: @algorithms

  @doc """
  Map key algorithms.
  """
  @spec map_key_algorithms() :: [binary()]
  def map_key_algorithms, do: @map_key_algorithms

  @doc """
  Creates a new Joken.Signer struct. Can accept either a binary for HS*** algorithms
  or a map with arguments for the other kinds of keys. Also, accepts an optional map
  that will be passed as extra header arguments for generated JWT tokens.

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
  @spec create(binary(), key(), %{binary() => term()}) :: __MODULE__.t()
  def create(alg, key, jose_extra_headers \\ %{})

  def create(alg, secret, headers) when is_binary(secret) and alg in @hs_algorithms do
    raw_create(
      alg,
      headers |> Map.merge(%{"alg" => alg, "typ" => "JWT"}) |> JWS.from_map(),
      JWK.from_oct(secret)
    )
  end

  def create(alg, %{"pem" => pem}, headers) when alg in @map_key_algorithms do
    raw_create(
      alg,
      headers |> Map.merge(%{"alg" => alg, "typ" => "JWT"}) |> JWS.from_map(),
      JWK.from_pem(pem)
    )
  end

  def create(alg, key, headers) when is_map(key) and alg in @map_key_algorithms do
    raw_create(
      alg,
      headers |> Map.merge(%{"alg" => alg, "typ" => "JWT"}) |> JWS.from_map(),
      JWK.from_map(key)
    )
  end

  def create(alg, _key, _headers) when alg in @map_key_algorithms,
    do: raise(Joken.Error, :algorithm_needs_key)

  def create(_, _, _), do: raise(Joken.Error, :unrecognized_algorithm)

  defp raw_create(alg, jws, jwk) do
    %__MODULE__{
      jws: jws,
      jwk: jwk,
      alg: alg
    }
  end

  @doc """
  Signs a map of claims with the given Joken.Signer.

  ## Examples

      iex> Joken.Signer.sign(%{"name" => "John Doe"}, Joken.Signer.create("HS256", "secret"))
      {:ok, "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.xuEv8qrfXu424LZk8bVgr9MQJUIrp1rHcPyZw_KSsds"}

      iex> Joken.Signer.sign(%{"name" => "John Doe"}, Joken.Signer.parse_config(:rs256))
      {:ok, "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.e3hyn_oaaA2lxMlqH1UPo8STN-a_sszl8B2_s6tY9aT_YBAmfd7BXJOPsOMl7x2wXeKMQaNBVjna2tA0UiO_m3SpwiYgoTcU65D6OgkzugmLD_DhjDK1YCOKlm7So1uhbkb_QCuo4Ij5scsQqwv7hkxo4IximGBeH9LAvPhPTaGmYJMI7_tWIld2TlY6tNUQP4n0qctXsI3hjvGzdvuQW-tRnzAQCC4TYe-mJgFa033NSHeiX-sZB-SuYlWi7DJqDTiwlb_beVdqWpxxtFDA005Iw6FZTpH9Rs1LVwJU5t3RN5iWB-z4ZI-kKsGUGLNrAZ7btV6Ow2FMAdj9TXmNpQ"}

  """
  @spec sign(Joken.claims(), __MODULE__.t()) ::
          {:ok, Joken.bearer_token()} | {:error, Joken.error_reason()}
  def sign(claims, %__MODULE__{alg: _, jwk: jwk, jws: %JWS{alg: {alg, _}} = jws})
      when is_map(claims) do
    with result = {%{alg: ^alg}, _} <- JWT.sign(jwk, jws, claims),
         {_, compacted_token} <- JWS.compact(result) do
      {:ok, compacted_token}
    end
  end

  @doc """
  Verifies the given token's signature with the given `Joken.Signer`.

  ## Examples

      iex> Joken.Signer.verify("eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.xuEv8qrfXu424LZk8bVgr9MQJUIrp1rHcPyZw_KSsds", Joken.Signer.create("HS256", "secret"))
      {:ok, %{"name" => "John Doe"}}

      iex> Joken.Signer.verify("eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.e3hyn_oaaA2lxMlqH1UPo8STN-a_sszl8B2_s6tY9aT_YBAmfd7BXJOPsOMl7x2wXeKMQaNBVjna2tA0UiO_m3SpwiYgoTcU65D6OgkzugmLD_DhjDK1YCOKlm7So1uhbkb_QCuo4Ij5scsQqwv7hkxo4IximGBeH9LAvPhPTaGmYJMI7_tWIld2TlY6tNUQP4n0qctXsI3hjvGzdvuQW-tRnzAQCC4TYe-mJgFa033NSHeiX-sZB-SuYlWi7DJqDTiwlb_beVdqWpxxtFDA005Iw6FZTpH9Rs1LVwJU5t3RN5iWB-z4ZI-kKsGUGLNrAZ7btV6Ow2FMAdj9TXmNpQ", Joken.Signer.parse_config(:rs256))
      {:ok, %{"name" => "John Doe"}}

  """
  @spec verify(Joken.bearer_token(), __MODULE__.t()) ::
          {:ok, Joken.claims()} | {:error, Joken.error_reason()}
  def verify(token, %__MODULE__{alg: alg, jwk: jwk}) when is_binary(token) do
    case JWT.verify_strict(jwk, [alg], token) do
      {true, %JWT{fields: claims}, _} -> {:ok, claims}
      _ -> {:error, :signature_error}
    end
  end

  @doc """
  Generates a `Joken.Signer` from Joken's application configuration.

  A `Joken.Signer` has an algorithm (one of #{inspect(@algorithms)}) and a key.

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
    - **key_pem** : a binary containing a key in PEM encoding format
    - **key_openssh** : a binary containing a key in Open SSH encoding format
    - **key_map** : a map with the raw parameters
    - **key_octet** : a binary used as the password for HS algorithms only

  ## Examples

      config :joken,
        hs256: [
          signer_alg: "HS256",
          key_octet: "test"
        ]

      config :joken,
        rs256: [
          signer_alg: "RS256",
          key_pem: \"\"\"
          -----BEGIN RSA PRIVATE KEY-----
          MIICWwIBAAKBgQDdlatRjRjogo3WojgGHFHYLugdUWAY9iR3fy4arWNA1KoS8kVw33cJibXr8bvwUAUparCwlvdbH6dvEOfou0/gCFQsHUfQrSDv+MuSUMAe8jzKE4qW+jK+xQU9a03GUnKHkkle+Q0pX/g6jXZ7r1/xAK5Do2kQ+X5xK9cipRgEKwIDAQABAoGAD+onAtVye4ic7VR7V50DF9bOnwRwNXrARcDhq9LWNRrRGElESYYTQ6EbatXS3MCyjjX2eMhu/aF5YhXBwkppwxg+EOmXeh+MzL7Zh284OuPbkglAaGhV9bb6/5CpuGb1esyPbYW+Ty2PC0GSZfIXkXs76jXAu9TOBvD0ybc2YlkCQQDywg2R/7t3Q2OE2+yo382CLJdrlSLVROWKwb4tb2PjhY4XAwV8d1vy0RenxTB+K5Mu57uVSTHtrMK0GAtFr833AkEA6avx20OHo61Yela/4k5kQDtjEf1N0LfI+BcWZtxsS3jDM3i1Hp0KSu5rsCPb8acJo5RO26gGVrfAsDcIXKC+bQJAZZ2XIpsitLyPpuiMOvBbzPavd4gY6Z8KWrfYzJoI/Q9FuBo6rKwl4BFoToD7WIUS+hpkagwWiz+6zLoX1dbOZwJACmH5fSSjAkLRi54PKJ8TFUeOP15h9sQzydI8zJU+upvDEKZsZc/UhT/SySDOxQ4G/523Y0sz/OZtSWcol/UMgQJALesy++GdvoIDLfJX5GBQpuFgFenRiRDabxrE9MNUZ2aPFaFp+DyAe+b4nDwuJaW2LURbr8AEZga7oQj0uYxcYw==
          -----END RSA PRIVATE KEY-----
          \"\"\"
          ]

  """
  @spec parse_config(atom()) :: __MODULE__.t() | nil
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
    signer_alg = config[:signer_alg] || "HS256"
    headers = config[:jose_extra_headers] || %{}

    key_pem = config[:key_pem]
    key_map = config[:key_map]
    key_openssh = config[:key_openssh]
    key_octet = config[:key_octet]

    key_config =
      [
        {&JWK.from_pem/1, key_pem},
        {&JWK.from_map/1, key_map},
        {&JWK.from_openssh_key/1, key_openssh},
        {&JWK.from_oct/1, key_octet}
      ]
      |> Enum.filter(fn {_, val} -> not is_nil(val) end)

    unless Enum.count(key_config) == 1, do: raise(Joken.Error, :wrong_key_parameters)

    {jwk_function, value} = List.first(key_config)

    if signer_alg in @algorithms do
      do_parse_signer(jwk_function.(value), signer_alg, headers)
    else
      raise Joken.Error, :unrecognized_algorithm
    end
  end

  defp do_parse_signer(jwk, signer_alg, headers) do
    raw_create(
      signer_alg,
      headers |> Map.merge(%{"alg" => signer_alg, "typ" => "JWT"}) |> JWS.from_map(),
      jwk
    )
  end
end
