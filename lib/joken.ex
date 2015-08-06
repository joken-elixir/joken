defmodule Joken do
  use Behaviour
  alias Joken.Token

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


  Joken looks for a config block with `joken_config`. `joken_config` module being a module that implements the `Joken.Config` Behaviour.

       config :my_app,
         joken_config: My.Config.Module

  Next, tell Joken where to find the config block
    use Joken, otp_app: :my_app


  then to encode and decode
      {:ok, token} = encode_token(%{username: "johndoe"})
      {:ok, decoded_payload} = decode_token(jwt)
  """

  defmacro __using__(opts) do
    quote do
      @behaviour Joken

      def encode_token(payload) do
        Token.encode(config_module, payload)
      end

      def decode_token(jwt, options \\ []) do
        Token.decode(config_module, jwt, options)
      end

      defp config_module() do
        Application.get_env(unquote(opts[:otp_app]), :joken_config)
      end
    end
  end

  @doc """
  Encodes the given payload and optional claims into a JSON Web Token

      Joken.encode(%{ name: "John Doe" })
  """
  defcallback encode_token(payload) :: { status, String.t }


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
  defcallback decode_token(String.t, Keyword.t) :: { status, map | String.t }
end
