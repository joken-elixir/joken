Joken
=====
[Documentation](http://hexdocs.pm/joken/)

Encodes and decodes JSON Web Tokens.

Currently supports the following algorithms:

* HS256
* HS384
* HS512

Currently supports the following claims:

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

```elixir
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
      Joken.Config.get_current_time() + 300
    end

    def claim(_, _) do
      nil
    end

    def validate_claim(:exp, payload) do
      Joken.Config.validate_time_claim(payload, :exp, "Token expired", fn(expires_at, now) -> expires_at > now end)
    end

    def validate_claim(_, _) do
      :ok
    end
  end
```


Joken looks for a `joken` config with `config_module`. `config_module` module being a module that implements the `Joken.Config` Behaviour.


```elixir
     config :joken,
       parameters_module: My.Config.Module,
```

then to encode and decode

```elixir
{:ok, token} = Joken.encode(%{username: "johndoe"})

{:ok, decoded_payload} = Joken.decode(jwt)
```
