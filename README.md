Joken
=====

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


Usage:

Looks for a config with `secret_key`, `algorithm`, and `json_module`. Json module being a module that implements the `Joken.Codec` Behaviour

```elixir
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
```

```elixir
     config :my_otp_app
       secret_key: "test",
       json_module: My.Json.Module,
       algorithm: :HS256, #Optional. defaults to :HS256

{:ok, joken} = Joken.start_link(:my_otp_app)
```

alternatively, you can pass in the variables as well

```elixir
{:ok, joken} = Joken.start_link("test", My.Json.Module) 
```

then to encode and decode

```elixir
{:ok, token} = Joken.encode(joken, %{username: "johndoe"})

{:ok, decoded_payload} = Joken.decode(joken, jwt)
```
