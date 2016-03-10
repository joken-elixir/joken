# Joken

[![Documentation](https://img.shields.io/badge/docs-hexpm-blue.svg)](http://hexdocs.pm/joken/) [![Downloads](https://img.shields.io/hexpm/dt/joken.svg)](https://hex.pm/packages/joken) [![Build](https://travis-ci.org/bryanjos/joken.svg?branch=master)](https://travis-ci.org/bryanjos/joken)

[Documentation](http://hexdocs.pm/joken/)

A JSON Web Token (JWT) Library

The goal of this library is to provide a convienent way to create, sign, verify, and validate JWTs while allowing the flexibility to customize each step along the way. This library also includes a Plug for checking tokens as well. 

Supports the following algorithms:

* ES256
* ES384
* ES512
* HS256
* HS384
* HS512
* PS256 <sup>[1](#footnote-1)</sup>
* PS384 <sup>[1](#footnote-1)</sup>
* PS512 <sup>[1](#footnote-1)</sup>
* RS256
* RS384
* RS512
* Ed25519
* Ed25519ph
* Ed448ph
* Ed448

<sup><a name="footnote-1">1</a></sup> Implemented mostly in pure Erlang. May be less performant than other supported signature algorithms. See [jose JWS algorithm support](https://github.com/potatosalad/erlang-jose#json-web-signature-jws-rfc-7515) for more information.

Joken allows you to use any claims you wish, but has convenience methods for the claims listed in the specification. These claims are listed below:

* **exp**: Expiration
* **nbf**: Not Before
* **aud**: Audience
* **iss**: Issuer
* **sub**: Subject
* **iat**: Issued At
* **jti**: JSON Token ID

For a more in depth description of each claim, please see the reference specification [here](https://tools.ietf.org/html/rfc7519).

You can view the changelog [here](https://github.com/bryanjos/joken/blob/master/CHANGELOG.md) or on the official documentation in the "Pages" section.


## Usage

All you need to generate a token is a `Joken.Token` struct with proper values. 
There you can set:
- json_module: choose your JSON library (currently supports Poison | JSX)
- signer: a map that tells the underlying system how to sign and verify your 
tokens
- validations: a map of claims keys to function validations
- claims: the map of values you want encoded in a token
- claims_generation: a map of functions called when signing to generate dynamic values
- token: the compact representation of a JWT token
- error: message indicating why a sign/verify operation failed

To help you fill that configuration struct properly, use the functions in the `Joken` module.

Joken allows for customization of tokens, but also provides some defaults.

To create a token with default generator for claims `exp`, `iaf`, and `nbf`, and to use Poison as the json serializer:

```elixir
import Joken

my_token = token
|> with_signer(hs256("my_secret"))
```

To create a function with an inital map of claims:

```elixir
import Joken

my_token = %{user_id: 1}
|> token
|> with_signer(hs256("my_secret"))
```

Here is an example of adding a custom validator for the claim:

```elixir
import Joken

my_token = %{user_id: 1}
|> token
|> with_validation("user_id", &(&1 == 1))
```

To sign a token, use the `sign` function. The `get_compact` function will return the token in its binary form:

```elixir
import Joken

my_token = %{user_id: 1}
|> token
|> with_validation("user_id", &(&1 == 1))
|> with_signer(hs256("my_secret"))
|> sign
|> get_compact
```

Verifying a token works in the same way. First, create a token using the compact form and verify it. `verify` will return the `Joken.Token` struct with the `claims` property filled with the claims from the token if verified. Otherwise, the `error` property will have the error:

```elixir
import Joken

my_verified_token = "some_token"
|> token
|> with_validation("user_id", &(&1 == 1))
|> with_signer(hs256("my_secret"))
|> verify
```

There are other options and helper functions available. See the docs of the `Joken` module for a complete documentation.

## Plug

Joken also comes with a Plug for verifying JWTs in web applications.

There are two possible scenarios:

1. Same configuration for all routes
2. Per route configuration

In the first scenario just add this plug before the dispatch plug.

```elixir
  defmodule MyRouter do
    use Plug.Router

    plug Joken.Plug, on_verifying: &MyRouter.verify_function/0
    plug :match
    plug :dispatch

    post "/user" do
      # will only execute here if token is present and valid
    end

    match _ do
      # will only execute here if token is present and valid
    end
  end
```

In the second scenario, you will need at least plug ~> 0.14 in your deps. 
Then you must plug this AFTER :match and BEFORE :dispatch. 

```elixir
  defmodule MyRouter do
    use Plug.Router

    # route options
    @skip_token_verification %{joken_skip: true}

    plug :match
    plug Joken.Plug, on_verifying: &MyRouter.verify_function/0       
    plug :dispatch

    post "/user" do
      # will only execute here if token is present and valid
    end
    
    # see options section below
    match _, private: @skip_token_verification do
      # will NOT try to validate a token
    end
  end
```

### Options

This plug accepts the following options in its initialization:

- `on_verifying`: a function used to verify the token. Must return a Token

- `on_error` (optional): a function that accepts `conn` and `message` as parameters. Must
return a tuple containing the conn and a binary representing the 401 response. If it's a map,
it's turned into json, otherwise, it is returned as is.

When using this with per route options you must pass a private map of options
to the route. The keys that Joken will look for in that map are:

- `joken_skip`: skips token validation. true or false

- `joken_on_verifying`: Same as `on_verifying` above. Overrides `on_verifying` if defined on the Plug

- `joken_on_error`: Same as `on_error` above. Overrides `on_error` if defined on the Plug

## Native crypto

Joken is based on cryptography implemented by the [erlang-jose](https://github.com/potatosalad/erlang-jose) project. One of the features it provides is the ability to auto detect the presence of native crypto libraries with a NIF (Erlang's Native Implemented Function) interface. Some of these libraries are:

- [erlang-libsodium](https://github.com/potatosalad/erlang-libsodium): provides native implemented crypto for Ed25519 and Ed25519ph
- [erlang-keccakf1600](https://github.com/potatosalad/erlang-keccakf1600): provides SHA-3 NIFs
- [erlang-libdecaf](https://github.com/potatosalad/erlang-libdecaf): provides ed448goldilocks NIFs

Joken inherits that auto discovery feature. So, in order to increase speed in scenarios that you are using these crypto libraries, all you need to do is add them as dependencies:

```elixir
defp deps do
  [
    {:joken, "~> 1.1"},
    {:libsodium, "~> 0.0.3"},
    {:keccakf1600, "~> 0.0.1"},
    {:libdecaf, "~> 0.0.1"}
  ]
end
```

Be advised though that this is a work in progress by [@potatosalad](https://github.com/potatosalad).

