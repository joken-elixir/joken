defmodule Joken do
  alias Joken.Token
  alias Joken.Utils

  @type algorithm :: :HS256 | :HS384 | :HS512
  @type status :: :ok | :error
  @type payload :: map | Keyword.t

  @moduledoc """
    Encodes and decodes JSON Web Tokens.


    Usage:

    Looks for a joken config block with `secret_key`, `algorithm`, and `parameters_module`. Parameters module being a module that implements the `Joken.Parameters` Behaviour

      defmodule My.Parameters.Module do
        alias Poison, as: JSON
<<<<<<< HEAD
        @behaviour Joken.Parameters
=======
        @behaviour Joken.Codec
>>>>>>> master

        def encode(map) do
          JSON.encode!(map)
        end

        def decode(binary) do
          JSON.decode!(binary, keys: :atoms!)
        end
      end

       config :joken,
         secret_key: "test",
         parameters_module: My.Parameters.Module,
         algorithm: :HS256, #Optional. defaults to :HS256

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
    Token.encode(secret_key, parameters_module, payload, algorithm)
  end

  @doc """
  Decodes the given JSON Web Token and gets the payload

      Joken.decode(token)
  """

  @spec decode(String.t) :: { status, map | String.t }
  def decode(jwt) do
    Token.decode(secret_key, parameters_module, jwt, algorithm)
  end

  defp secret_key() do
    secret_key = Application.get_env(:joken, :secret_key)

    if Application.get_env(:joken, :decode_secret_key?, false) do
      Utils.base64url_decode(secret_key)
    else
      secret_key
    end
  end

  defp parameters_module() do
    Application.get_env(:joken, :parameters_module)
  end

  defp algorithm() do
    Application.get_env(:joken, :algorithm, :HS256)    
  end
end
