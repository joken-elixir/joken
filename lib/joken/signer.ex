defmodule Joken.Signer do
  alias Joken.Token
  alias Joken.Signer

  @moduledoc """
  Signer is the JWK (JSON Web Key) and JWS (JSON Web Signature) configuration of Joken.

  JWK is used by JWS to generate a token _signature_ that is appended to the end of the
  token compact representation.

  Joken uses https://hex.pm/packages/jose to do signing and verification.
  """
  
  @type jwk :: %{}
  @type jws :: %{}

  @type t :: %__MODULE__{
    jwk: jwk,
    jws: jws
  }
  
  defstruct [:jwk, :jws]

  @doc "Convenience for generating an HS256 Joken.Signer"
  @spec hs256(binary) :: Signer.t
  def hs256(secret) when is_binary(secret) do
    %Signer{jws: %{ "alg" => "HS256" },
            jwk: %{ "kty" => "oct", "k" => :base64url.encode(secret) }}
  end

  @doc "Convenience for generating an HS384 Joken.Signer"
  @spec hs384(binary) :: Signer.t
  def hs384(secret) when is_binary(secret) do
    %Signer{jws: %{ "alg" => "HS384" },
            jwk: %{ "kty" => "oct", "k" => :base64url.encode(secret) }}
  end

  @doc "Convenience for generating an HS512 Joken.Signer"
  @spec hs512(binary) :: Signer.t
  def hs512(secret) when is_binary(secret) do
    %Signer{jws: %{ "alg" => "HS512" },
            jwk: %{ "kty" => "oct", "k" => :base64url.encode(secret) }}
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
    token = %{ token | signer: signer }
    {_, compacted_token} = JOSE.JWS.compact(JOSE.JWT.sign(signer.jwk, signer.jws, token.claims))
    %{ token | token: compacted_token }
  end

  @doc """
  Verifies a token signature and decodes its payload. This assumes a signer was configured. 
  It raises if there was none.
  """
  @spec verify(Token.t) :: Token.t
  def verify(%Token{signer: nil}) do
    raise ArgumentError, message: "Missing Signer"
  end
  def verify(token = %Token{signer: signer = %Signer{}}) do
    verify(token, signer)
  end

  @doc """
  Verifies a token signature and decodes its payload. 
  It uses the given signer and sets it on the token.
  """
  @spec verify(Token.t, Signer.t) :: Token.t
  def verify(t = %Token{token: token}, s = %Signer{jwk: jwk, jws: %{ "alg" => algorithm}}) do

    t = %{ t | signer: s }
    
    try do
      case JOSE.JWK.verify(token, jwk) do
        {true, payload, jws} ->
          jws = :erlang.element(2, JOSE.JWS.to_map(jws))
          algorithm_string = algorithm |> to_string
          case jws["alg"] do
            ^algorithm_string ->
              map_payload = decode_payload(t, payload)
              validate_all_claims(t, map_payload)
            _ ->
              %{ t | error: "Invalid signature algorithm" }
          end
        _ ->
          %{ t | error: "Invalid signature" }
      end
    catch
      :error, _ ->
        %{ t | error: "Missing signature" }
    end
  end

  ### PRIVATE
  
  defp decode_payload(%Token{json_module: json}, payload) when is_binary(payload) do
    json.decode! payload
  end

  defp validate_all_claims(t = %Token{validations: validations}, map_payload)
    when is_map(map_payload) do

    try do
      claims = Enum.reduce map_payload, [], fn({key, value}, acc) ->
        case Map.has_key? validations, val_key = String.to_existing_atom(key) do
          false ->
            [{val_key, value} | acc]
          true ->
            case validations[val_key].(value) do
              true ->
                [{val_key, value} | acc]
              false ->
                raise ArgumentError 
            end
        end
      end
      %{ t | claims: Enum.into(claims, %{}) }
    catch
      _,_ ->
        %{ t | error: "Invalid payload" }
    end
  end
  
end
