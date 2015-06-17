Joken
=====

[Documentation](http://hexdocs.pm/joken/)

Encodes and decodes JSON Web Tokens.

Currently supports the following algorithms:

* HS256
* HS384
* HS512

Currently validates the following:

* Signature
* Expiration (exp)
* Not Before (nbf)
* Audience (aud)
* Issuer (iss)
* Subject (sub)
* Issued At (iat)
* JSON Token ID (jti)


Usage:

Looks for a joken config with `secret_key`, `algorithm`, `parameters`. Parameters module being a module that implements the `Joken.Parameters` Behaviour

```elixir
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
```

```elixir
     config :joken,
       secret_key: "test",
       parameters_module: My.Parameters.Module,
       algorithm: :HS256, #Optional. defaults to :HS256
```

then to encode and decode

```elixir
{:ok, token} = Joken.encode(%{username: "johndoe"})

{:ok, decoded_payload} = Joken.decode(jwt)
```
