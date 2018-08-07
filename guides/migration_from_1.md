# Migrating from Joken 1.0

Joken 2.0 tries to fix several issues we had with the 1.x series. Some of those issues were:

1. **Initialization of the `json` client in JOSE**
  
  The JSON adapter was indicated as being needed to be set everytime. This is now an application configuration.
  
1. **Confusion between dynamic and static claim value generation**

  Using dynamic claims was confusing as it was hacked in after version 1.0. Now, it is very explicetely said that all claim generation must be a function that is called at *token generation time*. This avoids the confusion by being explicit. If you need dynamic values just implement your token generation function that way. Otherwise, return a fixed value. 
  
1. **Static claims**

  There was another hacked feature about including static claim values. If you want to pass the user id to your token generation function, the API was clumsy. Now you can pass a map of claims to be added to the token. This leaves the burden of trying to cope with all use cases. You can still validate any claim.
  
1. **Debugging**

  The error messages were not very instructive and a lot of times you would have to debug the inner core of `Joken`. We've improved a lot on this area.
  
In order to overcome most of these issues, we've came up with a major version that breaks backwards compatibility in several ways. We believe it was worth it. We brought in:

- Module configuration through `Joken.Config` which makes it really simple to configure your claims and have it encapsulated by default;
- Hook system through `Joken.Hooks` to extend Joken's features with a simple plug-like semantic;
- Performance analysis that brought a faster implementation and faster than other token libraries in the elixir community;
- Better developer experience with improved error messages;
- Ready for being extended without breaking the API again (options in claims);
- Improved testability with mocking current time implementation;
- A Jason adapter for JOSE;
- More configuration options for signers;

## Migrating 

Joken 2 has two approaches: one similar to Joken 1.x and another one using `Joken.Config`. Let's talk about them separately.

### Keeping close to Joken 1.x style

Joken 1.x was based on configuring the `Joken.Token` struct and then calling `sign/2` or `verify/3`. In Joken 2.0 there is no `Joken.Token` struct for several reasons: the name of the module was confusing and it had some side-effects like setting the JSON module on JOSE. 

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

On that module you can add your custom token logic too like persisting it, adding an `authenticate` function that receives a user and a token or things like that. You could even add a `call(conn, opts)` call there and call this your authentication plug.

Another advantage of this approach is that you can add hooks to your processing. Check the hooks guide for more information.
