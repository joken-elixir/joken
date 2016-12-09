# Joken

[![Documentation](https://img.shields.io/badge/docs-hexpm-blue.svg)](http://hexdocs.pm/joken/) [![Downloads](https://img.shields.io/hexpm/dt/joken.svg)](https://hex.pm/packages/joken) [![Build](https://travis-ci.org/bryanjos/joken.svg?branch=master)](https://travis-ci.org/bryanjos/joken)

[Documentation](http://hexdocs.pm/joken/)

A JSON Web Token (JWT) Library

The goal of this library is to provide a convenient way to create, sign, verify, and validate JWTs while allowing the flexibility to customize each step along the way. This library also includes a Plug for checking tokens as well.

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

To create a token with default generator for claims `exp`, `iat`, and `nbf`, and to use Poison as the json serializer:

```elixir
import Joken

my_token = token
|> with_signer(hs256("my_secret"))
```

To create a function with an initial map of claims:

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

    plug Joken.Plug, verify: &MyRouter.verify_function/0
    plug :match
    plug :dispatch

    post "/user" do
      # will only execute here if token is present and valid
    end

    match _ do
      # will only execute here if token is present and valid
    end

    def verify_function() do
      %Joken.Token{}
      |> Joken.with_signer(hs256("secret"))
      |> Joken.with_sub(1234567890)
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
    
    @custom_token_verification %{joken_verify: %MyRouter.is_not_subject/0}

    plug :match
    plug Joken.Plug, verify: &MyRouter.verify_function/0       
    plug :dispatch

    post "/user" do
      # will only execute here if token is present and valid
    end
    
    post "/endpoint", private: @custom_token_verification do
      # will only execute here if token is present and valid 
      # using the function `is_not_subject/0`
    end

    # see options section below
    match _, private: @skip_token_verification do
      # will NOT try to validate a token
    end
    
    def verify_function() do
      %Joken.Token{}
      |> Joken.with_signer(hs256("secret"))
      |> Joken.with_sub(1234567890)
    end
    
    def is_not_subject() do
      %Joken.Token{}
      |> Joken.with_validation("sub", &(&1 != 1234567890))
      |> Joken.with_signer(hs256("secret"))
    end
  end
```

For more examples, look in our [tests](https://github.com/bryanjos/joken/blob/master/test/plug_test.exs) for more usage scenarios. 


### Options

This plug accepts the following options in its initialization:

- `verify` (required): a function used to verify the token. The function must at least specify algorithm used and your secret using the `with_signer` function (see above). Must return a Token.

- `on_error` (optional): a function that accepts `conn` and `message` as parameters. Must
return a tuple containing the conn and a binary representing the 401 response. If it's a map,
it's turned into json, otherwise, it is returned as is.

When using this with per route options you must pass a private map of options
to the route. The keys that Joken will look for in that map are:

- `joken_skip`: skips token validation. true or false

- `joken_verify`: Same as `verify` above. Overrides `verify` if defined on the Plug

- `joken_on_error`: Same as `on_error` above. Overrides `on_error` if defined on the Plug

## Key arguments

The family of HS algorithms use Hash-Based Message Authentication Code algorithms with the SHA (Secure Hash) hashing function. This means that it uses a shared key (the "secret") to generate a signature of the message. So, the key is a string and `Joken`s signer functions can receive a string.

The other algorithms are based on asymmetric cryptography. For example: RS512 is based on RSA asymmetric cryptography. This is an algorithm that works with [large prime numbers multiplication](https://en.wikipedia.org/wiki/RSA_(cryptosystem)). So the key must contain data about the chosen primes amongst other parameters. Therefore, we can't simply accept these parameters as string.

Similarly, as an added example, ES256 is based on a digital signing algorithm using elliptic curve keys, a kind of asymmetric cryptography. They also need information on the points used on the curve and aren't suitable to be passed as a string in free-form.

These keys have standards on how they are shared. PEM (Privacy enhanced mail) files are a common example. They have all the key information encoded in a text format. Erlang, and by consequence Elixir, has native modules for dealing with these. They reside in the `:public_key` module. Functions like `pem_decode/1` or `pem_encode/1` might be useful for handling this kind of data. 

Actually, `Joken` depends on `JOSE`. There are facilities in `JOSE` that make the job even easier. Here is an example with an RSA key used in jwt.io:

``` elixir
# Suppose we have a file accessible from 'test/example_key.pem' with the following contents

#-----BEGIN RSA PRIVATE KEY-----
#MIICWwIBAAKBgQDdlatRjRjogo3WojgGHFHYLugdUWAY9iR3fy4arWNA1KoS8kVw33cJibXr8bvwUAUparCwlvdbH6dvEOfou0/gCFQsHUfQrSDv+MuSUMAe8jzKE4qW+jK+xQU9a03GUnKHkkle+Q0pX/g6jXZ7r1/xAK5Do2kQ+X5xK9cipRgEKwIDAQABAoGAD+onAtVye4ic7VR7V50DF9bOnwRwNXrARcDhq9LWNRrRGElESYYTQ6EbatXS3MCyjjX2eMhu/aF5YhXBwkppwxg+EOmXeh+MzL7Zh284OuPbkglAaGhV9bb6/5CpuGb1esyPbYW+Ty2PC0GSZfIXkXs76jXAu9TOBvD0ybc2YlkCQQDywg2R/7t3Q2OE2+yo382CLJdrlSLVROWKwb4tb2PjhY4XAwV8d1vy0RenxTB+K5Mu57uVSTHtrMK0GAtFr833AkEA6avx20OHo61Yela/4k5kQDtjEf1N0LfI+BcWZtxsS3jDM3i1Hp0KSu5rsCPb8acJo5RO26gGVrfAsDcIXKC+bQJAZZ2XIpsitLyPpuiMOvBbzPavd4gY6Z8KWrfYzJoI/Q9FuBo6rKwl4BFoToD7WIUS+hpkagwWiz+6zLoX1dbOZwJACmH5fSSjAkLRi54PKJ8TFUeOP15h9sQzydI8zJU+upvDEKZsZc/UhT/SySDOxQ4G/523Y0sz/OZtSWcol/UMgQJALesy++GdvoIDLfJX5GBQpuFgFenRiRDabxrE9MNUZ2aPFaFp+DyAe+b4nDwuJaW2LURbr8AEZga7oQj0uYxcYw==
#  -----END RSA PRIVATE KEY-----

# We can sign with this PRIVATE key using:
import Joken
key = JOSE.JWK.from_pem_file("test/example_key.pem") 

signed_token = %{ "name" => "John Doe" }
|> token
|> sign(rs256(key))
|> get_compact
```

In summary, what `Joken` expects as a key is what suits the algorithm in use. If it is: 

- HSXXX: then it must be a string
- RSXXX: then it must be a map with RSA key parameters (remember that it must sign with a private key and verify with a public key)

And so on...

The definition of the parameters we expect can be seen in:

* JSON Web Algorithms (JWA) [RFC 7518](https://tools.ietf.org/html/rfc7518)
* JSON Web Encryption (JWE) [RFC 7516](https://tools.ietf.org/html/rfc7516)
* JSON Web Key (JWK)        [RFC 7517](https://tools.ietf.org/html/rfc7517)
* JSON Web Signature (JWS)  [RFC 7515](https://tools.ietf.org/html/rfc7515)
* JSON Web Token (JWT)      [RFC 7519](https://tools.ietf.org/html/rfc7519)

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

