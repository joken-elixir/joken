# Configuration

Joken allows you to configure every aspect of its features:

1. Claim generation and validation
2. Key configuration (used for signing and verifying)
3. Override default behaviour
4. Extend its functionality with hooks

The way you can configure Joken is through options to `use Joken.Config`, overriding functions or through config.exs.

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
- Your claims generation and validation will delegate to `Joken.Config.default_claims/1`

So, if you call `MyApp.Token.generate_and_sign/2` **and** you have a key configured with the value `:default_signer` you'll get a token with:

- "exp": defaults to 2 hours with validation
- "iat": defaults to `Joken.current_time/0`
- "nbf": defaults to `Joken.current_time/0` with validation
- "iss": defaults to "Joken" with validation
- "aud": defaults to "Joken" with validation
- "jti": defaults to `Joken.generate_jti/0` 

It is important to notice that this configuration is used for claims we want to either generate dynamically (like all time based claims) or validate (like "iss" claim that we want to ensure is the same we use to generate our tokens).

All claims in this configuration have a binary key and a `Joken.Claim` value with a function for generating the claim data and a function with one parameter for validating the claim. These are called during token generation and validation respectively.

### Overriding `token_config/0`

You can customize token generation and validation by overriding the function `token_config/0` in your module. Example:

``` elixir
defmodule MyApp.Token do
  use Joken.Config
  
  # must return a map with binary keys and Joken.Claim as values
  def token_config do
    %{}
    |> Map.put("my_key", %Joken.Claim{
        generate: fn -> "My custom claim",
        validate: fn incoming_claim_value -> incoming_claim_value == "My custom claim"
    })
  end
end

{:ok, token} = MyApp.Token.generate_and_sign()

{:ok, claims} = MyApp.Token.verify_and_validate(token)

claims = %{"my_key" => "My custom claim"}
```

Since creating a Joken.Claim is cumbersome, we provide a helper function already imported in this module `Joken.Config.add_claim/4`. 

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

Both configurations are equivalent here. 

## Signer configuration

Please refer to signer guide.

