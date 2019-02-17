# Configuration

## Token configuration

One of Joken's basic concept is a map of configuration. This map has binary keys that are the claims names and `Joken.Claim` instances with what to do during generation or validation.

Here is an example:

``` elixir
# Empty token configuration
token_config = %{}

# Let's create a Joken.Claim
iss = %Joken.Claim{
         generate: fn -> "My issuer" end,
         validate: fn claim_val, claims, context -> claim_val == "My issuer" end
      }

# Now let's add it to our token config
token_config = Map.put(token_config, "iss", iss)
```

This configuration map is referred to as `token_config`. Since creating it is cumbersome, we provide some helpers:

``` elixir
# Same result as the first example:
token_config = %{} |> Joken.Config.add_claim("iss", fn -> "My issuer" end, &(&1 == "My issuer"))
```

You need at least one of the functions (validate or generate). One example of leaving one of them emty is when you are only validating tokens. In this case you might leave generate functions empty.

With your `token_config` created, you can pass it to functions like: `Joken.generate_claims/3` or `Joken.validate/4`.

## Signer configuration

Signer is an instance of `Joken.Signer`. You can create one like this:

``` elixir
signer = Joken.Signer.create("HS256", "my secret")
```

This is an explicit signer creation. You can configure a signer in mix `config.exs` too. Please see the docs on `Joken.Signer` for the accepted parameters.

## Module approach

In Joken 2.0 you can enpasulate all your token logic in a module with `Joken.Config`. You do that like this:

``` elixir
defmodule MyAppToken do
  use Joken.Config

  # other functions here...
end
```

This is the recommended approach. With this macro you get some generated functions that passes your `token_config` automatically to Joken's functions. It also implements the `Joken.Hooks` behaviour so you can overrid any of its callbacks. Also, by default, it will look for a signer from mix config with the `default_signer` key.

Let's see this in more depth below.

## 1. Claims generation and validation

Let's start with an example:

``` elixir
defmodule MyApp.Token do
  use Joken.Config
end
```

With this configuration, you get:

- A key configuration named `:default_signer`
- Your `token_config` will be created by `Joken.Config.default_claims/1`

So, if you call `MyApp.Token.generate_and_sign/2` **and** you have a key configured with the value `:default_signer` you'll get a token with:

- "exp": defaults to 2 hours with validation
- "iat": defaults to `Joken.current_time/0`
- "nbf": defaults to `Joken.current_time/0` with validation
- "iss": defaults to "Joken" with validation
- "aud": defaults to "Joken" with validation
- "jti": defaults to `Joken.generate_jti/0`

It is important to notice that this configuration is used for claims we want to either generate dynamically (like all time based claims) or validate (like "iss" claim that we want to ensure is the same we use to generate our tokens).

### Overriding `token_config/0`

You can customize token generation and validation by overriding the function `token_config/0` in your module. Example:

``` elixir
defmodule MyApp.Token do
  use Joken.Config

  def token_config do
    %{}
    |> add_claim("my_key", fn -> "My custom claim" end, &(&1 == "My custom claim"))
  end
end

{:ok, token} = MyApp.Token.generate_and_sign()

{:ok, claims} = MyApp.Token.verify_and_validate(token)

claims = %{"my_key" => "My custom claim"}
```

Please see `Joken.Config` docs for more info on the generated callbacks.
