defmodule Joken do
  alias Joken.Token
  alias Joken.Signer
  alias Joken.Token
  import Joken.Helpers

  @type algorithm :: :HS256 | :HS384 | :HS512
  @type claim :: :exp | :nbf | :iat | :aud | :iss | :sub | :jti
  @type status :: :ok | :error
  @type payload :: map | Keyword.t

  @moduledoc """
  Encodes and decodes JSON Web Tokens.

  Supports the following algorithms:

  * HS256
  * HS384
  * HS512

  Supports the following claims:

  * Expiration (exp)
  * Not Before (nbf)
  * Audience (aud)
  * Issuer (iss)
  * Subject (sub)
  * Issued At (iat)
  * JSON Token ID (jti)


  Usage:

  First, create a module that implements the `Joken.Config` Behaviour. 
  This Behaviour is responsible for the following:

    * encoding and decoding tokens
    * adding and validating claims
    * secret key used for encoding and decoding
    * the algorithm used

  If a claim function returns `nil` then that claim will not be added to the token. 
  Here is a full example of a module that would add and validate the `exp` claim 
  and not add or validate the others:


      defmodule My.Config.Module do
        @behaviour Joken.Config

        def secret_key() do
          Application.get_env(:app, :secret_key)
        end

        def algorithm() do
          :H256
        end

        def encode(map) do
          Poison.encode!(map)
        end

        def decode(binary) do
          Poison.decode!(binary, keys: :atoms!)
        end

        def claim(:exp, payload) do
          Joken.Helpers.get_current_time() + 300
        end

        def claim(_, _) do
          nil
        end

        def validate_claim(:exp, payload, options) do
          Joken.Helpers.validate_time_claim(payload, :exp, "Token expired", fn(expires_at, now) -> expires_at > now end)
        end

        def validate_claim(_, _, _) do
          :ok
        end
      end


  Joken looks for a `joken` config with `config_module`. `config_module` module being a module that implements the `Joken.Config` Behaviour.

       config :joken,
         config_module: My.Config.Module

  then to encode and decode

      {:ok, token} = Joken.encode(%{username: "johndoe"})

      {:ok, decoded_payload} = Joken.decode(jwt)
  """


  @doc """
  Encodes the given payload and optional claims into a JSON Web Token

      Joken.encode(%{ name: "John Doe" })
  """

  @spec encode(payload) :: { status, String.t }
  def encode(payload) do
    Token.encode(config_module, payload)
  end

  @doc """
  Decodes the given JSON Web Token and gets the payload

  token: The jwt token string to decode

  options (optional): a keyword list of decoding options. Most are passed to
  the validate_claim function when validating the claim. The `skip` option is
  not and is used to tell the decoder to skip the given claims when validating

  ex.

      #decode the given string with no options given
      Joken.decode(token)

      #decode the given string while skipping the exp claim
      Joken.decode(token, [ skip: [:exp] ])

      #decode the given string and pass the following the validate_claim function
      Joken.decode(token, [ user_id: 1, roles: [:admin] ])    

  """

  @spec decode(String.t, Keyword.t) :: { status, map | String.t }
  def decode(jwt, options \\ []) do
    Token.decode(config_module, jwt, options)
  end

  defp config_module() do
    Application.get_env(:joken, :config_module)
  end


  def token() do
    %Token{}
    |> with_exp
    |> with_iat
    |> with_nbf
    |> with_iss
    |> with_validation(:exp, &(&1 > get_current_time))
    |> with_validation(:iat, &(&1 < get_current_time))
    |> with_validation(:nbf, &(&1 < get_current_time))
    |> with_validation(:iss, &(&1 == "Joken"))
  end

  def token(payload) when is_map(payload) do
    %Token{claims: payload}
  end

  def token(token) when is_binary(token) do
    %Token{token: token}
  end

  def with_exp(token = %Token{claims: claims}) do
    %{ token | claims: Map.put(claims, :exp, get_current_time + (2 * 60 * 60 * 1000)) }
  end
  def with_exp(token = %Token{claims: claims}, time_to_expire) do
    %{ token | claims: Map.put(claims, :exp, time_to_expire) }
  end

  def with_iat(token = %Token{claims: claims}) do
    %{ token | claims: Map.put(claims, :iat, get_current_time) }
  end
  def with_iat(token = %Token{claims: claims}, time_issued_at) do
    %{ token | claims: Map.put(claims, :iat, time_issued_at) }
  end

  def with_nbf(token = %Token{claims: claims}) do
    %{ token | claims: Map.put(claims, :nbf, get_current_time - 100) }
  end
  def with_nbf(token = %Token{claims: claims}, time_not_before) do
    %{ token | claims: Map.put(claims, :nbf, time_not_before) }
  end

  def with_iss(token = %Token{claims: claims}) do
    %{ token | claims: Map.put(claims, :iss, "Joken") }
  end
  def with_iss(token = %Token{claims: claims}, issuer) do
    %{ token | claims: Map.put(claims, :iss, issuer) }
  end

  def with_sub(token = %Token{claims: claims}, sub) do
    %{ token | claims: Map.put(claims, :sub, sub) }
  end

  def with_aud(token = %Token{claims: claims}, aud) do
    %{ token | claims: Map.put(claims, :aud, aud) }
  end

  def with_jti(token = %Token{claims: claims}, jti) do
    %{ token | claims: Map.put(claims, :jti, jti) }
  end

  def with_claim(token = %Token{claims: claims}, claim_key, claim_value) do
    %{ token | claims: Map.put(claims, claim_key, claim_value) }
  end

  def with_HS256(token, secret) when is_binary(secret) do
    %{ token | signer: %Signer{jws: %{ "alg" => "HS256" }, jwk: secret} }
  end

  def with_HS384(token, secret) when is_binary(secret) do
    %{ token | signer: %Signer{jws: %{ "alg" => "HS384" }, jwk: secret} }
  end

  def with_HS512(token, secret) when is_binary(secret) do
    %{ token | signer: %Signer{jws: %{ "alg" => "HS512" }, jwk: secret} }
  end

  def sign(token), do: Signer.sign(token)
  def sign(token, signer), do: Signer.sign(token, signer)

  def get_compact(%Token{} = token), do: token.token

  def with_validation(token = %Token{validations: validations}, claim, function) when is_atom(claim) and is_function(function) do

    %{ token | validations: Map.put(validations, claim, function) }
  end

  def verify(%Token{} = token) do
    Signer.verify(token)
  end
  
end
