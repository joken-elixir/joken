defmodule Joken.Signer do
  alias Joken.Token
  alias Joken.Signer
  require Logger

  @on_load :configure_unsecured_signing

  @moduledoc """
  Signer is the JWK (JSON Web Key) and JWS (JSON Web Signature) configuration of Joken.

  JWK is used by JWS to generate a token _signature_ that is appended to the end of the
  token compact representation.

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

  defp none_algorithm_allowed?() do
    Application.get_env(:joken, :allow_none_algorithm, false)
  end

  def configure_unsecured_signing() do
    JOSE.unsecured_signing(none_algorithm_allowed?())
  end

  defstruct [:jwk, :jws]

  @doc "Convenience for generating a Joken.Signer with the none algorithm"
  @spec none(binary) :: Signer.t
  def none(secret) do
    unless none_algorithm_allowed? do
      raise Joken.AlgorithmError, message: """
        'none' algorithm is not allowed.
        In order to use the 'none algorithm', the 'allow_none_algorithm' key on the
        joken app's configuration must be set to 'true'
      """
    end

    %Signer{ jws: %{ "alg" => "none" }, jwk: %{ "kty" => "oct", "k" => :base64url.encode(secret) } }
  end

  @doc "Convenience for generating an HS*** Joken.Signer"
  @spec hs(binary, binary) :: Signer.t
  def hs(alg, secret) when is_binary(secret)
    and alg in ["HS256", "HS384", "HS512"] do
    %Signer{jws: %{ "alg" => alg },
            jwk: %{ "kty" => "oct", "k" => :base64url.encode(secret) }}
  end

  @doc "Convenience for generating an ES*** Joken.Signer"
  @spec es(binary, map) :: Signer.t
  def es(alg, key) when is_map(key)
    and alg in ["ES256", "ES384", "ES512"] do
    %Signer{jws: %{ "alg" => alg }, jwk: key }
  end

  @doc "Convenience for generating an RS*** Joken.Signer"
  @spec rs(binary, map) :: Signer.t
  def rs(alg, key) when is_map(key)
    and alg in ["RS256", "RS384", "RS512"] do
    %Signer{jws: %{ "alg" => alg }, jwk: key }
  end

  @doc "Convenience for generating an PS*** Joken.Signer"
  @spec ps(binary, map) :: Signer.t
  def ps(alg, key) when is_map(key)
    and alg in ["PS256", "PS384", "PS512"] do
    %Signer{jws: %{ "alg" => alg }, jwk: key }
  end

  @doc """
  Signs a payload (JOSE header + claims) with the configured signer.

  It raises ArgumentError if no signer was configured.
  """
  @spec sign(Token.t) :: Token.t
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
  @spec sign(Token.t, Signer.t) :: Token.t
  def sign(token, %Signer{ jws: nil, jwk: %{ "kty" => "oct" } = jwk }) do
    jws = %{ "alg" => "HS256" }
    sign(token, %Signer{ jwk: jwk, jws: jws})
  end
  def sign(token, %Signer{ jws: nil, jwk: jwk }) when is_binary(jwk) do
    jws = %{ "alg" => "HS256" }
    sign(token, %Signer{ jwk: jwk, jws: jws})
  end
  def sign(token, %Signer{ jws: jws, jwk: secret }) when is_binary(secret) do
    jwk = %{ "kty" => "oct", "k" => :base64url.encode(:erlang.iolist_to_binary(secret)) }
    sign(token, %Signer{ jwk: jwk, jws: jws})
  end
  def sign(token, signer) do
    header = token.header
    signer = %{ signer | jws: Map.merge( signer.jws, header ) }
    token = %{ token | signer: signer }

    Logger.debug fn -> "Signing #{inspect token.claims} with #{inspect signer}" end

    claims = prepare_claims(token)

    {_, compacted_token} = JOSE.JWS.compact(JOSE.JWT.sign(signer.jwk, signer.jws, claims))
    %{ token | token: compacted_token }
  end

  @doc """
  Verifies a token signature and decodes its payload. This assumes a signer was configured.
  It raises if there was none.
  """
  @spec verify(Token.t, Signer.t | nil, Keyword.t) :: Token.t
  def verify(token, signer \\ nil, options \\ [])
  def verify(%Token{signer: nil}, nil, _options),
    do: raise(ArgumentError, message: "Missing Signer")
  def verify(token = %Token{signer: signer = %Signer{}}, nil, options),
    do: do_verify(token, signer, options)
  def verify(t, signer, options),
    do: do_verify(t, signer, options)


  @doc """
  Returns the token payload without validating or verifying
  """
  @spec peek(Token.t, Keyword.t) :: Token.t
  def peek(%Token{token: token} = t, options \\ []) do
    payload = JOSE.JWS.peek(token)
    decode_payload(t, payload)
    |> process_claims(options)
  end

  ### PRIVATE
  defp do_verify(t = %Token{token: nil}, _signer, _options),
    do: %{ t | error: "No compact token set for verification"}
  defp do_verify(t = %Token{token: token},
                 s = %Signer{jwk: jwk, jws: %{ "alg" => algorithm}},
                 options) do

    Logger.debug fn ->
      "Verifying #{token} using #{inspect s} with options #{inspect options}"
    end

    t = %{ t | signer: s }
    t = %{ t | error: nil }

    try do
      case JOSE.JWK.verify_strict(token, [algorithm |> to_string], jwk) do
        {true, payload, jws} ->
          jws = JOSE.JWS.to_map(jws) |> elem(1)
          map_payload = decode_payload(t, payload)
          header = jws |> Map.drop(["alg", "typ"])
          validate_all_claims(t, header, map_payload, options)
        _ ->
          %{ t | error: "Invalid signature" }
      end
    catch
      :error, cause ->
        Logger.warn fn -> "Error: #{inspect cause}" end
        %{ t | error: "Could not verify token" }
    end
  end

  defp decode_payload(%Token{json_module: nil}, _),
    do: raise(ArgumentError, message: "No JSON module defined")
  defp decode_payload(%Token{json_module: :jsx}, payload) when is_binary(payload) do
    :jsx.decode payload, [:return_maps]
  end
  defp decode_payload(%Token{json_module: json}, payload) when is_binary(payload) do
    json.decode! payload
  end

  defp validate_all_claims(t = %Token{validations: validations},
                           header,
                           map_payload,
                           options) when is_map(map_payload) do

    if options[:skip_claims],
      do: validations = Map.drop validations, options[:skip_claims]

    try do
      claims = Enum.reduce map_payload, [], fn({key, value}, acc) ->
        case Map.has_key? validations, key do
          false ->
            [{key, value} | acc]
          true ->
            case validations[key].(value) do
              true ->
                [{key, value} | acc]
              false ->
                raise ArgumentError
            end
        end
      end

      %{ t | claims: process_claims(claims, options), header: header }
    catch
      _, cause ->
        Logger.warn fn -> "Error: #{inspect cause}" end
        %{ t | error: "Invalid payload" }
    end
  end

  def process_claims(claims, options) do
    if struct_name = options[:as] do
      struct(struct_name, Enum.map(claims, fn({key, value}) ->
        { String.to_existing_atom(key), value }
      end))
    else
      Enum.into(claims, %{})
    end
  end

  defp prepare_claims(%Token{claims: claims, claims_generation: generators}) do

    unless Enum.empty? generators do
      {_, claims} = Enum.map_reduce generators, claims, fn {claim_key, function}, acc ->
        {[], Map.put(acc, claim_key, function.())}
      end
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

end
