defmodule Joken.Signer do
  alias Joken.Token
  alias Joken.Signer
  alias JOSE.JWS
  alias JOSE.JWT
  alias JOSE.JWK

  @moduledoc """
  Signer is the JWK (JSON Web Key) and JWS (JSON Web Signature) configuration of
  Joken.

  JWK is used by JWS to generate a token _signature_ that is appended to the end
  of the token compact representation.

  Joken uses https://hex.pm/packages/jose to do signing and verification.

  Note: By default, the 'none' algorithm is disabled. To enable it, set the
  'allow_none_algorithm' key on the 'joken' app configuration to true
  """

  @type jwk :: %{}
  @type jws :: %{}

  @type t :: %__MODULE__{
          jwk: jwk,
          jws: jws
        }

  @doc "Enables the use of `none` algorithm."
  def configure_unsecured_signing() do
    JOSE.unsecured_signing(none_algorithm_allowed?())
  end

  defstruct [:jwk, :jws]

  @doc """
  Convenience for generating a Joken.Signer with the none algorithm.
  This raises `Joken.AlgorithmError` if the `none` algorightm is enabled.
  """
  @spec none(binary) :: Signer.t()
  def none(secret) do
    unless none_algorithm_allowed?() do
      raise Joken.AlgorithmError,
        message: """
          'none' algorithm is not allowed.
          In order to use the 'none algorithm', the 'allow_none_algorithm' key on
          the joken app's configuration must be set to 'true'
        """
    end

    %Signer{
      jws: %{"alg" => "none"},
      jwk: %{"kty" => "oct", "k" => Base.url_encode64(secret, padding: false)}
    }
  end

  @doc "Convenience for generating an HS*** Joken.Signer"
  @spec hs(binary, binary) :: Signer.t()
  def hs(alg, secret) when is_binary(secret) and alg in ["HS256", "HS384", "HS512"] do
    %Signer{
      jws: %{"alg" => alg},
      jwk: %{"kty" => "oct", "k" => Base.url_encode64(secret, padding: false)}
    }
  end

  @doc "Convenience for generating an EdDSA Joken.Signer"
  @spec eddsa(binary, map) :: Signer.t()
  def eddsa(alg, key) when is_map(key) and alg in ["Ed25519", "Ed25519ph", "Ed448", "Ed448ph"] do
    %Signer{jws: %{"alg" => alg}, jwk: key}
  end

  @doc "Convenience for generating an ES*** Joken.Signer"
  @spec es(binary, map) :: Signer.t()
  def es(alg, key) when is_map(key) and alg in ["ES256", "ES384", "ES512"] do
    %Signer{jws: %{"alg" => alg}, jwk: key}
  end

  @doc "Convenience for generating an RS*** Joken.Signer"
  @spec rs(binary, map) :: Signer.t()
  def rs(alg, key) when is_map(key) and alg in ["RS256", "RS384", "RS512"] do
    %Signer{jws: %{"alg" => alg}, jwk: key}
  end

  @doc "Convenience for generating an PS*** Joken.Signer"
  @spec ps(binary, map) :: Signer.t()
  def ps(alg, key) when is_map(key) and alg in ["PS256", "PS384", "PS512"] do
    %Signer{jws: %{"alg" => alg}, jwk: key}
  end

  @doc """
  Signs a payload (JOSE header + claims) with the configured signer.

  It raises ArgumentError if no signer was configured.
  """
  @spec sign(Token.t()) :: Token.t()
  def sign(%Token{signer: nil}) do
    raise ArgumentError, message: "Missing Signer"
  end

  def sign(token = %Token{signer: signer = %Signer{}}) do
    sign(token, signer)
  end

  @doc """
  Signs a payload (JOSE header + claims) with the given signer.

  This will override the configured signer.
  """
  @spec sign(Token.t(), Signer.t()) :: Token.t()
  def sign(token, %Signer{jws: nil, jwk: %{"kty" => "oct"} = jwk}) do
    jws = %{"alg" => "HS256"}
    sign(token, %Signer{jwk: jwk, jws: jws})
  end

  def sign(token, %Signer{jws: nil, jwk: jwk}) when is_binary(jwk) do
    jws = %{"alg" => "HS256"}
    sign(token, %Signer{jwk: jwk, jws: jws})
  end

  def sign(token, %Signer{jws: jws, jwk: secret}) when is_binary(secret) do
    jwk = %{
      "kty" => "oct",
      "k" => Base.url_encode64(:erlang.iolist_to_binary(secret), padding: false)
    }

    sign(token, %Signer{jwk: jwk, jws: jws})
  end

  def sign(token, signer) do
    header = token.header
    signer = %{signer | jws: Map.merge(signer.jws, header)}
    token = %{token | signer: signer}

    claims = prepare_claims(token)

    {_, compacted_token} = JWS.compact(JWT.sign(signer.jwk, signer.jws, claims))
    %{token | token: compacted_token, claims: claims, claims_generation: %{}}
  end

  @doc """
  Verifies a token signature and decodes its payload. This assumes a signer was
  configured. It raises if there was none.
  """
  @spec verify(Token.t(), Signer.t() | nil, Keyword.t()) :: Token.t()
  def verify(token, signer \\ nil, options \\ [])

  def verify(%Token{signer: nil}, nil, _options), do: raise(ArgumentError, message: "Missing Signer")

  def verify(token = %Token{signer: signer = %Signer{}}, nil, options), do: do_verify(token, signer, options)

  def verify(t, signer, options), do: do_verify(t, signer, options)

  @doc """
  Returns the token payload without validating or verifying
  """
  @spec peek(Token.t(), Keyword.t()) :: map
  def peek(%Token{token: compact_token} = token, options \\ []) do
    payload = JWS.peek_payload(compact_token)

    token
    |> decode_payload(payload)
    |> process_claims(options)
  end

  @doc """
  Returns the token header without validating or verifying
  """
  @spec peek_header(Token.t()) :: map
  def peek_header(%Token{token: compact_token} = token) do
    header = JWS.peek_protected(compact_token)

    token
    |> decode_payload(header)
  end

  ### PRIVATE
  defp do_verify(t = %Token{token: nil}, _signer, _options), do: %{t | error: "No compact token set for verification"}

  defp do_verify(
         t = %Token{token: token},
         s = %Signer{jwk: jwk, jws: %{"alg" => algorithm}},
         options
       ) do
    t = %{t | signer: s}
    t = %{t | error: nil}

    try do
      case JWK.verify_strict(token, [algorithm |> to_string], jwk) do
        {true, payload, jws} ->
          jws = jws |> JWS.to_map() |> elem(1)
          map_payload = decode_payload(t, payload)
          header = jws |> Map.drop(["alg", "typ"])
          validate_all_claims(t, header, map_payload, options)

        _ ->
          %{t | error: "Invalid signature"}
      end
    catch
      :error, cause ->
        %{t | error: "Could not verify token"}
    end
  end

  defp decode_payload(%Token{json_module: nil}, _), do: raise(ArgumentError, message: "No JSON module defined")

  defp decode_payload(%Token{json_module: :jsx}, payload)
       when is_binary(payload) do
    :jsx.decode(payload, [:return_maps])
  end

  defp decode_payload(%Token{json_module: json}, payload)
       when is_binary(payload) do
    json.decode!(payload)
  end

  defp validate_all_claims(t = %Token{validations: validations}, header, map_payload, options)
       when is_map(map_payload) do
    validations =
      if options[:skip_claims] do
        Map.drop(validations, options[:skip_claims])
      else
        validations
      end

    {valid_claims, errors} =
      Enum.reduce(validations, {[], []}, fn {key, {valid?, message, optional}}, acc ->
        validate_key(map_payload, key, valid?, message, optional, acc)
      end)

    claims =
      valid_claims ++
        Enum.filter(map_payload, fn {key, _} ->
          not Map.has_key?(validations, key)
        end)

    case errors do
      [first | _] -> %{t | error: first, errors: errors}
      _ -> %{t | claims: process_claims(claims, options), header: header}
    end
  end

  defp validate_key(map_payload, key, valid?, message, optional, {claims, errors}) when is_binary(key) do
    if (not optional and Map.has_key?(map_payload, key) and valid?.(map_payload[key])) or optional do
      {[{key, map_payload[key]} | claims], errors}
    else
      case message do
        nil ->
          {claims, ["Invalid payload" | errors]}

        _ ->
          {claims, [message | errors]}
      end
    end
  end

  defp validate_key(map_payload, keys, valid?, message, optional, {claims, errors}) when is_list(keys) do
    if (Enum.all?(keys, &Map.has_key?(map_payload, &1)) and apply(valid?, Enum.map(keys, &Map.fetch!(map_payload, &1)))) or
         optional do
      {claims, errors}
    else
      case message do
        nil ->
          {claims, ["Invalid payload" | errors]}

        _ ->
          {claims, [message | errors]}
      end
    end
  end

  def process_claims(claims, options) do
    struct_name = options[:as]

    if struct_name do
      struct(
        struct_name,
        Enum.map(claims, fn {key, value} ->
          {String.to_existing_atom(key), value}
        end)
      )
    else
      Enum.into(claims, %{})
    end
  end

  defp prepare_claims(%Token{claims: claims, claims_generation: generators}) do
    claims =
      if Enum.empty?(generators) do
        claims
      else
        Enum.map_reduce(generators, claims, fn {claim_key, function}, acc ->
          {[], Map.put(acc, claim_key, function.())}
        end)
        |> elem(1)
      end

    retrieve_claims(claims)
  end

  defp retrieve_claims(%{__struct__: _} = claims) do
    Map.from_struct(claims)
  end

  defp retrieve_claims(claims) when is_map(claims) do
    claims
  end

  defp retrieve_claims(_) do
    raise ArgumentError, message: "Claims must be a map"
  end

  defp none_algorithm_allowed?() do
    Application.get_env(:joken, :allow_none_algorithm, false)
  end
end
