defmodule Joken.Signer do
  @moduledoc """
  Interface between Joken and JOSE for signing and verifying tokens.

  In the future we plan to keep this interface but make it pluggable for other crypto
  implementations like using only standard `:crypto` and `:public_key` modules. So,
  **avoid** depending on the inner structure of this module.
  """
  alias JOSE.JWK
  alias JOSE.JWS
  alias JOSE.JWT

  require Joken.ASN1
  require Record

  @hs_algorithms ["HS256", "HS384", "HS512"]
  @rs_algorithms ["RS256", "RS384", "RS512"]
  @es_algorithms ["ES256", "ES384", "ES512"]
  @ps_algorithms ["PS256", "PS384", "PS512"]
  @eddsa_algorithms ["Ed25519", "Ed25519ph", "Ed448", "Ed448ph", "EdDSA"]

  @map_key_algorithms @rs_algorithms ++ @es_algorithms ++ @ps_algorithms ++ @eddsa_algorithms

  @algorithms @hs_algorithms ++ @map_key_algorithms

  @typedoc "A key may be an octet or a map with parameters according to JWK (JSON Web Key)"
  @type key :: binary() | map()

  @typedoc """
  A `Joken.Signer` instance.

  When using JOSE library, JWS (JSON Web Signature) and JWK (JSON Web Key) are filled.

  When using pure Erlang's crypto, then key is filled.

  It also contains an `alg` field for performance reasons.
  """
  @type t :: %__MODULE__{
          jwk: map() | nil,
          jws: map() | nil,
          alg: binary(),
          key:
            nil
            | binary()
            | Joken.ASN1.rsa_private_key()
            | Joken.ASN1.rsa_public_key()
            | Joken.ASN1.ec_private_key()
            | Joken.ASN1.ec_point(),
          headers: map(),
          opts: Keyword.t()
        }

  defstruct jwk: nil, jws: nil, key: nil, alg: nil, headers: nil, opts: [crypto_provider: :jose]

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

  ## Example

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
  def create(alg, key, jose_extra_headers \\ %{}, opts \\ [])

  if Code.ensure_loaded?(JOSE.JWS) do
    def create(alg, secret, headers, opts) when is_binary(secret) and alg in @hs_algorithms do
      if opts[:crypto_provider] == :jose do
        %__MODULE__{
          alg: alg,
          jws: headers |> transform_headers(alg) |> JOSE.JWS.from_map(),
          jwk: JOSE.JWK.from_oct(secret),
          opts: opts
        }
      else
        %__MODULE__{alg: alg, key: secret, headers: headers, opts: opts}
      end
    end
  else
    def create(alg, secret, headers, opts) when is_binary(secret) and alg in @hs_algorithms do
      %__MODULE__{alg: alg, key: secret, headers: headers, opts: opts}
    end
  end

  def create(alg, _key, _headers, _opts) when alg in @hs_algorithms,
    do: raise(Joken.Error, :algorithm_needs_binary_key)

  if Code.ensure_loaded?(JOSE.JWS) do
    def create(alg, %{"pem" => pem}, headers, opts) when alg in @map_key_algorithms do
      if opts[:crypto_provider] == :jose do
        %__MODULE__{
          alg: alg,
          jws: headers |> transform_headers(alg) |> JOSE.JWS.from_map(),
          jwk: JOSE.JWK.from_pem(pem),
          opts: opts
        }
      else
        [key | _] = :public_key.pem_decode(pem)

        key =
          if Record.is_record(key, :SubjectPublicKeyInfo) do
            :public_key.pem_entry_decode(key)
          else
            key
          end

        %__MODULE__{alg: alg, key: key, headers: headers, opts: opts}
      end
    end

    def create(alg, key, headers, opts) when is_map(key) and alg in @map_key_algorithms do
      %__MODULE__{
        alg: alg,
        jws: headers |> transform_headers(alg) |> JOSE.JWS.from_map(),
        jwk: JOSE.JWK.from_map(key),
        opts: opts
      }
    end
  else
    def create(alg, %{"pem" => pem}, headers, opts) when alg in @map_key_algorithms do
      [key | _] = :public_key.pem_decode(pem)
      %__MODULE__{alg: alg, key: key, headers: headers, opts: opts}
    end
  end

  def create(alg, _key, _headers, _opts) when alg in @map_key_algorithms,
    do: raise(Joken.Error, :algorithm_needs_key)

  def create(_, _, _, _), do: raise(Joken.Error, :unrecognized_algorithm)

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
  if Code.ensure_loaded?(JOSE.JWS) do
    def sign(claims, %__MODULE__{
          alg: _,
          jwk: %JOSE.JWK{kty: {_, key}} = jwk,
          jws: %JOSE.JWS{alg: {alg, _}, fields: fields} = jws,
          opts: opts
        })
        when is_map(claims) do
      if Keyword.get(opts, :crypto_provider, :jose) == :jose do
        with result = {%{alg: ^alg}, _} <- JWT.sign(jwk, jws, claims),
             {_, compacted_token} <- JWS.compact(result) do
          {:ok, compacted_token}
        end
      else
        sign(claims, %__MODULE__{alg: alg, key: key, headers: fields || %{}, opts: opts})
      end
    end
  end

  def sign(claims, %__MODULE__{alg: alg, key: key, headers: headers}) do
    protected = claims |> Jason.encode!() |> Base.url_encode64(padding: false)

    header =
      (headers || %{}) |> Map.put(:alg, alg) |> Jason.encode!() |> Base.url_encode64(padding: false)

    to_sign = <<header::binary, ?., protected::binary>>

    signature = alg |> do_sign(to_sign, key) |> Base.url_encode64(padding: false)

    {:ok, <<to_sign::binary, ?., signature::binary>>}
  end

  defp do_sign("HS" <> length, to_sign, key), do: :crypto.mac(:hmac, :"sha#{length}", key, to_sign)

  defp do_sign("RS" <> length, to_sign, key),
    do: :public_key.sign(to_sign, :"sha#{length}", key, rsa_padding: :rsa_pkcs1_padding)

  defp do_sign("PS" <> length, to_sign, key),
    do:
      :public_key.sign(to_sign, :"sha#{length}", key,
        rsa_padding: :rsa_pkcs1_pss_padding,
        rsa_pss_saltlen: pss_saltlen(length),
        rsa_mgf1_md: :"sha#{length}"
      )

  defp do_sign("ES" <> length, to_sign, key) do
    der_bits = :public_key.sign(to_sign, :"sha#{length}", key)
    {_, r, s} = :public_key.der_decode(:"ECDSA-Sig-Value", der_bits)
    bits = ec_length_for_each_part(length)
    <<r::integer-size(bits), s::integer-size(bits)>>
  end

  # Length in bytes (octets) for each hash length
  defp pss_saltlen("256"), do: 32
  defp pss_saltlen("384"), do: 48
  defp pss_saltlen("512"), do: 64

  # Bits for each ES*** length algorithm
  defp ec_length_for_each_part("256"), do: 256
  defp ec_length_for_each_part("384"), do: 384
  defp ec_length_for_each_part("512"), do: 528

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

  if Code.ensure_loaded?(JOSE.JWS) do
    def verify(token, %__MODULE__{alg: alg, jwk: %JOSE.JWK{kty: {_, key}} = jwk, opts: opts})
        when is_binary(token) do
      if Keyword.get(opts, :crypto_provider, :jose) == :jose do
        case JWT.verify_strict(jwk, [alg], token) do
          {true, %JWT{fields: claims}, _} -> {:ok, claims}
          _ -> {:error, :signature_error}
        end
      else
        verify(token, %__MODULE__{alg: alg, key: key})
      end
    end
  end

  def verify(token, %__MODULE__{alg: alg, key: key}) when is_binary(token) do
    [header, payload, signature] = String.split(token, ".")
    %{"alg" => ^alg} = header |> Base.url_decode64!(padding: false) |> Jason.decode!()
    to_verify = <<header::binary, ?., payload::binary>>

    if do_verify(alg, key, to_verify, signature) do
      {:ok, payload |> Base.url_decode64!(padding: false) |> Jason.decode!()}
    else
      {:error, :signature_error}
    end
  end

  defp do_verify("HS" <> length, key, to_verify, signature) when is_binary(key) do
    digest = :"sha#{length}"
    check = :hmac |> :crypto.mac(digest, key, to_verify) |> Base.url_encode64(padding: false)
    :crypto.hash_equals(check, signature)
  end

  defp do_verify("RS" <> length, key, to_verify, signature)
       when Record.is_record(key, :RSAPrivateKey) or Record.is_record(key, :RSAPublicKey) do
    :public_key.verify(to_verify, :"sha#{length}", signature, key)
  end

  defp do_verify("PS" <> length, key, to_verify, signature)
       when Record.is_record(key, :RSAPrivateKey) or Record.is_record(key, :RSAPublicKey) do
    :public_key.verify(to_verify, :"sha#{length}", signature, key,
      rsa_padding: :rsa_pkcs1_pss_padding,
      # We do not assume any length when verifying
      rsa_pss_saltlen: -1,
      rsa_mgf1_md: :"sha#{length}"
    )
  end

  defp do_verify("ES" <> length, key, to_verify, signature)
       when Record.is_record(key, :ECPrivateKey) or Record.is_record(key, :ECPoint) do
    :public_key.verify(to_verify, :"sha#{length}", signature, key)
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

    - `:signer_alg` : one of #{inspect(@algorithms)}.
    - `:key_pem` : a binary containing a key in PEM encoding format.
    - `:key_openssh` : a binary containing a key in Open SSH encoding format.
    - `:key_map` : a map with the raw parameters.
    - `:key_octet` : a binary used as the password for HS algorithms only.

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
      Enum.filter(
        [
          {&JWK.from_pem/1, key_pem},
          {&JWK.from_map/1, key_map},
          {&JWK.from_openssh_key/1, key_openssh},
          {&JWK.from_oct/1, key_octet}
        ],
        fn {_, val} -> not is_nil(val) end
      )

    unless Enum.count(key_config) == 1, do: raise(Joken.Error, :wrong_key_parameters)

    {jwk_function, value} = List.first(key_config)

    if signer_alg in @algorithms do
      %__MODULE__{
        alg: signer_alg,
        jws: headers |> transform_headers(signer_alg) |> JWS.from_map(),
        jwk: jwk_function.(value),
        opts: []
      }
    else
      raise Joken.Error, :unrecognized_algorithm
    end
  end

  defp transform_headers(headers, signer_alg) when is_map(headers) and is_binary(signer_alg) do
    headers
    |> Map.put("alg", signer_alg)
    |> Map.put_new("typ", "JWT")
  end
end
