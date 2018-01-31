defmodule Joken do
  @moduledoc """
  Joken is a library for generating, signing, validating and verifying JWT tokens.

  ## Architecture

  The core of Joken is `JOSE` library which provides all facilities to sign and verify tokens.
  Joken is a simpler Elixir API that provides a few facilities:

    - Validating claims. You can set up functions for validating custom claims in a portable way.
    - `config.exs` friendly. Define your signer configuration straight in your `config.exs` (even 
    for pem encoded keys or open ssh keys). This might help having different keys for development
    and production. 
    - Portable configuration. You can simply `use Joken.Config` in a module and it will give you
    default generate and verify functions. This encapsulates better your token code.
    - Enhanced errors. Joken strives to be as informative as it can when errors happen be it at 
    compilation or at validation time.
    - Debug friendly. When a token fails validation, a `Logger` debug message will show which claim 
    failed validation with which value. The return value, though for security reasons, does not 
    contain these information.
    - Performance. We have a benchmark suite for identifying where we can have a better performance. 
    From this analysis came: Jason adapter for JOSE, redefinition of :base64url module and other 
    minor tweaks. 

  ## Usage

  Joken has 2 concepts:

    - A token claim configuration
    - A signer configuration

  The claim configuration is a map of binary keys to `Joken.Claim` structs and is used to dynamically
  generate and validate tokens.

  A signer is an instance of `Joken.Signer` that encapsulates the algorithm used to sign and verify a
  token.

  Please, refer to `Joken.Config` for more details on usage of both concepts. Here is a simple example:

      defmodule MyAuth do
        use Joken.Config, default_signer: :pem_rs256
      
        @impl true
        def token_config do
          default_claims()
          |> add_claim("role", fn -> "USER" end, &(&1 in ["ADMIN", "USER"]))
        end
      end
      
      token = MyAuth.generate_and_sign(%{"user_id" => "1234567890"})
      {:ok, _claim_map} = MyAuth.verify_and_validate(token)
  """

  @current_time_adapter Application.get_env(:joken, :current_time_adapter, Joken.CurrentTime.OS)

  @doc """
  Retrieves current time in seconds. 

  This implementation uses an adapter so that you can replace it on your tests. The adapter is
  set through `config.exs`. Example:

      config :joken, 
        current_time_adapter: Joken.CurrentTime.OS

  See Joken's own tests for an example of how to override this with a customizable time mock.
  """
  def current_time, do: @current_time_adapter.current_time()

  @doc """
  Decodes the header of a token without validation.

  **Use this with care!** This DOES NOT validate the token signature and therefore the token might 
  be invalid. The common use case for this function is when you need info to decide on which signer 
  will be used. Even though there is a use case for this, be extra careful to handle data without 
  validation.
  """
  def peek_header(token) when is_binary(token) do
    %JOSE.JWS{alg: {_, alg}, fields: fields} = JOSE.JWT.peek_protected(token)
    Map.put(fields, "alg", Atom.to_string(alg))
  end

  @doc """
  Decodes the claim set of a token without validation.

  **Use this with care!** This DOES NOT validate the token signature and therefore the token might 
  be invalid. The common use case for this function is when you need info to decide on which signer 
  will be used. Even though there is a use case for this, be extra careful to handle data without 
  validation.
  """
  def peek_payload(token) when is_binary(token) do
    %JOSE.JWT{fields: fields} = JOSE.JWT.peek_payload(token)
    fields
  end
end
