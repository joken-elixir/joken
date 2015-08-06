## Joken [![Documentation](https://img.shields.io/badge/docs-hexpm-blue.svg)](http://hexdocs.pm/joken/) [![Downloads](https://img.shields.io/hexpm/dt/joken.svg)](https://hex.pm/packages/joken) [![Build](https://travis-ci.org/bryanjos/joken.svg)](https://travis-ci.org/bryanjos/joken.svg)


Encodes and decodes JSON Web Tokens.

Currently supports the following algorithms:

* HS256
* HS384
* HS512

Currently supports the following claims:

* **exp**: Expiration
* **nbf**: Not Before
* **aud**: Audience
* **iss**: Issuer
* **sub**: Subject
* **iat**: Issued At
* **jti**: JSON Token ID

For a more in depth description of each claim, please see the reference specification draft [here](http://self-issued.info/docs/draft-ietf-oauth-json-web-token.html).

### Usage:

Joken only needs an implementation of the `Joken.Config` behaviour to work properly. There is where you tell Joken:

* the chosen cryptographic algorithm (i.e.: HS256)
* the secret used to encode and to verify the payload
* how should it encode and decode JSON (i.e.: using Poison.encode!)
* which custom claims it should add
* how to validate all claims

To do that, you must implement the following callbacks:

* `secret_key` -> should return the key used to encrypt tokens. Remember that if you issue tokens using a secret, you can only verify them with the same secret, so this secret must be a constant and persistent value! Also, it seems obvious but does not hurt to mention: this should be a secret value. If it is somehow stolen it will be possible to create tokens that will pass your signing verification process.
* `algorithm` -> return one of the supported algorithms
* `encode(map_or_struct)` -> how Joken will encode claims into JSON
* `decode(binary)` -> how Joken will decode binaries into a valid structure
* `claim(claim, payload)` -> for adding claims to a token. If it returns `nil` then that claim will not be added to the token.
* `validate_claim(claim, payload, options)` -> the logic to validate a specific claim.
 
Here is a full example of a module that would add and validate the `exp` claim 
and not add or validate the others:

```elixir
  defmodule My.Config.Module do
    @behaviour Joken.Config

    def secret_key(), do: Application.get_env(:app, :secret_key) 
    
    def algorithm(), do: :HS256
    
    def encode(map), do: Poison.encode!(map)
    
    def decode(binary), do: Poison.decode!(binary)

    def claim(:exp, payload) do
      Joken.Helpers.get_current_time() + 300
    end

    def claim(_, _), do: nil

    def validate_claim(:exp, payload, options) do
      Joken.Helpers.validate_time_claim(payload, "exp", "Token expired", fn(expires_at, now) -> expires_at > now end)
    end

    def validate_claim(_, _, _), do: :ok
  end
```

Once you have implemented the behaviour module, you must add a configuration a property `joken_config` with your behaviour module to a config block and tell Joken where to find it. Ex:

```elixir
config :my_app,
  joken_config: My.Config.Module
```

next, add a use expression
```elixir
use Joken, otp_app: :my_app
```

then to encode:

```elixir
{:ok, token} = encode_token(%{username: "johndoe"})
```

and to decode:
```elixir
{:ok, decoded_payload} = decode_token(jwt)
```
