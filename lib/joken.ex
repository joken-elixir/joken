defmodule Joken do
  alias Joken.Token

  @type algorithm :: :HS256 | :HS384 | :HS512
  @type status :: :ok | :error
  @type payload :: map | Keyword.t

  @moduledoc """
    Encodes and decodes JSON Web Tokens.


    Usage:

    Looks for a joken config block with `secret_key`, `algorithm`, and `json_module`. Json module being a module that implements the `Joken.Codec` Behaviour

      defmodule My.Json.Module do
        alias Poison, as: JSON
        @behaviour Joken.Json

        def encode(map) do
          JSON.encode!(map)
        end

        def decode(binary) do
          JSON.decode!(binary, keys: :atoms!)
        end
      end

       config :joken
         secret_key: "test",
         json_module: My.Json.Module,
         algorithm: :HS256, #Optional. defaults to :HS256

    then to encode and decode

      {:ok, token} = Joken.encode(%{username: "johndoe"})

      {:ok, decoded_payload} = Joken.decode(jwt)
  """


  @doc """
  Encodes the given payload and optional claims into a JSON Web Token

      Joken.encode(%{ name: "John Doe" }, %{ iss: "self"})
  """

  @spec encode(payload, payload) :: { status, String.t }
  def encode(payload, claims \\ %{}) do
    secret_key =  Application.get_env(:joken, :secret_key)
    json_module = Application.get_env(:joken, :json_module)
    algorithm =   Application.get_env(:joken, :algorithm, :HS256)

    Token.encode(secret_key, json_module, payload, algorithm, claims)
  end

  @doc """
  Decodes the given JSON Web Token and gets the payload. Optionally checks against
  the given claims for validity

      Joken.decode(token, %{ aud: "self" })
  """

  @spec decode(String.t, payload) :: { status, map | String.t }
  def decode(jwt, claims \\ %{}) do
    secret_key =  Application.get_env(:joken, :secret_key)
    json_module = Application.get_env(:joken, :json_module)
    algorithm =   Application.get_env(:joken, :algorithm, :HS256)

    Token.decode(secret_key, json_module, jwt, algorithm, claims)
  end
  
end