# Joken Overview

[![Documentation](https://img.shields.io/badge/docs-hexpm-blue.svg)](http://hexdocs.pm/joken/) [![Downloads](https://img.shields.io/hexpm/dt/joken.svg)](https://hex.pm/packages/joken) [![Build](https://travis-ci.org/bryanjos/joken.svg?branch=master)](https://travis-ci.org/bryanjos/joken)

[Documentation](http://hexdocs.pm/joken/)

Joken is a JWT (Json Web Token) library based upon the awesome [`erlang-jose`](https://github.com/potatosalad/erlang-jose/). Features:

  - Ease of key configuration. We provide built-in support with Elixir's `Mix.Config` system. See our configuration guide for more details.
  - Portable configuration by leveraging `Joken.Config`. 
  - Built-in claim generation and validation. `erlang-jose` is responsible only for signing and verifying token signatures. Here we provide extra tools for claim validation and generation.
  - Better error handling. We provide `ExUnit` like error messages for claim validation. 
  - A good perfomance analysis for ensuring this hot-path in APIs won't be your bottleneck. Please see our perfomance documentation to check what we are talking about.
  - Good defaults. Joken comes with chosen good defaults for parsing Json and generating claims.
  - Hooks for extending Joken functionality. All core actions in Joken have a corresponding hook for extending its functionality. See our hooks guide.
  
## JWT algorithms

Joken supports all algorithms that JOSE supports. That contains:

  - All HS, RS, ES, PS signing algorithms.
  - All Edwards algorithms (Ed25519, Ed25519ph, Ed448, Ed448ph)
  
See [jose JWS algorithm support](https://github.com/potatosalad/erlang-jose#json-web-signature-jws-rfc-7515) for more information.

## Usage

As easy as:

1. A key configuration:

``` elixir
# config/dev.exs 
config :joken, default_signer: "secret"
```

2. A token module:

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

The default is to use HS256 with the configured binary as the key. It will generate:

- aud: defaults to "Joken"
- iss: defaults to "Joken"
- jti: defaults to `Joken.generate_jti`
- exp: defaults to 2hs
- nbf: defaults to current time
- iat: defaults to current time

Everything is customizable in your token module. Please, see our configuration guide for all configuration options.

## LICENSE

See [LICENSE.txt](https://github.com/bryanjos/joken/blob/master/LICENSE.txt)

