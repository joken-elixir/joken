# Migrating from Joken 1.0

Joken 2.0 tries to fix several issues we had with the 1.x series. Some of those issues were:

1.  **Initialization of the `json` client in JOSE**

    The JSON adapter needed to be set every time. This is now an application configuration.

2.  **Confusion between dynamic and static claim value generation**

    Using dynamic over static claims was confusing as this feature was thrown on after version 1.0. Now it is explicit that all claim generation must be done by providing a function that is called at *token generation time*. You are free to implement this token generation function to return static or dynamic values.

3.  **Static claims**

    There was another confusing feature about including static claim values. For example, the API was awkward if you wanted to pass the user id to your token generation function. Now you can pass a map of claims to be added to the token. This avoids the burden of handling all possible use cases. You can still validate any claim.

4.  **Debugging**

    The error messages were not very instructive, often requiring a deep understanding of `Joken` in order to debug. We've made great improvements in this area.

    In order to overcome most of these issues, Joken 2.0 breaks backward compatibility in several ways. We believe it was worth it. We brought in:

      - Module configuration through `Joken.Config` which makes it really simple to configure your claims and have it encapsulated by default;
      - Hook system through `Joken.Hooks` to extend Joken's features with simple plug-like semantics;
      - Performance analysis with a faster implementation--faster than other token libraries in the elixir community;
      - Improved error messages;
      - Ready for future development without breaking the API again (options in claims);
      - Improved testability with mocking current time implementation;
      - A Jason adapter for JOSE;
      - More signer configuration options;

## Migrating

Joken 2 has two approaches: one similar to Joken 1.x and another one using `Joken.Config`. Let's talk about them separately.

### Keeping close to Joken 1.x style

Joken 1.x was based on configuring the `Joken.Token` struct and then calling `sign/2` or `verify/3`. Joken 2.0 omits the `Joken.Token` struct for several reasons: the name of the module was confusing and it had some side-effects like setting the JSON module on JOSE.

We still can build a token configuration and pass it to similar functions `sign` and `verify`. The token configuration is now a simple map of claim keys that must be binaries to an instance of `Joken.Claim`. This struct holds the functions to operate on claims.

So, with this approach, let's compare the same configuration in both versions:

``` elixir
# Joken 1.x
import Joken

%Joken.Token{} # empty configuration
|> with_json_module(Poison) # no built-in Jason module
|> with_validation("some_claim", &(&1 == "some value"))
|> sign(hs256("secret")) # to change the signer for test is cumbersome
|> get_compat() # compact is not a JWT terminology in any way
```

``` elixir
# Joken 2.0
import Joken.Config # more specific

token_config =
  default_claims()
  |> add_claim("some_claim", nil, &(&1 == "some value")) # explicit no generate function

Joken.generate_and_sign()

## on your config.exs
config :joken, default_signer: "secret"

## ... or if you want to keep the explicit signer creation
Joken.generate_and_sign(token_config, nil, Joken.Signer.create("HS256", "secret"))
```

### Using the new encapsulated module configuration

The same example as above can be written differently in Joken 2. We think this is better for isolating token related logic in a single module. Here is how it could be written:

``` elixir
defmodule MyToken do
  use Joken.Config

  @impl true
  def token_config do
    default_claims()
    |> add_claim("some_claim", nil, &(&1 == "some value"))
  end
end

# to use it all you need is:
MyToken.generate_and_sign()
```

You can also add custom token logic in that module like persisting it, adding an `authenticate` function that receives a user and a token or something similar. You could even turn it into an authentication plug adding a `call(conn, opts)`.

Another advantage of this approach is that you can add hooks to your processing. Check the hooks guide for more information.
