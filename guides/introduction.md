# Joken Overview

Joken is a JWT (JSON Web Token) library centered on 4 core operations:

  - Generation of claims: for instance, time based claims.
  - Signing: using a `Joken.Signer`.
  - Verifying: also using a `Joken.Signer`.
  - Validation: running custom validations for received claims.

These core functions are not coupled so that you can use Joken only for verifying and validating incoming tokens or only for generating tokens for other consumers.

It is based upon the awesome [`erlang-jose`](https://github.com/potatosalad/erlang-jose/). Besides having a friendlier Elixir API we include some extras:

  - Ease of key configuration. We provide optional built-in support with Elixir's `Mix.Config` system. See our configuration guide for more details;
  - Portable configuration using `Joken.Claim`;
  - Encapsulate your token logic in a module with `Joken.Config`;
  - Built-in claim generation and validation. `erlang-jose` is responsible only for signing and verifying token signatures. Here we provide extra tools for claims validation and generation;
  - Better error handling. We provide `ExUnit` like error messages for claim validation and configuration errors;
  - A good performance analysis for ensuring this hot-path in APIs won't be your bottleneck. Please see our performance documentation to check what we are talking about;
  - Good defaults. Joken comes with chosen good defaults for parsing JSON (Jason) and generating claims;
  - Hooks for extending Joken functionality. All core actions in Joken have a corresponding hook for extending its functionality. See our hooks guide.

## JWT algorithms

Joken supports all algorithms that JOSE supports. That contains:

  - All HS, RS, ES, PS signing algorithms.
  - All Edwards algorithms (Ed25519, Ed25519ph, Ed448, Ed448ph)

See [jose JWS algorithm support](https://github.com/potatosalad/erlang-jose#json-web-signature-jws-rfc-7515) for more information.

## Usage

As easy as:

A key configuration:

``` elixir
# config/dev.exs
config :joken, default_signer: "secret"
```

Optionally, a signer instance:

``` elixir
signer = Joken.Signer.create("HS256", "secret")
```

A token module:

``` elixir
# lib/myapp/token.ex
defmodule MyApp.Token do
  use Joken.Config
end
```

Then, just use your module :)

``` elixir
{:ok, token_with_default_claims} = MyApp.Token.generate_and_sign()

extra_claims = %{"user_id" => "some_id"}
token_with_default_plus_custom_claims = MyApp.Token.generate_and_sign!(extra_claims)

{:ok, claims} = MyApp.Token.verify_and_validate(token)

# Example with a different key than the default
claims = MyApp.Token.verify_and_validate!(token, another_key)
```

Or with explicitly signer:

``` elixir
signer = Joken.Signer.create("HS256", "secret")

{:ok, token_with_default_claims} = MyApp.Token.generate_and_sign(%{}, signer)

extra_claims = %{"user_id" => "some_id"}
token_with_default_plus_custom_claims = MyApp.Token.generate_and_sign!(extra_claims, signer)

{:ok, claims} = MyApp.Token.verify_and_validate(token, signer)
```

The default is to use HS256 with the configured binary as the key. It will generate:

- `aud`: defaults to "Joken"
- `iss`: defaults to "Joken"
- `jti`: defaults to `&Joken.generate_jti/0`
- `exp`: defaults to 2hs
- `nbf`: defaults to current time
- `iat`: defaults to current time

Everything is customizable in your token module. Please, see our configuration guide for all configuration options.
