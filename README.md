## Joken [![Documentation](https://img.shields.io/badge/docs-hexpm-blue.svg)](http://hexdocs.pm/joken/) [![Downloads](https://img.shields.io/hexpm/dt/joken.svg)](https://hex.pm/packages/joken) [![Build](https://travis-ci.org/bryanjos/joken.svg)](https://travis-ci.org/bryanjos/joken.svg)


Signs and Verifies JSON Web Tokens. The goal of this library is to provide a convienent way to create JWTs while allowing the flexibility to customize claims, validations, algorithms, and json serializers as well. This library also includes a Plug for checking tokens as well. 

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

<sup><a name="footnote-1">1</a></sup> Implemented mostly in pure Erlang. May be less performant than other supported signature algorithms. See [jose JWS algorithm support](https://github.com/potatosalad/erlang-jose#json-web-signature-jws-rfc-7515) for more information.

Supports adding and validating claims from the JSON Web Token specification:

* **exp**: Expiration
* **nbf**: Not Before
* **aud**: Audience
* **iss**: Issuer
* **sub**: Subject
* **iat**: Issued At
* **jti**: JSON Token ID

For a more in depth description of each claim, please see the reference specification draft [here](http://self-issued.info/docs/draft-ietf-oauth-json-web-token.html).


Also allows for adding and validating custom claims as well.

### Usage:

Joken allows for customization of tokens, but also provides defaults. Joken works by passing a `Joken.Token` struct to functions, which also return a modified `Joken.Token` struct.

To create a token with default claims of `exp`, `iaf`, and `nbf`, and to use Poison as the json serializer:

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
|> with_validation(:user_id, &(&1 == 1))
|> with_signer(hs256("my_secret"))
```

To sign a token, use the `sign` function. The `get_compact` function will return the token in its binary form:

```elixir
import Joken

my_token = %{user_id: 1}
|> token
|> with_validation(:user_id, &(&1 == 1))
|> with_signer(hs256("my_secret"))
|> sign
|> get_compact
```

Verifying a token works in the same way. First create a token using the compact form and verify it. `verify` will return the `Joken.Token` struct with the `claims` property filled with the claims from the token if verified. Otherwise, the `error` property will have the error:

```elixir
import Joken

my_verified_token = "some_token"
|> token
|> with_validation(:user_id, &(&1 == 1))
|> with_signer(hs256("my_secret"))
|> verify
```
